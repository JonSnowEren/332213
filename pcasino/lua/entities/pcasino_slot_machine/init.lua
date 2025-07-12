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
    self:SetModel("models/freeman/owain_slotmachine.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    
    self:SetAutomaticFrameAdvance(true)
    self:SetPlaybackRate(1)
    
    self.cacheSeq = {}
    self.cacheSeq['idle'] = self:LookupSequence("idle")
    self.cacheSeq['leverpull'] = self:LookupSequence("leverpull")
    self:ResetSequence(self.cacheSeq['idle'])
    
    self.data = {}
    self.isActive = false
    self.pool = nil -- Will be generated on PostData
end

function ENT:PostData()
    self:GenerateResult() -- Generate the pool in advance
    self:SetCurrentJackpot(self.data.jackpot.startValue)
end

function ENT:GenerateResult()
    if not self.pool then
        self.pool = {}
        for k, v in pairs(self.data.chance) do
            for i=1, v do
                table.insert(self.pool, k)
            end
        end
    end
    
    return self.pool[math.random(#self.pool)]
end

function ENT:CheckForCombo(res1, res2, res3)
    local winData
    for k, v in pairs(self.data.combo) do
        if not (res1 == v.c[1]) and not (v.c[1] == "anything") then continue end
        if not (res2 == v.c[2]) and not (v.c[2] == "anything") then continue end
        if not (res3 == v.c[3]) and not (v.c[3] == "anything") then continue end
        
        if winData then
            if tobool(self.data.jackpot.toggle) and winData.j and not v.j then continue end
            if tonumber(winData.p) > tonumber(v.p) then continue end
        end
        
        winData = v
    end
    
    return winData or false
end

function ENT:Think()
    if not self.isActive then return end
    self:NextThink(CurTime())
    return true
end

function ENT:Use(ply)
    if self.isActive then return end
    if not ply:IsPlayer() then return end
    
    -- Cooldown check
    if PerfectCasino.Cooldown.Check(self:EntIndex()..":Use", 1, ply) then return end
    
    -- Multi-use check
    if self.data.general and self.data.general.limitUse then
        local allowed, reason = PerfectCasino.Core.ManageMultiUse(ply, self)
        if not allowed then
            PerfectCasino.Core.Msg(reason, ply)
            return
        end
    end
    
    -- Custom checks
    local canRun, failMsg = hook.Run("pCasinoCanBasicSlotMachineBet", ply, self)
    if canRun == false then
        if failMsg then
            PerfectCasino.Core.Msg(failMsg, ply)
        end
        return
    end
    
    self:StartRound(ply)
end

-- Game specific code
function ENT:StartRound(ply)
    PerfectCasino.Sound.Stop(self, "basic_slotmachine_stop3")
    
    if not PerfectCasino.Config.CanAfford(ply, self.data.bet.default) then
        PerfectCasino.Core.Msg(PerfectCasino.Translation.Chat.NoMoney, ply)
        return
    end
    
    -- Take money
    PerfectCasino.Config.AddMoney(ply, -self.data.bet.default)
    hook.Run("pCasinoOnBasicSlotMachineBet", ply, self, self.data.bet.default)
    
    -- Add to jackpot
    if tobool(self.data.jackpot.toggle) then
        self:SetCurrentJackpot(self:GetCurrentJackpot() + (self.data.bet.default * self.data.jackpot.betAdd))
    end
    
    self.isActive = true
    
    -- Generate results
    local results = {}
    for i = 1, 3 do
        results[i] = self:GenerateResult()
    end
    results.suspense = results[1] == results[2]
    
    local win = self:CheckForCombo(results[1], results[2], results[3])
    
    -- Run animations
    self:ResetSequence(self.cacheSeq['leverpull'])
    timer.Simple(0.5, function()
        if not IsValid(self) then return end
        PerfectCasino.Sound.Play(self, "other_lever")
    end)
    
    timer.Simple(self:SequenceDuration(self.cacheSeq['leverpull']), function()
        if not IsValid(self) then return end
        self:ResetSequence(self.cacheSeq['idle'])
        PerfectCasino.Sound.Stop(self, "other_lever")
    end)
    
    -- Start spinning
    timer.Simple(1, function()
        if not IsValid(self) then return end
        
        -- Network optimization - only send to nearby players
        if canSendNetwork(nil, "Spin:Start", 0.5) then
            local nearbyPlayers = {}
            for _, p in ipairs(player.GetAll()) do
                if p:GetPos():DistToSqr(self:GetPos()) < 562500 then
                    table.insert(nearbyPlayers, p)
                end
            end
            
            if #nearbyPlayers > 0 then
                net.Start("pCasino:BasicSlot:Spin:Start")
                    net.WriteEntity(self)
                net.Send(nearbyPlayers)
            end
        end
        
        PerfectCasino.Sound.Play(self, "other_slot_spin")
        
        -- Stop wheels
        for i=1, 3 do
            local delay = i + (((i == 3) and results.suspense) and 2 or 0)
            timer.Simple(delay, function()
                if not IsValid(self) then return end
                
                self:WheelStop(i, results)
                
                if i == 3 then
                    self:EndRound(ply, win, results)
                end
            end)
        end
    end)
end

function ENT:WheelStop(i, results)
    -- Network optimization
    if canSendNetwork(nil, "Spin:Stop"..i, 0.2) then
        net.Start("pCasino:BasicSlot:Spin:Stop")
            net.WriteEntity(self)
            net.WriteUInt(i, 2)
            net.WriteString(results[i])
        net.Broadcast()
    end
    
    -- Sound management
    PerfectCasino.Sound.Stop(self, "basic_slotmachine_stop"..(i-1))
    
    if (i ~= 3) or (not results.suspense) then
        PerfectCasino.Sound.Play(self, "basic_slotmachine_stop"..i)
    end
    
    if results.suspense and (i == 2) then
        PerfectCasino.Sound.Play(self, "basic_slotmachine_suspense")
    end
end

function ENT:EndRound(ply, win, results)
    PerfectCasino.Sound.Stop(self, "basic_slotmachine_suspense")
    PerfectCasino.Sound.Stop(self, "other_slot_spin")
    
    if not win then
        if results.suspense then
            PerfectCasino.Sound.Play(self, "basic_slotmachine_fail")
            timer.Simple(1, function()
                if not IsValid(self) then return end
                PerfectCasino.Sound.Stop(self, "basic_slotmachine_fail")
            end)
        end
        
        hook.Run("pCasinoOnBasicSlotMachineLoss", ply, self, self.data.bet.default)
        self.isActive = false
        return
    end
    
    -- Send win notification
    if canSendNetwork(nil, "Spin:Win", 0.5) then
        local nearbyPlayers = {}
        for _, p in ipairs(player.GetAll()) do
            if p:GetPos():DistToSqr(self:GetPos()) < 562500 then
                table.insert(nearbyPlayers, p)
            end
        end
        
        if #nearbyPlayers > 0 then
            net.Start("pCasino:BasicSlot:Spin:Win")
                net.WriteEntity(self)
                net.WriteTable(win)
            net.Send(nearbyPlayers)
        end
    end
    
    -- Calculate winnings
    local baseWinnings = self.data.bet.default + (self.data.bet.default * tonumber(win.p))
    PerfectCasino.Config.AddMoney(ply, baseWinnings)
    hook.Run("pCasinoOnBasicSlotMachinePayout", ply, self, baseWinnings)
    
    if baseWinnings ~= self.data.bet.default then
        PerfectCasino.Core.Msg(string.format(PerfectCasino.Translation.Chat.Payout, PerfectCasino.Config.FormatMoney(baseWinnings)), ply)
    end
    
    -- Handle jackpot
    if tobool(self.data.jackpot.toggle) and tobool(win.j) then
        local jackpotAmount = self:GetCurrentJackpot()
        PerfectCasino.Config.AddMoney(ply, jackpotAmount)
        hook.Run("pCasinoOnBasicSlotMachineJackpot", ply, self, jackpotAmount)
        PerfectCasino.Core.Msg(string.format(PerfectCasino.Translation.Chat.PayoutJackpot, PerfectCasino.Config.FormatMoney(jackpotAmount)), ply)
        self:SetCurrentJackpot(0)
    end
    
    -- Play win sound
    if tobool(self.data.jackpot.toggle) and tobool(win.j) then
        PerfectCasino.Sound.Play(self, "basic_slotmachine_jackpot")
    else
        PerfectCasino.Sound.Play(self, "basic_slotmachine_win")
    end
    
    -- Reset after delay
    local resetDelay = (tobool(self.data.jackpot.toggle) and tobool(win.j)) and 5 or 2
    timer.Simple(resetDelay, function()
        if not IsValid(self) then return end
        
        self.isActive = false
        
        if tobool(self.data.jackpot.toggle) and tobool(win.j) then
            PerfectCasino.Sound.Stop(self, "basic_slotmachine_jackpot")
            self:SetCurrentJackpot(self.data.jackpot.startValue)
        else
            PerfectCasino.Sound.Stop(self, "basic_slotmachine_win")
        end
    end)
end