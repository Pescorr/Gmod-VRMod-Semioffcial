local paths = {}

-- ConVarを作成
CreateConVar("vrmod_dev_excluded_Originalfiles", "", FCVAR_ARCHIVE, "Excluded Lua files separated by semicolons")

-- ConVarの値を取得
local excludedFilesString = GetConVarString("vrmod_dev_excluded_Originalfiles")
local excludedFiles = {}
if excludedFilesString ~= "" then
    for file in string.gmatch(excludedFilesString, "([^,]+)") do
        excludedFiles[file] = true
    end
end

local _, folders = file.Find("vrmod/*","LUA")
table.sort(folders, function(a,b) return tonumber(a) < tonumber(b) end)
for k,v in ipairs(folders) do
    paths[#paths+1] = "vrmod/"..v.."/"
end
paths[#paths+1] = "vrmod/"

for k,v in ipairs(paths) do
    for k2,v2 in ipairs(file.Find(v.."*","LUA")) do
        -- ConVarで指定されたファイルを除外して読み込む
        if not excludedFiles[v2] then
            AddCSLuaFile(v..v2)
            include(v..v2)
        end
    end
end
