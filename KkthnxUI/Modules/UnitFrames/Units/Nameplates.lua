local K, C = unpack(select(2, ...))
local UF = K:GetModule("Unitframes")

local _G = _G
local math_floor = _G.math.floor
local math_rad = _G.math.rad
local pairs = _G.pairs
local string_format = _G.string.format
local string_match = _G.string.match
local table_wipe = _G.table.wipe
local tonumber = _G.tonumber
local unpack = _G.unpack

local Ambiguate = _G.Ambiguate
local C_MythicPlus_GetCurrentAffixes = _G.C_MythicPlus.GetCurrentAffixes
local C_NamePlate_GetNamePlateForUnit = _G.C_NamePlate.GetNamePlateForUnit
local C_Scenario_GetCriteriaInfo = _G.C_Scenario.GetCriteriaInfo
local C_Scenario_GetInfo = _G.C_Scenario.GetInfo
local C_Scenario_GetStepInfo = _G.C_Scenario.GetStepInfo
local CreateFrame = _G.CreateFrame
local GetArenaOpponentSpec = _G.GetArenaOpponentSpec
local GetBattlefieldScore = _G.GetBattlefieldScore
local GetInstanceInfo = _G.GetInstanceInfo
local GetNumBattlefieldScores = _G.GetNumBattlefieldScores
local GetNumGroupMembers = _G.GetNumGroupMembers
local GetNumSubgroupMembers = _G.GetNumSubgroupMembers
local GetPlayerInfoByGUID = _G.GetPlayerInfoByGUID
local GetSpecializationInfoByID = _G.GetSpecializationInfoByID
local INTERRUPTED = _G.INTERRUPTED
local InCombatLockdown = _G.InCombatLockdown
local IsInGroup = _G.IsInGroup
local IsInInstance = _G.IsInInstance
local IsInRaid = _G.IsInRaid
local SetCVar = _G.SetCVar
local UnitClass = _G.UnitClass
local UnitClassification = _G.UnitClassification
local UnitExists = _G.UnitExists
local UnitFactionGroup = _G.UnitFactionGroup
local UnitGUID = _G.UnitGUID
local UnitGroupRolesAssigned = _G.UnitGroupRolesAssigned
local UnitIsConnected = _G.UnitIsConnected
local UnitIsPlayer = _G.UnitIsPlayer
local UnitIsTapDenied = _G.UnitIsTapDenied
local UnitIsUnit = _G.UnitIsUnit
local UnitName = _G.UnitName
local UnitPlayerControlled = _G.UnitPlayerControlled
local UnitReaction = _G.UnitReaction
local UnitSelectionColor = _G.UnitSelectionColor
local UnitThreatSituation = _G.UnitThreatSituation
local hooksecurefunc = _G.hooksecurefunc

local NameplateTexture = K.GetTexture(C["UITextures"].NameplateTextures)
-- local NameplateFont = K.GetFont(C["UIFonts"].NameplateFonts)
local HealPredictionTexture = K.GetTexture(C["UITextures"].HealPredictionTextures)

local healList, exClass, healerSpecs = {}, {}, {}
local testing = false

exClass.DEATHKNIGHT = true
exClass.MAGE = true
exClass.ROGUE = true
exClass.WARLOCK = true
exClass.WARRIOR = true

if C["Nameplate"].HealerIcon == true then
	local HealerEventFrame = CreateFrame("Frame")
	HealerEventFrame.factions = {
		["Horde"] = 1,
		["Alliance"] = 0,
	}

	local healerSpecIDs = {
		105, -- Druid Restoration
		270, -- Monk Mistweaver
		65,	-- Paladin Holy
		256, -- Priest Discipline
		257, -- Priest Holy
		264, -- Shaman Restoration
	}

	for _, specID in pairs(healerSpecIDs) do
		local _, name = GetSpecializationInfoByID(specID)
		if name and not healerSpecs[name] then
			healerSpecs[name] = true
		end
	end

	local lastCheck = 20
	local function CheckHealers(_, elapsed)
		lastCheck = lastCheck + elapsed
		if lastCheck > 25 then
			lastCheck = 0
			healList = {}
			for i = 1, GetNumBattlefieldScores() do
				local name, _, _, _, _, faction, _, _, _, _, _, _, _, _, _, talentSpec = GetBattlefieldScore(i)

				if name and healerSpecs[talentSpec] and HealerEventFrame.factions[UnitFactionGroup("player")] == faction then
					name = name:match("(.+)%-.+") or name
					healList[name] = talentSpec
				end
			end
		end
	end

	local function CheckArenaHealers(_, elapsed)
		lastCheck = lastCheck + elapsed
		if lastCheck > 25 then
			lastCheck = 0
			healList = {}
			for i = 1, 5 do
				local specID = GetArenaOpponentSpec(i)
				if specID and specID > 0 then
					local name = UnitName(string_format("arena%d", i))
					local _, talentSpec = GetSpecializationInfoByID(specID)
					if name and healerSpecs[talentSpec] then
						healList[name] = talentSpec
					end
				end
			end
		end
	end

	HealerEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	HealerEventFrame:RegisterEvent("PLAYER_ENTERING_BATTLEGROUND")
	HealerEventFrame:SetScript("OnEvent", function(_, event)
		if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_ENTERING_BATTLEGROUND" then
			local _, instanceType = IsInInstance()
			if instanceType == "pvp" then
				HealerEventFrame:SetScript("OnUpdate", CheckHealers)
			elseif instanceType == "arena" then
				HealerEventFrame:SetScript("OnUpdate", CheckArenaHealers)
			else
				healList = {}
				HealerEventFrame:SetScript("OnUpdate", nil)
			end
		end
	end)
end

-- Init
function UF:PlateInsideView()
	if C["Nameplate"].InsideView then
		SetCVar("nameplateOtherTopInset", 0.05)
		SetCVar("nameplateOtherBottomInset", 0.08)
	else
		SetCVar("nameplateOtherTopInset", -1)
		SetCVar("nameplateOtherBottomInset", -1)
	end
end

function UF:UpdatePlateScale()
	SetCVar("namePlateMinScale", C["Nameplate"].MinScale)
	SetCVar("namePlateMaxScale", C["Nameplate"].MinScale)
end

function UF:UpdatePlateAlpha()
	SetCVar("nameplateMinAlpha", 1)
	SetCVar("nameplateMaxAlpha", 1)
end

function UF:UpdatePlateRange()
	SetCVar("nameplateMaxDistance", C["Nameplate"].Distance)
end

function UF:UpdatePlateSpacing()
	SetCVar("nameplateOverlapV", C["Nameplate"].VerticalSpacing)
end

function UF:UpdateClickableSize()
	C_NamePlate.SetNamePlateEnemySize(C["Nameplate"].PlateWidth, C["Nameplate"].PlateHeight + 40)
	C_NamePlate.SetNamePlateFriendlySize(C["Nameplate"].PlateWidth, C["Nameplate"].PlateHeight + 40)
end

function UF:SetupCVars()
	UF:PlateInsideView()
	SetCVar("nameplateOverlapH", .8)
	UF:UpdatePlateSpacing()
	UF:UpdatePlateRange()
	UF:UpdatePlateAlpha()
	SetCVar("nameplateSelectedAlpha", 1)
	SetCVar("showQuestTrackingTooltips", 1)

	UF:UpdatePlateScale()
	SetCVar("nameplateSelectedScale", 1)
	SetCVar("nameplateLargerScale", 1)

	SetCVar("nameplateShowSelf", 0)
	SetCVar("nameplateResourceOnTarget", 0)
	K.HideInterfaceOption(InterfaceOptionsNamesPanelUnitNameplatesPersonalResource)
	K.HideInterfaceOption(InterfaceOptionsNamesPanelUnitNameplatesPersonalResourceOnEnemy)

	UF:UpdateClickableSize()
	hooksecurefunc(NamePlateDriverFrame, "UpdateNamePlateOptions", UF.UpdateClickableSize)
end

function UF:BlockAddons()
	if not DBM or not DBM.Nameplate then
		return
	end

	function DBM.Nameplate:SupportedNPMod()
		return true
	end

	local function showAurasForDBM(_, _, _, spellID)
		if not tonumber(spellID) then
			return
		end

		if not K.NameplateWhiteList[spellID] then
			K.NameplateWhiteList[spellID] = true
		end
	end

	hooksecurefunc(DBM.Nameplate, "Show", showAurasForDBM)
end

function UF:UpdateUnitPower()
	local unitName = self.unitName
	local npcID = self.npcID
	local shouldShowPower = K.NameplateShowPowerList[unitName] or K.NameplateShowPowerList[npcID]
	if shouldShowPower then
		self.powerText:Show()
	else
		self.powerText:Hide()
	end
end

-- Refresh for Nameplates quest into
local groupRoles, isInGroup = {}
local function refreshGroupRoles()
	local isInRaid = IsInRaid()
	isInGroup = isInRaid or IsInGroup()
	table_wipe(groupRoles)

	if isInGroup then
		local numPlayers = (isInRaid and GetNumGroupMembers()) or GetNumSubgroupMembers()
		local unit = (isInRaid and "raid") or "party"
		for i = 1, numPlayers do
			local index = unit..i
			if UnitExists(index) then
				groupRoles[UnitName(index)] = UnitGroupRolesAssigned(index)
			end
		end
	end
end

local function resetGroupRoles()
	isInGroup = IsInRaid() or IsInGroup()
	table_wipe(groupRoles)
end

function UF:UpdateGroupRoles()
	refreshGroupRoles()
	K:RegisterEvent("GROUP_ROSTER_UPDATE", refreshGroupRoles)
	K:RegisterEvent("GROUP_LEFT", resetGroupRoles)
end

-- Update unit color
function UF.UpdateColor(element, unit)
	local self = element.__owner
	local name = self.unitName
	local npcID = self.npcID
	local isCustomUnit = K.NameplateCustomUnits[name] or K.NameplateCustomUnits[npcID]
	local isPlayer = UnitIsPlayer(unit)
	local status = UnitThreatSituation("player", unit) or false -- just in case
	local reaction = UnitReaction(unit, "player")
	local reactionColor = K.Colors.reaction[reaction]
	local customColor = C["Nameplate"].CustomColor
	local secureColor = C["Nameplate"].SecureColor
	local transColor = C["Nameplate"].TransColor
	local insecureColor = C["Nameplate"].InsecureColor
	local revertThreat = C["Nameplate"].DPSRevertThreat
	local offTankColor = C["Nameplate"].OffTankColor
	local r, g, b

	if not UnitIsConnected(unit) then
		r, g, b = 0.7, 0.7, 0.7
	else
		if isCustomUnit then
			r, g, b = customColor[1], customColor[2], customColor[3]
		elseif isPlayer and (reaction and reaction >= 5) then
			if C["Nameplate"].FriendlyCC then
				r, g, b = K.UnitColor(unit)
			else
				r, g, b = unpack(K.Colors.power["MANA"])
			end
		elseif isPlayer and (reaction and reaction <= 4) and C["Nameplate"].HostileCC then
			r, g, b = K.UnitColor(unit)
		elseif UnitIsTapDenied(unit) and not UnitPlayerControlled(unit) then
			r, g, b = 0.6, 0.6, 0.6
		elseif not UnitIsTapDenied(unit) and not UnitIsPlayer(unit) then
			if reactionColor then
				r, g, b = reactionColor[1], reactionColor[2], reactionColor[3]
			else
				r, g, b = UnitSelectionColor(unit, true)
			end
		else
			if status and (C["Nameplate"].TankMode or K.Role == "Tank") then
				if status == 3 then
					if K.Role ~= "Tank" and revertThreat then
						r, g, b = insecureColor[1], insecureColor[2], insecureColor[3]
					else
						if IsInGroup() or IsInRaid() then
							for i = 1, GetNumGroupMembers() do
								if UnitExists("raid"..i) and not UnitIsUnit("raid"..i, "player") then
									local isTanking = UnitThreatSituation("raid"..i, self.unit)
									if isTanking and UnitGroupRolesAssigned("raid"..i) == "TANK" then
										r, g, b = offTankColor[1], offTankColor[2], offTankColor[3]
									else
										r, g, b = secureColor[1], secureColor[2], secureColor[3]
									end
								end
							end
						end
					end
				elseif status == 2 or status == 1 then
					r, g, b = transColor[1], transColor[2], transColor[3]
				elseif status == 0 then
					if K.Role ~= "Tank" and revertThreat then
						r, g, b = secureColor[1], secureColor[2], secureColor[3]
					else
						r, g, b = insecureColor[1], insecureColor[2], insecureColor[3]
					end
				end
			end
		end
	end

	if r or g or b then
		element:SetStatusBarColor(r, g, b)
	end

	if isCustomUnit or (not C["Nameplate"].TankMode and K.Role ~= "Tank") then
		if status and status == 3 then
			element.Shadow:SetBackdropBorderColor(1, 0, 0, 0.8)
		elseif status and (status == 2 or status == 1) then
			element.Shadow:SetBackdropBorderColor(1, 1, 0, 0.8)
		else
			element.Shadow:SetBackdropBorderColor(0, 0, 0, 0.8)
		end
	else
		element.Shadow:SetBackdropBorderColor(0, 0, 0, 0.8)
	end
end

function UF:UpdateThreatColor(_, unit)
	if unit ~= self.unit then
		return
	end

	UF.UpdateColor(self.Health, unit)
end

function UF:CreateThreatColor(self)
	local frame = CreateFrame("Frame", nil, self)
	self.ThreatIndicator = frame
	self.ThreatIndicator.Override = UF.UpdateThreatColor
end

-- Target indicator
function UF:UpdateTargetChange()
	local element = self.TargetIndicator
	if UnitIsUnit(self.unit, "target") and not UnitIsUnit(self.unit, "player") then
		element:SetAlpha(1)
	else
		element:SetAlpha(0)
	end
end

function UF:UpdateTargetIndicator(self)
	local style = C["Nameplate"].TargetIndicator.Value

	if style == 1 then
		self.TargetIndicator:Hide()
	else
		if style == 2 then
			self.TargetIndicator.TopArrow:Show()
			self.TargetIndicator.RightArrow:Hide()
			self.TargetIndicator.Glow:Hide()
		elseif style == 3 then
			self.TargetIndicator.TopArrow:Hide()
			self.TargetIndicator.RightArrow:Show()
			self.TargetIndicator.Glow:Hide()
		elseif style == 4 then
			self.TargetIndicator.TopArrow:Hide()
			self.TargetIndicator.RightArrow:Hide()
			self.TargetIndicator.Glow:Show()
		elseif style == 5 then
			self.TargetIndicator.TopArrow:Show()
			self.TargetIndicator.RightArrow:Hide()
			self.TargetIndicator.Glow:Show()
		elseif style == 6 then
			self.TargetIndicator.TopArrow:Hide()
			self.TargetIndicator.RightArrow:Show()
			self.TargetIndicator.Glow:Show()
		end

		self.TargetIndicator:Show()
	end
end

function UF:AddTargetIndicator(self)
	self.TargetIndicator = CreateFrame("Frame", nil, self)
	self.TargetIndicator:SetAllPoints()
	self.TargetIndicator:SetFrameLevel(0)
	self.TargetIndicator:SetAlpha(0)

	self.TargetIndicator.TopArrow = self.TargetIndicator:CreateTexture(nil, "BACKGROUND", nil, -5)
	self.TargetIndicator.TopArrow:SetSize(40, 40)
	self.TargetIndicator.TopArrow:SetTexture(C["Media"].NPArrow)
	self.TargetIndicator.TopArrow:SetPoint("BOTTOM", self.TargetIndicator, "TOP", 0, 10)
	self.TargetIndicator.TopArrow:SetRotation(math_rad(-90))

	self.TargetIndicator.RightArrow = self.TargetIndicator:CreateTexture(nil, "BACKGROUND", nil, -5)
	self.TargetIndicator.RightArrow:SetSize(40, 40)
	self.TargetIndicator.RightArrow:SetTexture(C["Media"].NPArrow)
	self.TargetIndicator.RightArrow:SetPoint("LEFT", self.TargetIndicator, "RIGHT", 3, 0)
	self.TargetIndicator.RightArrow:SetRotation(math_rad(-180))

	self.TargetIndicator.Glow = CreateFrame("Frame", nil, self.TargetIndicator)
	self.TargetIndicator.Glow:SetPoint("TOPLEFT", self.TargetIndicator, -5, 5)
	self.TargetIndicator.Glow:SetPoint("BOTTOMRIGHT", self.TargetIndicator, 5, -5)
	self.TargetIndicator.Glow:SetBackdrop({edgeFile = C["Media"].Glow, edgeSize = 4})
	self.TargetIndicator.Glow:SetBackdropBorderColor(unpack(C["Nameplate"].TargetIndicatorColor))
	self.TargetIndicator.Glow:SetFrameLevel(0)

	UF:UpdateTargetIndicator(self)
	self:RegisterEvent("PLAYER_TARGET_CHANGED", UF.UpdateTargetChange, true)
end

-- Quest progress
local isInInstance
local function CheckInstanceStatus()
	isInInstance = IsInInstance()
end

function UF:QuestIconCheck()
	if not C["Nameplate"].QuestIndicator then
		return
	end

	CheckInstanceStatus()
	K:RegisterEvent("PLAYER_ENTERING_WORLD", CheckInstanceStatus)
end

local unitTip = CreateFrame("GameTooltip", "KKUIQuestUnitTip", nil, "GameTooltipTemplate")
function UF:UpdateQuestUnit(_, unit)
	if not C["Nameplate"].QuestIndicator then
		return
	end

	if isInInstance then
		self.questIcon:Hide()
		self.questCount:SetText("")
		return
	end

	unit = unit or self.unit

	local isLootQuest, questProgress
	unitTip:SetOwner(UIParent, "ANCHOR_NONE")
	unitTip:SetUnit(unit)

	for i = 2, unitTip:NumLines() do
		local textLine = _G[unitTip:GetName().."TextLeft"..i]
		local text = textLine:GetText()
		if textLine and text then
			local r, g, b = textLine:GetTextColor()
			if r > .99 and g > .82 and b == 0 then
				if isInGroup and text == K.Name or not isInGroup then
					isLootQuest = true

					local questLine = _G[unitTip:GetName().."TextLeft"..(i+1)]
					local questText = questLine:GetText()
					if questLine and questText then
						local current, goal = string_match(questText, "(%d+)/(%d+)")
						local progress = string_match(questText, "(%d+)%%")
						if current and goal then
							current = tonumber(current)
							goal = tonumber(goal)
							if current == goal then
								isLootQuest = nil
							elseif current < goal then
								questProgress = goal - current
								break
							end
						elseif progress then
							progress = tonumber(progress)
							if progress == 100 then
								isLootQuest = nil
							elseif progress < 100 then
								questProgress = progress.."%"
								break
							end
						end
					end
				end
			end
		end
	end

	if questProgress then
		self.questCount:SetText(questProgress)
		self.questIcon:SetAtlas("Warfronts-BaseMapIcons-Horde-Barracks-Minimap")
		self.questIcon:Show()
	else
		self.questCount:SetText("")
		if isLootQuest then
			self.questIcon:SetAtlas("adventureguide-microbutton-alert")
			self.questIcon:Show()
		else
			self.questIcon:Hide()
		end
	end
end

function UF:AddQuestIcon(self)
	if not C["Nameplate"].QuestIndicator then
		return
	end

	self.questIcon = self:CreateTexture(nil, "OVERLAY", nil, 2)
	self.questIcon:SetPoint("LEFT", self, "RIGHT", 2, 0)
	self.questIcon:SetSize(18, 18)
	self.questIcon:SetAtlas("adventureguide-microbutton-alert")
	self.questIcon:Hide()

	self.questCount = K.CreateFontString(self, 11, "", "", nil, "LEFT", 0, 0)
	self.questCount:SetPoint("LEFT", self.questIcon, "RIGHT", -1, 0)

	self:RegisterEvent("QUEST_LOG_UPDATE", UF.UpdateQuestUnit, true)
end

-- Dungeon progress, AngryKeystones required
function UF:AddDungeonProgress(self)
	if not C["Nameplate"].AKSProgress then
		return
	end

	self.progressText = K.CreateFontString(self, 12, "", "", false, "LEFT", 0, 0)
	self.progressText:SetPoint("LEFT", self, "RIGHT", 5, 0)
end

local cache = {}
function UF:UpdateDungeonProgress(unit)
	if not self.progressText or not AngryKeystones_Data then
		return
	end

	if unit ~= self.unit then
		return
	end

	self.progressText:SetText("")

	local name, _, _, _, _, _, _, _, _, scenarioType = C_Scenario_GetInfo()
	if scenarioType == LE_SCENARIO_TYPE_CHALLENGE_MODE then
		local npcID = self.npcID
		local info = AngryKeystones_Data.progress[npcID]
		if info then
			local numCriteria = select(3, C_Scenario_GetStepInfo())
			local total = cache[name]
			if not total then
				for criteriaIndex = 1, numCriteria do
					local _, _, _, _, totalQuantity, _, _, _, _, _, _, _, isWeightedProgress = C_Scenario_GetCriteriaInfo(criteriaIndex)
					if isWeightedProgress then
						cache[name] = totalQuantity
						total = cache[name]
						break
					end
				end
			end

			local value, valueCount
			for amount, count in pairs(info) do
				if not valueCount or count > valueCount or (count == valueCount and amount < value) then
					value = amount
					valueCount = count
				end
			end

			if value and total then
				self.progressText:SetText(string_format("+%.2f", value / total*100))
			end
		end
	end
end

-- Unit classification
local classify = {
	rare = {1, 1, 1, true},
	elite = {1, 1, 1},
	rareelite = {1, .1, .1},
	worldboss = {0, 1, 0},
}

function UF:AddCreatureIcon(self)
	local iconFrame = CreateFrame("Frame", nil, self)
	iconFrame:SetAllPoints()
	iconFrame:SetFrameLevel(self:GetFrameLevel() + 2)

	self.creatureIcon = iconFrame:CreateTexture(nil, "ARTWORK")
	self.creatureIcon:SetAtlas("VignetteKill")
	self.creatureIcon:SetPoint("BOTTOMLEFT", self, "LEFT", 0, -4)
	self.creatureIcon:SetSize(14, 14)
	self.creatureIcon:Hide()
end

function UF:UpdateUnitClassify(unit)
	local class = UnitClassification(unit)
	if self.creatureIcon then
		if class and classify[class] then
			local r, g, b, desature = unpack(classify[class])
			self.creatureIcon:SetVertexColor(r, g, b)
			self.creatureIcon:SetDesaturated(desature)
			self.creatureIcon:Show()
		else
			self.creatureIcon:Hide()
		end
	end
end

-- Scale plates for explosives
local hasExplosives
local id = 120651
function UF:UpdateExplosives(event, unit)
	if not hasExplosives or unit ~= self.unit then
		return
	end

	local npcID = self.npcID
	if event == "NAME_PLATE_UNIT_ADDED" and npcID == id then
		self:SetScale(1.25)
	elseif event == "NAME_PLATE_UNIT_REMOVED" then
		self:SetScale(1)
	end
end

local function checkInstance()
	local name, _, instID = GetInstanceInfo()
	if name and instID == 8 then
		hasExplosives = true
	else
		hasExplosives = false
	end
end

local function checkAffixes(event)
	local affixes = C_MythicPlus_GetCurrentAffixes()
	if not affixes then
		return
	end

	if affixes[3] and affixes[3].id == 13 then
		checkInstance()
		K:RegisterEvent(event, checkInstance)
		K:RegisterEvent("CHALLENGE_MODE_START", checkInstance)
	end

	K:UnregisterEvent(event, checkAffixes)
end

function UF:CheckExplosives()
	if not C["Nameplate"].ExplosivesScale then
		return
	end

	K:RegisterEvent("PLAYER_ENTERING_WORLD", checkAffixes)
end

-- Mouseover indicator
function UF:IsMouseoverUnit()
	if not self or not self.unit then
		return
	end

	if self:IsVisible() and UnitExists("mouseover") then
		return UnitIsUnit("mouseover", self.unit)
	end

	return false
end

function UF:UpdateMouseoverShown()
	if not self or not self.unit then
		return
	end

	if self:IsShown() and UnitIsUnit("mouseover", self.unit) then
		self.HighlightIndicator:Show()
		self.HighlightUpdater:Show()
	else
		self.HighlightUpdater:Hide()
	end
end

function UF:MouseoverIndicator(self)
	self.HighlightIndicator = CreateFrame("Frame", nil, self.Health)
	self.HighlightIndicator:SetAllPoints(self)
	self.HighlightIndicator:Hide()

	self.HighlightIndicator.Texture = self.HighlightIndicator:CreateTexture(nil, "ARTWORK")
	self.HighlightIndicator.Texture:SetAllPoints()
	self.HighlightIndicator.Texture:SetColorTexture(1, 1, 1, .25)

	self:RegisterEvent("UPDATE_MOUSEOVER_UNIT", UF.UpdateMouseoverShown, true)

	self.HighlightUpdater = CreateFrame("Frame", nil, self)
	self.HighlightUpdater:SetScript("OnUpdate", function(_, elapsed)
		self.HighlightUpdater.elapsed = (self.HighlightUpdater.elapsed or 0) + elapsed
		if self.HighlightUpdater.elapsed > .1 then
			if not UF.IsMouseoverUnit(self) then
				self.HighlightUpdater:Hide()
			end

			self.HighlightUpdater.elapsed = 0
		end
	end)

	self.HighlightUpdater:HookScript("OnHide", function()
		self.HighlightIndicator:Hide()
	end)
end

-- NazjatarFollowerXP
function UF:AddFollowerXP(self)
	self.NazjatarFollowerXP = CreateFrame("StatusBar", nil, self)
	self.NazjatarFollowerXP:SetStatusBarTexture(C["Media"].Texture)
	self.NazjatarFollowerXP:SetSize(C["Nameplate"].PlateWidth * 0.75, C["Nameplate"].PlateHeight)
	self.NazjatarFollowerXP:SetPoint("TOP", self.Castbar, "BOTTOM", 0, -5)

	self.NazjatarFollowerXP.progressText = K.CreateFontString(self.NazjatarFollowerXP, 9)
end

function UF:AddClassIcon(self)
	if C["Nameplate"].ClassIcon == true then
		self.Class = CreateFrame("Frame", nil, self)

		self.Class.Icon = self.Class:CreateTexture(nil, "OVERLAY")
		self.Class.Icon:SetSize(self:GetHeight() * 2 + 3, self:GetHeight() * 2 + 3)
		self.Class.Icon:SetPoint("BOTTOMRIGHT", self.Castbar, "BOTTOMLEFT", -3, 0)
		self.Class.Icon:SetTexture("Interface\\WorldStateFrame\\Icons-Classes")
		self.Class.Icon:SetTexCoord(0, 0, 0, 0)

		self.Class:SetAllPoints(self.Class.Icon)
		self.Class:CreateShadow(true)
	end
end

function UF:UpdatePlateClassIcons(unit)
	if C["Nameplate"].ClassIcon == true then
		if UnitIsPlayer(unit) and (UnitReaction("player", unit) and UnitReaction("player", unit) <= 4) then
			local _, class = UnitClass(unit)
			local texcoord = CLASS_ICON_TCOORDS[class]
			self.Class.Icon:SetTexCoord(texcoord[1] + 0.015, texcoord[2] - 0.02, texcoord[3] + 0.018, texcoord[4] - 0.02)
			self.Class:Show()
		else
			self.Class.Icon:SetTexCoord(0, 0, 0, 0)
			self.Class:Hide()
		end
	end
end

function UF:AddHealerIcon(self)
	if C["Nameplate"].HealerIcon == true then
		self.HPHeal = self:CreateTexture(nil, "OVERLAY")
		self.HPHeal:SetTexture(C["Media"].NPHealer)
		self.HPHeal:SetPoint("BOTTOM", self.Auras, "TOP", 0, -20)
	end
end

function UF:UpdateHealerIcon(unit)
	if C["Nameplate"].HealerIcon == true then
		local name = UnitName(unit)
		if name then
			if testing then
				self.HPHeal:Show()
			else
				if healList[name] then
					if exClass[healList[name]] then
						self.HPHeal:Hide()
					else
						self.HPHeal:Show()
					end
				else
					self.HPHeal:Hide()
				end
			end
		end
	end
end

-- Interrupt info on castbars
local guidToPlate = {}
function UF:UpdateCastbarInterrupt(...)
	local _, eventType, _, sourceGUID, sourceName, _, _, destGUID = ...
	if eventType == "SPELL_INTERRUPT" and destGUID and sourceName and sourceName ~= "" then
		local nameplate = guidToPlate[destGUID]
		if nameplate and nameplate.Castbar then
			local _, class = GetPlayerInfoByGUID(sourceGUID)
			local r, g, b = K.ColorClass(class)
			local color = K.RGBToHex(r, g, b)
			local sourceName = Ambiguate(sourceName, "short")
			nameplate.Castbar.Text:SetText(INTERRUPTED.." > "..color..sourceName)
			nameplate.Castbar.Time:SetText("")
		end
	end
end

function UF:AddInterruptInfo()
	K:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", self.UpdateCastbarInterrupt)
end

function UF.CustomFilter(element, unit, _, _, _, _, _, _, _, caster, isStealable, _, spellID, _, _, _, nameplateShowAll)
	if K.NameplateBlackList[spellID] then
		return false
	elseif element.showStealableBuffs and isStealable and not UnitIsPlayer(unit) then
		return true
	elseif K.NameplateWhiteList[spellID] then
		return true
	else
		return nameplateShowAll or (caster == "player" or caster == "pet" or caster == "vehicle")
	end
end

local function auraIconSize(w, n, s)
	return (w - (n - 1) * s) / n
end

-- Create Nameplates
function UF:CreatePlates()
	self.mystyle = "nameplate"
	self:SetSize(C["Nameplate"].PlateWidth, C["Nameplate"].PlateHeight)
	self:SetPoint("CENTER")

	self.Health = CreateFrame("StatusBar", nil, self)
	self.Health:SetAllPoints()
	self.Health:SetStatusBarTexture(NameplateTexture)
	self.Health:CreateShadow(true)
	self.Health.UpdateColor = UF.UpdateColor
	self.Health.frequentUpdates = true

	self.Health.Smooth = true
	self.Health.colorTapping = true
	self.Health.colorDisconnected = true
	self.Health.colorClass = true
	self.Health.colorReaction = true
	self.Health.colorHealth = true

	if C["Nameplate"].Smooth then
		K.SmoothBar(self.Health)
	end

	self.levelText = K.CreateFontString(self.Health, C["Nameplate"].NameTextSize, "", "", false)
	self.levelText:SetJustifyH("RIGHT")
	--self.levelText:SetWidth(self:GetWidth() * 0.85)
	self.levelText:ClearAllPoints()
	self.levelText:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, 3)
	self:Tag(self.levelText, "[nplevel]")

	self.nameText = K.CreateFontString(self.Health, C["Nameplate"].NameTextSize, "", "", false)
	self.nameText:SetJustifyH("LEFT")
	self.nameText:SetWidth(self:GetWidth() * 0.85)
	self.nameText:ClearAllPoints()
	self.nameText:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 3)
	self:Tag(self.nameText, "[name]")

	self.healthValue = K.CreateFontString(self.Health, C["Nameplate"].HealthTextSize, "", "", false, "CENTER", 0, 0)
	self.healthValue:SetPoint("CENTER", self, 0, 0)
	self:Tag(self.healthValue, "[nphp]")

	self.Castbar = CreateFrame("StatusBar", "oUF_CastbarNameplate", self)
	self.Castbar:SetHeight(20)
	self.Castbar:SetWidth(self:GetWidth() - 22)
	self.Castbar:SetStatusBarTexture(NameplateTexture)
	self.Castbar:CreateShadow(true)
	self.Castbar:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -3)
	self.Castbar:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -3)
	self.Castbar:SetHeight(self:GetHeight())

	self.Castbar.Time = K.CreateFontString(self.Castbar, 10, "", "", false, "RIGHT", -2, 0)
	self.Castbar.Text = K.CreateFontString(self.Castbar, 10, "", "", false, "LEFT", 2, 0)
	self.Castbar.Text:SetPoint("RIGHT", self.Castbar.Time, "LEFT", -5, 0)
	self.Castbar.Text:SetJustifyH("LEFT")

	self.Castbar.Button = CreateFrame("Frame", nil, self.Castbar)
	self.Castbar.Button:SetSize(self:GetHeight() * 2 + 3, self:GetHeight() * 2 + 3)
	self.Castbar.Button:SetPoint("BOTTOMRIGHT", self.Castbar, "BOTTOMLEFT", -3, 0)
	self.Castbar.Button:CreateShadow(true)

	self.Castbar.Icon = self.Castbar.Button:CreateTexture(nil, "ARTWORK")
	self.Castbar.Icon:SetAllPoints()
	self.Castbar.Icon:SetTexCoord(unpack(K.TexCoords))

	self.Castbar.Text:SetPoint("LEFT", self.Castbar, 0, -5)
	self.Castbar.Time:SetPoint("RIGHT", self.Castbar, 0, -5)

	self.Castbar.Shield = self.Castbar:CreateTexture(nil, "OVERLAY")
	self.Castbar.Shield:SetTexture("Interface\\AddOns\\KkthnxUI\\Media\\Textures\\CastBorderShield")
	self.Castbar.Shield:SetTexCoord(0, 0.84375, 0, 1)
	self.Castbar.Shield:SetSize(14 * 0.84375, 14)
	self.Castbar.Shield:SetPoint("CENTER", 0, -5)
	self.Castbar.Shield:SetVertexColor(0.5, 0.5, 0.7)

	self.Castbar.timeToHold = .5
	self.Castbar.decimal = "%.1f"
	self.Castbar.OnUpdate = UF.OnCastbarUpdate
	self.Castbar.PostCastStart = UF.PostCastStart
	self.Castbar.PostChannelStart = UF.PostCastStart
	self.Castbar.PostCastStop = UF.PostCastStop
	self.Castbar.PostChannelStop = UF.PostChannelStop
	self.Castbar.PostCastFailed = UF.PostCastFailed
	self.Castbar.PostCastInterrupted = UF.PostCastFailed
	self.Castbar.PostCastInterruptible = UF.PostUpdateInterruptible
	self.Castbar.PostCastNotInterruptible = UF.PostUpdateInterruptible

	self.RaidTargetIndicator = self:CreateTexture(nil, "OVERLAY")
	self.RaidTargetIndicator:SetPoint("RIGHT", self, "LEFT", -5, 0)
	self.RaidTargetIndicator:SetSize(16, 16)

	local mhpb = self:CreateTexture(nil, "BORDER", nil, 5)
	mhpb:SetWidth(1)
	mhpb:SetTexture(HealPredictionTexture)
	mhpb:SetVertexColor(0, 1, 0.5, 0.25)

	local ohpb = self:CreateTexture(nil, "BORDER", nil, 5)
	ohpb:SetWidth(1)
	ohpb:SetTexture(HealPredictionTexture)
	ohpb:SetVertexColor(0, 1, 0, 0.25)

	local abb = self:CreateTexture(nil, "BORDER", nil, 5)
	abb:SetWidth(1)
	abb:SetTexture(HealPredictionTexture)
	abb:SetVertexColor(1, 1, 0, 0.25)

	local abbo = self:CreateTexture(nil, "ARTWORK", nil, 1)
	abbo:SetAllPoints(abb)
	abbo:SetTexture("Interface\\RaidFrame\\Shield-Overlay", true, true)
	abbo.tileSize = 32

	local oag = self:CreateTexture(nil, "ARTWORK", nil, 1)
	oag:SetWidth(15)
	oag:SetTexture("Interface\\RaidFrame\\Shield-Overshield")
	oag:SetBlendMode("ADD")
	oag:SetAlpha(.25)
	oag:SetPoint("TOPLEFT", self.Health, "TOPRIGHT", -5, 2)
	oag:SetPoint("BOTTOMLEFT", self.Health, "BOTTOMRIGHT", -5, -2)

	local hab = CreateFrame("StatusBar", nil, self)
	hab:SetPoint("TOP")
	hab:SetPoint("BOTTOM")
	hab:SetPoint("RIGHT", self.Health:GetStatusBarTexture())
	hab:SetWidth(self.Health:GetWidth())
	hab:SetReverseFill(true)
	hab:SetStatusBarTexture(HealPredictionTexture)
	hab:SetStatusBarColor(1, 0, 0, 0.25)

	local ohg = self:CreateTexture(nil, "ARTWORK", nil, 1)
	ohg:SetWidth(15)
	ohg:SetTexture("Interface\\RaidFrame\\Absorb-Overabsorb")
	ohg:SetBlendMode("ADD")
	ohg:SetPoint("TOPRIGHT", self.Health, "TOPLEFT", 5, 2)
	ohg:SetPoint("BOTTOMRIGHT", self.Health, "BOTTOMLEFT", 5, -2)

	self.HealPredictionAndAbsorb = {
		myBar = mhpb,
		otherBar = ohpb,
		absorbBar = abb,
		absorbBarOverlay = abbo,
		overAbsorbGlow = oag,
		healAbsorbBar = hab,
		overHealAbsorbGlow = ohg,
		maxOverflow = 1,
	}

	self.Auras = CreateFrame("Frame", nil, self)
	self.Auras:SetFrameLevel(self:GetFrameLevel() + 2)
	self.Auras.gap = true
	self.Auras.initialAnchor = "TOPLEFT"
	self.Auras["growth-y"] = "DOWN"
	self.Auras.spacing = 5
	self.Auras.initialAnchor = "BOTTOMLEFT"
	self.Auras["growth-y"] = "UP"
	if C["Nameplate"].ShowPlayerPlate and C["Nameplate"].NameplateClassPower then
		self.Auras:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 15 + _G.oUF_ClassPowerBar:GetHeight() + 6)
	else
		self.Auras:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 15)
	end
	self.Auras.numTotal = C["Nameplate"].MaxAuras
	self.Auras.spacing = 3
	self.Auras.size = C["Nameplate"].AuraSize
	self.Auras.gap = false
	self.Auras.disableMouse = true

	local width = self:GetWidth()
	local maxAuras = self.Auras.numTotal or self.Auras.numBuffs + self.Auras.numDebuffs
	local maxLines = self.Auras.iconsPerRow and math_floor(maxAuras / self.Auras.iconsPerRow + 0.5) or 2
	self.Auras.size = self.Auras.iconsPerRow and auraIconSize(width, self.Auras.iconsPerRow, self.Auras.spacing) or self.Auras.size
	self.Auras:SetWidth(width)
	self.Auras:SetHeight((self.Auras.size + self.Auras.spacing) * maxLines)

	self.Auras.showStealableBuffs = true
	self.Auras.CustomFilter = UF.CustomFilter
	self.Auras.PostCreateIcon = UF.PostCreateAura
	self.Auras.PostUpdateIcon = UF.PostUpdateAura

	self.PvPClassificationIndicator = self:CreateTexture(nil, "ARTWORK")
	self.PvPClassificationIndicator:SetSize(18, 18)
	self.PvPClassificationIndicator:SetPoint("LEFT", self, "RIGHT", 6, 0)

	UF:CreateThreatColor(self)

	self.powerText = K.CreateFontString(self, 15)
	self.powerText:ClearAllPoints()
	self.powerText:SetPoint("TOP", self.Castbar, "BOTTOM", 0, -4)
	self:Tag(self.powerText, "[nppp]")

	-- UF:AddFollowerXP(self) -- Enable when fixed.
	UF:MouseoverIndicator(self)
	UF:AddTargetIndicator(self)
	UF:AddCreatureIcon(self)
	UF:AddQuestIcon(self)
	UF:AddDungeonProgress(self)
	UF:AddClassIcon(self)
	UF:AddHealerIcon(self)
end

-- Classpower on target nameplate
local isTargetClassPower
function UF:UpdateClassPowerAnchor()
	if not isTargetClassPower then
		return
	end

	local bar = _G.oUF_ClassPowerBar
	local nameplate = C_NamePlate_GetNamePlateForUnit("target")
	if nameplate then
		bar:SetParent(nameplate.unitFrame)
		bar:ClearAllPoints()
		bar:SetPoint("TOPLEFT", nameplate.unitFrame, "TOPLEFT", 0, 22)
		bar:Show()
	else
		bar:Hide()
	end
end

function UF:UpdateTargetClassPower()
	local bar = _G.oUF_ClassPowerBar
	local playerPlate = _G.oUF_PlayerPlate

	if not bar or not playerPlate then
		return
	end

	if C["Nameplate"].NameplateClassPower then
		isTargetClassPower = true
		UF:UpdateClassPowerAnchor()
	else
		isTargetClassPower = false
		bar:SetParent(playerPlate.Health)
		bar:ClearAllPoints()
		bar:SetPoint("TOPLEFT", playerPlate.Health, 0, 3)
		bar:Show()
	end
end

function UF.PostUpdateNameplateClassPower(element, cur, max, diff, powerType)
	if diff then
		for i = 1, max do
			element[i]:SetWidth((C["Nameplate"].PlateWidth - (max - 1) * 6) / max)
		end
	end

	if (K.Class == "ROGUE" or K.Class == "DRUID") and (powerType == "COMBO_POINTS") and element.__owner.unit ~= "vehicle" then
		for i = 1, 6 do
			element[i]:SetStatusBarColor(unpack(K.Colors.power.COMBO_POINTS[i]))
		end
	end

	if (powerType == "COMBO_POINTS" or powerType == "HOLY_POWER") and element.__owner.unit ~= "vehicle" and cur == max then
		for i = 1, 6 do
			if element[i]:IsShown() then
				if C["Nameplate"].ShowPlayerPlate and C["Nameplate"].MaxPowerGlow then
					K.libCustomGlow.AutoCastGlow_Start(element[i])
				end
			end
		end
	else
		for i = 1, 6 do
			if C["Nameplate"].ShowPlayerPlate and C["Nameplate"].MaxPowerGlow then
				K.libCustomGlow.AutoCastGlow_Stop(element[i])
			end
		end
	end
end

function UF:PostUpdatePlates(event, unit)
	if not self then
		return
	end

	if event == "NAME_PLATE_UNIT_ADDED" then
		self.unitName = UnitName(unit)
		self.unitGUID = UnitGUID(unit)
		if self.unitGUID then
			guidToPlate[self.unitGUID] = self
		end
		self.npcID = K.GetNPCID(self.unitGUID)
	elseif event == "NAME_PLATE_UNIT_REMOVED" then
		if self.unitGUID then
			guidToPlate[self.unitGUID] = nil
		end
	end

	UF.UpdateUnitPower(self)
	UF.UpdateTargetChange(self)
	UF.UpdateQuestUnit(self, event, unit)
	UF.UpdateUnitClassify(self, unit)
	UF.UpdateExplosives(self, event, unit)
	UF.UpdateDungeonProgress(self, unit)
	UF.UpdatePlateClassIcons(self, unit)
	UF.UpdateHealerIcon(self, unit)
	UF:UpdateClassPowerAnchor()
end

-- Player Nameplate
function UF:PlateVisibility(event)
	if (event == "PLAYER_REGEN_DISABLED" or InCombatLockdown()) and UnitIsUnit("player", self.unit) then
		K.UIFrameFadeIn(self.Health, 0.3, self.Health:GetAlpha(), 1)
		K.UIFrameFadeIn(self.Power, 0.3, self.Power:GetAlpha(), 1)
	else
		K.UIFrameFadeOut(self.Health, 2, self.Health:GetAlpha(), 0.1)
		K.UIFrameFadeOut(self.Power, 2, self.Power:GetAlpha(), 0.1)
	end
end

function UF:CreatePlayerPlate()
	local iconSize, margin = C["Nameplate"].PPIconSize, 2

	self:SetSize(iconSize * 5 + margin * 4, C["Nameplate"].PPHeight)
	self:EnableMouse(false)
	self.iconSize = iconSize

	self.Health = CreateFrame("StatusBar", nil, self)
	self.Health:SetAllPoints()
	self.Health:SetStatusBarTexture(NameplateTexture)
	self.Health:SetStatusBarColor(.1, .1, .1)
	self.Health:CreateShadow(true)

	self.Health.colorHealth = true

	self.Power = CreateFrame("StatusBar", nil, self)
	self.Power:SetStatusBarTexture(NameplateTexture)
	self.Power:SetHeight(C["Nameplate"].PPPHeight)
	self.Power:SetWidth(self:GetWidth())
	self.Power:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -3)
	self.Power:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -3)
	self.Power:CreateShadow(true)

	self.Power.colorClass = true
	self.Power.colorTapping = true
	self.Power.colorDisconnected = true
	self.Power.colorReaction = true
	self.Power.frequentUpdates = true

	do
		local bar = CreateFrame("Frame", "oUF_ClassPowerBar", self.Health)
		bar:SetSize(C["Nameplate"].PlateWidth, C["Nameplate"].PlateHeight)
		bar:SetPoint("TOPLEFT", self.Health, 0, 3)

		local bars = {}
		for i = 1, 6 do
			bars[i] = CreateFrame("StatusBar", nil, bar)
			bars[i]:SetHeight(C["Nameplate"].PlateHeight)
			bars[i]:SetWidth((C["Nameplate"].PlateWidth - 5 * 6) / 6)
			bars[i]:SetStatusBarTexture(NameplateTexture)
			bars[i]:SetFrameLevel(self:GetFrameLevel() + 5)

			if i == 1 then
				bars[i]:SetPoint("BOTTOMLEFT")
			else
				bars[i]:SetPoint("LEFT", bars[i-1], "RIGHT", 6, 0)
			end

			bars[i]:CreateShadow(true)

			if K.Class == "DEATHKNIGHT" then
				bars[i].timer = K.CreateFontString(bars[i], 13, "")
			end

			if K.Class == "ROGUE" or K.Class == "DRUID" then
				bars[i]:SetStatusBarColor(unpack(K.Colors.power.COMBO_POINTS[i]))
			end

			if C["Nameplate"].ShowPlayerPlate then
				bars[i].glow = CreateFrame("Frame", nil, bars[i])
				bars[i].glow:SetPoint("TOPLEFT", -3, 2)
				bars[i].glow:SetPoint("BOTTOMRIGHT", 3, -2)
			end
		end

		if K.Class == "DEATHKNIGHT" then
			bars.colorSpec = true
			bars.sortOrder = "asc"
			bars.PostUpdate = UF.PostUpdateRunes
			self.Runes = bars
		else
			bars.PostUpdate = UF.PostUpdateNameplateClassPower
			self.ClassPower = bars
		end
	end

	if K.Class == "MONK" then
		self.Stagger = CreateFrame("StatusBar", self:GetName().."Stagger", self)
		self.Stagger:SetPoint("TOPLEFT", self.Health, 0, 8)
		self.Stagger:SetSize(self:GetWidth(), self:GetHeight())
		self.Stagger:SetStatusBarTexture(NameplateTexture)
		self.Stagger:CreateShadow(true)

		self.Stagger.Value = self.Stagger:CreateFontString(nil, "OVERLAY")
		self.Stagger.Value:SetFontObject(K.GetFont(C["UIFonts"].UnitframeFonts))
		self.Stagger.Value:SetPoint("CENTER", self.Stagger, "CENTER", 0, 0)
		self:Tag(self.Stagger.Value, "[monkstagger]")
	end

	K:GetModule("Auras"):CreateLumos(self)

	if C["Nameplate"].PPPowerText then
		local textFrame = CreateFrame("Frame", nil, self.Power)
		textFrame:SetAllPoints()

		local power = K.CreateFontString(textFrame, 14, "")
		self:Tag(power, "[pppower]")
	end

	UF:UpdateTargetClassPower()

	if C["Nameplate"].PPHideOOC then
		self:RegisterEvent("UNIT_EXITED_VEHICLE", UF.PlateVisibility)
		self:RegisterEvent("UNIT_ENTERED_VEHICLE", UF.PlateVisibility)
		self:RegisterEvent("PLAYER_REGEN_ENABLED", UF.PlateVisibility, true)
		self:RegisterEvent("PLAYER_REGEN_DISABLED", UF.PlateVisibility, true)
		self:RegisterEvent("PLAYER_ENTERING_WORLD", UF.PlateVisibility, true)
	end
end