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
local mod = core:NewEncounter("Mordechai", 104, 0, 548)
local Log = Apollo.GetPackage("Log-1.0").tPackage
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", { "Mordechai Redmoon" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Mordechai Redmoon"] = "Mordechai Redmoon",
	["Kinetic Orb"] = "Kinetic Orb",
	["Airlock Anchor"] = "Airlock Anchor",
	["Shoryu Ken"] = "Ignores Collision Big Base Invisible Unit for Spells (1 hit radius)",
	["Orb Spawn Telegraph"] = "Hostile Invisible Unit for Fields (0 hit radius)",
    -- Datachron messages.
	["Airlock Closed"] = "The airlock has been closed!",
    -- Cast.
	["Shatter Shock"] = "Shatter Shock",
	["Vicious Barrage"] = "Vicious Barrage",
    -- Bar and messages.
})
-- Default settings.
mod:RegisterDefaultSetting("LineCleave")
mod:RegisterDefaultSetting("LineTank")
mod:RegisterDefaultSetting("MarkerStackMid")
mod:RegisterDefaultSetting("CountdownOrb", false)
mod:RegisterDefaultSetting("StreetFighter", false)
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["SHORYU KEN"] = { sColor = "xkcdBloodOrange" },
})

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local DEBUFFID_KINETICLINK = 86797
local DEBUFFID_SHOCKINGATTRACTION = 86861
local CLEAVE_OFFSETS = {
	["FRONT_LEFT"] = Vector3.New(4.5, 0, 3),
	["FRONT_RIGHT"] = Vector3.New(-4.5, 0, 3),
	["BACK_LEFT"] = Vector3.New(-4.5, 0, -3),
	["BACK_RIGHT"] = Vector3.New(4.5, 0, -3),
}
local TANK_POSITIONS = {
	["LEFT"] = { x = 114.13, y = 353.87, z = 194.71 },
	["RIGHT"] = { x = 103.13, y = 353.87, z = 194.71 },
}
local STACK_POINT_MID = Vector3.New(108.63, 353.87, 175.49)
local STACK_POINT_RIGHT = Vector3.New(95.62, 353.87, 179.96)

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local GetUnitById = GameLib.GetUnitById
local GetPlayerUnit = GameLib.GetPlayerUnit
local bIsMidPhase
local nMordechaiId
local bFirstBarrage

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    bIsMidPhase = false
	bFirstBarrage = true
	mod:AddTimerBar("NEXT ORB", "NEXT ORB", 22, mod:GetSetting("CountdownOrb"), function() mod:AddTimerBar("ORB ACTIVE", "ORB ACTIVE", 5, false) end)
end

function mod:OnUnitCreated(nId, tUnit, sName)
	if sName == self.L["Mordechai Redmoon"] then
        core:AddUnit(tUnit)
        core:WatchUnit(tUnit)
		nMordechaiId = nId
		mod:AddMarkerLines()
	-- elseif sName == self.L["Orb Spawn Telegraph"] then
		-- core:AddPolygon(nId, nId, 6.5, 0, 6, "xkcdNeonPink", 20)
    elseif sName == self.L["Kinetic Orb"] then
        core:AddUnit(tUnit)
        core:WatchUnit(tUnit)
		mod:AddTimerBar("NEXT ORB", "NEXT ORB", 22, mod:GetSetting("CountdownOrb"), function() mod:AddTimerBar("ORB ACTIVE", "ORB ACTIVE", 5, false) end)
		if mod:GetSetting("StreetFighter") then
			core:PlaySound("hadou")
		end
	elseif sName == self.L["Airlock Anchor"] then
		bIsMidPhase = true
		mod:RemoveMarkerLines()
		mod:RemoveTimerBar("NEXT ORB")
		mod:RemoveTimerBar("SHORYU KEN")
	elseif sName == self.L["Shoryu Ken"] then
		if mod:GetSetting("LineShoryuKen") then
			core:AddSimpleLine(nId, nId, 0, 16, 0, 8, "green")
		end
	end
end

function mod:DisplayOrbTimer()
	
end

function mod:OnUnitDestroyed(nId, tUnit, sName)
	if sName == self.L["Shoryu Ken"] then
		if mod:GetSetting("LineShoryuKen") then
			core:RemoveSimpleLine(nId)
		end
	end
end

function mod:OnDebuffAdd(nId, nSpellId, nStack, fTimeRemaining)
	if nId == GetPlayerUnit():GetId() then
		if nSpellId == DEBUFFID_KINETICLINK then
			mod:AddMsg("HIT THE ORB", "HIT THE ORB", 3, "Burn")
		elseif nSpellId == DEBUFFID_SHOCKINGATTRACTION then
			mod:AddMsg("SHORYU KENS ON YOU", "SHORYU KENS ON YOU", 3, "RunAway")
		end
	end
	if nSpellId == DEBUFFID_KINETICLINK then
		core:AddPicture("KL" .. nId, nId, "Crosshair", 20)
	elseif nSpellId == DEBUFFID_SHOCKINGATTRACTION then
		core:AddPicture("SA" .. nId, nId, "Heart", 18)
	end
end

function mod:OnDebuffRemove(nId, nSpellId)
	if nSpellId == DEBUFFID_KINETICLINK then
		core:RemovePicture("KL" .. nId)
	elseif nSpellId == DEBUFFID_SHOCKINGATTRACTION then
		core:RemovePicture("SA" .. nId)
	end
end

function mod:OnHealthChanged(nId, nPercent, sName)
end

function mod:OnDatachron(sMessage)
	if sMessage:find(self.L["Airlock Closed"]) then
		bIsMidPhase = false
		mod:AddTimerBar("NEXT ORB", "NEXT ORB", 14, mod:GetSetting("CountdownOrb"), function() mod:AddTimerBar("ORB ACTIVE", "ORB ACTIVE", 5, false) end)
		mod:AddTimerBar("SHORYU KEN", "SHORYU KEN", 10, true)
		mod:AddMarkerLines()
	end
end

function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
	if sName == self.L["Mordechai Redmoon"] then
		if sCastName == self.L["Shatter Shock"] then
			mod:AddTimerBar("SHORYU KEN", "SHORYU KEN", 22, true)
			if mod:GetSetting("StreetFighter") then
				core:PlaySound("shouryuu")
			end
		elseif sCastName == self.L["Vicious Barrage"] and mod:GetSetting("StreetFighter") and bFirstBarrage then
			core:PlaySound("tatsumaki")
			bFirstBarrage = false
			self:ScheduleTimer("ResetBarrage", 10)
		end
	end
end

function mod:ResetBarrage()
	bFirstBarrage = true
end

function mod:AddMarkerLines()
	if mod:GetSetting("LineCleave") then
		core:AddOffsetLine("cleave_1", nMordechaiId, CLEAVE_OFFSETS["FRONT_LEFT"], 60, -28, 4, "FFFF0000", nil)
		core:AddOffsetLine("cleave_2", nMordechaiId, CLEAVE_OFFSETS["FRONT_RIGHT"], 60, 28, 4, "FFFF0000", nil)
		core:AddOffsetLine("cleave_3", nMordechaiId, CLEAVE_OFFSETS["BACK_LEFT"], -60, -28, 4, "FFFF0000", nil)
		core:AddOffsetLine("cleave_4", nMordechaiId, CLEAVE_OFFSETS["BACK_RIGHT"], -60, 28, 4, "FFFF0000", nil)
		core:AddPolygon("cleave_5", nMordechaiId, 5.5, 0, 5, "FFFF0000", 16)
	end
	if mod:GetSetting("LineTank") then
		core:AddSimpleLine("tank_left", TANK_POSITIONS["LEFT"], 0, 11.5, 90, 4, "FFFFFF00", nil)
		core:AddSimpleLine("tank_right", TANK_POSITIONS["RIGHT"], 0, 11.5, -90, 4, "FFFFFF00", nil)
	end
	if mod:GetSetting("MarkerStackMid") then
		core:AddPicture("stack_point_mid", STACK_POINT_MID, "ClientSprites:LootCloseBox_Holo", 25)
	end
end

function mod:RemoveMarkerLines()
	if mod:GetSetting("LineCleave") then
		core:DropLine("cleave_1")
		core:DropLine("cleave_2")
		core:DropLine("cleave_3")
		core:DropLine("cleave_4")
		core:RemovePolygon("cleave_5")
	end
	if mod:GetSetting("LineTank") then
		core:DropLine("tank_left")
		core:DropLine("tank_right")
	end
	if mod:GetSetting("MarkerStackMid") then
		core:DropPicture("stack_point_mid")
	end
end