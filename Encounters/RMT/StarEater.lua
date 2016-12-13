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
local mod = core:NewEncounter("StarEater", 104, 0, 548)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", { "Star-Eater the Voracious" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Star-Eater the Voracious"] = "Star-Eater the Voracious",
    ["Chaos Orb"] = "Chaos Orb",
	["Squirgling"] = "Squirgling",
    -- Datachron messages.
    
    -- Cast.
	["Hookshot"] = "Hookshot",
	["Shred"] = "Shred",
    ["Flamethrower"] = "Flamethrower",
    ["Chaos Orb"] = "Chaos Orb",
    ["Supernova"] = "Supernova",
	-- Bar and messages.
})
-- Default settings.
mod:RegisterDefaultSetting("CircleShredAlways")
mod:RegisterDefaultSetting("CircleShredDangerous")
mod:RegisterDefaultSetting("LineDangerousSquirg")
mod:RegisterDefaultSetting("CircleSquirgPuddles")
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
})

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local SHRED_OFFSETS = {
	["LEFT"] = Vector3.New(3.75, 0, 9),
	["RIGHT"] = Vector3.New(-3.75, 0, 9),
}

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local GetUnitById = GameLib.GetUnitById
local GetPlayerUnit = GameLib.GetPlayerUnit
local bWarnMidphase = false
local tSquirgWarningTimers = {}
local tSquirgPuddleTimers = {}
local tSquirgPuddlePositions = {}
local tSquirgPuddleRadii = {}
local tSquirgPuddleIds = {}
local nStarEaterId

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    mod:AddTimerBar("HOOKSHOT/SHRED", "HOOKSHOT/SHRED", 10, false)
end

function mod:OnUnitCreated(nId, tUnit, sName)
    local nHealth = tUnit:GetHealth()
    if sName == self.L["Star-Eater the Voracious"] then
        if nHealth then
            core:AddUnit(tUnit)
            core:WatchUnit(tUnit)
			nStarEaterId = nId
			if mod:GetSetting("CircleShredAlways") then
				mod:AddShredCircles("FFFF0000")
			end
        end
	elseif sName == self.L["Chaos Orb"] then
		core:AddUnit(tUnit)
		core:WatchUnit(tUnit)
	elseif sName == self.L["Squirgling"] then
		core:WatchUnit(tUnit)
		if mod:GetSetting("LineDangerousSquirg") then
			tSquirgWarningTimers[nId] = self:ScheduleTimer("WarnSquirglingExplosion", 30, nId)
		end
	end
end

function mod:OnHealthChanged(nId, nPercent, sName)
	if sName == self.L["Star-Eater the Voracious"] then
		if ((nPercent <= 67 and nPercent > 65) or (nPercent <= 37 and nPercent > 35)) and not bWarnMidphase then
			bWarnMidphase = true
			mod:AddMsg("MIDPHASE SOON", "MIDPHASE SOON", 3, false)
		end
	elseif sName == "Squirgling" and nPercent == 0 then
		if mod:GetSetting("LineDangerousSquirg") then
			core:RemoveLineBetweenUnits("PathToSquirgling" .. nId)
			self:CancelTimer(tSquirgWarningTimers[nId])
		end
		if mod:GetSetting("CircleSquirgPuddles") then
			table.insert(tSquirgPuddleIds, nId)
			tSquirgPuddlePositions[nId] = GetUnitById(nId):GetPosition()
			tSquirgPuddleRadii[nId] = 5
			core:AddPolygon("puddle_" .. nId, tSquirgPuddlePositions[nId], tSquirgPuddleRadii[nId], 0, 4, "FFFFFF00", 16)
			tSquirgPuddleTimers[nId] = self:ScheduleRepeatingTimer("IncreasePuddleRadius", 2, nId)
		end
	end
end

function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
	if sName == self.L["Star-Eater the Voracious"] then
		if sCastName == self.L["Hookshot"] then
			mod:AddTimerBar("HOOKSHOT/SHRED", "HOOKSHOT/SHRED", 30, false)
			if mod:GetSetting("CircleShredAlways") then
				self:ScheduleTimer("AddShredCircles", 5, "FF00FF00")
			end
			self:ScheduleTimer("AddShredCircles", 25, "FFFF0000")
		elseif sCastName == self.L["Flamethrower"] then
			mod:RemovePuddleCircles()
		elseif sCastName == self.L["Supernova"] then
			mod:RemovePuddleCircles()
			bWarnMidphase = false
		end
	end
end

function mod:OnCastEnd(nId, sCastName, bInterrupted, nCastEndTime, sName)
	if sName == self.L["Star-Eater the Voracious"] then
		if sCastName == self.L["Shred"] then
			if not mod:GetSetting("CircleShredAlways") then
				mod:RemoveShredCircles()
			end
		end
	end
end

function mod:AddShredCircles(sColor)
	core:AddOffsetPolygon("shred_1", nStarEaterId, SHRED_OFFSETS["LEFT"], 10.5, 0, 4, sColor, 16)
	core:AddOffsetPolygon("shred_2", nStarEaterId, SHRED_OFFSETS["RIGHT"], 10.5, 0, 4, sColor, 16)
end

function mod:RemoveShredCircles()
	core:RemovePolygon("shred_1")
	core:RemovePolygon("shred_2")
end

function mod:RemovePuddleCircles()
	for i = 1, #tSquirgPuddleIds do
		local nSquirgId = tSquirgPuddleIds[i]
		self:CancelTimer(tSquirgPuddleTimers[nSquirgId])
		core:RemovePolygon("puddle_" .. nSquirgId)
	end
	tSquirgPuddleTimers = {}
	tSquirgPuddlePositions = {}
	tSquirgPuddleRadii = {}
	tSquirgPuddleIds = {}
end

function mod:IncreasePuddleRadius(nId)
	tSquirgPuddleRadii[nId] = tSquirgPuddleRadii[nId] + 0.5
	core:AddPolygon("puddle_" .. nId, tSquirgPuddlePositions[nId], tSquirgPuddleRadii[nId], 0, 4, "FFFFFF00", 16)
	if tSquirgPuddleRadii[nId] >= 15 then
		self:CancelTimer(tSquirgPuddleTimers[nId])
		core:RemovePolygon("puddle_" .. nId)
	end
end

function mod:WarnSquirglingExplosion(nId)
	core:AddLineBetweenUnits("PathToSquirgling" .. nId, GetPlayerUnit():GetId(), nId, 6, "red")
end