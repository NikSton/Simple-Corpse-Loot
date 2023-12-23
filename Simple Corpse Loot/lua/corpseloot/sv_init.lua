util.AddNetworkString("Jelux_Loot")
util.AddNetworkString("Jelux_GiveWeapon")
util.AddNetworkString("Jelux_SetModel")
util.AddNetworkString("Jelux_LootChat")

local pairs = pairs

hook.Add("PlayerDeath", "JeluxLootDeath", function(ply, i, a)
    if IsValid(ply:GetRagdollEntity()) then
        local deadRag = ply:GetRagdollEntity()
        deadRag:Remove()
    end

    local ragdoll = ply.ragdoll
    local ragdoll = ents.Create("prop_ragdoll")
    ragdoll:SetPos(ply:GetPos())
    ragdoll:SetAngles(Angle(0, ply:GetAngles().Yaw, 0))
    ragdoll:SetModel(ply:GetModel())
    ragdoll:SetOwner(ply)
    ragdoll:Spawn()
    ragdoll:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    ragdoll:Activate()
    ragdoll:SetVelocity(ply:GetVelocity())
    ragdoll.Nick = ply:Nick()

    timer.Simple(90, function()
        if IsValid(ragdoll) then
            ragdoll:Remove()
        end
    end)

    ragdoll.Weapons = {}

    for k, v in pairs(ply:GetWeapons()) do
        local class = v:GetClass()
        if CorpseLoot.Config.BlackList[class] then continue end
        table.insert(ragdoll.Weapons, {v:GetModel(), class})
    end

    model = ply:GetModel()
end)

local LootCache = {}
local LootProgress = {}

timer.Create("LootProgress", 0.1, 0, function()
	if table.Count(LootProgress) == 0 then return end

	for ply, info in pairs(LootProgress) do
		if !IsValid(ply) then
			LootProgress[ply] = nil
			continue
		end

		local trace = ply:GetEyeTrace()

		if info.end_time <= CurTime() + 0.5 then

			LootProgress[ply] = nil

			LootCache[ply] = {
		        Weapons = info.ragdoll.Weapons,
		        Time = CurTime(),
		        Model = info.ragdoll:GetModel()
		    }

			net.Start("Jelux_Loot")
			net.WriteBool(true)
			net.WriteTable(LootCache[ply].Weapons)
			net.WriteString(LootCache[ply].Model)
			net.WriteString(info.ragdoll.Nick)
			net.Send(ply)

			info.ragdoll:Remove()

		elseif !IsValid(info.ragdoll) or trace.Entity != info.ragdoll or ply:GetPos():Distance(trace.HitPos) > 70 then

			LootProgress[ply] = nil
			net.Start("Jelux_Loot")
			net.WriteBool(false)
			net.WriteBool(false)
			net.Send(ply)
		end
	end
end)

function CorpseLoot:SendMessage(ply, msgtext)
    net.Start("Jelux_LootChat")
    net.WriteUInt(msgtext, 5)
    net.Send(ply)
end

local function LootBase(ply, key)
	if key != CorpseLoot.Config.Button_Loot then return end

    local tr = ply:GetEyeTrace()
    local ragdoll = tr.Entity

    if !IsValid(ragdoll) or ragdoll:GetClass() != "prop_ragdoll" then return end
    if ply:GetPos():Distance(tr.HitPos) > 70 then return end

    for k, v in pairs(LootProgress) do
    	if v.ragdoll == ragdoll then
           CorpseLoot:SendMessage(ply, 1)
    		return
    	end
    end

    LootProgress[ply] = {
    	ragdoll = ragdoll,
    	end_time = CurTime() + 10,
    }

    net.Start("Jelux_Loot")
    net.WriteBool(false)
    net.WriteBool(true)
    net.WriteUInt(CurTime(), 20)
    net.WriteUInt(LootProgress[ply].end_time, 20)
    net.Send(ply)
end
hook.Add("KeyPress", "JeluxLootFunction", LootBase)

local DragInfo = {}
hook.Add("Think", "Jelux_Drag_Handler", function()
	for ply, phys in pairs(DragInfo) do
		if !IsValid(phys) or !IsValid(ply) then
			DragInfo[ply] = nil
			continue
		end

		local pos = phys:GetPos()
		phys:ApplyForceOffset(((ply:EyePos() + ply:EyeAngles():Forward() * 40) - pos) * CorpseLoot.Config.DragForce, pos)
	end
end)

hook.Add("PlayerButtonUp", "JeluxLootFunction_Drag", function(ply, btn)
	if btn == CorpseLoot.Config.Button_Drag and DragInfo[ply] then
		DragInfo[ply] = nil
	end
end)

hook.Add("PlayerButtonDown", "JeluxLootFunction_Drag", function(ply, btn)
	if btn != CorpseLoot.Config.Button_Drag then return end

	local trace = ply:GetEyeTrace()
	if !IsValid(trace.Entity) or trace.Entity:GetClass() != "prop_ragdoll" or trace.HitPos:Distance(ply:GetPos()) > 70 then
		return
	end

	local phys = trace.Entity:GetPhysicsObjectNum(trace.PhysicsBone)
	if !IsValid(phys) then return end
	DragInfo[ply] = phys
end)

net.Receive("Jelux_GiveWeapon", function(len, ply)
    local weapon = net.ReadString()
    local Cache = LootCache[ply]
    if not Cache then return end
    if Cache.Time > CurTime() - 120 then
        for k, v in pairs(Cache.Weapons) do
            if v[2] == weapon then
                ply:Give(weapon)
                LootCache[ply].Weapons[k] = nil
                return
            end
        end
        CorpseLoot:SendMessage(ply, 2)
    else
        LootCache[ply] = nil
    end
end)

hook.Add("PlayerDisconnected", "JeluxLoot", function(ply)
    LootCache[ply] = nil
end)

net.Receive("Jelux_SetModel", function(len, ply)
    local Cache = LootCache[ply]
    if not Cache then return end

    if Cache.Picked then
       CorpseLoot:SendMessage(ply, 3)
        return
    end

    if Cache.Time > CurTime() - 120 then
        ply:SetNWBool("ClothBool", true)
        ply.upclothes = ply:GetModel()
        ply:SetModel(Cache.Model)
        CorpseLoot:SendMessage(ply, 4)
        LootCache[ply].Picked = true
    else
        LootCache[ply] = nil
    end
end)

hook.Add("PlayerSay", "Jelux_DropCloth", function(ply, text)
if text == CorpseLoot.Config.DropCloth then
	if ply:GetNWBool("ClothBool") and ply.upclothes then
        ply:SetNWBool("ClothBool", false)
        ply:SetModel(ply.upclothes)
        CorpseLoot:SendMessage(ply, 5)
    end
		 return ""
	 end
end)

hook.Add("PlayerDeath", "JeluxUnClothes", function(ply)
    ply:SetNWBool("ClothBool", false)
    ply.upclothes = nil
end)

hook.Add("OnPlayerChangedTeam", "JeluxUnClothesTeam", function(ply)
    ply:SetNWBool("ClothBool", false)
    ply.upclothes = nil
end)