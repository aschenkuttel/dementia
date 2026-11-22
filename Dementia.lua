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
    540729,
    540524,
    540952,
    540865,
    1304917,
    1316213
}

local FADE_MS = 500

local DEFAULT_REMINDER_INTERVAL = 60

local WELL_RESTED_MAX_STACKS = 3

local sleepingBagTimer
local buffFoodTimer
local busyUntil = 0
local quietUntil = GetTime() + 10

local function PlayCue(sound, msg, length, cut, isKit)
    if InCombatLockdown() or UnitOnTaxi("player") or UnitIsAFK("player") or GetTime() < quietUntil then
        return
    end

    local now = GetTime()
    if now < busyUntil then
        C_Timer.After(busyUntil - now, function()
            PlayCue(sound, msg, length, cut, isKit)
        end)
        return
    end
    busyUntil = now + (cut or length) + 1

    RaidNotice_AddMessage(RaidWarningFrame, msg, ChatTypeInfo.RAID_WARNING, 5)

    local ok, handle
    if isKit then
        ok, handle = PlaySound(sound, "Master")
    else
        ok, handle = PlaySoundFile(sound, "Master")
    end
    if ok and cut then
        C_Timer.After(cut, function()
            StopSound(handle, FADE_MS)
        end)
    end
end

local function findMiningTracking()
    local numTrackingTypes = C_Minimap.GetNumTrackingTypes()

    for i = 1, numTrackingTypes do
        local info = C_Minimap.GetTrackingInfo(i)

        if info.spellID == FIND_MINING_SPELL_ID then
            return i, info
        end
    end
end

local function wellRestedCallback()
    local randomIndex = math.random(1, #YAWNS)
    local randomYawnID = YAWNS[randomIndex]
    PlayCue(randomYawnID, "you're tired...", 2, nil, true)
end

local function scheduleWellRested()
    wellRestedCallback()
    sleepingBagTimer = C_Timer.NewTimer(DementiaDB.reminderInterval, scheduleWellRested)
end

local function updateWellRested()
    local wellRestedAura = C_UnitAuras.GetPlayerAuraBySpellID(WELL_RESTED_SPELL_ID)
    local hasMaxStacks = wellRestedAura and wellRestedAura.applications >= WELL_RESTED_MAX_STACKS
    local sleepingAura = C_UnitAuras.GetPlayerAuraBySpellID(RESTING_SPELL_ID)

    local shouldAlert = DementiaDB.enableSleepingBagReminder    -- setting on
            and not hasMaxStacks                    -- buff missing or under 3 stacks
            and not sleepingAura                    -- not laying in the sleepingBag
            and not IsResting()                     -- not in a city or inn
            and not UnitIsDeadOrGhost("player")     -- alive

    if shouldAlert and not sleepingBagTimer then
        scheduleWellRested()
    elseif not shouldAlert and sleepingBagTimer then
        sleepingBagTimer:Cancel()
        sleepingBagTimer = nil
    end
end

local function fedCallback()
    local randomIndex = math.random(1, #SIGHS)
    local randomSighID = SIGHS[randomIndex]
    PlayCue(randomSighID, "you're hungry...", 3)
end

local function scheduleFed()
    fedCallback()
    buffFoodTimer = C_Timer.NewTimer(DementiaDB.reminderInterval, scheduleFed)
end

local function updateFed()
    local fedAura = C_UnitAuras.GetPlayerAuraBySpellID(FED_SPELL_ID)
    local eatingAura = C_UnitAuras.GetAuraDataBySpellName("player", FOOD_NAME, "HELPFUL")

    local shouldAlert = DementiaDB.enableBuffFoodReminder       -- setting on
            and not fedAura                                     -- buff missing
            and not eatingAura                                  -- bro is eating
            and not IsResting()                                 -- not in a city or inn
            and not UnitIsDeadOrGhost("player")                 -- alive

    if shouldAlert and not buffFoodTimer then
        scheduleFed()
    elseif not shouldAlert and buffFoodTimer then
        buffFoodTimer:Cancel()
        buffFoodTimer = nil
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

        setting:SetValueChangedCallback(updateWellRested)

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

        setting:SetValueChangedCallback(updateFed)

        local tooltip = "Plays a reminding sound when the character is missing the buff"
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    do
        local name = "Reminder Interval"
        local variable = "DementiaReminderInterval"
        local variableKey = "reminderInterval"
        local variableTbl = DementiaDB
        local defaultValue = DEFAULT_REMINDER_INTERVAL
        local minValue = 10
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

    do
        local frame = CreateFrame("Frame")

        frame:RegisterUnitEvent("UNIT_AURA", "player")
        frame:RegisterEvent("PLAYER_ENTERING_WORLD")
        frame:RegisterEvent("PLAYER_UPDATE_RESTING")
        frame:RegisterEvent("PLAYER_DEAD")
        frame:RegisterEvent("PLAYER_ALIVE")
        frame:RegisterEvent("PLAYER_UNGHOST")

        frame:SetScript("OnEvent", function()
            updateWellRested()
            updateFed()
        end)
    end
end)