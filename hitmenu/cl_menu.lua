--[[
Modern Hitman Menu (Üst Kısım Fontları Düzeltildi v2)
Açıklama: Font hatası giderildi ve üst kısımdaki tüm yazıların
           (Başlık, İsim, Fiyat) fontları büyütülerek daha okunaklı hale getirildi.
--]]

local PANEL
local minHitDistanceSqr = GM.Config.minHitDistance * GM.Config.minHitDistance

-- Güncellenmiş Modern Renk Paleti
local colors = {
    background = Color(38, 40, 48, 245),        -- Biraz daha koyu ve az doygun arkaplan
    panelBorder = Color(80, 85, 95, 100),       -- Daha yumuşak kenarlık
    primaryText = Color(245, 245, 245, 255),    -- Standart beyaz metin
    secondaryText = Color(160, 165, 175, 220),  -- Daha griye yakın ikincil metin
    accent = Color(60, 180, 160, 255),       -- Turkuaz/Yeşil vurgu (Onay)
    accentDark = Color(45, 150, 130, 255),      -- Koyu vurgu
    price = Color(220, 180, 90, 255),         -- Fiyat için altın sarısı
    error = Color(210, 75, 75, 255),          -- Biraz daha yumuşak kırmızı (İptal)
    errorDark = Color(180, 55, 55, 255),        -- Koyu kırmızı
    rowDefault = Color(48, 50, 60, 180),        -- Nötr satır arkaplanı
    rowHover = Color(60, 62, 72, 210),        -- Satır üzerine gelince hafif vurgu
    rowSelected = Color(70, 72, 82, 230),       -- Seçili satır arkaplanı (nötr)
    rowSelectedBorder = Color(255, 255, 255, 50) -- Seçili satır için hafif iç kenarlık
}

-- Özel Arkaplan Çizim Fonksiyonları (Dosya Kapsamına Taşındı)
local function DrawBackground( x, y, w, h, color )
	-- Basit yuvarlak köşeli kutu
	draw.RoundedBox( 10, x, y, w, h, color )
end

local function DrawInsetBox( x, y, w, h, color, iSize )
	surface.SetDrawColor( ColorAlpha( color_black, color.a * 0.4 ) )
	surface.DrawRect( x + iSize, y + iSize, w - iSize * 2, h - iSize * 2 )

	surface.SetDrawColor( color )
	surface.DrawOutlinedRect( x, y, w, h )
	surface.DrawOutlinedRect( x + iSize, y + iSize, w - iSize * 2, h - iSize * 2 )
end

--[[---------------------------------------------------------------------------
Hitman menu (Ana Panel)
---------------------------------------------------------------------------]]
PANEL = {}

AccessorFunc(PANEL, "hitman", "Hitman")
AccessorFunc(PANEL, "target", "Target")
AccessorFunc(PANEL, "selected", "Selected")

function PANEL:Init()
    self.BaseClass.Init(self)

    self.btnClose = vgui.Create("DButton", self)
    self.btnClose:SetText("")
    self.btnClose.DoClick = function() self:Remove() end
    self.btnClose.Paint = function(panel, w, h)
        local bgColor = panel:IsHovered() and colors.error or Color(colors.error.r * 0.8, colors.error.g * 0.8, colors.error.b * 0.8, 220)
        draw.RoundedBox(4, 0, 0, w, h, bgColor)
        surface.SetDrawColor(colors.primaryText)
        local pad = w * 0.3
        surface.DrawLine(pad, pad, w - pad, h - pad)
        surface.DrawLine(w - pad, pad, pad, h - pad)
    end

    self.icon = vgui.Create("SpawnIcon", self)
    self.icon:SetDisabled(true)
    self.icon.PaintOver = function(icon) icon:SetTooltip() end
    self.icon:SetTooltip()

    self.title = vgui.Create("DLabel", self)
    self.title:SetText(DarkRP.getPhrase("hitman"))
    self.title:SetColor(colors.primaryText)

    self.name = vgui.Create("DLabel", self)
    self.name:SetColor(colors.secondaryText)

    self.price = vgui.Create("DLabel", self)
    self.price:SetColor(colors.price)

    self.playerList = vgui.Create("DScrollPanel", self)
    local sb = self.playerList:GetVBar()
    if sb then
        sb:SetWide(8) -- Daha ince scrollbar
        sb.Paint = function(panel, w, h) draw.RoundedBox(4, 0, 0, w, h, Color(colors.background.r, colors.background.g, colors.background.b, 200)) end
        sb.btnUp.Paint = function(panel, w, h) draw.RoundedBox(4, 0, 0, w, h, colors.secondaryText) end
        sb.btnDown.Paint = function(panel, w, h) draw.RoundedBox(4, 0, 0, w, h, colors.secondaryText) end
        sb.btnGrip.Paint = function(panel, w, h) draw.RoundedBox(4, 0, 0, w, h, colors.accent) end
    end

    self.btnRequest = vgui.Create("HitmanMenuButton", self)
    self.btnRequest:SetText(DarkRP.getPhrase("hitmenu_request"))
    self.btnRequest.DoClick = function()
        if IsValid(self:GetTarget()) then
            RunConsoleCommand("darkrp", "requesthit", self:GetTarget():SteamID(), self:GetHitman():UserID())
            self:Remove()
        end
    end

    self.btnCancel = vgui.Create("HitmanMenuButton", self)
    self.btnCancel:SetText(DarkRP.getPhrase("cancel"))
    self.btnCancel.DoClick = function() self:Remove() end

    -- self:SetSkin(GAMEMODE.Config.DarkRPSkin) -- Kaldırıldı

    self:InvalidateLayout()
end

function PANEL:Think()
    if not IsValid(self:GetHitman()) or self:GetHitman():GetPos():DistToSqr(LocalPlayer():GetPos()) > minHitDistanceSqr then
        self:Remove()
        return
    end
    self.price:SetText(DarkRP.getPhrase("priceTag", DarkRP.formatMoney(self:GetHitman():getHitPrice()), ""))
    self.price:SizeToContents()
end

function PANEL:PerformLayout()
    local w, h = self:GetSize()

    self:SetSize(500, 620) -- Boyut ayarı
    self:Center()

    self.btnClose:SetSize(20, 20)
    self.btnClose:SetPos(w - self.btnClose:GetWide() - 10, 10)

    local iconSize = 90
    self.icon:SetSize(iconSize, iconSize)
    self.icon:SetModel(self:GetHitman():GetModel())
    self.icon:SetPos(25, 45)

    -- FONT DÜZELTME ve BÜYÜTME: Tüm üst yazılar için "Trebuchet24" kullanıldı
    self.title:SetFont("Trebuchet24") -- Daha büyük ve genellikle var olan font
    self.title:SetPos(iconSize + 50, 50)
    self.title:SizeToContents() -- Otomatik boyutlandırma

    self.name:SetFont("Trebuchet24") -- İsim fontu da büyütüldü ve standartlaştırıldı
    self.name:SetText(DarkRP.getPhrase("name", self:GetHitman():Nick()))
    -- Konumu başlığın altına göre ayarla
    self.name:SetPos(iconSize + 50, self.title:GetTall() + 55)
    self.name:SizeToContents()

    self.price:SetFont("Trebuchet24") -- Fiyat fontu da aynı
    -- Konumu ismin altına göre ayarla
    self.price:SetPos(iconSize + 50, self.name:GetTall() + self.title:GetTall() + 65)
    -- Boyut Think içinde ayarlanıyor

    -- Liste ve Buton yerleşimi (Konumlar üstteki elemanlara göre ayarlandı)
    -- Dinamik Y konumu hesaplama
    local currentY = self.price:GetTall() + self.name:GetTall() + self.title:GetTall() + 75 -- Fiyatın altına boşluk bırak
    local listTop = currentY
    local listBottomMargin = 70
    local btnHeight = 45

    -- Liste yüksekliğinin negatif olmamasını sağla
    local listHeight = h - listTop - listBottomMargin
    if listHeight < 50 then listHeight = 50 end -- Minimum yükseklik

    self.playerList:SetPos(20, listTop)
    self.playerList:SetSize(w - 40, listHeight)

    local btnWidth = (w - 50) / 2 -- Butonlar arası boşluk
    self.btnRequest:SetSize(btnWidth, btnHeight)
    self.btnCancel:SetSize(btnWidth, btnHeight)

    self.btnRequest:SetPos(20, h - btnHeight - 20)
    self.btnRequest:SetButtonColor(colors.accent)

    self.btnCancel:SetPos(w - btnWidth - 20, h - btnHeight - 20)
    self.btnCancel:SetButtonColor(colors.error)

    local sb = self.playerList:GetVBar()
    self.playerList:GetCanvas():SetWide(self.playerList:GetWide() - (IsValid(sb) and sb:IsVisible() and sb:GetWide() or 0))

    self.BaseClass.PerformLayout(self)
end

function PANEL:Paint(w, h)
    -- Hafif gölgeli arkaplan
    DrawBackground( 0, 0, w, h, colors.background ) -- Kendi fonksiyonumuzla çizelim

    -- Dış kenarlık
    surface.SetDrawColor(colors.panelBorder)
    surface.DrawOutlinedRect(0, 0, w, h, 1)

    -- Başlık alanı için ayırıcı çizgi
    surface.SetDrawColor(colors.panelBorder)
    -- Çizginin Y konumunu dinamik olarak ayarlayalım (liste başlangıcının üstü)
    -- PerformLayout'taki listTop değerini kullanmak daha doğru olur ama Paint içinde erişimi yok.
    -- Bu yüzden yaklaşık bir değer kullanıyoruz veya PerformLayout'ta çizgi için bir panel oluşturabiliriz.
    -- Üstteki elemanların yüksekliğini tekrar hesaplayarak daha doğru bir Y bulalım
    local titleH = select(2, self.title:GetSize()) -- Gerçek yüksekliği al
    local nameH = select(2, self.name:GetSize())
    local priceH = select(2, self.price:GetSize())
    local lineY = 50 + titleH + 5 + nameH + 10 + priceH + 10 -- Elemanların Y pozisyonları ve boşluklara göre
    if lineY > h - 80 then lineY = 145 end -- Eğer hesaplama anormal olursa veya çok aşağı inerse varsayılanı kullan
    surface.DrawLine(15, lineY, w - 15, lineY)
end

-- Özel Arkaplan Çizim Fonksiyonları Tanımları BURADA DEĞİL, YUKARIDA!

function PANEL:AddPlayerRows()
    local players = table.Copy(player.GetAll())

    table.sort(players, function(a, b)
        local aTeam, bTeam, aNick, bNick = team.GetName(a:Team()), team.GetName(b:Team()), string.lower(a:Nick()), string.lower(b:Nick())
        return aTeam == bTeam and aNick < bNick or aTeam < bTeam
    end)

    self.playerList:Clear()

    for _, v in ipairs(players) do
        if v == LocalPlayer() or v == self:GetHitman() then continue end

        local canRequest = hook.Call("canRequestHit", DarkRP.hooks, self:GetHitman(), LocalPlayer(), v, self:GetHitman():getHitPrice())
        if not canRequest then continue end

        local line = vgui.Create("HitmanMenuPlayerRow", self.playerList)
        line:SetPlayer(v)
        line:SetTall(28) -- Satır yüksekliğini biraz artıralım
        line:Dock(TOP)
        line:DockMargin(0, 0, 0, 2) -- Satırlar arası boşluk

        line.DoClick = function(panel)
            self:SetTarget(panel:GetPlayer())

            local previousSelected = self:GetSelected()
            if IsValid(previousSelected) and previousSelected ~= panel then
                -- Önceki seçimi kaldırmadan önce Invalidate'ın varlığını kontrol et
                if previousSelected.SetSelected then
                    previousSelected:SetSelected(false)
                end
            end

            panel:SetSelected(true)
            self:SetSelected(panel)
        end
    end
    self.playerList:InvalidateLayout(true)
end

vgui.Register("HitmanMenu", PANEL, "DPanel")

--[[---------------------------------------------------------------------------
Hitmenu button
---------------------------------------------------------------------------]]
PANEL = {}

AccessorFunc(PANEL, "btnColor", "ButtonColor")

function PANEL:Init()
    self.BaseClass.Init(self)
    self:SetFont("DermaDefaultBold")
    self:SetTextColor(colors.primaryText)
end

function PANEL:PerformLayout()
    self.BaseClass.PerformLayout(self)
end

function PANEL:Paint(w, h)
    local col = self:GetButtonColor() or colors.accent
    local textColor = self:GetTextColor()
    local corner = 6 -- Köşe yuvarlaklığı

    local targetCol = col
    if self:IsDown() then
        targetCol = (col == colors.accent) and colors.accentDark or colors.errorDark
    elseif self:IsHovered() then
        targetCol = Color(col.r * 1.1, col.g * 1.1, col.b * 1.1, col.a) -- Daha hafif hover
        targetCol.r = math.min(targetCol.r, 255) targetCol.g = math.min(targetCol.g, 255) targetCol.b = math.min(targetCol.b, 255)
    end

    -- Buton arkaplanı
    draw.RoundedBox(corner, 0, 0, w, h, targetCol)

    -- Hafif iç gölge/kenarlık efekti
    draw.RoundedBox(corner, 1, 1, w - 2, h - 2, ColorAlpha(color_black, 30))
    draw.RoundedBox(corner, 1, 1, w - 2, h - 3, ColorAlpha(color_white, 15)) -- Üstten ışık

    -- Metni çiz
    self:DrawTextEntryText(textColor, textColor, textColor)
end

vgui.Register("HitmanMenuButton", PANEL, "DButton")

--[[---------------------------------------------------------------------------
Player row
---------------------------------------------------------------------------]]
PANEL = {}

AccessorFunc(PANEL, "player", "Player")
AccessorFunc(PANEL, "selected", "Selected", FORCE_BOOL)

function PANEL:Init()
    self.BaseClass.Init(self)

    self.lblName = vgui.Create("DLabel", self)
    self.lblName:SetMouseInputEnabled(false)
    self.lblName:SetColor(colors.primaryText)
    self.lblName:SetFont("DermaDefaultBold")

    self.lblTeam = vgui.Create("DLabel", self)
    self.lblTeam:SetMouseInputEnabled(false)
    self.lblTeam:SetColor(colors.secondaryText)
    self.lblTeam:SetFont("DermaDefault")

    self:SetText("")
    self:SetCursor("hand")
end

function PANEL:PerformLayout(w, h)
    local ply = self:GetPlayer()
    if not IsValid(ply) then self:Remove() return end

    local namePadding = 15 -- İsim için sol boşluk
    local jobPadding = 15 -- Meslek için sağ boşluk

    self.lblName:SetText(DarkRP.deLocalise(ply:Nick()))
    self.lblName:SizeToContents()
    self.lblName:SetPos(namePadding, (h - self.lblName:GetTall()) / 2)

    self.lblTeam:SetText((ply.DarkRPVars and DarkRP.deLocalise(ply:getDarkRPVar("job") or "")) or team.GetName(ply:Team()))
    self.lblTeam:SizeToContents()
    self.lblTeam:SetPos(w - self.lblTeam:GetWide() - jobPadding, (h - self.lblTeam:GetTall()) / 2)

    self.lblName:SetWide( math.min( self.lblName:GetWide(), w - self.lblTeam:GetWide() - namePadding - jobPadding - 10 ) ) -- Taşmayı önle
end

function PANEL:Paint(w, h)
    if not IsValid(self:GetPlayer()) then self:Remove() return end

    local corner = 4
    local ply = self:GetPlayer()
    local jobColor = team.GetColor(ply:Team()) or Color(150, 150, 150) -- Meslek rengi veya varsayılan gri
    jobColor.a = 255 -- Alfa değerini tam yapalım

    local bgColor
    local leftBarColor = ColorAlpha(jobColor, 0) -- Varsayılan olarak görünmez sol çubuk

    if self:GetSelected() then
        bgColor = colors.rowSelected
        leftBarColor = jobColor -- Seçiliyse meslek rengi
    elseif self:IsHovered() then
        bgColor = colors.rowHover
        leftBarColor = ColorAlpha(jobColor, 180) -- Üzerine gelince yarı şeffaf meslek rengi
    else
        bgColor = colors.rowDefault
    end

    -- Arkaplan
    draw.RoundedBox(corner, 0, 0, w, h, bgColor)

    -- Sol tarafa meslek rengi çubuğu
    if leftBarColor.a > 0 then
        draw.RoundedBoxEx(corner, 0, 0, 5, h, leftBarColor, true, false, true, false) -- Sadece sol köşeler yuvarlak
    end

    -- Seçiliyse hafif iç kenarlık
    if self:GetSelected() then
         draw.RoundedBox(corner, 1, 1, w - 2, h - 2, colors.rowSelectedBorder)
    end
end

-- Seçim değiştiğinde rengin güncellenmesi için
function PANEL:SetSelected(bSelected)
    if self.selected == bSelected then return end
    self.selected = bSelected
    -- HATA DÜZELTMESİ: Invalidate çağrılmadan önce hem panelin hem de metodun varlığını kontrol et
    if IsValid(self) and type(self.Invalidate) == "function" then
        self:Invalidate()
    end
end

vgui.Register("HitmanMenuPlayerRow", PANEL, "Button")

--[[---------------------------------------------------------------------------
Open the hit menu
---------------------------------------------------------------------------]]
function DarkRP.openHitMenu(hitman)
    if IsValid(g_HitmanMenu) then g_HitmanMenu:Remove() end

    local frame = vgui.Create("HitmanMenu")
    frame:SetHitman(hitman)
    frame:AddPlayerRows()
    frame:SetVisible(true)
    frame:MakePopup()

    g_HitmanMenu = frame
end