--[[
	mLogs 2 (M4D Logs 2)
	Created by M4D | http://m4d.one/ | http://steamcommunity.com/id/m4dhead |
	Copyright © 2018 M4D.one All Rights Reserved
	All 3rd party content is public domain or used with permission
	M4D.one is the copyright holder of all code below. Do not distribute in any circumstances.
--]]

local category = "rkidnap"

mLogs.addLogger("Restrains","restrains",category)
mLogs.addHook("RKS_Restrain", category, function(vic,restrainer)
	if(not IsValid(vic) or not IsValid(restrainer))then return end
	local LogText = "restrained"
	if !vic.RKRestrained then
		LogText = "unrestrained"
	end

	mLogs.log("restrains", category, {player1=mLogs.logger.getPlayerData(restrainer),action=LogText,player2=mLogs.logger.getPlayerData(vic),a=true})
end)