if not file.Exists("pcasino_data", "DATA") then
	file.CreateDir("pcasino_data")
	file.CreateDir("pcasino_data/ui")
end	

PerfectCasino.Icons = {}
PerfectCasino.IconsList = {} -- This is a list of all the icons. It is used in some UI elements to allow players to cycle through them all.
function PerfectCasino.Core.AddIcon(id, name, url, internal)
	PerfectCasino.Icons[id] = {name = name, url = url, internal = internal, mat = Material(id..".png")}

	table.insert(PerfectCasino.IconsList, id)
end

PerfectCasino.Core.AddIcon("anything", "Anything", "pcasino/anything.png", true)
PerfectCasino.Core.AddIcon("bell", "Bell", "pcasino/bell.png", true)
PerfectCasino.Core.AddIcon("berry", "Strawberry", "pcasino/berry.png", true)
PerfectCasino.Core.AddIcon("cherry", "Cherry", "pcasino/cherry.png", true)
PerfectCasino.Core.AddIcon("clover", "Clover", "pcasino/clover.png", true)
PerfectCasino.Core.AddIcon("diamond", "Diamond", "pcasino/diamond.png", true)
PerfectCasino.Core.AddIcon("dollar", "Dollar", "pcasino/dollar.png", true)
PerfectCasino.Core.AddIcon("melon", "Watermelon", "pcasino/melon.png", true)
PerfectCasino.Core.AddIcon("seven", "Seven", "pcasino/seven.png", true)
PerfectCasino.Core.AddIcon("gold", "Gold Bars", "pcasino/gold.png", true)
PerfectCasino.Core.AddIcon("coins", "Coins", "pcasino/coins.png", true)
PerfectCasino.Core.AddIcon("emerald", "Emerald", "pcasino/emerald.png", true)
PerfectCasino.Core.AddIcon("bag", "Money Bag", "pcasino/bag.png", true)
PerfectCasino.Core.AddIcon("bar", "Gold Bar", "pcasino/bar.png", true)
PerfectCasino.Core.AddIcon("coin", "Coin", "pcasino/coin.png", true)
PerfectCasino.Core.AddIcon("vault", "Vault", "pcasino/vault.png", true)
PerfectCasino.Core.AddIcon("chest", "Treasure Chest", "pcasino/chest.png", true)
PerfectCasino.Core.AddIcon("mystery_1", "Mystery Wheel 1", "pcasino/mystery_1.png", true)
PerfectCasino.Core.AddIcon("mystery_2", "Mystery Wheel 2", "pcasino/mystery_2.png", true)
PerfectCasino.Core.AddIcon("mystery_3", "Mystery Wheel 3", "pcasino/mystery_3.png", true)
PerfectCasino.Core.AddIcon("dolla", "Dolla", "pcasino/dolla.png", true)

function PerfectCasino.Core.LoadIconsFromURL()
	for k, v in pairs(PerfectCasino.Icons) do
		if (v.internal) then continue end

		print("[pCasino]", "Checking icon", k)
		if file.Exists( "pcasino_data/ui/"..k..".png", "DATA" ) then print("	", "Found") continue end

		print("	", "Attempting to download from", v.url)
		http.Fetch(v.url, function( body, len, headers, code )
			file.Write("pcasino_data/ui/"..k..".png", body)
			v.mat = Material("data/pcasino_data/ui/"..k..".png")

			print("[pCasino]", k, "Download is complete. The image can be found at", "pcasino_data/ui/"..k..".png")
		end)
	end
end

function PerfectCasino.Core.LoadIcons()
	for k, v in pairs(PerfectCasino.Icons) do
		if (!v.internal) then continue end;

		v.mat = Material(v.url)
	end
end

hook.Add("HUDPaint", "pVault:LoadIcons", function()
	hook.Remove("HUDPaint", "pVault:LoadIcons")

	PerfectCasino.Core.LoadIconsFromURL()
	PerfectCasino.Core.LoadIcons()
end)

-- Seat text
local draw_simpletext = draw.SimpleText
hook.Add("HUDPaint", "pVault:ChairLeave", function()
	local myChair = LocalPlayer():GetVehicle()
	if (not IsValid(myChair)) or (not IsValid(myChair:GetParent())) then return end
	if not (myChair:GetParent():GetClass() == "pcasino_chair") then return end

	draw_simpletext(PerfectCasino.Translation.UI.LeaveSeat, "pCasino.Entity.Bid", ScrW()*0.5, ScrH(), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
end)

-- Free spin received
net.Receive("pCasino:FreeSpin", function()
	PerfectCasino.Spins = net.ReadUInt(6)
end)



-- Improved toolgun
concommand.Add("pcasino_clone", function()
	if not PerfectCasino.Core.Access(LocalPlayer()) then return end
	local entity = LocalPlayer():GetEyeTrace().Entity

	if not string.match(entity:GetClass(), "pcasino") then return end
	if not entity.data then return end

	PerfectCasino.UI.CurrentSettings.Entity = entity:GetClass()
	PerfectCasino.UI.CurrentSettings.Settings = table.Copy(entity.data)

	if IsValid(PerfectCasino.UI.ConfigMenu) then
		PerfectCasino.UI.ConfigMenu:Close()
	end

	PerfectCasino.UI.Config()

	local comboBox = PerfectCasino.UI.ConfigMenu.entitySelectBox
	local key
	for k, v in pairs(comboBox.Choices) do
		if not (v == PerfectCasino.Translation.Entities[entity:GetClass()]) then continue end

		key = k
	end

	if not key then return end
	comboBox:ChooseOptionID(key)

	PerfectCasino.UI.ConfigMenu:Hide()
end)

-- Used for debugging
concommand.Add("pcasino_print_data", function()
	if not PerfectCasino.Core.Access(LocalPlayer()) then return end
	local entity = LocalPlayer():GetEyeTrace().Entity

	if not string.match(entity:GetClass(), "pcasino") then return end
	if not entity.data then return end

	PrintTable(entity.data)
end)