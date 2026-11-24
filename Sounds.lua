-- Character emote voice lines for all WoW Forever races.
-- No Skyborne male yawn exists in the game files.

local _, ns = ...

local SOUNDS = {}
ns.SOUNDS = SOUNDS

SOUNDS.SIGH = {
    { id = 540729,  name = "Human Male" },
    { id = 540524,  name = "Human Female" },
    { id = 539873,  name = "Dwarf Male" },
    { id = 539794,  name = "Dwarf Female" },
    { id = 540952,  name = "Night Elf Male" },
    { id = 540865,  name = "Night Elf Female" },
    { id = 540277,  name = "Gnome Male" },
    { id = 540266,  name = "Gnome Female" },
    { id = 8062305, name = "Skyborne Male" },
    { id = 8036503, name = "Skyborne Female" },
    { id = 541236,  name = "Orc Male" },
    { id = 541151,  name = "Orc Female" },
    { id = 542610,  name = "Undead Male" },
    { id = 542524,  name = "Undead Female" },
    { id = 542900,  name = "Tauren Male" },
    { id = 542813,  name = "Tauren Female" },
    { id = 543088,  name = "Troll Male" },
    { id = 543089,  name = "Troll Female" },

    -- not playable in Forever, but the files exist
    { id = 539170,  name = "Blood Elf Male" },
    { id = 539187,  name = "Blood Elf Female" },
    { id = 539495,  name = "Draenei Male" },
    { id = 539682,  name = "Draenei Female" },
    { id = 641340,  name = "Pandaren Male" },
    { id = 644726,  name = "Pandaren Female" },
    { id = 6021066, name = "Earthen Male" },
    { id = 6021051, name = "Earthen Female" },
    { id = 4738599, name = "Dracthyr Male" },
    { id = 4739527, name = "Dracthyr Female" },
    { id = 4737559, name = "Dracthyr Male (Visage)" },
    { id = 4741005, name = "Dracthyr Female (Visage)" },
    { id = 1304917, name = "Night Elf Male (Demon Hunter)" },
    { id = 1316213, name = "Night Elf Female (Demon Hunter)" },
}

SOUNDS.YAWN = {
    { id = 540740,  name = "Human Male" },
    { id = 540531,  name = "Human Female" },
    { id = 539879,  name = "Dwarf Male" },
    { id = 539801,  name = "Dwarf Female" },
    { id = 540944,  name = "Night Elf Male" },
    { id = 540871,  name = "Night Elf Female" },
    { id = 540274,  name = "Gnome Male" },
    { id = 540269,  name = "Gnome Female" },
    { id = 4738613, name = "Skyborne Male" }, -- placeholder: Dracthyr Male, no Skyborne male yawn found
    { id = 8036525, name = "Skyborne Female" },
    { id = 541232,  name = "Orc Male" },
    { id = 541145,  name = "Orc Female" },
    { id = 542606,  name = "Undead Male" },
    { id = 542529,  name = "Undead Female" },
    { id = 542890,  name = "Tauren Male" },
    { id = 542811,  name = "Tauren Female" },
    { id = 543083,  name = "Troll Male" },
    { id = 543095,  name = "Troll Female" },

    -- not playable in Forever, but the files exist
    { id = 539271,  name = "Blood Elf Male" },
    { id = 539212,  name = "Blood Elf Female" },
    { id = 539621,  name = "Draenei Male" },
    { id = 539585,  name = "Draenei Female" },
    { id = 641346,  name = "Pandaren Male" },
    { id = 644782,  name = "Pandaren Female" },
    { id = 1304923, name = "Night Elf Male (Demon Hunter)" },
    { id = 1316212, name = "Night Elf Female (Demon Hunter)" },
    { id = 1536193, name = "Blood Elf Male (Demon Hunter)" },
    { id = 1536192, name = "Blood Elf Female (Demon Hunter)" },
}

SOUNDS.RANDOM_ID = 1

function SOUNDS.Resolve(list, choice)
    if not choice or choice == SOUNDS.RANDOM_ID then
        return list[math.random(#list)].id
    end
    return choice
end

function SOUNDS.GetOptions(list)
    local container = Settings.CreateControlTextContainer()
    container:Add(SOUNDS.RANDOM_ID, "Random")
    for _, sound in ipairs(list) do
        container:Add(sound.id, sound.name)
    end
    return container:GetData()
end