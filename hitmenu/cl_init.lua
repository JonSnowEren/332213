--[[
Modern Hitman HUD (Crosshair Rengi)
Açıklama: Glow ve işaretçi kaldırıldı. Hedef görünürse yazı yeşil,
           crosshair hedef üzerindeyse yazı kırmızı olur.
--]]

local localplayer
local hudText
-- Modern Renk Paleti (cl_menu.lua ile uyumlu)
local colors = {
    background = Color(38, 40, 48, 245),
    panelBorder = Color(80, 85, 95, 100),
    primaryText = Color(245, 245, 245, 255),    -- Ana HUD yazıları için (Daha belirgin)
    secondaryText = Color(160, 165, 175, 220),
    accent = Color(60, 180, 160, 255),       -- Yeşil vurgu rengi
    accentBright = Color(0, 255, 0, 255),    -- Standart Parlak Yeşil (Görünür hedef için yazı)
    accentDark = Color(45, 150, 130, 255),
    price = Color(220, 180, 90, 255),
    error = Color(255, 0, 0, 255),          -- Parlak Kırmızı (Crosshair hedefte)
    errorDark = Color(180, 55, 55, 255),
    hudShadow = Color(0, 0, 0, 180)             -- HUD yazıları için gölge rengi
}
-- Eski renk tanımlarını kaldırıyoruz:
-- local textCol1, textCol2 = Color(0, 0, 0, 200), Color(128, 30, 30, 255)

local plyMeta = FindMetaTable("Player")
local activeHitmen = {}
-- local postPlayerDraw -- Kaldırıldı
local minHitDistanceSqr = GM.Config.minHitDistance * GM.Config.minHitDistance

-- Glow/Marker değişkenleri kaldırıldı
-- local targetToMark = nil
-- local isTargetCurrentlyVisible = false

--[[---------------------------------------------------------------------------
Interface functions
---------------------------------------------------------------------------]]
function plyMeta:drawHitInfo()
    activeHitmen[self] = true
    -- hook.Remove("PostPlayerDraw", "HitmanTargetMarker") -- Hook kaldırıldı, eklemeye gerek yok
end

function plyMeta:stopHitInfo()
    activeHitmen[self] = nil
    -- Hook kaldırıldığı için burada bir işlem yapmaya gerek yok
end

--[[---------------------------------------------------------------------------
Hooks
---------------------------------------------------------------------------]]
function DarkRP.hooks:onHitAccepted(hitman, target, customer)
    if not IsValid(hitman) then return end
    hitman:drawHitInfo()
end

function DarkRP.hooks:onHitCompleted(hitman, target, customer)
    if not IsValid(hitman) then return end
    hitman:stopHitInfo()
end

function DarkRP.hooks:onHitFailed(hitman, target, reason)
    if not IsValid(hitman) then return end
    hitman:stopHitInfo()
end

hook.Add("EntityRemoved", "hitmenu", function(ent)
    activeHitmen[ent] = nil
    -- Hook kaldırıldığı için burada bir işlem yapmaya gerek yok
end)

-- HUDPaint Hook'u (Görünürlük ve Crosshair Rengi)
hook.Add("HUDPaint", "DrawHitOption", function()
    localplayer = localplayer or LocalPlayer()
    hudText = hudText or GAMEMODE.Config.hudText -- Bu metin config'den geliyor
    local x, y
    local eyeTraceEntity = localplayer:GetEyeTrace().Entity

    -- Hitman'e bakınca çıkan "Hit İste" yazısı
    if IsValid(eyeTraceEntity) and eyeTraceEntity:IsPlayer() and eyeTraceEntity:isHitman() and not eyeTraceEntity:hasHit() and localplayer:GetPos():DistToSqr(eyeTraceEntity:GetPos()) < minHitDistanceSqr then
        x, y = ScrW() / 2, ScrH() / 2 + 30

        -- Daha modern font ve renkler
        local font = "Trebuchet24"
        draw.DrawText(hudText, font, x + 1, y + 1, colors.hudShadow, TEXT_ALIGN_CENTER) -- Gölge
        draw.DrawText(hudText, font, x, y, colors.primaryText, TEXT_ALIGN_CENTER) -- Ana renk (Beyaz)
    end

    -- Aktif hit yönetimi
    local currentTarget = nil
    if localplayer:isHitman() and localplayer:hasHit() then
        currentTarget = localplayer:getHitTarget() -- Hedefi al
    end

    local isVisible = false -- Varsayılan olarak görünmez
    local isCrosshairOnTarget = false -- Crosshair hedefte mi?
    local textColor = colors.primaryText -- Varsayılan yazı rengi

    -- Eğer aktif bir hedef varsa
    if IsValid(currentTarget) then
        -- Mesafe Hesaplama
        local distance = math.Round(localplayer:GetPos():Distance(currentTarget:GetPos()) / 39.37) -- İnç'ten metreye çevirip yuvarla

        -- Görünürlük Kontrolü (MASK_SOLID_BRUSHONLY)
        local visibilityTraceData = {
            start = localplayer:EyePos(),
            endpos = currentTarget:GetShootPos(),
            filter = { localplayer, currentTarget },
            mask = MASK_SOLID_BRUSHONLY
        }
        local visibilityTraceResult = util.TraceLine(visibilityTraceData)
        isVisible = not visibilityTraceResult.Hit

        -- Metin ve Renk Ayarlama
        local text = string.format("Hedef: %s (Mesafe: %d m)", currentTarget:Nick(), distance)
        local font = "Trebuchet24"

        if isVisible then
            textColor = colors.accentBright -- Görünürse parlak yeşil

            -- Crosshair Kontrolü (Sadece hedef görünürse yap)
            local aimTraceData = {
                start = localplayer:EyePos(),
                endpos = localplayer:EyePos() + localplayer:GetAimVector() * 16384, -- Uzun mesafe trace
                filter = { localplayer } -- Sadece kendimizi filtrele
                -- Mask kullanmaya gerek yok, oyuncuya çarpıp çarpmadığına bakacağız
            }
            local aimTraceResult = util.TraceLine(aimTraceData)
            isCrosshairOnTarget = aimTraceResult.Hit and aimTraceResult.Entity == currentTarget

            if isCrosshairOnTarget then
                textColor = colors.error -- Crosshair hedefteyse kırmızı
            end
        -- else: Görünür değilse renk beyaz kalır
        end

        -- Konum
        x = ScrW() / 2 -- Ekranın ortası (yatay)
        y = 15 -- Ekranın üstüne yakın (dikey)

        -- Çizim
        draw.DrawText(text, font, x + 1, y + 1, colors.hudShadow, TEXT_ALIGN_CENTER) -- Gölge ve ortalama
        draw.DrawText(text, font, x, y, textColor, TEXT_ALIGN_CENTER) -- Ana renk (beyaz, yeşil veya kırmızı) ve ortalama

    end
end)

-- PostPlayerDraw Hook'u Kaldırıldı
-- hook.Add("PostPlayerDraw", "HitmanTargetMarker", postPlayerDraw)
-- postPlayerDraw = function(ply) ... end

-- KeyPress Hook'u (Değişiklik yok)
local lastKeyPress = 0
hook.Add("KeyPress", "openHitMenu", function(ply, key)
    if key ~= IN_USE or lastKeyPress > CurTime() - 0.2 then return end
    lastKeyPress = CurTime()
    localplayer = localplayer or LocalPlayer()
    local hitman = localplayer:GetEyeTrace().Entity

    if not IsValid(hitman) or not hitman:IsPlayer() or not hitman:isHitman() or localplayer:GetPos():DistToSqr(hitman:GetPos()) > minHitDistanceSqr then return end

    local canRequest, message = hook.Call("canRequestHit", DarkRP.hooks, hitman, ply, nil, hitman:getHitPrice())

    if not canRequest then
        GAMEMODE:AddNotify(DarkRP.getPhrase("cannot_request_hit", message or ""), 1, 4)
        surface.PlaySound("buttons/lightswitch2.wav")
        return
    end

    DarkRP.openHitMenu(hitman)
end)

-- InitPostEntity Hook'u (Değişiklik yok)
hook.Add("InitPostEntity", "HitmanMenu", function()
    for _, v in ipairs(player.GetAll()) do
        if IsValid(v) and v:isHitman() and v:hasHit() then
            v:drawHitInfo()
        end
    end
end)

--[[---------------------------------------------------------------------------
Networking (Değişiklik yok)
---------------------------------------------------------------------------]]
net.Receive("onHitAccepted", function(len)
    hook.Call("onHitAccepted", DarkRP.hooks, net.ReadEntity(), net.ReadEntity(), net.ReadEntity())
end)

net.Receive("onHitCompleted", function(len)
    hook.Call("onHitCompleted", DarkRP.hooks, net.ReadEntity(), net.ReadEntity(), net.ReadEntity())
end)

net.Receive("onHitFailed", function(len)
    hook.Call("onHitFailed", DarkRP.hooks, net.ReadEntity(), net.ReadEntity(), net.ReadString())
end)
