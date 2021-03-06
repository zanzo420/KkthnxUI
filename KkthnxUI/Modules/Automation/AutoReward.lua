local K, C = unpack(select(2, ...))
local Module = K:GetModule("Automation")

local _G = _G

local CreateFrame = _G.CreateFrame
local GetQuestItemLink = _G.GetQuestItemLink
local GetQuestItemInfo = _G.GetQuestItemInfo
local GetItemInfo = _G.GetItemInfo
local GetNumQuestChoices = _G.GetNumQuestChoices

local function SetupAutoReward(self)
	local firstItem = _G.QuestInfoRewardsFrameQuestInfoItem1
	if not firstItem then
		return
	end

	local bestValue, bestItem = 0
	local numQuests = GetNumQuestChoices()

	if not self.QuestRewardGoldIconFrame then
		print(self)
		self.QuestRewardGoldIconFrame = CreateFrame("Frame", nil, firstItem)
		self.QuestRewardGoldIconFrame:SetFrameStrata("HIGH")
		self.QuestRewardGoldIconFrame:SetSize(20, 20)
		self.QuestRewardGoldIconFrame.Icon = self.QuestRewardGoldIconFrame:CreateTexture(nil, "OVERLAY")
		self.QuestRewardGoldIconFrame.Icon:SetAllPoints(self.QuestRewardGoldIconFrame)
		self.QuestRewardGoldIconFrame.Icon:SetTexture("Interface\\MONEYFRAME\\UI-GoldIcon")
	end

	self.QuestRewardGoldIconFrame:Hide()

	if numQuests < 2 then
		return
	end

	for i = 1, numQuests do
		local questLink = GetQuestItemLink("choice", i)
		local _, _, amount = GetQuestItemInfo("choice", i)
		local itemSellPrice = questLink and select(11, GetItemInfo(questLink))

		local totalValue = (itemSellPrice and itemSellPrice * amount) or 0
		if totalValue > bestValue then
			bestValue = totalValue
			bestItem = i
		end
	end

	if bestItem then
		local btn = _G["QuestInfoRewardsFrameQuestInfoItem"..bestItem]
		if btn and btn.type == "choice" then
			self.QuestRewardGoldIconFrame:ClearAllPoints()
			self.QuestRewardGoldIconFrame:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -2, -2)
			self.QuestRewardGoldIconFrame:Show()
		end
	end
end

function Module:CreateAutoReward()
	if not C["Automation"].AutoReward then
		return
	end

	K:RegisterEvent("QUEST_COMPLETE", SetupAutoReward)
end