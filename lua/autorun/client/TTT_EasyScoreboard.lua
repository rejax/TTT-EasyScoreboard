EZS = {} -- what's one more global to the fray
EZS.Ranks = {}

--[[ CONFIG ]]--
EZS.Enabled = true

-- you can set a silkicon to be used, by adding a "icon" field. for example: icon = "heart" will be drawn as "icon16/heart.png"
-- for a full list of silkicons, go to http://www.famfamfam.com/lab/icons/silk/previews/index_abc.png

--EZS.Ranks["rank OR steamid"] = { name = "displayname", color = RankColor, namecolor = (optional), admin = are they admin? (true/false) }
EZS.Ranks["superadmin"] = { name = "S. Admin", color = Color( 255, 0, 0 ), namecolor = Color( 0, 255, 0 ), admin = true }
EZS.Ranks["admin"] = { name = "Admin", color = Color( 150, 100, 100 ), admin = true }
EZS.Ranks["donator"] = { name = "Donator", color = Color( 100, 200, 100 ), admin = false }

-- it would be nice if you left this in :)
EZS.Ranks["STEAM_0:1:45852799"] = { color = Color( 100, 200, 100 ), icon = "bug", admin = false }

-- label enable on the top? what should it say?
EZS.CreateRankLabel = { enabled = true, text = "Rank" } 

-- sadly there is no way to shift the background bar over as TTT draws it manually :c
EZS.HideBackground = false

-- Width of the rank columns
EZS.ColumnWidth = 50

-- the number of columns (not pixels!!!!!!!) to shift to the left
EZS.ShiftLeft = 0

-- shift tags, search marker, etc how much? (IN PIXELS)
EZS.ShiftOthers = 200

-- Show icon as well as rank text? (if possible)
EZS.ShowIconsWithRanks = true

-- How far left should we shift the icon relative to the rank text?
EZS.ShiftRankIcon = 1

-- should we color the names?
EZS.UseNameColors = true

-- should names get rainbow?
EZS.AllowNamesToHaveRainbow = true

-- frequency of rainbow (if enabled)
EZS.RainbowFrequency = .5

EZS.RightClickFunction = { enabled = true, ask_admins = true, functions = {
		["User Functions"] = {
			["Show Profile"] = function( ply )
				ply:ShowProfile()
			end,
			["Copy SteamID"] = function( ply )
				SetClipboardText( ply:SteamID() )
				chat.AddText( color_white, ply:Nick() .. "'s SteamID (", Color( 200, 200, 200 ), ply:SteamID(), color_white, ") copied to clipboard!" )
			end,
			
			_icon = "icon16/group.png",
		},
		["Admin Functions"]	= {
			{ 
				["Kick"] = { func = function( ply )
					RunConsoleCommand( "ulx", "kick", ply:Nick():gsub( ";", "" ) )
				end, icon = "icon16/user_delete.png" },
				["Slay"] = { func = function( ply )
					RunConsoleCommand( "ulx", "slay", ply:Nick():gsub( ";", "" ) )
				end, icon = "icon16/pill.png" },
			},
			
			{
				["Mute"] = { func = function( ply )
					RunConsoleCommand( "ulx", "mute", ply:Nick():gsub( ";", "" ) )
				end, icon = "icon16/pill.png" },
				["Un-Mute"] = { func = function( ply )
					RunConsoleCommand( "ulx", "unmute", ply:Nick():gsub( ";", "" ) )
				end, icon = "icon16/pill.png" },
			},
			
			{
				["Gag"] = { func = function( ply )
					RunConsoleCommand( "ulx", "gag", ply:Nick():gsub( ";", "" ) )
				end, icon = "icon16/sound_mute.png" },
				["Un-Gag"] = { func = function( ply )
					RunConsoleCommand( "ulx", "ungag", ply:Nick():gsub( ";", "" ) )
				end, icon = "icon16/sound.png" },
			},
			
			{
				["Goto"] = { func = function( ply )
					RunConsoleCommand( "ulx", "goto", ply:Nick():gsub( ";", "" ) )
				end, icon = "icon16/sound_mute.png" },
				["Bring"] = { func = function( ply )
					RunConsoleCommand( "ulx", "bring", ply:Nick():gsub( ";", "" ) )
				end, icon = "icon16/sound.png" },
			},
			
			_icon = "icon16/shield.png",
		}
	}
}
hook.Run( "EZS_AddRightClickFunction", EZS.RightClickFunction.functions )
--[[ END CONFIG ]]--

for id, rank in pairs( EZS.Ranks ) do
	if rank.icon then
		rank.__iconmat = Material( ("icon16/%s.png"):format( rank.icon ) )
	end
end

local function RealUserGroup( ply )
	if ply.EV_GetRank then return ply:EV_GetRank() end
	return ply:GetUserGroup()
end

local function rainbow()
	local frequency, time = EZS.RainbowFrequency, RealTime()
	local red = math.sin( frequency * time ) * 127 + 128
	local green = math.sin( frequency * time + 2 ) * 127 + 128
	local blue = math.sin( frequency * time + 4 ) * 127 + 128
	return Color( red, green, blue )
end

function EZS.HandleShift( sb )
	if EZS.ShiftLeft < 1 then return end
	
	local function ShiftLeft( parent )
		local k = EZS.HideBackground and 6 or 5
		local p = parent.cols[k]
		
		if not p then return end
		
		local shift = EZS.HideBackground and 1 or 0
		local karma = KARMA.IsEnabled() and 0 or 1
		local left = ( 5 - karma ) - EZS.ShiftLeft
		local posx, posy = p:GetPos()
		local mod = ( 50 * ( ( left + shift ) - #parent.cols ) )
		
		p:SetPos( posx + mod, posy )
	end
	
	if sb.ply_groups then -- sb_main
		local OldPerformLayout = sb.PerformLayout
		sb.PerformLayout = function( s )
			OldPerformLayout( s )
			ShiftLeft( s )
		end
	else -- sb_row
		local OldLayoutColumns = sb.LayoutColumns
		sb.LayoutColumns = function( s )
			OldLayoutColumns( s )
			ShiftLeft( s )
			EZS.HandleTags( s )
		end
	end
end

function EZS.HandleTags( sb )
	if EZS.ShiftOthers <= 0 then return end
	
	-- copy some from base
	local cx = sb:GetWide() - 90
	for k,v in ipairs(sb.cols) do
		cx = cx - v.Width
	end
	
	sb.tag:SizeToContents()
	sb.tag:SetPos((cx - sb.tag:GetWide()/2) - EZS.ShiftOthers, (SB_ROW_HEIGHT - sb.tag:GetTall()) / 2)
	
	sb.sresult:SizeToContents()
	sb.sresult:SetPos((cx - 8)-EZS.ShiftOthers, (SB_ROW_HEIGHT - 16) / 2)
end

function EZS.AddSpacer( w )
	EZS.Scoreboard:AddColumn( "", function() return "" end, w or 0 )
end

function EZS.AddRankLabel( sb )
	EZS.Scoreboard = sb
	local heading = EZS.CreateRankLabel.enabled and EZS.CreateRankLabel.text or ""
	
	local function RainbowFunction( label, key )
		label.HasRainbow = true
		label.Think = function( s )
			if EZS.Ranks[key] and EZS.Ranks[key].color ~= "rainbow" then
				s:SetTextColor( EZS.Ranks[key].color )
			else
				s:SetTextColor( rainbow() )
			end
		end
		sb.nick.Think = function( s )
			if EZS.Ranks[key] and EZS.Ranks[key].color ~= "rainbow" then
				s:SetTextColor( EZS.Ranks[key].color )
			else
				if EZS.AllowNamesToHaveRainbow then
					s:SetTextColor( rainbow() )
				end
			end
		end
	end
	
	if EZS.HideBackground and KARMA.IsEnabled() then -- ttt pls
		EZS.AddSpacer()
	end
	
	sb:AddColumn( heading, function( ply, label )
		local key = ply:SteamID()
		if not EZS.Ranks[key] then key = RealUserGroup( ply ) end
		local rank = EZS.Ranks[key]
		
		local ov_name = hook.Run( "EZS_GetPlayerRankName", ply )
		if ov_name and not rank then return ov_name end
		
		if not rank and not ov_name then return "" end
		
		label:SetName( "EZS" )
		
		if rank.offset then
			local px, py = label:GetPos()
			label:SetPos( px - rank.offset, py )
		end
		
		if rank.icon and not rank.__iconmat:IsError() then
			label.Paint = function( s, w, h )
				surface.DisableClipping( true )
					surface.SetDrawColor( color_white )
					surface.SetMaterial( rank.__iconmat )
					
					local posx = -6
					
					if rank.name and EZS.ShowIconsWithRanks then
						posx = 0 - s:GetTextSize() - EZS.ShiftRankIcon
					end
					
					surface.DrawTexturedRect( posx, -1, rank.__iconmat:Width(), rank.__iconmat:Height() )
				surface.DisableClipping( false )
			end
			
			if not rank.name then return " " end
		end
		
		if rank.color ~= "rainbow" then
			label.Think = function( s )
				if EZS.Ranks[key] and EZS.Ranks[key].color ~= "rainbow" then
					s:SetTextColor( EZS.Ranks[key].color )
				else
					s:SetTextColor( rainbow() )
				end
			end
		elseif not label.HasRainbow then
			RainbowFunction( label, key )
		end

		if ov_name then return ov_name end
		return rank.name
	end, EZS.ColumnWidth )
	
	EZS.HandleShift( sb )
	
	hook.Run( "EZS_AddColumns", sb )
end
hook.Add( "TTTScoreboardColumns", "EZS_Columns", EZS.AddRankLabel )

local function AddNameColors( ply )
	if not EZS.UseNameColors then return end
	local col = EZS.Ranks[ply:SteamID()]
	if not col then col = EZS.Ranks[RealUserGroup( ply )] end
	if not col then return color_white end
	
	local color = col.namecolor == nil and col.color or col.namecolor
	if color == "rainbow" then
		color = EZS.AllowNamesToHaveRainbow and rainbow() or color_white
	end
	return color_white
end
hook.Add( "TTTScoreboardColorForPlayer", "EasyScoreboard_NameColors", AddNameColors )

local function AddMenu( menu )
	local RCF = EZS.RightClickFunction
	if not RCF.enabled then return nil end
	
	local rank = EZS.Ranks[RealUserGroup( LocalPlayer() )]
	local ply = menu.Player
	
	for permission, funcs in pairs( RCF.functions ) do
		if permission == "Admin Functions" then
			if not rank then continue end
			if not rank.admin then continue end
		end
		
		menu:AddSpacer()
		local perm = menu:AddOption( permission )
			perm.OnMousePressed = function() end
			perm.OnMouseReleased = function() end
		menu:AddSpacer()
		
		for name, f in pairs( funcs ) do
			if name == "_icon" then perm:SetIcon( f ) continue end
			
			if istable( f ) then
				if f.func then
					local option = menu:AddOption( name )
					option.DoClick = function()
						if not IsValid( ply ) then return end
						if RCF.ask_admins then
							Derma_Query( "Execute '" .. name .. "' on player " .. ply:Nick() .. "?", "Admin Command",
							"Yes", function() f.func( ply ) end,
							"No", function() end ) 
						else
							f.func( ply )
						end
					end
					option:SetIcon( f.icon )
				else
					for n, d in pairs( f ) do
						local option = menu:AddOption( n )
						option.DoClick = function()
							if not IsValid( ply ) then return end
							if RCF.ask_admins then
								Derma_Query( "Execute '" .. n .. "' on player " .. ply:Nick() .. "?", "Admin Command",
								"Yes", function() d.func( ply ) end,
								"No", function() end ) 
							else
								f.func( ply )
							end
						end
						option:SetIcon( d.icon )
					end
					menu:AddSpacer()
				end
			else
				menu:AddOption( name ).DoClick = function() f( ply ) end
			end
		end
	end
	
	hook.Add( "Think", "EZS_CheckInput", function()
		if not input.IsKeyDown( KEY_TAB ) then
			hook.Remove( "Think", "EZS_CheckInput" )
			menu:Remove()
		end
	end )
end
hook.Add( "TTTScoreboardMenu", "EasyScoreboard_Menu", AddMenu )

concommand.Add( "ezs_refreshscoreboard", function() gamemode.Call( "ScoreboardCreate" ) end )