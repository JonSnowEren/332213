--[[
	mLogs 2 (M4D Logs 2)
	Created by M4D | http://m4d.one/ | http://steamcommunity.com/id/m4dhead |
	Copyright © 2018 M4D.one All Rights Reserved
	All 3rd party content is public domain or used with permission
	M4D.one is the copyright holder of all code below. Do not distribute in any circumstances.
--]]

local category = "rkidnap"

mLogs.addLogger("Gagged","gag",category)
mLogs.addHook("RKS_Gag", category, function(vic,gagger)
	if(not IsValid(vic) or not IsValid(gagger))then return end
	local LogText = "gagged"
	if !vic.Gagged then
		LogText = "ungagged"
	end

	mLogs.log("gag", category, {player1=mLogs.logger.getPlayerData(gagger),action=LogText,player2=mLogs.logger.getPlayerData(vic),a=true})
end)