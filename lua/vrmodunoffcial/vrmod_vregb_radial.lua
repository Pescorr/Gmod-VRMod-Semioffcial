if SERVER then return end

local open = false

local openconvar = CreateClientConVar("vrmod_gbradial_cmd_open","+gb-radial",true,FCVAR_ARCHIVE)
local closeconvar = CreateClientConVar("vrmod_gbradial_cmd_close","-gb-radial",true,FCVAR_ARCHIVE)
local cl_hudonlykey = CreateClientConVar("vrmod_hud_visible_quickmenukey", "0", true, FCVAR_ARCHIVE)

function VREgb_radialToggle()
    if !open then
        VREgb_radialOpen()
    else
        VRUtilMenuClose("vremenu_gb_radial")
			LocalPlayer():ConCommand(closeconvar:GetString())
            if cl_hudonlykey:GetBool() then
                LocalPlayer():ConCommand("vrmod_hud 0")
            end
    end
end


function VREgb_radialOpen()
	if open then return end
    open = true

    local vregb_radialPanel = vgui.Create( "DPanel" )
    vregb_radialPanel:SetPos( 0, 0 )
    vregb_radialPanel:SetSize( ScrW(), ScrH() )
    function vregb_radialPanel:GetSize()
        return ScrW(),ScrH()
    end

    if cl_hudonlykey:GetBool() then
        LocalPlayer():ConCommand("vrmod_hud 1")
    end


    local settingsgrid = vgui.Create("DGrid", vregb_radialPanel)
    settingsgrid:SetPos( 10, 30 )
    settingsgrid:SetCols( 4 )
    settingsgrid:SetColWide( 150 )
    settingsgrid:SetRowHeight( 80 )


    local backbutton = vgui.Create("DButton", vregb_radialPanel)

    backbutton:SetText("<---")
    backbutton:SetSize(120, 60)
    backbutton:SetPos(0, 0)
    backbutton:SetTextColor(Color(255, 255, 255))
    backbutton.DoClick = function()
        VRUtilMenuClose("vremenu_vrmod")
        VREMenuToggle()
        LocalPlayer():ConCommand(closeconvar:GetString())
    end


    function backbutton:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(0,122,204))
    end


    -- Menu code starts here

    LocalPlayer():ConCommand(openconvar:GetString())

    if cl_hudonlykey:GetBool() then
        LocalPlayer():ConCommand("vrmod_hud 1")
    end



    -- Menu code ends here
	
	
	
	local ply = LocalPlayer()
	
	local renderCount = 0
	
	local tmp = Angle(0,g_VR.tracking.hmd.ang.yaw-90,45) --Forward() = right, Right() = back, Up() = up (relative to panel, panel forward is looking at top of panel from middle of panel, up is normal)
    local pos, ang = WorldToLocal( g_VR.tracking.pose_righthand.pos + tmp:Forward()*-9 + tmp:Right()*-11 + tmp:Up()*-7, tmp, g_VR.origin, g_VR.originAngle)
    local mode = 4
    --uid, width, height, panel, attachment, pos, ang, scale, cursorEnabled, closeFunc
    
    if vre_menuguiattachment:GetInt("vre_ui_attachtohand") == 1 then
        pos, ang = Vector(4,6,5), Angle(0,-90,10)
        mode = 1
    else
        pos, ang = WorldToLocal( g_VR.tracking.pose_righthand.pos + tmp:Forward()*-9 + tmp:Right()*-11 + tmp:Up()*-7, tmp, g_VR.origin, g_VR.originAngle)
        mode = 4
    end

    VRUtilMenuOpen("vremenu_gb_radial", ScrW(), ScrH(), vregb_radialPanel, mode, pos, ang, 0.01, true, function()
        vregb_radialPanel:Remove()
        vregb_radialPanel = nil
         hook.Remove("PreRender","vre_rendergb_radial")
         LocalPlayer():ConCommand(closeconvar:GetString())
		 open = false
	end)
	
    hook.Add("PreRender","vre_rendergb_radialmenu",function()
        if VRUtilIsMenuOpen("miscmenu") or VRUtilIsMenuOpen("vremenu") then
            VRUtilMenuClose("vremenu_gb_radial")
        elseif IsValid(vregb_radialPanel) then
            function vregb_radialPanel:Paint( w, h )
                surface.SetDrawColor( Color( 51, 51, 51, 200 ) )
                surface.DrawRect(0,0,w,h)
            end
            VRUtilMenuRenderPanel("vremenu_gb_radial")
        end
	end)
	
end
concommand.Add( "vre_gb-radial", function( ply, cmd, args )
    if g_VR.net[ply:SteamID()] then
        VREgb_radialToggle()
    end
end)
