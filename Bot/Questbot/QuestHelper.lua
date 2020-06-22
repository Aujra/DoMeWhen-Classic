local DMW = DMW
DMW.Bot.QuestHelper = {}
local QuestHelper = DMW.Bot.QuestHelper
local Log = DMW.Bot.Log

function QuestHelper:ShouldPickupQuest(questID)
    local qlink = GetQuestLogIndexByID(questID)
    local finished = IsQuestFlaggedCompleted(questID)
    if qlink <= 0 and not finished then
        return true
    else
        return false
    end
end

function QuestHelper:Finished(questId) 
    return IsQuestFlaggedCompleted(questId)
end

function QuestHelper:IsOnQuest(questId)
    local qlink = GetQuestLogIndexByID(questId)
    return qlink > 0
end

function QuestHelper:ShouldTurnIn(questId)
    return IsQuestComplete(questId)
end

function QuestHelper:GetQuestName(questId)
    local qlink = GetQuestLogIndexByID(questId)
    local title = GetQuestLogTitle(qlink)
    return title
end

function QuestHelper:GetNPC(name)
    for _, Unit in pairs(DMW.Units) do
        if Unit.Name == name then
            return Unit
        end
    end
end

