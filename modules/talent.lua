local addon, ns = ...
local cfg = ns.cfg
local unpack = unpack
--------------------------------------------------------------
if not cfg.talent.show then return end

local currentSpec = 0 -- from 1-4
local currentSpecID, currentSpecName = 0,0 --global id
local lootspecid = 0
local id, name = 0,0

local talentFrame = CreateFrame("Frame",nil, cfg.SXframe)
talentFrame:SetPoint("RIGHT", cfg.SXframe, "CENTER", -110,0)
talentFrame:SetSize(16, 16)

------------------------------------------------------------
local join = string.join
local GetActiveTalentGroup = GetActiveTalentGroup
local indexToChangeSpec = 1

local function AddTexture(texture)
	return texture and "|T"..texture..":20:20:0:0:64:64:4:55:4:55|t" or ""
end

local function switchSet()
	activeSpec = C_Talent.GetSpecInfoCache().activeTalentGroup

	local names ,_ = C_Talent.GetTalentGroupSettings(activeSpec)
	for i = 1, GetNumEquipmentSets() do
		local name = GetEquipmentSetInfo(i)
		if name and names == name then
			UseEquipmentSet(names)
		end
	end
end

local function GetTalentSpecInfo(isInspect)
	local talantGroup = GetActiveTalentGroup(isInspect)
	local maxPoints, specIdx, specName, specIcon = 0, 0

	for i = 1, MAX_TALENT_TABS do
		local name, icon, pointsSpent = GetTalentTabInfo(i, isInspect, nil, talantGroup)
		if maxPoints < pointsSpent then
			maxPoints = pointsSpent
			specIdx = i
			specName = name
			specIcon = icon
		end
	end

	if not specName then
		specName = NONE
	end
	if not specIcon then
		specIcon = "Interface\\Icons\\INV_Misc_QuestionMark"
	end

	return specIdx, specName, specIcon
end
---------------------------------------------
-- PRIMARY SPEC FRAME
---------------------------------------------

local primarySpecFrame = CreateFrame("BUTTON",nil, talentFrame)
primarySpecFrame:SetPoint("RIGHT")
primarySpecFrame:SetSize(16, 16)
primarySpecFrame:EnableMouse(true)
primarySpecFrame:EnableMouseWheel(true)
primarySpecFrame:RegisterForClicks("AnyUp")

local primarySpecText = primarySpecFrame:CreateFontString(nil, "OVERLAY")
primarySpecText:SetFont(cfg.text.font, 15)
primarySpecText:SetPoint("RIGHT")
primarySpecText:SetTextColor(unpack(cfg.color.normal))

local primarySpecIcon = primarySpecFrame:CreateTexture(nil,"OVERLAY",nil,7)
primarySpecIcon:SetSize(16, 16)
primarySpecIcon:SetPoint("RIGHT", primarySpecText,"LEFT",-2,0)
primarySpecIcon:SetVertexColor(unpack(cfg.color.normal))

local function OnEnter()
	if InCombatLockdown() then return end

	maxSpecs =  C_Talent.GetNumTalentGroups()
	activeSpec = C_Talent.GetSpecInfoCache().activeTalentGroup
	
	GameTooltip:SetOwner(talentFrame, cfg.tooltipPos)
	GameTooltip:AddLine(cfg.TooltipTitleText("Таланты"))
	GameTooltip:AddLine(" ")

	for i = 1,maxSpecs do
		local name ,texture = C_Talent.GetTalentGroupSettings(i)
		if activeSpec == i then
			if indexToChangeSpec == i then
				GameTooltip:AddLine(join(" ",AddTexture(texture and texture or nil), name and name.." (Текущий)" or "Набор талантов "..i.." (Текущий)"), .31,.99,.46)
			else
				GameTooltip:AddLine(join(" ",AddTexture(texture and texture or nil), name and name.." (Текущий)" or "Набор талантов "..i.." (Текущий)"), 1, 1, 1)
			end
		else
			if indexToChangeSpec == i then
				GameTooltip:AddLine(join(" ",AddTexture(texture and texture or nil), name and name or "Набор талантов "..i), .31,.99,.46)
			else
				GameTooltip:AddLine(join(" ",AddTexture(texture and texture or nil), name and name or "Набор талантов "..i), 1, 1, 1)
			end
		end
	end

	local name,_ = C_Talent.GetTalentGroupSettings(indexToChangeSpec)
	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine("ЛКМ", "Сменить специализацию на "..(name and name or indexToChangeSpec), 1, 1, 1, 1, 1, 0)
	GameTooltip:AddDoubleLine("ПКМ", "Открыть окно талантов", 1, 1, 1, 1, 1, 0)
	GameTooltip:AddDoubleLine("Гортать колесиком мыши для выбора специализации", "", 1, 1, 1, 1, 1, 0)

	primarySpecIcon:SetVertexColor(unpack(cfg.color.hover))
	GameTooltip:Show()
end

primarySpecFrame:SetScript("OnEnter", OnEnter)

primarySpecFrame:SetScript("OnLeave", function()
	if ( GameTooltip:IsShown() ) then GameTooltip:Hide() end
end)

primarySpecFrame:SetScript("OnClick", function(self, button, down)
	if InCombatLockdown() then return end

	if button == "LeftButton" then
		if indexToChangeSpec ~= C_Talent.GetSelectedTalentGroup() then

			if indexToChangeSpec > 2 then
				local selectedCurrencyID = C_Talent.GetSelectedCurrency() or 1

				SendServerMessage("ACMSG_ACTIVATE_SPEC", indexToChangeSpec..":"..selectedCurrencyID - 1)
				C_Timer:After(11,switchSet)
				C_Timer:After(12,switchSet)
			else
				SendServerMessage("ACMSG_ACTIVATE_SPEC", indexToChangeSpec..":0")
				C_Timer:After(6,switchSet)
				C_Timer:After(7,switchSet)
			end

		end

	elseif button == "RightButton" then
		ToggleTalentFrame()
		OnEnter(self)
	end
end)
primarySpecFrame:SetScript("OnMouseWheel", function(self,delta)

	indexToChangeSpec = indexToChangeSpec - delta
	if indexToChangeSpec > maxSpecs then
		indexToChangeSpec = maxSpecs
	elseif indexToChangeSpec <= 1 then
		indexToChangeSpec = 1
	end

	if ( GameTooltip:IsShown() ) then GameTooltip:Hide() end
	OnEnter(self)
end)
---------------------------------------------
-- EVENTS
---------------------------------------------

local eventframe = CreateFrame("Frame")
eventframe:RegisterEvent("PLAYER_ENTERING_WORLD")
eventframe:RegisterEvent("PLAYER_ALIVE")
eventframe:RegisterEvent("CHARACTER_POINTS_CHANGED")
eventframe:RegisterEvent("PLAYER_TALENT_UPDATE")
eventframe:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
eventframe:RegisterEvent("INSPECT_TALENT_READY")

eventframe:SetScript("OnEvent", function(self,event, ...)
	local displayString = ""
	maxSpecs =  C_Talent.GetNumTalentGroups()
	activeSpec = C_Talent.GetSpecInfoCache().activeTalentGroup

	local _, specName, talent = GetTalentSpecInfo()

	local name ,texture = C_Talent.GetTalentGroupSettings(activeSpec)

	if specName == "None" then
		displayString = "Без специализации"
	else
		displayString = AddTexture(texture and texture or talent) .. " " .. (name and name or specName)
	end
	
	primarySpecText:SetText(displayString)
	primarySpecFrame:SetSize(primarySpecText:GetStringWidth()+18, 16)
	primarySpecFrame:Show() 
	primarySpecFrame:EnableMouse(true)
	
	talentFrame:SetSize((primarySpecFrame:GetWidth()), 16)
end)