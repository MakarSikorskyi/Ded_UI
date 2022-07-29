local addon, ns = ...
local cfg = ns.cfg
local unpack = unpack
--------------------------------------------------------------
if not cfg.clock.show then return end

local hour, minu = 0,0
local AmPmTimeText = ""

--=========================--
--Lua functions
local _G = _G
local date = date
local next = next
local select = select
local time = time
local tonumber = tonumber
local find, format, gsub, join = string.find, string.format, string.gsub, string.join
local tinsert, wipe = table.insert, table.wipe
--WoW API / Variables
local GetGameTime = GetGameTime
local GetNumSavedInstances = GetNumSavedInstances
local GetSavedInstanceInfo = GetSavedInstanceInfo
local GetWintergraspWaitTime = GetWintergraspWaitTime
local IsInInstance = IsInInstance
local RequestRaidInfo = RequestRaidInfo
local SecondsToTime = SecondsToTime

local QUEUE_TIME_UNAVAILABLE = QUEUE_TIME_UNAVAILABLE
local TIMEMANAGER_AM = TIMEMANAGER_AM
local TIMEMANAGER_PM = TIMEMANAGER_PM
local TIMEMANAGER_TOOLTIP_LOCALTIME = TIMEMANAGER_TOOLTIP_LOCALTIME
local TIMEMANAGER_TOOLTIP_REALMTIME = TIMEMANAGER_TOOLTIP_REALMTIME
local WINTERGRASP_IN_PROGRESS = WINTERGRASP_IN_PROGRESS


local timeDisplayFormat = ""
local dateDisplayFormat = ""
local lockoutInfoFormat = "%s%s %s |cffaaaaaa(%s)"
local lockoutColorExtended, lockoutColorNormal = {r = 0.3, g = 1, b = 0.3}, {r = .8, g = .8, b = .8}
local lockedInstances = {raids = {}, dungeons = {}}
local timeFormat, showAMPM, showSecs
local enteredFrame, fullUpdate
local instanceIconByName
local numSavedInstances = 0

local locale = GetLocale()
local difficultyTag = { -- Normal, Normal, Heroic, Heroic
	PLAYER_DIFFICULTY1, -- N
	PLAYER_DIFFICULTY1, -- N
	PLAYER_DIFFICULTY2, -- H
	PLAYER_DIFFICULTY2, -- H
}

local function GetInstanceImages(...)
	local numTextures = select("#", ...) / 4

	local argn, title, texture = 1
	for i = 1, numTextures do
		title, texture = select(argn, ...)
		if texture ~= "" then
			instanceIconByName[title] = texture
		end
		argn = argn + 4
	end
end

local function OnEvent(self, event)
	if event == "UPDATE_INSTANCE_INFO" then
		local num = GetNumSavedInstances()

		if num ~= numSavedInstances then
			numSavedInstances = num or 0

			if enteredFrame then
				fullUpdate = true
			end
		end

		return
	end
end

--=========================--

local clockFrame = CreateFrame("BUTTON",nil, cfg.SXframe)
clockFrame:SetSize(32, 32)
clockFrame:SetPoint("CENTER")
clockFrame:EnableMouse(true)
clockFrame:RegisterForClicks("AnyUp")

local clockText = clockFrame:CreateFontString(nil, "OVERLAY")
clockText:SetFont(cfg.text.font, cfg.SXframe:GetHeight()-10)
clockText:SetPoint("CENTER", clockFrame, "TOP", 0, -11)
clockText:SetTextColor(unpack(cfg.color.normal))

local amText = clockFrame:CreateFontString(nil, "OVERLAY")
amText:SetFont(cfg.text.font, cfg.text.normalFontSize)
amText:SetPoint("RIGHT")
amText:SetTextColor(unpack(cfg.color.inactive))

local calendarText = clockFrame:CreateFontString(nil, "OVERLAY")
calendarText:SetFont(cfg.text.font, cfg.text.smallFontSize)
calendarText:SetPoint("CENTER", clockFrame, "BOTTOM", 0, 6)
if cfg.core.position ~= "BOTTOM" then
	calendarText:SetPoint("CENTER", clockFrame, "TOP")
end
calendarText:SetTextColor(unpack(cfg.color.main))

local elapsed = 0
clockFrame:SetScript('OnUpdate', function(self, e)
	elapsed = elapsed + e
	if elapsed >= 1 then
		hour, minu = GetGameTime()
		if minu < 10 then minu = ("0"..minu) end
		if ( GetCVarBool("timeMgrUseLocalTime") ) then
			if ( GetCVarBool("timeMgrUseMilitaryTime") ) then
				clockText:SetText(date("%H:%M"))
				amText:SetText("")	
			else
				clockText:SetText(date("%I:%M"))
				amText:SetText(date("%p"))		
			end			
		else
			if ( GetCVarBool("timeMgrUseMilitaryTime") ) then
				clockText:SetText(hour..":"..minu)
				amText:SetText("")	
			else
				if hour > 12 then 
					hour = hour - 12
					hour = ("0"..hour)
					AmPmTimeText = "PM"
				else 
					AmPmTimeText = "AM"
				end
				clockText:SetText(hour..":"..minu)
				amText:SetText(AmPmTimeText)		
			end			

		end
		if (CalendarGetNumPendingInvites() > 0) then
			calendarText:SetText(string.format("%s  (|cffffff00%i|r)", "New Event!", (CalendarGetNumPendingInvites())))
		else
			calendarText:SetText(date("%d/%m/%Y"))
		end
		clockFrame:SetWidth(clockText:GetStringWidth() + amText:GetStringWidth())
		clockFrame:SetPoint("CENTER", cfg.SXframe)
		elapsed = 0
	end
end)

--[[

--]]

clockFrame:SetScript("OnEnter", function()
	if InCombatLockdown() then return end
	-- clockText:SetTextColor(unpack(cfg.color.hover))
	if cfg.clock.showTooltip then
	hour, minu = GetGameTime()
	if minu < 10 then minu = ("0"..minu) end

	GameTooltip:SetOwner(clockFrame, cfg.tooltipPos)

	if not instanceIconByName then
		instanceIconByName = {}
		GetInstanceImages(CalendarEventGetTextures(1))
		GetInstanceImages(CalendarEventGetTextures(2))
	end

	local wgtime = GetWintergraspWaitTime()
	local _, instanceType = IsInInstance()
	if instanceType ~= "none" then
		wgtime = QUEUE_TIME_UNAVAILABLE
	elseif wgtime == nil then
		wgtime = WINTERGRASP_IN_PROGRESS
	else
		wgtime = SecondsToTime(wgtime, false, nil, 3)
	end

	GameTooltip:AddDoubleLine("Озеро Ледяных Оков", wgtime, 1, 1, 1, lockoutColorNormal.r, lockoutColorNormal.g, lockoutColorNormal.b)

	if numSavedInstances > 0 then
		wipe(lockedInstances.raids)
		wipe(lockedInstances.dungeons)

		local name, reset, difficulty, locked, extended, isRaid, maxPlayers, difficultyLetter, buttonImg

		for i = 1, numSavedInstances do
			name, _, reset, difficulty, locked, extended, _, isRaid, maxPlayers = GetSavedInstanceInfo(i)

			if name and (locked or extended) then
				difficultyLetter = difficultyTag[not isRaid and (difficulty == 2 and 3 or 1) or difficulty]
				buttonImg = format("|T%s%s:22:22:0:0:96:96:0:64:0:64|t ", "Interface\\LFGFrame\\LFGIcon-", instanceIconByName[name] or "Raid")

				if isRaid then
					tinsert(lockedInstances.raids, {name, reset, extended, maxPlayers, difficultyLetter, buttonImg})
				elseif difficulty == 2 then
					tinsert(lockedInstances.dungeons, {name, reset, extended, maxPlayers, difficultyLetter, buttonImg})
				end
			end
		end

		local lockoutColor, info

		if next(lockedInstances.raids) then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine("Рейды")

			for i = 1, #lockedInstances.raids do
				info = lockedInstances.raids[i]

				lockoutColor = info[3] and lockoutColorExtended or lockoutColorNormal

				GameTooltip:AddDoubleLine(
					format(lockoutInfoFormat, info[6], info[4], info[5], info[1]),
					SecondsToTime(info[2], false, nil, 3),
					1, 1, 1,
					lockoutColor.r, lockoutColor.g, lockoutColor.b
				)
			end
		end

		if next(lockedInstances.dungeons) then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine("Подземелья")

			for i = 1, #lockedInstances.dungeons do
				info = lockedInstances.dungeons[i]

				lockoutColor = info[3] and lockoutColorExtended or lockoutColorNormal

				GameTooltip:AddDoubleLine(
					format(lockoutInfoFormat, info[6], info[4], info[5], info[1]),
					SecondsToTime(info[2], false, nil, 3),
					1, 1, 1,
					lockoutColor.r, lockoutColor.g, lockoutColor.b
				)
			end
		end
	end

	GameTooltip:AddLine(" ")
	if ( GetCVarBool("timeMgrUseLocalTime") ) then
		GameTooltip:AddDoubleLine("Серверное время", hour..":"..minu, 1, 1, 1, 1, 1, 1)
	else
		GameTooltip:AddDoubleLine("Местное время", date("%H:%M"), 1, 1, 1, 1, 1, 1)
	end
	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine("<ЛКМ>", "Открыть календарь", 1, 1, 1, 1, 1, 0)
	GameTooltip:AddDoubleLine("<ПКМ>", "Открыть часы", 1, 1, 1, 1, 1, 0)
	GameTooltip:Show()
	end	
end)

clockFrame:SetScript("OnLeave", function() if ( GameTooltip:IsShown() ) then GameTooltip:Hide() end clockText:SetTextColor(unpack(cfg.color.normal)) end)

clockFrame:SetScript("OnClick", function(self, button, down)
	if InCombatLockdown() then return end
	if button == "LeftButton" then
		ToggleCalendar()
	elseif button == "RightButton" then 
		ToggleTimeManager()
	end
end)

local eventframe = CreateFrame("Frame")
eventframe:RegisterEvent("UPDATE_INSTANCE_INFO")
eventframe:SetScript("OnEvent", function(self,event, ...)
	local num = GetNumSavedInstances()

	if num ~= numSavedInstances then
		numSavedInstances = num or 0

		if enteredFrame then
			fullUpdate = true
		end
	end

	return
end)