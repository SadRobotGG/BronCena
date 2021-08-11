
local _, ns = ...

local playerGUID = UnitGUID("player")

local f = CreateFrame("Frame")
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
f:SetScript("OnEvent", function(self, event)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
	    self:COMBAT_LOG_EVENT_UNFILTERED(CombatLogGetCurrentEventInfo())
    end
end)

function f:COMBAT_LOG_EVENT_UNFILTERED(...)
	local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId = ...
	
	if subevent == "SPELL_SUMMON" then
        if spellId == 333961 then

            -- Limit to just ours?
            if sourceGUID == playerGUID then
                PlaySoundFile("Interface/AddOns/BronCena/Media/Sounds/broncena.ogg")
                --print("Your Bron appears!")
            else
                PlaySoundFile("Interface/AddOns/BronCena/Media/Sounds/broncena.ogg")
                --print("A wild Bron appears!")
            end            
        end
	end
end