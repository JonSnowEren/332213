AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- Network throttle sistemi
local networkThrottle = {}
local function canSendNetwork(ply, msgType, delay)
    local key = (ply and ply:SteamID64() or "broadcast") .. "_" .. msgType
    if (networkThrottle[key] or 0) > CurTime() then return false end
    networkThrottle[key] = CurTime() + (delay or 0.1)
    return true
end

local preset = {
    {p = 0.95, a = 35},
    {p = 0, a = 16},
    {p = 0, a = -16},
    {p = 0.95, a = -35},
}

function ENT:Initialize()
    self:SetModel("models/freeman/owain_blackjack_table.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self:SetPos(self:GetPos() + (self:GetUp() * 20))
    
    self:DropToFloor()
    
    self.panels = {}
    for i=1, 4 do
        local panel = ents.Create("pcasino_blackjack_panel")
        self.panels[i] = panel
        panel.order = i
        panel:SetParent(self)
        
        panel:SetPos(self:GetPos() + (self:GetUp() * 30) + ((self:GetForward() * 16) + ((self:GetForward() * -10) * preset[i].p)) + ((self:GetRight() * -20) * (i - 2.5)))
        
        local ang = self:GetAngles()
        ang:RotateAroundAxis(ang:Right(), -90)
        ang:RotateAroundAxis(ang:Up(), 90)    
        ang:RotateAroundAxis(ang:Right(), preset[i].a)
        
        panel:SetAngles(ang)
        panel:Spawn()
        panel.table = self
    end
    
    self:SetStartRoundIn(-1)
    
    self.currentBetAmounts = {}
    self.activeBets = {}
    self.data = {}
    self.isActive = false
    self.timerStarted = false
    
    -- Cache için
    self.networkCache = {}
    self.lastNetworkUpdate = 0
end

function ENT:PostData()
end

function ENT:Use(ply)
end

function ENT:StartRound()
    self.isActive = true
    self:SetStartRoundIn(-1)
    self.curHands = {}
    
    -- Build the players hands 
    for k, v in pairs(self.panels) do
        if v:GetStage() == 1 then
            v:SetStage(0)
        else
            local ply = v:GetUser()
            if not IsValid(ply) then
                v:SetStage(0)
                continue
            end
            
            self.curHands[k] = {}
            self.curHands[k][1] = {
                finished = false,
                cards = {PerfectCasino.Cards:GetRandom(), PerfectCasino.Cards:GetRandom()},
                ply = ply,
                bet = self.activeBets[ply:SteamID64()]
            }
        end
    end
    
    -- Build the dealer's hand
    self.dealerHand = {PerfectCasino.Cards:GetRandom()}
    
    -- Network optimization - sadece yakındaki oyunculara gönder
    local nearbyPlayers = {}
    for _, ply in ipairs(player.GetAll()) do
        if ply:GetPos():DistToSqr(self:GetPos()) < 562500 then -- 750 birim
            table.insert(nearbyPlayers, ply)
        end
    end
    
    if #nearbyPlayers > 0 and canSendNetwork(nil, "StartingCards", 0.5) then
        net.Start("pCasino:Blackjack:StartingCards")
            net.WriteEntity(self)
            net.WriteTable(self.curHands)
            net.WriteTable(self.dealerHand)
        net.Send(nearbyPlayers)
        
        PerfectCasino.Sound.Play(self, "card"..math.random(1, 4))
    end
    
    self:EndTurn()
end

function ENT:EndRound()
    -- Get the dealer to a value of 17 or more
    while PerfectCasino.Cards:GetHandValue(self.dealerHand) < 17 do
        table.insert(self.dealerHand, PerfectCasino.Cards:GetRandom())
    end
    
    -- Network optimization
    local nearbyPlayers = {}
    for _, ply in ipairs(player.GetAll()) do
        if ply:GetPos():DistToSqr(self:GetPos()) < 562500 then
            table.insert(nearbyPlayers, ply)
        end
    end
    
    if #nearbyPlayers > 0 and canSendNetwork(nil, "DealerCards", 0.5) then
        net.Start("pCasino:Blackjack:DealerCards")
            net.WriteEntity(self)
            net.WriteTable(self.dealerHand)
        net.Send(nearbyPlayers)
    end
    
    -- The sounds for placing of cards
    for i=1, (#self.dealerHand - 1) do
        timer.Simple(i - 1, function()
            if not IsValid(self) then return end
            PerfectCasino.Sound.Play(self, "card"..math.random(1, 4))
        end)
    end
    
    -- A small buffer so you have time to process what happened
    timer.Simple(3 + (#self.dealerHand - 2), function()
        if not IsValid(self) then return end
        
        self:PayoutBets()
        
        -- Reset everything
        self.isActive = false
        self.activeBets = {}
        self.timerStarted = false
        for k, v in pairs(self.panels) do
            v:SetStage(1)
            v:SetUser(NULL)
        end
        
        -- Clear for nearby players only
        if #nearbyPlayers > 0 and canSendNetwork(nil, "Clear", 0.5) then
            net.Start("pCasino:Blackjack:Clear")
                net.WriteEntity(self)
            net.Send(nearbyPlayers)
        end
    end)
end

function ENT:FindNextTurn()
    for i=4, 1, -1 do
        if not self.curHands[i] then continue end
        for k, v in ipairs(self.curHands[i]) do
            if v.finished then continue end
            return i, k
        end
    end
    
    return false
end

function ENT:PromptTurn(pad, hand)
    local padEnt = self.panels[pad]
    padEnt:SetStage(3)
    padEnt:SetHand(hand)
    
    timer.Create("pCasino:Blackjack:Timeout:"..self:EntIndex(), tonumber(self.data.turn.timeout), 1, function()
        if not IsValid(self) then return end
        self:EndTurn(pad, hand)
    end)
end

function ENT:EndTurn(pad, hand)
    if pad and hand then
        self.curHands[pad][hand].finished = true
        self.panels[pad]:SetStage(2)
    end
    
    timer.Remove("pCasino:Blackjack:Timeout:"..self:EntIndex())
    local curTurnPad, curTurnHand = self:FindNextTurn()
    if not curTurnPad then
        self:EndRound()
        return
    end
    
    self:PromptTurn(curTurnPad, curTurnHand)
end

function ENT:TurnAction(pad, action)
    local curTurnPad, curTurnHand = self:FindNextTurn()
    local handData = self.curHands[curTurnPad][curTurnHand]
    
    if not (pad.order == curTurnPad) then return end
    
    -- Network throttle check
    if not canSendNetwork(handData.ply, "TurnAction", 0.2) then return end
    
    if action == "doubledown" then
        if #handData.cards > 2 then return end
        
        local canRun, failMsg = hook.Run("pCasinoCanBlackjackBet", handData.ply, self, action)
        if canRun == false then
            if failMsg then
                PerfectCasino.Core.Msg(failMsg, handData.ply)
            end
            return
        end
        
        if not PerfectCasino.Config.CanAfford(handData.ply, handData.bet) then
            PerfectCasino.Core.Msg(PerfectCasino.Translation.Chat.NoMoney, handData.ply)
            return
        end
        
        PerfectCasino.Config.AddMoney(handData.ply, -handData.bet)
        hook.Run("pCasinoOnBlackjackBet", handData.ply, self, handData.bet)
        
        -- Optimized network send
        local nearbyPlayers = {}
        for _, ply in ipairs(player.GetAll()) do
            if ply:GetPos():DistToSqr(self:GetPos()) < 562500 then
                table.insert(nearbyPlayers, ply)
            end
        end
        
        if #nearbyPlayers > 0 then
            net.Start("pCasino:Blackjack:Bet:Place")
                net.WriteEntity(self)
                net.WriteUInt(curTurnPad, 3)
                net.WriteUInt(handData.bet, 32)
            net.Send(nearbyPlayers)
        end
        
        handData.bet = handData.bet*2
        
        local newCard = PerfectCasino.Cards:GetRandom()
        table.insert(handData.cards, newCard)
        
        if #nearbyPlayers > 0 then
            net.Start("pCasino:Blackjack:NewCard")
                net.WriteEntity(self)
                net.WriteUInt(curTurnPad, 3)
                net.WriteUInt(curTurnHand, 3)
                net.WriteString(newCard)
            net.Send(nearbyPlayers)
        end
        
        PerfectCasino.Sound.Play(self, "card"..math.random(1, 4))
        
        self:EndTurn(curTurnPad, curTurnHand)
        
    elseif action == "split" then
        if #handData.cards > 2 then return end
        if not handData.cards[2] then return end
        if not (PerfectCasino.Cards:GetValue(handData.cards[1]) == PerfectCasino.Cards:GetValue(handData.cards[2])) then return end
        
        local canRun, failMsg = hook.Run("pCasinoCanBlackjackBet", handData.ply, self, action)
        if canRun == false then
            if failMsg then
                PerfectCasino.Core.Msg(failMsg, handData.ply)
            end
            return
        end
        
        if not PerfectCasino.Config.CanAfford(handData.ply, handData.bet) then
            PerfectCasino.Core.Msg(PerfectCasino.Translation.Chat.NoMoney, handData.ply)
            return
        end
        
        PerfectCasino.Config.AddMoney(handData.ply, -handData.bet)
        hook.Run("pCasinoOnBlackjackBet", handData.ply, self, handData.bet)
        
        local nearbyPlayers = {}
        for _, ply in ipairs(player.GetAll()) do
            if ply:GetPos():DistToSqr(self:GetPos()) < 562500 then
                table.insert(nearbyPlayers, ply)
            end
        end
        
        if #nearbyPlayers > 0 then
            net.Start("pCasino:Blackjack:Bet:Place")
                net.WriteEntity(self)
                net.WriteUInt(curTurnPad, 3)
                net.WriteUInt(handData.bet, 32)
            net.Send(nearbyPlayers)
        end
        
        table.insert(self.curHands[curTurnPad], {
            finished = false,
            cards = {handData.cards[2]},
            ply = handData.ply,
            bet = handData.bet
        })
        
        handData.cards[2] = nil
        
        if #nearbyPlayers > 0 then
            net.Start("pCasino:Blackjack:Split")
                net.WriteEntity(self)
                net.WriteUInt(curTurnPad, 3)
                net.WriteTable(self.curHands[curTurnPad])
            net.Send(nearbyPlayers)
        end
        
        PerfectCasino.Sound.Play(self, "card"..math.random(1, 4))
        
    elseif action == "hit" then
        local canRun, failMsg = hook.Run("pCasinoCanBlackjackBet", handData.ply, self, action)
        if canRun == false then
            if failMsg then
                PerfectCasino.Core.Msg(failMsg, handData.ply)
            end
            return
        end
        
        local newCard = PerfectCasino.Cards:GetRandom()
        table.insert(handData.cards, newCard)
        
        local nearbyPlayers = {}
        for _, ply in ipairs(player.GetAll()) do
            if ply:GetPos():DistToSqr(self:GetPos()) < 562500 then
                table.insert(nearbyPlayers, ply)
            end
        end
        
        if #nearbyPlayers > 0 then
            net.Start("pCasino:Blackjack:NewCard")
                net.WriteEntity(self)
                net.WriteUInt(curTurnPad, 3)
                net.WriteUInt(curTurnHand, 3)
                net.WriteString(newCard)
            net.Send(nearbyPlayers)
        end
        
        PerfectCasino.Sound.Play(self, "card"..math.random(1, 4))
        
        if PerfectCasino.Cards:GetHandValue(handData.cards) >= 21 then
            self:EndTurn(curTurnPad, curTurnHand)
        end
        
    elseif action == "stand" then
        self:EndTurn(curTurnPad, curTurnHand)
    end
end

-- Bet functions
function ENT:PlaceBet(ply, pad)
    local betAmount = self.currentBetAmounts[ply:SteamID64()] or self.data.bet.default
    
    if not PerfectCasino.Config.CanAfford(ply, betAmount) then
        PerfectCasino.Core.Msg(PerfectCasino.Translation.Chat.NoMoney, ply)
        return false
    end
    
    local canRun, failMsg = hook.Run("pCasinoCanBlackjackBet", ply, self, "bet")
    if canRun == false then
        if failMsg then
            PerfectCasino.Core.Msg(failMsg, ply)
        end
        return
    end
    
    PerfectCasino.Config.AddMoney(ply, -betAmount)
    hook.Run("pCasinoOnBlackjackBet", ply, self, betAmount)
    
    self.activeBets[ply:SteamID64()] = betAmount 
    
    PerfectCasino.Sound.Play(self, "chip"..math.random(1, 2))
    
    pad:SetStage(2)
    pad:SetUser(ply)
    
    -- Network throttle
    if canSendNetwork(nil, "Bet:Place", 0.2) then
        local nearbyPlayers = {}
        for _, p in ipairs(player.GetAll()) do
            if p:GetPos():DistToSqr(self:GetPos()) < 562500 then
                table.insert(nearbyPlayers, p)
            end
        end
        
        if #nearbyPlayers > 0 then
            net.Start("pCasino:Blackjack:Bet:Place")
                net.WriteEntity(self)
                net.WriteUInt(pad.order, 3)
                net.WriteUInt(betAmount, 32)
            net.Send(nearbyPlayers)
        end
    end
    
    PerfectCasino.Core.Msg(PerfectCasino.Translation.Chat.BetPlaced, ply)
    
    -- Start the timer 
    if not self.timerStarted then
        timer.Create("pCasino:BlackJack:Countdown:"..self:EntIndex(), self.data.general.betPeriod, 1, function()
            if not IsValid(self) then return end
            self:StartRound()
        end)
        self.timerStarted = true
        self:SetStartRoundIn(os.time())
    else
        -- See how many pads are ready
        local padsReady = 0
        for k, v in pairs(self.panels) do
            if v:GetStage() == 2 then
                padsReady = padsReady + 1 
            end
        end
        
        -- All pads are full, start the game early
        if padsReady == 4 then
            timer.Remove("pCasino:BlackJack:Countdown:"..self:EntIndex())
            self:StartRound()
        end
    end
end

function ENT:ChangeBet(ply, newBet)
    -- Throttle check
    if not canSendNetwork(ply, "ChangeBet", 0.1) then return end
    
    self.currentBetAmounts[ply:SteamID64()] = self.currentBetAmounts[ply:SteamID64()] or self.data.bet.default
    
    self.currentBetAmounts[ply:SteamID64()] = math.Clamp(self.currentBetAmounts[ply:SteamID64()] + newBet, self.data.bet.min, self.data.bet.max)
    
    -- The bet has not changed, no need to network it
    if self.currentBetAmounts[ply:SteamID64()] == (self.currentBetAmounts[ply:SteamID64()] + newBet) then return end
    
    -- Network the new bet
    net.Start("pCasino:Roulette:Bet:Change")
        net.WriteEntity(self)
        net.WriteUInt(self.currentBetAmounts[ply:SteamID64()], 32)
    net.Send(ply)
end

function ENT:PayoutBets()
    local dealerValue = PerfectCasino.Cards:GetHandValue(self.dealerHand)
    
    for k, v in pairs(self.curHands) do
        for n, m in ipairs(v) do
            if not IsValid(m.ply) then continue end
            
            local handValue = PerfectCasino.Cards:GetHandValue(m.cards)
            
            if handValue > 21 then
                PerfectCasino.Core.Msg(PerfectCasino.Translation.Chat.HandBust, m.ply)
                hook.Run("pCasinoOnBlackjackLoss", m.ply, self, m.bet)
            elseif dealerValue > 21 then
                PerfectCasino.Core.Msg(string.format(PerfectCasino.Translation.Chat.DealerHandBust, PerfectCasino.Config.FormatMoney(m.bet*self.data.payout.win)), m.ply)
                PerfectCasino.Config.AddMoney(m.ply, m.bet*self.data.payout.win)
                hook.Run("pCasinoOnBlackjackPayout", m.ply, self, m.bet*self.data.payout.win)
            elseif handValue == dealerValue then
                PerfectCasino.Core.Msg(PerfectCasino.Translation.Chat.HandDraw, m.ply)
                PerfectCasino.Config.AddMoney(m.ply, m.bet)
                hook.Run("pCasinoOnBlackjackPayout", m.ply, self, m.bet)
            elseif handValue < dealerValue then
                PerfectCasino.Core.Msg(PerfectCasino.Translation.Chat.HandLose, m.ply)
                hook.Run("pCasinoOnBlackjackLoss", m.ply, self, m.bet)
            elseif handValue > dealerValue then
                local payout = (handValue == 21) and self.data.payout.blackjack or self.data.payout.win
                payout = m.bet * payout
                PerfectCasino.Core.Msg(string.format(PerfectCasino.Translation.Chat.HandWin, PerfectCasino.Config.FormatMoney(payout)), m.ply)
                PerfectCasino.Config.AddMoney(m.ply, payout)
                hook.Run("pCasinoOnBlackjackPayout", m.ply, self, payout)
            end
        end
    end
end