local MODULE = GAS.Logging:MODULE()

MODULE.Category = "ToBadForYou"
MODULE.Name     = "Realistic Kidnap"
MODULE.Colour   = Color(255,0,0)

MODULE:Hook("RKS_Knockout","rks_succ_ko",function(vic,knocker)
	MODULE:Log(GAS.Logging:FormatPlayer(knocker) .. " knocked out " .. GAS.Logging:FormatPlayer(vic))
end)

MODULE:Hook("RKS_Restrain","rks_toggle_restrain",function(vic,restrainer)
	local LogText = "restrained"
	if !vic.RKRestrained then
		LogText = "unrestrained"
	end
	MODULE:Log(GAS.Logging:FormatPlayer(restrainer) .. " " .. LogText .. " " .. GAS.Logging:FormatPlayer(vic))
end)

MODULE:Hook("RKS_Blindfold","rks_toggle_blindfold",function(vic,blindfolder)
	local LogText = "blindfolded"
	if !vic.Blindfolded then
		LogText = "unblindfolded"
	end
	MODULE:Log(GAS.Logging:FormatPlayer(blindfolder) .. " " .. LogText .. " " .. GAS.Logging:FormatPlayer(vic))
end)

MODULE:Hook("RKS_Gag","rks_toggle_gag",function(vic,gagger)
	local LogText = "gagged"
	if !vic.Gagged then
		LogText = "ungagged"
	end
	MODULE:Log(GAS.Logging:FormatPlayer(gagger) .. " " .. LogText .. " " .. GAS.Logging:FormatPlayer(vic))
end)

GAS.Logging:AddModule(MODULE)
