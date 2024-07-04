if SERVER then return end
local open = false
-- ConVarを作成
CreateClientConVar("vr_dummy_menu_toggle", 0, false)
function VRUtilDummyMenuOpen()
	if open then return end
	open = true
	-- 空白のメニューをMode = 2で開く
	VRUtilMenuOpen(
		"dummymenu",
		512,
		512,
		nil,
		2,
		Vector(34, 6, 10.5),
		Angle(0, -90, 90),
		0.03,
		true,
		function()
			-- Mode = 2
			open = false
			RunConsoleCommand("vr_dummy_menu_toggle", "0") -- メニューを閉じた時にConVarをリセット
		end
	)

	-- メニューのレンダリングフックを追加
	hook.Add(
		"PreRender",
		"vrutil_hook_renderdummymenu",
		function()
			VRUtilMenuRenderStart("dummymenu")
			-- 何もない大きなボタンを描画
			local buttonWidth, buttonHeight = 128, 128
			draw.RoundedBox(8, 0, 0, buttonWidth, buttonHeight, Color(0, 0, 0, 0))
			VRUtilMenuRenderEnd()
		end
	)
end

function VRUtilDummyMenuClose()
	VRUtilMenuClose("dummymenu")
	hook.Remove("PreRender", "vrutil_hook_renderdummymenu")
	open = false
end

-- ConVarの変更を監視
cvars.AddChangeCallback(
	"vr_dummy_menu_toggle",
	function(name, oldvalue, newvalue)
		if newvalue == "1" then
			VRUtilDummyMenuOpen()
		else
			VRUtilDummyMenuClose()
		end
	end, "VRDummyMenuToggle"
)