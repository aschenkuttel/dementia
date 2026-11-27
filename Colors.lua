local _, ns = ...

local COLORS = {}
ns.COLORS = COLORS

COLORS.MAP_COLORS = {
    { name = "Default", hex = "FFFFFFFF" },
    { name = "Red", hex = "FFFF2020" },
    { name = "Legendary Orange", hex = "FFFF8000" },
    { name = "Quest Gold", hex = "FFFFD100" },
    { name = "Uncommon Green", hex = "FF1EFF00" },
    { name = "Teal", hex = "FF00CC99" },
    { name = "Silver", hex = "FFC0C0C0" },
    { name = "Rare Blue", hex = "FF0070DD" },
    { name = "Epic Purple", hex = "FFA335EE" },
    { name = "Paladin Pink", hex = "FFF48CBA" },
}

function COLORS.GetOptions(list)
    local container = Settings.CreateControlTextContainer()

    for _, color in ipairs(list) do
        container:Add(color.hex, color.name)
    end

    return container:GetData()
end