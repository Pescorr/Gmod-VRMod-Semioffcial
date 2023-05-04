local paths = {}


local operation = CreateConVar("vrmod_dev_unoffcial_folder_file_operation", "0", FCVAR_ARCHIVE, "Excluded Lua files separated by semicolons",0,2)

if operation:GetInt() == 0 then return end

if operation:GetInt() == 1 then

    -- ConVarを作成
    CreateConVar("vrmod_dev_unoffcial_folder_excluded_files", "vrmod_sample01.lua,vrmod_sample02.lua", FCVAR_ARCHIVE, "Excluded Lua files separated by semicolons")

    -- ConVarの値を取得
    local excludedFilesString = GetConVarString("vrmod_dev_unoffcial_folder_excluded_files")
    local excludedFiles = {}
    if excludedFilesString ~= "" then
        for file in string.gmatch(excludedFilesString, "([^,]+)") do
            excludedFiles[file] = true
        end
    end

    local _, folders = file.Find("vrmodUnoffcial/*","LUA")
    table.sort(folders, function(a,b) return tonumber(a) < tonumber(b) end)
    for k,v in ipairs(folders) do
        paths[#paths+1] = "vrmodUnoffcial/"..v.."/"
    end
    paths[#paths+1] = "vrmodUnoffcial/"

    for k,v in ipairs(paths) do
        for k2,v2 in ipairs(file.Find(v.."*","LUA")) do
            -- ConVarで指定されたファイルを除外して読み込む
            if not excludedFiles[v2] then
                AddCSLuaFile(v..v2)
                include(v..v2)
            end
        end
    end

end

if operation:GetInt() == 2 then


    local paths = {}

    -- ConVarを作成
    CreateConVar("vrmod_dev_unoffcial_folder_included_files", "vrmod_sample01.lua,vrmod_sample02.lua", FCVAR_ARCHIVE, "Included Lua files separated by semicolons")

    -- ConVarの値を取得
    local includedFilesString = GetConVarString("vrmod_dev_unoffcial_folder_included_files")
    local includedFiles = {}
    if includedFilesString ~= "" then
        for file in string.gmatch(includedFilesString, "([^;]+)") do
            includedFiles[file] = true
        end
    end

    local _, folders = file.Find("vrmodUnoffcial/*","LUA")
    table.sort(folders, function(a,b) return tonumber(a) < tonumber(b) end)
    for k,v in ipairs(folders) do
        paths[#paths+1] = "vrmodUnoffcial/"..v.."/"
    end
    paths[#paths+1] = "vrmodUnoffcial/"

    for k,v in ipairs(paths) do
        for k2,v2 in ipairs(file.Find(v.."*","LUA")) do
            -- ConVarで指定されたファイルのみ読み込む
            if includedFiles[v2] then
                AddCSLuaFile(v..v2)
                include(v..v2)
            end
        end
    end
end
