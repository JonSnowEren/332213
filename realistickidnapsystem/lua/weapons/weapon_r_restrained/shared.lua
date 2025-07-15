if SERVER then
	AddCSLuaFile("shared.lua")
end

if CLIENT then
	SWEP.PrintName = "Restrained"
	SWEP.Slot = 2
	SWEP.SlotPos = 1
	SWEP.DrawAmmo = false
	SWEP.DrawCrosshair = false
end

SWEP.Author = "ToBadForYou"
SWEP.Instructions = ""
SWEP.Contact = ""
SWEP.Purpose = ""

SWEP.HoldType = "passive";
SWEP.ViewModelFlip = false
SWEP.AnimPrefix	 = "passive"
SWEP.Category = "ToBadForYou"
SWEP.UID = 76561197989708503

SWEP.Spawnable = false
SWEP.AdminSpawnable = false
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = ""

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""

function SWEP:SetupDataTables()
	self:NetworkVar("Float", 0, "RestrainsHP")
	self:SetRestrainsHP(100)
end

function SWEP:Initialize() self:SetHoldType("passive") end

function SWEP:PrimaryAttack()
	if SERVER and RKS_GetConf("RESTRAINS_EnableEscape") then
		self:SetRestrainsHP(self:GetRestrainsHP() - 0.15)

		if self:GetRestrainsHP() < 1 then
			self.Owner:RKSRestrain(self.Owner)
		end
	end
end
function SWEP:SecondaryAttack() self:PrimaryAttack() end

function SWEP:Think()
	if SERVER then
		local CurT = CurTime()
		local HP = self:GetRestrainsHP()
		if HP < 100 and (self.NextReg or 0) < CurT then
			self:SetRestrainsHP(math.Approach(HP, 100, 0.065))
			self.NextReg = CurTime()+0.05
		end
	end
end

function SWEP:PreDrawViewModel(vm)
    return true
end

function SWEP:DrawWorldModel()
end

if CLIENT then
	function SWEP:DrawHUD()
		local W,H = ScrW()/2, ScrH()/2

		draw.SimpleTextOutlined(RKS_GetLang("RestrainedText"),"Trebuchet24",W,H/6,Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM,2,Color(0,0,0,255))

		if RKS_GetConf("RESTRAINS_EnableEscape") then
			local BoxW = 200
			local BoxSW = W-BoxW/2
			surface.SetDrawColor(Color(0,0,0,255))
			surface.DrawOutlinedRect(BoxSW-1, H/5.5-1, BoxW+2, 27)
			draw.RoundedBox(0, BoxSW, H/5.5, BoxW, 25, Color(110,100,100,255))
			draw.RoundedBox(0, BoxSW, H/5.5, BoxW*self:GetRestrainsHP()/100, 25, Color(50,200,5,200))
		end
	end
end
