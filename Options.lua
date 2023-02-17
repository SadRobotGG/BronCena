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