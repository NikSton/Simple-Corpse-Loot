

local create_font = surface.CreateFont
create_font("LootMenu_Large", {
  font = "Tahoma",
  extended = false,
  size = 30,
  weight = 1000,
  antialias = true,
})

create_font("LootMenu_Small", {
  font = "Tahoma",
  extended = false,
  size = 23,
  weight = 1000,
  antialias = true,
})

local function NikBox(x, y, w, h, color)
	local surface_color = surface.SetDrawColor
	local rect = surface.DrawRect
    surface_color(color)
    rect(x, y, w, h)
end

local function NikRect(x, y, w, h, t)
	if not t then t = 1 end
	local rect = surface.DrawRect
	rect(x, y, w, t)
	rect(x, y + (h - t), w, t)
	rect(x, y, t, h)
	rect(x + (w - t), y, t, h)
end

local function NikDrawOutlines(x, y, w, h, col, thickness)
	local surface_color = surface.SetDrawColor
	surface_color(col)
	NikRect(x, y, w, h, thickness)
end

local NikText = draw.SimpleText

local dots = ""
local function Dots()
	local dots = ""
	for i = 1, (CurTime() * 4) % 4 do
		dots = dots .. "."
	end
	return dots
end

local Progress = false

local function LootHud()
	if Progress then
		if Progress.end_time <= CurTime() then
			Progress = false
			return
		end

	    local x, y = (ScrW() / 2) - 150, (ScrH() / 2) - 25
        local w, h  = 300, 50
        local frac = math.Clamp((CurTime() - Progress.start_time) / (Progress.end_time - Progress.start_time), 0, 1) 
        local color = Color(255 - (frac * 255), frac * 255, 0, 255)

        NikBox(x, y, w, h, Color(30,30,30))
        NikBox(x + 5, y + 5, math.Clamp((w * frac) - 10, 3, w), h - 10, color)
        NikDrawOutlines(x, y, w, h, Color(255,255,255))
		NikText("Looting" .. Dots(), "LootMenu_Large", ScrW()/2, ScrH()/2, white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end
hook.Add("HUDPaint", "Jelux_LootHud", LootHud)

net.Receive("Jelux_Loot", function()
	if net.ReadBool() then
		local start = CurTime()
		local tableweapons = net.ReadTable()
		local model = net.ReadString()
		local nick = net.ReadString()
		local x, y = ScrW(), ScrH()

		local frame = vgui.Create("DFrame")
		frame:SetSize(x * 0.3, y * 0.5)
		frame:MakePopup()
		frame:SetTitle("")
		frame:DockPadding(2, 24, 2, 2)
		frame:SetPos(x / 2 - frame:GetWide() / 2, y / 2 - frame:GetTall() / 2)
		frame:ShowCloseButton(false)
		frame.Think = function(self)
			if start < CurTime() - 120 then
				self:Remove()
			end
		end

		frame.Paint = function(s, w, h)
			NikBox(0, 0, w, h, Color(30, 30, 30))
			NikBox(0, 24, w, 2, Color(255, 255, 255))
			NikDrawOutlines(0, 0, w, h, Color(255,255,255))
			NikText("Player corpse: " .. nick, "LootMenu_Small", 1, 24/2, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end

		local closeButton = vgui.Create("DButton", frame)
		closeButton:SetPos(frame:GetWide() - 24, 2)
		closeButton:SetSize(22, 22)
		closeButton:SetText("")
		closeButton.Paint = function(self, w, h)
			NikBox(0, 0, w, h, self:IsDown() and Color(150, 50, 50) or self:IsHovered() and Color(200, 50, 50) or Color(255, 50, 50))
			NikText("X", "LootMenu_Small", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		closeButton.DoClick = function()
			frame:Remove()
		end

		local leftPanel = vgui.Create("DPanel", frame)
		leftPanel:Dock(LEFT)
		leftPanel:SetWide(frame:GetWide() * 0.3)
		leftPanel:DockPadding(0, 0, 2, 0)
		leftPanel.Paint = function(s, w, h)
			NikBox(w-2, 0, 2, h, Color(255, 255, 255))
		end

		local rightPanel = vgui.Create("DScrollPanel", frame)
		rightPanel:Dock(FILL)
		rightPanel.Paint = function(s, w, h)
			if table.Count(tableweapons) == 0 then
				NikText("Empty :(", "LootMenu_Small", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		end

		local lbl = vgui.Create("DLabel", rightPanel)
		lbl:SetText("Weapons")
		lbl:SetTextColor(Color(255, 255, 255))
		lbl:SetContentAlignment(5)
		lbl:SetFont("LootMenu_Large")
		lbl:SizeToContentsY(10)
		lbl:Dock(TOP)
		lbl.Paint = function(s, w, h)
			NikBox(0, h-2, w, 2, Color(255, 255, 255))
		end

		for k, v in ipairs(tableweapons) do
			local WepInfo = ""
			local WepTable = weapons.GetStored(v[2])
			if (WepTable != nil) then
				WepInfo = weapons.GetStored(v[2]).PrintName
			else
				WepInfo = language.GetPhrase(v[2])
			end

			local button_weapon = vgui.Create("DButton", rightPanel)
			button_weapon:SetTall(35)
			button_weapon:Dock(TOP)
			button_weapon:SetText("")
			button_weapon:DockMargin(4, 5, 4, 0)
			button_weapon.Paint = function(s, w, h)
				NikBox(0, 0, w, h, s:IsDown() and Color(50, 50, 50) or s:IsHovered() and Color(75, 75, 75) or Color(30, 30, 30))
				NikDrawOutlines(0, 0, w, h, Color(255,255,255))
				NikText(WepInfo, "LootMenu_Small", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end

			button_weapon.DoClick = function()
				tableweapons[k] = nil
				button_weapon:Remove()
				net.Start("Jelux_GiveWeapon")
		        net.WriteString(v[2])
				net.SendToServer()
				surface.PlaySound("buttons/button15.wav")
			end
		end

		local modelPanel = vgui.Create("DModelPanel", leftPanel)
		modelPanel:SetFOV(10)
		modelPanel:Dock(FILL)
		modelPanel:SetModel(model)
		modelPanel:SetMouseInputEnabled(false)
		modelPanel.DrawModel = function(s)
			s.Entity:DrawModel()
			s.Entity:SetEyeTarget(gui.ScreenToVector(gui.MousePos()))
		end

		modelPanel.LayoutEntity = function(s)
			s:RunAnimation()
		end

		local hz = 60

		if IsValid(modelPanel.Entity) then
			local headBone = modelPanel.Entity:LookupBone("ValveBiped.Bip01_Head1")
			if headBone then
				hz = modelPanel.Entity:GetBonePosition(headBone).z
			end
		end

		if hz < 5 then
			hz = 40
		end
		hz = hz * 0.6

		modelPanel:SetCamPos(Vector(175, 0, hz))
		modelPanel:SetLookAt(Vector(0, 0, hz))

		local button_clothes = vgui.Create("DButton", leftPanel)
		button_clothes:Dock(BOTTOM)
		button_clothes:SetTall(35)
		button_clothes:SetText("")
		button_clothes.DoClick = function()
			net.Start("Jelux_SetModel")
			net.SendToServer()
			surface.PlaySound("buttons/button15.wav")
		end

		button_clothes.Paint = function(s, w, h)
			NikBox(0, 0, w, h, s:IsDown() and Color(50, 50, 50) or s:IsHovered() and Color(75, 75, 75) or Color(30, 30, 30))
			NikBox(0, 0, w, 2, Color(255, 255, 255))
			NikText("Take clothes", "LootMenu_Small", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

	elseif net.ReadBool() then
		Progress = {
			start_time = net.ReadUInt(20),
			end_time = net.ReadUInt(20)
		}
	else
		Progress = false
	end
end)

net.Receive("Jelux_LootChat", function()
    local msgtext = net.ReadUInt(5)
    local message = CorpseLoot.Config.Messages[msgtext]
    if not message then return end
    local prefix = CorpseLoot.Config.Messages["Prefix"]
    local msg = {}
    table.Add(msg, prefix)
    table.Add(msg, message)
    chat.AddText(unpack(msg))
end)