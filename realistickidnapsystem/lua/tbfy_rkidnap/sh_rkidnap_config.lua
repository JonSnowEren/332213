
--[[
You can now disable attach system and restrict it to world surfaces only
You can now blacklist specific entities
Bug fixes

Config changes:
Added RESTRAINS_EnableAttach
Added RESTRAINS_EnableAttachEntity
Added .AttatchmentBlacklistEntities
]]

--IF YOU WANNA REMOVE THE COMPUTER FROM BEING PURCHASEABLE REMOVE THIS FOLDER: addons\tbfy_shared_v2\lua\darkrp_modules

RKidnapConfig = RKidnapConfig or {}
--Contact me on Gmodstore for help to translate
--Languages available:
--[[
chinese
english
french
german
korean
polish
russian
slovak
spanish
turkish
]]
RKidnapConfig.LanguageToUse = "english"
//Who can access admin commands,menus etc
RKidnapConfig.AdminAccessCustomCheck = function(Player) return Player:IsAdmin() end

//Calculates Movement/Penalty, so 2 would make player move half as fast
//Moving penalty while restrained
RKidnapConfig.RestrainedMovePenalty = 3
//Moving penalty while dragging
RKidnapConfig.DraggingMovePenalty = 3
//Displays if player is restrained overhead while aiming at him
RKidnapConfig.DisplayOverheadRestrained = false
//Setting this to true will cause the system to bonemanipulate clientside, might cause sync issues but won't require you to install all playermodels on the server
RKidnapConfig.BoneManipulateClientside = false
//How long should a player be knocked out?
RKidnapConfig.KnockoutTime = 15
//Allows to gravgun knocked out players ragdolls
RKidnapConfig.AllowGravGunRagdolls = true
//Key to press on a player to open up option menu
//https://wiki.garrysmod.com/page/Enums/IN
RKidnapConfig.KEY = IN_USE

RKidnapConfig.SurrenderEnabled = false
//All keys can be found here -> https://wiki.garrysmod.com/page/Enums/KEY
//Key for surrendering
//RKidnapConfig.SurrenderKey = KEY_T
//You can't surrender while holding these weapons
RKidnapConfig.SurrenderWeaponWhitelist = {
["weapon_arc_phone"] = true,
}

//Entities that you aren't allowed to attatch players to
//Add within the brackets, ["ENTITYNAME"] = true,
RKidnapConfig.AttatchmentBlacklistEntities = {
["rhc_jailer"] = true,
["func_door"] = true,
["func_door_rotating"] = true,
["prop_door_rotating"] = true,
}

local function RKidnap_init()
	timer.Simple(3, function()
		//These jobs are allowed if .RestrictToJobs = true
		//It will still check the data for these jobs even if .RestrictToJobs = false
		//So you can setup specific permissions for teams here
		RKidnapConfig.Jobs = {
			[TEAM_GANG] = {RestrainTime = 3, CanGag = true, CanBlind = true, CanSteal = true, CanKnockout = true},
			[TEAM_MOB] = {RestrainTime = 3, CanGag = true, CanBlind = true, CanSteal = true, CanKnockout = true},
		}
		
		DarkRP.createShipment("Kelepçe", {
    entity = "weapon_r_restrains",
    model = "models/tobadforyou/flexcuffs_deployed.mdl",
    amount = 1,
    price = 25000,
    noship = false,
    separate = false,
    category = "Cesitli Ekipmanlar",
    allowed = {
        TEAM_KARABORSACI
    },
})
		//Don't touch this unless you want to change models (this is for the one drawn on the player)
		local EData = {
			EID = "restrains", -- Don't change this
			Name = "Kelepçe",
			Ent = "prop_physics",
			Model = "models/tobadforyou/flexcuffs_deployed.mdl",
			MScale = 1.2,
			MSkin = nil,
			MColor = nil,
			AdjPos = Vector(0.3, -5.5, -2.6),
			AdjAng = Angle(0, 25, 250),
			Bone = "ValveBiped.Bip01_R_Hand",
			ForPurchase = false,
		}
		TBFY_SH:RegisterEquip(EData)

		local EData = {
			EID = "blindfold", -- Don't change this
			Name = "Gözlerini Kapat",
			Ent = "prop_physics",
			Model = "models/tobadforyou/blindfold.mdl",
			MScale = 1.1,
			MSkin = nil,
			MColor = Color(100,100,100),
			AdjPos = Vector(0.5, 0, 4),
			AdjAng = Angle(90, -180, 90),
			Bone = "ValveBiped.Bip01_Head1",
			ForPurchase = false,
			CustomPos = RKidnapConfig.AdjustBlindfold,
		}
		TBFY_SH:RegisterEquip(EData)

		local EData = {
		EID = "gag", -- Don't change this
		Name = "Sustur",
		Ent = "prop_physics",
		Model = "models/tobadforyou/blindfold_gag.mdl",
		MScale = 1.1,
		MSkin = nil,
		MColor = Color(100,100,100),
		AdjPos = Vector(1, 0, 1),
		AdjAng = Angle(90, -180, 90),
		Bone = "ValveBiped.Bip01_Head1",
		ForPurchase = false,
		CustomPos = RKidnapConfig.AdjustGag,
		}
		TBFY_SH:RegisterEquip(EData)

		local EData = {
			EID = "restrains_starwars", -- Don't change this
			Name = "Kelepçe",
			Ent = "prop_physics",
			Model = "models/casual/handcuffs/handcuffs.mdl",
			MScale = .94,
			MSkin = nil,
			MColor = nil,
			AdjPos = Vector(0, 4.4, 0.3),
			AdjAng = Angle(0, 10, 45),
			Bone = "ValveBiped.Bip01_R_Hand",
			ForPurchase = false,
		}
		TBFY_SH:RegisterEquip(EData)
	end)
end

hook.Add("DarkRPFinishedLoading", "RKidnap_init", function()
  if DCONFIG then
		hook.Add("DConfigDataLoaded", "RKidnap_init", RKidnap_init)
	elseif ezJobs then
      hook.Add("ezJobsLoaded", "RKidnap_init", RKidnap_init)
  else
      hook.Add("loadCustomDarkRPItems", "RKidnap_init", RKidnap_init)
  end
end)

//Disables drawing player shadow
//Only use this if the shadows are causing issues
//This is a temp fix, will be fixed in the future
RKidnapConfig.DisablePlayerShadow = false

//Should players be allowed to steal weapons from restrained players?
RKidnapConfig.AllowStealingWeapons = true
//Should it be possible to steal weapons given through job?
RKidnapConfig.AllowStealingJobWeapons = false
RKidnapConfig.BlackListedWeapons = {
["gmod_tool"] = true,
["weapon_keypadchecker"] = true,
["vc_wrench"] = true,
["vc_jerrycan"] = true,
["vc_spikestrip_wep"] = true,
["laserpointer"] = true,
["remotecontroller"] = true,
["idcard"] = true,
["pickpocket"] = true,
["keys"] = true,
["pocket"] = true,
["driving_license"] = true,
["firearms_license"] = true,
["weapon_physcannon"] = true,
["gmod_camera"] = true,
["weapon_physgun"] = true,
["weapon_r_restrained"] = true,
["tbfy_surrendered"] = true,
["weapon_r_cuffed"] = true,
["collections_bag"] = true,
["weapon_fists"] = true,
["weapon_arc_atmcard"] = true,
["itemstore_pickup"] = true,
["weapon_checker"] = true,
["driving_license_checker"] = true,
["fine_list"] = true,
["weapon_r_handcuffs"] = true,
["door_ram"] = true,
["med_kit"] = true,
["stunstick"] = true,
["arrest_stick"] = true,
["unarrest_stick"] = true,
["weaponchecker"] = true,
["weapon_vape_armor_plus"] = true,
["weapon_vape_medicinal_plus"] = true,
["weapon_vape_medicinal_armor_plus"] = true,
["weapon_grapplehook"] = true,
}

//Add all female models here or the restrain positioning will be weird
//It's case sensitive, make sure all letters are lowercase
RKidnapConfig.FEMALE_MODELS = {
	"models/player/group01/female_01.mdl",
	"models/player/group01/female_02.mdl",
	"models/player/group01/female_03.mdl",
	"models/player/group01/female_04.mdl",
	"models/player/group01/female_05.mdl",
	"models/player/group01/female_06.mdl",
	"models/player/group03/female_01.mdl",
	"models/player/group03/female_02.mdl",
	"models/player/group03/female_03.mdl",
	"models/player/group03/female_04.mdl",
	"models/player/group03/female_05.mdl",
	"models/player/group03/female_06.mdl",
}

//Allows adjustment of models that the default blindfold doesn't fit on
//RKS_AdjustBlindfold[MODELPATH] = {SIZE, LEFT/RIGHT, UP/DOWN, FORWARD/BACKWARD}
RKidnapConfig.AdjustBlindfold = {}
RKidnapConfig.AdjustBlindfold["models/player/group01/male_03.mdl"] = {1,0,4,1}
RKidnapConfig.AdjustBlindfold["models/player/group01/male_06.mdl"] = {1.07,0.05,4.3,1}
RKidnapConfig.AdjustBlindfold["models/player/group01/male_09.mdl"] = {1.04,0.05,4.3,0.5}
RKidnapConfig.AdjustBlindfold["models/player/group01/female_01.mdl"] = {0.7,0,3.8,1}
RKidnapConfig.AdjustBlindfold["models/player/group01/female_02.mdl"] = {0.7,0,3.8,1}
RKidnapConfig.AdjustBlindfold["models/player/group01/female_03.mdl"] = {0.7,0,3.8,1}
RKidnapConfig.AdjustBlindfold["models/player/group01/female_04.mdl"] = {0.7,0,3.8,1}
RKidnapConfig.AdjustBlindfold["models/player/group01/female_05.mdl"] = {0.7,0,3.8,1}
RKidnapConfig.AdjustBlindfold["models/player/group01/female_06.mdl"] = {0.7,0,3.8,1}
RKidnapConfig.AdjustBlindfold["models/player/group03/female_01.mdl"] = {0.7,0,3.8,1}
RKidnapConfig.AdjustBlindfold["models/player/group03/female_02.mdl"] = {0.7,0,3.8,1}
RKidnapConfig.AdjustBlindfold["models/player/group03/female_03.mdl"] = {0.7,0,3.8,1}
RKidnapConfig.AdjustBlindfold["models/player/group03/female_04.mdl"] = {0.7,0,3.8,1}
RKidnapConfig.AdjustBlindfold["models/player/group03/female_05.mdl"] = {0.7,0,3.8,1}
RKidnapConfig.AdjustBlindfold["models/player/group03/female_06.mdl"] = {0.7,0,3.8,1}


//Allows adjustment of models that the default gag doesn't fit on
RKidnapConfig.AdjustGag = {}
RKidnapConfig.AdjustGag["models/player/group01/male_03.mdl"] = {1,0,0.7,1.1}
RKidnapConfig.AdjustGag["models/player/group01/male_06.mdl"] = {1.07,0,0.7,1.6}
RKidnapConfig.AdjustGag["models/player/group01/female_01.mdl"] = {0.7,0,0.5,1.1}
RKidnapConfig.AdjustGag["models/player/group01/female_02.mdl"] = {0.7,0,0.5,1.1}
RKidnapConfig.AdjustGag["models/player/group01/female_03.mdl"] = {0.7,0,0.5,1.1}
RKidnapConfig.AdjustGag["models/player/group01/female_04.mdl"] = {0.7,0,0.5,1.1}
RKidnapConfig.AdjustGag["models/player/group01/female_05.mdl"] = {0.7,0,0.5,1.1}
RKidnapConfig.AdjustGag["models/player/group01/female_06.mdl"] = {0.7,0,0.5,1.1}
RKidnapConfig.AdjustGag["models/player/group03/female_01.mdl"] = {0.7,0,0.5,1.1}
RKidnapConfig.AdjustGag["models/player/group03/female_02.mdl"] = {0.7,0,0.5,1.1}
RKidnapConfig.AdjustGag["models/player/group03/female_03.mdl"] = {0.7,0,0.5,1.1}
RKidnapConfig.AdjustGag["models/player/group03/female_04.mdl"] = {0.7,0,0.5,1.1}
RKidnapConfig.AdjustGag["models/player/group03/female_05.mdl"] = {0.7,0,0.5,1.1}
RKidnapConfig.AdjustGag["models/player/group03/female_06.mdl"] = {0.7,0,0.5,1.1}
