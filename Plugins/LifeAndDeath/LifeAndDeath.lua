local BronCena = LibStub("AceAddon-3.0"):GetAddon("BronCena")
local LifeAndDeath = BronCena:NewModule("LifeAndDeath", "AceEvent-3.0", "AceConsole-3.0")
--local L = LibStub("AceLocale-3.0"):GetLocale("LifeAndDeath", false)

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
    heroesNeverDie = {name= "BronCena: OW: Heroes Never Die", path= BronCena.SOUND_PATH.."OW/heroes-never-die.ogg"},
}

function LifeAndDeath:OnInitialize()
    BronCena:RegisterPlugin("LifeAndDeath", LifeAndDeath);
    BronCena:RegisterSounds(sounds);
end

function LifeAndDeath:OnEnable()
    LifeAndDeath:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function LifeAndDeath:OnDisable()
    LifeAndDeath:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function LifeAndDeath:COMBAT_LOG_EVENT_UNFILTERED(...)
    local time, event, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, _, extraSpellId, amount = CombatLogGetCurrentEventInfo();

    if not event then return end;    
    if event ~= "SPELL_RESURRECT" then return; end

    -- Skip hostile units
    if bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE then
        BronCena:Debug("Hostile unit, skipping");
        return;
    end

-- ["391054"] = "CRez: Intercession (Paladin)"
-- ["61999"] = "CRez: Raise Ally (Death Knight)"
-- ["20707"] = "CRez: Soulstone (Warlock)"
-- ["20484"] = "CRez: Rebirth (Druid)"
-- ["20608"] = "CRez: Reincarnation (Shaman)"

    local args = {
        sound = nil,
        message = nil,
        soundHandle = soundHandle
    }

    soundHandle = BronCena:Trigger( { message="Heroes Never Die!", sound=sounds.heroesNeverDie.name, soundHandle=soundHandle } );
end