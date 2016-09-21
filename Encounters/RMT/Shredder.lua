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
local mod = core:NewEncounter("Shredder", 104, 548, 549)
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", { "Swabbie Ski'Li" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Swabbie Ski'Li"] = "Swabbie Ski'Li",
	["Regor the Rancid"] = "Regor the Rancid",
	["Braugh the Bloodied"] = "Braugh the Bloodied",
	["Noxious Nabber"] = "Noxious Nabber",
	["Sawblade"] = "Sawblade",
	["Saw"] = "Saw",
	["BubbleTelegraph"] = "Hostile Invisible Unit for Fields (1.2 hit radius)",
    -- Datachron messages.
    ["WARNING: THE SHREDDER IS STARTING!"] = "WARNING: THE SHREDDER IS STARTING!",
	["Almost finished cleanin'"] = "Almost finished cleanin'",
	["Into the shredder"] = "Into the shredder",
    -- Cast.
    ["Scrubber Bubbles"] = "Scrubber Bubbles",
	["Necrotic Lash"] = "Necrotic Lash",
	["Gravedigger"] = "Gravedigger",
	["Deathwail"] = "Deathwail",
    -- Bar and messages.
    ["SOUTH"] = "SOUTH",
	["MID"] = "MID",
	["NORTH"] = "NORTH",
})
-- Default settings.
mod:RegisterDefaultSetting("LineSawsNormalBig")
mod:RegisterDefaultSetting("LineSawsNormalSmall")
mod:RegisterDefaultSetting("LineSawsMidphase")
mod:RegisterDefaultSetting("LineSpawn")
mod:RegisterDefaultSetting("OtherSpawnLocation")
mod:RegisterDefaultSetting("CircleScrubberBubbles")
mod:RegisterDefaultSetting("BarBossProgress")
mod:RegisterDefaultSetting("OtherShame")
-- Timers default configs.
mod:RegisterDefaultTimerBarConfigs({
    --["EGGS"] = { sColor = "xkcdOrangered" },
})

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------

local SPAWN_LINE_1_Z = -829.34
local SPAWN_LINE_2_Z = -882.80
local CHECKPOINT_Z = { [0] = -810.58, [1] = -829.34, [2] = -882.80, [3] = -918.35, [4] = -974.68 } 
 local SPAWN_LINES = {
    ["FIRST"] = { x = -42.45, y = 597.89, z = CHECKPOINT_Z[1] },
    ["SECOND"] = { x = -42.45, y = 597.89, z = CHECKPOINT_Z[2] },
    ["THIRD"] = { x = -42.45, y = 597.89, z = CHECKPOINT_Z[3] },
 }
 local SPAWN_POSITIONS = {
    ["SOUTH"] = { x = -20.58, y = 597.89, z = -808.34 },
    ["MID"] = { x = -20.58, y = 597.89, z = -882.51 },
    ["NORTH"] = { x = -20.58, y = 597.89, z = -961.50 },
 }

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local GetUnitById = GameLib.GetUnitById
local GetPlayerUnit = GameLib.GetPlayerUnit
local ignoreNextBubble = false
local bIsMidPhase = false
local DEBUFFID_BILIOUSOOZE = 84321
local nBossId

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
	if mod:GetSetting("LineSpawn") then
		core:AddSimpleLine("FIRST", SPAWN_LINES["FIRST"], 0, 43.7, 90, 5, "FFFF0000", nil)
		core:AddSimpleLine("SECOND", SPAWN_LINES["SECOND"], 0, 43.7, 90, 5, "FF0000FF", nil)
		core:AddSimpleLine("THIRD", SPAWN_LINES["THIRD"], 0, 43.7, 90, 5, "FFFFFF00", nil)
	end
	if mod:GetSetting("OtherSpawnLocation") then
		core:SetWorldMarker("SOUTH", self.L["SOUTH"], SPAWN_POSITIONS["SOUTH"])
		core:SetWorldMarker("MID", self.L["MID"], SPAWN_POSITIONS["MID"])
		core:SetWorldMarker("NORTH", self.L["NORTH"], SPAWN_POSITIONS["NORTH"])
	end
	
	if mod:GetSetting("BarBossProgress") then
		self:ScheduleTimer(function() core:AddCustom("Next spawn", 0, 100, function() return PercentToNextCheckpoint() end, "FF99FF66") end, 5)	end
	bIsMidPhase = false
end

function mod:OnUnitCreated(nId, tUnit, sName)
    local nHealth = tUnit:GetHealth()
    if sName == self.L["Swabbie Ski'Li"] then
        if nHealth then
            core:AddUnit(tUnit)
            core:WatchUnit(tUnit)
        end
		nBossId = nId
	elseif sName == self.L["Braugh the Bloodied"] or sName == self.L["Regor the Rancid"] then
		mod:AddMsg("MINI SPAWNED", "MINI SPAWNED", 3, "Alert")
		core:AddUnit(tUnit)
		core:WatchUnit(tUnit)
	elseif sName == self.L["Noxious Nabber"] then
		core:WatchUnit(tUnit)
	elseif sName == self.L["Saw"] and mod:GetSetting("LineSawsNormalSmall") then
		core:AddSimpleLine(nId, nId, nil, 15, 0, 6, "xkcdGreen")
	elseif sName == self.L["Sawblade"] and mod:GetSetting("LineSawsNormalBig") and not bIsMidPhase then
		core:AddSimpleLine(nId, nId, nil, 30, 0, 10, "xkcdRed")
	elseif sName == self.L["Sawblade"] and mod:GetSetting("LineSawsMidphase") and bIsMidPhase then
		core:AddSimpleLine(nId, nId, nil, 50, 0, 10, "xkcdRed")
	elseif sName == self.L["BubbleTelegraph"] and mod:GetSetting("CircleScrubberBubbles") then
		core:AddPolygon(nId, nId, 6.5, 0, 6, "xkcdNeonPink", 20)
    end
end

function mod:OnDatachron(sMessage)
    if sMessage:find(self.L["THE SHREDDER IS STARTING!"]) then
		mod:AddMsg("SHREDDER STARTING", "SHREDDER STARTING", 3, "RunAway")
    end
end

function mod:OnDebuffUpdate(nId, nSpellId, nOldStack, nStack, fTimeRemaining)
	local nPlayerId = GetPlayerUnit():GetId()
	local tUnit = GetUnitById(nId)
	
	if nId == nPlayerId and nSpellId == DEBUFFID_BILIOUSOOZE then
		if nStack >= 10 and mod:GetSetting("OtherShame") then
			ChatSystemLib.Command("/p I hit " .. nStack .. " stacks because I'm a complete moron.")
		elseif nStack == 8 then
			mod:AddMsg("STOP HITTING THE BRUTE", "STOP HITTING THE BRUTE", 3, "Beware")
		end
	end
end

function mod:OnNPCSay(sMessage, sSender)
	if sMessage:find(self.L["Into the shredder"]) then
		if mod:GetSetting("BarBossProgress") then
			core:RemoveCustom("Next spawn")
		end
		bIsMidPhase = true
		if mod:GetSetting("LineSpawn") then
			core:DropPixie("FIRST")
			core:DropPixie("SECOND")
			core:DropPixie("THIRD")
		end
		if mod:GetSetting("OtherSpawnLocation") then
			core:DropWorldMarker("SOUTH")
			core:DropWorldMarker("MID")
			core:DropWorldMarker("NORTH")
		end
	elseif sMessage:find(self.L["Almost finished cleanin'"]) then
		bIsMidPhase = false
		if mod:GetSetting("LineSpawn") then
			core:AddSimpleLine("FIRST", SPAWN_LINES["FIRST"], 0, 43.7, 90, 5, "FFFF0000", nil)
			core:AddSimpleLine("SECOND", SPAWN_LINES["SECOND"], 0, 43.7, 90, 5, "FF0000FF", nil)
			core:AddSimpleLine("THIRD", SPAWN_LINES["THIRD"], 0, 43.7, 90, 5, "FFFFFF00", nil)
		end
		if mod:GetSetting("OtherSpawnLocation") then
			core:SetWorldMarker("SOUTH", self.L["SOUTH"], SPAWN_POSITIONS["SOUTH"])
			core:SetWorldMarker("MID", self.L["MID"], SPAWN_POSITIONS["MID"])
			core:SetWorldMarker("NORTH", self.L["NORTH"], SPAWN_POSITIONS["NORTH"])
		end
		if mod:GetSetting("BarBossProgress") then
			core:AddCustom("Next spawn", 0, 100, function() return PercentToNextCheckpoint() end, "FF99FF66")
		end
	end
end

function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
	if sName == self.L["Noxious Nabber"] then
		if self.L["Necrotic Lash"] == sCastName then
			mod:AddMsg("INTERRUPT NABBER", "INTERRUPT NABBER", 2, "Inferno")
		end
	elseif sName == self.L["Braugh the Bloodied"] or sName == self.L["Regor the Rancid"] then
		if self.L["Gravedigger"] == sCastName or self.L["Deathwail"] == sCastName then
			mod:AddMsg("INTERRUPT MINI", "INTERRUPT MINI", 2, "Inferno")
		end
	end
end

function PercentToNextCheckpoint()
	if bIsMidPhase or not nBossId then return 0 end
	local tUnit = GetUnitById(nBossId)
	if not tUnit then return 0 end
	local z = tUnit:GetPosition().z
	if z < CHECKPOINT_Z[3] then
		return (z - CHECKPOINT_Z[3]) / (CHECKPOINT_Z[4] - CHECKPOINT_Z[3]) * 100
	elseif z < CHECKPOINT_Z[2] then
		return (z - CHECKPOINT_Z[2]) / (CHECKPOINT_Z[3] - CHECKPOINT_Z[2]) * 100
	elseif z < CHECKPOINT_Z[1] then
		return (z - CHECKPOINT_Z[1]) / (CHECKPOINT_Z[2] - CHECKPOINT_Z[1]) * 100
	elseif z < CHECKPOINT_Z[0] then
		return (z - CHECKPOINT_Z[0]) / (CHECKPOINT_Z[1] - CHECKPOINT_Z[0]) * 100
	end
	return 0
end