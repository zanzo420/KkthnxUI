local K, C = unpack(select(2, ...))
local Module = K:NewModule("ActionBar")
local FilterConfig = K.ActionBars.actionBar1

local _G = _G
local next = _G.next
local table_insert = _G.table.insert

local CreateFrame = _G.CreateFrame
local NUM_ACTIONBAR_BUTTONS = _G.NUM_ACTIONBAR_BUTTONS
local RegisterStateDriver = _G.RegisterStateDriver
local UIParent = _G.UIParent

function Module:OnEnable()
	if not C["ActionBar"].Enable then
		return
	end

	local padding, margin = 0, 6
	local num = NUM_ACTIONBAR_BUTTONS
	local buttonList = {}
	local layout = C["ActionBar"].Layout.Value

	-- Create The Frame To Hold The Buttons
	local frame = CreateFrame("Frame", "KkthnxUI_ActionBar1", UIParent, "SecureHandlerStateTemplate")

	if layout == "3x4 Boxed arrangement" then
		frame:SetWidth(3 * FilterConfig.size + (3 - 1) * margin + 2 * padding)
		frame:SetHeight(4 * FilterConfig.size + (4 - 1) * margin + 2 * padding)
		frame.Pos = {"BOTTOM", UIParent, "BOTTOM", -305, 124}
	else
		frame:SetWidth(num * FilterConfig.size + (num - 1) * margin + 2 * padding)
		frame:SetHeight(FilterConfig.size + 2 * padding)
		frame.Pos = {"BOTTOM", UIParent, "BOTTOM", 0, 4}
	end

	if layout == "3x4 Boxed arrangement" then
		for i = 1, num do
			local button = _G["ActionButton"..i]
			table_insert(buttonList, button) -- Add The Button Object To The List
			button:SetParent(frame)
			button:SetSize(FilterConfig.size, FilterConfig.size)
			button:ClearAllPoints()

			if i == 1 then
				button:SetPoint("TOPLEFT", frame, padding, padding)
			elseif (i-1)%3 == 0 then
				local previous = _G["ActionButton"..i - 3]
				button:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, margin*(-1))
			else
				local previous = _G["ActionButton"..i - 1]
				button:SetPoint("LEFT", previous, "RIGHT", margin, 0)
			end
		end
	else
		for i = 1, num do
			local button = _G["ActionButton"..i]
			table_insert(buttonList, button) -- Add The Button Object To The List
			button:SetParent(frame)
			button:SetSize(FilterConfig.size, FilterConfig.size)
			button:ClearAllPoints()

			if i == 1 then
				button:SetPoint("BOTTOMLEFT", frame, padding, padding)
			else
				local previous = _G["ActionButton"..i - 1]
				button:SetPoint("LEFT", previous, "RIGHT", margin, 0)
			end
		end
	end

	-- Show/hide The Frame On A Given State Driver
	frame.frameVisibility = "[petbattle] hide; show"
	RegisterStateDriver(frame, "visibility", frame.frameVisibility)

	-- Create Drag Frame And Drag Functionality
	if K.ActionBars.userPlaced then
		K.Mover(frame, "Main Actionbar", "Bar1", frame.Pos)
	end

	if FilterConfig.fader then
		Module.CreateButtonFrameFader(frame, buttonList, FilterConfig.fader)
	end

	-- _onstate-page state driver
	local actionPage = "[bar:6]6;[bar:5]5;[bar:4]4;[bar:3]3;[bar:2]2;[overridebar]14;[shapeshift]13;[vehicleui]12;[possessbar]12;[bonusbar:5]11;[bonusbar:4]10;[bonusbar:3]9;[bonusbar:2]8;[bonusbar:1]7;1"
	local buttonName = "ActionButton"
	for i, button in next, buttonList do
		frame:SetFrameRef(buttonName..i, button)
	end

	frame:Execute(([[
	buttons = table.new()
	for i = 1, %d do
		table.insert(buttons, self:GetFrameRef("%s"..i))
	end
	]]):format(num, buttonName))

	frame:SetAttribute("_onstate-page", [[
	for _, button in next, buttons do
		button:SetAttribute("actionpage", newstate)
	end
	]])
	RegisterStateDriver(frame, "page", actionPage)

	-- Add Elements
	self:CreateBar2()
	self:CreateBar3()
	self:CreateBar4()
	self:CreateBar5()
	self:CreateExtrabar()
	self:CreateLeaveVehicle()
	self:CreatePetbar()
	self:CreateStancebar()
	self:HideBlizz()
	self:CreateBarSkin()
	self:HookActionEvents()
	self:CreateMicroMenu()

	-- Vehicle Fix
	local function getActionTexture(button)
		return GetActionTexture(button.action)
	end

	K:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR", function()
		for _, button in next, buttonList do
			local icon = button.icon
			local texture = getActionTexture(button)
			if texture then
				icon:SetTexture(texture)
				icon:Show()
			else
				icon:Hide()
			end
		end
	end)
end