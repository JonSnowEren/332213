include("shared.lua")

function ENT:Initialize()
    self.currentBid = 0
    self.active = false
    self.currentBets = {}
    
    self.hasInitialized = true
    
    -- Cache models
    self.cachedModels = {
        chip = "models/freeman/owain_casino_chip.mdl",
        plaque = "models/freeman/owain_casino_plaque.mdl"
    }
    
    -- Cache temp stack
    self.tempStack = {}
    self.lastPad = false
    
    -- Wheel order cache - Client tarafında da aynı sıralama
    self.wheelOrder = {}
    local correctOrder = {0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23, 10, 5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26}
    
    for i, num in ipairs(correctOrder) do
        self.wheelOrder[num] = i - 1
    end
end

function ENT:PostData()
    if not self.hasInitialized then
        self:Initialize()
    end
    
    self.currentBid = self.data.bet.default
    self:GetCurrentPad(Vector(0, 0, 0)) -- To force generate the cache
end

function ENT:OnRemove()
    self:ClearBets()
    self:ClearTempStack()
end

-- Optimized drawing functions
local surface_setdrawcolor = surface.SetDrawColor
local surface_drawrect = surface.DrawRect
local draw_simpletext = draw.SimpleText
local black = Color(0, 0, 0, 155)
local white = Color(255, 255, 255, 100)
local gold = Color(255, 200, 0, 100)
local distCheckSqr = 25000

function ENT:Draw()
    self:DrawModel()
    
    -- Early distance check
    if self:GetPos():DistToSqr(LocalPlayer():GetPos()) > distCheckSqr then return end
    
    -- Data check with optimized cooldown
    if not self.data then
        if not PerfectCasino.Cooldown.Check(self:EntIndex(), 5) then
            PerfectCasino.Core.RequestConfigData(self)
        end
        return
    end
    
    local pos = self:GetPos()
    local ang = self:GetAngles()
    ang:RotateAroundAxis(ang:Up(), -90)
    
    -- Get button state once
    local button = self:GetCurrentPad(self:WorldToLocal(LocalPlayer():GetEyeTrace().HitPos))
    
    cam.Start3D2D(pos + (ang:Up()*14.7) + (ang:Right()*20) + (ang:Forward()*-15.5), ang, 0.05)
        -- Bet limit
        if self.data.bet.betLimit and not (tonumber(self.data.bet.betLimit) == 0) then
            surface_setdrawcolor(black)
            surface_drawrect(5, -80, 410, 65)
            surface_setdrawcolor(white)
            surface_drawrect(0, -85, 420, 5)
            surface_drawrect(0, -80, 5, 65)
            surface_drawrect(415, -80, 5, 65)
            surface_drawrect(0, -15, 420, 5)
            draw_simpletext(string.format(PerfectCasino.Translation.UI.BetLimit, PerfectCasino.Config.FormatMoney(self.data.bet.betLimit)), "pCasino.Entity.Bid", 215, -47, white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        -- Previous bet step
        surface_setdrawcolor(black)
        surface_drawrect(5, 5, 90, 65)
        surface_setdrawcolor(button == "bet_lower" and gold or white)
        surface_drawrect(0, 0, 100, 5)
        surface_drawrect(0, 5, 5, 65)
        surface_drawrect(95, 5, 5, 65)
        surface_drawrect(0, 70, 100, 5)
        draw_simpletext("<", "pCasino.Entity.Arrows", 50, 35, button == "bet_lower" and gold or white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        -- Current bet
        surface_setdrawcolor(black)
        surface_drawrect(115, 5, 190, 65)
        surface_setdrawcolor(white)
        surface_drawrect(110, 0, 200, 5)
        surface_drawrect(110, 5, 5, 65)
        surface_drawrect(305, 5, 5, 65)
        surface_drawrect(110, 70, 200, 5)
        draw_simpletext(PerfectCasino.Config.FormatMoney(self.currentBid), "pCasino.Entity.Bid", 215, 37, white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        -- Next bet step
        surface_setdrawcolor(black)
        surface_drawrect(325, 5, 90, 65)
        surface_setdrawcolor(button == "bet_raise" and gold or white)
        surface_drawrect(320, 0, 100, 5)
        surface_drawrect(320, 5, 5, 65)
        surface_drawrect(415, 5, 5, 65)
        surface_drawrect(320, 70, 100, 5)
        draw_simpletext(">", "pCasino.Entity.Arrows", 370, 35, button == "bet_raise" and gold or white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
    
    -- Timer/Number display
    if (not (self:GetStartRoundIn() == -1)) or (self:GetLastRoundNumber() >= 0) then
        ang:RotateAroundAxis(ang:Forward(), 90)
        ang:RotateAroundAxis(ang:Right(), 90)
        
        cam.Start3D2D(pos + (ang:Up()*-20.3) + (ang:Right()*-21.3) + (ang:Forward()*-15), ang, 0.05)
            surface_setdrawcolor(black)
            surface_drawrect(5, 5, 190, 65)
            surface_setdrawcolor(white)
            surface_drawrect(0, 0, 200, 5)
            surface_drawrect(0, 5, 5, 65)
            surface_drawrect(195, 5, 5, 65)
            surface_drawrect(0, 70, 200, 5)
            
            local text = (not (self:GetStartRoundIn() == -1)) and 
                string.format(PerfectCasino.Translation.UI.Start, self.data.general.betPeriod - (os.time() - self:GetStartRoundIn())) or 
                string.format(PerfectCasino.Translation.UI.Number, self:GetLastRoundNumber())
            
            draw_simpletext(text, "pCasino.Entity.Bid", 100, 37, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end
end

function ENT:ClearTempStack()
    for k, v in pairs(self.tempStack) do
        if IsValid(v) then
            v:Remove()
        end
    end
    self.tempStack = {}
end

function ENT:Think()
    if self.active then return end
    if self:GetPos():DistToSqr(LocalPlayer():GetPos()) > distCheckSqr then return end
    
    local pos = self:WorldToLocal(LocalPlayer():GetEyeTrace().HitPos)
    local curPad, padData = self:GetCurrentPad(pos)
    
    if (not curPad) or (curPad == "bet_raise") or (curPad == "bet_lower") then
        self.lastPad = curPad
        if not table.IsEmpty(self.tempStack) then
            self:ClearTempStack()
        end
        return
    end
    
    if not (curPad == self.lastPad) then
        self:ClearTempStack()
    end
    self.lastPad = curPad
    
    if table.IsEmpty(self.tempStack) then
        local chips = PerfectCasino.Chips:GetFromNumber(self.currentBid)
        local ang = self:GetAngles()
        ang:RotateAroundAxis(ang:Up(), 90)
        
        for k=#PerfectCasino.Chips.Types, 0, -1 do
            if not chips[k] then continue end
            
            for i=1, chips[k] do
                local plaque = k >= 11
                local model = plaque and self.cachedModels.plaque or self.cachedModels.chip
                
                local chip = ClientsideModel(model)
                table.insert(self.tempStack, chip)
                chip:SetParent(self)
                chip:SetSkin(plaque and k-11 or k)
                
                local existingChips = self.currentBets[curPad] and #self.currentBets[curPad] or 0
                chip:SetPos(self:LocalToWorld(Vector(padData.origin.x, padData.origin.y, 14.8 + ((#self.tempStack + existingChips) * 0.3))))
                chip:SetAngles(ang)
            end
        end
    else
        -- Rotate temp stack
        local ang = self:GetAngles()
        ang:RotateAroundAxis(ang:Up(), CurTime()*30%360)
        for k, v in pairs(self.tempStack) do
            if IsValid(v) then
                v:SetAngles(ang)
            end
        end
    end
end

-- Optimized chip creation
function ENT:AddBet(pad, amount)
    local padName, padData = self:GetPadByName(pad)
    if not padName then return end
    
    self.currentBets[padName] = self.currentBets[padName] or {}
    
    local chips = PerfectCasino.Chips:GetFromNumber(amount)
    local ang = self:GetAngles()
    ang:RotateAroundAxis(ang:Up(), 90)
    
    for k=#PerfectCasino.Chips.Types, 0, -1 do
        if not chips[k] then continue end
        
        for i=1, chips[k] do
            local plaque = k >= 11
            local model = plaque and self.cachedModels.plaque or self.cachedModels.chip
            
            local chip = ClientsideModel(model)
            table.insert(self.currentBets[padName], chip)
            chip:SetParent(self)
            chip:SetSkin(plaque and k-11 or k)
            
            local stackHeight = #self.currentBets[padName]
            chip:SetPos(self:LocalToWorld(Vector(padData.origin.x, padData.origin.y, 14.5 + (stackHeight * 0.3))))
            chip:SetAngles(ang)
        end
    end
    
    self:ClearTempStack() -- Update height
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

-- Optimized network receivers
net.Receive("pCasino:Roulette:Bet:Change", function()
    local entity = net.ReadEntity()
    if not IsValid(entity) or not entity.data then return end
    
    entity.currentBid = net.ReadUInt(32)
end)

net.Receive("pCasino:Roulette:Bet:Place", function()
    local entity = net.ReadEntity()
    if not IsValid(entity) or not entity.data then return end
    
    -- Distance check
    if entity:GetPos():DistToSqr(LocalPlayer():GetPos()) > 100000 then return end
    
    local pad = net.ReadString()
    local betAmount = net.ReadUInt(32)
    
    entity:AddBet(pad, betAmount)
end)

net.Receive("pCasino:Roulette:Bet:Clear", function()
    local entity = net.ReadEntity()
    if not IsValid(entity) then return end
    
    local winningNumber = net.ReadUInt(6) -- Kazanan sayıyı da al
    
    -- Animasyon bitene kadar bekle
    timer.Simple(0.5, function()
        if not IsValid(entity) then return end
        entity:ClearBets()
    end)
end)