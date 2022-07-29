local addon, ns = ...
local cfg = ns.cfg
local unpack = unpack
--------------------------------------------------------------
if not cfg.armor.show then return end

local armorFrame = CreateFrame("BUTTON",nil, cfg.SXframe)
armorFrame:SetPoint("LEFT",600,0)
armorFrame:EnableMouse(true)
armorFrame:RegisterForClicks("AnyUp")

local armorIcon = armorFrame:CreateTexture(nil,"OVERLAY",nil,7)
armorIcon:SetPoint("LEFT")
armorIcon:SetTexture(cfg.mediaFolder.."datatexts\\repair")
armorIcon:SetVertexColor(unpack(cfg.color.inactive))

local armorText = armorFrame:CreateFontString(nil, "OVERLAY")
armorText:SetFont(cfg.text.font, cfg.text.normalFontSize)
armorText:SetPoint("RIGHT", armorFrame,2,0)
armorText:SetTextColor(unpack(cfg.color.normal))

local function setText(self,event, ...)
	local durMin, durCol

	durMin, durCol = 100, "ffffff"
	for i = 1, 18 do
		local durCur, durMax = GetInventoryItemDurability(i)
		if ( durCur ~= durMax ) then durMin = min(durMin, durCur*(100/durMax)) end
	end

	armorText:SetText(floor(durMin).."%")
	
	if durMin >= cfg.armor.maxArmor then 
		armorIcon:SetVertexColor(unpack(cfg.color.inactive)) 
		armorText:SetTextColor(unpack(cfg.color.normal)) 
	elseif durMin >= cfg.armor.minArmor then 
		armorIcon:SetVertexColor(unpack(cfg.color.normal)) 
		armorText:SetTextColor(unpack(cfg.color.normal)) 
	else 
		armorIcon:SetVertexColor(unpack(cfg.color.red)) 
		armorText:SetTextColor(unpack(cfg.color.red)) 
	end
	armorFrame:SetSize(armorText:GetStringWidth()+18, 16)
end

armorFrame:SetScript("OnEnter", function()
	if InCombatLockdown() then return end
	armorIcon:SetVertexColor(unpack(cfg.color.hover))
end)

armorFrame:SetScript("OnLeave", function()
	local durMin = 100
		for i = 1, 18 do
			local durCur, durMax = GetInventoryItemDurability(i)
			if ( durCur ~= durMax ) then durMin = min(durMin, durCur*(100/durMax)) end
		end
	if durMin >= cfg.armor.minArmor then 
		armorIcon:SetVertexColor(unpack(cfg.color.inactive))  
	else
		armorIcon:SetVertexColor(unpack(cfg.color.normal)) 
	end
	setText()
end)

armorFrame:SetScript("OnClick", function(self, button, down)
	if InCombatLockdown() then return end
	if button == "LeftButton" then 
		
	end
end)

local eventframe = CreateFrame("Frame")
eventframe:RegisterEvent("PLAYER_ENTERING_WORLD")
eventframe:RegisterEvent("UPDATE_INVENTORY_DURABILITY")

eventframe:SetScript("OnEvent", setText)