local brain = require "brains/er_boss_brain"

--受击定向目标
local function locktargrt(inst,data)
	if data then
		local combat = inst.components.combat
		if combat.target == nil then
			if data.attacker and data.attacker:HasTag("player") then
				combat:SetTarget(data.attacker)
				TheNet:Announce(data.attacker:GetDisplayName().."成为了"..STRINGS.NAMES[string.upper(inst.prefab)].."的狩猎目标!")
			end
		end
	end
end

--自定义掉落
SetSharedLootTable("er_boss001", {
	{"er_sundries036",1},	--武器强化石
	{"er_sundries036",1},	--武器强化石
	{"er_sundries037",1},	--护甲强化石
	{"er_sundries037",1},	--护甲强化石
	{"er_sundries014",0.6},	--紫漓花
	{"er_sundries017",0.5},	--火龙
	{"lucky_goldnugget",0.1},	--元宝
	{"er_sundries029",0.1},	--鎏金卡
})
SetSharedLootTable("er_boss002", {
	{"er_sundries036",1},	--武器强化石
	{"er_sundries036",1},	--武器强化石
	{"er_sundries037",1},	--护甲强化石
	{"er_sundries037",1},	--护甲强化石
	{"er_sundries015",0.6},	--玲珑玉
	{"er_sundries017",0.5},	--火龙
	{"er_sundries008",0.5},	--大金币袋
	{"er_sundries029",0.5},	--鎏金卡
})
SetSharedLootTable("er_boss003", {
	{"er_sundries036",1},	--武器强化石
	{"er_sundries036",1},	--武器强化石
	{"er_sundries037",1},	--护甲强化石
	{"er_sundries037",1},	--护甲强化石
	{"er_sundries016",0.6},	--炎阳纹章
	{"er_sundries017",0.5},	--火龙
	{"rg_giftbag001",0.5},	--十万金币
	{"er_sundries030",0.5},	--紫金卡
})


local function RetargetFn(inst, target)
    local combat = inst.components.combat
    if combat.target and not combat.target.components.health:IsDead() then
        if GetTime() - inst.skcd1 > 5 and inst.skli1 then
            inst.mode = 1
            combat.attackrange = 8
        elseif GetTime() - inst.skcd2 > 15 and inst.skli2 then
            inst.mode = 2
            combat.attackrange = 5
        elseif GetTime() - inst.skcd3 > 30 and inst.skli3 then
            inst.mode = 3
            combat.attackrange = 6
        else
            inst.mode = nil
            combat:SetRange(2,2.5)
        end
    end
end

local function LaunchItem(inst, target, item)
	if item.Physics ~= nil then
		local x, y, z = target.Transform:GetWorldPosition()
		item.Physics:Teleport(x, .1, z)
		local vel = (target:GetPosition() - inst:GetPosition()):GetNormalized()
		local speed = 5 + math.random() * 2
		local angle = math.atan2(vel.z, vel.x) + (math.random() * 20 - 10) * DEGREES
		item.Physics:SetVel(math.cos(angle) * speed, 10, -math.sin(angle) * speed)
	end
end

local function onattack(inst,data)
	local target = data.target
	if target and target:HasTag("player") then
		if math.random() < .25 then
			target:PushEvent("knockback", {knocker = inst, radius = 5})
--[[			local item = target.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
			if item then
				--击中玩家掉落武器
				target.components.inventory:DropItem(item)
				LaunchItem(inst, target, item)
			end]]
		end
	end
end

local maxhealthli = {100000,600000,1000000}	--最大生命
local damageli = {400,600,800}				--默认伤害
local runspeedli = {16,18,20}				--移动速度
local defenseli = {0.7,0.8,0.9}				--防御力
local regenli = {0.003,0.004,0.005}			--回血百分比
local periodli = {1,0.8,0.5}				--攻击频率
local rageli = {0.3,0.4,0.6}				--狂暴触发百分比
local aurali = {-1,-1.5,-2}					--降san光环
--local removeli = {2000,2000,2000}			--移除时间

--深渊恐惧
AddPrefabPostInit("er_boss001", function(inst)
	local maxhealth = maxhealthli[1]
	inst.skcd1 = 0
	inst.skcd2 = 0
	inst.skcd3 = 0
	inst.skli1 = {"skill1","skill2"}
	inst.damage = damageli[1]
	inst.uptarget = "er_boss002"

	inst:AddComponent("locomotor")
	inst.components.locomotor.runspeed = runspeedli[1]
	inst:SetStateGraph("SGer_boss")

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(maxhealth)
	inst.components.health:SetAbsorptionAmount(defenseli[1])
	inst.components.health:StartRegen(maxhealth*regenli[1], 1)

	inst:AddComponent("talker")
	inst:AddComponent("inventory")
	inst.components.inventory:DisableDropOnDeath()

	local weapon = SpawnPrefab("weapon103")
	weapon.components.weapon:SetDamage(inst.damage)
	weapon.components.weapon:SetRange(2,2.5)
	weapon.components.inventoryitem:SetOnDroppedFn(inst.Remove)
	inst.components.inventory:Equip(weapon)

	inst:AddComponent("sanityaura")
	inst.components.sanityaura.aura = aurali[1]

	inst:AddComponent("combat")
	inst.components.combat:SetAttackPeriod(periodli[1])
	inst.components.combat:SetRange(2,2.5)
	inst.components.combat:SetAreaDamage(3, 1)
    inst.components.combat:SetRetargetFunction(1, RetargetFn)

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("er_boss001")

	inst:AddComponent("inspectable")
	inst.components.inspectable:SetDescription("毁灭一切的深渊恐惧!!!")

	inst:ListenForEvent("onhitother", onattack)
	inst:ListenForEvent("attacked", locktargrt)
	inst:ListenForEvent("healthdelta", function(inst, data)
		local newpercent = data.newpercent
		if newpercent and newpercent < rageli[1] then
			if not inst.awaken then
				inst.awaken = true
				inst.damage = inst.damage * 1.2
				local newdefense = defenseli[1] + 0.1
				weapon.components.weapon:SetDamage(inst.damage)
				inst.components.health:SetAbsorptionAmount(newdefense)
				TheNet:Announce("深渊恐惧开始暴走!防御力提升至".. newdefense*100 .."%,攻击力提升20%!")
			end
		end
	end)
	--inst:ListenForEvent("death", function(inst)end)

	inst:DoPeriodicTask(10, function()
		local x, y, z = inst.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x, 0, z, 20, {"player"})
		local rank = 1 + #ents * 0.1
		weapon.components.weapon:SetDamage(inst.damage * rank)
		if rank > 1 then
			TheNet:Announce("当前参与人数为"..#ents..",深渊恐惧攻击力变更为".. rank*100 .."%!")
		end
	end)

	-- inst:DoTaskInTime(removeli[1], function()
		-- inst:Remove()
		-- TheNet:Announce("深渊恐惧脱离了该世界!")
	-- end)

	inst:SetBrain(brain)
end)

--虚空恐惧
AddPrefabPostInit("er_boss002", function(inst)
	local maxhealth = maxhealthli[2]
	inst.skcd1 = 0
	inst.skcd2 = 0
	inst.skcd3 = 0
	inst.skli1 = {"skill1","skill2"}
	inst.skli2 = {"skill3","skill4"}
	inst.damage = damageli[2]
	inst.uptarget = "er_boss003"

	inst:AddComponent("locomotor")
	inst.components.locomotor.runspeed = runspeedli[2]
	inst:SetStateGraph("SGer_boss")

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(maxhealth)
	inst.components.health:SetAbsorptionAmount(defenseli[2])
	inst.components.health:StartRegen(maxhealth*regenli[2], 1)

	inst:AddComponent("talker")
	inst:AddComponent("inventory")
	inst.components.inventory:DisableDropOnDeath()

	local weapon = SpawnPrefab("weapon103")
	weapon.components.weapon:SetDamage(inst.damage)
	weapon.components.weapon:SetRange(2,2.5)
	weapon.components.inventoryitem:SetOnDroppedFn(inst.Remove)
	inst.components.inventory:Equip(weapon)

	inst:AddComponent("sanityaura")
	inst.components.sanityaura.aura = aurali[2]

	inst:AddComponent("combat")
	inst.components.combat:SetAttackPeriod(periodli[2])
	inst.components.combat:SetRange(2,2.5)
	inst.components.combat:SetAreaDamage(3, 1)
    inst.components.combat:SetRetargetFunction(1, RetargetFn)

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("er_boss002")

	inst:AddComponent("inspectable")
	inst.components.inspectable:SetDescription("毁灭一切的虚空恐惧!!!")

	inst:ListenForEvent("onhitother", onattack)
	inst:ListenForEvent("attacked", locktargrt)
	inst:ListenForEvent("healthdelta", function(inst, data)
		local newpercent = data.newpercent
		if newpercent and newpercent < rageli[2] then
			if not inst.awaken then
				inst.awaken = true
				inst.damage = inst.damage * 1.35
				local newdefense = defenseli[2] + 0.1
				weapon.components.weapon:SetDamage(inst.damage)
				inst.components.health:SetAbsorptionAmount(newdefense)
				TheNet:Announce("虚空恐惧开始暴走!防御力提升至".. newdefense*100 .."%,攻击力提升35%!")
			end
		end
	end)
	-- inst:ListenForEvent("death", function(inst)end)

	inst:DoPeriodicTask(10, function()
		local x, y, z = inst.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x, 0, z, 20, {"player"})
		local rank = 1 + #ents * 0.2
		weapon.components.weapon:SetDamage(inst.damage * rank)
		if rank > 1 then
			TheNet:Announce("当前参与人数为"..#ents..",虚空恐惧攻击力变更为".. rank*100 .."%!")
		end
	end)

	-- inst:DoTaskInTime(removeli[2], function()
		-- TheNet:Announce("虚空恐惧脱离了该世界!")
		-- inst:Remove()
	-- end)

	inst:SetBrain(brain)
end)

--终极恐惧
AddPrefabPostInit("er_boss003", function(inst)
	local maxhealth = maxhealthli[3]	--最大生命
	inst.skcd1 = 0						--1级技能CD
	inst.skcd2 = 0						--2级技能CD
	inst.skcd3 = 0						--3级技能CD
	inst.skli1 = {"skill1","skill2"}	--1级技能列表
	inst.skli2 = {"skill3","skill4"}	--2级技能列表
	inst.skli3 = {"skill5","skill6"}	--3级技能列表
	inst.damage = damageli[3]			--默认伤害

	inst:AddComponent("locomotor")
	inst.components.locomotor.runspeed = runspeedli[3]
	inst:SetStateGraph("SGer_boss")			--加载SG

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(maxhealth)
	inst.components.health:SetAbsorptionAmount(defenseli[3])
	inst.components.health:StartRegen(maxhealth*regenli[3], 1)	--回复血量

	inst:AddComponent("talker")
	inst:AddComponent("inventory")
	inst.components.inventory:DisableDropOnDeath()

	local weapon = SpawnPrefab("weapon103")
	weapon.components.weapon:SetDamage(inst.damage)
	weapon.components.weapon:SetRange(2,2.5)
	weapon.components.inventoryitem:SetOnDroppedFn(inst.Remove)
	inst.components.inventory:Equip(weapon)

	inst:AddComponent("sanityaura")
	inst.components.sanityaura.aura = aurali[3]

	inst:AddComponent("combat")
	inst.components.combat:SetAttackPeriod(periodli[3])	--攻击频率
	inst.components.combat:SetRange(5,5)					--攻击距离
	inst.components.combat:SetAreaDamage(4, 1)			    --范围攻击
    inst.components.combat:SetRetargetFunction(1, RetargetFn)

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("er_boss003")

	inst:AddComponent("inspectable")
	inst.components.inspectable:SetDescription("毁灭一切的终极恐惧!!!")
	
	inst:ListenForEvent("onhitother", onattack)	--攻击监听
	inst:ListenForEvent("attacked", locktargrt)	--受伤监听
	--血量监控
	inst:ListenForEvent("healthdelta", function(inst, data)
		local newpercent = data.newpercent
		if newpercent and newpercent < rageli[3] then
			if not inst.awaken then
				inst.awaken = true
				inst.damage = inst.damage * 1.5
				local newdefense = defenseli[2] + 0.1
				weapon.components.weapon:SetDamage(inst.damage)
				inst.components.health:SetAbsorptionAmount(newdefense)
				TheNet:Announce("终极恐惧开始暴走!防御力提升至".. newdefense*100 .."%,攻击力提升50%!")
			end
		end
	end)
	-- inst:ListenForEvent("death", function(inst)end)
	
	inst:DoPeriodicTask(10, function()
		local x, y, z = inst.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x, 0, z, 20, {"player"})
		local rank = 1 + #ents * 0.3
		weapon.components.weapon:SetDamage(inst.damage * rank)
		if rank > 1 then
			TheNet:Announce("当前参与人数为"..#ents..",终极恐惧攻击力变更为".. rank*100 .."%!")
		end
	end)
	
	-- inst:DoTaskInTime(removeli[3], function()
		-- TheNet:Announce("终极恐惧脱离了该世界!")
		-- inst:Remove()
	-- end)

	inst:SetBrain(brain)	--加载脑子
end)