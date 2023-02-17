function BronCena:InitializeOptions(root)

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
    return BronCena.soundChannels;
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