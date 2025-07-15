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

-- Devamı...

function PLAYER:SetupRestrains()
		if RKS_GetConf("RESTRAINS_StarWarsRestrains") then
			TBFY_SH:TogglePEquip(self, "restrains_starwars", self.RKRestrained)
		else
			TBFY_SH:TogglePEquip(self, "restrains", self.RKRestrained)
		end
	  self:SetNWBool("rks_restrained", self.RKRestrained)
end

function PLAYER:SetupRKSWeapons()
  if self.RKRestrained then
    self.RKSStoreWTBL = {}
    for k,v in pairs(self:GetWeapons()) do
			local WData = {Class = v:GetClass()}
			WData.IsFromArmory = v.IsFromArmory
			WData.PrometheusGiven = v.PrometheusGiven
			WData.isPermanent = v.isPermanent
			self.RKSStoreWTBL[k] = WData
    end
    self:StripWeapons()
		self:Give("weapon_r_restrained")
    elseif !self.RKRestrained then
		self:StripWeapon("weapon_r_restrained")
    for k,v in pairs(self.RKSStoreWTBL) do
      local SWEP = self:Give(v.Class)
			SWEP.IsFromArmory = v.IsFromArmory
			SWEP.PrometheusGiven = v.PrometheusGiven
			SWEP.isPermanent = v.isPermanent
			local SWEPTable = weapons.GetStored(v.Class)
			if SWEPTable then
				local DefClip = SWEPTable.Primary.DefaultClip
				local AmmoType = SWEPTable.Primary.Ammo
				local ClipSize = SWEPTable.Primary.ClipSize
				if (DefClip and DefClip > 0) and AmmoType and ClipSize then
					local AmmoToRemove = DefClip - ClipSize
					self:RemoveAmmo(AmmoToRemove, AmmoType)
				end
			end
        end
        self.RKSStoreWTBL = {}
				self:SelectWeapon(RKS_GetConf("RESTRAINS_UnrestrainForcedWeaponSelection"))
    end
end

function PLAYER:RKSRestrain(RestrainedBy)
	local RNick = "UNKNOWN"
	local RPValid = false
	if IsValid(RestrainedBy) then
		RNick = RestrainedBy:Nick()
		RPValid = true
	end

  if !self.RKRestrained then
		if self.TBFY_Surrendered then
			self:TBFY_ToggleSurrender()
		end
    self.RKRestrained = true
    self.RestrainedBy = RestrainedBy
    RestrainedBy.RestrainedPlayer = self
		if RKS_GetConf("RESTRAINS_StarWarsRestrains") then
			self:SetupRKSBones("Restrained_StarWars")
		else
			self:SetupRKSBones("Restrained")
		end
    self:SetupRestrains()
    self:SetupRKSWeapons()
    TBFY_Notify(self, 1, 4, string.format(RKS_GetLang("RestrainedBy"), RNick))
		if RPValid then
			TBFY_Notify(RestrainedBy, 1, 4, string.format(RKS_GetLang("Restrainer"), self:Nick()))
		end
		local UnrestrainTime = RKS_GetConf("RESTRAINS_AutoUnrestrainTime")*60
		if UnrestrainTime != 0 then
			timer.Create("RKS_unrestrain_" .. TBFY_SH:SID(self), UnrestrainTime, 1, function()
				if IsValid(self) then
					self:CleanUpRKS(true, true)
					TBFY_Notify(self, 1, 4, RKS_GetLang("AutoUnrestrain"))
				end
			end)
		end
  elseif self.RKRestrained then
    self:CleanUpRKS(true, true)

    TBFY_Notify(self, 1, 4, string.format(RKS_GetLang("ReleasedBy"), RNick))
		if RPValid then
			TBFY_Notify(RestrainedBy, 1, 4, string.format(RKS_GetLang("Releaser"), self:Nick()))
		end
  end

	hook.Call("RKS_Restrain", GAMEMODE, self, RestrainedBy)
end

net.Receive("rks_unrestrain", function(len, Player)
	local TPlayer = net.ReadEntity()
	local Distance = Player:EyePos():Distance(TPlayer:GetPos());
	if Distance > 100 or !TPlayer:IsPlayer() or Player.RKRestrained then return false; end

	if TPlayer.RKRestrained then
		TPlayer:RKSRestrain(Player)
	end
end)

function PLAYER:SetupBlindfold()
	TBFY_SH:TogglePEquip(self, "blindfold", self.Blindfolded)
	net.Start("rks_blindfold")
		net.WriteBool(self.Blindfolded)
	net.Send(self)
end

function PLAYER:RKSBlindfold(BlindfoldedBy)
	if !self.RKRestrained then return end
	local Distance = BlindfoldedBy:EyePos():Distance(self:GetPos());
	if Distance > 100 then return false; end

	self.Blindfolded = !self.Blindfolded
	self:SetupBlindfold()

	if self.Blindfolded then
    TBFY_Notify(self, 1, 4, string.format(RKS_GetLang("BlindfoldedBy"), BlindfoldedBy:Nick()))
    TBFY_Notify(BlindfoldedBy, 1, 4, string.format(RKS_GetLang("Blindfolder"), self:Nick()))
	elseif !self.Blindfolded then
    TBFY_Notify(self, 1, 4, string.format(RKS_GetLang("UnBlindfoldedBy"), BlindfoldedBy:Nick()))
    TBFY_Notify(BlindfoldedBy, 1, 4, string.format(RKS_GetLang("UnBlindfolder"), self:Nick()))
	end

	hook.Call("RKS_Blindfold", GAMEMODE, self, BlindfoldedBy)
end
net.Receive("rks_blindfold", function(len, Player)
	if !Player:RKS_CanBlind() then return end
	if !IsValid(Player:GetActiveWeapon()) or Player:GetActiveWeapon():GetClass() != "weapon_r_restrains" then return false end

	local PToBlindfold = net.ReadEntity()
	if IsValid(PToBlindfold) then
		PToBlindfold:RKSBlindfold(Player)
	end
end)

function PLAYER:SetupRKSGag()
	TBFY_SH:TogglePEquip(self, "gag", self.Gagged)
end

function PLAYER:RKSGag(GaggedBy)
	if !self.RKRestrained then return end
	local Distance = GaggedBy:EyePos():Distance(self:GetPos());
	if Distance > 100 then return false; end

	if !self.Gagged then
		self.Gagged = true
		self:SetupRKSGag()
    TBFY_Notify(self, 1, 4, string.format(RKS_GetLang("GaggedBy"), GaggedBy:Nick()))
    TBFY_Notify(GaggedBy, 1, 4, string.format(RKS_GetLang("Gagger"), self:Nick()))
	elseif self.Gagged then
		self.Gagged = false
		self:SetupRKSGag()
    TBFY_Notify(self, 1, 4, string.format(RKS_GetLang("UnGaggedBy"), GaggedBy:Nick()))
    TBFY_Notify(GaggedBy, 1, 4, string.format(RKS_GetLang("UnGagger"), self:Nick()))
	end

	hook.Call("RKS_Gag", GAMEMODE, self, GaggedBy)
end
net.Receive("rks_gag", function(len, Player)
	if !Player:RKS_CanGag() then return end
	if !IsValid(Player:GetActiveWeapon()) or Player:GetActiveWeapon():GetClass() != "weapon_r_restrains" then return false end

	local PToGag = net.ReadEntity()
	PToGag:RKSGag(Player)
end)

net.Receive("rks_inspect", function(len, Player)
	if !Player:RKS_CanSteal() then return end
	if !IsValid(Player:GetActiveWeapon()) or Player:GetActiveWeapon():GetClass() != "weapon_r_restrains" then return false end

	local ToInspect = net.ReadEntity()
	if !ToInspect.RKRestrained then return end
	local Distance = Player:EyePos():Distance(ToInspect:GetPos());
	if Distance > 100 then return false; end

	local TotalWeps = #ToInspect.RKSStoreWTBL
	net.Start("rks_send_inspect_information")
		net.WriteEntity(ToInspect)
		net.WriteFloat(TotalWeps)
		for k,v in pairs(ToInspect.RKSStoreWTBL) do
			net.WriteFloat(k)
			net.WriteString(v.Class)
		end
	net.Send(Player)
end)

net.Receive("rks_stealcash", function(len, Player)
	if !DarkRP or !Player:RKS_CanSteal() then return end
	if !IsValid(Player:GetActiveWeapon()) or Player:GetActiveWeapon():GetClass() != "weapon_r_restrains" then return false end

	local StealFrom, Amount = net.ReadEntity(), net.ReadFloat()
	if !StealFrom.RKRestrained then return end
	local Distance = Player:EyePos():Distance(StealFrom:GetPos());
	if Distance > 100 then return false; end
	if StealFrom.RKSNextMoneySteal and StealFrom.RKSNextMoneySteal > CurTime() then
		local TimeLeft = math.Round(StealFrom.RKSNextMoneySteal - CurTime())
		TBFY_Notify(Player, 1, 4, string.format(RKS_GetLang("RobbCD"), StealFrom:Nick(),TimeLeft))
		return false
	end

	if RKS_GetConf("INSPECT_MoneyStealRandomAmount") then
		Amount = math.random(1,RKS_GetConf("INSPECT_MaxStolenMoney"))
	else
		Amount = math.Clamp(Amount, 0, RKS_GetConf("INSPECT_MaxStolenMoney"))
	end
	if Amount < 1 then return end
	if !StealFrom:canAfford(Amount) then
		TBFY_Notify(Player, 1, 4, string.format(RKS_GetLang("CantAfford"), StealFrom:Nick()))
		return
	end

	Player:addMoney(Amount)
	StealFrom:addMoney(-Amount)

	StealFrom.RKSNextMoneySteal = CurTime() + RKS_GetConf("INSPECT_MoneyStolenCooldown")
	TBFY_Notify(Player, 1, 4, string.format(RKS_GetLang("RobberSuccess"), Amount, StealFrom:Nick()))
	TBFY_Notify(StealFrom, 1, 4, string.format(RKS_GetLang("RobbedSuccess"), Player:Nick(), Amount))
end)

local function IsJobRanksLoadout(Player, Wep)
	local Rank = Player:GetJobRank()
	local Job = Player:Team()
	local WMatched = false

	if JobRanks and JobRanks[Job] then
		local JobTbl = JobRanks[Job]
		if JobTbl.ExtraLoadoutSingleRank and JobTbl.ExtraLoadoutSingleRank[Rank] then
			local SLoadout = JobTbl.ExtraLoadoutSingleRank[Rank]
			for k,v in pairs(SLoadout) do
				if v == Wep then
					WMatched = true
					break
				end
			end
		end
		if !WMatched and JobTbl.ExtraLoadout then
			local RLoadout = JobTbl.ExtraLoadout
			for k,v in pairs(RLoadout) do
				if v <= Rank and k == Wep then
					WMatched = true
					break
				end
			end
		end
	end
	return WMatched
end

net.Receive("rks_stealweapon", function(len, Player)
	if !Player:RKSAccess() or !RKidnapConfig.AllowStealingWeapons then return end
	if !IsValid(Player:GetActiveWeapon()) or Player:GetActiveWeapon():GetClass() != "weapon_r_restrains" then return false end

	local StealFrom, WepTblID = net.ReadEntity(), net.ReadFloat()
	if !StealFrom.RKRestrained then return end
	local Distance = Player:EyePos():Distance(StealFrom:GetPos());
	if Distance > 100 then return false; end
	if !StealFrom.RKSStoreWTBL[WepTblID] then return false end
	local WeaponClass = StealFrom.RKSStoreWTBL[WepTblID].Class

	if WeaponClass then
		if RKidnapConfig.BlackListedWeapons[WeaponClass] then return end

		local jobTable = {}
		if DarkRP then
			jobTable = StealFrom:getJobTable()
		end

		if RKidnapConfig.AllowStealingJobWeapons or (jobTable.weapons and !table.HasValue(jobTable.weapons, WeaponClass) and (!JobRanksConfig or !IsJobRanksLoadout(StealFrom, WeaponClass))) then
			Player:Give(WeaponClass)
			if CH_Armory_Locker and StealFrom.CH_ARMORY_NoDropWeapons[Wep] then
				StealFrom.CH_ARMORY_NoDropWeapons[Wep] = nil
			end
			StealFrom.RKSStoreWTBL[WepTblID] = nil
		end
	end
end)

concommand.Add("rks_togglerestrains", function(Player, CMD, Args)
	if !Player:IsAdmin() then return end

	if !Args or !Args[1] then return end

	local Nick = string.lower(Args[1]);
	local PFound = false

	for k, v in pairs(player.GetAll()) do
		if (string.find(string.lower(v:Nick()), Nick)) then
			PFound = v;
			break;
		end
	end

	if PFound then
		PFound:RKSRestrain(Player)
	end
end)

hook.Add("canDropWeapon", "RKS_DisableDropWeapon", function(Player)
	if Player.RKS_BeingRestrained or Player.RKRestrained then return false end
end)

hook.Add("onDarkRPWeaponDropped", "RKS_NoDrop", function(Player, Wep, EqpWep)
	if EqpWep:GetClass() == "weapon_r_restrains" then
		Wep:SetModel("models/tobadforyou/flexcuffs_deployed.mdl")
	end
	if Player.RKS_BeingRestrained or Player.RKRestrained then
		timer.Simple(0.1, function() if IsValid(Wep) then Wep:Remove() end end)
	end
end)

local RKS_DCPlayers = RKS_DCPlayers or {}
hook.Add("PlayerInitialSpawn", "RKS_InitSpawn", function(Player)
    //Allow to intialize fully first
    timer.Simple(8, function()
		if IsValid(Player) then
			for k,v in pairs(ents.FindByClass("rrestrainsent")) do
				net.Start("rks_sendrestrains")
					net.WriteEntity(v.RestrainedPlayer)
					net.WriteEntity(v)
				net.Send(Player)
			end
			for k,v in pairs(ents.FindByClass("rblindfoldent")) do
				net.Start("rks_sendblindfold")
					net.WriteEntity(v.BlindfoldedPlayer)
					net.WriteEntity(v)
					net.WriteBool(v.Female)
				net.Send(Player)
			end
			for k,v in pairs(ents.FindByClass("rgagent")) do
				net.Start("rks_sendgag")
					net.WriteEntity(v.GaggedPlayer)
					net.WriteEntity(v)
					net.WriteBool(v.Female)
				net.Send(Player)
			end

			if RKS_GetConf("RESTRAINS_TeleportBackDisconnectPlayers") then
				local SID = Player:SteamID()
				local DCTable = RKS_DCPlayers[SID]
				if DCTable then
					local Restrainer = DCTable.Restrainer
					if IsValid(Restrainer) then
						Player:RKSRestrain(Restrainer)
						local Pos = TBFY_findEmptyPos(Restrainer:GetPos(), {Player}, 600, 30, Vector(16, 16, 64))
						Player:SetPos(Pos)
						TBFY_Notify(Player, 1, 4, RKS_GetLang("DisconnectRestrained"))
					end
					RKS_DCPlayers[SID] = nil
				end
			end
		end
    end)
end)

hook.Add("PlayerCanHearPlayersVoice", "RKS_BlockVoiceChatWhenGagged", function(Listener, Talker)
	if Talker.Gagged then
		return false
	end
end)

hook.Add("PlayerSay", "RKS_BlockChatWhenGagged", function( Player, text, public )
	if Player.Gagged then
		return ""
	end
end)

hook.Add("PlayerDeath", "RKS_ResetOnDeath", function( Player, Inflictor, Attacker )
    if Player.RKRestrained or Player.Gagged or Player.Blindfolded then
        Player:CleanUpRKS(false, true)
    end
end)

function PLAYER:CanRKSDrag(CPlayer)
    if self.RKRestrained or !CPlayer.RKRestrained or (CPlayer.RKSDraggedBy or self.RKSDragging) and (self.RKSDragging != CPlayer or CPlayer.RKSDraggedBy != self) then return end
	return true
end

local RKSPGettingDragged = {}
function PLAYER:RKSDragPlayer(TPlayer)
    if self == TPlayer.RKSDraggedBy then
        TPlayer:RKSCancelDrag()
    elseif !self.RKSDragging then
		TPlayer.RKSDraggedBy = self
        TPlayer:Freeze(true)
        self.RKSDragging = TPlayer
        if !table.HasValue(RKSPGettingDragged, TPlayer) then
            table.insert(RKSPGettingDragged, TPlayer)
        end
    end
end

function PLAYER:RKSCancelDrag()
  if table.HasValue(RKSPGettingDragged, self) then
      table.RemoveByValue(RKSPGettingDragged, self)
  end
	if IsValid(self) then
		self:Freeze(false)
		local DraggedByP = self.RKSDraggedBy
		if IsValid(DraggedByP) then
			DraggedByP.RKSDragging = nil
		end
		self.RKSDraggedBy = nil
	end
end

function PLAYER:RKS_RemoveAttatch(UnAttatchPlayer)
	local AttatchEnt = self.RKS_AEnt
	if IsValid(AttatchEnt) then
		AttatchEnt:Remove()
	end
	local AEnt = self.RKS_AttachtedTo
	if IsValid(AEnt) then
		self.RKS_AttachtedTo.AttatchedPlayer = nil
	end

	if IsValid(UnAttatchPlayer) then
		TBFY_Notify(UnAttatchPlayer, 1, 4, string.format(RKS_GetLang("UnAttatchedPlayer"), self:Nick()))
	end

	self.RKS_AEnt = nil
	self.RKS_Attatched = false
	self:SetNWEntity("RKS_AttatchEnt", nil)
	self:SetNWBool("RKS_Attatched", false)
end

function PLAYER:RKS_AttatchPlayer(APlayer, Pos, AEnt)
	if IsValid(AEnt) then
		if !RKS_GetConf("RESTRAINS_EnableAttachEntity") then
			TBFY_Notify(self, 1, 4, "Players may not be attached to entities.")
			return
		end
		if AEnt:IsVehicle() or AEnt:IsPlayer() or !IsValid(AEnt:GetPhysicsObject()) or RKidnapConfig.AttatchmentBlacklistEntities[AEnt:GetClass()] then return end
		if AEnt:GetPhysicsObject():IsMotionEnabled() then
			TBFY_Notify(self, 1, 4, RKS_GetLang("MustBeFrozen"))
			return
		end
	end

	APlayer:RKSCancelDrag()

	local AttatchEnt = APlayer.RKS_AEnt
	if !IsValid(AttatchEnt) then
		AttatchEnt = ents.Create("rks_attatch")
		AttatchEnt:Spawn()
	end

	AttatchEnt:SetPos(APlayer:GetPos())
	AttatchEnt:SetOwningPlayer(APlayer)
	AttatchEnt:SetAttatchedEntity(AEnt)
	AttatchEnt:SetAttatchPosition(Pos)
	AttatchEnt:SetParent(APlayer)

	APlayer.RKS_AEnt = AttatchEnt
	APlayer.RKS_AttachtedTo = AEnt
	if IsValid(AEnt) then
		AEnt.AttatchedPlayer = APlayer
	end
	APlayer.RKS_Attatched = true

	APlayer:SetNWEntity("RKS_AttatchEnt", AttatchEnt)
	APlayer:SetNWBool("RKS_Attatched", true)

	TBFY_Notify(self, 1, 4, string.format(RKS_GetLang("AttatchedPlayer"), APlayer:Nick()))
end

-- Devamı...

hook.Add("PlayerDisconnected", "RKS_PDisconnect", function(Player)
	local Dragger = Player.RKSDraggedBy
	if IsValid(Dragger) then
		if table.HasValue(RKSPGettingDragged, Player) then
			table.RemoveByValue(RKSPGettingDragged, Player)
		end
		Dragger.RKSDragging = false
	end
	if IsValid(Player.Gag) then
		Player.Gag:Remove()
	end
	if IsValid(Player.Blindfold) then
		Player.Blindfold:Remove()
	end
	if IsValid(Player.Restrains) then
		Player.Restrains:Remove()
	end
	if IsValid(Player.RKSRagdoll) then
		Player.RKSRagdoll:Remove()
	end

	if Player.RKRestrained and RKS_GetConf("RESTRAINS_TeleportBackDisconnectPlayers") then
		local Restrainer = Player.RestrainedBy
		if IsValid(Restrainer) then
			RKS_DCPlayers[Player:SteamID()] = {Restrainer = Restrainer}
		end
	end
end)

hook.Add("PhysgunPickup", "RKS_PhysgunPickup", function(Player, Entity)
	if IsValid(Entity.AttatchedPlayer) then
		return false
	end
end)

hook.Add("CanPlayerUnfreeze", "RKS_CanUnFreezeEnt", function(Player, Entity)
	if IsValid(Entity.AttatchedPlayer) then
		return false
	end
end)

hook.Add("EntityRemoved", "RKS_EntityRemoved", function(Entity)
	if IsValid(Entity.AttatchedPlayer) then
		Entity.AttatchedPlayer:RKS_RemoveAttatch()
	end
end)


hook.Add("KeyPress", "RKS_keypress", function(Player, Key)
	if Key == IN_USE and !Player:InVehicle() then
		local Trace = {}
		Trace.start = Player:GetShootPos();
		Trace.endpos = Trace.start + Player:GetAimVector() * 100;
		Trace.filter = Player;

		local Tr = util.TraceLine(Trace);
		local TEnt = Tr.Entity

		local ValidEnt = IsValid(TEnt)
		local DraggedP = Player.RKSDragging
		if ValidEnt and TEnt:IsPlayer() then
			if TEnt:GetNWBool("RKS_Attatched", false) then
				TEnt:RKS_RemoveAttatch(Player)
			end
		elseif IsValid(DraggedP) and RKS_GetConf("RESTRAINS_EnableAttach") then
			local Pos = Tr.HitPos
			if ValidEnt then
				Pos = TEnt:GetPos()
			end
			if Pos:Distance(DraggedP:GetPos()) < 100 then
				Player:RKS_AttatchPlayer(DraggedP, Pos, TEnt)
			else
				TBFY_Notify(Player, 1, 4, RKS_GetLang("TooFarAway"))
			end
		end
  end
end)

net.Receive("rks_drag", function(len, Player)
	local TPlayer = net.ReadEntity()
	local Distance = Player:EyePos():Distance(TPlayer:GetPos());
	if Distance > 100 or !TPlayer:IsPlayer() then return false; end
	if Player:CanRKSDrag(TPlayer) then
		Player:RKSDragPlayer(TPlayer)
	end
end)

-- Think hook yerine timer kullan
timer.Create("RKS_HandlePlayerDraggingRange", 0.1, 0, function()
	local DragRange = RKS_GetConf("DRAG_MaxRange")
		for k,v in pairs(RKSPGettingDragged) do
        if !IsValid(v) then table.RemoveByValue(RKSPGettingDragged, v) end
        local DPlayer = v.RKSDraggedBy
        if IsValid(DPlayer) then
            local Distance = v:GetPos():Distance(DPlayer:GetPos());
            if Distance > DragRange then
                v:RKSCancelDrag()
            end
        else
            v:RKSCancelDrag()
        end
    end
end)

hook.Add("CanPlayerEnterVehicle", "RKS_RestrictEnterVehicle", function(Player, Vehicle)
    if Player.RKRestrained and !Player.RKSDraggedBy then
        TBFY_Notify(Player, 1, 4, RKS_GetLang("CantEnterVehicle"))
        return false
	elseif Player.RKSDragging then
		return false
    end
end)

hook.Add("PlayerEnteredVehicle", "RKS_RestrainsVFix", function(Player,Vehicle)
    if Player.RKRestrained then
        Player:CleanUpRKS(false, false,true)
        Player.RKRestrained = true
    end
end)

hook.Add("PlayerLeaveVehicle", "RKS_LeaveVehicle", function(Player, Vehicle)
    if Player.RKRestrained then
		Player:SetupRestrains()
		if RKS_GetConf("RESTRAINS_StarWarsRestrains") then
			Player:SetupRKSBones("Restrained_StarWars")
		else
			Player:SetupRKSBones("Restrained")
		end
    end
end)

hook.Add("CanExitVehicle", "RKS_RestrictExitVehicle", function(Vehicle, Player)
    if Player.RKRestrained then
        TBFY_Notify(Player, 1, 4, RKS_GetLang("CantLeaveVehicle"))
        return false
    end
end)

hook.Add("PlayerSpawnProp", "RKS_DisablePropSpawning", function(Player)
    if Player.RKRestrained then
        TBFY_Notify(Player, 1, 4, RKS_GetLang("CantSpawnProps"))
        return false
    end
end)

hook.Add("PlayerCanPickupWeapon", "RKS_DisableWeaponPickup", function(Player, Wep)
	if Player.RKRestrained and Wep:GetClass() != "weapon_r_restrained" then return false end
end)

hook.Add("playerCanChangeTeam", "RKS_RestrictTeamChange", function(Player, Team)
    if Player.RKRestrained then return false, RKS_GetLang("CantChangeTeam") end
end)

hook.Add("CanPlayerSuicide", "RKS_DisableSuicide", function(Player)
	if Player.RKRestrained or Player.RKSKnockedOut then return false end
end)

hook.Add("NOVA_CanChangeSeat", "RKS_NovacarsDisableSeatChange", function(Player)
	if Player.RKRestrained then
		return false, RKS_GetLang("CantSwitchSeat")
	end
end)

hook.Add("VC_CanEnterPassengerSeat", "RKS_VCMOD_EnterSeat", function(Player, Seat, Vehicle)
    local DraggedPlayer = Player.RKSDragging
    if IsValid(DraggedPlayer) then
        DraggedPlayer:EnterVehicle(Seat)
        return false
    end
end)

hook.Add("VC_CanSwitchSeat", "RKS_VCMOD_SwitchSeat", function(Player, SeatFrom, SeatTo)
	if Player.RKRestrained then
		return false
	end
end)

hook.Add("PlayerHasBeenTazed", "RKS_FixRestrainsTaze", function(Player)
    if Player.RKRestrained then
        Player:CleanUpRKS(false, false,true)
        Player.RKRestrained = true
    end
end)

hook.Add("PlayerUnTazed", "RKS_FixRestrainsUnTaze", function(Player)
    if Player.RKRestrained then
        Player:SetupRestrains()
				if RKS_GetConf("RESTRAINS_StarWarsRestrains") then
					Player:SetupRKSBones("Restrained_StarWars")
				else
					Player:SetupRKSBones("Restrained")
				end
    end
end)

hook.Add("onDarkRPWeaponDropped", "RKS_RemoveRestrainsSurrOnDeath", function(Player, Ent, Wep)
	if Wep:GetClass() == "weapon_r_restrained" or Wep:GetClass() == "tbfy_surrendered" then
		Ent:Remove()
	end
end)