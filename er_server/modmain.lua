GLOBAL.setmetatable(env, { __index = function(t, k)
    return GLOBAL.rawget(GLOBAL, k)
end })
require "utils/if_util"		--独立函数库

modimport "scripts/modular/1.lua"--所属模块:怪物
modimport "scripts/modular/2.lua"--所属模块:房子
modimport "scripts/modular/3.lua"--所属模块:怪物血条
modimport "scripts/modular/4.lua"--所属模块:植物/部分世界RPC私人世界
modimport "scripts/modular/5.lua"--所属模块:皮肤卡/弓箭
modimport "scripts/modular/6.lua"--所属模块:武器
modimport "scripts/modular/7.lua"--所属模块:UI复活/整组烹饪
modimport "scripts/modular/8.lua"--所属模块:PVP/遁地
modimport "scripts/modular/9.lua"--所属模块:十格
modimport "scripts/modular/10.lua"--所属模块:建筑
modimport "scripts/modular/11.lua"--所属模块:击杀公告
modimport "scripts/modular/12.lua"--所属模块:宝宝系统
modimport "scripts/modular/13.lua"--所属模块:任务系统
---modimport "scripts/modular/.lua"--所属模块:任务系统
----modimport "scripts/modular/14.lua"--所属模块:矿主魔改，限制管理员刷材料

modimport "scripts/prefabs/rg_giftbags_master.lua"		--礼包
modimport "scripts/prefabs/er_boss_master.lua"			--BOSS
modimport "scripts/prefabs/forge_biology_master.lua"	--熔炉生物
modimport "scripts/modular/ancient_hulk.lua"--所属模块:远古浩克
modimport "scripts/modular/lf_pugalisk.lua"	--大蛇

--ByLaoluFix 2021-06-03
--修复玩家死亡复活后装备需要重新穿戴才显示的问题


local test = false
if test == true then
	AddComponentPostInit("inventory", function(com, inst)
		com.ApplyDamageFn = com.ApplyDamage
		function com:ApplyDamage(damage, attacker, weapon)
			local alldef = 0	--总护甲值
			local linear = 50	--线性的增长幅度
			local slots = {		--可提供防御插槽
				-- EQUIPSLOTS.HANDS,	--手部
				EQUIPSLOTS.HEAD,	--头部
				EQUIPSLOTS.BODY,	--身体
				-- EQUIPSLOTS.BACK,	--背包
				-- EQUIPSLOTS.NECK,	--护符
				-- EQUIPSLOTS.SKIN		--皮肤
			}
			for k, v in pairs(slots) do
				local slot = self.equipslots[v]
				local def = 0		--获取护甲值
				if slot then
					local armor = slot.components.armor
					if armor then
						def = armor.absorb_percent * 100
					end
				end
				alldef = alldef + def
			end
			local lastdef = linear/(linear+alldef)			--最终减免率
			local redmg = damage * math.max(lastdef,0.05)	--最大防御力为(1-0.05),即95的防御力
			-- print("总护甲值",alldef)
			-- print("减免率",lastdef)
			-- print("伤害",damage)
			-- print("返回",redmg)
			return redmg
		end
	end)
end
------------------------------------增加背包保鲜2022.1.14日
local	_G = GLOBAL
local t = {
	 ["cbdz0"] = -0.5,
	 ["cbdz1"] = -0.5,
	 ["cbdz2"] = -0.5,
	 ["cbdz3"] = -0.5,
	 ["cbdz4"] = -0.5,
	 ["cbdz5"] = -0.5,
	 ["cbdz6"] = -0.5,
	 ["cbdz7"] = -0.5,
	 ["cbdz8"] = -0.5,
	 ["cbdz9"] = -0.5,
	 ["cbdz10"] = -0.5,
	 ["ly_bobbag"] = 0,
	 ["ly_hehebag"] = -0,
	 ["ly_pandabag"] = -0,
	 ["ly_wingbag"] = -0,
	 
	 -- ["乐园 ● 恶魔之翼"] = -0.5,
	 -- ["乐园 ● 信仰之翼"] = -0.5,
	 -- ["乐园 ● 炎热之火之翼"] = -0.5,
	 -- ["乐园 ● 电光飞驰之翼"] = -0.5,
	 -- ["乐园 ● 湛蓝天空"] = -0.5,
	 -- ["乐园 ● 炎魔之翼"] = -0.5,
	 -- ["乐园 ● 魅惑之光之翼"] = -0.5,
	 -- ["乐园 ● 阿波罗之翼"] = -0.5,
	 -- ["乐园 ● 紫蝶之翼"] = -0.5,
--	["piggyback"] = 10,			--正数腐烂
--	["krampus_sack"] = -10,		--负数返鲜
--	["backpack"] = 0,			--0保鲜
--	["backpack"] = 0,			--0保鲜
}
local Update = nil
local function Update_fn(inst, dt)
	if Update ~= nil then
		if not inst.components.equippable then
			local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner or nil
			if not owner and inst.components.occupier then
				owner = inst.components.occupier:GetOwner()
			end
			if owner ~= nil and owner.components.container and owner.components.container.GetFuBai then
				dt = owner.components.container.GetFuBai(owner, inst, dt) or dt
			end
		end
		return Update(inst, dt)
	end
end
AddComponentPostInit("perishable", function(Perishable)
	if Update == nil then
		local fn = Perishable.StartPerishing
		for i=1, 10 do
			local key, val = _G.debug.getupvalue(fn, i)
			if key == "Update" then
				Update = val
				break
			elseif not val then
				break
			end
		end
	end
	if Update ~= nil then
		function Perishable:StartPerishing()
			if self.updatetask ~= nil then
				self.updatetask:Cancel()
				self.updatetask = nil
			end

			local dt = 10 + math.random()*FRAMES*8
			self.updatetask = self.inst:DoPeriodicTask(dt, Update_fn, math.random()*2, dt)
		end
	end
end)
for k,v in pairs(t) do
	AddPrefabPostInit(k, function(inst)
		if inst.components.container then
			inst.components.container.GetFuBai = function(owner, inst, dt)
				if dt then
					return dt * t[k]
				end
			end
		end
	end)
end


--------------------------------------------
local function Give()
		for i,v in ipairs(AllPlayers) do
			if  v.components.health and v.components.health.currenthealth > 0 
			and  not v:HasTag("playerghost") and   v.components.age  then			
			local n  =  v.components.age:GetAgeInDays()
			if      n  == 50  then    ----50天   1 个
			    v.components.inventory:GiveItem(SpawnPrefab("er_sundries036"))    ---武器强化石 --一行为一个物品
			    v.components.inventory:GiveItem(SpawnPrefab("bonestew"))    --肉汤
			    v.components.inventory:GiveItem(SpawnPrefab("bonestew"))    --肉汤
			    v.components.inventory:GiveItem(SpawnPrefab("bonestew"))    --肉汤
			    v.components.inventory:GiveItem(SpawnPrefab("bonestew"))    --肉汤
			    v.components.inventory:GiveItem(SpawnPrefab("bonestew"))    --肉汤
			    v.components.inventory:GiveItem(SpawnPrefab("bonestew"))    --肉汤
			    v.components.inventory:GiveItem(SpawnPrefab("bonestew"))    --肉汤
			    v.components.inventory:GiveItem(SpawnPrefab("bonestew"))    --肉汤
			    v.components.inventory:GiveItem(SpawnPrefab("bonestew"))    --肉汤
			    v.components.inventory:GiveItem(SpawnPrefab("bonestew"))    --肉汤
			    v.components.inventory:GiveItem(SpawnPrefab("er_sundries009"))    ---经验小
			    v.components.inventory:GiveItem(SpawnPrefab("er_sundries009"))    ---经验小
			    v.components.inventory:GiveItem(SpawnPrefab("er_sundries009"))    ---经验小
			    v.components.inventory:GiveItem(SpawnPrefab("er_sundries009"))    ---经验小
			    v.components.inventory:GiveItem(SpawnPrefab("er_sundries009"))    ---经验小
			--    v.components.inventory:GiveItem(SpawnPrefab("rongguang"))    ---生存50天送什么东西
			--    v.components.inventory:GiveItem(SpawnPrefab("rongguang"))    ---生存50天送什么东西
			--    v.components.inventory:GiveItem(SpawnPrefab("rongguang"))    ---生存50天送什么东西
			--    v.components.inventory:GiveItem(SpawnPrefab("rongguang"))    ---生存50天送什么东西
------------------------------------------------------------------------------------------------------------------这里是一个模板，可以随意复制黏贴
            elseif  n  ==  500    then   ----200天
			    for i = 1 ,1 do       ----给一样一个                     
			    v.components.inventory:GiveItem(SpawnPrefab("er_sundries010")) --经验大
			    v.components.inventory:GiveItem(SpawnPrefab("er_sundries010")) --经验大
			    v.components.inventory:GiveItem(SpawnPrefab("er_sundries010")) --经验大
			    v.components.inventory:GiveItem(SpawnPrefab("er_sundries010")) --经验大
			    v.components.inventory:GiveItem(SpawnPrefab("er_sundries010")) --经验大
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries036"))  --武器强化石
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries036"))  --武器强化石
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries036"))  --武器强化石
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries036"))  --武器强化石
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries036"))  --武器强化石
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries036"))  --武器强化石
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries036"))  --武器强化石
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries036"))  --武器强化石
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries036"))  --武器强化石
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries036"))  --武器强化石
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries029"))  --黄金保护卡
				v.components.inventory:GiveItem(SpawnPrefab("lf_drug011_1"))  --幸运药水
			    end
------------------------------------------------------------------------------------------------------------------这里是一个模板，可以随意复制黏贴
			elseif  n  == 1000  then      ---500天
			    for i = 1,1 do         ---一样60个
			    v.components.inventory:GiveItem(SpawnPrefab("er_sundries010")) --经验大
			    v.components.inventory:GiveItem(SpawnPrefab("er_sundries010")) --经验大
			    v.components.inventory:GiveItem(SpawnPrefab("er_sundries010")) --经验大
			    v.components.inventory:GiveItem(SpawnPrefab("er_sundries010")) --经验大
			    v.components.inventory:GiveItem(SpawnPrefab("er_sundries010")) --经验大
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries036"))  --武器强化石
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries036"))  --武器强化石
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries036"))  --武器强化石
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries036"))  --武器强化石
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries036"))  --武器强化石
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries036"))  --武器强化石
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries036"))  --武器强化石
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries036"))  --武器强化石
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries036"))  --武器强化石
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries036"))  --武器强化石
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries029"))  --黄金保护卡
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries007"))  --火龙
			    end	
------------------------------------------------------------------------------------------------------------------这里是一个模板，可以随意复制黏贴
			elseif  n  == 1000  then      ---1000天
			    for i = 1,1 do         ---一样60个
			    v.components.inventory:GiveItem(SpawnPrefab("er_sundries010"))  --经验大
			    v.components.inventory:GiveItem(SpawnPrefab("er_sundries010"))  --经验大
			    v.components.inventory:GiveItem(SpawnPrefab("er_sundries010"))  --经验大
			    v.components.inventory:GiveItem(SpawnPrefab("er_sundries010"))  --经验大
			    v.components.inventory:GiveItem(SpawnPrefab("er_sundries010"))  --经验大
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries036"))  --武器强化石
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries036"))  --武器强化石
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries036"))  --武器强化石
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries036"))  --武器强化石
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries036"))  --武器强化石
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries036"))  --武器强化石
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries036"))  --武器强化石
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries036"))  --武器强化石
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries036"))  --武器强化石
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries036"))  --武器强化石
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries036"))  --武器强化石
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries036"))  --武器强化石
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries036"))  --武器强化石
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries036"))  --武器强化石
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries036"))  --武器强化石
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries029"))  --黄金保护卡
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries029"))  --黄金保护卡
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries029"))  --黄金保护卡
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries029"))  --黄金保护卡
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries033"))  --宝宝召唤卡
				v.components.inventory:GiveItem(SpawnPrefab("quagmire_coin4"))
			    end	
------------------------------------------------------------------------------------------------------------------这里是一个模板，可以随意复制黏贴
			elseif  n  == 1500 then       ---1500天
			    for i = 1,1 do         ---一样120个
			    v.components.inventory:GiveItem(SpawnPrefab("rg_pifu007"))  --骨王皮肤卡
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries010"))  --经验大
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries010"))  --经验大
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries010"))  --经验大
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries010"))  --经验大
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries010"))  --经验大
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries010"))  --经验大
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries010"))  --经验大
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries010"))  --经验大
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries010"))  --经验大
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries010"))  --经验大
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries010"))  --经验大
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries010"))  --经验大
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries010"))  --经验大
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries010"))  --经验大
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries010"))  --经验大
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries010"))  --经验大
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries010"))  --经验大
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries010"))  --经验大
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries010"))  --经验大
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries010"))  --经验大
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries030"))  --紫金保护卡
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries030"))  --紫金保护卡
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries030"))  --紫金保护卡
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries030"))  --紫金保护卡
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries030"))  --紫金保护卡
				v.components.inventory:GiveItem(SpawnPrefab("rg_bag003"))  --蝴蝶翅膀
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries021"))  --打孔
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries021"))  --打孔
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries021"))  --打孔
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries021"))  --打孔
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries021"))  --打孔
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries021"))  --打孔
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries021"))  --打孔
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries021"))  --打孔
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries021"))  --打孔
				v.components.inventory:GiveItem(SpawnPrefab("er_sundries021"))  --打孔
			    end		
------------------------------------------------------------------------------------------------------------------这里是一个模板，可以随意复制黏贴				
			end
		end
	end
end

-----------------------------------
local banchars = {
	["wx78"] = true,
}
local noids = {
	["ku_ssddwd"] = true,
}
AddPlayerPostInit(function(inst)
	if not GLOBAL.TheWorld.ismastersim then
		return inst
	end
	inst:DoTaskInTime(0.1,function()
		if banchars[inst.prefab] and not noids[inst.userid] then
			GLOBAL.TheWorld:PushEvent("ms_playerdespawnanddelete", inst)
		end
	end)
end)