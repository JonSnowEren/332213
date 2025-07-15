local PLAYER = FindMetaTable("Player")

local CatName = "Realistic Kidnap"
local CatID = "rkidnap"

TBFY_SH:RegisterLanguage(CatID)
local Language = RKidnapConfig.LanguageToUse
include("tbfy_rkidnap/language/" .. Language .. ".lua");
if SERVER then
	AddCSLuaFile("tbfy_rkidnap/language/" .. Language .. ".lua");
end

function RKS_GetLang(ID)
	return TBFY_SH:GetLanguage(CatID, ID)
end

function RKS_GetConf(ID)
	return TBFY_SH:FetchConfig(CatID, ID)
end

function PLAYER:RKSAccess()
	if RKS_GetConf("RESTRAINS_RestrictRestrains") then
		return RKidnapConfig.Jobs[self:Team()]
	else
		return true
	end
end

function PLAYER:RKS_GetRestrainTime()
	if RKidnapConfig.Jobs[self:Team()] then
		return RKidnapConfig.Jobs[self:Team()].RestrainTime
	else
		return RKS_GetConf("RESTRAINS_RestrainTime")
	end
end

function PLAYER:RKS_CanRestrain()
	local JobInf = RKidnapConfig.Jobs[self:Team()]
	if JobInf then
		return JobInf
	elseif RKS_GetConf("RESTRAINS_RestrictRestrains") then
		return false
	else
		return true
	end
end

function PLAYER:RKS_CanKO()
	local JobInf = RKidnapConfig.Jobs[self:Team()]
	if JobInf then
		return JobInf.CanKnockout
	elseif RKS_GetConf("RESTRAINS_RestrictRestrains") then
		return false
	else
		return true
	end
end

function PLAYER:RKS_CanSteal()
	local JobInf = RKidnapConfig.Jobs[self:Team()]
	if JobInf then
		return JobInf.CanSteal
	elseif RKS_GetConf("RESTRAINS_RestrictRestrains") then
		return false
	else
		return true
	end
end

function PLAYER:RKS_CanBlind()
	local JobInf = RKidnapConfig.Jobs[self:Team()]
	if JobInf then
		return JobInf.CanBlind
	elseif RKS_GetConf("RESTRAINS_RestrictRestrains") then
		return false
	else
		return true
	end
end

function PLAYER:RKS_CanGag()
	local JobInf = RKidnapConfig.Jobs[self:Team()]
	if JobInf then
		return JobInf.CanGag
	elseif RKS_GetConf("RESTRAINS_RestrictRestrains") then
		return false
	else
		return true
	end
end

function PLAYER:RKSImmune()
	return RKS_GetConf("RESTRAINS_BlacklistedJobs")[self:Team()]
end

function PLAYER:TBFY_CanSurrender()
	if !self:Alive() or self:InVehicle() or self.Restrained or self.RKRestrained then return false end

	local Wep = self:GetActiveWeapon()
	if !IsValid(Wep) or RKidnapConfig.SurrenderWeaponWhitelist[Wep:GetClass()] then
		return false
	else
		return true
	end
end

hook.Add("canRequestHit", "RKS_RestrictHitMenu", function(Hitman, Player)
	if Hitman:GetNWBool("rks_restrained", false) then
		return false
	end
end)

local CMoveData = FindMetaTable("CMoveData")

function CMoveData:RemoveKeys(keys)
	-- Using bitwise operations to clear the key bits.
	local newbuttons = bit.band(self:GetButtons(), bit.bnot(keys))
	self:SetButtons(newbuttons)
end

hook.Add("SetupMove", "rks_setupmove", function(Player, mv)
	local restrainedPlayer = Player.RKSDragging
	local AProp = Player:GetNWEntity("RKS_AttatchEnt", nil)

	if Player:GetNWBool("rks_restrained", false) or Player.RKSRestrained then
		mv:SetMaxClientSpeed(mv:GetMaxClientSpeed() / RKidnapConfig.RestrainedMovePenalty)
		if mv:KeyDown(IN_JUMP) then
			mv:RemoveKeys(IN_JUMP)
		end
	elseif Player.RKSDragging then
		mv:SetMaxClientSpeed(mv:GetMaxClientSpeed() / RKidnapConfig.DraggingMovePenalty)
	end

	if Player:GetNWBool("RKS_Attatched", false) and IsValid(AProp) then
		local PlayerPos = Player:GetPos()
		local EntPos
		
		-- GetAttatchPosition metodunun varlığını kontrol et
		if AProp.GetAttatchPosition then
			EntPos = AProp:GetAttatchPosition()
		else
			EntPos = AProp:GetPos()
		end
		
		-- GetAttatchedEntity metodunun varlığını kontrol et
		local AEnt = nil
		if AProp.GetAttatchedEntity then
			AEnt = AProp:GetAttatchedEntity()
		end

		if IsValid(AEnt) then
			EntPos = AEnt:GetPos()
		end

		local EntDir = (EntPos - PlayerPos):GetNormal()
		local MaxDistance = 100
		local MaxPos = EntPos - (EntDir*MaxDistance)

		local EntX, EntY, MaxX, MaxY = EntPos.x, EntPos.y, MaxPos.x, MaxPos.y
		local PlyX, PlyY = PlayerPos.x, PlayerPos.y
		if (EntX > PlyX and MaxX > PlyX) or (EntX < PlyX and MaxX < PlyX) or (EntY > PlyY and MaxY > PlyY) or (EntY < PlyY and MaxY < PlyY) then
			local Vel = EntDir*25

			mv:SetOrigin(MaxPos)
			mv:SetVelocity(Vel)
		end
	elseif IsValid(restrainedPlayer) and Player == restrainedPlayer.RKSDraggedBy then
		local DragerPos = Player:GetPos()
		local DraggedPos = restrainedPlayer:GetPos()
		local Distance = DragerPos:Distance(DraggedPos)

		if Distance < RKS_GetConf("DRAG_MaxRange") then
			local DragPosNormal = DragerPos:GetNormal()
			local Difx = math.abs(DragPosNormal.x)
			local Dify = math.abs(DragPosNormal.y)

			local Speed = (Difx + Dify)*math.Clamp(Distance/RKS_GetConf("DRAG_RangeForce"),0,RKS_GetConf("DRAG_MaxForce"))

			local ang = mv:GetMoveAngles()
			local pos = mv:GetOrigin()
			local vel = mv:GetVelocity()

			vel.x = vel.x * Speed
			vel.y = vel.y * Speed
			vel.z = 15

			pos = pos + vel + ang:Right() + ang:Forward() + ang:Up()

			if Distance > 55 then
				restrainedPlayer:SetVelocity(vel)
			end
		else
			restrainedPlayer:RKSCancelDrag()
		end
	end
end)

hook.Add("tbfy_InitSetup","RKS_InitSetup",function()
	TBFY_SH:SetupConfig(CatID, "DRAG_MaxRange", "Maximum range for dragging, will cancel if player is futher away than this", "Number", {Val = 175, Decimals = 0, Max = 300, Min = 50}, false)
	TBFY_SH:SetupConfig(CatID, "DRAG_MaxForce", "Maximum velocity for dragging (increase this if dragging is slow)", "Number", {Val = 30, Decimals = 0, Max = 300, Min = 1}, false)
	TBFY_SH:SetupConfig(CatID, "DRAG_RangeForce", "Range force for dragging (lower this if dragging is slow)", "Number", {Val = 100, Decimals = 0, Max = 100, Min = 1}, false)

	TBFY_SH:SetupConfig(CatID, "INSPECT_MoneyStealRandomAmount", "Should the stolen amount always be random?", "Bool", true, true)
	TBFY_SH:SetupConfig(CatID, "INSPECT_MaxStolenMoney", "The maximum amount of money that can be stolen from a player", "Number", {Val = 1000, Decimals = 0, Max = 5000, Min = 1}, false)
	TBFY_SH:SetupConfig(CatID, "INSPECT_MoneyStolenCooldown", "The delay before the player can be robbed again", "Number", {Val = 500, Decimals = 0, Max = 1000, Min = 1}, false)

	TBFY_SH:SetupConfig(CatID, "RESTRAINS_RestrainTime", "How long it takes to restrain a player", "Number", {Val = 3, Decimals = 1, Max = 10, Min = 0.1}, false)
	TBFY_SH:SetupConfig(CatID, "RESTRAINS_AutoUnrestrainTime", "How long before a player is automaticly unrestrained (Counted in minutes, set to 0 to disable)", "Number", {Val = 0, Decimals = 0, Max = 20, Min = 0}, false)
	TBFY_SH:SetupConfig(CatID, "RESTRAINS_RestrainRange", "How long range should restrains have?", "Number", {Val = 75, Decimals = 0, Max = 300, Min = 50}, false)
	TBFY_SH:SetupConfig(CatID, "RESTRAINS_RestrictRestrains", "Restrict restrains to jobs set in the config (no ingame config for job)", "Bool", false, true)
	TBFY_SH:SetupConfig(CatID, "RESTRAINS_EnableEscape", "Should players be able to escape from their restraints?", "Bool", true, true)
	TBFY_SH:SetupConfig(CatID, "RESTRAINS_TeleportBackDisconnectPlayers", "Should players who disconnect while being restrained be returned to the restrainer upon reconnecting?", "Bool", true, false)
	TBFY_SH:SetupConfig(CatID, "RESTRAINS_BlacklistedJobs", "The jobs that aren't allowed to be restrained or knocked out", "Jobs", {}, true)
	TBFY_SH:SetupConfig(CatID, "RESTRAINS_UnrestrainForcedWeaponSelection", "The SWEP that should be selected upon unrestrained", "SWEP", "keys", false)
	TBFY_SH:SetupConfig(CatID, "RESTRAINS_StarWarsRestrains", "Should Star Wars restrains be used?", "Bool", false, true)
	TBFY_SH:SetupConfig(CatID, "RESTRAINS_EnableAttach", "Should it be possible to attach players to surfaces/props?", "Bool", true, false)
	TBFY_SH:SetupConfig(CatID, "RESTRAINS_EnableAttachEntity", "Should it be possible to attach players to props?", "Bool", true, false)

	if SERVER then
		TBFY_SH:LoadConfigs(CatID)
		TBFY_SH:SetupAddonInfo(CatID, RKidnapConfig.AdminAccessCustomCheck, {})
	else
		TBFY_SH:RequestConfig(CatID)
		TBFY_SH:SetupCategory(CatName)
		TBFY_SH:SetupCMDButton(CatName, "Configs", nil, function() local Configs = vgui.Create("tbfy_edit_config") Configs:SetConfigs(CatID, CatName) end)
	end
end)