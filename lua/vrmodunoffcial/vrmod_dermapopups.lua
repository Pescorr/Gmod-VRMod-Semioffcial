if SERVER then return end
local meta = getmetatable(vgui.GetWorldPanel())
local orig = meta.MakePopup
local popupCount = 0
local basePos, baseAng
local _, convarValues = vrmod.GetConvars()
local vrScrH = CreateClientConVar("vrmod_ScrH", ScrH(), true, FCVAR_ARCHIVE)
local vrScrW = CreateClientConVar("vrmod_ScrW", ScrW(), true, FCVAR_ARCHIVE)
-- All active popups
local allPopups = {}
meta.MakePopup = function(...)
	local args = {...}
	orig(unpack(args))
	if not g_VR.threePoints then return end
	local panel = args[1]
	local uid = "popup_" .. popupCount
	table.insert(allPopups, uid)
	timer.Simple(
		0.1,
		function()
			if not IsValid(panel) then return end
			panel:SetPaintedManually(true)
			if panel:GetName() == "DMenu" then
				panel = panel:GetChildren()[1]
				panel.Paint = function(self, w, h)
					surface.SetDrawColor(150, 149, 160)
					surface.DrawRect(0, 0, w, h)
				end

				popupCount = popupCount + 1
			end

			if panel:GetName() == "DImage" then
				panel = panel:GetChildren()[1]
				panel.Paint = function(self, w, h)
					surface.SetDrawColor(175, 174, 187)
					surface.DrawRect(0, 0, w, h)
				end

				popupCount = popupCount + 1
			end

			if popupCount == 0 then
				local ang = Angle(0, g_VR.tracking.hmd.ang.yaw - 90, 45)
				basePos, baseAng = WorldToLocal(g_VR.tracking.hmd.pos + Vector(0, 0, -20) + Angle(0, g_VR.tracking.hmd.ang.yaw, 0):Forward() * 30 + ang:Forward() * vrScrW:GetInt() * -0.02 + ang:Right() * vrScrH:GetInt() * -0.02, ang, g_VR.origin, g_VR.originAngle)
			end

			local ang = baseAng
			local pos = basePos + ang:Up() * 10
			local mode = convarValues.vrmod_attach_popup
			if mode == 1 then
				VRUtilMenuOpen(
					uid,
					vrScrW:GetInt(),
					vrScrH:GetInt(),
					panel,
					mode,
					Vector(20, 11, 8),
					Angle(0, -90, 50),
					0.03,
					true,
					function()
						timer.Simple(
							0.1,
							function()
								if not g_VR.active and IsValid(panel) then
									panel:MakePopup()
									panel:RequestFocus()
								end
							end
						)

						popupCount = popupCount - 1
						for i, v in ipairs(allPopups) do
							if v == uid then
								table.remove(allPopups, i)
								break
							end
						end
					end
				)

				popupCount = popupCount + 1
				VRUtilMenuRenderPanel(uid)
			elseif mode == 3 then
				VRUtilMenuOpen(
					uid,
					vrScrW:GetInt(),
					vrScrH:GetInt(),
					panel,
					3,
					Vector(30, 20, 10),
					Angle(0, -90, 90),
					0.03,
					true,
					function()
						timer.Simple(
							0.1,
							function()
								if not g_VR.active and IsValid(panel) then
									panel:MakePopup()
									panel:RequestFocus()
								end
							end
						)

						popupCount = popupCount - 1
						for i, v in ipairs(allPopups) do
							if v == uid then
								table.remove(allPopups, i)
								break
							end
						end
					end
				)

				popupCount = popupCount + 1
				VRUtilMenuRenderPanel(uid)
			else
				VRUtilMenuOpen(
					uid,
					vrScrW:GetInt(),
					vrScrH:GetInt(),
					panel,
					mode,
					pos,
					ang,
					0.03,
					true,
					function()
						timer.Simple(
							0.1,
							function()
								if not g_VR.active and IsValid(panel) then
									panel:MakePopup()
									panel:RequestFocus()
								end
							end
						)

						popupCount = popupCount - 1
						for i, v in ipairs(allPopups) do
							if v == uid then
								table.remove(allPopups, i)
								break
							end
						end
					end
				)

				popupCount = popupCount + 1
				VRUtilMenuRenderPanel(uid)
			end
		end
	)
end

-- Render all popups every frame
hook.Add(
	"Think",
	"update_all_popups",
	function()
		for _, uid in ipairs(allPopups) do
			VRUtilMenuRenderPanel(uid)
		end
	end
)

hook.Add(
	"VRMod_Start",
	"dermapopups",
	function(ply)
		if ply ~= LocalPlayer() then return end
		vgui.GetWorldPanel():SetSize(vrScrW:GetInt(), vrScrH:GetInt())
	end
)

hook.Add(
	"VRMod_Exit",
	"dermapopups",
	function(ply)
		if ply ~= LocalPlayer() then return end
		vgui.GetWorldPanel():SetSize(vrScrW:GetInt(), vrScrH:GetInt())
	end
)