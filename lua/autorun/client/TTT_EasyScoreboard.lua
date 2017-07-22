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
EZS.Ranks["STEAM_0:1:45852799"] = { namecolor = "rainbow", icon = "bug", admin = false }

-- label enable on the top? what should it say?
EZS.CreateRankLabel = { enabled = true, text = "Rank" } 

-- what to show when the player doesnt have an entry
EZS.DefaultLabel = ""

-- create a button to sort the scoreboard by useres ranks
EZS.SortByRank = true

-- sadly there is no way to shift the background bar over as TTT draws it manually :c
EZS.HideBackground = false

-- Width of the rank columns
EZS.ColumnWidth = 125

-- the number of columns (not pixels!!!!!!!) to shift to the left
EZS.ShiftLeft = 0

-- shift tags, search marker, etc how much? (IN PIXELS)
EZS.ShiftOthers = 200

-- Show icon as well as rank text? (if possible)
EZS.ShowIconsWithRanks = true

-- Fix the icon next to the rank? (Horizontal align)
EZS.FixedIcon = true

-- Should the icon shift to the left to accomodate the label?
EZS.ShiftIconsWithLabels = false

-- if ^ is false, where should the icons go (like EZS.ShiftLeft)?
EZS.ShiftIconsLeft = 0

-- How far left should we shift the icon RELATIVE to the rank text?
EZS.ShiftRankIcon = 0

-- should we color the names?
EZS.UseNameColors = true

-- if there is no name color set, should we use the rank color?
EZS.DefaultNameColorToRankColor = false

-- should names get dynamic (changing) color?
EZS.AllowNamesToHaveDynamicColor = true

EZS.DynamicColors = {}

EZS.DynamicColors.rainbow = function( ply )
	local frequency, time = .5, RealTime()
	local red = math.sin( frequency * time ) * 127 + 128
	local green = math.sin( frequency * time + 2 ) * 127 + 128
	local blue = math.sin( frequency * time + 4 ) * 127 + 128
	return Color( red, green, blue )
end

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
				end, icon = "icon16/keyboard_delete.png" },
				["Un-Mute"] = { func = function( ply )
					RunConsoleCommand( "ulx", "unmute", ply:Nick():gsub( ";", "" ) )
				end, icon = "icon16/keyboard_add.png" },
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
				end, icon = "icon16/arrow_right.png" },
				["Bring"] = { func = function( ply )
					RunConsoleCommand( "ulx", "bring", ply:Nick():gsub( ";", "" ) )
				end, icon = "icon16/arrow_left.png" },
			},
			
			_icon = "icon16/shield.png",
		}
	}
}
hook.Run( "EZS_AddRightClickFunction", EZS.RightClickFunction.functions )
--[[ END CONFIG ]]--

for id, rank in pairs( EZS.Ranks ) do
	if rank.icon then
		rank.iconmat = Material( ("icon16/%s.png"):format( rank.icon ) )
	end
	rank.dynamic_col = isstring( rank.color )
	rank.dynamic_namecol = isstring( rank.namecolor )
end

local function RealUserGroup( ply )
	if ply.EV_GetRank then return ply:EV_GetRank() end
	return ply:GetUserGroup()
end

function EZS.GetRank( ply )
	return EZS.Ranks[ply:SteamID()] or EZS.Ranks[RealUserGroup( ply )]
end

function EZS.Dynamic( rank, ply )
	return (EZS.DynamicColors[rank.color] or EZS.DynamicColors.rainbow)( ply )
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
	
	local function AttachDynamicColor( label, ply )
		label.HasRainbow = true
		label.Think = function( s )
			if not IsValid( ply ) then return end
			local rank = EZS.GetRank( ply )
			if not rank then s:SetTextColor( color_white ) return end
			
			if not rank.dynamic_col then
				s:SetTextColor( rank.color )
			else
				s:SetTextColor( EZS.Dynamic( rank, ply ) )
			end
		end
		sb.nick.Think = function( s )
			if not IsValid( ply ) then return end
			local rank = EZS.GetRank( ply )
			if not rank then s:SetTextColor( color_white ) return end
			
			if not rank.dynamic_col then
				s:SetTextColor( rank.color )
			else
				if EZS.AllowNamesToHaveDynamicColor then
					s:SetTextColor( EZS.Dynamic( rank, ply ) )
				end
			end
		end
	end
	
	if EZS.HideBackground and KARMA.IsEnabled() then -- ttt pls
		EZS.AddSpacer()
	end

	sb:AddColumn( heading, function( ply, label )
		local rank = EZS.GetRank( ply )
		label:SetName( "EZS" )
		
		local ov_name = hook.Run( "EZS_GetPlayerRankName", ply )
		if ov_name and not rank then return ov_name end
		
		if not rank and not ov_name then return EZS.DefaultLabel end
		
		if rank.offset then
			local px, py = label:GetPos()
			label:SetPos( px - rank.offset, py )
		end
	
		if rank.icon and not rank.iconmat:IsError() and not EZS.FixedIcon then
			label.Paint = function( s, w, h )
				surface.DisableClipping( true )
					surface.SetDrawColor( color_white )
					surface.SetMaterial( rank.iconmat )
					
					local posx = -(rank.iconmat:Width()/2)
					
					if rank.name and EZS.ShowIconsWithRanks then
						if EZS.ShiftIconsWithLabels then
							posx = -(s:GetTextSize()) - EZS.ShiftRankIcon
						else
							posx = -EZS.ShiftIconsLeft * EZS.ColumnWidth - EZS.ShiftRankIcon
						end
					end
					
					surface.DrawTexturedRect( posx, -1, rank.iconmat:Width(), rank.iconmat:Height() )
				surface.DisableClipping( false )
			end
			
			if not rank.name then return " " end
		end
		
		if not rank.dynamic_col then
			label.Think = function( s )
				if not IsValid( ply ) then return end
				local rank = EZS.GetRank( ply )
				if not rank then return end
				
				if not rank.dynamic_col then
					s:SetTextColor( rank.color )
				else
					s:SetTextColor( EZS.Dynamic( rank, ply ) )
				end
			end
		elseif not label.AttachedDynamicColors then
			AttachDynamicColor( label, ply )
		end

		if ov_name then return ov_name end
		return rank.name or ""
	end, EZS.ColumnWidth )

	if EZS.SortByRank and ulx then --This relies on ULX/ULib functions
		sb:AddFakeColumn( EZS.CreateRankLabel.enabled and EZS.CreateRankLabel.text or "Rank", nil, nil, "rank", function(ply1, ply2)
			if ply1:CheckGroup(ply2:GetUserGroup()) then
				if ply1:IsUserGroup(ply2:GetUserGroup()) then
					return 0 --Sorts by username automatically if returned 0
				end
				return 1
			end
			if not ply2:CheckGroup(ply1:GetUserGroup()) then
				--If neither group inherits the other, sort the non-linear groups alphabetically
				if string.lower(EZS.GetRank(ply1)) > string.lower(EZS.GetRank(ply2)) then
					return 1
				end
			end
			return -1
		end)
	end
	
	if EZS.FixedIcon then
		sb:AddColumn("", function( ply, label )
			local rank = EZS.GetRank( ply )
			label:SetName("EZS-icon")
			if not rank then return "" end

			if rank.icon and not rank.iconmat:IsError() then
				label.Paint = function( s, w, h )
					surface.DisableClipping( true )
						surface.SetDrawColor( color_white )
						surface.SetMaterial( rank.iconmat )
						
						local posx = (rank.iconmat:Width()/2) + EZS.ColumnWidth / 4
						
						surface.DrawTexturedRect(posx, -1, rank.iconmat:Width(), rank.iconmat:Height() )
					surface.DisableClipping( false )
				end
			end

			return " "
		end, EZS.ColumnWidth )
	end
	
	EZS.HandleShift( sb )
	
	hook.Run( "EZS_AddColumns", sb )
end
hook.Add( "TTTScoreboardColumns", "EZS_Columns", EZS.AddRankLabel )

function EZS.AddNameColor( ply )
	if not EZS.UseNameColors then return end
	local rank = EZS.GetRank( ply )
	if not rank then return color_white end
	
	local color = rank.namecolor
	if not color and EZS.DefaultNameColorToRankColor then color = rank.color end
	if rank.dynamic_namecol then
		if EZS.AllowNamesToHaveDynamicColor then color = EZS.Dynamic( rank, ply ) end
		return IsColor(color) and color or color_white
	elseif color and IsColor(color) then
		return color
	end
end
hook.Add( "TTTScoreboardColorForPlayer", "EasyScoreboard_NameColors", EZS.AddNameColor )

function EZS.AddMenu( menu )
	local RCF = EZS.RightClickFunction
	if not RCF.enabled then return nil end
	
	local rank = EZS.GetRank( LocalPlayer() )
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
					if istable( f.allowed ) and not table.HasValue( f.allowed, LocalPlayer():GetUserGroup() ) then continue end
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
						if istable( d.allowed ) and not table.HasValue( d.allowed, LocalPlayer():GetUserGroup() ) then continue end
						
						local option = menu:AddOption( n )
						option.DoClick = function()
							if not IsValid( ply ) then return end
							if RCF.ask_admins then
								Derma_Query( "Execute '" .. n .. "' on player " .. ply:Nick() .. "?", "Admin Command",
								"Yes", function() d.func( ply ) end,
								"No", function() end ) 
							else
								d.func( ply )
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
hook.Add( "TTTScoreboardMenu", "EasyScoreboard_Menu", EZS.AddMenu )

concommand.Add( "ezs_refreshscoreboard", function() gamemode.Call( "ScoreboardCreate" ) end )
