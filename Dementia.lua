local ADDON_NAME = "Dementia"

local FIND_MINING_SPELL_ID = 2580
local RESTING_SPELL_ID = 1331671
local WELL_RESTED_SPELL_ID = 429959
local FED_SPELL_ID = 1249519
local EATING_SPELL_ID = 435
local FOOD_NAME = C_Spell.GetSpellName(EATING_SPELL_ID)

local YAWNS = {
    7946,
    7945,
    7942,
    7931,
    7932,
    7933,
    7934,
}

local SIGHS = {
    7914, -- human male sigh
    7894, -- human female sigh
    7915, -- nightelf female sigh
    7916, -- nightelf male sigh
    7925, -- tauren female sigh
    7926 -- tauren male sigh
}

local BASE_LOOP_INTERVAL = 2
local DEBOUNCE_TICKS = 2
local GRACE_PERIOD = 20
local DEFAULT_REMINDER_INTERVAL = 60
local WELL_RESTED_MAX_STACKS = 3
local WELL_RESTED_EXPIRY_WARNING_SECONDS = 600

local busyUntil = 0
local lastBlockedAt = 0

local function PlayCue(sound, msg, length)
    local now = GetTime()
    if now < busyUntil then
        return false -- next tick retries, since the timestamp wasn't updated
    end
    busyUntil = now + length + 3

    RaidNotice_AddMessage(RaidWarningFrame, msg, ChatTypeInfo.RAID_WARNING, 5)

    PlaySound(sound, "Master")
    return true
end

local sleepingBagReminder = {
    pendingTicks = 0,
    lastAt = 0,
    isNeeded = function()
        local wellRestedAura = C_UnitAuras.GetPlayerAuraBySpellID(WELL_RESTED_SPELL_ID)
        local hasMaxStacks = wellRestedAura and wellRestedAura.applications >= WELL_RESTED_MAX_STACKS
        local isExpiringSoon = wellRestedAura
                and wellRestedAura.expirationTime > 0
                and (wellRestedAura.expirationTime - GetTime()) < WELL_RESTED_EXPIRY_WARNING_SECONDS
        local sleepingAura = C_UnitAuras.GetPlayerAuraBySpellID(RESTING_SPELL_ID)

        local needsBuff = not hasMaxStacks or isExpiringSoon -- missing, under 3 stacks, or running out

        return DementiaDB.enableSleepingBagReminder -- setting on
                and needsBuff
                and not sleepingAura                    -- not laying in the sleeping bag
                and not IsResting()                     -- not in a city or inn
        , isExpiringSoon and hasMaxStacks
    end,
    play = function(isExpiringSoon)
        local randomIndex = math.random(1, #YAWNS)
        local randomYawnID = YAWNS[randomIndex]

        local msg = isExpiringSoon and "you're getting tired..." or "you're tired..."
        return PlayCue(randomYawnID, msg, 2)
    end,
}

local buffFoodReminder = {
    pendingTicks = 0,
    lastAt = 0,
    isNeeded = function()
        local fedAura = C_UnitAuras.GetPlayerAuraBySpellID(FED_SPELL_ID)
        local eatingAura = C_UnitAuras.GetAuraDataBySpellName("player", FOOD_NAME, "HELPFUL")

        return DementiaDB.enableBuffFoodReminder       -- setting on
                and not fedAura                                     -- buff missing
                and not eatingAura                                  -- bro is eating
                and not IsResting()                                 -- not in a city or inn
    end,
    play = function()
        local randomIndex = math.random(1, #SIGHS)
        local randomSighID = SIGHS[randomIndex]
        return PlayCue(randomSighID, "you're hungry...", 3)
    end
}

local REMINDERS = { sleepingBagReminder, buffFoodReminder }

local function findMiningTracking()
    local numTrackingTypes = C_Minimap.GetNumTrackingTypes()

    for i = 1, numTrackingTypes do
        local info = C_Minimap.GetTrackingInfo(i)

        if info.spellID == FIND_MINING_SPELL_ID then
            return i, info
        end
    end
end

-- settings

local settings = CreateFrame("Frame")

settings:RegisterEvent("ADDON_LOADED")

settings:SetScript("OnEvent", function(_, _, addonName)
    if addonName ~= ADDON_NAME then
        return
    end

    DementiaDB = DementiaDB or {}
    if DementiaDB.enableMiningTracking == nil then
        DementiaDB.enableMiningTracking = false
    end

    if DementiaDB.reminderInterval == nil then
        DementiaDB.reminderInterval = DEFAULT_REMINDER_INTERVAL
    end

    local category = Settings.RegisterVerticalLayoutCategory(ADDON_NAME)

    do
        local name = "Tracking Minerals"
        local variable = "DementiaEnableMiningTracking"
        local variableKey = "enableMiningTracking"
        local variableTbl = DementiaDB
        local defaultValue = false

        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue), name, defaultValue)

        setting:SetValueChangedCallback(function(_, value)
            local index, info = findMiningTracking()
            if not info or not value then
                return
            end

            C_Minimap.SetTracking(index, value)
        end)

        local tooltip = "Enables Tracking Minerals after the Character is revived"
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    do
        local name = "Sleeping Bag Reminder"
        local variable = "DementiaEnableSleepingBagReminder"
        local variableKey = "enableSleepingBagReminder"
        local variableTbl = DementiaDB
        local defaultValue = false

        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue), name, defaultValue)

        local tooltip = "Plays a reminding sound when the character is missing the buff"
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    do
        local name = "Buff Food Reminder"
        local variable = "DementiaEnableBuffFoodReminder"
        local variableKey = "enableBuffFoodReminder"
        local variableTbl = DementiaDB
        local defaultValue = false

        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue), name, defaultValue)

        local tooltip = "Plays a reminding sound when the character is missing the buff"
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    do
        local name = "Reminder Interval"
        local variable = "DementiaReminderInterval"
        local variableKey = "reminderInterval"
        local variableTbl = DementiaDB
        local defaultValue = DEFAULT_REMINDER_INTERVAL
        local minValue = 30
        local maxValue = 600
        local step = 10

        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue), name, defaultValue)

        local tooltip = "The duration in seconds between the reminders"
        local options = Settings.CreateSliderOptions(minValue, maxValue, step)
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right);
        Settings.CreateSlider(category, setting, options, tooltip)
    end

    Settings.RegisterAddOnCategory(category)

    -- features

    do
        local frame = CreateFrame("Frame")

        frame:RegisterEvent("PLAYER_ALIVE")
        frame:RegisterEvent("PLAYER_UNGHOST")
        frame:RegisterEvent("PLAYER_LOGIN")

        frame:SetScript("OnEvent", function()
            local index, info = findMiningTracking()
            if not info then
                return
            end

            if info.enabled or not DementiaDB.enableMiningTracking then
                return
            end

            C_Minimap.SetTracking(index, true)
        end)
    end

    lastBlockedAt = GetTime() -- grace period after start as well

    C_Timer.NewTicker(BASE_LOOP_INTERVAL, function()
        if UnitOnTaxi("player") or UnitIsAFK("player") then
            return
        end

        if InCombatLockdown() or UnitIsDeadOrGhost("player") then
            lastBlockedAt = GetTime()
            for _, reminder in ipairs(REMINDERS) do
                reminder.pendingTicks = 0
            end
            return
        end

        if (GetTime() - lastBlockedAt) < GRACE_PERIOD then
            return
        end

        local playedThisTick = false

        for _, reminder in ipairs(REMINDERS) do
            local isNeeded, reason = reminder.isNeeded()

            if not isNeeded then
                reminder.pendingTicks = 0
            else
                reminder.pendingTicks = reminder.pendingTicks + 1

                local isDebounced = reminder.pendingTicks >= DEBOUNCE_TICKS
                local isIntervalOver = GetTime() - reminder.lastAt >= DementiaDB.reminderInterval

                if isDebounced and isIntervalOver and not playedThisTick then
                    local hasPlayed = reminder.play(reason)
                    if hasPlayed then
                        reminder.lastAt = GetTime()
                        playedThisTick = true
                    end
                end
            end
        end
    end)
end)