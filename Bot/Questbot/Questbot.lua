local DMW = DMW
DMW.Bot.Questbot = {}
local Questbot = DMW.Bot.Questbot
local QuestHelper = DMW.Bot.QuestHelper
local Navigation = DMW.Bot.Navigation
local Log = DMW.Bot.Log

function Questbot:Pulse()
    if QuestHelper:ShouldPickupQuest(747) then
        local questGiver = QuestHelper:GetNPC("Grull Hawkwind")
        if questGiver.Distance >= 5 then
            Navigation:MoveTo(questGiver.PosX, questGiver.PosY, questGiver.PosZ)
        else
            InteractUnit(questGiver.Pointer)
        end
    end
end