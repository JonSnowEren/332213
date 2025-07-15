--[[
Hitman Sistemi - Sunucu Tarafı (Gelişmiş Ölüm İptal Mantığı)
Açıklama: Hedef öldüğünde hitin iptal olma mantığı güncellendi:
           - World hasarı/intihar ile ölürse iptal olmaz.
           - Başka bir oyuncu (hitman hariç) öldürürse iptal olur.
           - Hitman öldürürse başarılı olur.
           Sohbet mesajları korundu.
--]]

local plyMeta = FindMetaTable("Player")
local hits = {}
local questionCallback

--[[---------------------------------------------------------------------------
Net messages (Değişiklik yok)
---------------------------------------------------------------------------]]
util.AddNetworkString("onHitAccepted")
util.AddNetworkString("onHitCompleted")
util.AddNetworkString("onHitFailed")

--[[---------------------------------------------------------------------------
Interface functions (Değişiklik yok)
---------------------------------------------------------------------------]]
DarkRP.getHits = fp{fn.Id, hits}

function plyMeta:requestHit(customer, target, price)
    local canRequest, msg, cost = hook.Call("canRequestHit", DarkRP.hooks, self, customer, target, price)
    price = cost or price

    if canRequest == false then
        DarkRP.notify(customer, 1, 4, msg)
        return false
    end

    DarkRP.createQuestion(DarkRP.getPhrase("accept_hit_request", customer:Nick(), target:Nick(), DarkRP.formatMoney(price)),
        "hit" .. self:UserID() .. "|" .. customer:UserID() .. "|" .. target:UserID(),
        self,
        20,
        questionCallback,
        customer,
        target,
        price
    )

    DarkRP.notify(customer, 1, 4, DarkRP.getPhrase("hit_requested"))

    return true
end

function plyMeta:placeHit(customer, target, price)
    if hits[self] then DarkRP.error("This person has an active hit!", 2) end

    if not customer:canAfford(price) then
        DarkRP.notify(customer, 1, 4, DarkRP.getPhrase("cant_afford", DarkRP.getPhrase("hit")))
        return
    end

    hits[self] = {}
    hits[self].price = price -- the agreed upon price (as opposed to the price set by the hitman)

    self:setHitCustomer(customer)
    self:setHitTarget(target)

    DarkRP.payPlayer(customer, self, price)

    hook.Call("onHitAccepted", DarkRP.hooks, self, target, customer)
end

function plyMeta:setHitTarget(target)
    if not hits[self] then DarkRP.error("This person has no active hit!", 2) end

    self:setSelfDarkRPVar("hitTarget", target)
    self:setDarkRPVar("hasHit", target and true or nil)
end

function plyMeta:setHitPrice(price)
    self:setDarkRPVar("hitPrice", math.Min(GAMEMODE.Config.maxHitPrice or 50000, math.Max(GAMEMODE.Config.minHitPrice or 200, price)))
end

function plyMeta:setHitCustomer(customer)
    if not hits[self] then DarkRP.error("This person has no active hit!", 2) end

    hits[self].customer = customer
end

function plyMeta:getHitCustomer()
    return hits[self] and hits[self].customer or nil
end

function plyMeta:abortHit(message)
    if not hits[self] then DarkRP.error("This person has no active hit!", 2) end

    message = message or ""

    hook.Call("onHitFailed", DarkRP.hooks, self, self:getHitTarget(), message)
    -- DarkRP.notifyAll(0, 4, DarkRP.getPhrase("hit_aborted", message)) -- Bu satır onHitFailed hook'una taşındı

    self:finishHit()
end

function plyMeta:cancelHit()
    if not hits[self] then DarkRP.error("This person has no active hit!", 2) end
    if not self:canAfford(hits[self].price) then
        DarkRP.notify(self, 1, 4, DarkRP.getPhrase("cant_afford", DarkRP.getPhrase("hit_cancel")))
        return
    end

    DarkRP.payPlayer(self, hits[self].customer, hits[self].price)

    self:abortHit(DarkRP.getPhrase("hit_cancelled"))
end

function plyMeta:finishHit()
    self:setHitCustomer(nil)
    self:setHitTarget(nil)
    hits[self] = nil
end

function questionCallback(answer, hitman, customer, target, price)
    if not IsValid(customer) then return end
    if not IsValid(hitman) or not hitman:isHitman() then return end

    if not IsValid(customer) then
        DarkRP.notify(hitman, 1, 4, DarkRP.getPhrase("customer_left_server"))
        return
    end

    if not IsValid(target) then
        DarkRP.notify(hitman, 1, 4, DarkRP.getPhrase("target_left_server"))
        return
    end

    if not tobool(answer) then
        DarkRP.notify(customer, 1, 4, DarkRP.getPhrase("hit_declined"))
        return
    end

    if hits[hitman] then return end

    DarkRP.notify(hitman, 1, 4, DarkRP.getPhrase("hit_accepted"))

    hitman:placeHit(customer, target, price)
end

--[[---------------------------------------------------------------------------
Chat commands (Değişiklik yok)
---------------------------------------------------------------------------]]
DarkRP.defineChatCommand("hitprice", function(ply, args)
    if not ply:isHitman() then return "" end
    local price = DarkRP.toInt(args) or 0
    ply:setHitPrice(price)
    price = ply:getHitPrice()

    DarkRP.notify(ply, 2, 4, DarkRP.getPhrase("hit_price_set", DarkRP.formatMoney(price)))

    return ""
end)

DarkRP.defineChatCommand("requesthit", function(ply, args)
    args = string.Explode(' ', args)
    local target = DarkRP.findPlayer(args[1])
    local traceEnt = ply:GetEyeTrace().Entity
    local hitman = IsValid(traceEnt) and traceEnt:IsPlayer() and traceEnt or Player(tonumber(args[2] or -1) or -1)

    if not IsValid(hitman) or not IsValid(target) or not hitman:IsPlayer() then
        DarkRP.notify(ply, 1, 4, DarkRP.getPhrase("invalid_x", DarkRP.getPhrase("arguments"), ""))
        return ""
    end

    hitman:requestHit(ply, target, hitman:getHitPrice())

    return ""
end)

DarkRP.defineChatCommand("cancelhit", function(ply, args)
    if not hits[ply] then
        DarkRP.notify(ply, 1, 4, DarkRP.getPhrase("no_active_hit"))
        return ""
    end

    ply:cancelHit()
end)

--[[---------------------------------------------------------------------------
Hooks
---------------------------------------------------------------------------]]
-- onHitAccepted Hook'u Renkli Sohbet Mesajı İçin Güncellendi
function DarkRP.hooks:onHitAccepted(hitman, target, customer)
    net.Start("onHitAccepted")
        net.WriteEntity(hitman)
        net.WriteEntity(target)
        net.WriteEntity(customer)
    net.Broadcast()

    DarkRP.notify(customer, 0, 8, DarkRP.getPhrase("hit_accepted"))
    customer.lastHitAccepted = CurTime()

    -- RENKLİ SOHBET MESAJI:
    -- Hedef oyuncunun ismini al
    local targetName = "Bilinmeyen Oyuncu" -- Varsayılan isim
    if IsValid(target) then
        targetName = target:Nick()
    end

    -- Renkli mesajı formatla (<rgb:R,G,B> formatında)
    local message = string.format("<rgb:255,255,0>[Suikast] <rgb:255,0,0>%s <rgb:255,255,255>adlı oyuncuya suikast düzenlenecek.", targetName)

    -- Tüm oyunculara gönder
    for _, p in ipairs(player.GetAll()) do
        p:ChatPrint(message)
    end

    DarkRP.log("Hitman " .. hitman:Nick() .. " accepted a hit on " .. target:Nick() .. ", ordered by " .. customer:Nick() .. " for " .. DarkRP.formatMoney(hits[hitman].price), Color(255, 0, 255))
end

-- onHitCompleted Hook'u Renkli Sohbet Mesajı İçin Güncellendi
function DarkRP.hooks:onHitCompleted(hitman, target, customer)
    net.Start("onHitCompleted")
        net.WriteEntity(hitman)
        net.WriteEntity(target)
        net.WriteEntity(customer)
    net.Broadcast()

    -- DarkRP.notifyAll(0, 6, DarkRP.getPhrase("hit_complete", hitman:Nick())) -- Eski bildirim kaldırıldı

    -- RENKLİ SOHBET MESAJI (Tamamlandı):
    local message = "<rgb:255,255,0>[Suikast] <rgb:0,255,0>Suikast tamamlandı."
    for _, p in ipairs(player.GetAll()) do
        p:ChatPrint(message)
    end

    local targetname = IsValid(target) and target:Nick() or "disconnected player"
    local customername = IsValid(customer) and customer:Nick() or "disconnected player"

    DarkRP.log("Hitman " .. hitman:Nick() .. " finished a hit on " .. targetname .. ", ordered by " .. customername .. " for " .. DarkRP.formatMoney(hits[hitman].price), Color(255, 0, 255))

    if IsValid(target) then -- Sadece hedef geçerliyse lastHitTime ayarla
        target:setDarkRPVar("lastHitTime", CurTime())
    end

    hitman:finishHit()
end

-- onHitFailed Hook'u Renkli Sohbet Mesajı İçin Güncellendi
function DarkRP.hooks:onHitFailed(hitman, target, reason)
    net.Start("onHitFailed")
        net.WriteEntity(hitman)
        net.WriteEntity(target)
        net.WriteString(reason)
    net.Broadcast()

    -- DarkRP.notifyAll(0, 4, DarkRP.getPhrase("hit_aborted", message)) -- Bu bildirim abortHit içindeydi, şimdi burada
    -- RENKLİ SOHBET MESAJI (Başarısız):
    local message = "<rgb:255,255,0>[Suikast] <rgb:255,0,0>Suikast başarısız."
    for _, p in ipairs(player.GetAll()) do
        p:ChatPrint(message)
    end

    local targetname = IsValid(target) and target:Nick() or "disconnected player"

    DarkRP.log("Hit on " .. targetname .. " failed. Reason: " .. reason, Color(255, 0, 255))
end

-- PlayerDeath Hook'u Güncellendi
hook.Add("PlayerDeath", "DarkRP Hitman System", function(ply, inflictor, attacker)
    -- Eğer ölen kişi bir hitman ise, hit iptal olur (Bu değişmedi)
    if hits[ply] then
        ply:abortHit(DarkRP.getPhrase("hitman_died"))
    end

    -- Eğer saldıran kişi hitman ise ve ölen kişi hedef ise, hit tamamlanır (Bu değişmedi)
    if IsValid(attacker) and attacker:IsPlayer() and hits[attacker] and attacker:getHitTarget() == ply then
        hook.Call("onHitCompleted", DarkRP.hooks, attacker, ply, hits[attacker].customer)
    end

    -- Ölen kişinin hedef olduğu hitleri kontrol et
    for hitman in pairs(hits) do
        -- Hitman geçerli mi ve bu hitman için bir hit kaydı var mı kontrol et
        if not hitman or not IsValid(hitman) or not hits[hitman] then hits[hitman] = nil continue end

        -- Eğer ölen kişi bu hitman'in hedefi ise
        if IsValid(hitman:getHitTarget()) and hitman:getHitTarget() == ply then
            -- DEĞİŞİKLİK: Sadece başka bir oyuncu (hitman olmayan) tarafından öldürüldüyse iptal et
            if IsValid(attacker) and attacker:IsPlayer() and attacker ~= ply and attacker ~= hitman then
                -- Başka bir oyuncu öldürdüyse iptal et
                -- Dil dosyanıza "target_killed_by_other" eklemeyi unutmayın:
                -- ["target_killed_by_other"] = "Hedef başka bir oyuncu (%s) tarafından öldürüldü.",
                hitman:abortHit(DarkRP.getPhrase("target_killed_by_other", attacker:Nick()))
            -- else: World hasarı, intihar veya görevli hitman tarafından öldürüldü, iptal etme.
            -- (Hitman öldürdüyse onHitCompleted zaten çalışacak)
            end
            -- Bu hedef için başka işlem yapmaya gerek yok, döngüden çıkabiliriz (isteğe bağlı)
            -- break
        end
    end
end)


hook.Add("PlayerDisconnected", "Hitman system", function(ply)
    if hits[ply] then
        ply:abortHit(DarkRP.getPhrase("hitman_left_server"))
    end

    for hitman, hit in pairs(hits) do
        if not hitman or not IsValid(hitman) then hits[hitman] = nil continue end -- Güvenlik kontrolü
        if hit.customer == ply then
            hitman:abortHit(DarkRP.getPhrase("customer_left_server"))
        -- Hedef kontrolü için de IsValid ekleyelim
        elseif IsValid(hitman:getHitTarget()) and hitman:getHitTarget() == ply then
            hitman:abortHit(DarkRP.getPhrase("target_left_server"))
        end
    end
end)

hook.Add("playerArrested", "Hitman system", function(ply)
    if not hits[ply] or not IsValid(hits[ply].customer) then return end

    for _, v in ipairs(player.GetAll()) do
        if not v:isCP() then continue end

        DarkRP.notify(v, 0, 8, DarkRP.getPhrase("x_had_hit_ordered_by_y", ply:Nick(), hits[ply].customer:Nick()))
    end

    ply:abortHit(DarkRP.getPhrase("hitman_arrested"))
end)

hook.Add("OnPlayerChangedTeam", "Hitman system", function(ply, prev, new)
    if hits[ply] then
        ply:abortHit(DarkRP.getPhrase("hitman_changed_team"))
    end
end)