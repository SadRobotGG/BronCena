
local _, ns = ...

local APPNAME = "BronCena"
local APPDESC = "Bron Cena"

BronCena = LibStub("AceAddon-3.0"):NewAddon(APPNAME, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(APPNAME)
local LSM = LibStub("LibSharedMedia-3.0")
local ACD = LibStub("AceConfigDialog-3.0")

local playerGUID = UnitGUID("player")

-- Hidden tooltip used to parse summoned unit tooltips for things like name
local parsingTooltip = nil;

local soundOptions = {
    random = "BronCena: Surprise me! (Random)",
    default = "BronCena: Default",
    shoryuken = "BronCena: Shoryuken",
    shouryureppa = "BronCena: Shouryureppa",
    metalgear = "BronCena: Metal Gear Alert"
}

function BronCena:Debug(...)
    if self.db.profile.debug == false then
        --return
    end

    self:Printf(...)
end

local function ZoneDefaults()
    return {
        party = true,
        raid = true,
        pvp = true,
        arena = true,
        scenario = true,
        world = true
    }
end

local function OwnerDefaults()
    return {
        disabled = false,
        zones = ZoneDefaults(),
        sound = nil,
        message = nil,
        channel = nil
    }
end

local function CompanionDefaults(spellId, name, sound, soundDelay, soundChannel, message, messageDelay)
    return {
        spellId = spellId,
        name = name,
        disabled = false,
        sound = sound or nil,
        soundDelay = soundDelay or nil,
        soundChannel = soundChannel or nil,
        channel = nil,
        message = message or nil,
        messageDelay = messageDelay or nil,
        player = OwnerDefaults(),
        party = OwnerDefaults(),
        raid = OwnerDefaults(),
        friendly = OwnerDefaults(),
        enemy = OwnerDefaults()
    }
end

local BuildTemplate = function(message, sound, messageDelay, soundDelay)
    return {
        message = message or nil,
        sound = sound or nil,
        messageDelay = messageDelay or nil,
        soundDelay = soundDelay or nil
    }
end

-- Companions
-- 324739 Summon Steward (unit: Steward)
--   ITEM_PUSH: 463534 (Phial of Serenity)
-- 221745 - Judgement's Gaze (Lothraxion)
-- UNIT_SPELLCAST_SUCCEEDED: Summoning pets

local defaults = {
    profile = {
        disabled = false,
        unlocked = false, -- Enable or disable dragging of the UI elements
        debug = false,
        sound = nil,
        channel = nil,
        message = nil,
        player = OwnerDefaults(),
        party = OwnerDefaults(),
        raid = OwnerDefaults(),
        friendly = OwnerDefaults(),
        enemy = OwnerDefaults(),
        companions = {
            [333961] = CompanionDefaults(333961, "Bron Cena", soundOptions.shoryuken, 0.5, nil, "And his name is BRON CENA!"),
            [324739] = CompanionDefaults(324739, "Kyrian Steward")
        },
        templates = {
            ["default"] = BuildTemplate("A wild %s appears!", soundOptions.metalgear, 0.5),
            ["bron"] = BuildTemplate("And his name is BRON CENA!", soundOptions.default)
        }
    }
}

local options = {
    name = APPDESC,
    handler = BronCena,
    type = "group",
    desc = APPDESC,
    get = "GetConfig",
    set = "SetConfig",
    args = {
        disabled = {
            order = 10,
            type = "toggle",
            name = L["Disabled"],
            desc = L["Disables or enables the addon"]
        },
        unlocked = {
            order = 10,
            type = "toggle",
            name = L["Unlock"],
            desc = L["Enables or disables moving UI"]
        },        
        debug = {
            order = 10,
            type = "toggle",
            name = L["Debug"],
            desc = L["Enables or disables debug logging"]
        },
    --     zones = {
    --         order = 20,
    --         type = "multiselect",
    --         name = L["Zones"],
    --         values = "GetZoneOptions",
    --         get = "GetZoneValues",
    --         set = "SetZoneValues"
    --     },
    --     owners = {
    --         order = 30,
    --         type = "multiselect",
    --         name = L["Owners"],
    --         values = "GetOwnerOptions",
    --         get = "GetOwnerValues",
    --         set = "SetOwnerValues"
    --     },
    --     sound = {
    --         order = 40,
    --         type = 'select',
    --         width = 'full',
    --         --dialogControl = 'LSM30_Sound', --Select your widget here
    --         name = 'Sound',
    --         desc = 'The sound file to play when Bron appears',
    --         values = "GetSoundOptions",
    --         get = "GetSoundOption",
    --         set = "SetSoundOption",
    --    }
    },
}

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

function BronCena:GetSoundOptions()

    local values = {};

    -- Place our BronCena options at the top
    table.insert(values,soundOptions.default)
    table.insert(values,soundOptions.shoryuken)
    table.insert(values,soundOptions.shouryureppa)
    table.insert(values,soundOptions.metalgear)

    for i,v in ipairs(LSM:List(LSM.MediaType.SOUND)) do
        if not string.find(v, "BronCena") then
            values[v] = v
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
        group = L["Group"],
        friendly = L["Friendly"],
        enemy = L["Enemy"]
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

    LSM:Register(LSM.MediaType.SOUND, soundOptions.default, "Interface/AddOns/BronCena/Media/Sounds/broncena.ogg")
    LSM:Register(LSM.MediaType.SOUND, soundOptions.shoryuken, "Interface/AddOns/BronCena/Media/Sounds/shoryuken.ogg")
    LSM:Register(LSM.MediaType.SOUND, soundOptions.shouryureppa, "Interface/AddOns/BronCena/Media/Sounds/shouryureppa.ogg")
    LSM:Register(LSM.MediaType.SOUND, soundOptions.metalgear, "Interface/AddOns/BronCena/Media/Sounds/metalgear.ogg")

    --self.profileOptions = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db);
    --LibStub("AceConfig-3.0"):RegisterOptionsTable(APPNAME, self.profileOptions, {"bron", "broncena"});

    LibStub("AceConfig-3.0"):RegisterOptionsTable(APPNAME, options)
    self.optionsFrame = ACD:AddToBlizOptions(APPNAME, APPDESC)

    self:ApplyOptions()
    
    self:RegisterChatCommand("broncena", "ChatCommand")
    self:RegisterChatCommand("bron", "ChatCommand")
    --self.profilesFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BronCena", "Profiles", APPDESC);

end

function BronCena:ChatCommand()
    self:Debug("/bron or /broncena was invoked")
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

        self:Debug("%s summoned %s using %s", sourceName, destName, spellName)

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

        local companion = self.db.profile.companions[spellId]

        -- Companion spell id not found
        if not companion then
            self:Debug("Couldn't find companion for %d", spellId)
            return
        elseif companion.disabled == true then
            self:Debug("Disabled for this companion")
        end

        local instanceName, instanceType, difficultyId, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceId, instanceGroupSize, lfgDungeonId = GetInstanceInfo()

        local isHostile = bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE
        local isParty = bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_PARTY) == COMBATLOG_OBJECT_AFFILIATION_PARTY
        local isRaid = bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_RAID) == COMBATLOG_OBJECT_AFFILIATION_RAID
        local isMine = bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) == COMBATLOG_OBJECT_AFFILIATION_MINE
        local isOutsider = bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) == COMBATLOG_OBJECT_AFFILIATION_OUTSIDER
        
        self:Debug(string.format("isHostile=%s, isParty=%s, isRaid=%s, isMine=%s, isOutsider=%s", tostring(isHostile), tostring(isParty), tostring(isRaid), tostring(isMine), tostring(isOutsider)))

        -- if not instanceType or instanceType == 'none' then
        --     if companion.zones.world == false then
        --         self:Debug("Disabled for " .. instanceType)
        --         return
        --     end
        -- else
        --     if self.db.profile.zones[instanceType] == false then
        --         self:Debug("Disabled for " .. instanceType)
        --         return
        --         end
        -- end

        -- Limit to just ours?
        if false then --sourceGUID == playerGUID then

            if companion.player.disabled == true then
                self:Debug("Skipping, player Bron is disabled")
                return
            end

            PlaySoundFile("Interface/AddOns/BronCena/Media/Sounds/broncena.ogg", "Dialog")
            --print("Your Bron appears!")
        else
            if isMine == true and companion.player.disabled == true then
                self:Debug("Disabled for player")
                return
            elseif isHostile == true and companion.enemy.disabled == true then
                self:Debug("Disabled for hostile Brons")
                return
            elseif isRaid == true and companion.raid.disabled == true then
                self:Debug("Disabled for raid")
                return
            elseif isParty == true and companion.party.disabled == true then
                self:Debug("Disabled for party")
                return
            elseif isOutsider == true and companion.friendly.disabled == true then
                self:Debug("Disabled for external friendly Brons")
                return
            end

            -- Get the message text
            -- sound = sound or nil,
            -- soundDelay = soundDelay or nil,
            -- soundChannel = soundChannel or nil,
            -- channel = nil,
            -- message = message or nil,
            -- messageDelay = messageDelay or nil,
            local msgFormat = companion.message or self.db.profile.templates.default.message
            self:Debug("Using format message: %s", tostring(msgFormat))
            local msg = string.format(msgFormat, "Unknown" )
            BronCenaMessageFrame:AddMessage(msg, 1.0, 1.0, 1.0, 53, 8);

            local soundValue = companion.sound or self.db.profile.templates.default.sound;

            soundValue = soundOptions[soundValue] or soundValue

            -- See if the sound can be found in shared media
            local sound = LSM:Fetch(LSM.MediaType.SOUND, soundValue, false)

            if sound == nil then
                sound = LSM:Fetch(LSM.MediaType.SOUND, soundOptions.default, false)
            end

            if sound == nil then
                self:Debug("Couldn't locate sound file for %s", tostring(sound))
            else
                local soundChannel = companion.channel or self.db.profile.templates.default.channel or "Dialog"

                if companion.soundDelay then
                    self:Debug("Delaying sound by %s", tostring(companion.soundDelay))
                    self:ScheduleTimer(function (...)
                        self:Debug("Playing sound %s on %s", sound, soundChannel)
                        PlaySoundFile(sound, soundChannel)
                    end, companion.soundDelay)
                else
                    self:Debug("Playing sound %s on %s", sound, soundChannel)
                    PlaySoundFile(sound, soundChannel)
                end


            end

            --print("A wild Bron appears!")
        end         
	end
end