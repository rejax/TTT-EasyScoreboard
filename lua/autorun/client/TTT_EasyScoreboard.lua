local EZS = {}
EZS.Colors = {}
EZS.Ranks = {}

--[[ CONFIG ]]--
EZS.Enabled = true

EZS.Colors["superadmin"] = Color( 255, 222, 0 ) -- the color for a rank
EZS.Colors["admin"] = Color( 200, 0, 0 )

EZS.Ranks["superadmin"] = "S. Admin" -- the display name for a rank
EZS.Ranks["admin"] = "Admin"

EZS.RankPos = 5 -- Where on the scoreboard should we be? ( 5 is right on the left of karma )
EZS.RankOffset = 0 -- the offset of the rank (negative is left)
EZS.CreateRankLabel = { enabled = true, text = "Rank" } -- label enable on the top? what should it say?

EZS.UseNameColors = true -- should we color the names?

EZS.DrawBackground = false -- draw black bar behind?
EZS.BackgroundSize = 50 -- other columns are 50

--[[ END CONFIG ]]--

local function MakeLabel( sb, text )
	for i = 1, EZS.RankPos do
		if ValidPanel(sb.cols[i]) then continue end
		sb.cols[i] = vgui.Create( "DLabel", sb )
		sb.cols[i]:SetText("")
	end
	sb.cols[EZS.RankPos] = vgui.Create( "DLabel", sb )
	sb.cols[EZS.RankPos]:SetText( text )
	
	if EZS.RankOffset == 0 then return end
	local oldPL = sb.PerformLayout
	sb.PerformLayout = function( s )
		oldPL(s)
		for p, panel in ipairs( s.cols ) do
			if p == EZS.RankPos then
				local x,y = panel:GetPos()
				panel:SetPos( x + EZS.RankOffset, y )
			end
		end
	end
end

local function MakeRankText( sb, ply )
	local userGroup = ply:GetNWString( "usergroup" )
	local rankName = EZS.Ranks[userGroup]
	local rankColor = EZS.Colors[userGroup] or color_white
	local rankPos = EZS.RankPos
	
	for i = 1, rankPos-1 do
		if ValidPanel(sb.cols[i]) then continue end
		sb.cols[i] = vgui.Create( "DLabel", sb )
		sb.cols[i]:SetText("")
	end
	sb.cols[rankPos] = vgui.Create( "DLabel", sb )
	sb.cols[rankPos]:SetText( rankName )
	sb.cols[rankPos]:SetTextColor( rankColor )
	sb.cols[rankPos]:SetName( "ezsfor_"..ply:EntIndex() )

	local applySSettings = sb.ApplySchemeSettings
	sb.ApplySchemeSettings = function( self )
		applySSettings(self)
		self.cols[rankPos]:SetText( rankName )
		self.cols[rankPos]:SetTextColor( rankColor ) -- overwrite the given color
		self.cols[rankPos]:SetFont("treb_small")
	end
	
	if EZS.RankOffset == 0 then return end
	local LayoutCols = sb.LayoutColumns
	sb.LayoutColumns = function(s)
		LayoutCols(s)
		for p, panel in pairs( s.cols ) do
			if p == EZS.RankPos then
				local x,y = panel:GetPos()
				panel:SetPos( x + EZS.RankOffset, y )
			end
		end
	end
end

local function DoRankLabel( sb )
	for _, ply_group in ipairs( sb.ply_groups ) do
		for ply, row in pairs( ply_group.rows ) do
			if EZS.Ranks[ply:GetNWString("usergroup")] then
				MakeRankText( row, ply )
			end
		end
	end
end

local multis = { [5] = 275, [6] = 325, [7] = 375, [8] = 425, [9] = 475, [10] = 525, [11] = 575, [12] = 625, [13] = 675, [14] = 725,
	[15] = 775, [16] = 825, [17] = 875, [18] = 925, [19] = 975, [20] = 1025 } -- because its like 3am and i dont even know how im still typing
local function MakeBackground( sb )
	for _, sb_team in ipairs( sb.ply_groups ) do
		local oldPaint = sb_team.Paint
		sb_team.Paint = function( s, w, h )
			oldPaint(s)
			local scr = sb.ply_frame.scroll.Enabled and 16 or 0
			local sizeoff = EZS.BackgroundSize - 50
			local offset = ( ( s:GetWide() - scr ) - multis[EZS.RankPos] - sizeoff )
			surface.SetDrawColor( 0, 0, 0, 80 )
			surface.DrawRect( offset, 0, EZS.BackgroundSize + sizeoff, s:GetTall() )
		end
	end
end

local function EZS_Do()
	if not EZS.Enabled then return end
	
	GAMEMODE:ScoreboardCreate()
	
	local sb_main = GAMEMODE:GetScoreboardPanel()
	
	if EZS.CreateRankLabel.enabled then MakeLabel( sb_main, EZS.CreateRankLabel.text ) end
	DoRankLabel( sb_main )
	if EZS.DrawBackground then MakeBackground( sb_main ) end
end
hook.Add( "ScoreboardShow", "EasyScoreboard_Show", EZS_Do )

local function AddNameColors( ply )
	local userGroup = ply:GetNWString( "usergroup" )
	if EZS.Colors[userGroup] and EZS.UseNameColors then
		return EZS.Colors[userGroup]
	else return color_white end
end
hook.Add( "TTTScoreboardColorForPlayer", "EasyScoreboard_NameColors", AddNameColors )