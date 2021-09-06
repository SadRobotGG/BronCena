
local _, ns = ...

local APPNAME = "BronCena"
local APPDESC = "Bron Cena"

BronCena = LibStub("AceAddon-3.0"):NewAddon(APPNAME, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(APPNAME)
local LSM = LibStub("LibSharedMedia-3.0")
local ACD = LibStub("AceConfigDialog-3.0")

-- Library constants
local SOUND = LSM.MediaType and LSM.MediaType.SOUND or "sound"

local CHANNEL_DEFAULT = "Dialog"

local playerGUID = UnitGUID("player")

-- Hidden tooltip used to parse summoned unit tooltips for things like name
local parsingTooltip = nil;

local soundOptions = {
    custom = "<Custom Sound>",
    random = "BronCena: Surprise me! (Random)",
    broncena = "BronCena: Default",
    broncenafull = "BronCena: Full Length",
    shoryuken = "BronCena: Shoryuken",
    shouryureppa = "BronCena: Shouryureppa",
    metalgear = "BronCena: Metal Gear Alert"
}

local soundChannels =  {
    ["Default"] = "Default",
    ["Ambience"] = "Ambience",
    ["Dialog"] = "Dialog",
    ["Master"] = "Master",
    ["Music"] = "Music",
    ["SFX"] = "Sound"
}

function BronCena:Verbose(...)
    if self.db.profile.verbose == false then return end
    self:Printf(...)
end

function BronCena:Debug(...)
    if self.db.profile.debug == false then return end
    self:Printf(...)
end

local function ActionDefaults(...)
    local name, soundId, message, delay = ...
    return {
        disabled = false,
        name = name or nil,
        zones = { party = nil, raid = nil, pvp = nil, arena = nil, scenario = nil, world = nil },
        owners = { player = nil, party = nil, raid = nil, friendly = nil, hostile = nil },
        delay = delay or nil,
        soundDisabled = false,
        soundId = soundId or nil,
        soundPath = nil,
        soundChannel = nil,
        message = message or nil,
        messageDisabled = false
    }
end

local function CompanionDefaults(id, name, desc, action)
    return {
        id = id,
        name = name,
        desc = desc,
        disabled = false,
        actions = {
            ["action1"] = action
        }
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
        channel = CHANNEL_DEFAULT, -- Default sound channel

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
            ["333961"] = CompanionDefaults("333961", "Bron Cena", "", ActionDefaults("Bron's Theme", soundOptions.broncena, "And his name is BRON CENA!")),
            ["324739"] = CompanionDefaults("324739", "Kyrian Steward", "", ActionDefaults("Wild Steward", soundOptions.metalgear, "A wild %s appears!", 0.5))
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
                        debug = {
                            order = 30,
                            type = "toggle",
                            name = L["Debug"],
                            desc = L["Enables or disables debug logging"]
                        },                        
                        channel = {
                            order = 30,
                            type = "select",
                            name = L["Channel"],
                            desc = L["Default sound channel"],
                            values = "SoundChannels"
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
                    name = "Choose a companion to edit"
                },
                add = {
                    name = "Add",
                    desc = "Add a new companion",
                    type = "execute"
                },
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
                    order = 10,
                    width = "half",
                    type = "input",
                    name = "ID",
                    desc = "The spell identifier that summons this companion",
                    get = function ()
                        return v.id
                    end
                },
                name = {
                    order = 20,
                    type = "input",
                    name = "Name",
                    desc = "Edit the name for this companion",
                    get = function ()
                        return v.name
                    end
                },
                actions = {
                    order = 25,
                    type = "group",
                    --inline = true,
                    name = "Actions",
                    desc = "Actions",
                    args = {
                        add = {
                            name = "Add",
                            desc = "Add an action",
                            type = "execute"
                        },
                    },
                    childGroups = "tree"
                }
            }
        }

        local order = 30;
        local nextOrder = function()
            order = order + 1
            return order
        end

        for actionName, actionValue in pairs(v.actions) do

            local action = {

                header = {
                    order = nextOrder(),
                    type = 'header',
                    name = actionName
                },

                soundChannel = {
                    order = nextOrder(),
                    type = "select",
                    name = L["Channel"],
                    desc = L["Default sound channel"],
                    values = "SoundChannels",
                    get = function (info) return actionValue.soundChannel end,
                    set = function (info, value) actionValue.soundChannel = value end
                },
                
                soundId = {
                    order = nextOrder(),
                    type = "select",
                    name = "Sound",
                    desc = "The sound to play",
                    values = "GetSoundOptions",
                    get = function (info) return actionValue.soundId end,
                    set = function (info, value)
                        self:Debug("Set soundId to %s", tostring(value))
                        actionValue.soundId = value
                    end
                },
                
                soundPath = {
                    order = nextOrder(),
                    type = "input",
                    name = "Path",
                    desc = "The sound to play",
                    width = "full",
                    get = function (info)
                        if tostring(actionValue.soundId) == tostring(soundOptions.custom) then
                            return actionValue.soundPath
                        else
                            self:Debug("Fetching %s", actionValue.soundId)
                            return tostring(LSM:Fetch(LSM.MediaType.SOUND, actionValue.soundId, false) or actionValue.soundId)
                        end
                    end,
                    set = function (info, value) 
                        actionValue.soundPath = tostring(value)
                    end,
                    disabled = function ()
                        self:Debug("soundId=%s", actionValue.soundId)

                        if tostring(actionValue.soundId) == tostring(soundOptions.custom) then
                            return false
                        else
                            return true
                        end
                    end
                },

                playSound = {
                    order = nextOrder(),
                    type = "execute",
                    width = "half",
                    name = "Play",
                    func = function()

                        -- Default to the custom path
                        local sound = actionValue.soundPath

                        -- If we're using a selected option, we have to find the path / soundkit id
                        if tostring(actionValue.soundId) == tostring(soundOptions.custom) then
                            self:Debug("Using custom sound path")
                        else
                            self:Debug("Shared media id: %s", tostring(actionValue.soundId))
                            sound = LSM:Fetch(LSM.MediaType.SOUND, actionValue.soundId, false) or actionValue.soundId
                        end

                        self:Debug("Playing %s", sound)
                        local willPlay, handle = PlaySoundFile(sound, actionValue.soundChannel or CHANNEL_DEFAULT)
                        if willPlay then
                            actionValue.handle = handle
                        end
                    end
                },

                stopSound = {
                    order = nextOrder(),
                    type = "execute",
                    width = "half",
                    name = "Stop",
                    func = function()
                        if actionValue.handle then
                            StopSound(actionValue.handle)
                        end
                    end
                },

                zones = {
                    order = nextOrder(),
                    type = "multiselect",
                    name = L["Zones"],
                    values = "GetZoneOptions",
                    tristate = true,
                    -- set = "SetZoneValues"
                },
                owners = {
                    order = nextOrder(),
                    type = "multiselect",
                    name = L["Owners"],
                    values = "GetOwnerOptions",
                    tristate = true
                    -- get = "GetOwnerValues",
                    -- set = "SetOwnerValues"
                }
            }

            local groupAction = {
                name = actionName,
                type = "group",
                --inline = true,
                args = action
            }

            node.args.actions.args[actionName] = groupAction;
            -- node.args[actionName.."-header"] = action.header
            -- node.args[actionName.."-soundChannel"] = action.soundChannel
            -- node.args[actionName.."-soundId"] = action.soundId
            -- node.args[actionName.."-soundPath"] = action.soundPath
            -- node.args[actionName.."-soundPlay"] = action.playSound
            -- node.args[actionName.."-soundStop"] = action.stopSound
            -- node.args[actionName.."-zones"] = action.zones
            -- node.args[actionName.."-owners"] = action.owners

        end

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

function BronCena:GetCompanionConfig(info, key)
    local id = info[#info-1]
    local companion = self.db.profile.companions[id]
    self:Debug("GetCompanionConfig %s=%s", tostring(info[#info-1]), tostring(key))
    if companion then
        if key then
            return companion[info[#info]][key]
        else
            return companion[info[#info]]
        end
    end
end

function BronCena:SetCompanionConfig(info, key, value)
    local id = info[#info-1]
    local companion = self.db.profile.companions[id]
    self:Debug("SetCompanionConfig %s=%s", tostring(info[#info]), tostring(value))
    self:Debug("value2=%s", tostring(value2))

    if value then
        companion[info[#info]][key] = value
    else
        companion[info[#info]] = key
    end

    self:ApplyOptions()
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
    return {
        ["Default"] = "Default",
        ["Ambience"] = "Ambience",
        ["Dialog"] = "Dialog",
        ["Master"] = "Master",
        ["Music"] = "Music",
        ["SFX"] = "Sound"
    }
end

function BronCena:GetSoundOptions()

    local values = {
        -- Place our BronCena options at the top
        [soundOptions.custom] = soundOptions.custom,
        [soundOptions.broncena] = soundOptions.broncena,
        [soundOptions.broncenafull] = soundOptions.broncenafull,
        [soundOptions.shoryuken] = soundOptions.shoryuken,
        [soundOptions.shouryureppa] = soundOptions.shouryureppa,
        [soundOptions.metalgear] = soundOptions.metalgear,
    };

    -- Now we add all the non-BronCena sounds from shared media
    for k,v in pairs(LSM:HashTable(LSM.MediaType.SOUND)) do
        if not string.find(k, "BronCena") then
            values[k] = k
        end
    end

    --return LSM:List(LSM.MediaType.SOUND)
    return values
end

function BronCena:GetSoundOption(info, key)
    --return self.db.profile.sounds.player
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

    self.db = LibStub("AceDB-3.0"):New("BronCenaDB", defaults, true)

    LSM:Register(LSM.MediaType.SOUND, soundOptions.broncena, "Interface/AddOns/BronCena/Media/Sounds/broncena.ogg")
    LSM:Register(LSM.MediaType.SOUND, soundOptions.broncenafull, "Interface/AddOns/BronCena/Media/Sounds/broncena-full.ogg")
    LSM:Register(LSM.MediaType.SOUND, soundOptions.shoryuken, "Interface/AddOns/BronCena/Media/Sounds/shoryuken.ogg")
    LSM:Register(LSM.MediaType.SOUND, soundOptions.shouryureppa, "Interface/AddOns/BronCena/Media/Sounds/shouryureppa.ogg")
    LSM:Register(LSM.MediaType.SOUND, soundOptions.metalgear, "Interface/AddOns/BronCena/Media/Sounds/metalgear.ogg")

    self.media = LSM:HashTable(LSM.MediaType.SOUND)

    --self.profileOptions = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db);
    --LibStub("AceConfig-3.0"):RegisterOptionsTable(APPNAME, self.profileOptions, {"bron", "broncena"});

    options = self:InitializeOptions(options)

    LibStub("AceConfig-3.0"):RegisterOptionsTable(APPNAME, options)
    self.optionsFrame = ACD:AddToBlizOptions(APPNAME, APPDESC)

    --self.profileOptions = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db);
    --self.profileOptionsFrame = ACD:AddToBlizOptions("Bron Cena Profiles", "Profiles", self.optionsFrame);
    --LibStub("AceConfig-3.0"):RegisterOptionsTable(APPNAME, self.profileOptions, {"bron", "broncena"});

    self:ApplyOptions()
    
    self:RegisterChatCommand("broncena", "ChatCommand")
    self:RegisterChatCommand("bron", "ChatCommand")
    --self.profilesFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BronCena", "Profiles", APPDESC);

end

function BronCena:ChatCommand()
    self:Debug("/bron or /broncena was invoked")
    InterfaceOptionsFrame_OpenToCategory(APPDESC)
    InterfaceOptionsFrame_OpenToCategory(APPDESC)
end

function BronCena:OnEnable()
    self:Debug("OnEnable")
    BronCena:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    --BronCena:RegisterEvent("UNIT_AURA")

    self.parsingTooltip = CreateFrame("GameTooltip", APPNAME.."Tooltip", WorldFrame, "GameTooltipTemplate")
end

function BronCena:OnDisable()
    self:Debug("OnDisable")
    BronCena:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    --BronCena:RegisterEvent("UNIT_AURA")
end

function BronCena:UNIT_AURA(...)
    self:Print(...)
end

function BronCena:COMBAT_LOG_EVENT_UNFILTERED(...)

	local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName = CombatLogGetCurrentEventInfo()

    -- Could also use SPELL_AURA_APPLIED
	if subevent == "SPELL_SUMMON" then

        -- Spell blocklist (Consecration)
        if spellId == 26573 then
            return
        end

        if self.db.profile.disabled == true then
            self:Debug("Add-on is disabled")
            return
        end

        self:Debug("%s summoned %s using %s", tostring(sourceName), tostring(destName), tostring(spellName))

        self:ScheduleTimer(function (...)
            self.parsingTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
            self.parsingTooltip:SetHyperlink('unit:'..destGUID)
            local unitName = _G[APPNAME.."Tooltip".."TextLeft1"]:GetText()
            -- local unitId = tonumber(string.match(destGUID, "Creature%-.-%-.-%-.-%-.-%-(.-)%-"));
            self:Debug("Unit name=" .. tostring(unitName))
        end, 0.5)
        
        -- Types: "Creature", "Pet", "GameObject", "Vehicle", "Vignette" 
        -- [unitType]-0-[serverID]-[instanceID]-[zoneUID]-[ID]-[spawnUID]
        -- local unitID = tonumber(string.match(unitGUID, "Creature%-.-%-.-%-.-%-.-%-(.-)%-"));

        local companion = self.db.profile.companions[tostring(spellId)]

        -- Companion spell id not found
        if not companion then
            self:Debug("Couldn't find companion for %d", spellId)
            return
        elseif companion.disabled == true then
            self:Debug("Disabled for this companion")
        end

        local isHostile = bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE
        local isParty = bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_PARTY) == COMBATLOG_OBJECT_AFFILIATION_PARTY
        local isRaid = bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_RAID) == COMBATLOG_OBJECT_AFFILIATION_RAID
        local isMine = bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) == COMBATLOG_OBJECT_AFFILIATION_MINE
        local isOutsider = bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) == COMBATLOG_OBJECT_AFFILIATION_OUTSIDER
        
        self:Debug(string.format("isHostile=%s, isParty=%s, isRaid=%s, isMine=%s, isOutsider=%s", tostring(isHostile), tostring(isParty), tostring(isRaid), tostring(isMine), tostring(isOutsider)))

        if isMine == true and self.db.profile.owners.player == false then
            self:Debug("Disabled for player")
            return
        elseif isHostile == true and self.db.profile.owners.enemy == false then
            self:Debug("Disabled for hostile Brons")
            return
        elseif isRaid == true and self.db.profile.owners.raid == false then
            self:Debug("Disabled for raid")
            return
        elseif isParty == true and self.db.profile.owners.party == false then
            self:Debug("Disabled for party")
            return
        elseif isOutsider == true and self.db.profile.owners.friendly == false then
            self:Debug("Disabled for external friendly Brons")
            return
        end

        local instanceName, instanceType, difficultyId, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceId, instanceGroupSize, lfgDungeonId = GetInstanceInfo()
        
        if not instanceType or instanceType == 'none' then
            instanceType = 'world';
            -- if self.db.profile.zones.world == false then
            --     self:Debug("Disabled for " .. instanceType)
            --     return
            -- end
        end

        -- else
            if self.db.profile.zones[instanceType] == false then
                self:Debug("Disabled for " .. instanceType)
                return
            end
        -- end

        -- Process each registered action for this companion
        for k,v in pairs(companion.actions) do
            
            local actionName = v.name or k
            self:Debug("Processing action %s", actionName)

            if v.disabled == true then
                self:Debug("Action %s is disabled", v.name or k)
            else
                if v.zones[instanceType] == false then
                    self:Debug("Disabled for " .. instanceType)
                    return
                end

                -- Figure out the sound to play
                self:Debug("soundPath=%s,soundId=%s", tostring(v.soundPath), tostring(v.soundId))

                -- Default to the custom path
                local sound = v.soundPath

                -- If we're using a selected option, we have to find the path / soundkit id
                if tostring(v.soundId) == tostring(soundOptions.custom) then
                    self:Debug("Using custom sound path")
                else
                    self:Debug("Shared media id: %s", tostring(v.soundId))
                    sound = LSM:Fetch(LSM.MediaType.SOUND, v.soundId, false) or v.soundId
                end

                -- Add the message
                local name = destName
                local message = string.format(v.message, name or "Unknown")
                BronCenaMessageFrame:AddMessage(message, 1.0, 1.0, 1.0, 53, 8);

                -- Play the sound
                self:Debug("Playing %s", tostring(sound))
                local willPlay, handle = PlaySoundFile(sound, v.channel or CHANNEL_DEFAULT)
            end
        end
	end
end