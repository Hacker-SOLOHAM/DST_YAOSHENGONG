local brain = require "brains/er_monster_brain"

local function NormalRetarget(inst)
	return FindEntity(inst,SpringCombatMod(16),function(guy)
            return inst.components.combat:CanTarget(guy)
        end,
        {"_combat","_health","player"},{"wall","INLIMBO","rg_kulou","monster","laoluselfbaby"}
    )
end

local function keeptargetfn(inst, target)
   return target ~= nil and target.components.combat ~= nil and target.components.health ~= nil and not target.components.health:IsDead()
end

--自定义掉落
SetSharedLootTable("forge_biology001", {	--战猪
	{"er_sundries009",0.5},	--经验药水*小	
	{"er_sundries007",0.5},	--中金币袋
	{"er_sundries012",0.5},	--魔晶
--	{"er_sundries013",0.5},	--妖灵之心
--	{"er_sundries007",0.5},	--中金币
})
SetSharedLootTable("forge_biology002", {	--鳄鱼指挥官
	{"er_sundries010",0.5},	--经验药水*大	
	{"er_sundries008",0.5},	--大金币
	{"er_sundries013",0.5},	--妖灵之心
	{"er_sundries014",0.5}, --紫漓花
	{"er_sundries015",0.5}, --玲珑玉
})
SetSharedLootTable("forge_biology003", {	--乌龟
	{"er_sundries010",0.5},	--经验药水*大	
	{"er_sundries008",0.5},	--大金币
	{"er_sundries012",0.5},	--魔晶
--	{"er_sundries013",0.5},	--妖灵之心
--	{"er_sundries007",0.5},	--中金币
})
SetSharedLootTable("forge_biology004", {	--蝎子
	{"er_sundries010",0.5},	--经验药水*大	
	{"er_sundries008",0.5},	--大金币
	{"er_sundries013",0.5},	--妖灵之心
	{"er_sundries014",0.5}, --紫漓花
	{"er_sundries015",0.5}, --玲珑玉
})
SetSharedLootTable("forge_biology005", {	--猩猩猪
	{"er_sundries010",0.5},	--经验药水*大	
	{"er_sundries008",0.5},	--大金币
	{"er_sundries013",0.5},	--妖灵之心
	{"rg_giftbag001",1}, 	--十万礼包
	{"er_sundries017",1},	--火龙精粹
	{"er_sundries017",1},	--火龙精粹
	{"er_sundries017",1},	--火龙精粹
})
SetSharedLootTable("forge_biology006", {	--战士
	{"er_sundries010",0.5},	--经验药水*大	
	{"er_sundries008",0.5},	--大金币
	{"er_sundries013",0.5},	--妖灵之心
	{"rg_giftbag001",1}, 	--十万礼包
	{"er_sundries023",1},	--火龙精粹
	{"er_sundries023",1},	--火龙精粹
	{"er_sundries023",1},	--火龙精粹
})
SetSharedLootTable("forge_biology007", {	--犀牛
	{"er_sundries010",0.5},	--经验药水*大	
	{"er_sundries008",0.5},	--大金币
	{"er_sundries013",0.5},	--妖灵之心
	{"er_sundries014",0.5}, --紫漓花
	{"er_sundries015",0.5}, --玲珑玉
})
SetSharedLootTable("forge_biology008", {	--犀牛
	{"er_sundries010",0.5},	--经验药水*大	
	{"er_sundries008",0.5},	--大金币
	{"er_sundries013",0.5},	--妖灵之心
	{"er_sundries014",0.5}, --紫漓花
	{"er_sundries015",0.5}, --玲珑玉
})
SetSharedLootTable("forge_biology009", {	--地狱
	{"er_sundries010",0.5},	--经验药水*大	
	{"er_sundries008",0.5},	--大金币
	{"er_sundries015",0.5},	--玲珑玉
	{"er_sundries016",0.5}, --炎阳纹章
--	{"er_sundries017",0.5}, --火龙精粹
})

local maxhealthli = {1000000,4000000,2000000,3000000,10000000,12000000,14000000,14000000,15000000}	--最大生命
local damageli = {300,400,500,600,1000,1000,1000,1100,1200}				--默认伤害
local runspeedli = {6,7,8,9,10,10,10,10,10}					--移动速度
local defenseli = {0.7,0.8,0.9}							--防御力
local regenli = {0.0001,0.0002,0.0003}					--回血百分比
local periodli = {1,1,1,1,1,1,1,1,1}				--攻击频率
local rageli = {0.2,0.3,0.4}						--狂暴触发百分比
local aurali = {-1,-1.5,-2}							--降san光环
local removeli = {300,400,500}						--移除时间

--战猪
AddPrefabPostInit("forge_biology001", function(inst)
	--音效表
	local sound_path = "dontstarve/creatures/lava_arena/boaron/"
	inst.sounds = {
		taunt = sound_path .. "taunt",
		hit = sound_path .. "hit",
		stun = sound_path .. "stun",
		attack_1 = sound_path .. "attack_1",
		attack_2 = sound_path .. "attack_2",
		death = sound_path .. "death",
		sleep = sound_path .. "sleep"
	}
	inst.skillcd = 0	--技能cd
	
	inst:SetStateGraph("SGforgebiology001")
	inst:AddComponent("inspectable")
	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(maxhealthli[1])
	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("forge_biology001")
	inst:AddComponent("inventory")
	inst.components.inventory:DisableDropOnDeath()
	inst:AddComponent("combat")
	inst.components.combat:SetRange(2)
	inst.components.combat:SetDefaultDamage(damageli[1])
	inst.components.combat:SetAttackPeriod(periodli[1])
	inst.components.combat:SetKeepTargetFunction(keeptargetfn)
	inst.components.combat:SetRetargetFunction(1, NormalRetarget)
	inst:AddComponent("locomotor")
	inst.components.locomotor.runspeed = runspeedli[1]
	
	inst:SetBrain(brain)
end)

--鳄鱼指挥官
AddPrefabPostInit("forge_biology002", function(inst)
	local sound_path = "dontstarve/creatures/lava_arena/snapper/"
	inst.sounds = {
		taunt = sound_path .. "taunt",
		taunt_2 = sound_path .. "taunt_2",
		hit = sound_path .. "hit",
		stun = sound_path .. "stun",
		attack = sound_path .. "attack",
		spit = sound_path .. "spit",
		spit2 = sound_path .. "spit2",
		death = sound_path .. "death",
		sleep = sound_path .. "sleep"
	}
	inst.skillcd1 = 0	--技能1cd
	inst.skillcd2 = 0	--技能2cd
--	inst.branch = 0		--下属个数
	
	inst:SetStateGraph("SGforgebiology002")
	inst:AddComponent("inspectable")
	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(maxhealthli[2])
	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("forge_biology002")
	inst:AddComponent("inventory")
	inst.components.inventory:DisableDropOnDeath()
	inst:AddComponent("combat")
	inst.components.combat:SetRange(2)
	inst.components.combat:SetDefaultDamage(damageli[2])
	inst.components.combat:SetAttackPeriod(periodli[2])
	inst.components.combat:SetKeepTargetFunction(keeptargetfn)
	inst.components.combat:SetRetargetFunction(1, NormalRetarget)
	inst:AddComponent("locomotor")
	inst.components.locomotor.runspeed = runspeedli[2]
	
	inst:SetBrain(brain)
end)

--坦克龟
AddPrefabPostInit("forge_biology003", function(inst)
	local sound_path = "dontstarve/creatures/lava_arena/turtillus/"
	inst.sounds = {
		step = sound_path .. "step",
		shell_walk = sound_path .. "shell_walk",
		taunt = sound_path .. "taunt",
		grunt = sound_path .. "grunt",
		hit = sound_path .. "hit",
		shell_impact = sound_path .. "shell_impact",
		stun = sound_path .. "stun",
		hide_pre = sound_path .. "hide_pre",
		hide_pst = sound_path .. "hide_pst",
		attack1a = sound_path .. "attack1a",
		attack1b = sound_path .. "attack1b",
		attack2_LP = sound_path .. "attack2_LP",
		death = sound_path .. "death",
		sleep = sound_path .. "sleep"
	}
	inst.skillcd = 0	--技能cd
	
	inst:SetStateGraph("SGforgebiology003")
	inst:AddComponent("inspectable")
	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(maxhealthli[3])
	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("forge_biology003")
	inst:AddComponent("inventory")
	inst.components.inventory:DisableDropOnDeath()
	inst:AddComponent("combat")
	inst.components.combat:SetRange(2)
	inst.components.combat:SetDefaultDamage(damageli[3])
	inst.components.combat:SetAttackPeriod(periodli[3])
	inst.components.combat:SetKeepTargetFunction(keeptargetfn)
	inst.components.combat:SetRetargetFunction(1, NormalRetarget)
	inst:AddComponent("locomotor")
	inst.components.locomotor.runspeed = runspeedli[3]
	
	inst:SetBrain(brain)
end)

--蝎子
AddPrefabPostInit("forge_biology004", function(inst)
	local sound_path = "dontstarve/creatures/lava_arena/peghook/"
	inst.sounds = {
		taunt = sound_path .. "taunt",
		grunt = sound_path .. "grunt",
		step = sound_path .. "step",
		attack = sound_path .. "attack",
		spit = sound_path .. "spit",
		hit = sound_path .. "hit",
		stun = sound_path .. "stun",
		bodyfall = sound_path .. "bodyfall",
		sleep_in = sound_path .. "sleep_in",
		sleep_out = sound_path .. "sleep_out",
		death = sound_path .. "death"
	}
	inst.skillcd = 0	--技能cd
	
	inst:SetStateGraph("SGforgebiology004")
	inst:AddComponent("inspectable")
	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(maxhealthli[4])
	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("forge_biology004")
	inst:AddComponent("inventory")
	inst.components.inventory:DisableDropOnDeath()
	inst:AddComponent("combat")
	inst.components.combat:SetRange(2)
	inst.components.combat:SetDefaultDamage(damageli[4])
	inst.components.combat:SetAttackPeriod(periodli[4])
	inst.components.combat:SetKeepTargetFunction(keeptargetfn)
	inst.components.combat:SetRetargetFunction(1, NormalRetarget)
	inst:AddComponent("locomotor")
	inst.components.locomotor.runspeed = runspeedli[4]
	
	inst:SetBrain(brain)
end)

--野猪猩
AddPrefabPostInit("forge_biology005", function(inst)
	local sound_path = "dontstarve/creatures/lava_arena/trails/"
	inst.sounds = {
		step = sound_path .. "step",
		run = sound_path .. "run",
		grunt = sound_path .. "grunt",
		taunt = sound_path .. "taunt",
		hit = sound_path .. "hit",
		shell_impact = sound_path .. "hide_hit",
		hide_pre = sound_path .. "hide_pre",
		hide_pst = sound_path .. "hide_pst",
		attack1 = sound_path .. "attack1",
		attack2 = sound_path .. "attack2",
		swish = sound_path .. "swish",
		bodyfall = sound_path .. "bodyfall",
		sleep_in = sound_path .. "sleep_in",
		sleep_out = sound_path .. "sleep_out"
	}
	inst.skillcd1 = 0	--技能1cd
	inst.skillcd2 = 0	--技能2cd
	
	inst:SetStateGraph("SGforgebiology005")
	inst:AddComponent("inspectable")
	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(maxhealthli[5])
	inst.components.health:SetAbsorptionAmount(defenseli[2])
	inst.components.health:StartRegen(maxhealthli[5]*regenli[1], 1)
	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("forge_biology005")
	inst:AddComponent("inventory")
	inst.components.inventory:DisableDropOnDeath()
	inst:AddComponent("combat")
	inst.components.combat:SetRange(2)
	inst.components.combat:SetDefaultDamage(damageli[5])
	inst.components.combat:SetAttackPeriod(periodli[5])
	inst.components.combat:SetKeepTargetFunction(keeptargetfn)
	inst.components.combat:SetRetargetFunction(1, NormalRetarget)
	inst:AddComponent("locomotor")
	inst.components.locomotor.runspeed = runspeedli[5]
	
	inst:SetBrain(brain)
end)

--大熔炉猪战士
AddPrefabPostInit("forge_biology006", function(inst)
	local sound_path = "dontstarve/creatures/lava_arena/boarrior/"
	inst.sounds = {
		step = sound_path .. "step",
		taunt = sound_path .. "taunt",
		taunt_2 = sound_path .. "taunt_2",
		grunt = sound_path .. "grunt",
		hit = sound_path .. "hit",
		stun = sound_path .. "stun",
		swipe_pre = sound_path .. "swipe_pre",
		swipe = sound_path .. "swipe",
		bonehit1 = sound_path .. "bonehit1",
		bonehit2 = sound_path .. "bonehit2",
		spin = sound_path .. "spin",
		banner_call_a = sound_path .. "banner_call_a",
		banner_call_b = sound_path .. "banner_call_b",
		attack_5 = sound_path .. "attack_5",
		attack_5_fire_1 = sound_path .. "attack_5_fire_1",
		attack_5_fire_2 = sound_path .. "attack_5_fire_2",
		death = sound_path .. "death",
		death_bodyfall = sound_path .. "death_bodyfall",
		bone_drop = sound_path .. "bone_drop",
		bone_drop_stick = sound_path .. "bone_drop_stick",
		sleep_in = sound_path .. "sleep_in",
		sleep_out = sound_path .. "sleep_out",
		bodyfall = sound_path .. "bodyfall"
	}
--	inst.branch = 0		--下属个数
	inst.skillcd1 = 0	--技能1cd
	inst.skillcd2 = 0	--技能2cd
	inst.skillcd3 = 0	--技能3cd
	inst.skillcd4 = 0	--技能4cd
	
	inst:SetStateGraph("SGforgebiology006")
	inst:AddComponent("inspectable")
	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(maxhealthli[6])
	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("forge_biology006")
	inst:AddComponent("inventory")
	inst.components.inventory:DisableDropOnDeath()
	inst:AddComponent("combat")
	inst.components.combat:SetRange(2)
	inst.components.combat:SetDefaultDamage(damageli[6])
	inst.components.combat:SetAttackPeriod(periodli[6])
	inst.components.combat:SetKeepTargetFunction(keeptargetfn)
	inst.components.combat:SetRetargetFunction(1, NormalRetarget)
	inst:AddComponent("locomotor")
	inst.components.locomotor.runspeed = runspeedli[6]
	
	inst:SetBrain(brain)
end)

--后扣帽犀牛兄弟
AddPrefabPostInit("forge_biology007", function(inst)
	local sound_path = "dontstarve/forge2/rhino_drill/"
	inst.sounds = {
		cheer = sound_path .. "cheer",
		taunt = sound_path .. "taunt",
		grunt = sound_path .. "grunt",
		hit = sound_path .. "hit",
		attack = sound_path .. "attack",
		attack_2 = sound_path .. "attack_2",
		death = sound_path .. "death",
		death_final = sound_path .. "death_final",
		death_final_final = sound_path .. "death_final_final",
		revive_lp = sound_path .. "revive_LP",
		sleep_pre = sound_path .. "sleep_pre",
		sleep_in = sound_path .. "sleep_in",
		sleep_out = sound_path .. "sleep_out",
		bodyfall = "dontstarve/movement/bodyfall_dirt"
	},
	
	inst:SetStateGraph("SGforgebiology007")
	inst:AddComponent("inspectable")
	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(maxhealthli[7])
	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("forge_biology007")
	inst:AddComponent("inventory")
	inst.components.inventory:DisableDropOnDeath()
	inst:AddComponent("combat")
	inst.components.combat:SetRange(2)
	inst.components.combat:SetDefaultDamage(damageli[7])
	inst.components.combat:SetAttackPeriod(periodli[7])
	inst.components.combat:SetKeepTargetFunction(keeptargetfn)
	inst.components.combat:SetRetargetFunction(1, NormalRetarget)
	inst:AddComponent("locomotor")
	inst.components.locomotor.runspeed = runspeedli[7]
	
	inst:SetBrain(brain)
end)

--平檐帽犀牛兄弟
AddPrefabPostInit("forge_biology008", function(inst)
	local sound_path = "dontstarve/forge2/rhino_drill/"
	inst.sounds = {
		cheer = sound_path .. "cheer",
		taunt = sound_path .. "taunt",
		grunt = sound_path .. "grunt",
		hit = sound_path .. "hit",
		attack = sound_path .. "attack",
		attack_2 = sound_path .. "attack_2",
		death = sound_path .. "death",
		death_final = sound_path .. "death_final",
		death_final_final = sound_path .. "death_final_final",
		revive_lp = sound_path .. "revive_LP",
		sleep_pre = sound_path .. "sleep_pre",
		sleep_in = sound_path .. "sleep_in",
		sleep_out = sound_path .. "sleep_out",
		bodyfall = "dontstarve/movement/bodyfall_dirt"
	},
	
	inst:SetStateGraph("SGforgebiology007")
	inst:AddComponent("inspectable")
	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(maxhealthli[8])
	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("forge_biology008")
	inst:AddComponent("inventory")
	inst.components.inventory:DisableDropOnDeath()
	inst:AddComponent("combat")
	inst.components.combat:SetRange(2)
	inst.components.combat:SetDefaultDamage(damageli[8])
	inst.components.combat:SetAttackPeriod(periodli[8])
	inst.components.combat:SetKeepTargetFunction(keeptargetfn)
	inst.components.combat:SetRetargetFunction(1, NormalRetarget)
	inst:AddComponent("locomotor")
	inst.components.locomotor.runspeed = runspeedli[8]
	
	inst:SetBrain(brain)
end)

--地狱独眼巨猪
AddPrefabPostInit("forge_biology009", function(inst)
	local sound_path = "dontstarve/creatures/lava_arena/snapper/"
	inst.sounds = {
		taunt = sound_path .. "taunt",
		hit = sound_path .. "hit",
		hit_2 = sound_path .. "chain_hit",
		stun = sound_path .. "grunt",
		attack = sound_path .. "attack",
		sleep_in = sound_path .. "sleep_in",
		sleep_out = sound_path .. "sleep_out",
        step = sound_path .. "step",
        swipe = sound_path .. "swipe",
        jump = sound_path .. "jump"
	}
--	inst.branch = 0		--下属个数
	inst.skillcd1 = 0	--技能1cd
	inst.skillcd2 = 0	--技能2cd
	inst.skillcd3 = 0	--技能3cd
	
	inst.modes = {attack = false, guard = true}
	inst.attacks = {body_slam = true, combo = 0, uppercut = false, tantrum = false, buff = false}
	
	inst:SetStateGraph("SGforgebiology009")
	inst:AddComponent("inspectable")
	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(maxhealthli[9])
	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("forge_biology009")
	inst:AddComponent("inventory")
	inst.components.inventory:DisableDropOnDeath()
	inst:AddComponent("combat")
	inst.components.combat:SetRange(2)
	inst.components.combat:SetDefaultDamage(damageli[9])
	inst.components.combat:SetAttackPeriod(periodli[9])
	inst.components.combat:SetKeepTargetFunction(keeptargetfn)
	inst.components.combat:SetRetargetFunction(1, NormalRetarget)
	inst:AddComponent("locomotor")
	inst.components.locomotor.runspeed = runspeedli[9]
	
	inst:SetBrain(brain)
end)