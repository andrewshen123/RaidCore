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
local mod = core:NewEncounter("Engineers", 104, 548, 552)
local Log = Apollo.GetPackage("Log-1.0").tPackage
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", { "Head Engineer Orvulgh", "Chief Engineer Wilbargh", "Fusion Core", "Cooling Turbine", "Spark Plug", "Lubricant Nozzle" })
--mod:RegisterTrigMob("ANY", { "Head Engineer Orvulgh", "Chief Engineer Wilbargh" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Head Engineer Orvulgh"] = "Head Engineer Orvulgh",
    ["Chief Engineer Wilbargh"] = "Chief Engineer Wilbargh",
	["Fusion Core"] = "Fusion Core",
	["Cooling Turbine"] = "Cooling Turbine",
    ["Spark Plug"] = "Spark Plug",
    ["Lubricant Nozzle"] = "Lubricant Nozzle",
    ["Discharged Plasma"] = "Discharged Plasma",
    -- Datachron messages.
    -- Cast.
	["Liquidate"] = "Liquidate",
	["Rocket Jump"] = "Rocket Jump",
	["Electroshock"] = "Electroshock",
	["Ignition Spark"] = "Ignition Spark",
    -- Bar and messages.
})
-- Default settings.
mod:RegisterDefaultSetting("TimerAll", false)
mod:RegisterDefaultSetting("LineSwordCleave")
mod:RegisterDefaultSetting("AlertElectroshock")
mod:RegisterDefaultSetting("AlertOrb")
mod:RegisterDefaultSetting("AlertSwordJumping")
mod:RegisterDefaultSetting("AlertGunJumping")
mod:RegisterDefaultSetting("AlertOrbStacksSelf")
mod:RegisterDefaultSetting("AlertOrbStacksOther")
mod:RegisterDefaultSetting("AlertAllLowCore", false)
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
	["SAFE FIRE SWITCH"] = { sColor = "xkcdBloodRed" },
	["IGNITION SPARK"] = { sColor = "FF33FFFF" },
	["NEXT ORB"] = { sColor = "FFE65C00" },
})

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local DEBUFFID_ELECTROSHOCKVULNERABILITY = 83798
local DEBUFFID_ATOMICATTRACTION = 84053
local BUFFID_DIMINISHINGFUSIONREACTION = 87214
local PLATFORM_BOUNDING_BOXES = {
	["Cooling Turbine"] = { x_min = 249.19, x_max = 374.71, z_min = -893.52, z_max = -768.06 },
    ["Spark Plug"] = { x_min = 374.71, x_max = 500.23, z_min = -893.52, z_max = -768.06 },
    ["Lubricant Nozzle"] = { x_min = 374.71, x_max = 500.23, z_min = -1018.96, z_max = -893.52 },
    ["Fusion Core"] = { x_min = 249.19, x_max = 374.71, z_min = -1018.96, z_max = -893.52 }
}

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local GetUnitById = GameLib.GetUnitById
local GetPlayerUnit = GameLib.GetPlayerUnit
local tCores
local tCoreWarnings
local tCoreHPIndicators
local bOrbOnMe

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    if mod:GetSetting("TimerAll") then
		mod:AddTimerBar("LIQUIDATE", "LIQUIDATE", 12, false)
		mod:AddTimerBar("ELECTROSHOCK", "ELECTROSHOCK", 12, false)
	
		mod:SafeFireSwitch()
	end
	
	bOrbOnMe = false
	tCoreWarnings = { ["Spark Plug"] = false, ["Cooling Turbine"] = false, ["Lubricant Nozzle"] = false, ["Fusion Core"] = false }
	tCoreHPIndicators = { ["Spark Plug"] = nil, ["Cooling Turbine"] = nil, ["Lubricant Nozzle"] = nil, ["Fusion Core"] = nil }
	
	-- Hardcoded because I'm lazy. If it ever breaks, I'll fix it.
	local nEventId = 0
	local nNumEvents = #PublicEvent.GetActiveEvents()
	for nEventId = 1, nNumEvents do
		if PublicEvent.GetActiveEvents()[nEventId]:GetName() == "Redmoon Terror" then
			break
		end
	end
	core:AddCustom("Engine Heat", 0, 100, function() return PublicEvent.GetActiveEvents()[nEventId]:GetObjectives()[38]:GetCount() end, "FFFF0000")
	core:AddCustom("Spark Plug", 0, 6000000, function() return PublicEvent.GetActiveEvents()[nEventId]:GetObjectives()[46]:GetCount() * 60000 end, "FF33FFFF")
	core:AddCustom("Cooling Turbine", 0, 6000000, function() return PublicEvent.GetActiveEvents()[nEventId]:GetObjectives()[47]:GetCount() * 60000 end, "FFFFFFFF")
	core:AddCustom("Lubricant Nozzle", 0, 6000000, function() return PublicEvent.GetActiveEvents()[nEventId]:GetObjectives()[48]:GetCount() * 60000 end, "FF5900B3")
	core:AddCustom("Fusion Core", 0, 6000000, function() return PublicEvent.GetActiveEvents()[nEventId]:GetObjectives()[49]:GetCount() * 60000 end, "FFE65C00")
end

function mod:SafeFireSwitch()
    mod:AddTimerBar("SAFE FIRE SWITCH", "SAFE FIRE SWITCH", 15, false)
	self:ScheduleTimer("SafeFireSwitch", 15)
end

function mod:PersistDelayedUnits()
	return true -- this function has to exist so that OnEncounterHookGenericUnsafe doesn't error
end

function mod:OnUnitCreated(nId, tUnit, sName)
	if sName == self.L["Head Engineer Orvulgh"] then
        core:AddUnit(tUnit)
        core:WatchUnit(tUnit)
    elseif sName == self.L["Chief Engineer Wilbargh"] then
        core:AddUnit(tUnit)
        core:WatchUnit(tUnit)
		if mod:GetSetting("LineSwordCleave") then
			core:AddSimpleLine("swordcleave_1", nId, 3, 15, -60, 4, "xkcdBrightRed", nil)
			core:AddSimpleLine("swordcleave_2", nId, 3, 15, 60, 4, "xkcdBrightRed", nil)
		end
	elseif sName == self.L["Fusion Core"] or sName == self.L["Cooling Turbine"] or sName == self.L["Spark Plug"] or sName == self.L["Lubricant Nozzle"] then
		tCores = tCores or {}
		tCores[sName] = tUnit
		core:WatchUnit(tUnit)
	elseif sName == self.L["Discharged Plasma"] then
		mod:AddTimerBar("NEXT ORB", "NEXT ORB", 24, true)
		core:WatchUnit(tUnit)
	end
end

function mod:OnBuffUpdate(nId, nSpellId, nNewStack, fTimeRemaining)
	if nSpellId == BUFFID_DIMINISHINGFUSIONREACTION then
		if (bOrbOnMe and mod:GetSetting("AlertOrbStacksSelf")) or mod:GetSetting("AlertOrbStacksOther") then
			mod:AddMsg("ORB STACKS", "ORB " .. nNewStack .. " STACKS!", 3, false)
		end
	end
end

function mod:OnDebuffAdd(nId, nSpellId, nStack, fTimeRemaining)
	if nId == GetPlayerUnit():GetId() then
		if nSpellId == DEBUFFID_ELECTROSHOCKVULNERABILITY then
			mod:AddMsg("ELECTROSHOCK ON YOU", "ELECTROSHOCK ON YOU", 3, mod:GetSetting("AlertElectroshock") and "Inferno" )
		elseif nSpellId == DEBUFFID_ATOMICATTRACTION then
			mod:AddMsg("ORB ON YOU", "ORB ON YOU", 3, mod:GetSetting("AlertOrb") and "RunAway")
			bOrbOnMe = true
		end
	end
	if nSpellId == DEBUFFID_ELECTROSHOCKVULNERABILITY then
		core:AddPicture("ES" .. nId, nId, "Crosshair", 20)
	end
end

function mod:OnDebuffRemove(nId, nSpellId)
	if nId == GetPlayerUnit():GetId() then
		if nSpellId == DEBUFFID_ELECTROSHOCKVULNERABILITY then
			mod:AddMsg("ELECTROSHOCK FADED", "ELECTROSHOCK FADED", 3, "Alert")
		elseif nSpellId == DEBUFFID_ATOMICATTRACTION then
			bOrbOnMe = false
		end
	end
	if nSpellId == DEBUFFID_ELECTROSHOCKVULNERABILITY then
		core:RemovePicture("ES" .. nId)
	end
end

function mod:OnHealthChanged(nId, nPercent, sName)
	if sName == self.L["Fusion Core"] or sName == self.L["Cooling Turbine"] or sName == self.L["Spark Plug"] or sName == self.L["Lubricant Nozzle"] then
		if nPercent <= 16 and not tCoreWarnings[sName] then
			tCoreWarnings[sName] = true
			if mod:GetSetting("AlertAllLowCore") or mod:GetPlatform(GetPlayerUnit()) == sName then
				mod:AddMsg("CORE LOW " .. sName, "STOP ON " .. sName, 3, "Beware")
			end
		elseif nPercent >= 19 and tCoreWarnings[sName] then
			tCoreWarnings[sName] = false
		end
		if nPercent <= 15 and tCoreHPIndicators[sName] ~= "red" then
			core:AddPolygon("HP" .. nId, GetUnitById(nId):GetPosition(), 8, 0, 6, "FFFF0000", 16)
			tCoreHPIndicators = "red"
		elseif nPercent <= 22 and tCoreHPIndicators[sName] ~= "yellow" then
			core:AddPolygon("HP" .. nId, GetUnitById(nId):GetPosition(), 8, 0, 6, "FFFFFF00", 16)
			tCoreHPIndicators = "yellow"
		elseif tCoreHPIndicators[sName] ~= "green" then
			core:AddPolygon("HP" .. nId, GetUnitById(nId):GetPosition(), 8, 0, 6, "FF00FF00", 16)
			tCoreHPIndicators = "green"
		end
	end
end

function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
	if sName == self.L["Chief Engineer Wilbargh"] then
		if sCastName == self.L["Liquidate"] and mod:GetSetting("TimerAll") then
			bLiquidateQueued = false
			mod:AddTimerBar("LIQUIDATE", "LIQUIDATE", 25, false)
		elseif sCastName == self.L["Rocket Jump"] then
			local sCurrentPlatform = mod:GetPlatform(GetUnitById(nId))
			if mod:GetSetting("AlertSwordJumping") then
				mod:AddMsg("SWORD JUMPING", "Sword leaving " .. sCurrentPlatform, 3, false)
			end
			self:ScheduleTimer("CheckArrivalPlatform", 3, GetUnitById(nId))
		end
	elseif sName == self.L["Head Engineer Orvulgh"] then
		if sCastName == self.L["Electroshock"] then
			core:AddSimpleLine("ElectroshockFacing", nId, 0, 75, 0, 4, "xkcdBrightRed", nil)
			if  mod:GetSetting("TimerAll") then
				mod:AddTimerBar("ELECTROSHOCK", "ELECTROSHOCK", 20, false)
			end
		elseif sCastName == self.L["Rocket Jump"] then
			local sCurrentPlatform = mod:GetPlatform(GetUnitById(nId))
			if mod:GetSetting("AlertGunJumping") then
				mod:AddMsg("GUN JUMPING", "Gun leaving " .. sCurrentPlatform, 3, false)
			end
			self:ScheduleTimer("CheckArrivalPlatform", 3, GetUnitById(nId))
		end
	elseif sName == self.L["Spark Plug"] then
		if sCastName == self.L["Ignition Spark"] then
			mod:AddTimerBar("IGNITION SPARK", "IGNITION SPARK", 12, false)
		end
	end
end

function mod:OnCastEnd(nId, sCastName, bIsInterrupted, nCastEndTime, sName)
	if sName == self.L["Head Engineer Orvulgh"] then
		if sCastName == self.L["Electroshock"] then
			core:RemoveSimpleLine("ElectroshockFacing")
		end
	end
end

function mod:CheckArrivalPlatform(tUnit)
	local sCurrentPlatform = mod:GetPlatform(tUnit)
	if sCurrentPlatform == "Fusion Core" then
		mod:AddTimerBar("NEXT ORB", "NEXT ORB", 21, true)
	-- elseif sCurrentPlatform == "Spark Plug" then
		-- mod:AddTimerBar("IGNITION SPARK", "IGNITION SPARK", 9, false)
	end
end

function mod:GetPlatform(tUnit)
	local loc = tUnit:GetPosition()
	if not loc then return nil end
	for k,v in pairs(PLATFORM_BOUNDING_BOXES) do
		if v.x_min <= loc.x and loc.x <= v.x_max and v.z_min <= loc.z and loc.z <= v.z_max then
			return k
		end
	end
	return nil
end