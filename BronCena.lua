local _, ns = ...

local APPNAME = "BronCena";
local APPDESC = "Bron Cena";

BronCena = LibStub("AceAddon-3.0"):NewAddon(APPNAME, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0");
local L = LibStub("AceLocale-3.0"):GetLocale(APPNAME);
local LSM = LibStub("LibSharedMedia-3.0");
local ACD = LibStub("AceConfigDialog-3.0");

BronCena.plugins = {}

BronCena.SOUND_PATH = "Interface/AddOns/BronCena/Media/Sounds/";
BronCena.CHANNEL_DEFAULT = "default";

-- Library constants
local SOUND = LSM.MediaType and LSM.MediaType.SOUND or "sound";

local isInitialized = false;

-- Hidden tooltip used to parse summoned unit tooltips for things like name
local parsingTooltip = nil;

local sounds = {
}

-- Sound Channels
local soundChannels =  {
    ["default"] = "Default",
    ["ambience"] = "Ambience",
    ["dialog"] = "Dialog",
    ["master"] = "Master",
    ["music"] = "Music",
    ["sfx"] = "Sound"
}

function BronCena:Debug(...)
    --if self.db.profile.debug == false then return end
    --self:Printf(...)
end

local defaults = {
    profile = {

        -- General
        disabled = false,
        unlocked = false, -- Enable or disable dragging of the UI elements
        debug = false,
        soundChannel = BronCena.CHANNEL_DEFAULT, -- Default sound channel
        enableOverlap = false, -- Allow sounds to overlap each other

        -- Enable / disable for zones
        zones = {
            party = true,
            raid = true,
            pvp = true,
            arena = true,
            scenario = true,
            world = true
        },

        -- Enable / disable for owners
        owners = {
            player = true,
            party = true,
            raid = true,
            friendly = true,
            hostile = true
        }
    }
}

function BronCena:OnInitialize()

    if self.isInitialized == true then
        return
    end

    self.db = LibStub("AceDB-3.0"):New("BronCenaDB", defaults, true)

    BronCena:RegisterSounds(sounds);
    
    self:RegisterChatCommand("broncena", "ChatCommand");
    self:RegisterChatCommand("bron", "ChatCommand");

    self.isInitialized = true;
end

function BronCena:RegisterSounds(sounds)
    for k,v in pairs(sounds) do
        self:Debug("Registering sound "..k..": "..v.name);
        LSM:Register(SOUND, v.name, v.path);
    end
end

function BronCena:ChatCommand()
    self:Debug("/bron or /broncena was invoked");
    --InterfaceOptionsFrame_OpenToCategory(APPDESC)
    --InterfaceOptionsFrame_OpenToCategory(APPDESC)
end

function BronCena:OnEnable()
    self:Debug("BronCena:OnEnable");
    BronCena:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
    BronCena:RegisterEvent("PLAYER_LEVEL_UP");
    if self.parsingTooltip == nil then
        self.parsingTooltip = CreateFrame("GameTooltip", APPNAME.."Tooltip", WorldFrame, "GameTooltipTemplate");
    end

    if BronCena.tooltip then
        self:Debug("Registering tooltip hook")
        --BronCena.tooltip:SetHooks();
    end
end

function BronCena:OnDisable()
    self:Debug("OnDisable");
    BronCena:UnregisterEvent("PLAYER_LEVEL_UP");
    BronCena:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
end

function BronCena:RegisterPlugin(pluginName, pluginHandler, optionsTable)
	if self.plugins[pluginName] ~= nil then
		error(pluginName.." is already registered by another plugin.")
	else
		self.plugins[pluginName] = pluginHandler
	end
end

local getOwner = function(sourceFlags)
    if sourceFlags == nil then
        self:Debug("getOwner(sourceFlags==nil)")
        return nil
    end
    if bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE then return "hostile" end
    if bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_PARTY) == COMBATLOG_OBJECT_AFFILIATION_PARTY then return "party" end
    if bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_RAID) == COMBATLOG_OBJECT_AFFILIATION_RAID then return "raid" end
    if bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) == COMBATLOG_OBJECT_AFFILIATION_MINE then return "player" end
    if bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) == COMBATLOG_OBJECT_AFFILIATION_OUTSIDER then return "friendly" end
    return nil
end

function BronCena:PLAYER_LEVEL_UP(event, ...)
    self:Trigger( { event = event, params = ...});
end

function BronCena:COMBAT_LOG_EVENT_UNFILTERED(...)
    if true then return end

    local time, event, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, _, extraSpellId, amount = CombatLogGetCurrentEventInfo();

    local args = {
    }

    args.time, args.event = time, event;
    args.sourceGUID, args.sourceName, args.sourceFlags, args.sourceRaidFlags, args.sourceEnabled = sourceGUID, sourceName, sourceFlags, sourceRaidFlags, true;
    args.destGUID, args.destName, args.destFlags, args.destRaidFlags, args.destEnabled = destGUID, destName, destFlags, destRaidFlags, true;
    args.spellId, args.spellName, args.extraSpellId, amount = spellId, spellName, extraSpellId, amount;
    
    if ( not sourceName or CombatLog_Object_IsA(sourceFlags, COMBATLOG_OBJECT_NONE) ) then
		args.sourceEnabled = false;
	end

	if ( not destName or CombatLog_Object_IsA(destFlags, COMBATLOG_OBJECT_NONE) ) then
		args.destEnabled = false;
	end
    
    --sound = LSM:Fetch(SOUND, companion.soundId, false) or companion.soundId

    --self:Trigger(args)
end

function BronCena:Trigger(args)
    self:Debug("Trigger");

    if not args then return end;

    local soundHandle = nil;

    if args.sound then
        local soundChannel = args.soundChannel or BronCena.CHANNEL_DEFAULT;
        if soundChannel == BronCena.CHANNEL_DEFAULT then soundChannel = soundChannels.dialog end;

        if args.soundHandle then
            -- Users can allow overlapping sounds for hilarity
            if not args.enableOverlap == true then
                StopSound(args.soundHandle);
            end             
        end

        local sound = LSM:Fetch(SOUND, args.sound, false) or args.sound;

        -- Play the sound
        self:Debug("Playing %s", tostring(sound));
        local willPlay, handle = PlaySoundFile(sound, soundChannel)
        if willPlay then
            soundHandle = handle
        end
    end

    return soundHandle;
end

function BronCena:TriggerBron(spellId, subevent, destName, sourceFlags, destGUID)

    if self.db.profile.disabled == true then
        --self:Debug("Add-on is disabled")
        return
    end

    -- See if this spellId is supported
    local companion = self.db.profile.companions[tostring(spellId)]

    if not companion then
        --self:Debug("No companion for "..tostring(spellId))
        return
    elseif companion.disabled == true then
        self:Debug("Disabled for this companion")
        return
    end

    if companion.eventType ~= subevent then
        -- The type of event doesn't match what we want, so skip this
        --self:Debug("subevent not enabled for "..tostring(subevent).." "..spellId)
        return
    end
    
    -- Types: "Creature", "Pet", "GameObject", "Vehicle", "Vignette" 
    -- [unitType]-0-[serverID]-[instanceID]-[zoneUID]-[ID]-[spawnUID]
    -- local unitID = tonumber(string.match(unitGUID, "Creature%-.-%-.-%-.-%-.-%-(.-)%-"));

    local owner = getOwner(sourceFlags);
    --self:Debug("Owner: %s", tostring(owner))
    if owner and companion.owners[owner] == false or (companion.owners[owner] == nil and self.db.profile.owners[owner] == false) then
        self:Debug("Disabled for %s", owner)
        return
    end

    local instanceName, instanceType, difficultyId, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceId, instanceGroupSize, lfgDungeonId = GetInstanceInfo()

    if not instanceType or instanceType == 'none' then
        instanceType = 'world';
    end

    if self.db.profile.zones[instanceType] == false then
        self:Debug("Disabled for " .. instanceType)
        return
    end

    if companion.zones[instanceType] == false then
        self:Debug("Disabled for " .. instanceType)
        return
    end

    -- Figure out the sound to play
    self:Debug("soundPath=%s,soundId=%s", tostring(companion.soundPath), tostring(companion.soundId))

    -- Default to the custom path
    local sound = companion.soundPath

    -- If we're using a selected option, we have to find the path / soundkit id
    if tostring(companion.soundId) == tostring(soundOptions.custom) then
        self:Debug("Using custom sound path")
    else
        self:Debug("Shared media id: %s", tostring(companion.soundId))
        sound = LSM:Fetch(SOUND, companion.soundId, false) or companion.soundId
    end

    local soundChannel = companion.soundChannel or CHANNEL_DEFAULT
    if soundChannel == CHANNEL_DEFAULT then soundChannel = soundChannels.dialog end

    -- Is there a delay on this companion? We can do this to line up the message or sounds to
    -- the companion's timings, or use it to give the game engine time to get the unit's descriptive name
    -- e.g. "Farah" instead of "Kyrian Steward"
    if companion.delay == nil or companion.delay <= 0 then
        
        -- Add the message
        if companion.message then
            local name = destName
            local message = string.format(companion.message, name or "Unknown")
            BronCenaMessageFrame:AddMessage(message, 1.0, 1.0, 1.0);            
        end

        -- Stop this companion's sound if it's already playing to prevent annoying overlaps
        if companion.handle then
            -- Users can allow overlapping sounds for hilarity
            if not self.db.profile.enableOverlap == true then
                StopSound(companion.handle)
            end             
        end

        -- Play the sound
        self:Debug("Playing %s", tostring(sound))
        local willPlay, handle = PlaySoundFile(sound, soundChannel)
        if willPlay then
            companion.handle = handle
        end

    else
        -- Delay the message to be able to get the unit's name 
        self:ScheduleTimer(function (...)

            if companion.message then
                self.parsingTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
                self.parsingTooltip:SetHyperlink('unit:'..destGUID)
                local unitName = _G[APPNAME.."Tooltip".."TextLeft1"]:GetText()
                local message = string.format(companion.message, unitName or destName or "Unknown")
                BronCenaMessageFrame:AddMessage(message, 1.0, 1.0, 1.0);
            end

            -- Stop this companion's sound if it's already playing to prevent annoying overlaps
            if companion.handle then
                -- Users can allow overlapping sounds for hilarity
                if not self.db.profile.enableOverlap == true then
                    StopSound(companion.handle)
                end             
            end

            -- Play the sound
            self:Debug("Playing %s", tostring(sound))
            local willPlay, handle = PlaySoundFile(sound, soundChannel)
            if willPlay then
                companion.handle = handle
            end

        end, companion.delay)
    end
end