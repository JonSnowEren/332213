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

function ENT:Initialize()
    self:SetModel("models/freeman/owain_roulette_table.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    
    self:SetAutomaticFrameAdvance(true)
    self:SetPlaybackRate(1)
    
    self.cacheSeq = {}
    self.cacheSeq['idle'] = self:LookupSequence("idle")
    self.cacheSeq['wheel_spin'] = self:LookupSequence("wheel_spin")
    self:SetSequence(self.cacheSeq['idle'])
    
    self:SetLastRoundNumber(-1)
    self:SetStartRoundIn(-1)
    self:SetWinningNumber(-1) -- Yeni eklenen
    
    self.currentBetAmounts = {}
    self.activeBets = {}
    self.data = {}
    self.isActive = false
    self.timerStarted = false
    
    -- Cache for wheel order - Doğru Avrupa ruleti sıralaması
    self.wheelOrder = {}
    local correctOrder = {0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23, 10, 5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26}
    
    -- wheelOrder'ı tersine çevrilmiş index olarak oluştur
    for i, num in ipairs(correctOrder) do
        self.wheelOrder[num] = i - 1  -- 0-indexed for pose parameter
    end
end

function ENT:PostData()
    if not self.isActive then return end
    self:GetCurrentPad(Vector(0, 0, 0)) -- To force generate the cache
end

function ENT:Think()
    if not self.isActive then return end
    self:NextThink(CurTime())
    return true
end

function ENT:Use(ply)
    if self.isActive then return end
    if not ply:IsPlayer() then return end
    
    -- Use cooldown
    if PerfectCasino.Cooldown.Check(self:EntIndex()..":Use", 0.5, ply) then return end
    
    local pos = self:WorldToLocal(ply:GetEyeTrace().HitPos)
    local button = self:GetCurrentPad(pos)
    if not button then return end
    
    -- Custom checks
    local canRun, failMsg = hook.Run("pCasinoCanRouletteBet", ply, self)
    if canRun == false then
        if failMsg then
            PerfectCasino.Core.Msg(failMsg, ply)
        end
        return
    end
    
    if button == "bet_lower" then
        self:ChangeBet(ply, -self.data.bet.iteration)
        return
    elseif button == "bet_raise" then
        self:ChangeBet(ply, self.data.bet.iteration)
        return
    end
    
    self:PlaceBet(ply, button)
    
    if not self.timerStarted then
        timer.Create("pCasino:Roulette:Countdown:"..self:EntIndex(), self.data.general.betPeriod, 1, function()
            if not IsValid(self) then return end
            self:StartRound()
        end)
        self.timerStarted = true
        self:SetStartRoundIn(os.time())
    end
end

function ENT:StartRound()
    self.isActive = true
    self.winningNumber = math.random(0, 36)
    
    -- Network variable'ı henüz ayarlama
    
    -- Önce animasyonu başlat
    self:ResetSequence(self.cacheSeq['wheel_spin'])
    
    -- Sonra kısa bir gecikme ile pose parametresini ayarla
    timer.Simple(0.2, function()
        if not IsValid(self) then return end
        self:SetPoseParameter("roulette_wheel_changenumber", self.wheelOrder[self.winningNumber])
    end)
    
    self:SetLastRoundNumber(-1)
    self:SetStartRoundIn(-1)
    
    PerfectCasino.Sound.Play(self:GetPos() + (self:GetUp() * 15) + (self:GetForward() * 10) + (self:GetRight() * 40), "other_spin")
    
    timer.Simple(self:SequenceDuration(self.cacheSeq['wheel_spin']), function()
        if not IsValid(self) then return end
        self:EndRound()
    end)
end

function ENT:EndRound()
    self.isActive = false
    self.timerStarted = false
    
    self:PayoutBets()
    self.activeBets = {}
    
    -- Animasyon bittiğinde kazanan sayıyı set et
    self:SetWinningNumber(self.winningNumber)
    self:SetLastRoundNumber(self.winningNumber)
    self:SetSequence("idle")
    
    PerfectCasino.Sound.Stop(self, "other_spin")
    
    -- Network optimization - only send to nearby players
    if canSendNetwork(nil, "Bet:Clear", 0.5) then
        local nearbyPlayers = {}
        for _, ply in ipairs(player.GetAll()) do
            if ply:GetPos():DistToSqr(self:GetPos()) < 562500 then
                table.insert(nearbyPlayers, ply)
            end
        end
        
        if #nearbyPlayers > 0 then
            net.Start("pCasino:Roulette:Bet:Clear")
                net.WriteEntity(self)
                net.WriteUInt(self.winningNumber, 6) -- Kazanan sayıyı da gönder
            net.Send(nearbyPlayers)
        end
    end
end

function ENT:PlaceBet(ply, pad)
    local betAmount = self.currentBetAmounts[ply:SteamID64()] or self.data.bet.default
    
    if not PerfectCasino.Config.CanAfford(ply, betAmount) then
        PerfectCasino.Core.Msg(PerfectCasino.Translation.Chat.NoMoney, ply)
        return
    end
    
    -- Bet limit check
    if self.data.bet.betLimit and not (tonumber(self.data.bet.betLimit) == 0) then
        if self.activeBets[ply:SteamID64()] then
            local betTotal = 0
            for k, v in pairs(self.activeBets[ply:SteamID64()]) do
                betTotal = betTotal + v
            end
            
            if tonumber(betTotal) >= tonumber(self.data.bet.betLimit) then
                PerfectCasino.Core.Msg(PerfectCasino.Translation.Chat.BetLimit, ply)
                return
            elseif (betTotal + betAmount) > tonumber(self.data.bet.betLimit) then
                PerfectCasino.Core.Msg(string.format(PerfectCasino.Translation.Chat.WillReachBetLimit, PerfectCasino.Config.FormatMoney(self.data.bet.betLimit - betTotal)), ply)
                return
            end
        end
    end
    
    PerfectCasino.Config.AddMoney(ply, -betAmount)
    hook.Run("pCasinoOnRouletteBet", ply, self, betAmount)
    
    self.activeBets[ply:SteamID64()] = self.activeBets[ply:SteamID64()] or {}
    self.activeBets[ply:SteamID64()][pad] = (self.activeBets[ply:SteamID64()][pad] or 0) + betAmount 
    
    PerfectCasino.Sound.Play(self, "chip"..math.random(1, 2))
    
    -- Network optimization
    if canSendNetwork(nil, "Bet:Place", 0.2) then
        local nearbyPlayers = {}
        for _, p in ipairs(player.GetAll()) do
            if p:GetPos():DistToSqr(self:GetPos()) < 562500 then
                table.insert(nearbyPlayers, p)
            end
        end
        
        if #nearbyPlayers > 0 then
            net.Start("pCasino:Roulette:Bet:Place")
                net.WriteEntity(self)
                net.WriteString(pad)
                net.WriteUInt(betAmount, 32)
            net.Send(nearbyPlayers)
        end
    end
end

function ENT:ChangeBet(ply, newBet)
    -- Throttle check
    if not canSendNetwork(ply, "ChangeBet", 0.1) then return end
    
    self.currentBetAmounts[ply:SteamID64()] = self.currentBetAmounts[ply:SteamID64()] or self.data.bet.default
    self.currentBetAmounts[ply:SteamID64()] = math.Clamp(self.currentBetAmounts[ply:SteamID64()] + newBet, self.data.bet.min, self.data.bet.max)
    
    -- No change, no network
    if self.currentBetAmounts[ply:SteamID64()] == (self.currentBetAmounts[ply:SteamID64()] + newBet) then return end
    
    net.Start("pCasino:Roulette:Bet:Change")
        net.WriteEntity(self)
        net.WriteUInt(self.currentBetAmounts[ply:SteamID64()], 32)
    net.Send(ply)
end

function ENT:PayoutBets()
    if not self.winningNumber then return end
    
    local winningPads = self:GetPadsFromNumber(self.winningNumber)
    local padCache = {}
    
    for k, v in pairs(self.activeBets) do
        local ply = player.GetBySteamID64(k)
        if not ply then continue end
        
        local winnings = 0
        local totalBet = 0
        
        for n, m in pairs(v) do
            totalBet = totalBet + m
            if table.HasValue(winningPads, n) then
                local padData = padCache[n]
                if not padData then
                    _, padData = self:GetPadByName(n)
                    padCache[n] = padData
                end
                
                winnings = winnings + m + (m * padData.payout)
            end
        end
        
        if winnings == 0 then
            PerfectCasino.Core.Msg(PerfectCasino.Translation.Chat.RouletteFail, ply)
            hook.Run("pCasinoOnRouletteLoss", ply, self, totalBet)
        else
            PerfectCasino.Config.AddMoney(ply, winnings)
            hook.Run("pCasinoOnRoulettePayout", ply, self, winnings)
            PerfectCasino.Core.Msg(string.format(PerfectCasino.Translation.Chat.Payout, PerfectCasino.Config.FormatMoney(winnings)), ply)
        end
    end
end