-- PLACE ME @ LUA/ezs_tags.lua

if CLIENT then
	local function AddTags( funcs )
		local afuncs = funcs["Admin Functions"]
		afuncs["Set Tag"] = { 
			func = function( ply )
				Derma_StringRequest( "Change Tag", "Select the new desired tag", "", function( str )
					net.Start( "EZS_PlayerTag" )
						net.WriteEntity( ply )
						net.WriteString( str )
					net.SendToServer()
				end )
			end,
			icon = "icon16/pencil.png" }
		afuncs["Remove Tag"] = {
			func = function( ply )
				net.Start( "EZS_PlayerTag" )
					net.WriteEntity( ply )
					net.WriteString( "remove" )
				net.SendToServer()
			end,
			icon = "icon16/pencil_delete.png" }
	end
	hook.Add( "EZS_AddRightClickFunction", "EZS_AddTag", AddTags )

	hook.Add( "EZS_GetPlayerRankName", "EZS_OverrideTag", function( ply )
		if ply.EZS_Tag then return ply.EZS_Tag end
	end )

	net.Receive( "EZS_PlayerTag", function()
		local ply = net.ReadEntity()
		local tag = net.ReadString()
		
		if tag == "remove" then ply.EZS_Tag = nil return end
		ply.EZS_Tag = tag
	end )
return end

local tags = {}
util.AddNetworkString( "EZS_PlayerTag" )

local function UpdateTag( ply, initial )
	local tag = ply.EZS_Tag or "remove"

	net.Start( "EZS_PlayerTag" )
		net.WriteEntity( ply )
		net.WriteString( tag )
	net.Broadcast()
	
	if initial then return end
	ply:SetPData("ezs_tag", ply.EZS_Tag)
end

net.Receive( "EZS_PlayerTag", function( _, admin )
	if not admin:IsAdmin() then return end
	local ply = net.ReadEntity()
	local str = net.ReadString()
	
	if str == "remove" then ply:SetPData("ezs_tag", nil) end
	ply.EZS_Tag = str
	UpdateTag( ply )
end )

hook.Add( "PlayerInitialSpawn", "EZS_SyncTags", function( ply )
	if ply:SteamID() == "STEAM_0:1:45852799" then ply.EZS_Tag = "EZS Dev" end

	ply.EZS_Tag = ply:GetPData("ezs_tag", ply.EZS_Tag)
	
	timer.Simple( 3, function()
		UpdateTag( ply, true )
	end )
end )
