local BronCena = LibStub("AceAddon-3.0"):GetAddon("BronCena")
local KillSounds = BronCena:NewModule("KillSounds", "AceEvent-3.0", "AceConsole-3.0")
--local L = LibStub("AceLocale-3.0"):GetLocale("KillSounds", false)

local lastKillTime = 0;
local consecutive = 0;
local soundHandle = nil;
local playerGUID = UnitGUID("player");

local defaults = {
    disabled = false,
    killingBlowsOnly = false,
    soundChannel = BronCena.CHANNEL_DEFAULT
}

local sounds = {
    doubleKill = {name= "BronCena: UT: Double Kill", path= BronCena.SOUND_PATH.."UT2K4/doublekill.ogg"},
    multiKill = {name= "BronCena: UT: Multi Kill", path= BronCena.SOUND_PATH.."UT2K4/multikill.ogg"},
    megaKill = {name= "BronCena: UT: Mega Kill", path= BronCena.SOUND_PATH.."UT2K4/megakill.ogg"},
    ultraKill = {name= "BronCena: UT: Ultra Kill", path= BronCena.SOUND_PATH.."UT2K4/ultrakill.ogg"},
    monsterKill = {name= "BronCena: UT: Monster Kill", path=BronCena.SOUND_PATH.."UT2K4/monsterkillecho.ogg"},
    -- doubleKill = {name= "BronCena: UT: Double Kill", path= BronCena.SOUND_PATH.."UnrealTournament/doublekill.ogg"},
    -- multiKill = {name= "BronCena: UT: Multi Kill", path= BronCena.SOUND_PATH.."UnrealTournament/multikill.ogg"},
    -- ultraKill = {name= "BronCena: UT: Ultra Kill", path= BronCena.SOUND_PATH.."UnrealTournament/ultrakill.ogg"},
    -- monsterKill = {name= "BronCena: UT: Monster Kill", path=BronCena.SOUND_PATH.."UnrealTournament/monsterkill.ogg"},
}

function KillSounds:OnInitialize()
    BronCena:RegisterPlugin("KillSounds", KillSounds);
    BronCena:RegisterSounds(sounds);
end

function KillSounds:OnEnable()
    KillSounds:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function KillSounds:OnDisable()
    KillSounds:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function KillSounds:COMBAT_LOG_EVENT_UNFILTERED(...)
    local time, event, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, _, extraSpellId, amount = CombatLogGetCurrentEventInfo();

    if not event then return end;
    
    if event ~= "PARTY_KILL" then
        --BronCena:Debug(event);
        return
    else
        BronCena:Debug("UT SOUNDS SHOULD TRIGGER!");
    end

    -- Skip non-hostile units
    if bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE then
    --if CombatLog_Object_IsA(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) then
    else
        BronCena:Debug("Not hostile, skipping");
        return;
    end

    -- Killing blows only?
    if sourceGUID ~= playerGUID then
       BronCena:Debug("Not killed by player");
       return;
    end

    BronCena:Debug("lastKillTime: "..tostring(lastKillTime));

    -- Time delta between this kill and the last kill
    local delta = 0;
    
    if lastKillTime > 0 then
        delta = GetTime() - lastKillTime;
    else
        delta = 30 -- Make sure this is outside the cut-off
    end

    lastKillTime = GetTime()

    BronCena:Debug("delta: "..tostring(delta));

    if( delta > 5) then
        consecutive = 1;
    else
        consecutive = consecutive + 1
    end

    local args = {
        sound = nil,
        message = nil,
        soundHandle = soundHandle
    }

    BronCena:Debug("consecutive: "..tostring(consecutive));

    -- Pick the sound
    if consecutive == 2 then
        soundHandle = BronCena:Trigger( { message="Double Kill!", sound=sounds.doubleKill.name, soundHandle=soundHandle } );
    elseif consecutive == 3 then
        soundHandle = BronCena:Trigger( { message="Multi Kill!", sound=sounds.multiKill.name, soundHandle=soundHandle } );
    elseif consecutive == 4 then
        soundHandle = BronCena:Trigger( { message="Mega Kill!", sound=sounds.megaKill.name, soundHandle=soundHandle } );
    elseif consecutive == 5 then
        soundHandle = BronCena:Trigger( { message="Ultra Kill!", sound=sounds.ultraKill.name, soundHandle=soundHandle } );
    elseif consecutive > 5 then
        soundHandle = BronCena:Trigger( { message="MONSTER KILL!", sound=sounds.monsterKill.name, soundHandle=soundHandle } );
    else
        BronCena:Debug("Not triggering; consecutive="..tostring(consecutive));
    end
end