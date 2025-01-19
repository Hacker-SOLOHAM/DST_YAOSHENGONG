local brain = require "brains/er_monster_brain"

local function NormalRetarget(inst)
	return FindEntity(inst,SpringCombatMod(8),function(guy)
            return inst.components.combat:CanTarget(guy)
        end,
        {"_combat","_health"},{"wall","INLIMBO","rg_kulou","laoluselfbaby"}
    )
end

local function keeptargetfn(inst, target)
   return target ~= nil and target.components.combat ~= nil and target.components.health ~= nil and not target.components.health:IsDead()
end

--装备武器
local function EquipWeapon(inst)
    if inst.components.inventory ~= nil and not inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
        local weapon =  SpawnPrefab("batbat")
		if weapon ~= nil then
			if weapon.components.weapon ~= nil then
				weapon.components.weapon.attackwear = 0
			end
			if weapon.components.inventoryitem ~= nil then
				weapon.components.inventoryitem:SetOnDroppedFn(inst.Remove)			
			end
			weapon.persists = false    
			inst.components.inventory:Equip(weapon)
		end
    end
end

SetSharedLootTable("rg_kulou001",{
    {"boneshard",             1},
    {"boneshard",             1},
    {"boneshard",             1},
    {"er_safekey", 1},
})
SetSharedLootTable("rg_kulou002",{
	{"boneshard",		1},
	{"er_sundries012",	1},
	{"er_sundries036",	1},
	{"er_ore001",		1},
})

local maxhealthli = {5000000,4000000}	--最大生命
local damageli = {1200,1000}			--默认伤害
local runspeedli = {16,12}				--移动速度
local defenseli = {0.9,0.9}				--防御力
local regenli = {0.0002,0.0002}			--回血百分比
local periodli = {0.8,0.8}				--攻击频率
local aurali = {-1.5,-1}				--降san光环

--骷髅骑士
AddPrefabPostInit("rg_kulou001", function(inst)
	local maxhealth = maxhealthli[1]
	inst.rg_mount = true
	inst.branch = 0		--下属个数
	inst:AddComponent("inspectable")
	inst.components.inspectable:SetDescription("实力强劲的骷髅骑士!!!")

	inst:AddComponent("locomotor")
	inst.components.locomotor.runspeed = runspeedli[1]

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(maxhealth)
	inst.components.health:StartRegen(maxhealth*regenli[1], 1)
	
	inst:AddComponent("sanityaura")
	inst.components.sanityaura.aura = aurali[1]
	
	inst:AddComponent("inventory")
	inst.components.inventory:DisableDropOnDeath()

	inst:AddComponent("combat")
	inst.components.combat:SetRange(2)
	inst.components.combat:SetDefaultDamage(damageli[1])
	inst.components.combat:SetAttackPeriod(periodli[1])
	inst.components.combat:SetKeepTargetFunction(keeptargetfn)
	inst.components.combat:SetRetargetFunction(1, NormalRetarget)
	
	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("rg_kulou001")
	
	inst:SetBrain(brain)
	inst:SetStateGraph("SGrg_kulou")
	
	inst:DoPeriodicTask(30, function()
		if inst.branch < 3 then
			inst.branch = inst.branch + 1	--增加随从战士
			local health = inst.components.health
			health.newabsorb = (health.newabsorb or 0) + 0.1
			
			local x,y,z = inst.Transform:GetWorldPosition()
			local monster = SpawnPrefab("rg_kulou002")
			local pos = inst:GetPosition()
			local offset = FindValidPositionByFan(2 * PI * math.random(), 6, 24, function(offsets)
				local pt = Vector3(x + offsets.x, 0, z + offsets.z)
				return TheWorld.Map:IsPassableAtPoint(pt:Get())
					and not TheWorld.Map:IsPointNearHole(pt)
			end)
			if offset ~= nil then
				pos = pos + offset
			end
			monster.Transform:SetPosition(pos:Get())
			--死亡扣除骑士防御力
			monster:ListenForEvent("death", function()
				if health and not health:IsDead() then
					inst.branch = inst.branch - 1
					health.newabsorb = health.newabsorb - 0.1
				end
			end)
		end
	end)

	inst.persists = false --不保存
end)

--骷髅战士
AddPrefabPostInit("rg_kulou002", function(inst)
	local maxhealth = maxhealthli[2]
	inst.rg_mount = false
	inst:AddComponent("inspectable")
	inst.components.inspectable:SetDescription("实力强劲的骷髅战士!!!")

	inst:AddComponent("locomotor")
	inst.components.locomotor.runspeed = runspeedli[2]

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(maxhealth)
	inst.components.health:StartRegen(maxhealth*regenli[2], 1)
	
	inst:AddComponent("sanityaura")
	inst.components.sanityaura.aura = aurali[2]

	inst:AddComponent("inventory")
	inst.components.inventory:DisableDropOnDeath()
	
	inst:AddComponent("combat")
	inst.components.combat:SetRange(2)
	inst.components.combat:SetDefaultDamage(damageli[2])
	inst.components.combat:SetAttackPeriod(periodli[2])
	inst.components.combat:SetKeepTargetFunction(keeptargetfn)
	inst.components.combat:SetRetargetFunction(1, NormalRetarget)
	
	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("rg_kulou002")
	
	inst:SetBrain(brain)
	inst:SetStateGraph("SGrg_kulou")

	EquipWeapon(inst)

	inst.persists = false
end)