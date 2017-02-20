local K, C, L = unpack(select(2, ...))

-- Lua Wow
local _G = _G

-- Wow API
local DropDownList1 = _G.DropDownList1
local FCF_StartAlertFlash = _G.FCF_StartAlertFlash
local GetContainerNumSlots = _G.GetContainerNumSlots
local HideUIPanel = _G.HideUIPanel
local InCombatLockdown = _G.InCombatLockdown
local IsAddOnLoaded = _G.IsAddOnLoaded
local IsBagOpen = _G.IsBagOpen
local IsOptionFrameOpen = _G.IsOptionFrameOpen
local oldUpdate = _G.WorldMapLevelDropDown_Update
local ShowUIPanel = _G.ShowUIPanel
local UnitIsUnit = _G.UnitIsUnit
local WorldMapFrame = _G.WorldMapFrame
local WorldMapFrame_OnHide = _G.WorldMapFrame_OnHide
local WorldMapLevelButton_OnClick = _G.WorldMapLevelButton_OnClick

-- Global variables that we don't cache, list them here for mikk's FindGlobals script
-- GLOBALS: LFRBrowseFrame, ScriptErrorsFrame, C_ArtifactUI, ArtifactFrame, addon, ToggleFrame
-- GLOBALS: SpellBookFrame, build, PetJournal_LoadUI, UIParent, WorldMapFrame, event
-- GLOBALS: WorldMapLevelButton, BankFrame, CloseAllBags, NUM_BAG_FRAMES, OpenBag
-- GLOBALS: NUM_CONTAINER_FRAMES, CloseBag

-- Fix spellbook taint in combat
local SpellBookTaint = CreateFrame("Frame")
SpellBookTaint:RegisterEvent("ADDON_LOADED")
SpellBookTaint:SetScript("OnEvent", function(self, event, addon)
	if addon ~= "KkthnxUI" then
		return
	end

	ToggleFrame(SpellBookFrame)

	self:UnregisterEvent("ADDON_LOADED")
end)

-- Fix RemoveTalent() taint
FCF_StartAlertFlash = K.Noop

-- Fix SearchLFGLeave() taint
local LFRBrowseTaint = CreateFrame("Frame")
LFRBrowseTaint:SetScript("OnUpdate", function(self, elapsed)
	if LFRBrowseFrame.timeToClear then
		LFRBrowseFrame.timeToClear = nil
	end
end)

-- Misclicks for some popups
StaticPopupDialogs.RESURRECT.hideOnEscape = nil
StaticPopupDialogs.AREA_SPIRIT_HEAL.hideOnEscape = nil
StaticPopupDialogs.PARTY_INVITE.hideOnEscape = nil
StaticPopupDialogs.CONFIRM_SUMMON.hideOnEscape = nil
StaticPopupDialogs.ADDON_ACTION_FORBIDDEN.button1 = nil
StaticPopupDialogs.TOO_MANY_LUA_ERRORS.button1 = nil
PetBattleQueueReadyFrame.hideOnEscape = nil
if PVPReadyDialog then
	PVPReadyDialog.leaveButton:Hide()
	PVPReadyDialog.enterButton:ClearAllPoints()
	PVPReadyDialog.enterButton:SetPoint("BOTTOM", PVPReadyDialog, "BOTTOM", 0, 25)
	PVPReadyDialog.label:SetPoint("TOP", 0, -22)
end

ReadyCheckFrame:HookScript("OnShow", function(self)
	-- bug fix, don't show it if player is initiator
	if self.initiator and UnitIsUnit("player", self.initiator) then
		self:Hide()
	end
end)

-- The first problem is that WorldMapScrollFrame_ResetZoom doesn't work properly in combat.
-- The second problem is that changing it taints the WorldMap and probably the POI system and Objectives Tracker too.
-- The "solution" is to remove events and script handlers that call it while engaged in combat.

-- WoW frames & functions
local MapResetZoomFix = CreateFrame("Frame", nil, UIParent)
MapResetZoomFix:RegisterEvent("PLAYER_REGEN_ENABLED")
MapResetZoomFix:RegisterEvent("PLAYER_REGEN_DISABLED")
MapResetZoomFix:SetScript("OnEvent", function(self)
	if event == "PLAYER_REGEN_DISABLED" then
		WorldMapFrame:UnregisterEvent("WORLD_MAP_UPDATE")
		WorldMapFrame:SetScript("OnHide", nil)
		WorldMapLevelButton:SetScript("OnClick", nil)
	elseif event == "PLAYER_REGEN_ENABLED" then
		WorldMapFrame:RegisterEvent("WORLD_MAP_UPDATE")
		WorldMapFrame:SetScript("OnHide", WorldMapFrame_OnHide)
		WorldMapLevelButton:SetScript("OnClick", WorldMapLevelButton_OnClick)
	end
end)

-- In 7.1 if you open the world map and open any dropdown in the UI
-- (from the world map frame or any other frame) the dropdown will suddenly close itself.

-- This little fix was supplied by Ellypse@WowInterface.
-- http://www.wowinterface.com/forums/showthread.php?t=54979
local newUpdate = function()
	if not DropDownList1:IsVisible() then
		oldUpdate()
	end
end

_G.WorldMapLevelDropDown_Update = newUpdate

-- blizzard's baghandling just doesn't cut it
-- we wish for all backpack/bag hotkeys and buttons to toggle all bags, always
local function OpenAllBags()
	if not UIParent:IsShown() or IsOptionFrameOpen() then
		return
	end
	if not BankFrame:IsShown() then
		if IsBagOpen(0) then
			CloseAllBags()
		else
			for i = 0, NUM_BAG_FRAMES, 1 do
				OpenBag(i)
			end
		end
	else
		local bagsOpen = 0
		local totalBags = 0

		-- check for open bank bags
		for i = NUM_BAG_FRAMES + 1, NUM_CONTAINER_FRAMES, 1 do
			if GetContainerNumSlots(i) > 0 then
				totalBags = totalBags + 1
			end
			if IsBagOpen(i) then
				CloseBag(i)
				bagsOpen = bagsOpen + 1
			end
		end
		if bagsOpen < totalBags or totalBags == 0 then
			for i = 0, NUM_CONTAINER_FRAMES, 1 do
				OpenBag(i)
			end
		else
			CloseAllBags()
		end
	end
end

-- replace blizzard's bag opening functions
local otherBagsLoaded
for _, bags in ipairs({"ArkInventory", "Bagnon", "OneBag3", "BagForce", "Tbag", "Tbag-Shefki"}) do
	if K.CheckAddOn(bags) then
		otherBagsLoaded = true
		break
	end
end
if not otherBagsLoaded then
	_G.OpenBackpack = OpenAllBags
	_G.OpenAllBags = OpenAllBags
	_G.ToggleBackpack = OpenAllBags
	_G.ToggleBag = OpenAllBags
else
	OpenAllBags = nil
end