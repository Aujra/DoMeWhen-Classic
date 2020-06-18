local DMW = DMW
DMW.Bot.QuestHelper = {}
local QuestHelper = DMW.Bot.QuestHelper
local Log = DMW.Bot.Log

function QuestHelper:ShouldPickupQuest(questID)
    local qlink = GetQuestLogIndexByID(750)
    local finished = IsQuestFlaggedCompleted(750)
    if qlink <= 0 and not finished then
        return true
    else
        return false
    end
end

function QuestHelper:GetNPC(name)
    for _, Unit in pairs(DMW.Units) do
        if Unit.Name == name then
            return Unit
        end
    end
end

