local ADDON_NAME = "Dementia"
local FIND_MINING_SPELL_ID = 2580

local RESTING_SPELL_ID = 1331671
local WELL_RESTED_SPELL_ID = 429959

local sleepingBagTimer
local buffFoodTimer

local function findMiningTracking()
    local numTrackingTypes = C_Minimap.GetNumTrackingTypes()

    for i = 1, numTrackingTypes do
        local info = C_Minimap.GetTrackingInfo(i)

        if info.spellID == FIND_MINING_SPELL_ID then return i, info end
    end
end

-- settings

local settings = CreateFrame("Frame")

settings:RegisterEvent("ADDON_LOADED")

settings:SetScript("OnEvent", function(_, _, addonName)
    if addonName ~= ADDON_NAME then return end

    DementiaDB = DementiaDB or {}
    if DementiaDB.enableMiningTracking == nil then DementiaDB.enableMiningTracking = false end

    local category =  Settings.RegisterVerticalLayoutCategory(ADDON_NAME)

    do
    	local name = "Tracking Minerals"
    	local variable = "DementiaEnableMiningTracking"
    	local variableKey = "enableMiningTracking"
    	local variableTbl = DementiaDB
    	local defaultValue = false

    	local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue), name, defaultValue)

        setting:SetValueChangedCallback(function(_, value)
            local index, info = findMiningTracking()
            if not info or not value then return end

            C_Minimap.SetTracking(index, value)
        end)
        
    	local tooltip = "Enables Tracking Minerals after the Character is revived"
    	Settings.CreateCheckbox(category, setting, tooltip)
    end

    do
    	local name = "Sleeping Bag Buff"
    	local variable = "DementiaEnableSleepingBagReminder"
    	local variableKey = "enableSleepingBagReminder"
    	local variableTbl = DementiaDB
    	local defaultValue = false

    	local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue), name, defaultValue)

        setting:SetValueChangedCallback(function(_, value)

        end)

    	local tooltip = "Plays a reminding sound when the character is missing the buff"
    	Settings.CreateCheckbox(category, setting, tooltip)
    end

    Settings.RegisterAddOnCategory(category)
end)

-- features

do
    local frame = CreateFrame("Frame")

    frame:RegisterEvent("PLAYER_ALIVE")
    frame:RegisterEvent("PLAYER_UNGHOST")
    frame:RegisterEvent("PLAYER_LOGIN")

    frame:SetScript("OnEvent", function()
        local index, info = findMiningTracking()
        if not info then return end

        if info.enabled or not DementiaDB.enableMiningTracking then return end

        C_Minimap.SetTracking(index, true)
        print("|cff00ff00Mining tracking enabled!|r")
    end)
end

do
    local frame = CreateFrame("Frame")

    frame:RegisterUnitEvent("UNIT_AURA", "player")

    frame:SetScript("OnEvent", function(self, event, unitTarget, updateInfo)
        if not C_UnitAuras.GetPlayerAuraBySpellID(WELL_RESTED_SPELL_ID) then
           print("user has no buff currently")
        end
    end)
end