local DMW = DMW
DMW.Bot.Questbot = {}
local Questbot = DMW.Bot.Questbot
local QuestHelper = DMW.Bot.QuestHelper
local Gathering = DMW.Bot.Gathering
local Navigation = DMW.Bot.Navigation
local Log = DMW.Bot.Log
local Combat = DMW.Bot.Combat
local Vendor = DMW.Bot.Vendor
local Misc = DMW.Bot.Misc
local Point = DMW.Classes.Point

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
local Modes = {
    Resting = 0,
    Dead = 1,
    Combat = 2,
    Grinding = 3,
    Vendor = 4,
    Roaming = 5,
    Looting = 6,
    Gathering = 7,
    Idle = 8,
    Interact = 9
}

Questbot.Mode = 0

local Throttle = false
local VendorTask = false
local InformationOutput = false
local skinBlacklist = {}
local lootBlacklist = {}
local moveToLootTime

local Settings = {
    RestHP = 60,
    RestMana = 50,
    RepairPercent = 40,
    MinFreeSlots = 5,
    BuyFood = false,
    BuyWater = false,
    FoodName = '',
    WaterName = ''
}

local HotSpots = {}

local pickingup = 0
local droppingoff = 0

--- [questid] = { title, pickupnpc, pickupxyz, dropoffxyz, hotspots{}, dropoffnpc, questtype, {mobids}, {gatherids} }
local questslist = {
    [4641] = {"Your place in the world", "Kaltunk", {-601, -4251, 0}, {-601, -4190, 0}, {}, "Gornek", "turnin", {}, {}},
    [788] = {"Cutting Teeth", "Gornek", {-601, -4190, 0}, {-601, -4190, 0}, {-667, -4219, 42}, "Gornek", "grind", {}, {}},
    [4402] = {"Apple Surprise", "Galgar", {-564, -4190, 0}, {-601, -4221, 0}, {-517, -4302, 38}, "Galgar", "gather", {}, {}},
    [5441] = {"Lazy Peons", "Foreman Thrazz'til", {-564, -4190, 0}, {-601, -4221, 0}, {-323, -4132, 52}, "Foreman Thrazz'til", "useitem", {}, {}, "Foreman's Blackjack", "Lazy Peon", "UnitMovementFlags(Object)==1024" }
}
local qorder = {4641, 788, 4402, 5441}

local ModeFrame = CreateFrame("Frame",nil,UIParent)
ModeFrame:SetWidth(1)
ModeFrame:SetHeight(1)
ModeFrame:SetAlpha(.90);
ModeFrame:SetPoint("CENTER",0,-200)
ModeFrame.text = ModeFrame:CreateFontString(nil,"ARTWORK")
ModeFrame.text:SetFont("Fonts\\ARIALN.ttf", 13, "OUTLINE")
ModeFrame.text:SetPoint("CENTER",0,0)

local TaskFrame = CreateFrame("Frame",nil,UIParent)
TaskFrame:SetWidth(1)
TaskFrame:SetHeight(1)
TaskFrame:SetAlpha(.90);
TaskFrame:SetPoint("CENTER",0,-225)
TaskFrame.text = TaskFrame:CreateFontString(nil,"ARTWORK")
TaskFrame.text:SetFont("Fonts\\ARIALN.ttf", 13, "OUTLINE")
TaskFrame.text:SetPoint("CENTER",0,0)

local evFrame=CreateFrame("Frame");
evFrame:RegisterEvent("CHAT_MSG_WHISPER");
evFrame:RegisterEvent("LOOT_CLOSED");
evFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
evFrame:SetScript("OnEvent",function(self,event,msg,ply)
    if DMW.Settings.profile then
        if DMW.Settings.profile.Grind.ignoreWhispers then
            if event == "CHAT_MSG_WHISPER" then
                Log:DebugInfo('Added [' .. ply .. '] To Ignore List')
                RunMacroText('/Ignore ' .. ply)
            end
        end
        if DMW.Settings.profile.Grind.doSkin then
            if event == "LOOT_CLOSED" then
                PauseFlags.skinDelay = true C_Timer.After(1.8, function() PauseFlags.skinDelay = false end)
            end
        end
        if DMW.Settings.profile.Helpers.AutoLoot then
            if event == "COMBAT_LOG_EVENT_UNFILTERED" then
                local _, type = CombatLogGetCurrentEventInfo()
                if type == "PARTY_KILL" then
                    PauseFlags.waitingForLootable = true C_Timer.After(1, function() PauseFlags.waitingForLootable = false end)
                end
            end 
        end
    end
end)

local MyScanningTooltip = CreateFrame("GameTooltip", "MyScanningTooltip", UIParent, "GameTooltipTemplate")

local QuestTitleFromID = setmetatable({}, { __index = function(t, id)
    MyScanningTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    MyScanningTooltip:SetHyperlink("quest:"..id)
    local title = MyScanningTooltip.TextLeft1:GetText()
    MyScanningTooltip:Hide()
    if title and title ~= RETRIEVING_DATA then
        t[id] = title
        return title
    end
end })

function Questbot:PickupQuest(questID)
    local QuestGiver, name, npcname, spawn = QuestHelper:GetStartNPC(questID)
    local giver = QuestHelper:GetNPC(npcname)
    Navigation:MoveTo(spawn.X, spawn.Y, spawn.Z)
    if giver and giver.Distance <= 2 then
        Navigation:StopMoving()
        InteractUnit(giver.Pointer)
    end
    ModeFrame.text:SetText("Picking up quest "..name.." from "..npcname)
end
function Questbot:TurnInQuest(questID)
    local QuestGiver, name, npcname, spawn = QuestHelper:GetEndNPC(questID)
    local giver = QuestHelper:GetNPC(npcname)
    Navigation:MoveTo(spawn.X, spawn.Y, spawn.Z)
    if giver and giver.Distance <= 2 then
        Navigation:StopMoving()
        InteractUnit(giver.Pointer)
    end
    ModeFrame.text:SetText("Turning in quest "..name.." to "..npcname)
end

function Questbot:Pulse()  
    if QuestHelper:ShouldPickupQuest(4641) then
        Questbot:PickupQuest(4641)
    end
    if (QuestHelper:ShouldTurnIn(4641)) then
        Questbot:TurnInQuest(4641)
    end

    if QuestHelper:Finished(4641) and QuestHelper:ShouldPickupQuest(788) then
        self:PickupQuest(788)
    end
    if QuestHelper:IsOnQuest(788) and not QuestHelper:ShouldTurnIn(788) then
        ModeFrame.text:SetText("Doing quest Cutting Teeth")
        HotSpots = QuestHelper:GetHotSpots(788)
        self:DoQuestTask(nil)
    end
    if (QuestHelper:ShouldTurnIn(788)) then
        Questbot:TurnInQuest(788)
    end

    --- do together
    if QuestHelper:Finished(788) and QuestHelper:ShouldPickupQuest(789) then
        Questbot:PickupQuest(789)
    end
    if QuestHelper:Finished(788) and QuestHelper:ShouldPickupQuest(4402) and QuestHelper:IsOnQuest(789) then
        Questbot:PickupQuest(4402)
    end
    if QuestHelper:Finished(788) and QuestHelper:ShouldPickupQuest(790) and QuestHelper:IsOnQuest(4402) then
        Questbot:PickupQuest(790)
    end
    if QuestHelper:IsOnQuest(789) and QuestHelper:IsOnQuest(4402) and QuestHelper:IsOnQuest(790) then
        HotSpots = QuestHelper:GetHotSpots(789)
        Questbot:DoQuestTask();
    end
    if (QuestHelper:ShouldTurnIn(4402) and QuestHelper:ShouldTurnIn(789) and QuestHelper:ShouldTurnIn(790)) then
        Questbot:TurnInQuest(4402)
    end
    if (QuestHelper:Finished(4402) and QuestHelper:ShouldTurnIn(789)) then
        Questbot:TurnInQuest(789)
    end
    if QuestHelper:Finished(789) and QuestHelper:ShouldTurnIn(790) then
        self:TurnInQuest(790)
    end
end

function Questbot:DoQuestTask()
    if not Throttle then
        self:LoadSettings()
        if DMW.Settings.profile.Grind.openClams then Misc:ClamTask() end
        Misc:DeleteTask()
        self:ClearBlackList()
        self:SetFoodAndWater()
        if DMW.Player.Pet and not DMW.Player.Pet.Dead and DMW.Player.Pet.Target and not Combat:SearchEnemy() then PetFollow() end -- Stupid ass rotations using pets unnecesary
        Throttle = true
        C_Timer.After(0.1, function() Throttle = false end)
    end

    if DMW.Player.Casting then self:ResetMoveToLoot() end -- Reset if casting

 -- This sets our state
 if not (PauseFlags.skinDelay and DMW.Settings.profile.Grind.doSkin) and not (PauseFlags.waitingForLootable and DMW.Settings.profile.Helpers.AutoLoot) then 
    self:SwapMode() 
end
if (HasQuestNPC) then
    Questbot.Mode = Modes.Interact
end
 if Questbot.Mode ~= Modes.Looting then Questbot:ResetMoveToLoot() end

 if Questbot.Mode == Modes.Dead then
    Navigation:MoveToCorpse()
    TaskFrame.text:SetText('Corpse Run')
end

if Questbot.Mode == Modes.Combat then
    Combat:AttackCombat()
    TaskFrame.text:SetText('Combat Attack')
end

if Questbot.Mode == Modes.Resting then
    self:Rest()
    TaskFrame.text:SetText('Resting')
end

if Questbot.Mode == Modes.Vendor then
    Vendor:DoTask()
    TaskFrame.text:SetText('Vendor run')
end

if Questbot.Mode == Modes.Looting then
    self:GetLoot()
    TaskFrame.text:SetText('Looting')
end

if (Questbot.Mode == Modes.Interact) then
    self:NPCInteract()
    TaskFrame.text:SetText("Interacting with NPC")
end

if Questbot.Mode == Modes.Gathering then
    Gathering:Gather()
    TaskFrame.text:SetText('Gathering')
end

if Questbot.Mode == Modes.Grinding then
    Combat:GrindingQuest()
    TaskFrame.text:SetText('Grinding')
end

if Questbot.Mode == Modes.Roaming then
    Navigation:GrindRoam()
    TaskFrame.text:SetText('Roaming')
end

if Questbot.Mode == Modes.Idle then
    Navigation:StopMoving()
    TaskFrame.text:SetText('Rotation')
end
end


function Questbot:Rest()
    local Eating = DMW.Player.Eating
    local Drinking = DMW.Player.Drinking
    local Bandaging = DMW.Player.Bandaging
    local RecentlyBandaged = DMW.Player.RecentlyBandaged

    if DMW.Player.Moving then Navigation:StopMoving() return end
    if DMW.Player.Casting then return end

    CancelShapeshiftForm()

    if DMW.Settings.profile.Grind.firstAid then
        bandage = getBestUsableBandage()
        if DMW.Player.HP < Settings.RestHP and not Eating and not Drinking and not RecentlyBandaged and bandage then
            UseItemByName(bandage.Name, 'player')
            return
        end
    end

    if Settings.WaterName ~= '' then
        if UnitPower('player', 0) / UnitPowerMax('player', 0) * 100 < Settings.RestMana and not Drinking and not Bandaging and not PauseFlags.CantDrink then
            UseItemByName(Settings.WaterName)
            PauseFlags.CantDrink = true
            C_Timer.After(1, function() PauseFlags.CantDrink = false end)
        end
    end

    if Settings.FoodName ~= '' then
        if DMW.Player.HP < Settings.RestHP and not Eating and not Bandaging and not PauseFlags.CantEat then
            UseItemByName(Settings.FoodName)
            PauseFlags.CantEat = true
            C_Timer.After(1, function() PauseFlags.CantEat = false end)
        end
    end
end

function Questbot:SwapMode()
    if UnitIsDeadOrGhost('player') then
        Questbot.Mode = Modes.Dead
        return
    end

    local Eating = AuraUtil.FindAuraByName('Food', 'player')
    local Drinking = AuraUtil.FindAuraByName('Drink', 'player')
    local hasEnemy, theEnemy = Combat:SearchEnemy()
    local hasAttackable, theAttackable = Combat:SearchAttackableQuest()
    local hasOre = Gathering:OreSearch()
    local hasHerb = Gathering:HerbSearch()
    local hasQuest = Gathering:QuestSearch()

    -- If we arent in combat and we arent standing (if our health is less than 95 percent and we currently have the eating buff or we are a caster and our mana iss less than 95 and we have the drinking buff) then set mode to rest.
    if not DMW.Player.Swimming and not DMW.Player.Combat and not DMW.Player:Standing() and (DMW.Player.HP < 95 and Eating or UnitPower('player', 0) > 0 and (UnitPower('player', 0) / UnitPowerMax('player', 0) * 100) < 95 and Drinking) then
        Questbot.Mode = Modes.Resting
        return
    else
        -- If the above is not true and we arent standing, we stand.
        if not DMW.Player:Standing() then DoEmote('STAND') end
    end

    -- (TRIAL!)
    if Navigation:NearHotspotArray(200, HotSpots) and hasEnemy then
        Questbot.Mode = Modes.Combat
        return
    end

    -- if we dont have skip aggro enabled in pathing and we arent mounted and we are in combat, fight back.
    if not DMW.Settings.profile.Grind.SkipCombatOnTransport and not IsMounted() and hasEnemy then
        Questbot.Mode = Modes.Combat
        return
    end

    -- If we are not in combat and not mounted and our health is less than we decided or if we use mana and its less than decided do the rest function.
    if not DMW.Player.Swimming and not DMW.Player.Combat and not IsMounted() and (DMW.Player.HP < Settings.RestHP or UnitPower('player', 0) > 0 and (UnitPower('player', 0) / UnitPowerMax('player', 0) * 100) < Settings.RestMana) then
        Questbot.Mode = Modes.Resting
        return
    end

    -- Loot out of combat?
    if self:CanLoot() and not hasEnemy then
        Questbot.Mode = Modes.Looting
        return
    end

    -- If we are on vendor task and the Vendor.lua has determined the task to be done then we set the vendor task to false.
    if VendorTask and Vendor:TaskDone() then
        VendorTask = false
        return
    end

    -- Force vendor while vendor task is true, this is set in Vendor.lua file to make sure we complete it all.
    if VendorTask then
        Questbot.Mode = Modes.Vendor
        return
    end

    -- If our durability is less than we decided or our bag slots is less than decided, vendor task :)
    if (Vendor:GetDurability() <= Settings.RepairPercent or Misc:GetFreeSlots() < Settings.MinFreeSlots) then
        Questbot.Mode = Modes.Vendor
        if not VendorTask then
            Vendor:Reset()
            VendorTask = true
        end
        return
    end

    -- if we chose to buy food and we dont have any food, if we chose to buy water and we dont have any water, Vendor task.
    if (Settings.BuyFood and not Misc:HasItem(Settings.FoodName)) or (Settings.BuyWater and not Misc:HasItem(Settings.WaterName)) then
        Questbot.Mode = Modes.Vendor
        if not VendorTask then
            Vendor:Reset()
            VendorTask = true
        end
        return
    end

    -- Interact with quest NPC --
    if (HasQuestNPC) then
        Questbot.Mode = Modes.Interact
    end

    -- Gather when we are within 100 yards of hotspot
    if (hasQuest or hasOre and DMW.Settings.profile.Grind.mineOre or hasHerb and DMW.Settings.profile.Grind.gatherHerb) then
        Questbot.Mode = Modes.Gathering
        return
    end

     -- if we are not within 105 yards of the hotspots then walk to them no matter what. (IF WE CHOSE THE SKIP AGGRO SETTING)
    if not Navigation:NearHotspot(DMW.Settings.profile.Grind.RoamDistance) and DMW.Settings.profile.Grind.SkipCombatOnTransport and not Combat:HasTarget() then
        Questbot.Mode = Modes.Roaming
        return
    end

    -- if we arent in combat and we arent casting and there are units around us, start grinding em.  (If we arent in combat or if we are in combat and our target is denied(grey) then search for new.)
    if (not DMW.Player.Combat or DMW.Player.Combat and DMW.Player.Target and (UnitIsTapDenied(DMW.Player.Target.Pointer) or not UnitAffectingCombat("DMW.Player.Target.Pointer"))) and not DMW.Player.Casting and hasAttackable then
        Questbot.Mode = Modes.Grinding
        return
    end

    -- if there isnt anything to attack and we arent in combat then roam around till we find something.
    if not hasAttackable and (not DMW.Player.Combat or DMW.Player.Combat and DMW.Player.Target and (UnitIsTapDenied(DMW.Player.Target.Pointer) or not UnitAffectingCombat("DMW.Player.Target.Pointer"))) then
        Questbot.Mode = Modes.Roaming
        return
    end

    if not Navigation:NearHotspotArray(100, HotSpots) then
        Questbot.Mode = Modes.Roaming
        return
    end

    Questbot.Mode = Modes.Idle
end

function Questbot:NPCInteract()
    local hasNPC, theNPC = self:QuestNPCSearch()
    Navigation:MoveTo(theNPC.PosX, theNPC.PosY,theNPC.PosZ)
    if (theNPC.Distance < 5) then
        Navigation:StopMoving()
        InteractUnit(theNPC.Pointer)
        UseItemByName("Foreman's Blackjack")
    end
end

function Questbot:QuestNPCSearch(thequest)
    Log:DebugInfo(thequest[12])
    local Table = {}
    for _, Object in pairs(DMW.Units) do
        if Object.Quest and self:NodeNearHotspot(Object) then
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

function Questbot:NodeNearHotspot(Node)
    local Hotspots = HotSpots

    for i = 1, #Hotspots do
        local hx, hy, hz = Hotspots[i].X, Hotspots[i].Y, Hotspots[i].Z
        if GetDistanceBetweenPositions(Node.PosX, Node.PosY, Node.PosZ, hx, hy, hz) <= 100 and GetDistanceBetweenPositions(Node.PosX, Node.PosY, Node.PosZ, DMW.Player.PosX, DMW.Player.PosY, DMW.Player.PosZ) < 80 then
            return true
        end
    end
    return false
end

---Looting Stuff
function Questbot:ClearBlackList()
    for i = 1, #skinBlacklist do
        if skinBlacklist[i] and not ObjectExists(skinBlacklist[i]) then
            skinBlacklist[i] = nil
        end
    end
    local cleanBlacklist = CleanNils(skinBlacklist)
    skinBlacklist = cleanBlacklist
end
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

function Questbot:SetFoodAndWater()
    if getBestFood() and getBestWater() then
        if DMW.Player.Class == 'MAGE' then
            if DMW.Settings.profile.Grind.autoFood and DMW.Settings.profile.Grind.FoodName ~= getBestFood() then
                DMW.Settings.profile.Grind.FoodName = getBestFood()
                Log:DebugInfo('Automatically set your food to ' .. getBestFood())
            end

            if DMW.Settings.profile.Grind.autoWater and DMW.Settings.profile.Grind.WaterName ~= getBestWater() then
                DMW.Settings.profile.Grind.WaterName = getBestWater()
                Log:DebugInfo('Automatically set your water to ' .. getBestWater())
            end
        end
    end
end

function Questbot:LoadSettings()
    if Settings.BuyWater ~= DMW.Settings.profile.Grind.BuyWater then
        Settings.BuyWater = DMW.Settings.profile.Grind.BuyWater
    end

    if Settings.BuyFood ~= DMW.Settings.profile.Grind.BuyFood then
        Settings.BuyFood = DMW.Settings.profile.Grind.BuyFood
    end

    if Settings.RepairPercent ~= DMW.Settings.profile.Grind.RepairPercent then
        Settings.RepairPercent = DMW.Settings.profile.Grind.RepairPercent
    end

    if Settings.MinFreeSlots ~= DMW.Settings.profile.Grind.MinFreeSlots then
        Settings.MinFreeSlots = DMW.Settings.profile.Grind.MinFreeSlots
    end

    if Settings.RestHP ~= DMW.Settings.profile.Grind.RestHP then
        Settings.RestHP = DMW.Settings.profile.Grind.RestHP
    end

    if Settings.RestMana ~= DMW.Settings.profile.Grind.RestMana then
        Settings.RestMana = DMW.Settings.profile.Grind.RestMana
    end

    if Settings.FoodName ~= DMW.Settings.profile.Grind.FoodName then
        Settings.FoodName = DMW.Settings.profile.Grind.FoodName
    end

    if Settings.WaterName ~= DMW.Settings.profile.Grind.WaterName then
        Settings.WaterName = DMW.Settings.profile.Grind.WaterName
    end
end