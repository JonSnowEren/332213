-- realisticidnapsystem/lua/weapons/weapon_r_baton/shared.lua

if SERVER then
    AddCSLuaFile("shared.lua")
end

if CLIENT then
    SWEP.PrintName = "Baton"
    SWEP.Slot = 2
    SWEP.SlotPos = 1
    SWEP.DrawAmmo = false
    SWEP.DrawCrosshair = false
end

SWEP.Author = "ToBadForYou"
SWEP.Instructions = "Left Click: Knock someone out.\nRight Click (Ranked): Carry/Drop knocked out player."
SWEP.Contact = ""
SWEP.Purpose = ""

-- Baton ile taşıma/bırakma özelliğini kullanabilecek rütbeler (küçük harfle yazın)
local allowedCarryRanks = {
    ["superadmin"] = true,
    ["admin"] = true,
    ["moderator"] = true,
    -- ["vip"] = true,
    -- Buraya izin vermek istediğiniz diğer tüm rütbelerin isimlerini küçük harfle ekleyin
}

SWEP.HoldType = "melee2";
SWEP.ViewModel = "models/weapons/v_stunbaton.mdl"
SWEP.WorldModel = "models/weapons/w_stunbaton.mdl"
SWEP.UseHands = true

SWEP.ViewModelFOV = 62
SWEP.ViewModelFlip = false
SWEP.AnimPrefix  = "melee2"
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

function SWEP:Initialize() self:SetWeaponHoldType("melee2") end

function SWEP:HitFromBack(Player)
    local angle = self.Owner:GetAngles().y - Player:GetAngles().y
    if angle < -180 then angle = 360 + angle end
    if angle <= 100 and angle >= -100 then
        return true
    else
        return false
    end
end

function SWEP:PrimaryAttack()
    local Trace = self.Owner:GetEyeTrace()
    local TPlayer = Trace.Entity
    self.Weapon:SetNextPrimaryFire(CurTime() + 3)
    if !self.Owner:RKS_CanKO() then if SERVER then TBFY_Notify(self.Owner, 1, 4, "This job can't use this SWEP.") end return end

    local Distance = self.Owner:EyePos():Distance(TPlayer:GetPos());
    if Distance > 125 or !IsValid(TPlayer) or !TPlayer:IsPlayer() then return false; end

    if TPlayer:RKSImmune() then if SERVER then TBFY_Notify(self.Owner, 1, 4, "This job can't be knocked out.") end return end
    self.Weapon:EmitSound("npc/vort/claw_swing" .. math.random(1, 2) .. ".wav")
    self.Owner:SetAnimation(PLAYER_ATTACK1)
    self.Weapon:SendWeaponAnim(ACT_VM_HITCENTER)
    timer.Simple(.2, function()
        if IsValid(self.Weapon) then
            self.Weapon:EmitSound("physics/body/body_medium_impact_hard" .. math.random(1, 6) .. ".wav")
            if SERVER then
                TPlayer:RKSKnockout(self.Owner)
            end
        end
    end)
end

-- YENİ EKLENEN FONKSİYON: Sağ tık ile taşıma/bırakma (Debug Print Eklendi)
function SWEP:SecondaryAttack()
    if SERVER then
        self.Weapon:SetNextSecondaryFire(CurTime() + 0.5)
        local Player = self.Owner
        local Trace = Player:GetEyeTrace()
        local TEnt = Trace.Entity

        print("[Baton Debug] Sağ Tık Yapıldı - Oyuncu: " .. Player:Nick())

        local playerRank = ""
        -- Kullandığınız admin moduna göre doğru fonksiyonun başındaki -- işaretini kaldırın!
        -- ULX veya ServerGuard (Genellikle):
        if Player.GetUserGroup then playerRank = string.lower(Player:GetUserGroup()) end
        -- Alternatif ServerGuard:
        -- if Player.sgGetRank then playerRank = string.lower(Player:sgGetRank()) end
        -- FAdmin (Emin değilseniz test edin):
        -- if Player.FAdmin_GetRank then playerRank = string.lower(Player:FAdmin_GetRank()) end

        print("[Baton Debug] Oyuncu Rütbesi: " .. playerRank)

        if playerRank == "" or not allowedCarryRanks[playerRank] then
            print("[Baton Debug] Rütbe kontrolü BAŞARISIZ! İzin verilen rütbe değil veya rütbe alınamadı.")
            return -- Eğer izin verilen rütbeler listesinde yoksa işlemi bitir.
        end

        print("[Baton Debug] Rütbe kontrolü BAŞARILI!")

        if IsValid(Player.RKSDragging) then
            print("[Baton Debug] Oyuncu zaten birini taşıyor. Bırakılıyor: " .. Player.RKSDragging:Nick())
            Player.RKSDragging:RKSCancelDrag()
        else
            print("[Baton Debug] Oyuncu kimseyi taşımıyor. Hedef kontrol ediliyor...")
            if not IsValid(TEnt) then
                 print("[Baton Debug] Hedef Geçersiz!")
                 return
            end
            print("[Baton Debug] Hedef Entity Sınıfı: " .. TEnt:GetClass())

            local Distance = Player:EyePos():Distance(TEnt:GetPos());
            print("[Baton Debug] Hedef Mesafesi: " .. Distance)
            if Distance > 125 then
                print("[Baton Debug] Hedef çok uzakta!")
                return
            end

            local isRagdoll = TEnt:GetClass() == "prop_ragdoll"
            local hasPlayer = IsValid(TEnt.Player)
            local isKnockedOut = hasPlayer and (TEnt.Player.RKSKnockedOut or TEnt.RKSRagdoll)

            print("[Baton Debug] Ragdoll mu?: " .. tostring(isRagdoll) .. " - Oyuncusu Var mı?: " .. tostring(hasPlayer) .. " - Baygın mı?: " .. tostring(isKnockedOut))

            if isRagdoll and hasPlayer and isKnockedOut then
                print("[Baton Debug] Geçerli ragdoll bulundu! Taşıma başlatılıyor: " .. TEnt.Player:Nick())
                Player:RKSDragPlayer(TEnt.Player)
            else
                 print("[Baton Debug] Geçerli ragdoll bulunamadı!")
            end
        end
    end
end