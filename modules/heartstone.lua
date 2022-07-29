local addon, ns = ...
local cfg = ns.cfg
local unpack = unpack
--------------------------------------------------------------
if not cfg.heartstone.show then return end

local garrOnHover = false
local hsOnHover = false

local teleportFrame = CreateFrame("Frame",nil, cfg.SXframe)
teleportFrame:SetPoint("RIGHT",-5,0)
teleportFrame:SetSize(16, 16)
---------------------------------------------------------------------
local HSFrame = CreateFrame("BUTTON","hsButton", teleportFrame, "SecureActionButtonTemplate")
HSFrame:SetPoint("RIGHT")
HSFrame:SetSize(16, 16)
HSFrame:EnableMouse(true)
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

HSFrame:SetScript("OnEnter", function()
	if InCombatLockdown() then return end
	HSIcon:SetVertexColor(unpack(cfg.color.hover))
	if not cfg.heartstone.showTooltip then return end
	local startTime, duration = GetItemCooldown(6948)
	if startTime ~= 0 then
		local CDremaining = (startTime+duration)-GetTime()
		GameTooltip:SetOwner(teleportFrame, cfg.tooltipPos)
		GameTooltip:AddDoubleLine("Cooldown",SecondsToTime(CDremaining),1,1,0,1,1,1)
		GameTooltip:Show()
	end
	hsOnHover = true
end)

HSFrame:SetScript("OnLeave", function() 
	hsOnHover = false
	if IsUsableItem(6948) and GetItemCooldown(6948) == 0 then
		HSIcon:SetVertexColor(unpack(cfg.color.normal))
	else
		HSIcon:SetVertexColor(unpack(cfg.color.inactive))
	end
end)

-- Change the button action before the click reaches it:
function HSFrame:ChangeAction(action)
     if InCombatLockdown() then return end -- can't change attributes in combat
     self:SetAttribute("macrotext", action)
end

HSFrame:SetScript("PreClick", function(self)
     if InCombatLockdown() then return end -- can't change attributes in combat

     -- Innkeeper's Daughter
     if IsUsableItem(64488) and GetItemCooldown(64488) == 0 then
          local itemName, itemLink, _, _, _, _, _, _, _, itemIcon = GetItemInfo(64488)
          return self:ChangeAction("/use " .. itemName)

     -- Hearthstone
     elseif IsUsableItem(6948) and GetItemCooldown(6948) == 0 then
          local itemName, itemLink, _, _, _, _, _, _, _, itemIcon = GetItemInfo(6948)
          return self:ChangeAction("/use " .. itemName)

     -- Astral Recall
     elseif IsPlayerSpell(556) and GetSpellCooldown(556) == 0 then
          local spellName, _, spellIcon = GetSpellInfo(556)
          return self:ChangeAction("/cast " .. spellName)
     end
end)

local function hsHover()
local startTime, duration = GetItemCooldown(6948)
	if startTime ~= 0 then
		local CDremaining = (startTime+duration)-GetTime()
		GameTooltip:SetOwner(teleportFrame, cfg.tooltipPos)
		GameTooltip:AddDoubleLine("Cooldown",SecondsToTime(CDremaining),1,1,0,1,1,1)
		GameTooltip:Show()
	end
	HSIcon:SetVertexColor(unpack(cfg.color.hover))
end

local function garrHover()
local startTime, duration = GetItemCooldown(110560)
	if startTime ~= 0 then
		local CDremaining = (startTime+duration)-GetTime()
		GameTooltip:SetOwner(teleportFrame, cfg.tooltipPos)
		GameTooltip:AddDoubleLine("Cooldown",SecondsToTime(CDremaining),1,1,0,1,1,1)
		GameTooltip:Show()
	end
	-- garrisonIcon:SetVertexColor(unpack(cfg.color.hover))
end

local function updateTeleportText()
local playerLevel = UnitLevel("player")
	if IsUsableItem(64488) and GetItemCooldown(64488) == 0 
	or IsUsableItem(6948) and GetItemCooldown(6948) == 0 
	-- or IsPlayerSpell(556) and GetSpellCooldown(556) == 0
	then 
		HSIcon:SetVertexColor(unpack(cfg.color.normal))
		HSText:SetTextColor(unpack(cfg.color.normal))
	else
		HSIcon:SetVertexColor(unpack(cfg.color.inactive))
		HSText:SetTextColor(unpack(cfg.color.inactive))
	end
end

local elapsed = 0
teleportFrame:SetScript('OnUpdate', function(self, e)
	elapsed = elapsed + e
	if elapsed >= 1 then
		updateTeleportText()
		if garrOnHover then garrHover() end
		if hsOnHover then hsHover() end
		elapsed = 0
	end
end)

local eventframe = CreateFrame("Frame")
eventframe:RegisterEvent("PLAYER_ENTERING_WORLD")
eventframe:RegisterEvent("BAG_UPDATE")
eventframe:RegisterEvent("HEARTHSTONE_BOUND")
eventframe:RegisterEvent("MODIFIER_STATE_CHANGED")

eventframe:SetScript("OnEvent", function(this, event, arg1, arg2, arg3, arg4, ...)
if InCombatLockdown() then return end 

HSText:SetText(strupper(GetBindLocation()))
HSFrame:SetSize(HSText:GetStringWidth()+16, 16)

teleportFrame:SetSize(HSFrame:GetWidth()+8, 16)
end)