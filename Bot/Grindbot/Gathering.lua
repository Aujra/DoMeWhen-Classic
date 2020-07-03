local DMW = DMW
DMW.Bot.Gathering = {}
local Gathering = DMW.Bot.Gathering
local Navigation = DMW.Bot.Navigation
local doingAction = false
local Log = DMW.Bot.Log

function Gathering:NodeNearHotspot(Node)
    local Hotspots = DMW.Settings.profile.Grind.HotSpots

    for i = 1, #Hotspots do
        local hx, hy, hz = Hotspots[i].X, Hotspots[i].Y, Hotspots[i].Z
        if GetDistanceBetweenPositions(Node.PosX, Node.PosY, Node.PosZ, hx, hy, hz) <= 100 and GetDistanceBetweenPositions(Node.PosX, Node.PosY, Node.PosZ, DMW.Player.PosX, DMW.Player.PosY, DMW.Player.PosZ) < 80 then
            return true
        end
    end
    return false
end

function Gathering:QuestSearch(questid)
    local Table = {}
    for _, Object in pairs(DMW.GameObjects) do
        if Object.Quest and self:NodeNearHotspot(Object) or Object:IsQuestByName(questid) then
            table.insert(Table, Object)
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

    for _, Object in pairs(Table) do
        return true, Object
    end

    return false
end

function Gathering:OreSearch()
    local Table = {}
    for _, Object in pairs(DMW.GameObjects) do
        if Object.Ore and self:NodeNearHotspot(Object) then
            table.insert(Table, Object)
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

    for _, Object in pairs(Table) do
        return true, Object
    end

    return false
end

function Gathering:HerbSearch()
    local Table = {}
    for _, Object in pairs(DMW.GameObjects) do
        if Object.Herb and self:NodeNearHotspot(Object) then
            table.insert(Table, Object)
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

    for _, Object in pairs(Table) do
        return true, Object
    end

    return false
end

function Gathering:OreSearch()
    local Table = {}
    for _, Object in pairs(DMW.GameObjects) do
        if Object.Ore and self:NodeNearHotspot(Object) then
            table.insert(Table, Object)
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

    for _, Object in pairs(Table) do
        return true, Object
    end

    return false
end

function Gathering:Gather()
    local hasHerb, theHerb = self:HerbSearch()
    local hasOre, theOre = self:OreSearch()
    local hasQuest, theQuest = self:QuestSearch()
    local Enemy = DMW.Player:GetHostiles(20)[1]

    if Enemy then
        DMW.Bot.Combat:InitiateAttack(Enemy)
        return
    end

    if hasQuest then
        local Distance = GetDistanceBetweenPositions(DMW.Player.PosX, DMW.Player.PosY, DMW.Player.PosZ, theQuest.PosX, theQuest.PosY, theQuest.PosZ)
        if Distance >= 5 then
            Navigation:MoveTo(theQuest.PosX, theQuest.PosY, theQuest.PosZ)
        else
            if not DMW.Player.Casting and not DMW.Player.Moving and not doingAction then
                ObjectInteract(theQuest.Pointer)
                doingAction = true
                C_Timer.After(0.1, function() doingAction = false end)
            end
        end
        return
    end

    if hasHerb then
        local Distance = GetDistanceBetweenPositions(DMW.Player.PosX, DMW.Player.PosY, DMW.Player.PosZ, theHerb.PosX, theHerb.PosY, theHerb.PosZ)
        if Distance >= 5 then
            Navigation:MoveTo(theHerb.PosX, theHerb.PosY, theHerb.PosZ)
        else
            if not DMW.Player.Casting and not DMW.Player.Moving and not doingAction then
                ObjectInteract(theHerb.Pointer)
                doingAction = true
                C_Timer.After(0.1, function() doingAction = false end)
            end
        end
        return
    end

    if hasOre then
        local Distance = GetDistanceBetweenPositions(DMW.Player.PosX, DMW.Player.PosY, DMW.Player.PosZ, theOre.PosX, theOre.PosY, theOre.PosZ)
        if Distance >= 5 then
            Navigation:MoveTo(theOre.PosX, theOre.PosY, theOre.PosZ)
        else
            if not DMW.Player.Casting and not DMW.Player.Moving and not doingAction then
                ObjectInteract(theOre.Pointer)
                doingAction = true
                C_Timer.After(0.1, function() doingAction = false end)
            end
        end
        return
    end
end

function Gathering:GatherQuest(thequest)
    local hasHerb, theHerb = self:HerbSearch()
    local hasOre, theOre = self:OreSearch()
    local hasQuest, theQuest = self:QuestSearch(thequest)
    local Enemy = DMW.Player:GetHostiles(20)[1]

    if Enemy then
        DMW.Bot.Combat:InitiateAttack(Enemy)
        return
    end

    if hasQuest then
        local Distance = GetDistanceBetweenPositions(DMW.Player.PosX, DMW.Player.PosY, DMW.Player.PosZ, theQuest.PosX, theQuest.PosY, theQuest.PosZ)
        if Distance >= 5 then
            Navigation:MoveTo(theQuest.PosX, theQuest.PosY, theQuest.PosZ)
        else
            if not DMW.Player.Casting and not DMW.Player.Moving and not doingAction then
                ObjectInteract(theQuest.Pointer)
                doingAction = true
                C_Timer.After(0.1, function() doingAction = false end)
            end
        end
        return
    end

    if hasHerb then
        local Distance = GetDistanceBetweenPositions(DMW.Player.PosX, DMW.Player.PosY, DMW.Player.PosZ, theHerb.PosX, theHerb.PosY, theHerb.PosZ)
        if Distance >= 5 then
            Navigation:MoveTo(theHerb.PosX, theHerb.PosY, theHerb.PosZ)
        else
            if not DMW.Player.Casting and not DMW.Player.Moving and not doingAction then
                ObjectInteract(theHerb.Pointer)
                doingAction = true
                C_Timer.After(0.1, function() doingAction = false end)
            end
        end
        return
    end

    if hasOre then
        local Distance = GetDistanceBetweenPositions(DMW.Player.PosX, DMW.Player.PosY, DMW.Player.PosZ, theOre.PosX, theOre.PosY, theOre.PosZ)
        if Distance >= 5 then
            Navigation:MoveTo(theOre.PosX, theOre.PosY, theOre.PosZ)
        else
            if not DMW.Player.Casting and not DMW.Player.Moving and not doingAction then
                ObjectInteract(theOre.Pointer)
                doingAction = true
                C_Timer.After(0.1, function() doingAction = false end)
            end
        end
        return
    end
end