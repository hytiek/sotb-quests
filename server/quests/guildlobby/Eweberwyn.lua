-- Eweberwyn.lua
-- Provides easy transport around EQ for solo, group, and or raids while in the same zone as Eweberwyn
-- configurable destination blocks
-- database driven for future proofing as EQ EMU expands
-- version 1.0, by hytiek

local db = Database(Database.Content)
local chunk_size = 3 -- don't set this higher than 10 due to saylink corruption
local chunk = {}

-- keyed zones config
local block_key_locked_zones = true
local key_locked_zones = { "sebilis", "charasis", "veeshan", "sleeper", "vexthal" }

-- flagged zones config
local block_flag_locked_zones = true
local flag_locked_zones = { }

-- ignore xpac config
local ignore_xpac = {
    "Planes of Power", "Lost Dungeons of Norrath"
}

-- ignore zones config
local ignore_zones = {  
    "fearplane", "hateplane", "hateplaneb", "growthplane",
    "nightmarea", "nightmareb", "podisease", "poinnovation", "pojustice",
    "postorms", "povalor", "potorment", "codecay", "hohonora", "hohonorb",
    "bothunder", "potactics", "solrotower", "powar", "poair", "poeartha",
    "poearthb", "pofire", "ponightmare", "potimea", "potimeb", "powater",
    "chambersa", "chambersb", "chambersc", "chambersd", "chamberse", "chambersf",
    "dranikcatacombsa", "dranikcatacombsb", "dranikcatacombsc",
    "dranikhollowsa", "dranikhollowsb", "dranikhollowsc",
    "draniksewersa", "draniksewersb", "draniksewersc", 
    "qvicb", "sncrematory", "snlair", "snplant", "snpool", "tacvi", "fhalls",
    "tipt", "yxtta", "vxed", "uqua", "ikkinz", "inktuta", "kodtaz", "txevu",
    "barter", "guildlobby", "guildhall"
}

-- enable quick search via set
local function table_to_set(tbl)
    local set = {}
    for _, v in ipairs(tbl) do
        set[v] = true
    end
    return set
end
local key_locked_set = table_to_set(key_locked_zones)
local flag_locked_set = table_to_set(flag_locked_zones)
local ignored_set = table_to_set(ignore_zones)
local ignored_xpac_set = table_to_set(ignore_xpac)

function event_spawn(e)
   --auto-afk check to not draw a model
   local xloc = e.self:GetX();
   local yloc = e.self:GetY();
   eq.set_proximity(xloc - 75, xloc + 75, yloc - 75, yloc + 75);
end

function event_say(e)
    local bucket = "eweber-" .. e.other:GetName() or ""
    local zoneshortname = eq.get_data("eweber-" .. e.other:GetName()) or ""

    if e.message:findi("hail") then
        if zoneshortname == "" then
            get_xpacs()
            return
        else
            travel_link(zoneshortname, e.other)
        end
    elseif e.message:findi("list xpac") then
        get_xpacs()
        return
    elseif e.message:findi("help") then
        display_help(e.other)
        return
    elseif e.message:findi("solo") then
        if zoneshortname ~= "" then -- send solo
            eq.delete_data(bucket)
            e.other:MoveZone(zoneshortname)
            return
        else
            eq.whisper("I'm sorry, you haven't selected a destination to travel to by yourself.")
            get_xpacs()
        end
    elseif e.message:findi("group") then
        if zoneshortname ~= "" then -- send group (only group members in zone)
            local group = e.other:GetGroup();
            if (group ~= nil and group.valid) then
                eq.delete_data(bucket)
                e.other:MoveZoneGroup(zoneshortname)
            else
                eq.whisper("You aren't in a group!")
                return
            end
        else
            eq.whisper("I'm sorry, you haven't selected a destination for your group.")
            get_xpacs()
        end
        return
    elseif e.message:findi("raid") then
        if zoneshortname ~= "" then --- send raid (only raid members in zone)
            local raid_id = eq.get_raid_id_by_char_id(eq.get_char_id_by_name(e.other:GetName()))
            if (raid_id ~= nil and raid_id > 0) then
                eq.delete_data(bucket)
                e.other:MoveZoneRaid(zoneshortname)
            else
                eq.whisper("You aren't in a raid!")
                return
            end
        else
            eq.whisper("I'm sorry, you haven't selected a destination for your raid.")
            get_xpacs()
        end
        return
    elseif e.message:findi("reset") then
        eq.delete_data(bucket)
        get_xpacs()
        return
    else
        if is_xpac(e.message) == true then
            get_zones(e.message)
            return
        else
            if is_valid_zone(e.message) == true then
                zoneshortname = e.message
                eq.set_data(bucket, zoneshortname, tostring(eq.seconds("1m")))
                travel_link(zoneshortname, e.other)
            elseif is_valid_zone(e.message) == false then
                eq.whisper("I'm sorry but " .. e.message .." is not available as a destination.")
            end
        end
    end
end

function display_help(otherapi)
    local help_text = [[
        I'm your go to to go to, as long as there's not a key blocking the entry!<br>
        <br>
        Step 1. Select an expansion.<br>
        <br>
        Step 2. Select the zone you want to visit.<br>
        <br>
        Step 3. Click on solo, group, or raid link(s) that are provided.<br>
        <br><br>
        NOTE: When traveling by group or by raid, I will only teleport those friends that are in the same zone as us.
        <br>
        ]]
    eq.whisper("A dialog window has been opened, if the window is not visible please check behind your other windows.")
    otherapi:Popup("Eweberwyn Help", help_text)
end

function travel_link(zoneshortname, otherapi)
    local raid_id = eq.get_raid_id_by_char_id(eq.get_char_id_by_name(otherapi:GetName()))
    local group = otherapi:GetGroup();
    local usecomma = false

    local linktext = "Travel to " .. zoneshortname
    
    if not (group ~= nil and group.valid) then
        linktext = linktext .. " [" .. eq.say_link("solo") .. "]"
        usecomma = true
    else
        linktext = linktext .. " [" .. eq.say_link("solo") .. "], [" .. eq.say_link("group") .. "]"
        usecomma = true
    end

    if (raid_id ~= nil and raid_id > 0) then
        if usecomma == true then
            linktext = linktext .. ","
        end

        linktext = linktext .. " [" .. eq.say_link("raid") .. "]"
    end
    
    -- display the travel link
    if usecomma == true then
        linktext = linktext .. ","
    end
    eq.whisper(linktext .. " [" .. eq.say_link("reset") .. "], or [" .. eq.say_link("help") .. "]?")
end

function is_valid_zone(zone_name)
    if ignored_set[zone_name] or 
        (block_key_locked_zones and key_locked_set[zone_name]) or 
        (block_flag_locked_zones and flag_locked_set[zone_name]) then
            return false
    end

    if not db then
        eq.whisper("Database connection is not established, please report this to a GM. (iz)")
        return
    end

    local iz_stmt = db:prepare("SELECT id FROM zone WHERE short_name = ? AND expansion <= ? LIMIT 1")

    if not iz_stmt then
        eq.whisper("Failed to prepare statement, please report this to a GM. (iz) " .. zone_name)
        return
    end

    iz_stmt:execute({zone_name, 9}) -- 9 is Dragons of Norrath xpac ID
    local row = iz_stmt:fetch_hash()
    iz_stmt:close()

    if not row then
        return false
    else
        return true
    end
end

function get_zones(xpac_name)
    local zones = {}

    if not db then
        eq.whisper("Database connection is not established, please report this to a GM. (gz)")
        return
    end

    local get_zones_stmt = db:prepare("SELECT z.zoneidnumber, z.version, z.short_name, z.long_name, d.value AS expansion_name FROM zone z JOIN db_str d ON z.expansion = d.id WHERE d.id <= ? AND d.type = ? AND d.value = ? AND version = 0 ORDER BY z.long_name")

    if not get_zones_stmt then
        eq.whisper("Failed to prepare statement, please report this to a GM. (gz) " .. get_zones_stmt)
        return
    end

    get_zones_stmt:execute({9, 20, xpac_name})

    local row = get_zones_stmt:fetch_hash()
    
    while row do
        local short_name = row["short_name"]
    
        -- Skip insertion if short_name exists in either set
        if not key_locked_set[short_name] and not flag_locked_set[short_name] and not ignored_set[short_name] then
            table.insert(zones, {
                zoneidnumber = row["zoneidnumber"],
                version = row["version"],
                short_name = short_name,
                long_name = row["long_name"]
            })
        end
    
        row = get_zones_stmt:fetch_hash()
    end

    get_zones_stmt:close()

    if #zones > 0 then
        eq.whisper("Available zones for " .. xpac_name)
        for i, zone in ipairs(zones) do
            local zone_info = string.format("%s", zone.long_name)
            table.insert(chunk, eq.say_link(zone.short_name, false, zone_info))

            if #chunk == chunk_size then
                eq.whisper("[" .. table.concat(chunk, "], [") .. "]")
                chunk = {}
            end
        end

        if #chunk > 0 then
            eq.whisper("[" .. table.concat(chunk, "], [") .. "]")
        end
        eq.whisper("Need [" .. eq.say_link("help") .. "]?")
    else
        eq.whisper("No zones available for this expansion. (p_m)")
    end
    -- clear chunk to avoid duplicate printing
    chunk = {}
end

function is_xpac(xpac_name)
    if not db then
        eq.whisper("Database connection is not established, please report this to a GM. (ix)")
        return
    end

    local ix_stmt = db:prepare("SELECT id FROM `db_str` WHERE value = ? AND type = ? LIMIT 1")

    if not ix_stmt then
        eq.whisper("Failed to prepare statement, please report this to a GM. (ix) " .. ix_stmt)
        return
    end

    ix_stmt:execute({xpac_name, 20})
    local row = ix_stmt:fetch_hash()
    ix_stmt:close()

    if not row then
        return false
    else
        return true
    end
end

function get_xpacs()
    expansions = {}
    expansion_links = {}

    if not db then
        eq.whisper("Database connection is not established, please report this to a GM. (ge)")
        return
    end

    local stmt = db:prepare("SELECT id, value as name FROM `db_str` where id <= ? AND type = ? ")
    if not stmt then
        eq.whisper("Failed to prepare statement, please report this to a GM. (ge)")
        return
    end

    stmt:execute({9, 20})

    local row = stmt:fetch_hash()
    if not row then
        eq.whisper("No rows fetched, please report this to a GM. (ge)")
        stmt:close()
        return
    end

    while row do
        local expansion_name = row["name"]
        if not ignored_xpac_set[expansion_name] then
            table.insert(expansions, {name = expansion_name})
            table.insert(expansion_links, eq.say_link(expansion_name, false, expansion_name))
        end
        row = stmt:fetch_hash()
    end

    stmt:close()

    if #expansions > 0 then
        local links = table.concat(expansion_links, "], [")
        eq.whisper("Select an expansion [" .. links .. "]")
        eq.whisper("Need [" .. eq.say_link("help") .. "]?")
    else
        eq.whisper("No expansions available, please report this to a GM. (ge)")
    end
end

function checkGroupHasItem(otherAPI, itemID)
    local group = otherAPI:GetGroup();
    local status = false

    if group.valid then
        local player_list_count = group:GroupCount();
        for i = 0, player_list_count - 1, 1 do
            local client_v = group:GetMember(i):CastToClient();
            if client_v.valid then
                if client_v:HasItem(itemID) then
                    status = true
                end
            end
        end
        return status
    end
end
