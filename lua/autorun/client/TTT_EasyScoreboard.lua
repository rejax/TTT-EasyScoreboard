local EZS = {}
EZS.Ranks = {}

--[[ CONFIG ]]--
EZS.Enabled = true

EZS.Ranks["superadmin"] = { name = "S. Admin", color = Color( 255, 0, 0 ), admin = true } -- the display name for a rank, color, is the rank admin?
EZS.Ranks["admin"] = { name = "Admin", color = Color( 150, 100, 100 ), admin = true }
EZS.Ranks["donator"] = { name = "Donator", color = Color( 100, 200, 100 ), admin = false }

EZS.CreateRankLabel = { enabled = true, text = "Rank" } -- label enable on the top? what should it say?

EZS.HideBackground = false
EZS.ShiftLeft = 0

EZS.UseNameColors = true -- should we color the names?
EZS.RainbowFrequency = .5 -- frequency of rainbow (if enabled)

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
			["Kick"] = { func = function( ply )
				RunConsoleCommand( "ulx", "kick", ply:Nick():gsub( ";", "" ) )
			end, icon = "icon16/user_delete.png" },
			["Slay"] = { func = function( ply )
				RunConsoleCommand( "ulx", "slay", ply:Nick():gsub( ";", "" ) )
			end, icon = "icon16/pill.png" },
			_icon = "icon16/shield.png",
		}
	}
}
--[[ END CONFIG ]]--

local function rainbow()
	local frequency, time = EZS.RainbowFrequency, RealTime()
	local red = math.sin( frequency * time ) * 127 + 128
	local green = math.sin( frequency * time + 2 ) * 127 + 128
	local blue = math.sin( frequency * time + 4 ) * 127 + 128
	return Color( red, green, blue )
end

local function AddRankLabel( sb )
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
				s:SetTextColor( rainbow() )
			end
		end
	end
	
	if EZS.HideBackground and KARMA.IsEnabled() then
		sb:AddColumn( "", function() return "" end, 0 )
	end
	
	sb:AddColumn( heading, function( ply, label )
		local key = ply:SteamID()
		if not EZS.Ranks[key] then key = ply:GetUserGroup() end
		local rank = EZS.Ranks[key]
		if not rank then return "" end
		
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
		
		if rank.offset then
			local px, py = label:GetPos()
			label:SetPos( px - rank.offset, py )
		end
		
		label:SetName( "EZS" )
		return rank.name
	end )
	
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
		end
	end
end
hook.Add( "TTTScoreboardColumns", "EasyScoreboard_Columns", AddRankLabel )

local function AddNameColors( ply )
	if EZS.UseNameColors then
	local col = EZS.Ranks[ply:SteamID()]
	if not col then col = EZS.Ranks[ply:GetUserGroup()] end
	
		if col and col.color then
			if col.color == "rainbow" then return rainbow() end
			return col.color
		else return color_white end
	end
end
hook.Add( "TTTScoreboardColorForPlayer", "EasyScoreboard_NameColors", AddNameColors )

local function AddMenu( menu )
	local RCF = EZS.RightClickFunction
	if not RCF.enabled then return nil end
	
	local rank = EZS.Ranks[LocalPlayer():GetUserGroup()]
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
			
			local option = menu:AddOption( name )
			if istable( f ) then
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
				option.DoClick = function() f( ply ) end
			end
		end
	end
end
hook.Add( "TTTScoreboardMenu", "EasyScoreboard_Menu", AddMenu )

concommand.Add( "ezs_refreshscoreboard", function() GAMEMODE:ScoreboardCreate() end )