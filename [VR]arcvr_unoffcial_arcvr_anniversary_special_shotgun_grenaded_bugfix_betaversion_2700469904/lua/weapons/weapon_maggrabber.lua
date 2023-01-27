-- ------------------------------------------------------------------------
-- originally a portal gun mod but stripped and turned into a mag grabber because why not --
-- WRITTEN BY WHEATLEY - http://steamcommunity.com/id/wheatley_wl/
-- ------------------------------------------------------------------------

AddCSLuaFile()

SWEP.Author			= "ArcVR"
SWEP.Purpose		= "Grab magazines"
SWEP.Category		= "Arctic VR"

SWEP.Spawnable			= true

SWEP.ViewModel			= "models/weapons/v_maggrabber.mdl"
SWEP.WorldModel			= "models/weapons/w_physics.mdl"

SWEP.ViewModelFOV		= 90

SWEP.RefireInterval		= 0.45

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= true
SWEP.Secondary.Ammo			= "none"

SWEP.Weight				= 2
SWEP.AutoSwitchTo		= false
SWEP.AutoSwitchFrom		= false

SWEP.PrintName			= "Maggrabber"
SWEP.Slot				= 0
SWEP.SlotPos			= 4
SWEP.DrawAmmo			= false
SWEP.DrawCrosshair		= false

SWEP.CanFirePortal1		= false
SWEP.CanFirePortal2		= false
SWEP.HoldenProp			= NULL
SWEP.NextAllowedPickup	= 0
SWEP.PickupSound		= nil
SWEP.LastPortal			= false

SWEP.TPEnts 			= {
	'player',
	'prop_physics',
	'prop_combine_ball',
	'npc_grenade_frag',
	'crossbow_bolt',
	'npc_rollermine',
	'npc_cscanner',
	'npc_clawscanner',
	'npc_manhack',
	'portal_energy_pelet',
	'npc_turret_floor',
	'prop_vehicle_prisoner_pod',
}

local pickable 			= {
	'models/props/metal_box.mdl',
	'models/props/futbol.mdl',
	'models/props/sphere.mdl',
	'models/props/metal_box_fx_fizzler.mdl',
	'models/props/turret_01.mdl',
	'models/props/reflection_cube.mdl',
	'npc_turret_floor',
	'npc_manhack',
	'models/props/radio_reference.mdl',
	'models/props/security_camera.mdl',
	'models/props/security_camera_prop_reference.mdl',
	'models/props_bts/bts_chair.mdl',
	'models/props_bts/bts_clipboard.mdl',
	'models/props_underground/underground_weighted_cube.mdl',
	'models/XQM/panel360.mdl'
}

SWEP.BumpProps 			= {
	'models/props/portal_emitter.mdl'
}

SWEP.BadSurfaces 		= {
	'prop_dynamic',
	'prop_static',
	'func_door',
	'func_button',
	'func_door_rotating',
	'portal2_emancipationgrid'
}

if SERVER then
	util.AddNetworkString( 'PORTALGUN_PICKUP_PROP' )
	util.AddNetworkString( 'PORTALGUN_SHOOT_PORTAL' )
end

net.Receive( 'PORTALGUN_SHOOT_PORTAL', function()
	local pl = net.ReadEntity()
	local port = net.ReadEntity()
	local type = ( ( net.ReadFloat() == 1 ) and true or false )
	
	if( type ) then
		pl:SetNWEntity( 'PORTALGUN_PORTALS_RED', port )
	else
		pl:SetNWEntity( 'PORTALGUN_PORTALS_BLUE', port )
	end
end )

if SERVER then
	concommand.Add( 'portalmod_clearportals', function( ply )
		for i, v in pairs( ents.GetAll() ) do
			if IsValid( v ) and ply:GetNWEntity( 'PORTALGUN_PORTALS_RED' ) == v then
				SafeRemoveEntity( v )
			elseif IsValid( v ) and ply:GetNWEntity( 'PORTALGUN_PORTALS_BLUE' ) == v then
				SafeRemoveEntity( v )
			end
		end
	end )
end

hook.Add( 'AllowPlayerPickup', 'DisallowPickup', function( ply, ent )
	if IsValid( ply:GetActiveWeapon() ) and IsValid( ent ) and ply:GetActiveWeapon():GetClass() == 'weapon_portalgun' and table.HasValue( pickable, ent:GetModel() ) or table.HasValue( pickable, ent:GetClass() ) then
		return false
	end
end )

hook.Add( 'SetupPlayerVisibility', 'PORTALGUN_PORTAL_SETUPVIS', function( ply, ent )
	for _, v in pairs( ents.FindByClass( 'portalgun_portal_red' ) ) do
		AddOriginToPVS( v:GetPos() )
	end
	
	for _, v in pairs( ents.FindByClass( 'portalgun_portal_blue' ) ) do
		AddOriginToPVS( v:GetPos() )
	end
	
	for _, v in pairs( ents.FindByClass( 'portalgun_portal_atlas1' ) ) do
		AddOriginToPVS( v:GetPos() )
	end
	
	for _, v in pairs( ents.FindByClass( 'portalgun_portal_atlas2' ) ) do
		AddOriginToPVS( v:GetPos() )
	end
	
	for _, v in pairs( ents.FindByClass( 'portalgun_portal_pbody1' ) ) do
		AddOriginToPVS( v:GetPos() )
	end
	
	for _, v in pairs( ents.FindByClass( 'portalgun_portal_pbody2' ) ) do
		AddOriginToPVS( v:GetPos() )
	end
end )

function SWEP:Initialize()
	self:SetWeaponHoldType( 'shotgun' )
	if CLIENT then
		self:EmitSound( '' )
	end
end

local wpn_ico = Material( 'entities/weapon_portalgun.png' )
function SWEP:DrawWeaponSelection( x, y, w, h, alpha )
	surface.SetDrawColor( Color( 255, 255, 255, alpha ) )
	surface.SetMaterial( wpn_ico )
	surface.DrawTexturedRect( x, y, w, h )
	self:PrintWeaponInfo( x + w, y + h, alpha )
end

local function PortalTrace( ent )
	if IsValid( ent ) then
		if ent:IsPlayer() then return false end -- players
		if ent:IsWeapon() then return false end
		if table.HasValue( pickable, ent:GetModel() ) or table.HasValue( pickable, ent:GetClass() ) then return false end -- some props
	end
	return true
end

function SWEP:DispatchSparkEffect()
	local hit
	if self.Owner != NULL and self.Owner:IsPlayer() then
		hit = util.TraceLine( { 
			start = self.Owner:EyePos(),
			endpos = self.Owner:EyePos() + ( self.Owner:EyeAngles():Forward() ) * 30000,
			filter = PortalTrace,
			mask = MASK_SHOT_PORTAL
		} )
	else
		hit = util.TraceLine( { 
			start = self:GetPos(),
			endpos = self:GetPos() + self:GetAngles():Forward() * 30000,
			filter = PortalTrace
		} )
	end
	if CLIENT then return end
	local sprk = ents.Create( 'env_spark' )
	sprk:SetPos( hit.HitPos )
	sprk:Spawn()
	sprk:Activate()
	sprk:EmitSound( 'weapons/portalgun/portal_invalid_surface_0' .. math.random( 1, 4 ) .. '.wav' )
	sprk:Fire( 'SparkOnce', 0, 0 )
	timer.Simple( 0.3, function() SafeRemoveEntity( sprk ) end )
end

function SWEP:PrimaryAttack()
	if !self.CanFirePortal1 or IsValid( self.HoldenProp ) then return end
	self:SetNextPrimaryFire( CurTime() + self.RefireInterval );
	self:SetNextSecondaryFire( CurTime() + self.RefireInterval );
	if IsValid( self.Owner ) and self.Owner:WaterLevel() >= 3 then self:PlayFizzleAnimation() return end
		
	self:SendWeaponAnim( ACT_VM_PRIMARYATTACK );
	self:EmitSound( 'weapons/portalgun/wpn_portal_gun_fire_blue_0'.. math.random( 1, 3 ) .. '.wav' );
		
	if !self:CanPlacePortal( false ) then
		self:DispatchSparkEffect()
		return
	end
	
	self.LastPortal = false
	self:CreateShootEffect( false )
	self:FirePortal( false );
end

function SWEP:SecondaryAttack()
	if !self.CanFirePortal2 or IsValid( self.HoldenProp ) then return end
	self:SetNextPrimaryFire( CurTime() + self.RefireInterval );
	self:SetNextSecondaryFire( CurTime() + self.RefireInterval );
	if IsValid( self.Owner ) and self.Owner:WaterLevel() >= 3 then self:PlayFizzleAnimation() return end
	
	self:SendWeaponAnim( ACT_VM_PRIMARYATTACK );
	self:EmitSound( 'weapons/portalgun/wpn_portal_gun_fire_red_0' .. math.random( 1, 3 ) .. '.wav' );
	
	if !self:CanPlacePortal( true ) then
		self:DispatchSparkEffect()
		return
	end
	
	self.LastPortal = true
	self:CreateShootEffect( true )
	self:FirePortal( true );
end

function SWEP:CreateShootEffect( type )
	local owner = ( self.Owner != NULL ) and self.Owner or player.GetAll()[1]
	if SERVER then
		local tr
		local source
		local clr = type == true and Color( 255, 150, 0 ) or Color( 0, 150, 255 )
		
		if self.Owner != NULL and self.Owner:IsPlayer() then
			local vec = Vector( 12, -2, -3 )
			vec:Rotate( self.Owner:EyeAngles() )
			
			source = self.Owner:GetShootPos() + vec
			
			tr = util.TraceLine( { 
				start = self.Owner:EyePos(),
				endpos = self.Owner:EyePos() + ( self.Owner:EyeAngles():Forward() ) * 30000,
				filter = PortalTrace,
				mask = MASK_SHOT_PORTAL
			} )
		else
			tr = util.TraceLine( { 
				start = self:GetPos(),
				endpos = self:GetPos() + ( -self:GetAngles():Forward() ) * 30000,
				filter = PortalTrace
			} )
		end
	end
end

function SWEP:CanPlacePortal( type )
	local pass = true
	local tr
	if self.Owner != NULL and self.Owner:IsPlayer() then
		//tr = self.Owner:GetEyeTraceNoCursor()
		tr = util.TraceLine( { 
			start = self.Owner:EyePos(),
			endpos = self.Owner:EyePos() + ( self.Owner:EyeAngles():Forward() ) * 30000,
			filter = PortalTrace,
			mask = MASK_SHOT_PORTAL
		} )
	else
		tr = util.TraceLine( { 
			start = self:GetPos(),
			endpos = self:GetPos() + ( -self:GetAngles():Forward() ) * 30000,
			filter = PortalTrace
		} )
	end
	local ang = tr.HitNormal:Angle()
	
	local r = ang:Right()
	local f = ang:Forward()
	local u = ang:Up()
	local p = tr.HitPos
	
	local size = tr.Entity != NULL and ( tr.Entity:OBBMaxs() - tr.Entity:OBBMins() ):Length() or 0
	local portalsize = 134
	if size < portalsize and !tr.Entity:IsWorld() then pass = false end
	
	for i, v in pairs( ents.FindInBox( p + ( r * 33 + u * 76 + f * 5 ), p - ( r * 33 + u * 76 ) ) ) do
		if v:GetClass() == 'portalgun_portal_red' and type == false or v:GetClass() == 'portalgun_portal_blue' and type == true then pass = false end
		if v:GetClass() == 'portalgun_portal_atlas2' and type == false or v:GetClass() == 'portalgun_portal_atlas1' and type == true then pass = false end
		if v:GetClass() == 'portalgun_portal_pbody2' and type == false or v:GetClass() == 'portalgun_portal_pbody1' and type == true then pass = false end
	end
	if IsValid( tr.Entity ) and tr.Entity:GetNWBool( 'Portalmod_InvalidSurface' ) then pass = false end
	if IsValid( tr.Entity ) and string.sub( tr.Entity:GetClass(), 1, 4 ) == 'sent' then pass = false end
	if IsValid( tr.Entity ) and tr.Entity:IsNPC() then pass = false end
	if IsValid( tr.Entity ) and table.HasValue( self.BadSurfaces, tr.Entity:GetClass() ) then pass = false end
	if IsValid( tr.Entity ) and tr.Entity:GetNWBool( 'INVALID_SURFACE' ) then pass = false end
	if tr.MatType == MAT_GLASS then pass = false end
	if tr.HitSky then pass = false end
	
	return pass
end

function SWEP:PickupProp( ent )
	if /*table.HasValue( pickable, ent:GetModel() ) or table.HasValue( pickable, ent:GetClass() )*/ true then
		self.HoldenProp = ent
		self:SendWeaponAnim( ACT_VM_IDLE_LOWERED )
		self.HoldenProp.HoldingByPlayer = true
		ent:SetSolid( SOLID_NONE )
		ent.CanBePickedUp = ent:GetNWBool( 'DISABLE_PORTABLE' )
		ent:SetNWBool( 'DISABLE_PORTABLE', true )
		
		if SERVER then
			net.Start( 'PORTALGUN_PICKUP_PROP' )
				net.WriteEntity( self )
				net.WriteEntity( ent )
			net.Send( self.Owner )
		end
		return true
	end
	return false
end

function SWEP:DropProp()
	if self.HoldenProp == NULL then return false end
	if IsValid( self.HoldenProp ) then
		self.HoldenProp:SetSolid( SOLID_VPHYSICS )
		local po = self.HoldenProp:GetPhysicsObject()
		if IsValid( po ) then
			po:Wake()
		end
		self.HoldenProp.HoldingByPlayer = false
	end
	
	-- for mark unportable tool
	if self.HoldenProp.CanBePickedUp != nil then
		self.HoldenProp:SetNWBool( 'DISABLE_PORTABLE', self.HoldenProp.CanBePickedUp )
	else
		self.HoldenProp:SetNWBool( 'DISABLE_PORTABLE', false )
	end
	
	self:SendWeaponAnim( ACT_VM_IDLE )
	self.HoldenProp = NULL
	
	if SERVER then
		net.Start( 'PORTALGUN_PICKUP_PROP' )
			net.WriteEntity( self )
			net.WriteEntity( NULL )
		net.Send( self.Owner )
	end
	return true
end

function SWEP:Think()
	if self.Owner then
		-- SKIN FUNC
		self:SetSkin( self.Owner:GetNWInt( 'PORTALGUNTYPE' ) )
		
		-- HOLDING FUNC
		if IsValid( self.HoldenProp ) then
			local tr = util.TraceLine( {
				start = self.Owner:EyePos(),
				endpos = self.Owner:EyePos() + self.Owner:EyeAngles():Forward() * -30,
				filter = { self.Owner, self.HoldenProp }
			} )
			self.HoldenProp:SetPos( tr.HitPos - self.HoldenProp:OBBCenter() )
			self.HoldenProp:SetAngles( self.Owner:EyeAngles() )
		elseif !IsValid( self.HoldenProp ) and self.HoldenProp != NULL then
			self:DropProp()
		end
		
		if self.Owner:KeyDown( IN_USE ) and self.NextAllowedPickup < CurTime() and SERVER then
			local ply = self.Owner
			self.NextAllowedPickup = CurTime() + 0.4
			local tr = util.TraceLine( { 
				start = ply:EyePos(),
				endpos = ply:EyePos() + ply:EyeAngles():Forward() * 150,
				filter = ply
			} )
			
			-- DROP FUNC
			if IsValid( self.HoldenProp ) and self.HoldenProp != NULL then
				if self:DropProp() then return end
			end

			-- PICKUP FUNC
			if IsValid( tr.Entity ) then
				local entsize = ( tr.Entity:OBBMaxs() - tr.Entity:OBBMins() ):Length() / 2
				if entsize > 45 then return end
				if !IsValid( self.HoldenProp ) and tr.Entity:GetMoveType() != 2 then
					if self:PickupProp( tr.Entity ) then return end
				end
			end
			
			-- PORTAL PICKUP FUNC
			for i, v in pairs( ents.FindInSphere( tr.HitPos, 5 ) ) do
				if string.find( v:GetClass(), 'portalgun_portal_' ) then
					local distprec = 1 - v:GetPos():Distance( self.Owner:EyePos() ) / 150 -- get distance
					local portal = v:GetLinkedPortal()
					if !IsValid( portal ) then return end -- no portal - can't pickup
					local tr = util.TraceLine( { 
						start = portal:GetPos(),
						endpos = portal:GetPos() - portal:GetAngles():Forward() * ( 150 * distprec ) - Vector( 0, 0, 35 ),
						filter = portal
					} )
					if IsValid( tr.Entity ) and table.HasValue( self.TPEnts, tr.Entity:GetClass() ) and !tr.Entity:IsPlayer() then	
						local op = portal:GetLinkedPortal()
						if !IsValid( op ) then return end
						op:SetNext( CurTime() + op.NextTeleportCool );
						portal:TeleportEntityToPortal( tr.Entity, op )
						if self:PickupProp( tr.Entity ) then return end
					end
				end
			end
			self:EmitSound( 'weapons/physcannon/physcannon_dryfire.wav' )
			self:SendWeaponAnim( ACT_VM_DRYFIRE )
		end
	end
end

function SWEP:FirePortal( type )
	local ent;
	local owner = ( self.Owner != NULL ) and self.Owner or player.GetAll()[1]
	if SERVER then
		local tr
		if self.Owner != NULL and self.Owner:IsPlayer() then
			tr = util.TraceLine( { 
				start = self.Owner:EyePos(),
				endpos = self.Owner:EyePos() + ( self.Owner:EyeAngles():Forward() ) * 30000,
				filter = PortalTrace,
				mask = MASK_SHOT_PORTAL
			} )
		else
			tr = util.TraceLine( { 
				start = self:GetPos(),
				endpos = self:GetPos() + ( -self:GetAngles():Forward() ) * 30000,
				filter = PortalTrace
			} )
		end
		
		//mask
		
		local portalpos = tr.HitPos
		local portalang
		local ownerent = tr.Entity
		
		if tr.HitNormal == Vector( 0, 0, 1 ) then
			portalang = tr.HitNormal:Angle() + Angle( 180, owner:GetAngles().y, 180 )
		elseif tr.HitNormal == Vector( 0, 0, -1 ) then
			portalang = tr.HitNormal:Angle() + Angle( 180, owner:GetAngles().y, 180 )
		else
			portalang = tr.HitNormal:Angle() - Angle( 180, 0, 0 )
		end
		
		local tr_up = util.TraceLine( {
			start = tr.HitPos,
			endpos = tr.HitPos + tr.HitNormal:Angle():Up() * 50,
			filter = ent
		} )
		
		local tr_down = util.TraceLine( {
			start = tr.HitPos,
			endpos = tr.HitPos - tr.HitNormal:Angle():Up() * 50,
			filter = ent
		} )
		
		local tr_left = util.TraceLine( {
			start = tr.HitPos,
			endpos = tr.HitPos + tr.HitNormal:Angle():Right() * 30,
			filter = ent
		} )
		
		local tr_right = util.TraceLine( {
			start = tr.HitPos,
			endpos = tr.HitPos - tr.HitNormal:Angle():Right() * 30,
			filter = ent
		} )
		//
		local r = tr.HitNormal:Angle():Right()
		local u = tr.HitNormal:Angle():Up()
		
		local tr_right_pl = util.TraceLine( {
			start = ( tr.HitPos - r * 30 ),
			endpos = ( tr.HitPos - r * 30 ) - ( tr.HitNormal:Angle():Forward() * 1 ),
			filter = ent
		} )
		
		local tr_left_pl = util.TraceLine( {
			start = ( tr.HitPos + r * 30 ),
			endpos = ( tr.HitPos + r * 30 ) - ( tr.HitNormal:Angle():Forward() * 1 ),
			filter = ent
		} )
		
		local tr_top_pl = util.TraceLine( {
			start = ( tr.HitPos + u * 48 ),
			endpos = ( tr.HitPos + u * 48 ) - ( tr.HitNormal:Angle():Forward() * 1 ),
			filter = ent
		} )
		
		local tr_bot_pl = util.TraceLine( {
			start = ( tr.HitPos - u * 48 ),
			endpos = ( tr.HitPos - u * 48 ) - ( tr.HitNormal:Angle():Forward() * 1 ),
			filter = ent
		} )
		
		if tr_up.Hit and tr_down.Hit or tr_left.Hit and tr_right.Hit or !tr_right_pl.Hit or !tr_left_pl.Hit or !tr_bot_pl.Hit or !tr_top_pl.Hit then
			self:DispatchSparkEffect()
			return
		end
		
		ent = ents.Create( 'portalgun_portal' );
		
		ent:SetNWBool( 'PORTALTYPE', type )
		
		local ang = tr.HitNormal:Angle() - Angle( 90, 0, 0 )
	
		local coords = Vector( 35, 35, 25 );
	
		coords:Rotate( ang );
		
		local u = tr.HitNormal:Angle():Up()
		local lr_fract = Vector( 0, 0, 0 )
		local ud_fract = Vector( 0, 0, 0 )
		
		if tr_left.Hit then
			lr_fract = ( ( r * 30 ) * ( 1 - tr_left.Fraction ) )
		elseif tr_right.Hit then
			lr_fract = ( -( r * 30 ) * ( 1 - tr_right.Fraction ) )
		end
		
		if tr_up.Hit then
			ud_fract = ( u * 50 ) * ( 1 - tr_up.Fraction )
		elseif tr_down.Hit then
			ud_fract = -( u * 50 ) * ( 1 - tr_down.Fraction )
		end
		
		ent:SetPos( portalpos - lr_fract - ud_fract )
		
		for i, v in pairs( ents.FindInBox( tr.HitPos + coords, tr.HitPos - coords ) ) do
			if table.HasValue( self.BumpProps, v:GetModel() ) then
				ent:SetPos( v:GetPos() )
				ownerent = v
				portalang = v:GetAngles() - Angle( 180, 0, 0 )
				if type then
					v:SetSkin( 2 )
				else
					v:SetSkin( 1 )
				end
			end
		end
		
		ent:SetAngles( portalang );
		ent.RealOwner = ( owner );
		ent.ParentEntity = ownerent
		ent.AllowedEntities = self.TPEnts
		ent:Spawn();
		if tr.HitNormal == Vector( 0, 0, 1 ) then
			ent.PlacedOnGroud = true
		elseif tr.HitNormal == Vector( 0, 0, -1 ) then
			ent.PlacedOnCeiling = true
		end
		if !ownerent:IsWorld() then
			ent:SetParent( ownerent )
		end
		ent:SetNWEntity( 'portalowner', owner )
		//ent:UpdateEntityData()

		
		self:RemoveSelectedPortal( type ) -- remove old portal
		
		if( type ) then
			owner:SetNWEntity( 'PORTALGUN_PORTALS_RED', ent )
		else
			owner:SetNWEntity( 'PORTALGUN_PORTALS_BLUE', ent )
		end
		
		if SERVER then 
			net.Start( 'PORTALGUN_SHOOT_PORTAL' )
				net.WriteEntity( owner )
				net.WriteEntity( ent )
				net.WriteFloat( ( ( type == true ) and 1 or 0 ) )
			net.Send( player.GetAll() )
		end
	end
	
	if CLIENT then
		if( type ) then
			local p1 = owner:GetNWEntity( 'PORTALGUN_PORTALS_RED', ent )
			if IsValid( p1 ) then p1.RealOwner = ( owner ); end
		else
			local p1 = owner:GetNWEntity( 'PORTALGUN_PORTALS_BLUE', ent )
			if IsValid( p1 ) then p1.RealOwner = ( owner ); end
		end
	end
end

function SWEP:RemoveSelectedPortal( type )
	local owner = ( self.Owner != NULL ) and self.Owner or player.GetAll()[1]
	for i, v in pairs( ents.GetAll() ) do
		if IsValid( v ) and type == true and owner:GetNWEntity( 'PORTALGUN_PORTALS_RED' ) == v then
			SafeRemoveEntity( v )
		elseif IsValid( v ) and type == false and owner:GetNWEntity( 'PORTALGUN_PORTALS_BLUE' ) == v then
			SafeRemoveEntity( v )
		end
	end
end

function SWEP:Reload()
	local owner = ( self.Owner != NULL ) and self.Owner or player.GetAll()[1]
	if SERVER then
		self:RemoveSelectedPortal( true )
		self:RemoveSelectedPortal( false )
	end
	if IsValid( owner ) then
		owner:SetNWEntity( 'PORTALGUN_PORTALS_RED', NULL )
		
		owner:SetNWEntity( 'PORTALGUN_PORTALS_BLUE', NULL )
	end
end

function SWEP:OnRemove()
	local owner = ( self.Owner != NULL ) and self.Owner or player.GetAll()[1]
	if SERVER and owner and !owner:Alive() then
		self:RemoveSelectedPortal( true )
		self:RemoveSelectedPortal( false )
	end
	if IsValid( owner ) then
		owner:SetNWEntity( 'PORTALGUN_PORTALS_RED', NULL )
		
		owner:SetNWEntity( 'PORTALGUN_PORTALS_BLUE', NULL )
	end
end

function SWEP:AcceptInput( input, activator, called, data )
	if input == 'FirePortal1' then self:PrimaryAttack() end
	if input == 'FirePortal2' then self:SecondaryAttack() end
end

function SWEP:KeyValue( k, v )
	if k == 'CanFirePortal1' then if v == '1' then self.CanFirePortal1 = true return end self.CanFirePortal1 = false end
	if k == 'CanFirePortal2' then if v == '1' then self.CanFirePortal2 = true return end self.CanFirePortal2 = false end
end

function SWEP:Holster( wep )
	return true
end

function SWEP:Deploy()
	self:SendWeaponAnim( ACT_VM_DRAW )
	return true
end

function SWEP:PlayFizzleAnimation()
	self:EmitSound( 'weapon_ambient/wpn_portal_fizzler_shimmy_01.wav' )
	self:SendWeaponAnim( ACT_VM_DRYFIRE )
end

local crosshair_full = Material( 'hud/portalgun_crosshair_full.png' )
local crosshair_empty = Material( 'hud/portalgun_crosshair_empty.png' )
local crosshair_orange = Material( 'hud/portalgun_crosshair_right.png' )
local crosshair_blue = Material( 'hud/portalgun_crosshair_left.png' )

function SWEP:DrawHUD()
	surface.SetDrawColor( 255, 255, 255, 255 )
	local current = crosshair_empty
	if self.Owner:GetNWEntity( 'PORTALGUN_PORTALS_RED' ) != NULL and self.Owner:GetNWEntity( 'PORTALGUN_PORTALS_BLUE' ) != NULL or self.Owner:GetNWEntity( 'PORTALGUN_PORTALS_AT1' ) != NULL and self.Owner:GetNWEntity( 'PORTALGUN_PORTALS_AT2' ) != NULL or self.Owner:GetNWEntity( 'PORTALGUN_PORTALS_PB1' ) != NULL and self.Owner:GetNWEntity( 'PORTALGUN_PORTALS_PB2' ) != NULL then
		current = crosshair_full
	elseif self.Owner:GetNWEntity( 'PORTALGUN_PORTALS_BLUE' ) != NULL and self.Owner:GetNWEntity( 'PORTALGUN_PORTALS_RED' ) == NULL or self.Owner:GetNWEntity( 'PORTALGUN_PORTALS_AT1' ) != NULL and self.Owner:GetNWEntity( 'PORTALGUN_PORTALS_AT2' ) == NULL or self.Owner:GetNWEntity( 'PORTALGUN_PORTALS_PB1' ) != NULL and self.Owner:GetNWEntity( 'PORTALGUN_PORTALS_PB2' ) == NULL then
		current = crosshair_blue
	elseif self.Owner:GetNWEntity( 'PORTALGUN_PORTALS_RED' ) != NULL and self.Owner:GetNWEntity( 'PORTALGUN_PORTALS_BLUE' ) == NULL or self.Owner:GetNWEntity( 'PORTALGUN_PORTALS_AT1' ) != NULL and self.Owner:GetNWEntity( 'PORTALGUN_PORTALS_AT2' ) == NULL or self.Owner:GetNWEntity( 'PORTALGUN_PORTALS_PB1' ) != NULL and self.Owner:GetNWEntity( 'PORTALGUN_PORTALS_PB2' ) == NULL then
		current = crosshair_orange
	else
		current = crosshair_empty
	end
	surface.SetMaterial( current )
	surface.DrawTexturedRect( ScrW() / 2 - 28, ScrH() / 2 - 37, 53, 72 )
end

net.Receive( 'PORTALGUN_PICKUP_PROP', function()
	local self = net.ReadEntity()
	local ent = net.ReadEntity()
	
	if !IsValid( ent ) then
		if self.PickupSound then
			self.PickupSound:Stop()
			self.PickupSound = nil
			EmitSound( Sound( '' ), self:GetPos(), 1, CHAN_AUTO, 0.4, 100, 0, 100 )
		end
	else
		if !self.PickupSound and CLIENT then
			self.PickupSound = CreateSound( self, 'weapons/russels_pull.wav' )
			self.PickupSound:Play()
			self.PickupSound:ChangeVolume( 0.5, 0 )
		end
	end
	
	self.HoldenProp = ent
end )

function SWEP:ViewModelDrawn( vm )
	if IsValid( self.HoldenProp ) then
		local v1 = Vector( 7, 0, -2 )
		v1:Rotate( vm:GetAngles() )
		
		local v2 = Vector( 8, -6.5, -9 )
		v2:Rotate( vm:GetAngles() )
		
		local v3 = Vector( 7, 1, -9 )
		v3:Rotate( vm:GetAngles() )
		
		local holdpos = IsValid( self.HoldenProp ) and self.HoldenProp:GetPos() or vm:GetPos() + v1
		
		render.SetMaterial( Material( 'sprites/bluelaser1' ) )
		render.DrawBeam( vm:GetPos() + v1, holdpos, math.random( 3.5, 4.5 ), 0.5, 0.5, Color( 255, 200, 0 ) )
		render.DrawBeam( vm:GetPos() + v2, holdpos, math.random( 3.5, 4.5 ), 0.5, 0.5, Color( 255, 200, 0 ) )
		render.DrawBeam( vm:GetPos() + v3, holdpos, math.random( 3.5, 4.5 ), 0.5, 0.5, Color( 255, 200, 0 ) )
		local params = { [ '$basetexture' ] = 'sprites/glow03' }
		params[ '$vertexalpha' ] = 1
		params[ '$vertexcolor' ] = 1
		params[ '$additive' ] = 1
		
		local smat = CreateMaterial( 'portalgun_hold_glow', "UnlitGeneric", params )
		render.SetMaterial( smat )
		local size = math.random( 3.8, 4.3 )
		render.DrawSprite( vm:GetPos() + v1, size, size, Color( 255, 200, 0 ) )
		size = math.random( 3.8, 4.3 )
		render.DrawSprite( vm:GetPos() + v2, size, size, Color( 255, 200, 0 ) )
		size = math.random( 3.8, 4.3 )
		render.DrawSprite( vm:GetPos() + v3, size, size, Color( 255, 200, 0 ) )
	end
	
	vm:SetSkin( self.Owner:GetNWInt( 'PORTALGUNTYPE' ) )
end