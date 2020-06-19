local DMW = DMW
DMW.Bot.Questbot = {}
local Questbot = DMW.Bot.Questbot
local QuestHelper = DMW.Bot.QuestHelper
local Navigation = DMW.Bot.Navigation
local Log = DMW.Bot.Log
local Combat = DMW.Bot.Combat
local Misc = DMW.Bot.Misc

local PauseFlags = {
    movingToLoot = false,
    Interacting = false,
    Skinning = false,
    Information = false,
    CantEat = false,
    CantDrink = false,
    skinDelay = false,
    waitingForLootable = false,
}

local Throttle = false
local VendorTask = false
local InformationOutput = false
local skinBlacklist = {}
local lootBlacklist = {}
local moveToLootTime

function Questbot:Pulse()
    if QuestHelper:ShouldPickupQuest(747) then
        local questGiver = QuestHelper:GetNPC("Grull Hawkwind")
        if questGiver.Distance >= 5 then
            Navigation:MoveTo(questGiver.PosX, questGiver.PosY, questGiver.PosZ)
        else
            Navigation:StopMoving()
            InteractUnit(questGiver.Pointer)
        end
    end
    if QuestHelper:ShouldTurnIn(747) then
        local questGiver = QuestHelper:GetNPC("Grull Hawkwind")
        if questGiver.Distance >= 5 then
            Navigation:MoveTo(questGiver.PosX, questGiver.PosY, questGiver.PosZ)
        else
            Navigation:StopMoving()
            InteractUnit(questGiver.Pointer)
            GetQuestReward(1)
        end
    end
    if (QuestHelper:IsOnQuest(747) and not QuestHelper:ShouldTurnIn(747)) then     
        if self:CanLoot() then
            Questbot:GetLoot()
        else
            Navigation:MoveTo(-3241, -311, 29)
            -- Combat:Grinding()
        end
    end
end

---Grinding Stuff
function blackListContains(unit)
    for i=1, #skinBlacklist do
        if skinBlacklist[i] == unit then
           return true
        end
     end
     return false
end

function Questbot:OnLootBlacklist(unit)
    for i=1, #lootBlacklist do
        if lootBlacklist[i] == unit then
           return true
        end
     end
     return false
end

function Questbot:ResetMoveToLoot()
    moveToLootTime = DMW.Time
    PauseFlags.movingToLoot = false
end

function Questbot:CanLoot()
    if not DMW.Settings.profile.Helpers.AutoLoot then return false end
    if Misc:GetFreeSlots() == 0 then return false end
    if DMW.Player.Casting then return false end
    if PauseFlags.skinDelay then return end

    local Table = {}
        for _, Unit in pairs(DMW.Units) do
            if Unit.Dead and not blackListContains(Unit.Pointer) and not self:OnLootBlacklist(Unit.Pointer) and (UnitCanBeLooted(Unit.Pointer) or UnitCanBeSkinned(Unit.Pointer) and DMW.Settings.profile.Grind.doSkin) then
                table.insert(Table, Unit)
            end
        end

        if #Table > 1 then
            table.sort(
                Table,
                function(x, y)
                    return x.Distance < y.Distance
                end
            )
        end

        for _, Unit in ipairs(Table) do
            if Unit.Distance <= 30 then
                return true, Unit
            end
        end
    return false
end

function Questbot:GetLoot()
    local hasLoot, LootUnit = self:CanLoot()
    local px, py, pz = ObjectPosition('player')
    local lx, ly, lz = ObjectPosition(LootUnit)
    if hasLoot and ObjectExists(LootUnit.Pointer) then
        if LootUnit.Distance > 5 then
            Navigation:MoveTo(LootUnit.PosX, LootUnit.PosY, LootUnit.PosZ)
            if Navigation:ReturnPathEnd() ~= nil then
                if not PauseFlags.movingToLoot then PauseFlags.movingToLoot = true moveToLootTime = DMW.Time end
                local endX, endY, endZ = Navigation:ReturnPathEnd()
                local endPathToUnitDist = GetDistanceBetweenPositions(LootUnit.PosX, LootUnit.PosY, LootUnit.PosZ, endX, endY, endZ)
                if endPathToUnitDist > 3 or DMW.Time - moveToLootTime > 10 then
                    -- Blacklist unit
                    Log:SevereInfo('Added LootUnit to badBlacklist Dist: ' .. endPathToUnitDist .. ' Time: ' .. DMW.Time-moveToLootTime)
                    table.insert(lootBlacklist, LootUnit.Pointer)
                end
                end
        else
            self:ResetMoveToLoot()
            if IsMounted() then Dismount() end
            if not PauseFlags.Interacting then
                for _, Unit in pairs(DMW.Units) do
                    if Unit.Dead and Unit.Distance < 5 then
                        if UnitCanBeLooted(Unit.Pointer) then
                            if InteractUnit(Unit.Pointer) then PauseFlags.Interacting = true C_Timer.After(0.1, function() PauseFlags.Interacting = false end) end
                        end
                    end
                end
                if DMW.Settings.profile.Grind.doSkin and UnitCanBeSkinned(LootUnit.Pointer) and not PauseFlags.Skinning then
                    if not DMW.Player.Casting then
                        if InteractUnit(LootUnit.Pointer) then PauseFlags.Skinning = true C_Timer.After(0.45, function() PauseFlags.Skinning = false end) end
                        return
                    end
                end
            end
        end
    end
    Misc:LootAllSlots()
end