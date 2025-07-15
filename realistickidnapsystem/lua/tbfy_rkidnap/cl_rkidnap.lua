
local RKS_BoneManipulations = {
	["Restrained"] = {
		["ValveBiped.Bip01_R_UpperArm"] = Angle(-28,18,-21),
		["ValveBiped.Bip01_L_Hand"] = Angle(0,0,119),
		["ValveBiped.Bip01_L_Forearm"] = Angle(15,20,40),
		["ValveBiped.Bip01_L_UpperArm"] = Angle(15, 26, 0),
		["ValveBiped.Bip01_R_Forearm"] = Angle(0,50,0),
		["ValveBiped.Bip01_R_Hand"] = Angle(45,34,-15),
		["ValveBiped.Bip01_L_Finger01"] = Angle(0,50,0),
		["ValveBiped.Bip01_R_Finger0"] = Angle(10,2,0),
		["ValveBiped.Bip01_R_Finger1"] = Angle(-10,0,0),
		["ValveBiped.Bip01_R_Finger11"] = Angle(0,-40,0),
		["ValveBiped.Bip01_R_Finger12"] = Angle(0,-30,0)
	},
	["Restrained_StarWars"] = {
		["ValveBiped.Bip01_L_Hand"] = Angle(0,0,119),
		["ValveBiped.Bip01_L_Forearm"] = Angle(0,25,40),
		["ValveBiped.Bip01_L_UpperArm"] = Angle(30, 26, 0),
		["ValveBiped.Bip01_R_UpperArm"] = Angle(-40,20, 0),
		["ValveBiped.Bip01_R_Forearm"] = Angle(5,50,0),
		["ValveBiped.Bip01_R_Hand"] = Angle(45,34,-15),
		["ValveBiped.Bip01_L_Finger01"] = Angle(0,50,0),
		["ValveBiped.Bip01_R_Finger0"] = Angle(10,2,0),
		["ValveBiped.Bip01_R_Finger1"] = Angle(-10,0,0),
		["ValveBiped.Bip01_R_Finger11"] = Angle(0,-40,0),
		["ValveBiped.Bip01_R_Finger12"] = Angle(0,-30,0)
	},	
	["HandsUp"] = {
		["ValveBiped.Bip01_R_UpperArm"] = Angle(73,35,128),
		["ValveBiped.Bip01_L_Hand"] = Angle(-12,12,90),
		["ValveBiped.Bip01_L_Forearm"] = Angle(-28,-29,44),
		["ValveBiped.Bip01_R_Forearm"] = Angle(-22,1,15),
		["ValveBiped.Bip01_L_UpperArm"] = Angle(-77,-46,4),
		["ValveBiped.Bip01_R_Hand"] = Angle(33,39,-21),
		["ValveBiped.Bip01_L_Finger01"] = Angle(0,30,0),
		["ValveBiped.Bip01_L_Finger1"] = Angle(0,45,0),
		["ValveBiped.Bip01_L_Finger11"] = Angle(0,45,0),
		["ValveBiped.Bip01_L_Finger2"] = Angle(0,45,0),
		["ValveBiped.Bip01_L_Finger21"] = Angle(0,45,0),
		["ValveBiped.Bip01_L_Finger3"] = Angle(0,45,0),
		["ValveBiped.Bip01_L_Finger31"] = Angle(0,45,0),
		["ValveBiped.Bip01_R_Finger0"] = Angle(-10,0,0),
		["ValveBiped.Bip01_R_Finger11"] = Angle(0,30,0),
		["ValveBiped.Bip01_R_Finger2"] = Angle(20,25,0),
		["ValveBiped.Bip01_R_Finger21"] = Angle(0,45,0),
		["ValveBiped.Bip01_R_Finger3"] = Angle(20,35,0),
		["ValveBiped.Bip01_R_Finger31"] = Angle(0,45,0)
	}
}

net.Receive("rks_bonemanipulate", function()
	local Player, Type, Reset = net.ReadEntity(), net.ReadString(), net.ReadBool()

	if IsValid(Player) then
		for k,v in pairs(RKS_BoneManipulations[Type]) do
			local Bone = Player:LookupBone(k)
			if Bone then
				if Reset then
					Player:ManipulateBoneAngles(Bone, Angle(0,0,0))
				else
					Player:ManipulateBoneAngles(Bone, v)
				end
			end
		end
		if !Reset and Type == "Restrained" and table.HasValue(RKidnapConfig.FEMALE_MODELS, Player:GetModel()) then
			local LEFT_UP_ARM, RIGHT_UP_ARM, RIGHT_FORE_ARM = Player:LookupBone("ValveBiped.Bip01_L_UpperArm"), Player:LookupBone("ValveBiped.Bip01_R_UpperArm"), Player:LookupBone("ValveBiped.Bip01_R_Forearm")
			if LEFT_UP_ARM then
				Player:ManipulateBoneAngles(Player:LookupBone("ValveBiped.Bip01_L_UpperArm"), Angle(15, 23, 0))
			end
			if RIGHT_UP_ARM then
				Player:ManipulateBoneAngles(Player:LookupBone("ValveBiped.Bip01_R_UpperArm"), Angle(-28, 5, -21))
			end
			if RIGHT_FORE_ARM then
				Player:ManipulateBoneAngles(Player:LookupBone("ValveBiped.Bip01_R_Forearm"), Angle(0, 60, 10))
			end
		end
		if RKidnapConfig.DisablePlayerShadow then
			Player:DrawShadow(false)
		end
	end
end)

net.Receive("tbfy_surr", function(Player, len)
	local SurrTime = net.ReadFloat()
	if SurrTime == 0 then
		LocalPlayer().Surrendering = false
	else
		LocalPlayer().Surrendering = SurrTime
	end
end)

hook.Add("HUDPaint", "TBFY_Surr", function()
	local ST = LocalPlayer().Surrendering
	if ST then
		local W,H = ScrW(), ScrH()
		local TimeLeft = math.Round(ST - CurTime(),1)
		draw.SimpleTextOutlined("Teslim Olunuyor - " .. TimeLeft,"rks_ko_text",ScrW()/2,ScrH()/2,Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,2,Color(0,0,0,255))
	end
end)

local PLAYER = FindMetaTable("Player")
//Whacky way to add text without overriding the function completely
hook.Add("loadCustomDarkRPItems", "rks_set_drawPINFO", function()
	local OldDrawPlayerInfo = PLAYER.drawPlayerInfo
	function RKS_AddInCuffs(self)
		if RKidnapConfig.DisplayOverheadRestrained and self:GetNWBool("rks_restrained", false) then
			local pos = self:EyePos()

			pos.z = pos.z + 10
			pos = pos:ToScreen()
			if not self:getDarkRPVar("wanted") then
				pos.y = pos.y - 50
			end

			draw.DrawNonParsedText("Restrained", "DarkRPHUD2", pos.x + 1, pos.y - 19, Color(0,0,0,255), 1)
			draw.DrawNonParsedText("Restrained", "DarkRPHUD2", pos.x, pos.y - 20, Color(255,255,255,255) , 1)
		end
		OldDrawPlayerInfo(self)
	end
	PLAYER.drawPlayerInfo = RKS_AddInCuffs
end)

net.Receive("rks_update_ragdollcolor", function()
	local Player, Ragdoll = net.ReadEntity(), net.ReadEntity()

	Ragdoll.GetPlayerColor = function() return Player:GetPlayerColor() end
end)

net.Receive("rks_knockout", function()
	local KnockedOut = net.ReadBool()

	LocalPlayer().RKSKOStart = CurTime() + RKidnapConfig.KnockoutTime
	LocalPlayer().RKSKO = KnockedOut
end)

net.Receive("rks_blindfold", function()
	local Blindfolded = net.ReadBool()
	LocalPlayer().RKSBlindfolded = Blindfolded
end)

net.Receive("rks_send_inspect_information", function()
	local Player, WepAmount = net.ReadEntity(), net.ReadFloat()

	local WepTbl = {}
	for i = 1, WepAmount do
		local TID = net.ReadFloat()
		local WepC = net.ReadString()

		if WepC and WepC != "" then
			WepTbl[TID] = WepC
		end
	end

	local InsMenu = vgui.Create("rks_inspect_menu")
	InsMenu:SetupInfo(Player, WepTbl)
	LocalPlayer().LastInspect = Player
end)

surface.CreateFont( "rks_ko_text", {
	font = "Verdana",
	size = 20,
	weight = 1000,
	antialias = true,
})

hook.Add("HUDPaintBackground", "RKS_PaintHUD", function()
	if LocalPlayer().RKSBlindfolded then
		local W,H = ScrW(), ScrH()
		draw.RoundedBox( 0, 0, 0, W, H, Color( 0, 0, 0, 255 ) )
	elseif LocalPlayer().RKSKO then
		local W,H = ScrW(), ScrH()
		local TimeLeft = math.Round(LocalPlayer().RKSKOStart - CurTime())
		draw.RoundedBox( 0, 0, 0, W, H, Color( 0, 0, 0, 255 ) )
		draw.SimpleTextOutlined(string.format(RKS_GetLang("KnockedOut"), TimeLeft),"rks_ko_text",ScrW()/2,ScrH()/12,Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM,2,Color(0,0,0,255))
	end
end)

local KeyToCheck = RKidnapConfig.KEY
hook.Add("KeyPress", "RKS_DragKeyPress", function(Player, Key)
	if Key == KeyToCheck then
        if !Player:InVehicle() and !Player:GetNWBool("rks_restrained", false) then
			local Trace = {}
			Trace.start = Player:GetShootPos();
			Trace.endpos = Trace.start + Player:GetAimVector() * 100;
			Trace.filter = Player;

			local Tr = util.TraceLine(Trace);
			local TEnt = Tr.Entity
			if IsValid(TEnt) and TEnt:IsPlayer() and TEnt:GetNWBool("rks_restrained", false) and !TEnt:GetNWBool("RKS_Attatched", false) then
				local UnRestrainM = vgui.Create("DMenu")
				UnRestrainM:AddOption(RKS_GetLang("UnRestrain"), function() net.Start("rks_unrestrain") net.WriteEntity(TEnt) net.SendToServer() end)
				UnRestrainM:AddOption(RKS_GetLang("Drag"), function() net.Start("rks_drag") net.WriteEntity(TEnt) net.SendToServer() end)
				UnRestrainM:Open()

				UnRestrainM:SetPos(ScrW()/2,ScrH()/2)
			end
		end
    end
end)

surface.CreateFont( "rks_inspect_headline", {
	font = "Arial",
	size = 20,
	weight = 1000,
	antialias = true,
})

surface.CreateFont( "rks_inspect_information", {
	font = "Arial",
	size = 20,
	weight = 100,
	antialias = true,
})

surface.CreateFont( "rks_inspect_stealweapon", {
	font = "Arial",
	size = 15,
	weight = 1000,
	antialias = true,
})

surface.CreateFont( "rks_inspect_stealmoney", {
	font = "Arial",
	size = 14,
	weight = 1000,
	antialias = true,
})

surface.CreateFont( "rks_inspect_weaponname", {
	font = "Arial",
	size = 14,
	weight = 100,
	antialias = true,
})

local MainPanelColor = Color(255,255,255,200)
local HeaderColor = Color(50,50,50,255)
local SecondPanelColor = Color(215,215,220,255)
local ButtonColor = Color(50,50,50,255)
local ButtonColorHovering = Color(75,75,75,200)
local ButtonColorPressed = Color(150,150,150,200)
local ButtonOutline = Color(0,0,0,200)

local PANEL = {}

function PANEL:Init()
	self.Name = ""
	self.WID = 0

	self.WModel = vgui.Create( "ModelImage", self )
end

function PANEL:Paint(W,H)
	draw.SimpleText(self.Name, "rks_inspect_weaponname", W/2, 0, Color(0,0,0,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
end

function PANEL:PerformLayout(W,H)
	self.StealItem:SetPos(2.5,H-20)
	self.StealItem:SetSize(W-5,15)

	self.WModel:SetPos(2.5,10)
	self.WModel:SetSize(W-15,W-15)
end

function PANEL:SetInfo(Wep, ID)
	local SWEPTable = weapons.GetStored(Wep)
	if SWEPTable then
		if SWEPTable.WorldModel then
			self.WModel:SetModel(SWEPTable.WorldModel)
		end
		self.Name = SWEPTable.PrintName
	else
		self.Name = ""
	end
	self.WID = ID

	if self.StarWars then
		self.StealItem = vgui.Create("tbfy_button_starwars", self)
		self.StealItem:SetBoxColor(Color(0,0,0,100), Color(25,25,25,220), Color(100,100,100,255))
	else
		self.StealItem = vgui.Create("tbfy_button", self)
	end
	self.StealItem:SetBText("STEAL")
	self.StealItem:SetBFont("rks_inspect_stealweapon")
	self.StealItem.DoClick = function() if !RKidnapConfig.AllowStealingWeapons then LocalPlayer():ChatPrint("The server owner has disabled stealing weapons.") return end net.Start("rks_stealweapon") net.WriteEntity(LocalPlayer().LastInspect) net.WriteFloat(self.WID) net.SendToServer() self:Remove() end
end
vgui.Register("rks_weapon", PANEL)

local PANEL = {}

function PANEL:Init()
	self:ShowCloseButton(false)
	self:SetTitle("")
	self:MakePopup()

	self.StarWars = RKS_GetConf("RESTRAINS_StarWarsRestrains")

	self.Name = "INVALID"
	self.Job = "INVALID"
	self.SteamID = "INVALID"
	self.Wallet = 0
	self.WepItems = {}

	self.TopDPanel = vgui.Create("DPanel", self)
	self.TopDPanel.Paint = function(selfp, W,H)
		if self.StarWars then
			draw.RoundedBox(4, 5, 4, W-10, H-8, Color(21, 34, 56,255))
		else
			draw.RoundedBoxEx(8, 0, 0, W, H, HeaderColor, true, true, false, false)
		end
		draw.SimpleText("Inspecting: " .. self.Name, "rks_inspect_headline", W/2, H/2, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	self.InfoDPanel = vgui.Create("DPanel", self)
	self.InfoDPanel.Paint = function(selfp, W,H)
		if !self.StarWars then
			draw.RoundedBoxEx(8, 0, 0, W, H, SecondPanelColor, false, false, true, true)
		end
		local TW, TH = surface.GetTextSize("Name: ")
		draw.SimpleText("Name:", "rks_inspect_headline", 5, 10, Color(0,0,0,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		draw.SimpleText(self.Name, "rks_inspect_information", 5+TW, 10, Color(0,0,0,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		TW, TH = surface.GetTextSize("SteamID: ")
		draw.SimpleText("SteamID:", "rks_inspect_headline", 5, 25, Color(0,0,0,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		draw.SimpleText(self.SteamID, "rks_inspect_information", 5 + TW, 25, Color(0,0,0,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		TW, TH = surface.GetTextSize("Job: ")
		draw.SimpleText("Job:", "rks_inspect_headline", 5, 40, Color(0,0,0,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		draw.SimpleText(self.Job, "rks_inspect_information", 5 + TW, 40, Color(0,0,0,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		TW, TH = surface.GetTextSize("Wallet: ")
		draw.SimpleText("Wallet:", "rks_inspect_headline", 5, 55, Color(0,0,0,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		draw.SimpleText(self.Wallet, "rks_inspect_information", 5 + TW, 55, Color(0,0,0,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
	end

	self.WeaponHeader = vgui.Create("DPanel", self)
	self.WeaponHeader.Paint = function(selfp, W,H)
		if self.StarWars then
			draw.RoundedBox(4, 0, 0, W, H, Color(21, 34, 56,255))
		else
			draw.RoundedBoxEx(8, 0, 0, W, H, HeaderColor, true, true, false, false)
		end
		draw.SimpleText("Weapon List", "rks_inspect_headline", W/2, H/2, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	self.WeaponList = vgui.Create("DScrollPanel", self)
	self.WeaponList.Paint = function(selfp, W, H)
		if !self.StarWars then
			draw.RoundedBoxEx(4, 0, 0, W-15, H, SecondPanelColor, false, false, true, true)
		end
	end

	self.WeaponList.VBar.Paint = function() end
	self.WeaponList.VBar.btnUp.Paint = function() end
	self.WeaponList.VBar.btnDown.Paint = function() end
	self.WeaponList.VBar.btnGrip.Paint = function() end

	if DarkRP then
		local RandomMoney = RKS_GetConf("INSPECT_MoneyStealRandomAmount")

		if !RandomMoney then
			self.StealMoneyAmount = vgui.Create("DTextEntry", self.InfoDPanel)
			self.StealMoneyAmount:SetNumeric(true)
		end

		if self.StarWars then
			self.StealMoney = vgui.Create("tbfy_button_starwars", self.InfoDPanel)
			self.StealMoney:SetBoxColor(Color(0,0,0,100), Color(25,25,25,220), Color(100,100,100,255))
		else
			self.StealMoney = vgui.Create("tbfy_button", self.InfoDPanel)
		end
		self.StealMoney:SetBText("STEAL")
		self.StealMoney:SetBFont("rks_inspect_stealmoney")
		self.StealMoney.DoClick = function()
			if IsValid(LocalPlayer().LastInspect) then
				net.Start("rks_stealcash")
					net.WriteEntity(LocalPlayer().LastInspect)
					if !RandomMoney then
						net.WriteFloat(tonumber(self.StealMoneyAmount:GetValue()))
					end
				net.SendToServer()

				timer.Simple(1, function()
					if IsValid(self) then
						self.Wallet = DarkRP.formatMoney(LocalPlayer().LastInspect:getDarkRPVar("money"))
						self:PerformLayout()
					end
				end)
			end
		end
	end

	self.CloseButton = vgui.Create("tbfy_button", self)
	self.CloseButton:SetBText("X")
	if self.StarWars then
		self.CloseButton:SetBoxColor(Color(0,0,0,0), Color(0,0,0,0), Color(0,0,0,0))
	end
	self.CloseButton.DoClick = function() self:Remove() end
end

local function IsJobRanksLoadout(Player, Wep)
	local Rank = Player:GetJobRank()
	local Job = Player:Team()
	local WMatched = false

	if JobRanks and JobRanks[Job] then
		local JobTbl = JobRanks[Job]
		if JobTbl.ExtraLoadoutSingleRank and JobTbl.ExtraLoadoutSingleRank[Rank] then
			local SLoadout = JobTbl.ExtraLoadoutSingleRank[Rank]
			for k,v in pairs(SLoadout) do
				if v == Wep then
					WMatched = true
					break
				end
			end
		end
		if !WMatched and JobTbl.ExtraLoadout then
			local RLoadout = JobTbl.ExtraLoadout
			for k,v in pairs(RLoadout) do
				if v <= Rank and k == Wep then
					WMatched = true
					break
				end
			end
		end
	end
	return WMatched
end

function PANEL:SetupInfo(Player, WepTbl)
	self.Name = Player:Nick()
	self.SteamID = Player:SteamID()

	local jobTable = {}
	if DarkRP then
		self.Job = Player:getDarkRPVar("job")
		self.Wallet = DarkRP.formatMoney(Player:getDarkRPVar("money"))
		self:PerformLayout()
		jobTable = Player:getJobTable()
	end

	for k,v in pairs(WepTbl) do
		if !RKidnapConfig.BlackListedWeapons[v] then
			if RKidnapConfig.AllowStealingJobWeapons or (jobTable.weapons and !table.HasValue(jobTable.weapons, v) and (!JobRanksConfig or !IsJobRanksLoadout(Player, v))) then
				local Wep = vgui.Create("rks_weapon", self.WeaponList)
				Wep.StarWars = self.StarWars
				Wep:SetInfo(v, k)

				self.WepItems[k] = Wep
			end
		end
	end
end

local TopH = 25
local InfoH =75
local WeaponH = 25
local WeaponListH = 180
function PANEL:Paint(W,H)
	if self.StarWars then
		draw.RoundedBox(8, 0, 0, W, H, Color(21, 34, 56,255))
		surface.SetTexture(surface.GetTextureID("vgui/gradient_down"))
		surface.SetDrawColor(0, 142, 203, 200)
		surface.DrawTexturedRect(0,0,W,H)
		surface.SetDrawColor(0, 0, 0, 100)
		surface.DrawOutlinedRect(0,0,W,H,3)
		surface.SetDrawColor(0, 109, 105, 200)
		surface.DrawOutlinedRect(0,0,W,H,2)
	else
		draw.RoundedBoxEx(8, 0, TopH, W, H-TopH, MainPanelColor,false,false,true,true)
	end
end

local WepsPerLine = 4
local Width, Height, Padding = 300, 330, 5
function PANEL:PerformLayout()
	self:SetPos(ScrW()/2-Width/2, ScrH()/2-Height/2)
	self:SetSize(Width, TopH+InfoH+WeaponH+WeaponListH)

	self.TopDPanel:SetPos(0,0)
	self.TopDPanel:SetSize(Width,TopH)

	self.InfoDPanel:SetPos(Padding,TopH+Padding)
	self.InfoDPanel:SetSize(Width-Padding*2,InfoH-Padding*2)

	self.WeaponHeader:SetPos(Padding,TopH+InfoH)
	self.WeaponHeader:SetSize(Width-Padding*2,WeaponH)

	self.WeaponList:SetPos(Padding,TopH+InfoH+WeaponH)
	self.WeaponList:SetSize(Width+Padding, WeaponListH-Padding)

	local WAvailable = self.WeaponList:GetWide()-15
	local WepWSize = WAvailable/WepsPerLine

	local NumSlots = 0
	local CRow = 0
	for k,v in pairs(self.WepItems) do
		if IsValid(v) then
			if NumSlots >= WepsPerLine then
				NumSlots = 0
				CRow = CRow + 1
			end
			v:SetPos(WepWSize*(NumSlots),CRow*(WepWSize+15))
			v:SetSize(WepWSize,WepWSize+15)
			NumSlots = NumSlots + 1
		end
	end

	if self.StealMoney then
		local TW, TH = surface.GetTextSize("Wallet:  " .. self.Wallet)
		if !RKS_GetConf("INSPECT_MoneyStealRandomAmount") then
			if self.StealMoneyAmount then
				self.StealMoneyAmount:SetPos(TW+37, 49)
				self.StealMoneyAmount:SetSize(45,13)
			end

			self.StealMoney:SetPos(TW+84, 49)
			self.StealMoney:SetSize(45,13)
		else
			self.StealMoney:SetPos(TW+37, 49)
			self.StealMoney:SetSize(45,13)
		end
	end

	self.CloseButton:SetPos(Width-TopH,TopH/2-9)
	self.CloseButton:SetSize(20, 20)
end
vgui.Register("rks_inspect_menu", PANEL, "DFrame")
