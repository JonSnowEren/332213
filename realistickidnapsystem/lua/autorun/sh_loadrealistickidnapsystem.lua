
print("////////////////////////////////////////////")
print("//                                        //")
print("//  Loading Realistic Kidnap System Files //")
print("//   www.gmodstore.com/scripts/view/3334  //")
print("//         Created by ToBadForYou         //")
print("//                                        //")
print("////////////////////////////////////////////")

if SERVER then
	include("tbfy_rkidnap/sh_rkidnap_config.lua")
	include("tbfy_rkidnap/sh_rkidnap.lua")
	include("tbfy_rkidnap/sv_rkidnap.lua")

	AddCSLuaFile("tbfy_rkidnap/sh_rkidnap_config.lua")
	AddCSLuaFile("tbfy_rkidnap/sh_rkidnap.lua")
	AddCSLuaFile("tbfy_rkidnap/cl_rkidnap.lua")
elseif CLIENT then
	include("tbfy_rkidnap/sh_rkidnap_config.lua")
	include("tbfy_rkidnap/sh_rkidnap.lua")
    include("tbfy_rkidnap/cl_rkidnap.lua")
end
