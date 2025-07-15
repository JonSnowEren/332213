if SERVER then
	AddCSLuaFile("shared.lua")
end

if CLIENT then
	SWEP.PrintName = "Restrains"
	SWEP.Slot = 2
	SWEP.SlotPos = 1
	SWEP.DrawAmmo = false
	SWEP.DrawCrosshair = false
end

SWEP.Author = "ToBadForYou"
SWEP.Instructions = "Left Click: Restrain/Release. \nRight Click: Force Players out of vehicle.\nReload: Blindfold/Gag/Inspect"
SWEP.Contact = ""
SWEP.Purpose = ""

SWEP.HoldType = "melee";
SWEP.UseHands = true

SWEP.ViewModelFOV = 62
SWEP.ViewModelFlip = false
SWEP.AnimPrefix	 = "melee"
SWEP.Category = "ToBadForYou"
SWEP.UID = 76561197989708503

SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = ""

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""

function SWEP:Initialize()
	self:SetHoldType("melee")
	if RKS_GetConf("RESTRAINS_StarWarsRestrains") then
		self.ViewModel = "models/casual/handcuffs/c_handcuffs.mdl";
		self.WorldModel = "models/casual/handcuffs/handcuffs.mdl";
		self.PlayBackRate = 1.5
	else
		self.ViewModel = "models/tobadforyou/c_flexcuffs.mdl";
		self.WorldModel = "models/tobadforyou/flexcuffs_deployed.mdl";
		self.PlayBackRate = 1.8
	end
end

function SWEP:CanPrimaryAttack ( ) return true; end

function SWEP:Think()
	local PlayerToRestrain = self.AttemptToRestrain
	if IsValid(PlayerToRestrain) then
		local vm = self.Owner:GetViewModel();

		local sequence
		if RKS_GetConf("RESTRAINS_StarWarsRestrains") then
	  	sequence = "draw"
		else
			sequence = "Reset"
		end

		local ResetSeq, Time1 = vm:LookupSequence(sequence)
		local CancelRestrain
		if self.RestrainingRagdoll then
			CancelRestrain = PlayerToRestrain:GetPos():Distance(self.Owner:GetPos()) > 350
		else
			local TraceEnt = self.Owner:GetEyeTrace().Entity
			CancelRestrain = !IsValid(TraceEnt) or TraceEnt != PlayerToRestrain or TraceEnt:GetPos():Distance(self.Owner:GetPos()) > RKS_GetConf("RESTRAINS_RestrainRange")
		end

		if CancelRestrain then
			if self.RestrainingRagdoll then
				PlayerToRestrain.RagdollRestrained = true
			else
				PlayerToRestrain.RKS_BeingRestrained = false
			end
			self.AttemptToRestrain = nil
			vm:SendViewModelMatchingSequence(ResetSeq)
			vm:SetPlaybackRate(self.PlayBackRate)
		elseif CurTime() >= self.AttemptRestrainFinish then
			if SERVER then
				if self.RestrainingRagdoll then
					PlayerToRestrain.LastRKSRestrained = self.Owner
					PlayerToRestrain.RKSRestrained = true
				else
					PlayerToRestrain:RKSRestrain(self.Owner)
				end
			end
			if self.RestrainingRagdoll then
				PlayerToRestrain.RagdollCuffed = true
			end
			PlayerToRestrain.RKS_BeingRestrained = false
			self.AttemptToRestrain = nil
			vm:SendViewModelMatchingSequence(ResetSeq)
			vm:SetPlaybackRate(self.PlayBackRate)
		end
	end
end

function SWEP:PrimaryAttack()
	local Player = self.Owner
	local Trace = Player:GetEyeTrace()

	self.Weapon:SetNextPrimaryFire(CurTime() + 3)
	if !Player:RKS_CanRestrain() then if SERVER then TBFY_Notify(Player, 1, 4, "This job can't use this SWEP.") end return end
	self.Weapon:EmitSound("npc/vort/claw_swing" .. math.random(1, 2) .. ".wav")
	Player:SetAnimation(PLAYER_ATTACK1)

	local TPlayer = Trace.Entity
	local Distance = Player:EyePos():Distance(TPlayer:GetPos());
	if Distance > 200 or !IsValid(TPlayer) then return false; end
	if TPlayer:GetNWBool("rhc_cuffed", false) then
		if SERVER then
			TBFY_Notify(Player, 1, 4, RKS_GetLang("CantRestrainCuffed"))
		end
		return
	end

	local RTime = Player:RKS_GetRestrainTime()
	local RestrainingPlayer = TPlayer:IsPlayer() and !IsValid(self.AttemptToRestrain)
	local RestrainingRagdoll = !TPlayer.RagdollRestrained and TPlayer:GetNWBool("CanRKSRestrain", false) and !IsValid(self.AttemptToRestrain)
	if RestrainingPlayer or RestrainingRagdoll then
		if TPlayer:IsPlayer() and TPlayer:RKSImmune() then
			if SERVER then
				TBFY_Notify(Player, 1, 4, RKS_GetLang("JobCantBeRestrained"))
			end
			return
		end

		if !RestrainingRagdoll and (RTime == 0 or TPlayer:GetNWBool("rks_restrained", false)) then
			if SERVER then
				TPlayer:RKSRestrain(Player)
			end
		else
			self.RestrainingRagdoll = !RestrainingPlayer
			self.AttemptToRestrain = TPlayer
			self.AttemptRestrainFinish = CurTime() + RTime
			self.AttemptRestrainStart = CurTime()
			TPlayer.RKS_BeingRestrained = true

			local vm = Player:GetViewModel();
			local DeploySeq, Time = vm:LookupSequence("Deploy")

			vm:SendViewModelMatchingSequence(DeploySeq)
			vm:SetPlaybackRate(self.PlayBackRate)
		end
	end
end

function SWEP:SecondaryAttack()
	if SERVER then
		self.Weapon:SetNextSecondaryFire(CurTime() + 1)
		local Player = self.Owner
		local Trace = Player:GetEyeTrace()

		local TVehicle = Trace.Entity
		local Distance = Player:GetPos():Distance(TVehicle:GetPos());
		if Distance > 300 then return false; end

		if IsValid(TVehicle) and (TVehicle:IsVehicle() or TVehicle.LFS) then
			local Seats = {}
			if TVehicle.LFS then
				Seats = TVehicle:GetPassengerSeats()
			elseif TVehicle.IsSimfphyscar then
				if istable(TVehicle.pSeat) then
					Seats = TVehicle.pSeat
				else
					Seats = {}
				end
			elseif vcmod1 then
				Seats = TVehicle:VC_getSeatsAvailable()
			elseif SVMOD then
				Seats = TVehicle:SV_GetPassengerSeats()
			elseif NOVA_Config then
				Seats = TVehicle.CmodSeats
			elseif TVehicle.Seats then
				Seats = TVehicle.Seats
			end

			if Player.RKSDragging then
				local PlayerDragged = Player.RKSDragging
				if IsValid(PlayerDragged) then
					if SVMOD then
						local result = TVehicle:SV_EnterVehicle(PlayerDragged)
						if result == -3 then
							TBFY_Notify(Player, 1, 4, RKS_GetLang("NoSeats"))
						end
					else
						if table.Count(Seats) < 1 then
							TBFY_Notify(Player, 1, 4, RKS_GetLang("NoSeats"))
							if !IsValid(TVehicle:GetDriver()) then
								PlayerDragged:EnterVehicle(TVehicle)
								TBFY_Notify(Player, 1, 4, RKS_GetLang("PlayerPutInDriver"))
							end
							return
						end
						local foundSeat = false
						for k,v in pairs(Seats) do
							local SeatsDist = Player:GetPos():Distance(v:GetPos())
							if SeatsDist < 80 then
								PlayerDragged:EnterVehicle(v)
								foundSeat = true
								break
							end
						end
						if !foundSeat then
							for k,v in pairs(Seats) do
								local SeatsDist = Player:GetPos():Distance(v:GetPos())
								PlayerDragged:EnterVehicle(v)
								break
							end
						end
					end
				end
			else
				for k,v in pairs(Seats) do
					local Driver = v:GetDriver()
					if IsValid(Driver) and Driver.RKRestrained then
						Driver:ExitVehicle()
					end
				end
			end
		end
	end
end

if CLIENT then
	function SWEP:DrawWorldModel()
		if not IsValid(self.Owner) then
			return
		end

		local boneindex = self.Owner:LookupBone("ValveBiped.Bip01_R_Hand")
		if boneindex then
			local HPos, HAng = self.Owner:GetBonePosition(boneindex)

			local offset = HAng:Right() * 0.5 + HAng:Forward() * 3.3 + HAng:Up() * 0

			HAng:RotateAroundAxis(HAng:Right(), 0)
			HAng:RotateAroundAxis(HAng:Forward(),  -90)
			HAng:RotateAroundAxis(HAng:Up(), 0)

			self:SetRenderOrigin(HPos + offset)
			self:SetRenderAngles(HAng)

			self:DrawModel()
		end
	end

function SWEP:Reload()
	if self.NextRPress and self.NextRPress > CurTime() then return end
	self.NextRPress = CurTime() + 1

	local Player = self.Owner

	local Trace = Player:GetEyeTrace()

	self.Weapon:SetNextPrimaryFire(CurTime() + 3)

	local TPlayer = Trace.Entity
	local Distance = Player:EyePos():Distance(TPlayer:GetPos());
	if Distance > 100 then return false; end

	if TPlayer:GetNWBool("rks_restrained", false) then
		local OptionsMenu = vgui.Create("DMenu")
		if Player:RKS_CanBlind() then
			OptionsMenu:AddOption(RKS_GetLang("Blindfold"), function() net.Start("rks_blindfold") net.WriteEntity(TPlayer) net.SendToServer() end)
		end
		if Player:RKS_CanGag() then
			OptionsMenu:AddOption(RKS_GetLang("Gag"), function() net.Start("rks_gag") net.WriteEntity(TPlayer) net.SendToServer() end)
		end
		if Player:RKS_CanSteal() then
			OptionsMenu:AddOption(RKS_GetLang("Inspect"), function() net.Start("rks_inspect") net.WriteEntity(TPlayer) net.SendToServer() end)
		end
		OptionsMenu:Open()

		OptionsMenu:SetPos(ScrW()/2,ScrH()/2)
	end
end

function SWEP:DrawHUD()
	draw.SimpleText("Left Click: Restrain player","default",ScrW()/2,5,Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP,2,Color(0,0,0,255))
	draw.SimpleText("Right Click: Put dragged player in vehicle","default",ScrW()/2,15,Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP,2,Color(0,0,0,255))
	draw.SimpleText("R: Inspect restrained player","default",ScrW()/2,25,Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP,2,Color(0,0,0,255))
	draw.SimpleText("E: Drag restrained player (While dragging aim at prop/surface to attatch player)","default",ScrW()/2,35,Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP,2,Color(0,0,0,255))

	local PlayerToRestrain = self.AttemptToRestrain
	if !IsValid(PlayerToRestrain) then return end

    local time = self.AttemptRestrainFinish - self.AttemptRestrainStart
    local curtime = CurTime() - self.AttemptRestrainStart
    local percent = math.Clamp(curtime / time, 0, 1)
    local w = ScrW()
    local h = ScrH()
	local Nick = ""
	if self.RestrainingRagdoll then
		Nick = RKS_GetLang("KnockedOutPlayer")
	else
		Nick = PlayerToRestrain:Nick()
	end

	local TPercent = math.Round(percent*100)
	local TextToDisplay = string.format(RKS_GetLang("RestrainingText"), Nick)
    draw.DrawText(TextToDisplay .. "(" .. TPercent .. "%)", "Trebuchet24", w/2, h/2, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end
end
