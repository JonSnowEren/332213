ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.Category = "ToBadForYou"

ENT.Spawnable = false
ENT.PrintName		= "Attatch Entity"
ENT.Author			= "ToBadForYou"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "OwningPlayer")
	self:NetworkVar("Entity", 1, "AttatchedEntity")
	self:NetworkVar("Vector", 0, "AttatchPosition")
end