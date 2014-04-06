local EZS = {}
EZS.Ranks = {}

--[[ CONFIG ]]--
EZS.Enabled = true

EZS.Ranks["superadmin"] = { name = "S. Admin", color = Color( 255, 0, 0 ), admin = true } -- the display name for a rank, color, is the rank admin?
EZS.Ranks["admin"] = { name = "Admin", color = Color( 150, 100, 100 ), admin = true }
EZS.Ranks["donator"] = { name = "Donator", color = Color( 100, 200, 100 ), admin = false }

EZS.CreateRankLabel = { enabled = true, text = "Rank" } -- label enable on the top? what should it say?

EZS.UseNameColors = true -- should we color the names?
EZS.RainbowFrequency = .5 -- frequency of rainbow (if enabled)

EZS.RightClickFunction = { enabled = true, functions = {
		["User Functions"] = {
			["Show Profile"] = function( ply )
				ply:ShowProfile()
			end,
			
			_icon = "icon16/group.png",
		},
		["Admin Functions"]	= {
			["Kick"] = { func = function( ply )
				RunConsoleCommand( "ulx", "kick", ply:Nick():gsub( ";", "" ) ) -- change this to whatever
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
	
	sb:AddColumn( heading, function( ply, label )
		local key = ply:GetUserGroup()
		if not EZS.Ranks[key] then key = ply:SteamID() end
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
			
		return rank.name
	end )
	
end
hook.Add( "TTTScoreboardColumns", "EasyScoreboard_Columns", AddRankLabel )

local function AddNameColors( ply )
	if EZS.UseNameColors then
	local col = EZS.Ranks[ply:GetUserGroup()]
	if not col then col = EZS.Ranks[ply:SteamID()] end
	
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
			
			local o = menu:AddOption( name )
			if istable( f ) then
				o.DoClick = function() f.func( menu.Player ) end
				o:SetIcon( f.icon )
			else
				o.DoClick = function() f( menu.Player ) end
			end
		end
	end
end
hook.Add( "TTTScoreboardMenu", "EasyScoreboard_Menu", AddMenu )