--[[
	mLogs 2 (M4D Logs 2)
	Created by M4D | http://m4d.one/ | http://steamcommunity.com/id/m4dhead |
	Copyright © 2018 M4D.one All Rights Reserved
	All 3rd party content is public domain or used with permission
	M4D.one is the copyright holder of all code below. Do not distribute in any circumstances.
--]]

mLogs.addCategory(
	"Realistic Kidnap System", -- Name
	"rkidnap", 
	Color(255,0,0), -- Color
	function() -- Check
		return true
	end,
	true
)

mLogs.addCategoryDefinitions("rkidnap", {
	restrains = function(data) return mLogs.doLogReplace({"^player1", "^action", "^player2"},data) end,
	blindfold = function(data) return mLogs.doLogReplace({"^player1", "^action", "^player2"},data) end,
	knockedout = function(data) return mLogs.doLogReplace({"^player1", "knocked out", "^player2"},data) end,
	gag = function(data) return mLogs.doLogReplace({"^player1", "^action", "^player2"},data) end,
})	