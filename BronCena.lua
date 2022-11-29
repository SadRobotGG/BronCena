
local _, ns = ...

local APPNAME = "BronCena"
local APPDESC = "Bron Cena"

BronCena = LibStub("AceAddon-3.0"):NewAddon(APPNAME, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(APPNAME)
local LSM = LibStub("LibSharedMedia-3.0")
local ACD = LibStub("AceConfigDialog-3.0")

-- Library constants
local SOUND = LSM.MediaType and LSM.MediaType.SOUND or "sound"

local isInitialized = false

-- Hidden tooltip used to parse summoned unit tooltips for things like name
local parsingTooltip = nil;

local soundOptions = {
    custom = "<Custom Sound>",
    random = "BronCena: Surprise me! (Random)",
    broncena = "BronCena: Default",
    broncenafull = "BronCena: Full Length",
    shoryuken = "BronCena: Shoryuken",
    shouryureppa = "BronCena: Shouryureppa",
    metalgear = "BronCena: Metal Gear Alert",
    yaketysax = "BronCena: Yakety Sax (Benny Hill)",
    darkness = "BronCena: Sound of Silence",
}

local soundPaths = {
    [soundOptions.broncena] = "Interface/AddOns/BronCena/Media/Sounds/broncena.ogg",
    [soundOptions.broncenafull] = "Interface/AddOns/BronCena/Media/Sounds/broncena-full.ogg",
    [soundOptions.shoryuken] = "Interface/AddOns/BronCena/Media/Sounds/shoryuken.ogg",
    [soundOptions.shouryureppa] = "Interface/AddOns/BronCena/Media/Sounds/shouryureppa.ogg",
    [soundOptions.metalgear] = "Interface/AddOns/BronCena/Media/Sounds/metalgear.ogg",
    [soundOptions.yaketysax] = "Interface/AddOns/BronCena/Media/Sounds/yakety-sax.ogg",
    [soundOptions.darkness] = "Interface/AddOns/BronCena/Media/Sounds/darkness.ogg"
}

local soundChannels =  {
    ["default"] = "Default",
    ["ambience"] = "Ambience",
    ["dialog"] = "Dialog",
    ["master"] = "Master",
    ["music"] = "Music",
    ["sfx"] = "Sound"
}

local sharedSoundOptions = nil

local CHANNEL_DEFAULT = "default"

function BronCena:Verbose(...)
    if self.db.profile.verbose == false then return end
    self:Printf(...)
end

function BronCena:Debug(...)
    if self.db.profile.debug == false then return end
    self:Printf(...)
end

local function CompanionDefaults(disabled, id, name, desc, soundId, message, delay, eventType)
    return {
        id = id,
        name = name,
        desc = desc,
        disabled = disabled or false,
        zones = { party = nil, raid = nil, pvp = nil, arena = nil, scenario = nil, world = nil },
        owners = { player = nil, party = nil, raid = nil, friendly = nil, hostile = nil },
        delay = delay or nil,
        soundDisabled = false,
        soundId = soundId or nil,
        soundPath = nil,
        soundChannel = CHANNEL_DEFAULT,
        message = message or nil,
        messageDisabled = false,
        eventType = eventType or "SPELL_SUMMON"
    }
end

-- Spells that by default should only trigger for just the player
local function CompanionPlayerDefaults(disabled, id, name, desc, soundId, message, delay, eventType)
    return {
        id = id,
        name = name,
        desc = desc,
        disabled = disabled or false,
        zones = { party = nil, raid = nil, pvp = nil, arena = nil, scenario = nil, world = nil },
        owners = { player = true, party = false, raid = false, friendly = false, hostile = false },
        delay = delay or nil,
        soundDisabled = false,
        soundId = soundId or nil,
        soundPath = nil,
        soundChannel = CHANNEL_DEFAULT,
        message = message or nil,
        messageDisabled = false,
        eventType = eventType or "SPELL_SUMMON"
    }
end

-- Companions
-- 324739 Summon Steward (unit: Steward)
--   ITEM_PUSH: 463534 (Phial of Serenity)
-- 221745 - Judgement's Gaze (Lothraxion)
-- UNIT_SPELLCAST_SUCCEEDED: Summoning pets

local defaults = {
    profile = {

        -- General
        disabled = false,
        unlocked = false, -- Enable or disable dragging of the UI elements
        debug = false,
        soundChannel = CHANNEL_DEFAULT, -- Default sound channel
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
        },

        -- Default companions
        companions = {
            ["1"] = CompanionDefaults(false, "1", "Level Up", "", soundOptions.broncena, "DING! Bron Cena says grats on level %s!", nil, "PLAYER_LEVEL_UP"),
            ["333961"] = CompanionDefaults(false, "333961", "Bron Cena", "", soundOptions.broncena, "And his name is BRON CENA!"),
            ["324739"] = CompanionDefaults(true, "324739", "Kyrian Steward", "", soundOptions.metalgear, "A wild %s appears!", 0.8),
            ["368241"] = CompanionPlayerDefaults(true, "368241", "Wo Speed Buff", "", soundOptions.yaketysax, nil, nil, "SPELL_AURA_APPLIED"),
            ["883"] = CompanionDefaults(true, "883", "Hunter Pet 1", "", soundOptions.metalgear, "A wild %s appears!", 0.8),
            ["1297"] = CompanionDefaults(true, "1297", "Revive Pet", "", soundOptions.metalgear, "A wild %s appears!", 0.8),
            ["196718"] = CompanionDefaults(true, "196718", "Darkness", "", soundOptions.darkness, "Hello Darkness my old friend...", nil, "SPELL_CAST_SUCCESS"),
        }
    }
}

local options = {
    name = APPDESC,
    handler = BronCena,
    type = "group",
    childGroups = "tab",
    desc = APPDESC,
    get = "GetConfig",
    set = "SetConfig",
    args = {
        general = {
            type = "group",
            name = "General",
            order = 1,
            args={
                general = {
                    type = "group",
                    name = "General Options",
                    order = 10,
                    inline = true,
                    args = {
                        disabled = {
                            order = 10,
                            type = "toggle",
                            name = L["Disabled"],
                            desc = L["Disables or enables the addon"]
                        },
                        unlocked = {
                            order = 20,
                            type = "toggle",
                            name = L["Unlock"],
                            desc = L["Enables or disables moving UI"]
                        },
                        soundChannel = {
                            order = 30,
                            type = "select",
                            name = L["Channel"],
                            desc = L["Default sound channel"],
                            values = "SoundChannels"
                        },
                        debug = {
                            order = 40,
                            type = "toggle",
                            name = L["Debug"],
                            desc = L["Enables or disables debug logging"]
                        },
                        enableOverlap = {
                            order = 50,
                            type = "toggle",
                            width = "double",
                            name = L["Enable overlapping sounds"],
                            desc = L["Enables or disables sounds to play over each other when triggered multiple times"]
                        },
                    }
                },
                zones = {
                    order = 20,
                    type = "multiselect",
                    name = L["Zones"],
                    values = "GetZoneOptions",
                    get = "GetMultiSelectConfig",
                    set = "SetMultiSelectConfig"
                },
                owners = {
                    order = 30,
                    type = "multiselect",
                    name = L["Owners"],
                    values = "GetOwnerOptions",
                    get = "GetMultiSelectConfig",
                    set = "SetMultiSelectConfig"
                }
            }
        },
        companions = {
            name = "Companions",
            type = "group",
            childGroups = "select",
            args = {
                general = {
                    type = "description",
                    name = "Choose a companion from the drop-down"
                },
                -- add = {
                --     name = "Add",
                --     desc = "Add a new companion",
                --     type = "execute"
                -- },
            }
        }
    }
}

function BronCena:InitializeOptions(root)

    for k,v in pairs(self.db.profile.companions) do

        local node = {
            type = "group",
            name = v.name,
            desc = v.description,
            get = "GetCompanionConfig",
            set = "SetCompanionConfig",
            childGroups = "tab",
            args = {
                disabled = {
                    order = 1,
                    type = "toggle",
                    name = L["Disabled"],
                    desc = "Disable or enable this companion",
                    width = "full",
                    get = function ()
                        return v.disabled
                    end
                },
                id = {
                    disabled = true,
                    order = 10,
                    width = "normal",
                    type = "input",
                    name = "ID",
                    desc = "The spell id that summons this companion",
                    get = function ()
                        return v.id
                    end
                },
                name = {
                    width = "normal",
                    order = 20,
                    disabled = true,
                    type = "input",
                    name = "Name",
                    desc = "The name for this companion",
                    get = function ()
                        return v.name
                    end
                },
                message = {
                    width = "full",
                    order = 25,
                    type = "input",
                    name = "Message",
                    desc = "The message for this companion. %s will be substituted with the companion's name.",
                    get = function (info)
                        return v.message
                    end,
                    set = function(info, value)
                        v.message = value
                    end
                },
                soundId = {
                    order = 30,
                    width = "double",
                    type = "select",
                    name = "Sound",
                    desc = "The sound to play",
                    values = "GetSoundOptions",
                    get = function (info) return v.soundId end,
                    set = function (info, value)
                        self:Debug("Set soundId to %s", tostring(value))
                        v.soundId = value
                    end
                },
                soundChannel = {
                    width = "normal",
                    order = 40,
                    type = "select",
                    name = L["Channel"],
                    desc = L["Default sound channel"],
                    values = "SoundChannels",
                    get = function (info) return v.soundChannel end,
                    set = function (info, value) v.soundChannel = value end
                },
                soundPath = {
                    order = 50,
                    type = "input",
                    name = "Path",
                    desc = "The sound to play",
                    width = "full",
                    get = function (info)
                        if tostring(v.soundId) == tostring(soundOptions.custom) then
                            return v.soundPath
                        else
                            self:Debug("Fetching %s", v.soundId)
                            return tostring(LSM:Fetch(SOUND, v.soundId, false) or v.soundId)
                        end
                    end,
                    set = function (info, value) 
                        v.soundPath = tostring(value)
                    end,
                    disabled = function ()
                        self:Debug("soundId=%s", v.soundId)

                        if tostring(v.soundId) == tostring(soundOptions.custom) then
                            return false
                        else
                            return true
                        end
                    end
                },
                playSound = {
                    order = 60,
                    type = "execute",
                    width = "half",
                    name = "Test",
                    func = function()

                        -- Default to the custom path
                        local sound = v.soundPath

                        -- If we're using a selected option, we have to find the path / soundkit id
                        if tostring(v.soundId) == tostring(soundOptions.custom) then
                            self:Debug("Using custom sound path")
                        else
                            self:Debug("Shared media id: %s", tostring(v.soundId))
                            sound = LSM:Fetch(SOUND, v.soundId, false) or v.soundId
                        end

                        local soundChannel = v.soundChannel or CHANNEL_DEFAULT
                        if soundChannel == CHANNEL_DEFAULT then soundChannel = soundChannels.dialog end

                        if not sound then
                            self:Debug("No sound path to play")
                        else
                            if v.message then
                                local message = string.format(v.message, "<Unknown>")
                                BronCenaMessageFrame:AddMessage(message, 1.0, 1.0, 1.0);
                            end

                            self:Debug("Playing %s", sound)

                            -- Stop this companion's sound if it's already playing to prevent annoying overlaps
                            if v.handle then
                                -- Users can allow overlapping sounds for hilarity
                                if not self.db.profile.enableOverlap == true then
                                    StopSound(v.handle)
                                end             
                            end

                            local willPlay, handle = PlaySoundFile(sound, soundChannel)
                            if willPlay then
                                v.handle = handle
                            end
                        end
                    end
                },
                stopSound = {
                    order = 70,
                    type = "execute",
                    width = "half",
                    name = "Stop",
                    func = function()
                        if v.handle then
                            StopSound(v.handle)
                        end
                    end
                },
                zones = {
                    order = 80,
                    type = "multiselect",
                    name = L["Zones"],
                    values = "GetZoneOptions",
                    tristate = true,
                    get = "GetCompanionMultiSelectConfig",
                    set = "SetCompanionMultiSelectConfig"
                },
                owners = {
                    order = 90,
                    type = "multiselect",
                    name = L["Owners"],
                    values = "GetOwnerOptions",
                    tristate = true,
                    get = "GetCompanionMultiSelectConfig",
                    set = "SetCompanionMultiSelectConfig"
                }
            }
        }

        root.args.companions.args[k] = node
    end

    root.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db);

    return root
end

function BronCena:GetMultiSelectConfig(info, key)
    self:Debug("GetMultiSelectConfig %s, %s", info[#info], tostring(key))
    return self.db.profile[info[#info]][key]
end

function BronCena:SetMultiSelectConfig(info, key, value)
    self:Debug("SetMultiSelectConfig %s.%s=%s", info[#info], key, tostring(value))
    self.db.profile[info[#info]][key] = value
end

function BronCena:GetConfig(info)
    self:Debug("GetConfig %s", tostring(info[#info]))
    --self:Debug("GetConfig %s", tostring(info[#info]))
    return self.db.profile[info[#info]]
end

function BronCena:SetConfig(info, value)
    self:Debug("SetConfig %s=%s", tostring(info[#info]), tostring(value))
    self.db.profile[info[#info]] = value
    self:ApplyOptions()
end

function BronCena:GetCompanionConfig(info)
    local id = info[#info-1]
    local companion = self.db.profile.companions[id]
    if companion then
        self:Debug("GetCompanionConfig %s", tostring(info[#info]))
        return companion[info[#info]]
    end
end

function BronCena:SetCompanionConfig(info, value)
    local id = info[#info-1]
    local companion = self.db.profile.companions[id]
    self:Debug("SetCompanionConfig companion.%s=%s", tostring(info[#info]), tostring(value))
    companion[info[#info]] = value
end

function BronCena:GetCompanionMultiSelectConfig(info, key)
    local id = info[#info-1]
    local companion = self.db.profile.companions[id]
    if companion then
        self:Debug("GetCompanionMultiSelectConfig %s.%s", tostring(info[#info]), tostring(key))
        return companion[info[#info]][key]
    end
end

function BronCena:SetCompanionMultiSelectConfig(info, key, value)
    local id = info[#info-1]
    local companion = self.db.profile.companions[id]
    self:Debug("SetCompanionMultiSelectConfig companion.%s.%s=%s", tostring(info[#info]), tostring(key), tostring(value))
    companion[info[#info]][key] = value
end

function BronCena:ApplyOptions()

    -- Do we need to toggle visibility of the draggable anchor frame?
    if not BronCenaMessageAnchor:IsVisible() == self.db.profile.unlocked then
        self:Debug("Unlocked status was changed")
        if self.db.profile.unlocked == true then
            BronCenaMessageAnchor:Show()
        else
            BronCenaMessageAnchor:Hide()
        end
    end
end

function BronCena:SoundChannels()
    return soundChannels
end

function BronCena:GetSoundOptions()
    if self.sharedSoundOptions == nil then
        self.sharedSoundOptions = {
            -- Place our BronCena options at the top
            [soundOptions.custom] = soundOptions.custom,
            [soundOptions.broncena] = soundOptions.broncena,
            [soundOptions.broncenafull] = soundOptions.broncenafull,
            [soundOptions.shoryuken] = soundOptions.shoryuken,
            [soundOptions.shouryureppa] = soundOptions.shouryureppa,
            [soundOptions.metalgear] = soundOptions.metalgear,
            [soundOptions.yaketysax] = soundOptions.yaketysax,
            [soundOptions.darkness] = soundOptions.darkness,
        };

        -- Now we add all the non-BronCena sounds from shared media
        for k,v in pairs(LSM:HashTable(SOUND)) do
            if not string.find(k, "BronCena") then
                self.sharedSoundOptions[k] = k
            end
        end
    end

    return self.sharedSoundOptions
end

function BronCena:GetZoneOptions()
    return {
        party = L["Dungeon"],
        raid = L["Raid"],
        pvp = L["PvP"],
        arena = L["Arena"],
        scenario = L["Scenario"],
        world = L["World"],
    }
end

function BronCena:GetZoneValues(info, key)
    return self.db.profile.zones[key]
end

function BronCena:SetZoneValues(info, key, value)
    self.db.profile.zones[key] = value;
end

function BronCena:GetOwnerOptions()
    return {
        player = L["Player"],
        party = L["Party"],
        raid = L["Raid"],
        friendly = L["Friendly"],
        hostile = L["Hostile"]
    }
end

function BronCena:GetOwnerValues(info, key)
    return self.db.profile.owners[key]
end

function BronCena:SetOwnerValues(info, key, value)
    self.db.profile.owners[key] = value;
end

function BronCena:OnInitialize()

    if self.isInitialized == true then
        return
    end

    self.db = LibStub("AceDB-3.0"):New("BronCenaDB", defaults, true)

    LSM:Register(SOUND, soundOptions.broncena, "Interface/AddOns/BronCena/Media/Sounds/broncena.ogg")
    LSM:Register(SOUND, soundOptions.broncenafull, "Interface/AddOns/BronCena/Media/Sounds/broncena-full.ogg")
    LSM:Register(SOUND, soundOptions.shoryuken, "Interface/AddOns/BronCena/Media/Sounds/shoryuken.ogg")
    LSM:Register(SOUND, soundOptions.shouryureppa, "Interface/AddOns/BronCena/Media/Sounds/shouryureppa.ogg")
    LSM:Register(SOUND, soundOptions.metalgear, "Interface/AddOns/BronCena/Media/Sounds/metalgear.ogg")
    LSM:Register(SOUND, soundOptions.yaketysax, "Interface/AddOns/BronCena/Media/Sounds/yakety-sax.ogg")
    LSM:Register(SOUND, soundOptions.darkness, "Interface/AddOns/BronCena/Media/Sounds/darkness.ogg")

    if self.options == nil then
        self.options = self:InitializeOptions(options)
        LibStub("AceConfig-3.0"):RegisterOptionsTable(APPNAME, options)
        self.optionsFrame = ACD:AddToBlizOptions(APPNAME, APPDESC)
    end

    self:ApplyOptions()

    self:RegisterChatCommand("broncena", "ChatCommand")
    self:RegisterChatCommand("bron", "ChatCommand")

    self.isInitialized = true
end

function BronCena:ChatCommand()
    self:Debug("/bron or /broncena was invoked")
    InterfaceOptionsFrame_OpenToCategory(APPDESC)
    InterfaceOptionsFrame_OpenToCategory(APPDESC)
end

function BronCena:OnEnable()
    BronCena:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    BronCena:RegisterEvent("PLAYER_LEVEL_UP")
    if self.parsingTooltip == nil then
        self.parsingTooltip = CreateFrame("GameTooltip", APPNAME.."Tooltip", WorldFrame, "GameTooltipTemplate")
    end
end

function BronCena:OnDisable()
    self:Debug("OnDisable")
    BronCena:UnregisterEvent("PLAYER_LEVEL_UP")
    BronCena:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

local getOwner = function(sourceFlags)
    if sourceFlags == nill then return nill end
    if bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE then return "hostile" end
    if bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_PARTY) == COMBATLOG_OBJECT_AFFILIATION_PARTY then return "party" end
    if bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_RAID) == COMBATLOG_OBJECT_AFFILIATION_RAID then return "raid" end
    if bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) == COMBATLOG_OBJECT_AFFILIATION_MINE then return "player" end
    if bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) == COMBATLOG_OBJECT_AFFILIATION_OUTSIDER then return "friendly" end
    return nil
end

function BronCena:PLAYER_LEVEL_UP(subevent, newLevel)
    self:TriggerBron(1, subevent, tostring(newLevel), nil)
end

function BronCena:COMBAT_LOG_EVENT_UNFILTERED(...)
	local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName = CombatLogGetCurrentEventInfo()
    self:TriggerBron(spellId, subevent, destName, sourceFlags)
end

function BronCena:TriggerBron(spellId, subevent, destName, sourceFlags)

    if self.db.profile.disabled == true then
        --self:Debug("Add-on is disabled")
        return
    end

    -- See if this spellId is supported
    local companion = self.db.profile.companions[tostring(spellId)]

    if not companion then
        return
    elseif companion.disabled == true then
        self:Debug("Disabled for this companion")
        return
    end

    if companion.eventType ~= subevent then
        -- The type of event doesn't match what we want, so skip this
        return
    end
    
    -- Spell blocklist (Consecration)
    if spellId == 26573 then
        return
    end

    -- Types: "Creature", "Pet", "GameObject", "Vehicle", "Vignette" 
    -- [unitType]-0-[serverID]-[instanceID]-[zoneUID]-[ID]-[spawnUID]
    -- local unitID = tonumber(string.match(unitGUID, "Creature%-.-%-.-%-.-%-.-%-(.-)%-"));

    local owner = getOwner(sourceFlags);
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
