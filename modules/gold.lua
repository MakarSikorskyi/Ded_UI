local addon, ns = ...
local cfg = ns.cfg
local unpack = unpack
--------------------------------------------------------------
if not cfg.gold.show then return end

local onHover = false

local function GroupDigits(num)
	if not num then return 0 end
	if abs(num) < 1000 then return num end

	local neg = num < 0 and "-" or ""
	local left, mid, right = tostring(abs(num)):match("^([^%d]*%d)(%d*)(.-)$")
	return ("%s%s%s%s"):format(neg, left, mid:reverse():gsub("(%d%d%d)", "%1,"):reverse(), right)
end

local function goldConverter(money)
	local g, s, c = abs(money/10000), abs(mod(money/100, 100)), abs(mod(money, 100))
	local cash
	if ( g < 1 ) then g = "" else g = string.format("|cffffffff%s|cffffd700g|r ", GroupDigits(floor(g))) end
	cash = string.format("%s", g)
	if money == 0 then cash = "|cffffffff0" end
	return cash
end

local playerName, playerFaction, playerRealm = UnitName("player"), UnitFactionGroup("player"), GetRealmName()

local positiveSign = "|cff00ff00+ "
local negativeSign = "|cffff0000- "

local goldFrame = CreateFrame("BUTTON",nil, cfg.SXframe)
goldFrame:SetPoint("RIGHT",-230,0)
goldFrame:SetSize(16, 16)
goldFrame:EnableMouse(true)
goldFrame:RegisterForClicks("AnyUp")

 local function goldFrameOnEnter()
	if not cfg.gold.showTooltip then return end
	if not onHover then return end
	GameTooltip:SetOwner(goldFrame, cfg.tooltipPos)
	GameTooltip:AddLine(cfg.TooltipTitleText("Голда"))
	GameTooltip:AddLine(" ")
	---------------------------------------------------

	local gold = GetMoney()
	local logDate = ns.playerData.lastLoginDate
	
	local sessionGold = ns.playerData["money_on_session_start"]
	local sessionGoldIcon = ""
	sessionGold = sessionGold - gold

	if sessionGold < 0 then 
		sessionGoldIcon = positiveSign
	elseif sessionGold > 0 then
		sessionGoldIcon = negativeSign
	else
	end
	
	local dayGold = ns.playerData["money_on_first_login_today"]
	local dayGoldIcon = ""
	dayGold = dayGold - gold

	if dayGold < 0 then 
		dayGoldIcon = positiveSign
	elseif dayGold > 0 then
		dayGoldIcon = negativeSign
	else
	end
	
	
	local weekGold = ns.playerData["money_on_first_weekday"]
	local weekGoldIcon = ""
	weekGold = weekGold - gold

	if weekGold < 0 then 
		weekGoldIcon = positiveSign
	elseif weekGold > 0 then
		weekGoldIcon = negativeSign
	else
	end

	
	local totalGold = 0
	for key, val in pairs(ns.realmData) do
		for k, v in pairs(val) do
			if k == "money_on_log_out" then
				totalGold = totalGold + v
			end
		end
	end
	
	local realmDailyGold = 0
	for key, val in pairs(ns.realmData) do
		for k, v in pairs(val) do
			if k == "money_on_first_login_today" then
				realmDailyGold = realmDailyGold + v
			end
		end
	end
	
	local realmDayGoldIcon = ""
	realmDailyGold = realmDailyGold - totalGold

	if realmDailyGold < 0 then 
		realmDayGoldIcon = positiveSign
	elseif realmDailyGold > 0 then
		realmDayGoldIcon = negativeSign
	else
	end
	
	
	local realmWeeklyGold = 0
	for key, val in pairs(ns.realmData) do
		for k, v in pairs(val) do
			if k == "money_on_first_weekday" then
				realmWeeklyGold = realmWeeklyGold + v
			end
		end
	end

	local realmWeekGoldIcon = ""
	realmWeeklyGold = realmWeeklyGold - totalGold
	
	if realmWeeklyGold < 0 then 
		realmWeekGoldIcon = positiveSign
	elseif realmWeeklyGold > 0 then
		realmWeekGoldIcon = negativeSign
	else
	end

	for key, val in pairs(ns.realmData) do
		local classColor = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[val["CLASS"]]
		if val["money_on_log_out"] then 
			GameTooltip:AddDoubleLine( cfg.hex(classColor.r, classColor.g, classColor.b)..key,format(goldConverter(val["money_on_log_out"])))
		end
	end
	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine("Баланс за сеанс",sessionGoldIcon..format(goldConverter(sessionGold)),1,1,1)
	-- GameTooltip:AddDoubleLine("Баланс за день",dayGoldIcon..format(goldConverter(dayGold)),1,1,1)
	GameTooltip:AddDoubleLine("Баланс за неделю",weekGoldIcon..format(goldConverter(weekGold)),1,1,1)
	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine("Всего голды","|cffffffff"..format(goldConverter(totalGold)),1,1,1)
	GameTooltip:Show()
 end

local goldIcon = goldFrame:CreateTexture(nil,"OVERLAY",nil,7)
goldIcon:SetPoint("LEFT")
goldIcon:SetTexture(cfg.mediaFolder.."datatexts\\gold")
goldIcon:SetVertexColor(unpack(cfg.color.normal))

local goldText = goldFrame:CreateFontString(nil, "OVERLAY")
goldText:SetFont(cfg.text.font, cfg.text.normalFontSize)
goldText:SetPoint("RIGHT", goldFrame,2,0)
goldText:SetTextColor(unpack(cfg.color.normal))

goldFrame:SetScript("OnEnter", function()
	if InCombatLockdown() then return end
	goldIcon:SetVertexColor(unpack(cfg.color.hover))
	onHover = true
	goldFrameOnEnter()
end)

goldFrame:SetScript("OnLeave", function() if ( GameTooltip:IsShown() ) then GameTooltip:Hide() onHover = false end goldIcon:SetVertexColor(unpack(cfg.color.normal)) end)

goldFrame:SetScript("OnClick", function(self, button, down)
	if InCombatLockdown() then return end
	if button == "LeftButton" then
		OpenAllBags()
	elseif button == "RightButton" then 
		CloseAllBags()
	end
end)

local eventframe = CreateFrame("Frame")
eventframe:RegisterEvent("PLAYER_ENTERING_WORLD")
eventframe:RegisterEvent("PLAYER_MONEY")
eventframe:RegisterEvent("SEND_MAIL_MONEY_CHANGED")
eventframe:RegisterEvent("SEND_MAIL_COD_CHANGED")
eventframe:RegisterEvent("PLAYER_TRADE_MONEY")
eventframe:RegisterEvent("TRADE_MONEY_CHANGED")
eventframe:RegisterEvent("TRADE_CLOSED")
eventframe:RegisterEvent("MODIFIER_STATE_CHANGED")

eventframe:SetScript("OnEvent", function(this, event, arg1, arg2, arg3, arg4, ...)

goldFrameOnEnter()
if event == "MODIFIER_STATE_CHANGED" then
		if InCombatLockdown() then return end
		if arg1 == "LSHIFT" or arg1 == "RSHIFT" then
			if arg2 == 1 then
				goldFrameOnEnter()
			elseif arg2 == 0 then
				goldFrameOnEnter()
			end
		end
	end

	
	local gold = GetMoney()
	
	ns.playerData["money_on_log_out"] = gold
	
	local g, s, c = abs(gold/10000), abs(mod(gold/100, 100)), abs(mod(gold, 100))
	
	if g > 1 then 
		goldText:SetText(GroupDigits(floor(g)).."g")
	elseif s > 1 then 
		goldText:SetText(floor(s).."s")
	else 
		goldText:SetText(floor(c).."c")
	end
	if gold == 0 then goldText:SetText("0") end

	
	goldFrame:SetSize(goldText:GetStringWidth()+18, 16)
end)