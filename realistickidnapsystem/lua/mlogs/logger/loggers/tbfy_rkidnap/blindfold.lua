--[[
	mLogs 2 (M4D Logs 2)
	Created by M4D | http://m4d.one/ | http://steamcommunity.com/id/m4dhead |
	Copyright © 2018 M4D.one All Rights Reserved
	All 3rd party content is public domain or used with permission
	M4D.one is the copyright holder of all code below. Do not distribute in any circumstances.
--]]

local category = "rkidnap"

mLogs.addLogger("Blindfolds","blindfold",category)
mLogs.addHook("RKS_Blindfold", category, function(vic,blindfolder)
	if(not IsValid(vic) or not IsValid(blindfolder))then return end
	local LogText = "blindfolded"
	if !vic.Blindfolded then
		LogText = "unblindfolded"
	end

	mLogs.log("blindfold", category, {player1=mLogs.logger.getPlayerData(blindfolder),action=LogText,player2=mLogs.logger.getPlayerData(vic),a=true})
end)