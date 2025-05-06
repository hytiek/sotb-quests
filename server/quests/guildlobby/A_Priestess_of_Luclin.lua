-- This version of PoL allows for standard acceptance of item for rez or words like live and offers 
-- different percentages of rez for a fee

local pct_to_spell = {
    [20] = 2170,
    [50] = 2171,
    [75] = 2172,
    [90] = 392,
    [96] = 1524
}

local function get_cost(e, percent)
    percent = percent / 100 -- convert the int percentage to its float value
    level = e.other:GetLevel() -- Get the players level
    local cost = 0.0
    if (percent ~= 0.96) then
        cost = math.floor(level * (1 + percent) + 0.5)
        return cost
    else
        cost = math.floor(((level * (1 + percent)) + (level / 2)) + 0.5)
        return cost
    end
end

local function prices_popup(e)
    local npc_instructions = string.format([[
    <c '#FFD700'>Hello there, for a price I can ressurect your corpses. Here's how it works:</c>
    <br><p>
    1. <c '#00FF00'>Hail Me:</c>
      Start by hailing me, and I’ll guide you through the process.
    </p>
    <br>
    <p>
    2. <c '#00FF00'>Choose the percentage of the resurrection you seek:</c>
      I will ressurect your nearest corpse with a spell of that percentage. The prices for this
          are based off of your current level, and the percentage of the res chosen.
    </p>
    <br>
    <p>
    3. <c '#00FF00'>Current prices for you:</c><br>
                <c '#00FF00'>20: </c> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<c '#00FFFF'> %d Platinum</c><br>
                <c '#00ff00'>50: </c> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<c '#00FFFF'> %d Platinum</c><br>
                <c '#00ff00'>75: </c> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<c '#00FFFF'> %d Platinum</c><br>
                <c '#00ff00'>90: </c> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<c '#00FFFF'> %d Platinum</c><br>
                <c '#00ff00'>96: </c> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<c '#00FFFF'> %d Platinum</c><br>
                      <br>
      <c '#FFD700'>Let me know when you're ready to begin!</c>
    </p>
  ]], get_cost(e, 20), get_cost(e, 50), get_cost(e, 75), get_cost(e, 90),
                                           get_cost(e, 96))
    e.other:Popup("Resurrection Instructions & Prices", npc_instructions)
end

local function insuffecient_funds(e)
    e.self:Say("You lack suffecient platinum to pay for this service.")
end

local function res_corpse(e, cost, percent)
    local spell_id = pct_to_spell[percent]
    -- e.self:Say("spell id: " .. spell_id)
    local clist = eq.get_entity_list():GetCorpseList()
    if clist == nil then e.self:Say("I see no corpses to be resurrected.") end
    cost = cost * 1000
    for corpse in clist.entries do
        if (corpse:IsPlayerCorpse()) then
            if (corpse:GetOwnerName() == e.other:GetName()) then
                e.self:Say("That will cost you " .. cost / 1000 .. " platinum.")
                e.other:TakeMoneyFromPP(cost, true)
                e.self:CastSpell(spell_id, corpse:GetID(), 0, 0)
                return
            end
        end
    end
    e.self:Say("I do not see any of your corpses near here.")
end

function event_say(e)
    if e.message:findi("hail") then
        e.self:Say(
            "If you are in need of our aid speak to the disciple and bring me one of the soulstones that he sells. I must continue to delve into the twilight of our world in search of lost souls. f you are in need, we may be able to [" ..
                eq.say_link("summon") ..
                "] back the remnants of your former life before they drift completely into darkness. I can also [" ..
                eq.say_link("resurrect") .. "] you, for a price.")
    elseif e.message:findi("summon") then
        summon_corpse(e, 1)
    elseif e.message:findi("resurrect") then
        e.self:Say("I offer resurrections of the following percentages [" ..
                       eq.say_link("20") .. "], [" .. eq.say_link("50") ..
                       "], [" .. eq.say_link("75") .. "], [" ..
                       eq.say_link("90") .. "], and [" .. eq.say_link("96") ..
                       "]. Or you can ask me about my [" ..
                       eq.say_link("prices") .. "].")
    elseif e.message:findi("prices") then
        prices_popup(e)
    elseif e.message:findi("20") then
        local cost = get_cost(e, 20)
        local theirMoney = e.other:GetCarriedPlatinum()
        if cost > theirMoney then
            insuffecient_funds(e)
            return
        end
        res_corpse(e, cost, 20)
    elseif e.message:findi("50") then
        local cost = get_cost(e, 50)
        local theirMoney = e.other:GetCarriedPlatinum()
        if cost > theirMoney then
            insuffecient_funds(e)
            return
        end
        res_corpse(e, cost, 50)
    elseif e.message:findi("75") then
        local cost = get_cost(e, 75)
        local theirMoney = e.other:GetCarriedPlatinum()
        if cost > theirMoney then
            insuffecient_funds(e)
            return
        end
        res_corpse(e, cost, 75)
    elseif e.message:findi("90") then
        local cost = get_cost(e, 90)
        local theirMoney = e.other:GetCarriedPlatinum()
        if cost > theirMoney then
            insuffecient_funds(e)
            return
        end
        res_corpse(e, cost, 90)
    elseif e.message:findi("96") then
        local cost = get_cost(e, 96)
        local theirMoney = e.other:GetCarriedPlatinum()
        if cost > theirMoney then
            insuffecient_funds(e)
            return
        end
        res_corpse(e, cost, 96)
    end
end

function event_trade(e)
    local item_lib = require("items");
    local failure =
        "This focus is not powerful enough to summon the remnants of your former self.  The disciple of Luclin can help you select an appropriate focus."
    local player_level = e.other:GetLevel();

    if item_lib.check_turn_in(e.trade, {item1 = 76013}) then -- Items: Minor Soulstone
        if player_level < 21 then
            summon_corpse(e);
        else
            e.self:Say(failure);
            e.other:SummonItem(76013);
        end
    elseif item_lib.check_turn_in(e.trade, {item1 = 76014}) then -- Items: Lesser Soulstone
        if player_level < 31 then
            summon_corpse(e);
        else
            e.self:Say(failure);
            e.other:SummonItem(76014);
        end
    elseif item_lib.check_turn_in(e.trade, {item1 = 76015}) then -- Items: Soulstone
        if player_level < 41 then
            summon_corpse(e);
        else
            e.self:Say(failure);
            e.other:SummonItem(76015);
        end
    elseif item_lib.check_turn_in(e.trade, {item1 = 76016}) then -- Items: Greater Soulstone
        if player_level < 51 then
            summon_corpse(e);
        else
            e.self:Say(failure);
            e.other:SummonItem(76016);
        end
    elseif item_lib.check_turn_in(e.trade, {item1 = 76017}) then -- Items: Faceted Soulstone
        if player_level < 56 then
            summon_corpse(e);
        else
            e.self:Say(failure);
            e.other:SummonItem(76017);
        end
    elseif item_lib.check_turn_in(e.trade, {item1 = 76018}) then -- Items: Pristine Soulstone
        if player_level < 71 then
            summon_corpse(e);
        else
            e.self:Say(failure);
            e.other:SummonItem(76018);
        end
    elseif item_lib.check_turn_in(e.trade, {item1 = 76019}) then -- Items: Glowing Soulstone
        if player_level < 76 then
            summon_corpse(e);
        else
            e.self:Say(failure);
            e.other:SummonItem(76019);
        end
    elseif item_lib.check_turn_in(e.trade, {item1 = 76048}) then -- Items: Prismatic Soulstone
        if player_level < 81 then
            summon_corpse(e);
        else
            e.self:Say(failure);
            e.other:SummonItem(76048);
        end
    elseif item_lib.check_turn_in(e.trade, {item1 = 76065}) then -- Items: Iridescent Soulstone
        if player_level < 86 then
            summon_corpse(e);
        else
            e.self:Say(failure);
            e.other:SummonItem(76065);
        end
    elseif item_lib.check_turn_in(e.trade, {item1 = 76274}) then -- Items: Phantasmal Soulstone
        if player_level < 91 then
            summon_corpse(e);
        else
            e.self:Say(failure);
            e.other:SummonItem(76274);
        end
    elseif item_lib.check_turn_in(e.trade, {item1 = 76274}) then -- Items: Luminous Soulstone
        if player_level < 96 then
            summon_corpse(e);
        else
            e.self:Say(failure);
            e.other:SummonItem(76274);
        end
    end
    item_lib.return_items(e.self, e.other, e.trade);
end

function summon_corpse(e, extra)
    local x, y, z, h = e.self:GetX(), e.self:GetY(), e.self:GetZ(),
                       e.self:GetHeading();
    local char_id = e.other:CharacterID();
    local corpse_count = e.other:GetCorpseCount();

    if corpse_count > 0 then
        eq.summon_all_player_corpses(char_id, x, y, z, h)
        if extra ~= nil and extra == 1 then
            e.self:Emote(
                "A Priest of Luclin breathes deeply and begins to chant. Shadows begin to drift across the floor and over the altar, swirling upward as if to reach Luclin herself.  The priest's voice is soon joined with several others, blending into a fervent, esoteric chorus as the shadows slowly coalesce into a familiar wispy mass.  The two candles near the altar explode with light and there, before you, appears all that remains of your former life.")
            return
        else
            e.self:Emote(
                "takes your stone and places it on the altar. Shadows begin to drift across the floor and over the altar and finally onto the soulstone.  The priest's voice chants with intensity and is soon joined with several others as the shadows slowly coalesce into a wispy mass that feels familiar.  The two candles near the altar explode with light and there, before you, appears all that remains of your former life.")
            return
        end
    end
    e.self:Emote(
        "ponders at you, wondering why you think you have a corpse when you don't.")
end
