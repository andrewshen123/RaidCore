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
local mod = core:NewEncounter("Robomination", {104, 104}, {0, 548}, {548, 551})
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", { "Robomination" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Robomination"] = "Robomination",
	["Cannon Arm"] = "Cannon Arm",
	["Flailing Arm"] = "Flailing Arm",
	["Scanning Eye"] = "Scanning Eye",
    -- Datachron messages.
    ["The Robomination sinks"] = "The Robomination sinks",
    ["The Robomination erupts back into the fight!"] = "The Robomination erupts back into the fight!",
	["The Robomination tries to incinerate [PlayerName]"] = "The Robomination tries to incinerate (.*)",
	["Robomination tries to crush [PlayerName]!"] = "Robomination tries to crush (.*)!",
    -- Cast.
    ["Noxious Belch"] = "Noxious Belch",
    ["Cannon Fire"] = "Cannon Fire",
	-- Bar and messages.
	--["THIRD"] = "3",
})
-- Default settings.
mod:RegisterDefaultSetting("LineCannonArm")
mod:RegisterDefaultSetting("LineFlailingArm")
mod:RegisterDefaultSetting("LineRobominationFacing")
mod:RegisterDefaultSetting("AlertSelfCrush")
mod:RegisterDefaultSetting("AlertOtherCrush")
mod:RegisterDefaultSetting("BewareNoxiousBelch")
mod:RegisterDefaultSetting("CountdownCrush")
mod:RegisterDefaultSetting("CountdownArmSpawn")
mod:RegisterDefaultSetting("MarkLaser")
mod:RegisterDefaultSetting("MarkCrush")
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    ["BELCH"] = { sColor = "xkcdBlueyGreen" },
    ["CRUSH"] = { sColor = "xkcdOrangered" },
})

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local DEBUFFID_CRUSH = 75126

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local GetUnitById = GameLib.GetUnitById
local GetPlayerUnit = GameLib.GetPlayerUnit
local bIsMidPhase = false

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
	bIsMidPhase = false
    mod:AddTimerBar("ARMS SPAWN", "ARMS SPAWN", 45, mod:GetSetting("CountdownArmSpawn"))
    mod:AddTimerBar("CRUSH", "CRUSH", 8, mod:GetSetting("CountdownCrush"))
    mod:AddTimerBar("BELCH", "BELCH", 16, false)
end

function mod:OnUnitCreated(nId, tUnit, sName)
    local nHealth = tUnit:GetHealth()
    if sName == self.L["Robomination"] then
        if nHealth then
            core:AddUnit(tUnit)
            core:WatchUnit(tUnit)
			core:AddPicture(nId, nId, "Crosshair", 10)
			if mod:GetSetting("LineRobominationFacing") then
				core:AddSimpleLine("RobominationFacing", nId, 0, 20, 0, 6, "xkcdGreen", nil)
			end
        end
	elseif sName == self.L["Flailing Arm"] then
		if not bIsMidPhase then
			mod:AddTimerBar("ARMS SPAWN", "ARMS SPAWN", 45, mod:GetSetting("CountdownArmSpawn"))
		end
		core:PlaySound("Alert")
        if mod:GetSetting("LineFlailingArm") then
			core:AddLineBetweenUnits("PathToFlailingArm" .. nId, GetPlayerUnit():GetId(), tUnit:GetPosition(), 6, "blue")
		end
        core:AddUnit(tUnit)
        core:WatchUnit(tUnit)
	elseif sName == self.L["Cannon Arm"] then
        if mod:GetSetting("LineCannonArm") then
			core:AddLineBetweenUnits("PathToCannonArm" .. nId, GetPlayerUnit():GetId(), tUnit:GetPosition(), 6, "red")
		end
        core:AddUnit(tUnit)
        core:WatchUnit(tUnit)
	elseif sName == self.L["Scanning Eye"] then
		core:AddUnit(tUnit)
        core:WatchUnit(tUnit)
	end
end

function mod:OnUnitDestroyed(nId, tUnit, sName)
    if sName == self.L["Cannon Arm"] and mod:GetSetting("LineCannonArm") then
        core:RemoveLineBetweenUnits("PathToCannonArm" .. nId)
	elseif sName == self.L["Flailing Arm"] and mod:GetSetting("LineFlailingArm") then
        core:RemoveLineBetweenUnits("PathToFlailingArm" .. nId)
    end
end

function mod:OnDatachron(sMessage)
	local sPlayerCrushed = sMessage:match(self.L["Robomination tries to crush [PlayerName]!"])
	local sPlayerLasered = sMessage:match(self.L["The Robomination tries to incinerate [PlayerName]"])
	if sPlayerCrushed then
		local tSelf = GetPlayerUnit()
		mod:AddTimerBar("CRUSH", "CRUSH", 17, mod:GetSetting("CountdownCrush"))
		if sPlayerCrushed == tSelf:GetName() and mod:GetSetting("AlertSelfCrush") then
			mod:AddMsg("RUN AWAY", "RUN AWAY", 3, "RunAway")
		elseif mod:GetSetting("AlertOtherCrush") then
			mod:AddMsg(sPlayerCrushed, sPlayerCrushed, 3, false)
		end
		local tUnit = GameLib.GetPlayerUnitByName(sPlayerCrushed)
		local nId = tUnit:GetId()
		if mod:GetSetting("MarkCrush") then
			core:AddPicture(nId, nId, "Crosshair", 20)
			self:ScheduleTimer(function(nId) core:RemovePicture(nId) end, 10, nId)
		end
	elseif sPlayerLasered then
		local tUnit = GameLib.GetPlayerUnitByName(sPlayerLasered)
		local nId = tUnit:GetId()
		mod:AddMsg("LASER", "LASER ON " .. sPlayerLasered, 3, false)
		mod:AddTimerBar("INCINERATE", "INCINERATE", 40, false)
		if mod:GetSetting("MarkLaser") then
			core:AddPicture(nId, nId, "Crafting_RunecraftingSprites:sprRunecrafting_Fire_Colored", 20)
			self:ScheduleTimer(function(nId) core:RemovePicture(nId) end, 10, nId)
		end
	elseif sMessage:find(self.L["The Robomination sinks"]) then
		bIsMidPhase = true
		core:RemoveTimerBar("CRUSH")
		core:RemoveTimerBar("BELCH")
		core:RemoveTimerBar("INCINERATE")
		core:RemoveTimerBar("ARMS SPAWN")
	elseif sMessage:find(self.L["The Robomination erupts back into the fight!"]) then
		bIsMidPhase = false
		mod:AddTimerBar("CRUSH", "CRUSH", 7, mod:GetSetting("CountdownCrush"))
		mod:AddTimerBar("BELCH", "BELCH", 14, false)
		mod:AddTimerBar("INCINERATE", "INCINERATE", 20, false)
		mod:AddTimerBar("ARMS SPAWN", "ARMS SPAWN", 45, mod:GetSetting("CountdownArmSpawn"))
	end
end

function mod:OnNPCSay(sMessage, sSender)
end

function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
	if sName == self.L["Robomination"] then
		if sCastName == self.L["Noxious Belch"] then
			if mod:GetSetting("BewareNoxiousBelch") then
				core:PlaySound("Beware")
			end
			mod:AddTimerBar("BELCH", "BELCH", 31, false)
		end
	-- elseif sName == self.L["Cannon Arm"] then
		-- if sCastName == self.L["Cannon Fire"] then
			-- mod:AddMsg("INTERRUPT CANNON", "INTERRUPT CANNON", 3, false)
		-- end
	end
end