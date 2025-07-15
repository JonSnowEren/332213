include('shared.lua')

function ENT:Initialize()

end

function ENT:Think ()
end

local AttMat = Material("cable/cable")
function ENT:Draw()
	local Player = self:GetOwningPlayer()
	local AEnt = self:GetAttatchedEntity()
	local APos = self:GetAttatchPosition()
	if IsValid(AEnt) then
		APos = AEnt:GetPos()
	end
	if IsValid(Player) then
		local Bone = Player:LookupBone("ValveBiped.Bip01_R_Hand")
		if Bone then
			local Pos, Ang = Player:GetBonePosition(Bone)
			local FPos = Pos + Ang:Forward() * 1.7 + Ang:Right() * 5 + Ang:Up() * -3.7

			self:SetPos(FPos)
			self:SetAngles(Ang)

			render.SetMaterial(AttMat)
			render.DrawBeam(self:GetPos(), APos, 1, 0, 0, Color(255, 255, 255, 255))
		end
	end
end

function ENT:OnRemove( )
end