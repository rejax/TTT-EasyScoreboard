local EZS = {}
EZS.Ranks = {}

--[[ CONFIG ]]--
EZS.Enabled = true

EZS.Ranks["superadmin"] = { name = "S. Admin", color = "rainbow", admin = true } -- the display name for a rank, color, is the rank admin?
EZS.Ranks["admin"] = { name = "Admin", color = Color( 150, 100, 100 ), admin = true }

EZS.CreateRankLabel = { enabled = true, text = "Rank" } -- label enable on the top? what should it say?

EZS.UseNameColors = true -- should we color the names?
EZS.RainbowFrequency = .5 -- frequency of rainbow (if enabled) (higher is faster)

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
	
	local function RainbowFunction( label )
		label.HasRainbow = true
		label.Think = function( s )
			s:SetTextColor( rainbow() )
		end
	end
	
	sb:AddColumn( heading, function( ply, label )
		local rank = EZS.Ranks[ply:GetUserGroup()]
		if not rank then return "" end
		
		if rank.color ~= "rainbow" then
			label:SetTextColor( rank.color )	
		elseif not label.HasRainbow then
			RainbowFunction( label )
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
	
	local userGroup = ply:GetNWString( "usergroup" )
	local col = EZS.Colors[userGroup]
	if not col then col = EZS.Colors[ply:SteamID()] end

		if col then
			if col == "rainbow" then return color_white end
			return col
		else return color_white end
	end
end
hook.Add( "TTTScoreboardColorForPlayer", "EasyScoreboard_NameColors", AddNameColors )

local function AddMenu( menu )
	local RCF = EZS.RightClickFunction
	if not RCF.enabled then return nil end
	
	local rank = EZS.Ranks[LocalPlayer():GetUserGroup()]
	
	for permission, funcs in pairs( RCF.functions ) do
		if permission == "Admin Functions" and not rank.admin then continue end
		
		menu:AddSpacer()
		local perm = menu:AddOption( permission )
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