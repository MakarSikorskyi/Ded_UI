local addon, ns = ...
local cfg = ns.cfg
local unpack = unpack

local join = string.join
--------------------------------------------------------------
if not cfg.heartstone.show then return end

local activeHS = 1
local hsText = GetBindLocation()

local hsList = {
	{
		id = 307810,
		type = "spell",
		desc = "Остров Форбс"
	},
	{
		id = 6948,
		type = "item"
	},
	{
		id = 52251,
		type = "item",
		desc = "Портал в Даларан"
	},
	{
		id = 556,
		type = "spell",
	},
}
local availableHsList = {}

local function AddTexture(texture)
	return texture and "|T"..texture..":20:20:0:0:64:64:4:55:4:55|t" or ""
end

local teleportFrame = CreateFrame("Frame",nil, cfg.SXframe)
teleportFrame:SetPoint("RIGHT",-5,0)
teleportFrame:SetSize(16, 16)
---------------------------------------------------------------------
local HSFrame = CreateFrame("BUTTON","hsButton", teleportFrame, "SecureActionButtonTemplate")
HSFrame:SetPoint("RIGHT")
HSFrame:SetSize(16, 16)
HSFrame:EnableMouse(true)
HSFrame:EnableMouseWheel(true)
HSFrame:RegisterForClicks("AnyUp")
HSFrame:SetAttribute("type", "macro")

local HSText = HSFrame:CreateFontString(nil, "OVERLAY")
HSText:SetFont(cfg.text.font, cfg.text.normalFontSize)
HSText:SetPoint("RIGHT")
HSText:SetTextColor(unpack(cfg.color.normal))

local HSIcon = HSFrame:CreateTexture(nil,"OVERLAY",nil,7)
HSIcon:SetSize(16, 16)
HSIcon:SetPoint("RIGHT", HSText,"LEFT",-2,0)
HSIcon:SetTexture(cfg.mediaFolder.."datatexts\\hearth")
HSIcon:SetVertexColor(unpack(cfg.color.normal))

local function updateHsText() 
	if availableHsList[activeHS] and availableHsList[activeHS].desc then
		hsText = availableHsList[activeHS].desc
	else
		hsText = GetBindLocation()
	end
	HSText:SetText(strupper(hsText))
end

local function alreadyInList(id)
	local find = false
	for _,v in pairs(availableHsList) do
		if v.id == id then
				find = true
		  	break
		end 
	end
	return find
end

local function checkActiveList()
	for i = 1, #hsList do
		local data = hsList[i]
		if data.type == "spell" then 
			if IsSpellKnown(data.id) then
				if not alreadyInList(data.id) then
					table.insert(availableHsList, data)
				end
			end
		elseif data.type == "item" then 
			if GetItemCount(data.id) > 0 then
				if not alreadyInList(data.id) then
					table.insert(availableHsList, data)
				end
			end
		end
	end
end

local function updateActiveList()
	activeHS = 1
	
	count = #availableHsList
	for i=0, count do availableHsList[i]=nil end

	checkActiveList()
end

local function hsHover()
	GameTooltip:SetOwner(teleportFrame, cfg.tooltipPos)
	GameTooltip:AddLine(cfg.TooltipTitleText("Heartstone"))
	GameTooltip:AddLine(" ")
	HSIcon:SetVertexColor(unpack(cfg.color.hover))

	checkActiveList()

	updateHsText()
	
	maxHS =  #availableHsList

	for i = 1, #availableHsList do
		local data = availableHsList[i]

		local CDremaining = "Ready"
		local startTime, duration
		local name, icon

		if data.type == "spell" then 
			name, _, icon = GetSpellInfo(data.id)
			startTime, duration = GetSpellCooldown(data.id)
		elseif data.type == "item" then 
			name, _, _, _, _, _, _, _, _, icon = GetItemInfo(data.id)
			startTime, duration = GetItemCooldown(data.id)
		end

		if startTime ~= 0 then
			CDremaining = (startTime+duration)-GetTime()
			CDremaining = SecondsToTime(CDremaining)
		end

		if i == activeHS then
			GameTooltip:AddDoubleLine(
				join(" ",AddTexture(icon and icon or nil), cfg.hex(cfg.color.main)..name),
				cfg.hex(1,1,1)..CDremaining
			)
		else 
			GameTooltip:AddDoubleLine(
				cfg.hex(1,1,1)..join(" ",AddTexture(icon and icon or nil), name),
				cfg.hex(1,1,1)..CDremaining
			)
		end
	end
	GameTooltip:Show()
end

HSFrame:SetScript("OnEnter", function()
	if InCombatLockdown() then return end
	HSIcon:SetVertexColor(unpack(cfg.color.hover))
	if not cfg.heartstone.showTooltip then return end
	hsHover()
end)

HSFrame:SetScript("OnLeave", function() 
	HSIcon:SetVertexColor(unpack(cfg.color.normal))
	if ( GameTooltip:IsShown() ) then GameTooltip:Hide() end
end)

HSFrame:SetScript("OnMouseWheel", function(self,delta)
	activeHS = activeHS - delta
	if activeHS > maxHS then
		activeHS = maxHS
	elseif activeHS <= 1 then
		activeHS = 1
	end
	if ( GameTooltip:IsShown() ) then GameTooltip:Hide() end
	hsHover(self)
end)

-- Change the button action before the click reaches it:
function HSFrame:ChangeAction(action)
     if InCombatLockdown() then return end -- can't change attributes in combat
     self:SetAttribute("macrotext", action)
end

HSFrame:SetScript("PreClick", function(self)
    if InCombatLockdown() then return end -- can't change attributes in combat

	if availableHsList[activeHS] then
		local data = availableHsList[activeHS]

		if data.type == "spell" then 
			if IsSpellKnown(data.id) and GetSpellCooldown(data.id) == 0 then
				local spellName, _, spellIcon = GetSpellInfo(data.id)
				return self:ChangeAction("/cast " .. spellName)
			end
		elseif data.type == "item" then 
			if IsUsableItem(data.id) and GetItemCount(data.id) > 0 and GetItemCooldown(data.id) == 0 then
				local itemName, itemLink, _, _, _, _, _, _, _, itemIcon = GetItemInfo(data.id)
          		return self:ChangeAction("/use " .. itemName)
			end
		end
	end
end)

local eventframe = CreateFrame("Frame")
eventframe:RegisterEvent("PLAYER_ENTERING_WORLD")
eventframe:RegisterEvent("BAG_UPDATE")
eventframe:RegisterEvent("HEARTHSTONE_BOUND")
eventframe:RegisterEvent("MODIFIER_STATE_CHANGED")

eventframe:SetScript("OnEvent", function(this, event, arg1, arg2, arg3, arg4, ...)
	if InCombatLockdown() then return end 
	
	updateActiveList()
	updateHsText()

	HSFrame:SetSize(HSText:GetStringWidth()+16, 16)

	teleportFrame:SetSize(HSFrame:GetWidth()+8, 16)
end)