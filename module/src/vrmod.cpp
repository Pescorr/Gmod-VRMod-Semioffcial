#include <gmod/Interface.h>
#include <openvr/openvr.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <stdint.h>
#include <limits.h>
#include <errno.h>
#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <Windows.h>
#include <d3d9.h>
#include <d3d11.h>
#define PATH_MAX MAX_PATH
#else
#include <GL/gl.h>
#include <sys/mman.h>
#include <dlfcn.h>
#include <unistd.h>
#endif
#ifdef VRMOD_USE_SRANIPAL
#include <sranipal/SRanipal.h>
#include <sranipal/SRanipal_Eye.h>
#include <sranipal/SRanipal_Lip.h>
#pragma comment (lib, "SRanipal.lib")
#endif

#define MAX_STR_LEN     256
#define MAX_ACTIONS     128
#define MAX_ACTIONSETS  16
#define PI_F            3.141592654f

enum EActionType{
    ActionType_Pose         = 439,
    ActionType_Vector1      = 708,
    ActionType_Vector2      = 709,
    ActionType_Boolean      = 736,
    ActionType_Skeleton     = 869,
    ActionType_Vibration    = 974,
};

enum ELuaRefIndex{
    LuaRefIndex_EmptyTable,
    LuaRefIndex_PoseTable,
    LuaRefIndex_HmdPose,
    LuaRefIndex_ActionTable,
    LuaRefIndex_LipDataTable,
    LuaRefIndex_LeftEyeDataTable,
    LuaRefIndex_RightEyeDataTable,
    LuaRefIndex_Max,
};

typedef struct {
    vr::VRActionHandle_t handle;
    char fullname[MAX_STR_LEN];
    int luaRefs[2];
    char* name;
    int type;
}action;

typedef struct {
    vr::VRActionSetHandle_t handle;
    char name[MAX_STR_LEN];
}actionSet;

vr::IVRSystem*          g_pSystem = NULL;
vr::IVRInput*           g_pInput = NULL;
vr::TrackedDevicePose_t g_poses[vr::k_unMaxTrackedDeviceCount];
actionSet               g_actionSets[MAX_ACTIONSETS];
int                     g_actionSetCount = 0;
vr::VRActiveActionSet_t g_activeActionSets[MAX_ACTIONSETS];
int                     g_activeActionSetCount = 0;
action                  g_actions[MAX_ACTIONS];
int                     g_actionCount = 0;
char                    g_errorString[MAX_STR_LEN];
vr::VRTextureBounds_t   g_textureBoundsLeft;
vr::VRTextureBounds_t   g_textureBoundsRight;
vr::Texture_t           g_vrTexture;
int                     g_luaRefs[LuaRefIndex_Max];
int                     g_luaRefCount = 0;

char                    g_createTextureOrigBytes[14];
int                     g_captureTarget = 0; // 0=main VR texture, 1=overlay texture

// Overlay system
#define MAX_OVERLAYS    8
vr::VROverlayHandle_t   g_overlays[MAX_OVERLAYS];
int                     g_overlayCount = 0;

#ifdef _WIN32
typedef HRESULT         (APIENTRY* CreateTexture)(IDirect3DDevice9*, UINT, UINT, UINT, DWORD, D3DFORMAT, D3DPOOL, IDirect3DTexture9**, HANDLE*);
CreateTexture           g_createTexture = NULL;
ID3D11Device*           g_d3d11Device = NULL;
ID3D11Texture2D*        g_d3d11Texture = NULL;
HANDLE                  g_sharedTexture = NULL;
ID3D11Texture2D*        g_overlayD3D11Texture = NULL;
HANDLE                  g_overlaySharedTexture = NULL;
IDirect3DDevice9*       g_pD3D9Device = NULL;
HWND                    g_gameHWND = NULL;
vr::Texture_t           g_overlayVrTexture;
typedef void*           (*CreateInterfaceFn)(const char* pName, int* pReturnCode);
HRESULT APIENTRY CreateTextureHook(IDirect3DDevice9* pDevice, UINT w, UINT h, UINT levels, DWORD usage, D3DFORMAT format, D3DPOOL pool, IDirect3DTexture9** tex, HANDLE* shared_handle) {
    WriteProcessMemory(GetCurrentProcess(), g_createTexture, g_createTextureOrigBytes, 14, NULL);
    HANDLE* target = (g_captureTarget == 0) ? &g_sharedTexture : &g_overlaySharedTexture;
    if (*target == NULL) {
        shared_handle = target;
        pool = D3DPOOL_DEFAULT;
    }
    return g_createTexture(pDevice, w, h, levels, usage, format, pool, tex, shared_handle);
};
#else
typedef struct{
    void ClearEntryPoints();
    uint64_t m_nTotalGLCycles, m_nTotalGLCalls;
    int unknown1;
    int unknown2;
    int m_nOpenGLVersionMajor;
    int m_nOpenGLVersionMinor;
    int m_nOpenGLVersionPatch;
    bool m_bHave_OpenGL;
    char *m_pGLDriverStrings[4];
    int m_nDriverProvider;
    void *firstFunc;
}COpenGLEntryPoints;
typedef void *(*GL_GetProcAddressCallbackFunc_t)(const char *, bool &, const bool, void *);
typedef COpenGLEntryPoints*(*GetOpenGLEntryPoints_t)(GL_GetProcAddressCallbackFunc_t callback);
typedef void            (*glGenTextures_t)(GLsizei n, GLuint *textures);
void*                   g_createTexture = NULL;
GLuint                  g_sharedTexture = GL_INVALID_VALUE;
GLuint                  g_overlaySharedTexture_GL = GL_INVALID_VALUE;
COpenGLEntryPoints*     g_GL = NULL;
vr::Texture_t           g_overlayVrTexture;
void CreateTextureHook(GLsizei n, GLuint *textures) {
    memcpy((void*)g_createTexture, (void*)g_createTextureOrigBytes, 14);
    ((glGenTextures_t)g_createTexture)(n, textures);
    if (g_captureTarget == 0)
        g_sharedTexture = textures[0];
    else
        g_overlaySharedTexture_GL = textures[0];
    return;
}
#endif

#ifdef VRMOD_USE_SRANIPAL
char facial_blend_names[][32] = {
    "Jaw_Right",
    "Jaw_Left",
    "Jaw_Forward",
    "Jaw_Open",
    "Mouth_Ape_Shape",
    "Mouth_Upper_Right",
    "Mouth_Upper_Left",
    "Mouth_Lower_Right",
    "Mouth_Lower_Left",
    "Mouth_Upper_Overturn",
    "Mouth_Lower_Overturn",
    "Mouth_Pout",
    "Mouth_Smile_Right",
    "Mouth_Smile_Left",
    "Mouth_Sad_Right",
    "Mouth_Sad_Left",
    "Cheek_Puff_Right",
    "Cheek_Puff_Left",
    "Cheek_Suck",
    "Mouth_Upper_UpRight",
    "Mouth_Upper_UpLeft",
    "Mouth_Lower_DownRight",
    "Mouth_Lower_DownLeft",
    "Mouth_Upper_Inside",
    "Mouth_Lower_Inside",
    "Mouth_Lower_Overlay",
    "Tongue_LongStep1",
    "Tongue_Left",
    "Tongue_Right",
    "Tongue_Up",
    "Tongue_Down",
    "Tongue_Roll",
    "Tongue_LongStep2",
    "Tongue_UpRight_Morph",
    "Tongue_UpLeft_Morph",
    "Tongue_DownRight_Morph",
    "Tongue_DownLeft_Morph",
};

ViveSR::anipal::Eye::EyeData_v2 eye_data_v2;
ViveSR::anipal::Lip::LipData_v2 lip_data_v2;
HANDLE SRanipalThreadHandle = NULL;
bool SRanipalLipInitialized = false;
bool SRanipalEyeInitialized = false;

void SRanipalDataThread(){
    char lip_image[800 * 400];
    lip_data_v2.image = lip_image;
    int error = ViveSR::Error::WORK;
    while(SRanipalEyeInitialized || SRanipalLipInitialized){
        if(SRanipalEyeInitialized)
            error = ViveSR::anipal::Eye::GetEyeData_v2(&eye_data_v2);
        if(SRanipalLipInitialized)
            error = ViveSR::anipal::Lip::GetLipData_v2(&lip_data_v2);
    }
    return;
}

LUA_FUNCTION(SRanipalInit) {
    if(SRanipalThreadHandle != NULL)
        return 0;
    int error = ViveSR::anipal::Initial(ViveSR::anipal::Eye::ANIPAL_TYPE_EYE_V2, NULL);
    SRanipalEyeInitialized = (error == ViveSR::Error::WORK);
    LUA->PushNumber(error);
    error = ViveSR::anipal::Initial(ViveSR::anipal::Lip::ANIPAL_TYPE_LIP_V2, NULL);
    SRanipalLipInitialized = (error == ViveSR::Error::WORK);
    LUA->PushNumber(error);
    if ((SRanipalThreadHandle = CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)SRanipalDataThread, NULL, 0, NULL)) == NULL)
        LUA->ThrowError("Failed to create SRanipal thread");
    return 2;
}

LUA_FUNCTION(SRanipalGetLipData) {
    LUA->ReferencePush(g_luaRefs[LuaRefIndex_LipDataTable]);
    LUA->PushNumber(lip_data_v2.timestamp);
    LUA->SetField(-2, "timestamp");
    for (int i = 0; i < 37; i++) {
        LUA->PushNumber(lip_data_v2.prediction_data.blend_shape_weight[i]);
        LUA->SetField(-2, facial_blend_names[i]);
    }
    return 1;
}

LUA_FUNCTION(SRanipalGetEyeData) {
    LUA->ReferencePush(g_luaRefs[LuaRefIndex_LeftEyeDataTable]);
    LUA->PushNumber(eye_data_v2.timestamp);
    LUA->SetField(-2, "timestamp");
    LUA->PushVector(*(Vector*)&eye_data_v2.verbose_data.left.gaze_direction_normalized);
    LUA->SetField(-2, "gaze_direction");
    LUA->PushVector(*(Vector*)&eye_data_v2.verbose_data.left.gaze_origin_mm);
    LUA->SetField(-2, "gaze_origin_mm");
    LUA->PushNumber(eye_data_v2.verbose_data.left.pupil_diameter_mm);
    LUA->SetField(-2, "pupil_diameter_mm");
    LUA->PushNumber(eye_data_v2.verbose_data.left.eye_openness);
    LUA->SetField(-2, "eye_openness");
    LUA->PushNumber(eye_data_v2.expression_data.left.eye_wide);
    LUA->SetField(-2, "eye_wide");
    LUA->PushNumber(eye_data_v2.expression_data.left.eye_squeeze);
    LUA->SetField(-2, "eye_squeeze");
    LUA->PushNumber(eye_data_v2.expression_data.left.eye_frown);
    LUA->SetField(-2, "eye_frown");
    LUA->ReferencePush(g_luaRefs[LuaRefIndex_RightEyeDataTable]);
    LUA->PushVector(*(Vector*)&eye_data_v2.verbose_data.right.gaze_direction_normalized);
    LUA->SetField(-2, "gaze_direction");
    LUA->PushVector(*(Vector*)&eye_data_v2.verbose_data.right.gaze_origin_mm);
    LUA->SetField(-2, "gaze_origin_mm");
    LUA->PushNumber(eye_data_v2.verbose_data.right.pupil_diameter_mm);
    LUA->SetField(-2, "pupil_diameter_mm");
    LUA->PushNumber(eye_data_v2.verbose_data.right.eye_openness);
    LUA->SetField(-2, "eye_openness");
    LUA->PushNumber(eye_data_v2.expression_data.right.eye_wide);
    LUA->SetField(-2, "eye_wide");
    LUA->PushNumber(eye_data_v2.expression_data.right.eye_squeeze);
    LUA->SetField(-2, "eye_squeeze");
    LUA->PushNumber(eye_data_v2.expression_data.right.eye_frown);
    LUA->SetField(-2, "eye_frown");
    return 2;
}
#endif

void LuaPrint(GarrysMod::Lua::ILuaBase* LUA, const char* msg) {
    LUA->PushSpecial(GarrysMod::Lua::SPECIAL_GLOB);
    LUA->GetField(-1, "print");
    LUA->PushString(msg);
    LUA->Call(1, 0);
    LUA->Pop(1);
}

LUA_FUNCTION(GetVersion) {
    LUA->PushNumber(20);
    return 1;
}

LUA_FUNCTION(GetSemiVersion) {
    LUA->PushNumber(103);
    return 1;
}

LUA_FUNCTION(IsHMDPresent) {
    LUA->PushBool(vr::VR_IsHmdPresent());
    return 1;
}

LUA_FUNCTION(Init) {
    if (g_pSystem != NULL)
        LUA->ThrowError("Already initialized");
    vr::HmdError error = vr::VRInitError_None;
    g_pSystem = vr::VR_Init(&error, vr::VRApplication_Scene);
    if (error != vr::VRInitError_None)
        LUA->ThrowError(vr::VR_GetVRInitErrorAsEnglishDescription(error));
    if (!vr::VRCompositor())
        LUA->ThrowError("VRCompositor failed");
    for(int i = 0; i < LuaRefIndex_Max; i++){
        LUA->CreateTable();
        g_luaRefs[i] = LUA->ReferenceCreate();
        g_luaRefCount++;
    }
#ifdef _WIN32
    HMODULE hMod = GetModuleHandleA("shaderapidx9.dll");
    if (hMod == NULL) LUA->ThrowError("GetModuleHandleA failed");
    CreateInterfaceFn CreateInterface = (CreateInterfaceFn)GetProcAddress(hMod, "CreateInterface");
    if (CreateInterface == NULL) LUA->ThrowError("GetProcAddress failed");
# ifdef _WIN64
    DWORD_PTR fnAddr = ((DWORD_PTR**)CreateInterface("ShaderDevice001", NULL))[0][5];
    g_pD3D9Device = *(IDirect3DDevice9**)(fnAddr + 8 + (*(DWORD_PTR*)(fnAddr + 3) & 0xFFFFFFFF));
# else
    g_pD3D9Device = **(IDirect3DDevice9***)(((DWORD_PTR**)CreateInterface("ShaderDevice001", NULL))[0][5] + 2);
# endif
    g_createTexture = ((CreateTexture**)g_pD3D9Device)[0][23];
#else
# ifdef __x86_64__
    void *lib = dlopen("libtogl_client.so", RTLD_NOW | RTLD_NOLOAD);
# else
    void *lib = dlopen("libtogl.so", RTLD_NOW | RTLD_NOLOAD);
# endif
    if(lib==NULL) {
        const char *dlErr = dlerror();
        char errBuf[512];
        snprintf(errBuf, sizeof(errBuf), "[VRMod] dlopen libtogl failed: %s", dlErr ? dlErr : "unknown");
        LUA->ThrowError(errBuf);
    }
    GetOpenGLEntryPoints_t GetOpenGLEntryPoints = (GetOpenGLEntryPoints_t)dlsym(lib, "GetOpenGLEntryPoints");
    if(GetOpenGLEntryPoints==NULL) {
        const char *dlErr = dlerror();
        char errBuf[512];
        snprintf(errBuf, sizeof(errBuf), "[VRMod] dlsym GetOpenGLEntryPoints failed: %s", dlErr ? dlErr : "unknown");
        dlclose(lib);
        LUA->ThrowError(errBuf);
    }
    g_GL = GetOpenGLEntryPoints(NULL);
    dlclose(lib);
    if(g_GL == NULL)
        LUA->ThrowError("[VRMod] GetOpenGLEntryPoints returned NULL");
# ifdef __x86_64__
    g_createTexture = *((void**)&g_GL->firstFunc+50);
# else
    g_createTexture = *((void**)&g_GL->firstFunc+48);
# endif
    if(g_createTexture == NULL)
        LUA->ThrowError("[VRMod] Failed to get glGenTextures entry point (NULL at expected offset)");
#endif
    return 0;
}

LUA_FUNCTION(SetActionManifest) {
    const char* fileName = LUA->CheckString(1);
    char path[PATH_MAX];
    char currentDir[PATH_MAX];
#ifdef _WIN32
    GetCurrentDirectory(PATH_MAX, currentDir);
#else
    if(getcwd(currentDir, PATH_MAX) == NULL)
        LUA->ThrowError("getcwd failed");
#endif
    if (snprintf(path, PATH_MAX, "%s/garrysmod/data/%s", currentDir, fileName) >= PATH_MAX)
        LUA->ThrowError("SetActionManifest path too long");

    // Debug: print resolved path so users can diagnose path issues
    char debugMsg[PATH_MAX + 64];
    snprintf(debugMsg, sizeof(debugMsg), "[VRMod] Action manifest path: %s", path);
    LuaPrint(LUA, debugMsg);

    g_pInput = vr::VRInput();
    vr::EVRInputError inputError = g_pInput->SetActionManifestPath(path);
    if (inputError != vr::VRInputError_None) {
        snprintf(g_errorString, MAX_STR_LEN, "SetActionManifestPath failed (error %d) for: %s", (int)inputError, path);
        LUA->ThrowError(g_errorString);
    }
    FILE* file = fopen(path, "r");
    if (file == NULL) {
        snprintf(g_errorString, MAX_STR_LEN, "Failed to open action manifest at: %s", path);
        LUA->ThrowError(g_errorString);
    }
    memset(g_actions, 0, sizeof(g_actions));
    char word[MAX_STR_LEN];
    char fmt1[MAX_STR_LEN], fmt2[MAX_STR_LEN];
    snprintf(fmt1, MAX_STR_LEN, "%%*[^\"]\"%%%i[^\"]\"", MAX_STR_LEN-1);
    snprintf(fmt2, MAX_STR_LEN, "%%%i[^\"]\"", MAX_STR_LEN-1);
    while (fscanf(file, fmt1, word) == 1 && strcmp(word, "actions") != 0);
    while (fscanf(file, fmt2, word) == 1) {
        if (strchr(word, ']') != nullptr)
            break;
        if (strcmp(word, "name") == 0) {
            if (fscanf(file, fmt1, g_actions[g_actionCount].fullname) != 1)
                break;
            g_actions[g_actionCount].name = g_actions[g_actionCount].fullname;
            for (unsigned int i = 0; i < strlen(g_actions[g_actionCount].fullname); i++) {
                if (g_actions[g_actionCount].fullname[i] == '/')
                    g_actions[g_actionCount].name = g_actions[g_actionCount].fullname + i + 1;
            }
            g_pInput->GetActionHandle(g_actions[g_actionCount].fullname, &(g_actions[g_actionCount].handle));
        }
        if (strcmp(word, "type") == 0) {
            char typeStr[MAX_STR_LEN] = {0};
            if (fscanf(file, fmt1, typeStr) != 1)
                break;
            if (strcmp(typeStr, "boolean") == 0)        g_actions[g_actionCount].type = ActionType_Boolean;
            else if (strcmp(typeStr, "vector1") == 0)  g_actions[g_actionCount].type = ActionType_Vector1;
            else if (strcmp(typeStr, "vector2") == 0)  g_actions[g_actionCount].type = ActionType_Vector2;
            else if (strcmp(typeStr, "pose") == 0)     g_actions[g_actionCount].type = ActionType_Pose;
            else if (strcmp(typeStr, "skeleton") == 0)  g_actions[g_actionCount].type = ActionType_Skeleton;
            else if (strcmp(typeStr, "vibration") == 0) g_actions[g_actionCount].type = ActionType_Vibration;
        }
        if (g_actions[g_actionCount].fullname[0] && g_actions[g_actionCount].type) {
            for(int i = 0; i < 2; i++){
                LUA->CreateTable();
                g_actions[g_actionCount].luaRefs[i] = LUA->ReferenceCreate();
            }
            g_actionCount++;
            if (g_actionCount == MAX_ACTIONS)
                break;
        }
    }
    fclose(file);
    return 0;
}

LUA_FUNCTION(SetActiveActionSets) {
    g_activeActionSetCount = 0;
    for (int i = 0; i < MAX_ACTIONSETS; i++) {
        if (LUA->GetType(i + 1) == GarrysMod::Lua::Type::STRING) {
            const char* actionSetName = LUA->CheckString(i + 1);
            int actionSetIndex = -1;
            for (int j = 0; j < g_actionSetCount; j++) {
                if (strcmp(actionSetName, g_actionSets[j].name) == 0) {
                    actionSetIndex = j;
                    break;
                }
            }
            if (actionSetIndex == -1) {
                g_pInput->GetActionSetHandle(actionSetName, &g_actionSets[g_actionSetCount].handle);
                memcpy(g_actionSets[g_actionSetCount].name, actionSetName, strlen(actionSetName));
                actionSetIndex = g_actionSetCount;
                g_actionSetCount++;
            }
            g_activeActionSets[g_activeActionSetCount].ulActionSet = g_actionSets[actionSetIndex].handle;
            g_activeActionSetCount++;
        }
        else {
            break;
        }
    }
    return 0;
}

void PushMatrixAsTable(GarrysMod::Lua::ILuaBase* LUA, float* mtx, unsigned int rows, unsigned int cols) {
    LUA->CreateTable();
    for (unsigned int row = 0; row < rows; row++) {
        LUA->PushNumber(row + 1);
        LUA->CreateTable();
        for (unsigned int col = 0; col < cols; col++) {
            LUA->PushNumber(col+1);
            LUA->PushNumber(mtx[row * cols + col]);
            LUA->SetTable(-3);
        }
        LUA->SetTable(-3);
    }
}

LUA_FUNCTION(GetDisplayInfo) {
    float fNearZ = (float)LUA->CheckNumber(1);
    float fFarZ = (float)LUA->CheckNumber(2);
    uint32_t recommendedWidth = 0;
    uint32_t recommendedHeight = 0;
    g_pSystem->GetRecommendedRenderTargetSize(&recommendedWidth, &recommendedHeight);
    vr::HmdMatrix44_t projLeft = g_pSystem->GetProjectionMatrix(vr::Hmd_Eye::Eye_Left, fNearZ, fFarZ);
    vr::HmdMatrix44_t projRight = g_pSystem->GetProjectionMatrix(vr::Hmd_Eye::Eye_Right, fNearZ, fFarZ);
    vr::HmdMatrix34_t transformLeft = g_pSystem->GetEyeToHeadTransform(vr::Eye_Left);
    vr::HmdMatrix34_t transformRight = g_pSystem->GetEyeToHeadTransform(vr::Eye_Right);
    LUA->CreateTable();
    PushMatrixAsTable(LUA, (float*)&projLeft, 4, 4);
    LUA->SetField(-2, "ProjectionLeft");
    PushMatrixAsTable(LUA, (float*)&projRight, 4, 4);
    LUA->SetField(-2, "ProjectionRight");
    PushMatrixAsTable(LUA, (float*)&transformLeft, 3, 4);
    LUA->SetField(-2, "TransformLeft");
    PushMatrixAsTable(LUA, (float*)&transformRight, 3, 4);
    LUA->SetField(-2, "TransformRight");
    LUA->PushNumber(recommendedWidth);
    LUA->SetField(-2, "RecommendedWidth");
    LUA->PushNumber(recommendedHeight);
    LUA->SetField(-2, "RecommendedHeight");
    return 1;
}

LUA_FUNCTION(UpdatePosesAndActions) {
    vr::VRCompositor()->WaitGetPoses(g_poses, vr::k_unMaxTrackedDeviceCount, NULL, 0);
    g_pInput->UpdateActionState(g_activeActionSets, sizeof(vr::VRActiveActionSet_t), g_activeActionSetCount);
    return 0;
}

LUA_FUNCTION(GetPoses) {
    vr::InputPoseActionData_t poseActionData;
    vr::TrackedDevicePose_t pose = g_poses[0];
    char* poseName = (char*)"hmd";
    int poseRef = g_luaRefs[LuaRefIndex_HmdPose];
    LUA->ReferencePush(g_luaRefs[LuaRefIndex_PoseTable]);
    for (int i = -1; i < g_actionCount; i++) {
        if (i != -1){
            if (g_actions[i].type == ActionType_Pose) {
                g_pInput->GetPoseActionData(g_actions[i].handle, vr::TrackingUniverseStanding, 0, &poseActionData, sizeof(poseActionData), vr::k_ulInvalidInputValueHandle);
                pose = poseActionData.pose;
                poseName = g_actions[i].name;
                poseRef = g_actions[i].luaRefs[0];
            } else continue;
        }
        if (pose.bPoseIsValid) {
            vr::HmdMatrix34_t mat = pose.mDeviceToAbsoluteTracking;
            Vector pos;
            Vector vel;
            QAngle ang;
            QAngle angvel;
            pos.x = -mat.m[2][3];
            pos.y = -mat.m[0][3];
            pos.z = mat.m[1][3];
            ang.x = asinf(mat.m[1][2]) * (180.0f / PI_F);
            ang.y = atan2f(mat.m[0][2], mat.m[2][2]) * (180.0f / PI_F);
            ang.z = atan2f(-mat.m[1][0], mat.m[1][1]) * (180.0f / PI_F);
            vel.x = -pose.vVelocity.v[2];
            vel.y = -pose.vVelocity.v[0];
            vel.z = pose.vVelocity.v[1];
            angvel.x = -pose.vAngularVelocity.v[2] * (180.0f / PI_F);
            angvel.y = -pose.vAngularVelocity.v[0] * (180.0f / PI_F);
            angvel.z = pose.vAngularVelocity.v[1] * (180.0f / PI_F);
            LUA->ReferencePush(poseRef);
            LUA->PushVector(pos);
            LUA->SetField(-2, "pos");
            LUA->PushVector(vel);
            LUA->SetField(-2, "vel");
            LUA->PushAngle(ang);
            LUA->SetField(-2, "ang");
            LUA->PushAngle(angvel);
            LUA->SetField(-2, "angvel");
            LUA->SetField(-2, poseName);
        }
    }
    return 1;
}

LUA_FUNCTION(GetActions) {
    vr::InputDigitalActionData_t digitalActionData;
    vr::InputAnalogActionData_t analogActionData;
    vr::VRSkeletalSummaryData_t skeletalSummaryData;
    char* changedActionNames[MAX_ACTIONS];
    bool changedActionStates[MAX_ACTIONS];
    int changedActionCount = 0;
    LUA->ReferencePush(g_luaRefs[LuaRefIndex_ActionTable]);
    for (int i = 0; i < g_actionCount; i++) {
        if (g_actions[i].type == ActionType_Boolean) {
            LUA->PushBool((g_pInput->GetDigitalActionData(g_actions[i].handle, &digitalActionData, sizeof(digitalActionData), vr::k_ulInvalidInputValueHandle) == vr::VRInputError_None && digitalActionData.bState));
            LUA->SetField(-2, g_actions[i].name);
            if(digitalActionData.bChanged){
                changedActionNames[changedActionCount] = g_actions[i].name;
                changedActionStates[changedActionCount] = digitalActionData.bState;
                changedActionCount++;
            }
        }
        else if (g_actions[i].type == ActionType_Vector1) {
            g_pInput->GetAnalogActionData(g_actions[i].handle, &analogActionData, sizeof(analogActionData), vr::k_ulInvalidInputValueHandle);
            LUA->PushNumber(analogActionData.x);
            LUA->SetField(-2, g_actions[i].name);
        }
        else if (g_actions[i].type == ActionType_Vector2) {
            LUA->ReferencePush(g_actions[i].luaRefs[0]);
            g_pInput->GetAnalogActionData(g_actions[i].handle, &analogActionData, sizeof(analogActionData), vr::k_ulInvalidInputValueHandle);
            LUA->PushNumber(analogActionData.x);
            LUA->SetField(-2, "x");
            LUA->PushNumber(analogActionData.y);
            LUA->SetField(-2, "y");
            LUA->SetField(-2, g_actions[i].name);
        }
        else if (g_actions[i].type == ActionType_Skeleton) {
            g_pInput->GetSkeletalSummaryData(g_actions[i].handle, &skeletalSummaryData);
            LUA->ReferencePush(g_actions[i].luaRefs[0]);
            LUA->ReferencePush(g_actions[i].luaRefs[1]);
            for (int j = 0; j < 5; j++) {
                LUA->PushNumber(j + 1);
                LUA->PushNumber(skeletalSummaryData.flFingerCurl[j]);
                LUA->SetTable(-3);
            }
            LUA->SetField(-2, "fingerCurls");
            LUA->SetField(-2, g_actions[i].name);
        }
    }
    if (changedActionCount == 0){
        LUA->ReferencePush(g_luaRefs[LuaRefIndex_EmptyTable]);
    }else{
        LUA->CreateTable();
        for(int i = 0; i < changedActionCount; i++){
            LUA->PushBool(changedActionStates[i]);
            LUA->SetField(-2,changedActionNames[i]);
        }
    }
    return 2;
}

LUA_FUNCTION(ShareTextureBegin) {
    char patch[] = "\x68\x0\x0\x0\x0\xC3\x44\x24\x04\x0\x0\x0\x0\xC3";
    *(uint32_t*)(patch + 1) = (uint32_t)((uintptr_t)CreateTextureHook);
#if defined _WIN64 || defined __x86_64__
    patch[5] = '\xC7';
    *(uint32_t*)(patch + 9) = (uint32_t)((uintptr_t)CreateTextureHook >> 32);
#endif
#ifdef _WIN32
    if (ReadProcessMemory(GetCurrentProcess(), g_createTexture, g_createTextureOrigBytes, 14, NULL) == 0)
        LUA->ThrowError("ReadProcessMemory failed");
    if (WriteProcessMemory(GetCurrentProcess(), g_createTexture, patch, 14, NULL) == 0)
        LUA->ThrowError("WriteProcessMemory failed");
#else
    uintptr_t pageSize = (uintptr_t)getpagesize();
    uintptr_t startAddr = (uintptr_t)g_createTexture;
    uintptr_t alignedAddr = startAddr & ~(pageSize - 1);
    size_t protectLen = ((startAddr + 14) - alignedAddr + pageSize - 1) & ~(pageSize - 1);
    if(mprotect((void*)alignedAddr, protectLen, PROT_READ | PROT_WRITE | PROT_EXEC) == -1) {
        int savedErrno = errno;
        char errBuf[256];
        snprintf(errBuf, sizeof(errBuf), "[VRMod] mprotect failed: errno=%d addr=%p len=%lu", savedErrno, (void*)alignedAddr, (unsigned long)protectLen);
        LUA->ThrowError(errBuf);
    }
    memcpy((void*)g_createTextureOrigBytes, (void*)g_createTexture, 14);
    memcpy((void*)g_createTexture, (void*)patch, 14);
#endif
    return 0;
}

LUA_FUNCTION(ShareTextureFinish) {
#ifdef _WIN32
    if (g_sharedTexture == NULL)
        LUA->ThrowError("g_sharedTexture is null");
    if (D3D11CreateDevice(NULL, D3D_DRIVER_TYPE_HARDWARE, NULL, 0, NULL, NULL, D3D11_SDK_VERSION, &g_d3d11Device, NULL, NULL) != S_OK)
        LUA->ThrowError("D3D11CreateDevice failed");
    ID3D11Resource* res;
    if (FAILED(g_d3d11Device->OpenSharedResource(g_sharedTexture, __uuidof(ID3D11Resource), (void**)&res)))
        LUA->ThrowError("OpenSharedResource failed");
    if (FAILED(res->QueryInterface(__uuidof(ID3D11Texture2D), (void**)&g_d3d11Texture)))
        LUA->ThrowError("QueryInterface failed");
    g_vrTexture.handle = g_d3d11Texture;
    g_vrTexture.eType = vr::TextureType_DirectX;
#else
    if (g_sharedTexture == GL_INVALID_VALUE)
        LUA->ThrowError("g_sharedTexture is invalid");
    g_vrTexture.handle = (void*)(uintptr_t)g_sharedTexture;
    g_vrTexture.eType = vr::TextureType_OpenGL;
#endif
    g_vrTexture.eColorSpace = vr::ColorSpace_Auto;
    return 0;
}

LUA_FUNCTION(SetSubmitTextureBounds) {
    g_textureBoundsLeft.uMin = (float)LUA->CheckNumber(1);
    g_textureBoundsLeft.vMin = (float)LUA->CheckNumber(2);
    g_textureBoundsLeft.uMax = (float)LUA->CheckNumber(3);
    g_textureBoundsLeft.vMax = (float)LUA->CheckNumber(4);
    g_textureBoundsRight.uMin = (float)LUA->CheckNumber(5);
    g_textureBoundsRight.vMin = (float)LUA->CheckNumber(6);
    g_textureBoundsRight.uMax = (float)LUA->CheckNumber(7);
    g_textureBoundsRight.vMax = (float)LUA->CheckNumber(8);
    return 0;
}

LUA_FUNCTION(SubmitSharedTexture) {
#ifdef _WIN32
    if (g_d3d11Texture == NULL)
        return 0;
    IDirect3DQuery9* pEventQuery = nullptr;
    g_pD3D9Device->CreateQuery(D3DQUERYTYPE_EVENT, &pEventQuery);
    if (pEventQuery != nullptr)
    {
        pEventQuery->Issue(D3DISSUE_END);
        while (pEventQuery->GetData(nullptr, 0, D3DGETDATA_FLUSH) != S_OK);
        pEventQuery->Release();
    }
#endif
    vr::VRCompositor()->Submit(vr::EVREye::Eye_Left, &g_vrTexture, &g_textureBoundsLeft);
    vr::VRCompositor()->Submit(vr::EVREye::Eye_Right, &g_vrTexture, &g_textureBoundsRight);
    return 0;
}

LUA_FUNCTION(Shutdown) {
    // Destroy all overlays before VR shutdown
    if (vr::VROverlay()) {
        for (int i = 0; i < g_overlayCount; i++)
            vr::VROverlay()->DestroyOverlay(g_overlays[i]);
    }
    g_overlayCount = 0;

    if (g_pSystem != NULL) {
        vr::VR_Shutdown();
        g_pSystem = NULL;
    }
    for(int i = 0; i < g_luaRefCount; i++)
        LUA->ReferenceFree(g_luaRefs[i]);
    g_luaRefCount = 0;
    for(int i = 0; i < g_actionCount; i++)
        for(int j = 0; j < 2; j++)
            LUA->ReferenceFree(g_actions[i].luaRefs[j]);
    g_actionCount = 0;
    g_actionSetCount = 0;
    g_activeActionSetCount = 0;
    g_captureTarget = 0;
#ifdef _WIN32
    if (g_overlayD3D11Texture != NULL) {
        g_overlayD3D11Texture->Release();
        g_overlayD3D11Texture = NULL;
    }
    g_overlaySharedTexture = NULL;
    if (g_d3d11Device != NULL) {
        g_d3d11Device->Release();
        g_d3d11Device = NULL;
    }
    g_d3d11Texture = NULL;
    g_pD3D9Device = NULL;
    g_sharedTexture = NULL;
    g_gameHWND = NULL;
#else
    g_sharedTexture = GL_INVALID_VALUE;
    g_overlaySharedTexture_GL = GL_INVALID_VALUE;
#endif
    memset(&g_overlayVrTexture, 0, sizeof(g_overlayVrTexture));
#ifdef VRMOD_USE_SRANIPAL
    SRanipalLipInitialized = false;
    SRanipalEyeInitialized = false;
    ViveSR::anipal::Release(ViveSR::anipal::Lip::ANIPAL_TYPE_LIP_V2);
    ViveSR::anipal::Release(ViveSR::anipal::Eye::ANIPAL_TYPE_EYE_V2);
    if(SRanipalThreadHandle != NULL){
        CloseHandle(SRanipalThreadHandle);
        SRanipalThreadHandle = NULL;
    }
#endif
    return 0;
}

LUA_FUNCTION(TriggerHaptic) {
    const char* actionName = LUA->CheckString(1);
    for (int i = 0; i < g_actionCount; i++) {
        if (strcmp(g_actions[i].name, actionName) == 0) {
            g_pInput->TriggerHapticVibrationAction(g_actions[i].handle, (float)LUA->CheckNumber(2), (float)LUA->CheckNumber(3), (float)LUA->CheckNumber(4), (float)LUA->CheckNumber(5), vr::k_ulInvalidInputValueHandle);
            break;
        }
    }
    return 0;
}

LUA_FUNCTION(GetTrackedDeviceNames) {
    LUA->CreateTable();
    int tableIndex = 1;
    char name[MAX_STR_LEN];
    for (int i = 0; i < vr::k_unMaxTrackedDeviceCount; i++) {
        if (g_pSystem->GetStringTrackedDeviceProperty(i, vr::Prop_ControllerType_String, name, MAX_STR_LEN) > 1) {
            LUA->PushNumber(tableIndex);
            LUA->PushString(name);
            LUA->SetTable(-3);
            tableIndex++;
        }
    }
    return 1;
}

#ifdef _WIN32
static HWND GetGameHWNDInternal() {
    if (g_gameHWND != NULL) return g_gameHWND;
    if (g_pD3D9Device != NULL) {
        D3DDEVICE_CREATION_PARAMETERS params;
        if (SUCCEEDED(g_pD3D9Device->GetCreationParameters(&params)) && params.hFocusWindow != NULL) {
            g_gameHWND = params.hFocusWindow;
            return g_gameHWND;
        }
    }
    g_gameHWND = FindWindowA("Valve001", NULL);
    return g_gameHWND;
}

LUA_FUNCTION(GetGameHWND) {
    HWND hwnd = GetGameHWNDInternal();
    if (hwnd == NULL) {
        LUA->PushBool(false);
        return 1;
    }
    LUA->PushNumber((double)(uintptr_t)hwnd);
    return 1;
}

LUA_FUNCTION(SendKeyEvent) {
    HWND hwnd = GetGameHWNDInternal();
    if (hwnd == NULL) {
        LUA->PushBool(false);
        LUA->PushString("HWND not available");
        return 2;
    }
    int vk = (int)LUA->CheckNumber(1);
    bool pressed = LUA->GetBool(2);
    if (vk < 0 || vk > 254) {
        LUA->PushBool(false);
        LUA->PushString("Invalid VK code");
        return 2;
    }
    UINT scanCode = MapVirtualKeyA(vk, MAPVK_VK_TO_VSC);
    LPARAM lParam;
    bool extended = (vk == VK_RCONTROL || vk == VK_RMENU ||
        vk == VK_INSERT || vk == VK_DELETE || vk == VK_HOME || vk == VK_END ||
        vk == VK_PRIOR || vk == VK_NEXT ||
        vk == VK_LEFT || vk == VK_RIGHT || vk == VK_UP || vk == VK_DOWN);
    if (pressed) {
        lParam = 1 | (scanCode << 16);
        if (extended) lParam |= (1 << 24);
    } else {
        lParam = 1 | (scanCode << 16) | (1 << 30) | ((LPARAM)1 << 31);
        if (extended) lParam |= (1 << 24);
    }
    PostMessageA(hwnd, pressed ? WM_KEYDOWN : WM_KEYUP, (WPARAM)vk, lParam);
    LUA->PushBool(true);
    return 1;
}

LUA_FUNCTION(DebugGetAsyncKeyState) {
    int vk = (int)LUA->CheckNumber(1);
    SHORT state = GetAsyncKeyState(vk);
    LUA->PushBool((state & 0x8000) != 0);
    return 1;
}
#endif

// =========================================================================
// B4+B5: Event Polling + Device Properties (v103)
// =========================================================================

LUA_FUNCTION(PollNextEvent) {
    if (g_pSystem == NULL) { LUA->PushBool(false); return 1; }
    vr::VREvent_t event;
    if (!g_pSystem->PollNextEvent(&event, sizeof(event))) {
        LUA->PushBool(false);
        return 1;
    }
    LUA->CreateTable();
    LUA->PushNumber(event.eventType);
    LUA->SetField(-2, "type");
    LUA->PushNumber(event.trackedDeviceIndex);
    LUA->SetField(-2, "deviceIndex");
    LUA->PushNumber(event.eventAgeSeconds);
    LUA->SetField(-2, "age");
    return 1;
}

LUA_FUNCTION(IsTrackedDeviceConnected) {
    if (g_pSystem == NULL) { LUA->PushBool(false); return 1; }
    LUA->PushBool(g_pSystem->IsTrackedDeviceConnected(
        (vr::TrackedDeviceIndex_t)(int)LUA->CheckNumber(1)));
    return 1;
}

LUA_FUNCTION(GetTrackedDeviceClass) {
    if (g_pSystem == NULL) { LUA->PushNumber(0); return 1; }
    LUA->PushNumber((int)g_pSystem->GetTrackedDeviceClass(
        (vr::TrackedDeviceIndex_t)(int)LUA->CheckNumber(1)));
    return 1;
}

LUA_FUNCTION(GetFloatTrackedDeviceProperty) {
    if (g_pSystem == NULL) { LUA->PushBool(false); return 1; }
    vr::ETrackedPropertyError err;
    float val = g_pSystem->GetFloatTrackedDeviceProperty(
        (vr::TrackedDeviceIndex_t)(int)LUA->CheckNumber(1),
        (vr::ETrackedDeviceProperty)(int)LUA->CheckNumber(2), &err);
    if (err != vr::TrackedProp_Success) { LUA->PushBool(false); return 1; }
    LUA->PushNumber(val);
    return 1;
}

LUA_FUNCTION(GetInt32TrackedDeviceProperty) {
    if (g_pSystem == NULL) { LUA->PushBool(false); return 1; }
    vr::ETrackedPropertyError err;
    int32_t val = g_pSystem->GetInt32TrackedDeviceProperty(
        (vr::TrackedDeviceIndex_t)(int)LUA->CheckNumber(1),
        (vr::ETrackedDeviceProperty)(int)LUA->CheckNumber(2), &err);
    if (err != vr::TrackedProp_Success) { LUA->PushBool(false); return 1; }
    LUA->PushNumber(val);
    return 1;
}

LUA_FUNCTION(GetStringTrackedDeviceProperty) {
    if (g_pSystem == NULL) { LUA->PushBool(false); return 1; }
    char buf[MAX_STR_LEN];
    vr::ETrackedPropertyError err;
    g_pSystem->GetStringTrackedDeviceProperty(
        (vr::TrackedDeviceIndex_t)(int)LUA->CheckNumber(1),
        (vr::ETrackedDeviceProperty)(int)LUA->CheckNumber(2),
        buf, MAX_STR_LEN, &err);
    if (err != vr::TrackedProp_Success) { LUA->PushBool(false); return 1; }
    LUA->PushString(buf);
    return 1;
}

LUA_FUNCTION(ShouldApplicationPause) {
    if (g_pSystem == NULL) { LUA->PushBool(false); return 1; }
    LUA->PushBool(g_pSystem->ShouldApplicationPause());
    return 1;
}

LUA_FUNCTION(ShouldApplicationReduceRenderingWork) {
    if (g_pSystem == NULL) { LUA->PushBool(false); return 1; }
    LUA->PushBool(g_pSystem->ShouldApplicationReduceRenderingWork());
    return 1;
}

// =========================================================================
// B3: Frame Timing + Performance (v103)
// =========================================================================

LUA_FUNCTION(GetFrameTiming) {
    if (!vr::VRCompositor()) { LUA->PushBool(false); return 1; }
    vr::Compositor_FrameTiming timing;
    timing.m_nSize = sizeof(vr::Compositor_FrameTiming);
    uint32_t framesAgo = 0;
    if (LUA->IsType(1, GarrysMod::Lua::Type::NUMBER))
        framesAgo = (uint32_t)LUA->CheckNumber(1);
    if (!vr::VRCompositor()->GetFrameTiming(&timing, framesAgo)) {
        LUA->PushBool(false);
        return 1;
    }
    LUA->CreateTable();
    LUA->PushNumber(timing.m_nFrameIndex);              LUA->SetField(-2, "frameIndex");
    LUA->PushNumber(timing.m_nNumFramePresents);        LUA->SetField(-2, "framePresents");
    LUA->PushNumber(timing.m_nNumMisPresented);         LUA->SetField(-2, "misPresented");
    LUA->PushNumber(timing.m_nNumDroppedFrames);        LUA->SetField(-2, "droppedFrames");
    LUA->PushNumber(timing.m_nReprojectionFlags);       LUA->SetField(-2, "reprojectionFlags");
    LUA->PushNumber(timing.m_flPreSubmitGpuMs);         LUA->SetField(-2, "preSubmitGpuMs");
    LUA->PushNumber(timing.m_flPostSubmitGpuMs);        LUA->SetField(-2, "postSubmitGpuMs");
    LUA->PushNumber(timing.m_flTotalRenderGpuMs);       LUA->SetField(-2, "totalRenderGpuMs");
    LUA->PushNumber(timing.m_flCompositorRenderGpuMs);  LUA->SetField(-2, "compositorGpuMs");
    LUA->PushNumber(timing.m_flCompositorRenderCpuMs);  LUA->SetField(-2, "compositorCpuMs");
    LUA->PushNumber(timing.m_flCompositorIdleCpuMs);    LUA->SetField(-2, "compositorIdleCpuMs");
    LUA->PushNumber(timing.m_flClientFrameIntervalMs);  LUA->SetField(-2, "clientFrameIntervalMs");
    LUA->PushNumber(timing.m_flPresentCallCpuMs);       LUA->SetField(-2, "presentCallCpuMs");
    LUA->PushNumber(timing.m_flWaitForPresentCpuMs);    LUA->SetField(-2, "waitForPresentCpuMs");
    LUA->PushNumber(timing.m_flSubmitFrameMs);          LUA->SetField(-2, "submitFrameMs");
    return 1;
}

LUA_FUNCTION(GetFrameTimeRemaining) {
    if (!vr::VRCompositor()) { LUA->PushNumber(0); return 1; }
    LUA->PushNumber(vr::VRCompositor()->GetFrameTimeRemaining());
    return 1;
}

LUA_FUNCTION(IsMotionSmoothingEnabled) {
    if (!vr::VRCompositor()) { LUA->PushBool(false); return 1; }
    LUA->PushBool(vr::VRCompositor()->IsMotionSmoothingEnabled());
    return 1;
}

LUA_FUNCTION(FadeToColor) {
    if (!vr::VRCompositor()) return 0;
    vr::VRCompositor()->FadeToColor(
        (float)LUA->CheckNumber(1),
        (float)LUA->CheckNumber(2),
        (float)LUA->CheckNumber(3),
        (float)LUA->CheckNumber(4),
        (float)LUA->CheckNumber(5),
        LUA->GetBool(6));
    return 0;
}

LUA_FUNCTION(VRSuspendRendering) {
    if (!vr::VRCompositor()) return 0;
    vr::VRCompositor()->SuspendRendering(LUA->GetBool(1));
    return 0;
}

// =========================================================================
// B1: Full Skeletal Bone Data (v103)
// =========================================================================

LUA_FUNCTION(GetSkeletalBoneData) {
    if (g_pInput == NULL) { LUA->PushBool(false); return 1; }
    const char* actionName = LUA->CheckString(1);
    int motionRange = 0;
    if (LUA->IsType(2, GarrysMod::Lua::Type::NUMBER))
        motionRange = (int)LUA->CheckNumber(2);

    // Find skeleton action handle
    vr::VRActionHandle_t handle = vr::k_ulInvalidActionHandle;
    for (int i = 0; i < g_actionCount; i++) {
        if (g_actions[i].type == ActionType_Skeleton && strcmp(g_actions[i].name, actionName) == 0) {
            handle = g_actions[i].handle;
            break;
        }
    }
    if (handle == vr::k_ulInvalidActionHandle) { LUA->PushBool(false); return 1; }

    vr::VRBoneTransform_t bones[31];
    vr::EVRInputError err = g_pInput->GetSkeletalBoneData(handle,
        vr::VRSkeletalTransformSpace_Model,
        (vr::EVRSkeletalMotionRange)motionRange, bones, 31);
    if (err != vr::VRInputError_None) { LUA->PushBool(false); return 1; }

    LUA->CreateTable();
    for (int i = 0; i < 31; i++) {
        LUA->PushNumber(i);
        LUA->CreateTable();
        // position (HmdVector4_t: x,y,z,w)
        LUA->PushNumber(bones[i].position.v[0]); LUA->SetField(-2, "px");
        LUA->PushNumber(bones[i].position.v[1]); LUA->SetField(-2, "py");
        LUA->PushNumber(bones[i].position.v[2]); LUA->SetField(-2, "pz");
        // orientation (HmdQuaternionf_t: w,x,y,z)
        LUA->PushNumber(bones[i].orientation.w);  LUA->SetField(-2, "rw");
        LUA->PushNumber(bones[i].orientation.x);  LUA->SetField(-2, "rx");
        LUA->PushNumber(bones[i].orientation.y);  LUA->SetField(-2, "ry");
        LUA->PushNumber(bones[i].orientation.z);  LUA->SetField(-2, "rz");
        LUA->SetTable(-3);
    }
    return 1;
}

// =========================================================================
// A1: IVROverlay - Overlay System (v103)
// =========================================================================

LUA_FUNCTION(ShareOverlayTextureBegin) {
    g_captureTarget = 1;
    char patch[] = "\x68\x0\x0\x0\x0\xC3\x44\x24\x04\x0\x0\x0\x0\xC3";
    *(uint32_t*)(patch + 1) = (uint32_t)((uintptr_t)CreateTextureHook);
#if defined _WIN64 || defined __x86_64__
    patch[5] = '\xC7';
    *(uint32_t*)(patch + 9) = (uint32_t)((uintptr_t)CreateTextureHook >> 32);
#endif
#ifdef _WIN32
    if (ReadProcessMemory(GetCurrentProcess(), g_createTexture, g_createTextureOrigBytes, 14, NULL) == 0)
        LUA->ThrowError("ShareOverlayTextureBegin: ReadProcessMemory failed");
    if (WriteProcessMemory(GetCurrentProcess(), g_createTexture, patch, 14, NULL) == 0)
        LUA->ThrowError("ShareOverlayTextureBegin: WriteProcessMemory failed");
#else
    uintptr_t pageSize = (uintptr_t)getpagesize();
    uintptr_t startAddr = (uintptr_t)g_createTexture;
    uintptr_t alignedAddr = startAddr & ~(pageSize - 1);
    size_t protectLen = ((startAddr + 14) - alignedAddr + pageSize - 1) & ~(pageSize - 1);
    if(mprotect((void*)alignedAddr, protectLen, PROT_READ | PROT_WRITE | PROT_EXEC) == -1) {
        g_captureTarget = 0;
        LUA->ThrowError("ShareOverlayTextureBegin: mprotect failed");
    }
    memcpy((void*)g_createTextureOrigBytes, (void*)g_createTexture, 14);
    memcpy((void*)g_createTexture, (void*)patch, 14);
#endif
    return 0;
}

LUA_FUNCTION(ShareOverlayTextureFinish) {
    g_captureTarget = 0; // Reset capture target
#ifdef _WIN32
    if (g_overlaySharedTexture == NULL)
        LUA->ThrowError("ShareOverlayTextureFinish: g_overlaySharedTexture is null");
    // Reuse existing D3D11 device if already created, otherwise create one
    if (g_d3d11Device == NULL) {
        if (D3D11CreateDevice(NULL, D3D_DRIVER_TYPE_HARDWARE, NULL, 0, NULL, NULL, D3D11_SDK_VERSION, &g_d3d11Device, NULL, NULL) != S_OK)
            LUA->ThrowError("ShareOverlayTextureFinish: D3D11CreateDevice failed");
    }
    ID3D11Resource* res;
    if (FAILED(g_d3d11Device->OpenSharedResource(g_overlaySharedTexture, __uuidof(ID3D11Resource), (void**)&res)))
        LUA->ThrowError("ShareOverlayTextureFinish: OpenSharedResource failed");
    if (FAILED(res->QueryInterface(__uuidof(ID3D11Texture2D), (void**)&g_overlayD3D11Texture)))
        LUA->ThrowError("ShareOverlayTextureFinish: QueryInterface failed");
    res->Release();
    g_overlayVrTexture.handle = g_overlayD3D11Texture;
    g_overlayVrTexture.eType = vr::TextureType_DirectX;
#else
    if (g_overlaySharedTexture_GL == GL_INVALID_VALUE)
        LUA->ThrowError("ShareOverlayTextureFinish: g_overlaySharedTexture_GL is invalid");
    g_overlayVrTexture.handle = (void*)(uintptr_t)g_overlaySharedTexture_GL;
    g_overlayVrTexture.eType = vr::TextureType_OpenGL;
#endif
    g_overlayVrTexture.eColorSpace = vr::ColorSpace_Auto;
    return 0;
}

LUA_FUNCTION(CreateVROverlay) {
    if (!vr::VROverlay()) { LUA->PushBool(false); return 1; }
    if (g_overlayCount >= MAX_OVERLAYS) {
        LUA->PushBool(false);
        LUA->PushString("Max overlays reached");
        return 2;
    }
    const char* key = LUA->CheckString(1);
    const char* name = LUA->CheckString(2);
    vr::VROverlayHandle_t handle;
    vr::EVROverlayError err = vr::VROverlay()->CreateOverlay(key, name, &handle);
    if (err != vr::VROverlayError_None) {
        LUA->PushBool(false);
        snprintf(g_errorString, MAX_STR_LEN, "CreateOverlay failed (error %d)", (int)err);
        LUA->PushString(g_errorString);
        return 2;
    }
    g_overlays[g_overlayCount++] = handle;
    // Return handle as two 32-bit numbers to avoid Lua double precision loss
    LUA->PushNumber((double)handle);
    return 1;
}

LUA_FUNCTION(DestroyVROverlay) {
    if (!vr::VROverlay()) { LUA->PushBool(false); return 1; }
    vr::VROverlayHandle_t handle = (vr::VROverlayHandle_t)(uint64_t)LUA->CheckNumber(1);
    vr::VROverlay()->DestroyOverlay(handle);
    for (int i = 0; i < g_overlayCount; i++) {
        if (g_overlays[i] == handle) {
            g_overlays[i] = g_overlays[--g_overlayCount];
            break;
        }
    }
    LUA->PushBool(true);
    return 1;
}

LUA_FUNCTION(SetOverlayTexture) {
    if (!vr::VROverlay()) { LUA->PushBool(false); return 1; }
    vr::VROverlayHandle_t handle = (vr::VROverlayHandle_t)(uint64_t)LUA->CheckNumber(1);
    // Use overlay-dedicated texture
    if (g_overlayVrTexture.handle == NULL) { LUA->PushBool(false); return 1; }
    vr::EVROverlayError err = vr::VROverlay()->SetOverlayTexture(handle, &g_overlayVrTexture);
    LUA->PushBool(err == vr::VROverlayError_None);
    return 1;
}

LUA_FUNCTION(OverlayControl) {
    if (!vr::VROverlay()) { LUA->PushBool(false); return 1; }
    vr::VROverlayHandle_t handle = (vr::VROverlayHandle_t)(uint64_t)LUA->CheckNumber(1);
    vr::IVROverlay* overlay = vr::VROverlay();

    LUA->CheckType(2, GarrysMod::Lua::Type::TABLE);
    LUA->GetField(2, "cmd");
    if (!LUA->IsType(-1, GarrysMod::Lua::Type::STRING)) {
        LUA->Pop(1);
        LUA->PushBool(false);
        return 1;
    }
    const char* cmd = LUA->GetString(-1);
    LUA->Pop(1);

    if (strcmp(cmd, "show") == 0) {
        overlay->ShowOverlay(handle);
    } else if (strcmp(cmd, "hide") == 0) {
        overlay->HideOverlay(handle);
    } else if (strcmp(cmd, "setWidth") == 0) {
        LUA->GetField(2, "value");
        overlay->SetOverlayWidthInMeters(handle, (float)LUA->GetNumber(-1));
        LUA->Pop(1);
    } else if (strcmp(cmd, "setAlpha") == 0) {
        LUA->GetField(2, "value");
        overlay->SetOverlayAlpha(handle, (float)LUA->GetNumber(-1));
        LUA->Pop(1);
    } else if (strcmp(cmd, "setColor") == 0) {
        LUA->GetField(2, "r"); float r = (float)LUA->GetNumber(-1); LUA->Pop(1);
        LUA->GetField(2, "g"); float g = (float)LUA->GetNumber(-1); LUA->Pop(1);
        LUA->GetField(2, "b"); float b = (float)LUA->GetNumber(-1); LUA->Pop(1);
        overlay->SetOverlayColor(handle, r, g, b);
    } else if (strcmp(cmd, "setSortOrder") == 0) {
        LUA->GetField(2, "value");
        overlay->SetOverlaySortOrder(handle, (uint32_t)LUA->GetNumber(-1));
        LUA->Pop(1);
    } else if (strcmp(cmd, "setTextureBounds") == 0) {
        vr::VRTextureBounds_t bounds;
        LUA->GetField(2, "uMin"); bounds.uMin = (float)LUA->GetNumber(-1); LUA->Pop(1);
        LUA->GetField(2, "vMin"); bounds.vMin = (float)LUA->GetNumber(-1); LUA->Pop(1);
        LUA->GetField(2, "uMax"); bounds.uMax = (float)LUA->GetNumber(-1); LUA->Pop(1);
        LUA->GetField(2, "vMax"); bounds.vMax = (float)LUA->GetNumber(-1); LUA->Pop(1);
        overlay->SetOverlayTextureBounds(handle, &bounds);
    } else if (strcmp(cmd, "setTransformAbsolute") == 0) {
        LUA->GetField(2, "origin");
        int origin = (int)LUA->GetNumber(-1); LUA->Pop(1);
        LUA->GetField(2, "matrix");
        vr::HmdMatrix34_t mat;
        memset(&mat, 0, sizeof(mat));
        for (int r = 0; r < 3; r++) {
            LUA->PushNumber(r + 1); LUA->GetTable(-2);
            for (int c = 0; c < 4; c++) {
                LUA->PushNumber(c + 1); LUA->GetTable(-2);
                mat.m[r][c] = (float)LUA->GetNumber(-1); LUA->Pop(1);
            }
            LUA->Pop(1);
        }
        LUA->Pop(1);
        overlay->SetOverlayTransformAbsolute(handle, (vr::ETrackingUniverseOrigin)origin, &mat);
    } else if (strcmp(cmd, "setTransformTrackedDevice") == 0) {
        LUA->GetField(2, "deviceIndex");
        int devIdx = (int)LUA->GetNumber(-1); LUA->Pop(1);
        LUA->GetField(2, "matrix");
        vr::HmdMatrix34_t mat;
        memset(&mat, 0, sizeof(mat));
        for (int r = 0; r < 3; r++) {
            LUA->PushNumber(r + 1); LUA->GetTable(-2);
            for (int c = 0; c < 4; c++) {
                LUA->PushNumber(c + 1); LUA->GetTable(-2);
                mat.m[r][c] = (float)LUA->GetNumber(-1); LUA->Pop(1);
            }
            LUA->Pop(1);
        }
        LUA->Pop(1);
        overlay->SetOverlayTransformTrackedDeviceRelative(handle,
            (vr::TrackedDeviceIndex_t)devIdx, &mat);
    } else if (strcmp(cmd, "isVisible") == 0) {
        LUA->PushBool(overlay->IsOverlayVisible(handle));
        return 1;
    } else {
        LUA->PushBool(false);
        return 1;
    }
    LUA->PushBool(true);
    return 1;
}

// =========================================================================

LUA_FUNCTION(GetModuleInfo) {
    LUA->CreateTable();
    LUA->PushString("semiofficial");
    LUA->SetField(-2, "name");
    LUA->PushNumber(103);
    LUA->SetField(-2, "version");
#ifdef VRMOD_USE_SRANIPAL
    LUA->PushBool(true);
#else
    LUA->PushBool(false);
#endif
    LUA->SetField(-2, "sranipal_support");
    LUA->PushNumber(MAX_ACTIONS);
    LUA->SetField(-2, "max_actions");
    LUA->PushNumber(MAX_ACTIONSETS);
    LUA->SetField(-2, "max_actionsets");
    LUA->PushNumber(MAX_STR_LEN);
    LUA->SetField(-2, "max_str_len");
    // v103 capabilities
    LUA->PushBool(true);  LUA->SetField(-2, "event_polling");
    LUA->PushBool(true);  LUA->SetField(-2, "frame_timing");
    LUA->PushBool(true);  LUA->SetField(-2, "skeleton_bones");
    LUA->PushBool(true);  LUA->SetField(-2, "overlay");
    LUA->PushNumber(MAX_OVERLAYS);
    LUA->SetField(-2, "max_overlays");
    return 1;
}

GMOD_MODULE_OPEN(){
    LUA->PushSpecial(GarrysMod::Lua::SPECIAL_GLOB);
    LUA->GetField(-1, "vrmod");
    if (!LUA->IsType(-1, GarrysMod::Lua::Type::TABLE)) {
        LUA->Pop(1);
        LUA->CreateTable();
    }
    LUA->PushCFunction(GetVersion);
    LUA->SetField(-2, "GetVersion");
    LUA->PushCFunction(GetSemiVersion);
    LUA->SetField(-2, "GetSemiVersion");
    LUA->PushCFunction(IsHMDPresent);
    LUA->SetField(-2, "IsHMDPresent");
    LUA->PushCFunction(Init);
    LUA->SetField(-2, "Init");
    LUA->PushCFunction(SetActionManifest);
    LUA->SetField(-2, "SetActionManifest");
    LUA->PushCFunction(SetActiveActionSets);
    LUA->SetField(-2, "SetActiveActionSets");
    LUA->PushCFunction(GetDisplayInfo);
    LUA->SetField(-2, "GetDisplayInfo");
    LUA->PushCFunction(UpdatePosesAndActions);
    LUA->SetField(-2, "UpdatePosesAndActions");
    LUA->PushCFunction(GetPoses);
    LUA->SetField(-2, "GetPoses");
    LUA->PushCFunction(GetActions);
    LUA->SetField(-2, "GetActions");
    LUA->PushCFunction(ShareTextureBegin);
    LUA->SetField(-2, "ShareTextureBegin");
    LUA->PushCFunction(ShareTextureFinish);
    LUA->SetField(-2, "ShareTextureFinish");
    LUA->PushCFunction(SetSubmitTextureBounds);
    LUA->SetField(-2, "SetSubmitTextureBounds");
    LUA->PushCFunction(SubmitSharedTexture);
    LUA->SetField(-2, "SubmitSharedTexture");
    LUA->PushCFunction(Shutdown);
    LUA->SetField(-2, "Shutdown");
    LUA->PushCFunction(TriggerHaptic);
    LUA->SetField(-2, "TriggerHaptic");
    LUA->PushCFunction(GetTrackedDeviceNames);
    LUA->SetField(-2, "GetTrackedDeviceNames");
    LUA->PushCFunction(GetModuleInfo);
    LUA->SetField(-2, "GetModuleInfo");
#ifdef _WIN32
    LUA->PushCFunction(GetGameHWND);
    LUA->SetField(-2, "GetGameHWND");
    LUA->PushCFunction(SendKeyEvent);
    LUA->SetField(-2, "SendKeyEvent");
    LUA->PushCFunction(DebugGetAsyncKeyState);
    LUA->SetField(-2, "DebugGetAsyncKeyState");
#endif
#ifdef VRMOD_USE_SRANIPAL
    LUA->PushCFunction(SRanipalInit);
    LUA->SetField(-2, "SRanipalInit");
    LUA->PushCFunction(SRanipalGetLipData);
    LUA->SetField(-2, "SRanipalGetLipData");
    LUA->PushCFunction(SRanipalGetEyeData);
    LUA->SetField(-2, "SRanipalGetEyeData");
#endif
    // v103: B4+B5 Event Polling + Device Properties
    LUA->PushCFunction(PollNextEvent);
    LUA->SetField(-2, "PollNextEvent");
    LUA->PushCFunction(IsTrackedDeviceConnected);
    LUA->SetField(-2, "IsTrackedDeviceConnected");
    LUA->PushCFunction(GetTrackedDeviceClass);
    LUA->SetField(-2, "GetTrackedDeviceClass");
    LUA->PushCFunction(GetFloatTrackedDeviceProperty);
    LUA->SetField(-2, "GetFloatTrackedDeviceProperty");
    LUA->PushCFunction(GetInt32TrackedDeviceProperty);
    LUA->SetField(-2, "GetInt32TrackedDeviceProperty");
    LUA->PushCFunction(GetStringTrackedDeviceProperty);
    LUA->SetField(-2, "GetStringTrackedDeviceProperty");
    LUA->PushCFunction(ShouldApplicationPause);
    LUA->SetField(-2, "ShouldApplicationPause");
    LUA->PushCFunction(ShouldApplicationReduceRenderingWork);
    LUA->SetField(-2, "ShouldApplicationReduceRenderingWork");
    // v103: B3 Frame Timing + Performance
    LUA->PushCFunction(GetFrameTiming);
    LUA->SetField(-2, "GetFrameTiming");
    LUA->PushCFunction(GetFrameTimeRemaining);
    LUA->SetField(-2, "GetFrameTimeRemaining");
    LUA->PushCFunction(IsMotionSmoothingEnabled);
    LUA->SetField(-2, "IsMotionSmoothingEnabled");
    LUA->PushCFunction(FadeToColor);
    LUA->SetField(-2, "FadeToColor");
    LUA->PushCFunction(VRSuspendRendering);
    LUA->SetField(-2, "SuspendRendering");
    // v103: B1 Skeletal Bone Data
    LUA->PushCFunction(GetSkeletalBoneData);
    LUA->SetField(-2, "GetSkeletalBoneData");
    // v103: A1 Overlay System
    LUA->PushCFunction(ShareOverlayTextureBegin);
    LUA->SetField(-2, "ShareOverlayTextureBegin");
    LUA->PushCFunction(ShareOverlayTextureFinish);
    LUA->SetField(-2, "ShareOverlayTextureFinish");
    LUA->PushCFunction(CreateVROverlay);
    LUA->SetField(-2, "CreateOverlay");
    LUA->PushCFunction(DestroyVROverlay);
    LUA->SetField(-2, "DestroyOverlay");
    LUA->PushCFunction(SetOverlayTexture);
    LUA->SetField(-2, "SetOverlayTexture");
    LUA->PushCFunction(OverlayControl);
    LUA->SetField(-2, "OverlayControl");
    LUA->SetField(-2, "vrmod");
    return 0;
}

GMOD_MODULE_CLOSE(){
    return 0;
}
