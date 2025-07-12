include("shared.lua")

local preset = {
    {p = 0.7, a = -30, o = 0.9},
    {p = 0.1, a = -16, o = 1.8},
    {p = 0, a = 16, o = 3},
    {p = 0.3, a = 35, o = 4.1},
}

function ENT:Initialize()
    -- Rebuild the panels table client side, without needing to do any extra networking.
    self.panels = {}
    for k, v in ipairs(self:GetChildren()) do
        if v:GetClass() == "pcasino_blackjack_panel" then
            table.insert(self.panels, v)
        end
    end
    -- Flip the table
    self.panels = table.Reverse(self.panels)
    for k, v in pairs(self.panels) do
        v.order = k
    end
    
    self.currentBid = 0
    self.active = false
    self.currentBets = {}
    self.currentCards = {}
    self.curHands = {}
    
    self.hasInitialized = true
    
    -- Optimization: Cache models
    self.cachedModels = {
        chip = "models/freeman/owain_casino_chip.mdl",
        plaque = "models/freeman/owain_casino_plaque.mdl",
        card = "models/freeman/owain_playingcards.mdl"
    }
end

function ENT:PostData()
    if not self.hasInitialized then
        self:Initialize()
    end
    
    self.currentBid = self.data.bet.default
end

function ENT:OnRemove()
    self:ClearBets()
    self:ClearCards()
end

-- Optimized drawing
local surface_setdrawcolor = surface.SetDrawColor
local surface_drawrect = surface.DrawRect
local draw_simpletext = draw.SimpleText
local black = Color(0, 0, 0, 200)
local white = Color(255, 255, 255, 100)

-- Cache calculations
local distCheckSqr = 25000

function ENT:DrawTranslucent()
    -- Early distance check
    if self:GetPos():DistToSqr(LocalPlayer():GetPos()) > distCheckSqr then return end
    
    -- Data check with optimized cooldown
    if not self.data then
        if not PerfectCasino.Cooldown.Check(self:EntIndex(), 5) then
            PerfectCasino.Core.RequestConfigData(self)
        end
        return
    end
    
    -- Cache timer text
    if not (self:GetStartRoundIn() == -1) then
        local pos = self:GetPos()
        local ang = self:GetAngles()
        ang:RotateAroundAxis(ang:Forward(), 90)
        ang:RotateAroundAxis(ang:Right(), -90)
        
        -- Use cached text calculation
        local timeLeft = self.data.general.betPeriod - (os.time() - self:GetStartRoundIn())
        if timeLeft < 0 then return end
        
        cam.Start3D2D(pos + (ang:Up()*-22) + (ang:Right()*-19.7) + (ang:Forward()*-4.5), ang, 0.05)
            surface_setdrawcolor(black)
            surface_drawrect(5, 5, 190, 65)
            surface_setdrawcolor(white)
            surface_drawrect(0, 0, 200, 5)
            surface_drawrect(0, 5, 5, 65)
            surface_drawrect(195, 5, 5, 65)
            surface_drawrect(0, 70, 200, 5)
            
            draw_simpletext(string.format(PerfectCasino.Translation.UI.Start, timeLeft), "pCasino.Entity.Bid", 100, 37, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end
    
    -- Draw card values
    if not self.currentCards or not self.currentCards[0] then return end
    
    for k, v in pairs(self.currentCards) do
        for i, h in pairs(v) do
            if not h[1] then continue end
            
            local masterCard = h[1]
            if not IsValid(masterCard) then continue end
            
            local ang = masterCard:GetAngles()
            ang:RotateAroundAxis(ang:Right(), -90)
            ang:RotateAroundAxis(ang:Up(), 90)
            
            local pos = masterCard:GetPos() + (ang:Forward()*-2.4) + (ang:Right()*1.2)
            
            cam.Start3D2D(pos, ang, 0.04)
                surface_setdrawcolor(black)
                surface_drawrect(-20, -20, 40, 40)
                surface_setdrawcolor(white)
                surface_drawrect(-20, -20, 2, 38)
                surface_drawrect(-18, -20, 38, 2)
                surface_drawrect(18, -18, 2, 38)
                surface_drawrect(-20, 18, 38, 2)
                
                draw_simpletext(PerfectCasino.Cards:GetHandValue(self.curHands[k][i]), "pCasino.Header.Static", -1, 0, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            cam.End3D2D()
        end 
    end
end

-- Optimized chip creation
function ENT:AddBet(pad, amount)
    self.currentBets[pad] = self.currentBets[pad] or {}
    
    local chips = PerfectCasino.Chips:GetFromNumber(amount)
    local ang = self:GetAngles()
    
    -- Batch chip creation
    for k=#PerfectCasino.Chips.Types, 0, -1 do
        if not chips[k] then continue end
        
        for i=1, chips[k] do
            local plaque = k >= 11
            local model = plaque and self.cachedModels.plaque or self.cachedModels.chip
            
            local chip = ClientsideModel(model)
            table.insert(self.currentBets[pad], chip)
            chip:SetParent(self)
            chip:SetSkin(plaque and k-11 or k)
            
            local stackHeight = #self.currentBets[pad]
            chip:SetPos(self:GetPos() + 
                (self:GetUp() * (15.8 + stackHeight * 0.3)) + 
                (self:GetForward() * (8 - 10 * preset[pad].p)) + 
                (self:GetRight() * -13 * (pad - 2.5)))
            chip:SetAngles(ang)
        end
    end
end

function ENT:ClearBets()
    for _, pad in pairs(self.currentBets) do
        for k, v in pairs(pad) do
            if IsValid(v) then
                v:Remove()
            end
        end
    end
    self.currentBets = {}
end

-- Optimized card creation
function ENT:AddCard(pad, hand, face)
    self.currentCards[pad] = self.currentCards[pad] or {}
    self.currentCards[pad][hand] = self.currentCards[pad][hand] or {}
    
    local ang = self:GetAngles()
    ang:RotateAroundAxis(ang:Right(), 90)
    ang:RotateAroundAxis(ang:Forward(), preset[pad] and preset[pad].a or 0)
    
    local card = ClientsideModel(self.cachedModels.card)
    table.insert(self.currentCards[pad][hand], card)
    card:SetParent(self)
    
    if face then 
        local skin, bodygroup = PerfectCasino.Cards:GetFaceData(face)
        card:SetBodygroup(1, bodygroup)
        card:SetSkin(skin)
        card:SetAngles(ang)
    else
        ang:RotateAroundAxis(ang:Right(), 180)
        ang:RotateAroundAxis(ang:Forward(), 180)
        card:SetAngles(ang)
    end
    
    -- Optimized positioning
    if pad == 0 then
        local cardCount = #self.currentCards[pad][hand]
        card:SetPos(self:GetPos() + 
            (self:GetUp() * 15.8) + 
            (self:GetForward() * -7) + 
            (self:GetRight() * (10 - 3 * cardCount)))
    else
        local cardCount = #self.currentCards[pad][hand]
        if cardCount == 1 then
            card:SetPos(self:GetPos() + 
                (self:GetUp() * 15.8) + 
                (self:GetForward() * (2 - 9 * (preset[pad].p + (cardCount-1) * 0.1))) + 
                (self:GetRight() * -10 * (preset[pad].o - 2.7)))
            
            card:SetPos(card:GetPos() + (-card:GetRight() * 4 * (hand-1)))
        else
            local baseCard = self.currentCards[pad][hand][cardCount - 1]
            if IsValid(baseCard) then
                card:SetPos(baseCard:GetPos() + 
                    (self:GetUp() * (cardCount * 0.02)) + 
                    (-baseCard:GetRight() * 0.6) + 
                    (baseCard:GetUp() * 0.5))
            end
        end
    end
end

function ENT:ClearCards()
    for _, pad in pairs(self.currentCards) do
        for k, h in ipairs(pad) do
            for _, c in ipairs(h) do
                if IsValid(c) then
                    c:Remove()
                end
            end
        end
    end
    self.currentCards = {}
end

-- Optimized network receivers
net.Receive("pCasino:Blackjack:Bet:Change", function()
    local entity = net.ReadEntity()
    if not IsValid(entity) then return end
    if not entity.data then return end
    
    entity.currentBid = net.ReadUInt(32)
end)

net.Receive("pCasino:Blackjack:Bet:Place", function()
    local entity = net.ReadEntity()
    if not IsValid(entity) then return end
    if not entity.data then return end
    
    -- Distance check optimization
    if entity:GetPos():DistToSqr(LocalPlayer():GetPos()) > 100000 then return end
    
    local pad = net.ReadUInt(3)
    local betAmount = net.ReadUInt(32)
    
    entity:AddBet(pad, betAmount)
end)

net.Receive("pCasino:Blackjack:Clear", function()
    local entity = net.ReadEntity()
    if not IsValid(entity) then return end
    
    entity:ClearBets()
    entity:ClearCards()
    entity.curHands = {}
end)

net.Receive("pCasino:Blackjack:StartingCards", function()
    local entity = net.ReadEntity()
    if not IsValid(entity) then return end
    if not entity.data then return end
    
    -- Distance check optimization
    if entity:GetPos():DistToSqr(LocalPlayer():GetPos()) > 100000 then return end
    
    local hands = net.ReadTable()
    local dealersHand = net.ReadTable()
    
    -- Batch processing
    for i, p in pairs(hands) do
        entity.curHands[i] = {}
        
        for ih, h in ipairs(p) do
            entity.curHands[i][ih] = {}
            
            for _, c in ipairs(h.cards) do
                table.insert(entity.curHands[i][ih], c)
                entity:AddCard(i, ih, c)
            end
        end
    end
    
    entity.curHands[0] = {{}}
    for k, c in pairs(dealersHand) do
        entity:AddCard(0, 1, c)
        table.insert(entity.curHands[0][1], c)
    end
    entity:AddCard(0, 1) -- The dealer's blind card
end)

net.Receive("pCasino:Blackjack:NewCard", function()
    local entity = net.ReadEntity()
    if not IsValid(entity) then return end
    if not entity.data then return end
    
    -- Distance check optimization
    if entity:GetPos():DistToSqr(LocalPlayer():GetPos()) > 100000 then return end
    
    local pad = net.ReadUInt(3)
    local hand = net.ReadUInt(3)
    local card = net.ReadString()
    
    if not entity.curHands or not entity.curHands[pad] or not entity.curHands[pad][hand] then return end
    
    table.insert(entity.curHands[pad][hand], card)
    entity:AddCard(pad, hand, card)
end)

net.Receive("pCasino:Blackjack:Split", function()
    local entity = net.ReadEntity()
    if not IsValid(entity) then return end
    if not entity.data then return end
    
    -- Distance check optimization
    if entity:GetPos():DistToSqr(LocalPlayer():GetPos()) > 100000 then return end
    
    local pad = net.ReadUInt(3)
    local hands = net.ReadTable()
    
    -- Clear existing cards efficiently
    if entity.currentCards[pad] then
        for k, v in pairs(entity.currentCards[pad]) do
            for n, m in pairs(v) do
                if IsValid(m) then
                    m:Remove()
                end
            end
        end
    end
    
    entity.curHands[pad] = {}
    entity.currentCards[pad] = {}
    
    -- Batch card creation
    for i, h in ipairs(hands) do
        entity.curHands[pad][i] = {}
        for _, c in ipairs(h.cards) do
            table.insert(entity.curHands[pad][i], c)
            entity:AddCard(pad, i, c)
        end
    end
end)

net.Receive("pCasino:Blackjack:DealerCards", function()
    local entity = net.ReadEntity()
    if not IsValid(entity) then return end
    if not entity.data then return end
    
    -- Distance check optimization
    if entity:GetPos():DistToSqr(LocalPlayer():GetPos()) > 100000 then return end
    
    local dealersCards = net.ReadTable()
    
    -- Remove the blind card
    if entity.currentCards and entity.currentCards[0] and entity.currentCards[0][1] and entity.currentCards[0][1][2] then
        if IsValid(entity.currentCards[0][1][2]) then
            entity.currentCards[0][1][2]:Remove()
            entity.currentCards[0][1][2] = nil
        end
    end
    
    -- Batch timer creation for cards
    for i=2, #dealersCards do
        timer.Simple(i-2, function()
            if not IsValid(entity) then return end
            entity:AddCard(0, 1, dealersCards[i])
            table.insert(entity.curHands[0][1], dealersCards[i])
        end)
    end
end)