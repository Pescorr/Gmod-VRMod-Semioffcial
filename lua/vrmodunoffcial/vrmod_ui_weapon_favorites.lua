-- VRMod Semi-Official Addon Plus - Weapon Favorites System
-- お気に入り武器の永続化・管理
-- file.Write は .txt 拡張子のみ動作する (GLua制約)
if SERVER then return end

local FAVORITES_PATH = "vrmod/weapon_favorites.txt"

-- Defensive init: 既存テーブルを保持
vrmod = vrmod or {}
vrmod._weaponFavorites = vrmod._weaponFavorites or {}

-- DATA ディレクトリの確保
local function EnsureDataDirectory()
	if not file.IsDir("vrmod", "DATA") then
		file.CreateDir("vrmod")
	end
end

-- お気に入りをディスクから読み込み
function vrmod.LoadWeaponFavorites()
	EnsureDataDirectory()
	if not file.Exists(FAVORITES_PATH, "DATA") then
		vrmod._weaponFavorites = {}
		return
	end
	local raw = file.Read(FAVORITES_PATH, "DATA")
	if not raw or raw == "" then
		vrmod._weaponFavorites = {}
		return
	end
	local ok, tbl = pcall(util.JSONToTable, raw)
	if ok and istable(tbl) then
		vrmod._weaponFavorites = tbl
	else
		vrmod._weaponFavorites = {}
	end
end

-- お気に入りをディスクに保存
function vrmod.SaveWeaponFavorites()
	EnsureDataDirectory()
	local json = util.TableToJSON(vrmod._weaponFavorites, true)
	if json then
		file.Write(FAVORITES_PATH, json)
	end
end

-- お気に入りトグル
function vrmod.ToggleWeaponFavorite(weaponClass)
	if not isstring(weaponClass) or weaponClass == "" then return false end
	if vrmod._weaponFavorites[weaponClass] then
		vrmod._weaponFavorites[weaponClass] = nil
	else
		vrmod._weaponFavorites[weaponClass] = true
	end
	vrmod.SaveWeaponFavorites()
	return vrmod._weaponFavorites[weaponClass] == true
end

-- お気に入り確認
function vrmod.IsWeaponFavorite(weaponClass)
	return vrmod._weaponFavorites[weaponClass] == true
end

-- 初回ロード
vrmod.LoadWeaponFavorites()
