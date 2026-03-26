--------[!vrmod_debug_core.lua]Start--------
AddCSLuaFile()

-- デバッグシステム基盤
-- vrmod_unoff_debug == 0 の時は一切の影響を与えない

vrmod = vrmod or {}
vrmod.debug = vrmod.debug or {}

-- マスタースイッチConVar（FCVAR_ARCHIVE: cfg保存、再起動で反映）
-- JSON移行対象: vrmod.JsonConfig.CreateVar経由で登録
local cv_debug = CreateClientConVar("vrmod_unoff_debug", "0", true, FCVAR_ARCHIVE, "Enable VRMod debug system (requires restart)", 0, 1)

-- 安全ガード: デバッグ無効なら即return
if not cv_debug:GetBool() then
	vrmod.debug.enabled = false
	-- 他の10/ファイルが参照する空関数を用意
	vrmod.debug.Log = {
		Error = function() end,
		Warn = function() end,
		Info = function() end,
		Debug = function() end,
	}
	return
end

-- ========================================
-- デバッグシステム有効化
-- ========================================
vrmod.debug.enabled = true

if SERVER then return end

-- ----------------------------------------
-- ConVar定義（ファイルスコープでキャッシュ）
-- ----------------------------------------
local cv_hooks = CreateClientConVar("vrmod_unoff_debug_hooks", "0", true, FCVAR_ARCHIVE, "Enable hook.Call monitoring", 0, 1)
local cv_loglevel = CreateClientConVar("vrmod_unoff_debug_loglevel", "2", true, FCVAR_ARCHIVE, "Log level: 0=off, 1=error, 2=warn, 3=info, 4=debug", 0, 4)

-- 内部キャッシュ変数（cvars.AddChangeCallbackで同期）
local debugHooksEnabled = cv_hooks:GetBool()
local logLevel = cv_loglevel:GetInt()

cvars.AddChangeCallback("vrmod_unoff_debug_hooks", function(_, _, val)
	debugHooksEnabled = tobool(val)
end, "vrmod_debug_core")

cvars.AddChangeCallback("vrmod_unoff_debug_loglevel", function(_, _, val)
	logLevel = tonumber(val) or 2
end, "vrmod_debug_core")

-- 公開アクセサ
function vrmod.debug.IsHooksEnabled()
	return debugHooksEnabled
end

function vrmod.debug.GetLogLevel()
	return logLevel
end

-- ----------------------------------------
-- ロガー（MsgC色付き出力）
-- ----------------------------------------
local LOG_PREFIX = "[VRMod Debug] "
local COLOR_ERROR = Color(255, 100, 100)
local COLOR_WARN = Color(255, 200, 100)
local COLOR_INFO = Color(100, 200, 255)
local COLOR_DEBUG = Color(180, 180, 180)
local COLOR_WHITE = Color(255, 255, 255)

vrmod.debug.Log = {}

function vrmod.debug.Log.Error(source, ...)
	MsgC(COLOR_ERROR, LOG_PREFIX, COLOR_WHITE, "[", source, "] ", ...)
	MsgN()
	-- エラーバッファに追加
	vrmod.debug.AddError(source, table.concat({...}, ""))
end

function vrmod.debug.Log.Warn(source, ...)
	if logLevel < 2 then return end
	MsgC(COLOR_WARN, LOG_PREFIX, COLOR_WHITE, "[", source, "] ", ...)
	MsgN()
end

function vrmod.debug.Log.Info(source, ...)
	if logLevel < 3 then return end
	MsgC(COLOR_INFO, LOG_PREFIX, COLOR_WHITE, "[", source, "] ", ...)
	MsgN()
end

function vrmod.debug.Log.Debug(source, ...)
	if logLevel < 4 then return end
	MsgC(COLOR_DEBUG, LOG_PREFIX, COLOR_WHITE, "[", source, "] ", ...)
	MsgN()
end

-- ----------------------------------------
-- エラー追跡（循環バッファ）
-- ----------------------------------------
vrmod.debug.errors = vrmod.debug.errors or {}
local MAX_ERRORS = 100

function vrmod.debug.AddError(source, message)
	local entry = {
		source = source,
		message = message,
		stack = debug.traceback("", 3),
		time = CurTime(),
		sysTime = SysTime(),
	}

	table.insert(vrmod.debug.errors, entry)

	if #vrmod.debug.errors > MAX_ERRORS then
		table.remove(vrmod.debug.errors, 1)
	end
end

function vrmod.debug.GetErrors()
	return vrmod.debug.errors
end

function vrmod.debug.ClearErrors()
	vrmod.debug.errors = {}
end

-- ----------------------------------------
-- フック発火データストア
-- ----------------------------------------
vrmod.debug.hooks = vrmod.debug.hooks or {}
vrmod.debug.hookInventory = vrmod.debug.hookInventory or {}

-- ----------------------------------------
-- 行レベルトレースデータストア
-- ----------------------------------------
vrmod.debug.activeLines = vrmod.debug.activeLines or {}
vrmod.debug.lineTraceFile = nil
vrmod.debug.lineTraceActive = false
vrmod.debug.lineTraceStartTime = 0

-- ----------------------------------------
-- ファイルツリー構築
-- ----------------------------------------
vrmod.debug.fileTree = vrmod.debug.fileTree or {}

local function BuildFileTree()
	local tree = {}
	local basePath = "vrmodunoffcial/"

	-- 番号付きフォルダを検出
	local _, folders = file.Find("vrmodUnoffcial/*", "LUA")
	if not folders then
		vrmod.debug.Log.Warn("core", "Could not find vrmodUnoffcial folder")
		return tree
	end

	-- フォルダをソート（init.luaと同じロジック）
	local numFolders = {}
	local otherFolders = {}
	for _, folderName in ipairs(folders) do
		local num = tonumber(folderName)
		if num then
			table.insert(numFolders, { name = folderName, num = num })
		else
			table.insert(otherFolders, folderName)
		end
	end
	table.sort(numFolders, function(a, b) return a.num < b.num end)

	-- 番号付きフォルダのファイル
	for _, folder in ipairs(numFolders) do
		local files = file.Find("vrmodUnoffcial/" .. folder.name .. "/*", "LUA")
		if files and #files > 0 then
			tree[folder.name] = {}
			for _, fileName in ipairs(files) do
				table.insert(tree[folder.name], {
					name = fileName,
					path = basePath .. folder.name .. "/" .. fileName,
					fullPath = "addons/vrmod_semioffcial_addonplus/lua/" .. basePath .. folder.name .. "/" .. fileName,
				})
			end
		end
	end

	-- ルートディレクトリのファイル
	local rootFiles = file.Find("vrmodUnoffcial/*", "LUA")
	if rootFiles then
		tree["Root"] = {}
		for _, fileName in ipairs(rootFiles) do
			-- フォルダでなくファイルのみ
			if string.GetExtensionFromFilename(fileName) == "lua" then
				table.insert(tree["Root"], {
					name = fileName,
					path = basePath .. fileName,
					fullPath = "addons/vrmod_semioffcial_addonplus/lua/" .. basePath .. fileName,
				})
			end
		end
	end

	-- autorunファイルも追加
	local autorunFiles = file.Find("autorun/*vrmod*", "LUA")
	if autorunFiles and #autorunFiles > 0 then
		tree["autorun"] = {}
		for _, fileName in ipairs(autorunFiles) do
			table.insert(tree["autorun"], {
				name = fileName,
				path = "autorun/" .. fileName,
				fullPath = "addons/vrmod_semioffcial_addonplus/lua/autorun/" .. fileName,
			})
		end
	end

	local autorunClientFiles = file.Find("autorun/client/*vrmod*", "LUA")
	if autorunClientFiles and #autorunClientFiles > 0 then
		tree["autorun/client"] = {}
		for _, fileName in ipairs(autorunClientFiles) do
			table.insert(tree["autorun/client"], {
				name = fileName,
				path = "autorun/client/" .. fileName,
				fullPath = "addons/vrmod_semioffcial_addonplus/lua/autorun/client/" .. fileName,
			})
		end
	end

	return tree
end

-- ----------------------------------------
-- ソースコード読み込み
-- ----------------------------------------
vrmod.debug.sourceCache = vrmod.debug.sourceCache or {}

function vrmod.debug.ReadSource(fullPath)
	-- キャッシュチェック
	if vrmod.debug.sourceCache[fullPath] then
		return vrmod.debug.sourceCache[fullPath]
	end

	local content = file.Read(fullPath, "GAME")
	if not content then
		-- フォールバック: luaパスから試行
		local luaPath = string.gsub(fullPath, "^addons/vrmod_semioffcial_addonplus/lua/", "")
		content = file.Read(luaPath, "LUA")
	end

	if not content then
		vrmod.debug.Log.Warn("core", "Could not read file: " .. fullPath)
		return nil
	end

	-- 行ごとに分割
	local lines = {}
	for line in string.gmatch(content .. "\n", "(.-)\n") do
		table.insert(lines, line)
	end

	vrmod.debug.sourceCache[fullPath] = lines
	return lines
end

function vrmod.debug.ClearSourceCache()
	vrmod.debug.sourceCache = {}
end

-- ----------------------------------------
-- 初期化
-- ----------------------------------------
vrmod.debug.fileTree = BuildFileTree()

-- ファイル数カウント
local totalFiles = 0
for _, files in pairs(vrmod.debug.fileTree) do
	totalFiles = totalFiles + #files
end

vrmod.debug.Log.Info("core", "Debug system initialized. " .. totalFiles .. " files indexed.")

-- ----------------------------------------
-- VR終了時クリーンアップ
-- ----------------------------------------
hook.Add("VRMod_Exit", "vrmod_debug_cleanup", function(ply)
	if ply ~= LocalPlayer() then return end

	-- Line Trace解除
	if vrmod.debug.lineTraceActive then
		vrmod.debug.StopLineTrace()
	end

	-- フック発火カウンターリセット（エラーログは保持）
	for hookName, hookData in pairs(vrmod.debug.hooks) do
		hookData.fireCount = 0
		hookData.lastFire = 0
	end

	vrmod.debug.Log.Info("core", "VR exit cleanup complete")
end)

-- ----------------------------------------
-- コンソールコマンド
-- ----------------------------------------
concommand.Add("vrmod_unoff_debug_status", function()
	print("=== VRMod Debug System Status ===")
	print("  Enabled: " .. tostring(vrmod.debug.enabled))
	print("  Hooks monitoring: " .. tostring(debugHooksEnabled))
	print("  Log level: " .. tostring(logLevel))
	print("  Files indexed: " .. tostring(totalFiles))
	print("  Errors recorded: " .. tostring(#vrmod.debug.errors))
	print("  Line trace active: " .. tostring(vrmod.debug.lineTraceActive))
	if vrmod.debug.lineTraceFile then
		print("  Line trace file: " .. vrmod.debug.lineTraceFile)
	end
	print("=================================")
end)

--------[!vrmod_debug_core.lua]End--------
