local columns = {
	["Rank"] = {
		column_width = "dynamic", -- set to "dynamic" for dynamic sizing
		dynamic_width_padding = 10,

		color_ranks = true,

		draw_background = true,

		default_text = "",

		entries = {
			superadmin = {
				text = "S. Admin",
				rank_color = "rainbow",
				name_color = Color(0, 255, 0),
			},
			["STEAM_0_1:123:456"] = {
				text = "rejax",
				rank_color = "rainbow",
			}
		},

		spacer = 50,
	},

	["Donator Status"] = {
		column_width = "dynamic", -- set to "dynamic" for dynamic sizing
		dynamic_width_padding = 20,

		draw_background = true,
		hide_name = true,

		default_text = "",

		entries = {
			superadmin = {
				icon = "heart",
				rank_color = Color(255, 0, 0),
			},
		},
	},
}

local order = {
	"Rank",
	"Donator Status",
	"Donator Status2",
}

local config_names = {
	color_names = true,

	entries = {
		superadmin = "rainbow",
		["STEAM_0_1:123:456"] = "rainbow",
	}
}

local dynamic_colors = {
	rainbow = function()
		local frequency, time = .5, RealTime()
		local red = math.sin(frequency * time) * 127 + 128
		local green = math.sin(frequency * time + 2) * 127 + 128
		local blue = math.sin(frequency * time + 4) * 127 + 128

		return Color(red, green, blue)
	end,
}

local shiftables = {
	tag = 0, 
	sresult = 0,
	avatar = 0,
	nick = 0,
}

------------------------------------------
--[[ |		 END USER CONFIG 		| ]]--
--[[ V  dont touch anything below   V ]]--
------------------------------------------

local function waitFrame(func) timer.Simple(0, func) end

local default_column = {
	column_width = "dynamic", -- set to "dynamic" for dynamic sizing
	dynamic_width_padding = 0,
	color_ranks = true,
	draw_background = true,
	default_text = "",
	entries = {},
	spacer = false,
}
default_column.__index = default_column

local frame_width = 0
local column_widths = {}
local internal_ignored_configs = {NameColors = true}
local config = columns -- eh

for id, conf in pairs(config) do
	if internal_ignored_configs[id] then continue end

	setmetatable(conf, default_column)

	for name, tb in pairs(conf.entries) do
		if tb.parent and conf.entries[tb.parent] then
			local parent = conf.ranks[tb.parent]
			setmetatable(tb, parent)
			parent.__index = parent
		end
		if tb.icon then
			local mat = Material("icon16/" .. tb.icon .. ".png")
			tb._icon = mat
		end
	end
end

timer.Simple(0, function()
	hook.Run("ezs_exp_colors", dynamic_colors)
	hook.Run("ezs_exp_columns", columns)
	hook.Run("ezs_exp_order", order)
	hook.Run("ezs_exp_names", config_names)
end) -- wait for other scripts to load

local function getRank(ply)
	return ply:GetUserGroup()
end

local function getColumn(ply, col_index)
	return config[col_index].entries[ply:SteamID()] or config[col_index].entries[getRank(ply)]
end

local function getColumnText(ply, col_index)
	local col = getColumn(ply, col_index)
	local alt = hook.Run("ezs_GetTextForPlayer", ply, col_index)
	return alt or (col and col.text or config[col_index].default_text)
end

local function getColumnWidth(col_index)
	surface.SetFont("treb_small")
	local conf = config[col_index]
	local max = conf.hide_name and 0 or surface.GetTextSize(col_index)
	for _, col in pairs(conf.entries) do
		if col.text then
			local text_width = surface.GetTextSize(col.text)
			max = math.max(max, text_width)
		elseif col._icon then
			local icon_width = col._icon:Width()
			max = math.max(max, icon_width)
		end
	end
	return math.max(max + conf.dynamic_width_padding, (45 + conf.dynamic_width_padding or 0)) -- anything less fucks with the system apparently <:(
end

local function getColor(index)
	if IsColor(index) then 
		return index
	elseif type(index) == "string" and dynamic_colors[index] then
		return dynamic_colors[index]()
	else 
		return color_white 
	end
end

local function getColumnTextColor(ply, col_index)
	if not config[col_index].color_ranks then return end
	local col = getColumn(ply, col_index)

	local alt = hook.Run("ezs_GetColumnColorForPlayer", ply, col_index)
	return alt or (col and getColor(col.rank_color)) or color_white
end

local function getNameColor(ply)
	if not config_names.color_names then return end
	local entry = config_names.entries[ply:SteamID()] or config_names.entries[getRank(ply)]
	local alt = hook.Run("ezs_GetNameColorForPlayer", ply, col_index)
	return alt or getColor(entry)
end

local function installColors(label, ply, col_index)
	label.ezs_installed_colors = true

	local oldThink = label.Think
	function label:Think()
		oldThink(self)
		local col = getColumnTextColor(ply, col_index)
		if col then
			self:SetTextColor(col)
		end
	end 
end

local function xPosForColumn(col)
	local x = frame_width
	for i = 1, col.ezs_w_index do
		x = x - column_widths[i]
	end
	return x
end

local function installIcon(pnl, ply, col_index)
	pnl.ezs_installed_icon = true

	local col = getColumn(ply, col_index)
	if not col then return end
	local icon = col._icon
	if not icon then return end
	
	local col_w = getColumnWidth(col_index)
	local ico_w = icon:Width()

	local parent = pnl:GetParent()
	local image = vgui.Create("DImage", parent)
		image:SetMaterial(icon)
		image:SetSize(ico_w, icon:Height())

		local x = xPosForColumn(pnl)
		local margin = ico_w * .25
		image:SetPos(x - ico_w / 2, margin)
end

local function updateLabel(label, ply, col_index)
	if not label.ezs_installed_colors then
		installColors(label, ply, col_index)
	end

	if not label.ezs_installed_icon then
		installIcon(label, ply, col_index)
	end
end

local function updateColumn(ply, label)
	local col_index = label.ezs_col_index
	if not col_index then ErrorNoHalt("no index set on label!") return "" end

	updateLabel(label, ply, col_index)
	return getColumnText(ply, col_index)
end

local function drawBackground(col_index, x, y, w, h)

end

local function drawBackgrounds(group, sb)
	local scr = sb.ply_frame.scroll.Enabled and 16 or 0
	local cx = group:GetWide() - scr

	surface.SetDrawColor(0,0,0, 80)

	for k, v in ipairs(sb.cols) do
		cx = cx - v.Width
		if v.ezs and v.ezs_col_index == "pass" then continue end
		if v.ezs and not config[v.ezs_col_index].draw_background then
			drawBackground(v.ezs_col_index, cx-v.Width/2, 0, v.Width, group:GetTall())
		elseif k % 2 == 1 or (v.ezs and config[v.ezs_col_index].draw_background) then -- Draw for odd numbered columns
			surface.DrawRect(cx-v.Width/2, 0, v.Width, group:GetTall())
		end
	end
end

-- sb_team.lua
local function hijackGroup(group, sb)
	local oldPaint = group.Paint
	function group:Paint()
		local oldcols = sb.cols
		sb.cols = {}
		oldPaint(self)
		sb.cols = oldcols
		drawBackgrounds(self, sb)
	end
end

-- sb_main.lua
local function hijackScoreboard(sb)
	for _, group in pairs(sb.ply_groups) do
		hijackGroup(group, sb)
	end
end

-- sb_row.lua
local function hijackRow(row)
	local oldLayoutColumns = row.LayoutColumns

	function row:LayoutColumns()
		oldLayoutColumns(self)

		for id, shift_amt in pairs(shiftables) do
			if not self[id] then continue end
			local x, y = self[id]:GetPos()
			if type(shift_amt) == "string" then
				self[id]:SetPos(tonumber(shift_amt), y)
			else
				self[id]:SetPos(x - shift_amt, y)
			end
		end
	end
end

local function attachHijacks(panel)
	if panel.ply_groups then
		hijackScoreboard(panel)
	else
		hijackRow(panel)
	end
end

-- dummy function
local function pass() return "" end

local function onScoreboardOpen(panel)
	column_widths = {}

	if panel.ply_frame then -- sb_main
		panel.ply_frame:InvalidateParent(true) -- your mother smelt of elderberries
		frame_width = panel.ply_frame:GetWide() + 1
	end

	for _, pnl in pairs(panel.cols) do
		table.insert(column_widths, pnl.Width)
		panel.ezs_w_index = #column_widths
	end


	local k = 0
	for i, name in pairs(order) do
		if not config[name] or internal_ignored_configs[name] then continue end

		local conf = config[name]

		k = k + 1
		local _name = conf.hide_name and "" or name
		local width = conf.column_width == "dynamic" and getColumnWidth(name) or conf.column_width

		local column = panel:AddColumn(_name, updateColumn, width)
			column.ezs = true
			column.ezs_col_index = name

		table.insert(column_widths, width)
		column.ezs_w_index = #column_widths

		if conf.spacer then
			local fake = panel:AddColumn("", pass, conf.spacer)
				fake.ezs = true
				fake.ezs_col_index = "pass"

			table.insert(column_widths, conf.spacer)
			fake.ezs_w_index = #column_widths
		end

		attachHijacks(panel)
	end
end
hook.Add("TTTScoreboardColumns", "ezs columns", onScoreboardOpen)

local function onRequestNameColor(ply)
	local col = getNameColor(ply)
	if IsColor(col) then return col end
end
hook.Add("TTTScoreboardColorForPlayer", "ezs colors", onRequestNameColor)

concommand.Add( "ezs_refreshscoreboard", function() gamemode.Call( "ScoreboardCreate" ) end )