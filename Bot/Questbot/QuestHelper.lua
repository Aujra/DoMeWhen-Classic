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

function QuestHelper:IsOnQuest(questId)
    local qlink = GetQuestLogIndexByID(questId)
    return qlink > 0
end

function QuestHelper:ShouldTurnIn(questId)
    local qlink = GetQuestLogIndexByID(questId)
    local title, level, suggestedGroup, isHeader, isCollapsed, isComplete,
  frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI,
  isTask, isStory = GetQuestLogTitle(qlink);
    return isComplete > 0
end

function QuestHelper:GetNPC(name)
    for _, Unit in pairs(DMW.Units) do
        if Unit.Name == name then
            return Unit
        end
    end
end
