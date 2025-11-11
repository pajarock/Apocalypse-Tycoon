--!strict
local Players = game:GetService("Players")
local BadgeService = game:GetService("BadgeService")

local Achievements = {}

local BADGES = {
	FirstPurchase = 0,  -- Reemplazar con Badge ID real
	Millionaire = 0,
	Survivor100 = 0,
}

function Achievements.Award(userId: number, badgeName: string)
	local badgeId = BADGES[badgeName]
	if badgeId == 0 then return end

	pcall(function()
		BadgeService:AwardBadge(userId, badgeId)
	end)
end

return Achievements