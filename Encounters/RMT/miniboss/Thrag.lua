----------------------------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2015 RaidCore
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Description:
--   TODO
----------------------------------------------------------------------------------------------------
local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local mod = core:NewEncounter("Thrag", 104, 548, 552)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", { "Chief Engine Scrubber Thrag" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Chief Engine Scrubber Thrag"] = "Chief Engine Scrubber Thrag",
	["Jumpstart Charge"] = "Jumpstart Charge",
    -- Datachron messages.
    -- Cast.
	-- Bar and messages.
})
-- Default settings.
mod:RegisterDefaultSetting("LineThragBomb")
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
})

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local GetUnitById = GameLib.GetUnitById
local GetPlayerUnit = GameLib.GetPlayerUnit

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------

function mod:OnUnitCreated(nId, tUnit, sName)
    local nHealth = tUnit:GetHealth()
    if sName == self.L["Chief Engine Scrubber Thrag"] then
        if nHealth then
            core:AddUnit(tUnit)
            core:WatchUnit(tUnit)
        end
	elseif sName == self.L["Jumpstart Charge"] and mod:GetSetting("LineThragBomb") then
		core:AddLineBetweenUnits("PathToBomb" .. nId, GetPlayerUnit():GetId(), nId, 4, "red")
	end
end

function mod:OnUnitDestroyed(nId, tUnit, sName)
    if sName == self.L["Jumpstart Charge"] and mod:GetSetting("LineThragBomb") then
        core:RemoveLineBetweenUnits("PathToBomb" .. nId)
    end
end