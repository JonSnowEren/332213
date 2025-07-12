include("shared.lua")

function ENT:Initialize()
    self.table = self:GetParent()
    self.hasInitialized = true
    
    -- Cache colors
    self.black = Color(0, 0, 0, 155)
    self.white = Color(255, 255, 255, 100)
    self.gold = Color(255, 200, 0, 100)
    
    -- Cache edge position
    self.edge = -235
end

-- Cache functions
local surface_setdrawcolor = surface.SetDrawColor
local surface_drawrect = surface.DrawRect
local draw_simpletext = draw.SimpleText

function ENT:Draw()
    -- Empty: We only use DrawTranslucent
end

function ENT:DrawTranslucent()
    -- Early distance check
    if self:GetPos():DistToSqr(LocalPlayer():GetPos()) > 25000 then return end
    if not self.table.data then return end
    
    if not self.hasInitialized then
        self:Initialize()
    end
    
    local pos = self:GetPos()
    local ang = self:GetAngles()
    
    -- Get button state once
    local button = self:GetCurrentPad(self:WorldToLocal(LocalPlayer():GetEyeTrace().HitPos))
    local stage = self:GetStage()
    
    cam.Start3D2D(pos + (ang:Up()*5.95), ang, 0.05)
        if stage == 1 then -- Changing bet buttons
            self:DrawBettingUI(button)
        elseif stage == 2 and self:GetUser() == LocalPlayer() then -- Waiting for your turn
            self:DrawWaitingUI()
        elseif stage == 3 and self:GetUser() == LocalPlayer() then -- Active turn
            self:DrawGameUI(button)
        end
    cam.End3D2D()
end

function ENT:DrawBettingUI(button)
    local edge = self.edge
    
    -- Previous bet step
    surface_setdrawcolor(self.black)
    surface_drawrect(edge + 5, -edge - 150, 90, 65)
    surface_setdrawcolor(button == "bet_lower" and self.gold or self.white)
    surface_drawrect(edge + 0, -edge - 155, 100, 5)
    surface_drawrect(edge + 0, -edge - 150, 5, 65)
    surface_drawrect(edge + 95, -edge - 150, 5, 65)
    surface_drawrect(edge + 0, -edge - 85, 100, 5)
    draw_simpletext("<", "pCasino.Entity.Arrows", edge + 50, -edge - 120, button == "bet_lower" and self.gold or self.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Current bet
    surface_setdrawcolor(self.black)
    surface_drawrect(edge + 115, -edge - 150, 240, 65)
    surface_setdrawcolor(self.white)
    surface_drawrect(edge + 110, -edge - 155, 250, 5)
    surface_drawrect(edge + 110, -edge - 150, 5, 65)
    surface_drawrect(edge + 355, -edge - 150, 5, 65)
    surface_drawrect(edge + 110, -edge - 85, 250, 5)
    draw_simpletext(PerfectCasino.Config.FormatMoney(self.table.currentBid), "pCasino.Entity.Bid", edge + 235, -edge - 118, self.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Next bet step
    surface_setdrawcolor(self.black)
    surface_drawrect(edge + 375, -edge - 150, 90, 65)
    surface_setdrawcolor(button == "bet_raise" and self.gold or self.white)
    surface_drawrect(edge + 370, -edge - 155, 100, 5)
    surface_drawrect(edge + 370, -edge - 150, 5, 65)
    surface_drawrect(edge + 465, -edge - 150, 5, 65)
    surface_drawrect(edge + 370, -edge - 85, 100, 5)
    draw_simpletext(">", "pCasino.Entity.Arrows", edge + 420, -edge - 120, button == "bet_raise" and self.gold or self.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Place bet
    surface_setdrawcolor(self.black)
    surface_drawrect(edge, -edge - 70, 465, 65)
    surface_setdrawcolor(button == "bet_place" and self.gold or self.white)
    surface_drawrect(edge, -edge - 75, 470, 5)
    surface_drawrect(edge, -edge - 70, 5, 65)
    surface_drawrect(edge + 465, -edge - 70, 5, 65)
    surface_drawrect(edge, -edge - 5, 470, 5)
    draw_simpletext(PerfectCasino.Translation.UI.PlaceBet, "pCasino.Entity.Bid", edge + 235, -edge - 38, button == "bet_place" and self.gold or self.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function ENT:DrawWaitingUI()
    local edge = self.edge
    
    surface_setdrawcolor(self.black)
    surface_drawrect(edge, -edge - 70, 465, 65)
    surface_setdrawcolor(self.white)
    surface_drawrect(edge, -edge - 75, 470, 5)
    surface_drawrect(edge, -edge - 70, 5, 65)
    surface_drawrect(edge + 465, -edge - 70, 5, 65)
    surface_drawrect(edge, -edge - 5, 470, 5)
    draw_simpletext(PerfectCasino.Translation.UI.Waiting, "pCasino.Entity.Bid", edge + 235, -edge - 38, self.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function ENT:DrawGameUI(button)
    if not self.table.curHands[self.order] then return end
    
    local activeHandData = self.table.curHands[self.order][self:GetHand()]
    if not activeHandData then return end
    
    local edge = self.edge
    
    -- Hit button
    surface_setdrawcolor(self.black)
    surface_drawrect(edge + 5, -edge - 70, 220, 65)
    surface_setdrawcolor(button == "action_hit" and self.gold or self.white)
    surface_drawrect(edge, -edge - 75, 230, 5)
    surface_drawrect(edge, -edge - 70, 5, 65)
    surface_drawrect(edge + 225, -edge - 70, 5, 65)
    surface_drawrect(edge, -edge - 5, 230, 5)
    draw_simpletext(PerfectCasino.Translation.UI.Hit, "pCasino.Entity.Bid", edge + 115, -edge - 38, button == "action_hit" and self.gold or self.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Stand button
    surface_setdrawcolor(self.black)
    surface_drawrect(edge + 245, -edge - 70, 220, 65)
    surface_setdrawcolor(button == "action_stand" and self.gold or self.white)
    surface_drawrect(edge + 240, -edge - 75, 230, 5)
    surface_drawrect(edge + 240, -edge - 70, 5, 65)
    surface_drawrect(edge + 465, -edge - 70, 5, 65)
    surface_drawrect(edge + 240, -edge - 5, 230, 5)
    draw_simpletext(PerfectCasino.Translation.UI.Stand, "pCasino.Entity.Bid", edge + 355, -edge - 38, button == "action_stand" and self.gold or self.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Can't double a hand if it's not the first action
    if #activeHandData <= 2 then
        -- Double down button
        surface_setdrawcolor(self.black)
        surface_drawrect(edge + 5, -edge - 150, 220, 65)
        surface_setdrawcolor(button == "action_double" and self.gold or self.white)
        surface_drawrect(edge, -edge - 155, 230, 5)
        surface_drawrect(edge, -edge - 150, 5, 65)
        surface_drawrect(edge + 225, -edge - 150, 5, 65)
        surface_drawrect(edge, -edge - 85, 230, 5)
        draw_simpletext(PerfectCasino.Translation.UI.DoubleDown, "pCasino.Entity.Bid", edge + 115, -edge - 118, button == "action_double" and self.gold or self.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end    
    
    if (#activeHandData <= 2) and activeHandData[2] and (PerfectCasino.Cards:GetValue(activeHandData[1]) == PerfectCasino.Cards:GetValue(activeHandData[2])) then
        -- Split button
        surface_setdrawcolor(self.black)
        surface_drawrect(edge + 245, -edge - 150, 220, 65)
        surface_setdrawcolor(button == "action_split" and self.gold or self.white)
        surface_drawrect(edge + 240, -edge - 155, 230, 5)
        surface_drawrect(edge + 240, -edge - 150, 5, 65)
        surface_drawrect(edge + 465, -edge - 150, 5, 65)
        surface_drawrect(edge + 240, -edge - 85, 230, 5)
        draw_simpletext(PerfectCasino.Translation.UI.Split, "pCasino.Entity.Bid", edge + 355, -edge - 118, button == "action_split" and self.gold or self.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Current Hand Stats
    surface_setdrawcolor(self.black)
    surface_drawrect(edge + 5, -edge + 10, 460, 65)
    surface_setdrawcolor(self.white)
    surface_drawrect(edge, -edge + 5, 470, 5)
    surface_drawrect(edge, -edge + 10, 5, 65)
    surface_drawrect(edge + 465, -edge + 10, 5, 65)
    surface_drawrect(edge, -edge + 75, 470, 5)
    
    -- Current Hand text
    draw_simpletext(string.format(PerfectCasino.Translation.UI.CurrentHand, PerfectCasino.UI.NumberSuffix(self:GetHand())), "pCasino.Entity.Bid", edge + 235, -edge + 7, self.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    
    -- Hand value
    local total = PerfectCasino.Cards:GetHandValue(activeHandData)
    local valueState = ((total > 21) and string.format(PerfectCasino.Translation.UI.Bust, total)) or ((total == 21) and string.format(PerfectCasino.Translation.UI.Blackjack, total)) or total
    draw_simpletext(string.format(PerfectCasino.Translation.UI.CurrentHandTotalValue, valueState), "pCasino.Entity.Bid", edge + 235, -edge + 77, self.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
end