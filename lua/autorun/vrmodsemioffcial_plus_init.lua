AddCSLuaFile()

-- フォルダ番号 → 機能名マップ（表示用）
local FOLDER_INFO = {
    ["0"]  = "Core(API)",
    ["1"]  = "Core(Modules)",
    ["2"]  = "Holster Type2",
    ["3"]  = "Foregrip",
    ["4"]  = "Magbone/ARC9",
    ["5"]  = "Melee",
    ["6"]  = "Holster Type1",
    ["7"]  = "VR Hand HUD",
    ["8"]  = "Physgun",
    ["9"]  = "VR Pickup",
    ["10"] = "Debug",
    ["11"] = "(Reserved)",
    ["12"] = "Guide",
    ["13"] = "RealMech",
    ["14"] = "Throw",
    ["15"] = "Hand Sync",
    ["16"] = "Ragdoll Grab",
    ["17"] = "Ragdoll Puppeteer",
    ["18"] = "Time Crisis",
}

-- Legacy v133 に存在したフォルダ（これだけロードする）
local LEGACY_FOLDERS = { ["0"] = true, ["1"] = true }

-- 個別ON/OFFが可能なフォルダ（通常モードではフォルダ2以上）
local TOGGLEABLE_FOLDERS = {}
for k in pairs(FOLDER_INFO) do
    if tonumber(k) and tonumber(k) >= 2 then
        TOGGLEABLE_FOLDERS[k] = true
    end
end

function VRMod_SemiOffcial_Include()
    local paths = {}
    local operation = CreateClientConVar("vrmod_dev_unoffcial_folder_file_operation", "1", true, FCVAR_ARCHIVE, "Excluded Lua files separated by semicolons", 1, 2)

    if operation:GetInt() == 0 then return end

    -- フォルダ単位のロード制御
    local legacyModeCV = CreateClientConVar("vrmod_unoff_legacy_mode", "0", true, FCVAR_ARCHIVE, "Legacy mode: only load folders 0,1 + root (0=off, 1=on)", 0, 1)

    -- Addon-Only Mode: ルートファイルをスキップし、外部VRModと併用する
    local addonOnlyCV = CreateClientConVar("vrmod_unoff_addon_only_mode", "0", true, FCVAR_ARCHIVE, "Addon-only mode: skip root files, use with external VRMod (0=off, 1=on)", 0, 1)

    local isLegacy = legacyModeCV:GetBool()
    local isAddonOnly = addonOnlyCV:GetBool()

    -- 他VRModのinitが存在するか検出
    -- (リネーム後、vrmodsemioffcial_init.lua は他VRModのみが持つ)
    local otherVRModPresent = file.Exists("autorun/vrmodsemioffcial_init.lua", "LUA")

    if otherVRModPresent then
        if isAddonOnly then
            -- Addon-only: 他VRModがベースシステムをロード済み → メニューだけ追加
            VRMOD_ADDON_ONLY_MODE = true
            print("[VRMod SemiOffcial] Addon-only mode: external VRMod detected, modules loaded by external init")
            AddCSLuaFile("vrmodUnoffcial/1/vrmod_addononly_menu.lua")
            include("vrmodUnoffcial/1/vrmod_addononly_menu.lua")
        else
            -- 通常モード: 他VRModが全システムをロード済み → 二重ロード防止
            print("[VRMod SemiOffcial] External VRMod detected - skipping to avoid double-load")
            print("[VRMod SemiOffcial] Tip: use 'vrmod_unoff_addon_only_mode 1' for addon-only features")
        end
        return
    end

    -- 他VRMod不在 + addon-only → フォールバック（通常モードで動作）
    if isAddonOnly then
        print("[VRMod SemiOffcial] WARNING: Addon-only mode but no external VRMod found! Loading normally.")
        isAddonOnly = false
    end

    -- Addon-Only が ON なら Legacy は無視（排他）
    if isAddonOnly then isLegacy = false end

    -- グローバルフラグ設定（folder 0 のファイルが参照する）
    VRMOD_ADDON_ONLY_MODE = isAddonOnly

    -- Addon-Only Mode: フォルダ0/1も個別トグル可能にする
    if isAddonOnly then
        TOGGLEABLE_FOLDERS["0"] = true
        TOGGLEABLE_FOLDERS["1"] = true
    end

    -- 個別フォルダConVar作成
    for k in pairs(TOGGLEABLE_FOLDERS) do
        -- Addon-only時: フォルダ1はデフォルトOFF（他VRModのauto-settingsと競合回避）
        local default = "1"
        if isAddonOnly and k == "1" then default = "0" end
        CreateClientConVar("vrmod_unoff_load_" .. k, default, true, FCVAR_ARCHIVE,
            "Load folder " .. k .. " (" .. (FOLDER_INFO[k] or "") .. ") 0=skip 1=load", 0, 1)
    end

    local function shouldLoadFolder(name)
        if isAddonOnly then
            -- Addon-only: 個別ConVarのみで判定（Legacyロジックをスキップ）
            if TOGGLEABLE_FOLDERS[name] then
                local cv = GetConVar("vrmod_unoff_load_" .. name)
                if cv and not cv:GetBool() then return false end
            end
            return true
        end
        -- 通常/Legacyモード
        if isLegacy and not LEGACY_FOLDERS[name] then return false end
        if TOGGLEABLE_FOLDERS[name] then
            local cv = GetConVar("vrmod_unoff_load_" .. name)
            if cv and not cv:GetBool() then return false end
        end
        return true
    end

    -- フォルダ一覧を取得・ソート・フィルタ
    local _, allFolders = file.Find("vrmodUnoffcial/*", "LUA")
    table.sort(allFolders, function(a, b) return tonumber(a) < tonumber(b) end)

    local skippedFolders = {}
    for _, v in ipairs(allFolders) do
        if shouldLoadFolder(v) then
            paths[#paths + 1] = "vrmodUnoffcial/" .. v .. "/"
        else
            skippedFolders[#skippedFolders + 1] = v
        end
    end

    -- スキップ情報をコンソールに表示
    if #skippedFolders > 0 then
        local details = {}
        for _, f in ipairs(skippedFolders) do
            details[#details + 1] = f .. "(" .. (FOLDER_INFO[f] or "?") .. ")"
        end
        print("[VRMod SemiOffcial] Skipped folders: " .. table.concat(details, ", "))
    end

    if isAddonOnly then
        print("[VRMod SemiOffcial] Addon-only mode ON - root files skipped, using external VRMod")
    elseif isLegacy then
        print("[VRMod SemiOffcial] Legacy mode ON - only loading core folders + root")
    end

    -- ルートファイル（番号なし）: Addon-only時はスキップ
    if not isAddonOnly then
        paths[#paths + 1] = "vrmodUnoffcial/"
    end

    -- Addon-only時: 互換性スタブ定義（ルートファイルが提供する関数の代替）
    -- 全て "if not X then" ガード付き → 通常モードでは一切影響しない
    if isAddonOnly and CLIENT then
        if not VRModL then
            VRMOD_LANG = VRMOD_LANG or { current = "en", en = {} }
            function VRModL(key, fallback) return fallback or key end
        end
        VRMOD_DEFAULTS = VRMOD_DEFAULTS or {}
        if not VRModGetDefault then
            function VRModGetDefault() return nil end
        end
        if not VRModResetCategory then
            function VRModResetCategory() end
        end
        if not VRModResetAll then
            function VRModResetAll() end
        end
    end

    if operation:GetInt() == 1 then
        -- Mode 1: 除外リストに無いファイルを全てロード
        CreateClientConVar("vrmod_dev_unoffcial_folder_excluded_files", "", true, FCVAR_ARCHIVE, "Excluded Lua files separated by semicolons")
        local excludedFilesString = GetConVar("vrmod_dev_unoffcial_folder_excluded_files"):GetString()
        local excludedFiles = {}
        if excludedFilesString ~= "" then
            for f in string.gmatch(excludedFilesString, "([^,]+)") do
                excludedFiles[f] = true
            end
        end

        for _, v in ipairs(paths) do
            for _, v2 in ipairs(file.Find(v .. "*", "LUA")) do
                if not excludedFiles[v2] then
                    AddCSLuaFile(v .. v2)
                    include(v .. v2)
                end
            end
        end
    end

    if operation:GetInt() == 2 then
        -- Mode 2: 指定リストのファイルのみロード
        CreateClientConVar("vrmod_dev_unoffcial_folder_included_files", "", true, FCVAR_ARCHIVE, "Included Lua files separated by semicolons")
        local includedFilesString = GetConVar("vrmod_dev_unoffcial_folder_included_files"):GetString()
        local includedFiles = {}
        if includedFilesString ~= "" then
            for f in string.gmatch(includedFilesString, "([^;]+)") do
                includedFiles[f] = true
            end
        end

        for _, v in ipairs(paths) do
            for _, v2 in ipairs(file.Find(v .. "*", "LUA")) do
                if includedFiles[v2] then
                    AddCSLuaFile(v .. v2)
                    include(v .. v2)
                end
            end
        end
    end
end

VRMod_SemiOffcial_Include()

concommand.Add("vrmod_dev_lua_reinclude_semioffcial", function()
    VRMod_SemiOffcial_Include()
end)

-- フォルダ状態表示コマンド
concommand.Add("vrmod_unoff_folders", function()
    local legacyCV = GetConVar("vrmod_unoff_legacy_mode")
    local addonOnlyCV = GetConVar("vrmod_unoff_addon_only_mode")
    local isLegacy = legacyCV and legacyCV:GetBool() or false
    local isAddonOnly = addonOnlyCV and addonOnlyCV:GetBool() or false

    print("========================================")
    print("[VRMod SemiOffcial] Folder Loading Status")
    if isAddonOnly then
        print("  ** ADDON-ONLY MODE ** (root files skipped)")
    elseif isLegacy then
        print("  ** LEGACY MODE ON **")
    end
    print("----------------------------------------")

    local sortedKeys = {}
    for k in pairs(FOLDER_INFO) do sortedKeys[#sortedKeys + 1] = k end
    table.sort(sortedKeys, function(a, b) return tonumber(a) < tonumber(b) end)

    for _, k in ipairs(sortedKeys) do
        local status
        if isAddonOnly then
            if TOGGLEABLE_FOLDERS[k] then
                local cv = GetConVar("vrmod_unoff_load_" .. k)
                if cv and not cv:GetBool() then
                    status = "DISABLED (manual)"
                else
                    status = "LOADED"
                end
            else
                status = "LOADED"
            end
        elseif not TOGGLEABLE_FOLDERS[k] then
            status = "ALWAYS LOADED (core)"
        elseif isLegacy and not LEGACY_FOLDERS[k] then
            status = "DISABLED (legacy)"
        else
            local cv = GetConVar("vrmod_unoff_load_" .. k)
            if cv and not cv:GetBool() then
                status = "DISABLED (manual)"
            else
                status = "LOADED"
            end
        end
        print(string.format("  [%2s] %-20s %s", k, FOLDER_INFO[k], status))
    end

    if not isAddonOnly then
        print("  [--] Root files            " .. "LOADED")
    else
        print("  [--] Root files            " .. "SKIPPED (addon-only)")
    end

    print("----------------------------------------")
    print("ConVars:")
    print("  vrmod_unoff_legacy_mode    = " .. (legacyCV and legacyCV:GetString() or "?"))
    print("  vrmod_unoff_addon_only_mode = " .. (addonOnlyCV and addonOnlyCV:GetString() or "?"))
    for k in pairs(TOGGLEABLE_FOLDERS) do
        local cv = GetConVar("vrmod_unoff_load_" .. k)
        print("  vrmod_unoff_load_" .. k .. " = " .. (cv and cv:GetString() or "?"))
    end
    print("========================================")
end)
