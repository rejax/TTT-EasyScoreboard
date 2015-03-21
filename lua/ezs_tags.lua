-- PLACE ME @ LUA/AUTORUN/ezs_tags.lua

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
		if ply.IsValid then return end
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

local function UpdateTag( ply, up )
	net.Start( "EZS_PlayerTag" )
		net.WriteEntity( ply )
		net.WriteString( ply.EZS_Tag )
	net.Broadcast()
	
	if ply.EZS_Tag == "remove" or up then return end
	sql.Query( ([[
		REPLACE INTO `ezs_tags` ( `id`, `tag` )
		VALUES( %d, %s );
	]]):format( ply:UniqueID(), ply.EZS_Tag ) )
end

net.Receive( "EZS_PlayerTag", function( _, admin )
	if not admin:IsAdmin() then return end
	local ply = net.ReadEntity()
	local str = net.ReadString()
	
	-- fuck off we're doing it like this
	if str == "remove" then sql.Query( ([[DELETE FROM `ezs_tags` WHERE `id`=%d]]):format( ply.EZS_ID ) ) end
	ply.EZS_Tag = str
	UpdateTag( ply )
end )

local function InitTags()
	if not sql.TableExists( "ezs_tags" ) then
		sql.Query( [[CREATE TABLE `ezs_tags` (
			`id` INTEGER NOT NULL PRIMARY KEY,
			`tag` TEXT
			);
		]] )
		
		local s = sql.Query( [[
			INSERT INTO `ezs_tags` ( `id`, `tag` )
			VALUES( 3208878610, 'EZS Dev' );
		]] )
	else
		local _tags = sql.Query( [[SELECT * FROM `ezs_tags`]] )
		for _, tag in pairs( _tags ) do tags[tostring(tag.id)] = tag.tag end
	end
end
InitTags()

hook.Add( "PlayerInitialSpawn", "EZS_SyncTags", function( ply )
	ply.EZS_ID = tostring( ply:UniqueID() )
	if tags[ply.EZS_ID] then ply.EZS_Tag = tags[ply.EZS_ID] else return end
	
	UpdateTag( ply, true )
	
	timer.Simple( 3, function() 
		net.Start( "EZS_PlayerTag" )
			net.WriteEntity( ply )
			net.WriteString( ply.EZS_Tag )
		net.Send( ply )
	end )
end )
