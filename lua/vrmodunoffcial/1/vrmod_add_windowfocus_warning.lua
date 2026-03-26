-- --------[vrmod_add_windowfocus_warning.lua]Start--------
-- [v2.0統合済み] この機能は lua/autorun/client/vrmod_fps_guard.lua に統合されました
-- 統一ConVar: vrmod_unoff_fps_guard (0=無効, 1=有効)
if SERVER then return end

-- 旧ConVar: 既存の設定ファイルでエラーにならないよう定義だけ残す
CreateClientConVar("vrmod_unoff_windowfocus_enable", "1", true, FCVAR_ARCHIVE,
	"[Deprecated] Merged into vrmod_unoff_fps_guard")
-- --------[vrmod_add_windowfocus_warning.lua]End--------
