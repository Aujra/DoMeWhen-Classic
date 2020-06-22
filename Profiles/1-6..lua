local Questbot = DMW.Bot.Questbot
local QuestHelper = DMW.Bot.QuestHelper

if QuestHelper:ShouldPickup(4641) and not QuestHelper:IsOnQuest(4641) then
    Questbot:PickupQuest("Your Place in the world", {-601, -4251, 0}, "Kalturk")
end
while not QuestHelper:ShouldTurnIn(4641) do

end
if (QuestHelper:ShouldTurnIn(4641)) then
    Questbot:TurnInQuest("Your place in the world", {-601, -4251, 0})
end

Questbot.ModeFrame.text:setText("Finished the quests")