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
local mod = core:NewEncounter("Skooty", 104, 548, 552)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", { "Assistant Technician Skooty" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Assistant Technician Skooty"] = "Assistant Technician Skooty",
	["Jumpstart Charge"] = "Jumpstart Charge",
    -- Datachron messages.
    -- Cast.
	["Batten Down the Hatches"] = "Batten Down the Hatches",
	-- Bar and messages.
})
-- Default settings.
mod:RegisterDefaultSetting("LineSkootyBomb")
--mod:RegisterDefaultSetting("OtherBombLocation")
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
})

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
 -- local BOMB_POSITIONS = {
    -- ["1"] = { x = 332.23, y = -196.45, z = -1081.70 },
    -- ["2"] = { x = 345.36, y = -196.45, z = -1075.94 },
    -- ["3"] = { x = 350.62, y = -196.45, z = -1062.88 },
    -- ["4"] = { x = 345.36, y = -196.45, z = -1049.85 },
    -- ["5"] = { x = 332.23, y = -196.45, z = -1044.64 },
    -- ["6"] = { x = 319.02, y = -196.45, z = -1049.88 },
    -- ["7"] = { x = 313.74, y = -196.45, z = -1062.88 },
    -- ["8"] = { x = 319.02, y = -196.45, z = -1075.94 },
 -- }

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local GetUnitById = GameLib.GetUnitById
local GetPlayerUnit = GameLib.GetPlayerUnit

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    -- mod:AddTimerBar("BOMBS/TETHERS", "BOMBS/TETHERS", 20, true)
end

function mod:OnUnitCreated(nId, tUnit, sName)
    local nHealth = tUnit:GetHealth()
    if sName == self.L["Assistant Technician Skooty"] then
        if nHealth then
            core:AddUnit(tUnit)
            core:WatchUnit(tUnit)
        end
	elseif sName == self.L["Jumpstart Charge"] and mod:GetSetting("LineSkootyBomb") then
		self:ScheduleTimer("AddLineDelayed", 6, nId)
	end
end

function mod:OnUnitDestroyed(nId, tUnit, sName)
    if sName == self.L["Jumpstart Charge"] and mod:GetSetting("LineSkootyBomb") then
        core:RemoveLineBetweenUnits("PathToBomb" .. nId)
    end
end

-- function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
	-- if sName == self.L["Assistant Technician Skooty"] then
		-- if sCastName == self.L["Batten Down the Hatches"] then
			-- mod:AddTimerBar("BOMBS/TETHERS", "BOMBS/TETHERS", 55, true)
		-- end
	-- end
-- end

function mod:AddLineDelayed(nId)
	local tUnit = GetUnitById(nId)
	if tUnit then
		core:AddLineBetweenUnits("PathToBomb" .. nId, GetPlayerUnit():GetId(), nId, 4, "red")
	end
end