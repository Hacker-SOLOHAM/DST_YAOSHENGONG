----[[
local fumorate = {  0.9,0.8,0.7,0.6,0.5,0.4,}--附魔等级关系冷却系数
--功能操作
local DoAbility = {
	{	--附加功能
		[1] = function(inst,owner)	--恒温

			if owner then --获取使用者
				inst:AddTag("rg_hengwen") --给护符添加标签 主要是为了实现功能用
				if owner.components and owner.components.temperature and inst._WD_task ==nil then
					inst._WD_task = inst:DoPeriodicTask(1, function()
						owner.components.temperature:SetTemperature(25) --温度强制变成25
					end)
				end
			end

		end,
		[2] = function(inst,owner)	--防水
			if inst.components.waterproofer ==nil then inst:AddComponent("waterproofer") end
			inst.components.waterproofer:SetEffectiveness(1)
		end,
		[3] = function(inst,owner)	--绝缘
			if inst.components.equippable ==nil then inst:AddComponent("equippable") end
			inst.components.equippable.insulated = true
		end,
		[4] = function(inst,owner)	--移速
			if inst.components.equippable ==nil then inst:AddComponent("equippable") end
			inst.components.equippable.walkspeedmult = 1.25
		end,
		-- [5] = function(inst,owner)	--魔法:不启用
			-- if not owner.magicnum then
				-- local lr_magic = owner.components.lr_magic
				-- local percent = lr_magic:GetPercent()
				-- owner.magicnum = lr_magic.max
				-- lr_magic.max = lr_magic.max + 200
				-- lr_magic:SetPercent(percent)
			-- end
		-- end,
		--
		[5] = function(inst,owner)	--精神回复
			local hf_sanity = (owner and owner.components and owner.components.sanity) or nil
			if hf_sanity ~=nil and inst._sanity_task ==nil then
				inst._sanity_task = inst:DoPeriodicTask(1, function()
					hf_sanity:SetPercent(1) --玩家回复脑残100&
				end)		
			end
		end,		
		-- [6] = function(inst,owner)	--生命:不启用
			-- if not owner.maxhealth then
				-- owner.maxhealth = owner.components.health.maxhealth
				-- owner.components.health.maxhealth = owner.components.health.maxhealth * 1.2
			-- end
		-- end
		[6] = function(inst,owner)	--霸体
			if inst and owner then
				owner:AddTag("lf_bati")
			end
		end,
	},
	{	--移除功能
		[1] = function(inst,owner)	
			inst:RemoveTag("rg_hengwen")--恒温
			if inst._WD_task ~=nil then
				inst._WD_task:Cancel()
				inst._WD_task = nil
			end
		end,
		[2]	= function(inst,owner)	
			inst.components.waterproofer:SetEffectiveness(0)--防水
		end,
		[3] = function(inst,owner)	
			inst.components.equippable.insulated = false--绝缘
		end,
		[4] = function(inst,owner)
			if inst.components.equippable ~=nil then
				inst.components.equippable.walkspeedmult = 1--移速
				-- inst:RemoveComponent("equippable")-- 移除一个组件
			end
		end,
			--魔法:不启用
			-- if owner.magicnum then
				-- local lr_magic = owner.components.lr_magic
				-- local percent = lr_magic:GetPercent()
				-- lr_magic.max = lr_magic.max - 200
				-- lr_magic:SetPercent(percent)
				-- owner.magicnum = nil
			-- end				
		[5] = function(inst,owner)--精神回复
			if inst._sanity_task ~=nil then
				inst._sanity_task:Cancel()
				inst._sanity_task = nil
			end
		end,			
		-- [6] = function(inst,owner)--生命:不启用
			-- if owner.maxhealth then
				-- owner.components.health.maxhealth = owner.maxhealth
				-- owner.maxhealth = nil
			-- end
		-- end,
		[6] = function(inst,owner)	--霸体
			if inst and owner then
				owner:RemoveTag("lf_bati")
			end
		end,
	}
}
local function ratefn(inst)
	local rate = 1 --默认的当然是1
	if inst.components.rgwuqinew ~= nil and inst.components.rgwuqinew.colour ~= 0 then -- 如果附魔组件存在 而且有附魔 
		rate = fumorate[inst.components.rgwuqinew.colour] --比如6级就是 0.4 缩短了一半多
	end
	return rate
end

local function onstart(inst)
	inst.components.useableitem.inuse = true --冷却的时候 护符不可以使用
end

local function onstop(inst)
	inst.components.useableitem.inuse = false --冷却结束护符可以使用
end

--恒温护符
AddPrefabPostInit("rg_amulet001", function(inst)
	inst.abilityid = 1
	inst:AddTag("rechargeable")

	inst:AddComponent("useableitem") --使用装备组件 
	inst.components.useableitem:SetOnUseFn(function(inst)
		if inst.components.rechargeable and inst.components.rechargeable.recharging == true then
			return	--如果是冷却中 那么直接返回
		end
		local owner = inst.components.inventoryitem.owner
		if owner then --获取使用者
			if owner.components.temperature then
				owner.components.temperature:SetTemperature(25) --温度强制变成25
			end
			inst:AddTag("rg_hengwen") --给护符添加标签 主要是为了实现功能用
			inst._temtask = inst:DoTaskInTime(30, function(inst)
				inst:RemoveTag("rg_hengwen")
				inst._temtask = nil
			end)
			inst.components.rechargeable:StartRecharging() --开始进入冷却
		end
	end)
	
	inst:AddComponent("rechargeable") --冷却组件
	inst.components.rechargeable:SetRechargeTime(50) --总的冷却时间
	inst.components.rechargeable:SetRechargeRate(ratefn) --设置冷却系数 关系到冷却时间的长短
	inst.components.rechargeable.onstartrecharging = onstart --冷却开始触发的函数
	inst.components.rechargeable.onstoprecharging = onstop --冷却结束触发的函数
end)

--绝缘护符(原战骑)
AddPrefabPostInit("rg_amulet002", function(inst)
	inst.abilityid = 3

	inst.components.equippable.insulated = true
end)

--魔法护符:暂不启用
-- AddPrefabPostInit("rg_amulet003", function(inst)
	-- inst.abilityid = 5

	-- inst.components.equippable:SetOnEquip(function(inst, owner)
		-- local lr_magic = owner.components.lr_magic
		-- local percent = lr_magic:GetPercent()
		-- lr_magic.max = lr_magic.max + 200
		-- lr_magic:SetPercent(percent)
	-- end)
	-- inst.components.equippable:SetOnUnequip(function(inst, owner)
		-- local lr_magic = owner.components.lr_magic
		-- local percent = lr_magic:GetPercent()
		-- lr_magic.max = lr_magic.max - 200
		-- lr_magic:SetPercent(percent)
	-- end)
-- end)

--精神护符
AddPrefabPostInit("rg_amulet003", function(inst)
	inst.abilityid = 5

	inst.components.equippable:SetOnEquip(function(inst, owner)
		local hf_sanity = owner.components.sanity
		if hf_sanity ~=nil then
			inst._sanity_task = inst:DoPeriodicTask(1, function()
				hf_sanity:SetPercent(1) --玩家回复脑残100&
			end)		
		end
	end)
	inst.components.equippable:SetOnUnequip(function(inst, owner)
		if inst._sanity_task ~=nil then
			inst._sanity_task:Cancel()
			inst._sanity_task = nil
		end
	end)
end)
--磐石护符
AddPrefabPostInit("rg_amulet004", function(inst)
	inst:AddTag("rechargeable")
	inst:AddComponent("useableitem")
	inst.components.useableitem:SetOnUseFn(function(inst)
		if inst.components.rechargeable and inst.components.rechargeable.recharging == true then
			return
		end
		local owner = inst.components.inventoryitem.owner
		if owner then
			owner.components.health:SetAbsorptionAmount(0.5)
			owner:DoTaskInTime(10, function(inst)
				owner.components.health:SetAbsorptionAmount(0)
			end)
			inst.components.rechargeable:StartRecharging()
		end
	end)
	
	inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetRechargeTime(50)
	inst.components.rechargeable:SetRechargeRate(ratefn)
	inst.components.rechargeable.onstartrecharging = onstart
	inst.components.rechargeable.onstoprecharging = onstop
end)

--移速护符
AddPrefabPostInit("rg_amulet005", function(inst)
	inst.abilityid = 4
	inst:AddTag("rechargeable")

	inst:AddComponent("useableitem")
	inst.components.useableitem:SetOnUseFn(function(inst)
		if inst.components.rechargeable and inst.components.rechargeable.recharging == true then
			return
		end
		inst.components.equippable.walkspeedmult = 1.25
		inst:DoTaskInTime(30, function(inst)
			inst.components.equippable.walkspeedmult = 1
		end)
		inst.components.rechargeable:StartRecharging()
	end)
	
	inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetRechargeTime(50)
	inst.components.rechargeable:SetRechargeRate(ratefn)
	inst.components.rechargeable.onstartrecharging = onstart
	inst.components.rechargeable.onstoprecharging = onstop
end)

--生命护符:暂时不启用
-- AddPrefabPostInit("rg_amulet006", function(inst)
	-- inst.abilityid = 6

	-- inst.components.equippable:SetOnEquip(function(inst, owner)
		-- owner.maxhealth = owner.components.health.maxhealth
		-- owner.components.health.maxhealth = owner.components.health.maxhealth * 1.2
	-- end)
	-- inst.components.equippable:SetOnUnequip(function(inst, owner)
		-- owner.components.health.maxhealth = owner.maxhealth
	-- end)
-- end)
--霸体
AddPrefabPostInit("rg_amulet006", function(inst)
	inst.abilityid = 6
	inst.components.equippable:SetOnEquip(function(inst, owner)
		owner:AddTag("lf_bati")
	end)
	inst.components.equippable:SetOnUnequip(function(inst, owner)
		owner:RemoveTag("lf_bati")
	end)
end)
-----------------------
local evess = nil
local atta = EventHandler("attacked", function(inst, data)
	if not inst.components.health:IsDead() then
		if inst.sg:HasStateTag("sleeping") or (inst.components.freezable and inst.components.freezable:IsFrozen()) then
			return evess ~= nil and evess.fn ~= nil and evess.fn(inst, data)
		elseif inst.components.inventory:ArmorHasTag("heavyarmor") then--青木以前的预留,物品有:heavyarmor标记就返回,萌服重甲标记
			return
		elseif inst:HasTag("lf_bati") then
			return
		end
	end
	return evess ~= nil and evess.fn ~= nil and evess.fn(inst, data)
end)
AddStategraphPostInit("wilson", function(sg)
	evess = sg.events["attacked"]
	sg.events["attacked"] = atta
end)
-----------------------

--防水护符
AddPrefabPostInit("rg_amulet007", function(inst)
	inst.abilityid = 2

	inst:AddComponent("waterproofer")
	inst.components.waterproofer:SetEffectiveness(1)
end)

--狂暴护符
AddPrefabPostInit("rg_amulet008", function(inst)
	inst:AddTag("rechargeable")
	inst:AddComponent("useableitem")
	inst.components.useableitem:SetOnUseFn(function(inst)
		if inst.components.rechargeable and inst.components.rechargeable.recharging == true then
			return
		end
		local owner = inst.components.inventoryitem.owner
		if owner then
			owner.healthdebuff = owner:DoPeriodicTask(1, function()
				owner.components.health:DoDelta(-5)
			end)
			local combat = owner.components.combat
			if combat then
				combat.damagemultiplier = combat.damagemultiplier + 0.5
				owner:DoTaskInTime(30, function(inst)
					combat.damagemultiplier = combat.damagemultiplier - 0.5
					if owner.healthdebuff then
						owner.healthdebuff:Cancel()
						owner.healthdebuff = nil
					end
				end)
			end
			inst.components.rechargeable:StartRecharging()
		end
	end)
	
	inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetRechargeTime(50)
	inst.components.rechargeable:SetRechargeRate(ratefn)
	inst.components.rechargeable.onstartrecharging = onstart
	inst.components.rechargeable.onstoprecharging = onstop
end)

--万能护符
AddPrefabPostInit("rg_amulet009", function(inst)

	--关闭所有功能
	local function UpdataItemFnOFF(inst, owner)
		local owner = owner or inst.components.inventoryitem.owner or nil
		if owner ~=nil then
			for i=1, 6 do
				-- local item = inst.components.container:GetItemInSlot(i)
				-- if item and item.abilityid then
					DoAbility[2][i](inst, owner)
				-- end
			end			
		end
	end
	--检测并打开所有功能
	local function UpdataItemFnON(inst, owner)
		-- if inst and owner and owner:HasTag("player") and owner.components then
		local owner = owner or inst.components.inventoryitem.owner or nil
		if owner ~=nil then
			UpdataItemFnOFF(inst, owner)--先初始化全关闭
			--在执行所有检测到的应该有的功能
			for i=1, 6 do
				local item = inst.components.container:GetItemInSlot(i)
				if item and item.abilityid then
					DoAbility[1][item.abilityid](inst,owner)
				end
			end
		end
	end
	local function OnItemGet(inst, data)
		if data.item ~= nil and data.item.abilityid then
			local owner = inst.components.inventoryitem.owner
			DoAbility[1][data.item.abilityid](inst, owner)
		end
	end

	local function OnItemLose(inst, data)
		if inst then
			local owner = inst.components.inventoryitem.owner
			UpdataItemFnON(inst, owner)
		end
	end
	
	inst:AddComponent("container")
	inst.components.container:WidgetSetup("rg_amulet")
	
	inst:AddComponent("waterproofer")
	inst.components.waterproofer:SetEffectiveness(0)
	--卸载装备时
	inst.components.equippable.onunequipfn = function(inst, owner)
		inst.components.container:Close(owner)--ByLaolu 2021-06-13 修复卡UI问题	
		UpdataItemFnOFF(inst, owner)
	end
	--穿戴装备时
	inst.components.equippable.onequipfn = function(inst, owner)
		inst.components.container:Open(owner)--ByLaolu 2021-06-13 修复卡UI问题
		UpdataItemFnON(inst, owner)
	end
	--打开容器时执行
	-- inst:ListenForEvent("onopen", UpdataItemFnON )
	--关闭容器时执行
	-- inst:ListenForEvent("onclose", function(inst,data)
		-- DoAbility[2][1](inst,data.doer)
	-- end)
	
	
	inst:ListenForEvent("itemget", OnItemGet )
	inst:ListenForEvent("itemlose", OnItemLose )
	
end)
--逻辑补偿,玩家初始化时的逻辑
AddPlayerPostInit( function(inst)
	--有装备万能护符时,初始化的处理
	local item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.NECK)
	if item and item.prefab == "rg_amulet009" then
		inst.components.inventory:Equip(item)
		-- item.components.container:Close()
	end
end)
--]]


local cantpickli = {	--不可拾取列表
	["er_mould013"] = true,				--铸造核心·传说 剑
	["er_mould023"] = true,				--铸造核心·传说 矛
	["er_mould033"] = true,				--铸造核心·传说 弓
	["er_mould043"] = true,				--铸造核心·传说 镰
	["er_mould053"] = true,				--铸造核心·传说 刀
	["er_mould063"] = true,				--铸造核心·传说 斧
	["er_mould073"] = true,				--铸造核心·传说 杖
	--[[	["er_mould012"] = true,				--铸造核心·史诗 剑
        ["er_mould022"] = true,				--铸造核心·史诗 矛
        ["er_mould032"] = true,				--铸造核心·史诗 弓
        ["er_mould042"] = true,				--铸造核心·史诗 镰
        ["er_mould052"] = true,				--铸造核心·史诗 刀
        ["er_mould062"] = true,				--铸造核心·史诗 斧
        ["er_mould072"] = true,				--铸造核心·史诗 杖
        ["er_mould011"] = true,				--铸造核心·经典 剑
        ["er_mould021"] = true,				--铸造核心·经典 矛
        ["er_mould031"] = true,				--铸造核心·经典 弓
        ["er_mould041"] = true,				--铸造核心·经典 镰
        ["er_mould051"] = true,				--铸造核心·经典 刀
        ["er_mould061"] = true,				--铸造核心·经典 斧
        ["er_mould071"] = true,				--铸造核心·经典 杖]]
	["yellow1"] = true,
	["yellow2"] = true,
	["yellow3"] = true,
	["yellow4"] = true,
	["yellow5"] = true,
	["yellow6"] = true,
	["purple1"] = true,
	["purple2"] = true,
	["purple3"] = true,
	["purple4"] = true,
	["purple5"] = true,
	["purple6"] = true,
	["green1"] = true,
	["green2"] = true,
	["green3"] = true,
	["green4"] = true,
	["green5"] = true,
	["green6"] = true,
	["orange1"] = true,
	["orange2"] = true,
	["orange3"] = true,
	["orange4"] = true,
	["orange5"] = true,
	["orange6"] = true,
	["colour1"] = true,
	["colour2"] = true,
	["colour3"] = true,
	["colour4"] = true,
	["colour5"] = true,
	["colour6"] = true,
	["black1"] = true,
	["black2"] = true,
	["black3"] = true,
	["black4"] = true,
	["black5"] = true,
	["black6"] = true,
	--	["er_drawing001"] = true,			--图纸经典
	--	["er_drawing002"] = true,			--图纸史诗
	["er_drawing003"] = true,			--图纸传说
	--	["er_ore001"] = true,				--矿石
	--	["er_ore002"] = true,				--矿石
	--	["er_ore003"] = true,				--矿石
	--	["er_ore004"] = true,				--矿石
	--	["er_ore005"] = true,				--矿石
	--	["er_ore006"] = true,				--矿石
	--	["er_ore007"] = true,				--矿石
	--	["er_ore008"] = true,				--矿石
	--	["er_ore009"] = true,				--矿石
	["er_sundries001"] = true,			--生命の刻印
	["er_sundries002"] = true,			--复活の刻印
	["er_sundries003"] = true,			--湖泊种子
	["er_sundries004"] = true,			--冷火种子
	["er_sundries005"] = true,			--暖火种子
	--	["er_sundries009"] = true,			--经验药水*小
	--	["er_sundries010"] = true,			--经验药水*大
	["er_sundries011"] = true,			--解绑珠
	--	["er_sundries012"] = true,			--魔晶
	--	["er_sundries013"] = true,			--妖灵之心
	--	["er_sundries014"] = true,			--紫漓花
	["er_sundries015"] = true,			--玲珑玉
	["er_sundries016"] = true,			--炎阳纹章
	["er_sundries017"] = true,			--火龙精粹
	--	["er_sundries018"] = true,			--棉布
	--	["er_sundries019"] = true,			--雨丝棉
	--	["er_sundries020"] = true,			--云中锦
	--	["er_sundries021"] = true,			--初级超限卷
	--	["er_sundries022"] = true,			--中级超限卷
	["er_sundries023"] = true,			--高级超限书
	["er_sundries024"] = true,			--精灵蛛图纸
	["er_sundries025"] = true,			--魔王蛛卷轴
	["er_sundries028"] = true,			--绑定钥匙
	["er_sundries029"] = true,			--鎏金保护卡
	["er_sundries030"] = true,			--紫金保护卡
	["er_sundries031"] = true,			--猎犬雕像
	["er_sundries032"] = true,			--地龙雕像
	["er_sundries033"] = true,			--宝宝召唤卡
	["weapon101"] = true,				--剑
	["weapon102"] = true,				--剑
	["weapon103"] = true,				--剑
	["weapon104"] = true,				--剑
	["weapon105"] = true,				--剑
	["weapon201"] = true,				--矛
	["weapon202"] = true,				--矛
	["weapon203"] = true,				--矛
	["weapon204"] = true,				--矛
	["weapon205"] = true,				--矛
	["weapon301"] = true,				--弓
	["weapon302"] = true,				--弓
	["weapon303"] = true,				--弓
	["weapon304"] = true,				--弓
	["weapon305"] = true,				--弓
	["weapon401"] = true,				--镰
	["weapon402"] = true,				--镰
	["weapon403"] = true,				--镰
	["weapon404"] = true,				--镰
	["weapon405"] = true,				--镰
	["weapon501"] = true,				--刀
	["weapon502"] = true,				--刀
	["weapon503"] = true,				--刀
	["weapon504"] = true,				--刀
	["weapon505"] = true,				--刀
	["weapon601"] = true,				--斧
	["weapon602"] = true,				--斧
	["weapon603"] = true,				--斧
	["weapon604"] = true,				--斧
	["weapon605"] = true,				--斧
	["weapon701"] = true,				--杖
	["weapon702"] = true,				--杖
	["weapon703"] = true,				--杖
	["weapon704"] = true,				--杖
	["weapon705"] = true,				--杖
	["rg_armor001"] = true,				--震退护甲
	["rg_armor002"] = true,				--寒冰护甲
	["rg_armor003"] = true,				--尖牙护甲
	["rg_helmet001"] = true,			--猎鹰盔
	["rg_helmet002"] = true,			--石王冠
	["rg_helmet003"] = true,			--银角冠
	["pweapon001"] = true,				--
	["pweapon002"] = true,				--
	["pweapon003"] = true,				--定制弓
	["pweapon004"] = true,				--
	["pweapon005"] = true,				--
	["pweapon006"] = true,				--
	["pweapon007"] = true,				--
	["pweapon008"] = true,				--
	["pweapon009"] = true,				--定制刀
	["rg_bag001"] = true,				--背包
	["rg_bag002"] = true,				--背包
	["rg_bag003"] = true,				--背包
	["rg_bag004"] = true,				--背包
	["rg_bag005"] = true,				--背包
	["rg_bag006"] = true,				--背包
	["rg_bag007"] = true,				--背包
	["rg_bag008"] = true,				--背包
	["rg_bag008"] = true,				--背包
	["lf_drug011_1"] = true,				--经验药水LV1
	["lf_drug011_2"] = true,				--经验药水LV2
	["lf_drug011_3"] = true,				--经验药水LV3
	["lf_drug010_1"] = true,				--觉醒秘药LV1
	["lf_drug010_2"] = true,				--觉醒秘药LV2
	["lf_drug010_3"] = true,				--觉醒秘药LV3
	["er_awaken001"] = true,			--技能书
	["er_awaken002"] = true,			--技能书
	["er_awaken003"] = true,			--技能书
	["er_awaken004"] = true,			--技能书
	["er_awaken005"] = true,			--技能书
	["er_awaken006"] = true,			--技能书
	["er_awaken007"] = true,			--技能书
	["er_awaken008"] = true,			--技能书
	["er_awaken009"] = true,			--技能书
	["rg_pifu001"] = true,				--皮肤
	["rg_pifu002"] = true,				--皮肤
	["rg_pifu003"] = true,				--皮肤
	["rg_pifu005"] = true,				--皮肤
	["rg_pifu005"] = true,				--皮肤
	["rg_pifu006"] = true,				--皮肤
	["rg_pifu007"] = true,				--皮肤
	["er_fishingrod"] = true,			--超级鱼竿
	["erg_giftbag001"] = true,			--金币礼包
}
--
AddPrefabPostInit("rg_amulet010", function(inst)
	inst:AddTag("rg_hengwen")
	inst:AddTag("skillchange")
	inst.abilityid = 1	--添加护符功能类id定义:恒温
	inst:AddComponent("rgwuqi")
	inst.components.equippable.walkspeedmult = 1.25

	inst.components.equippable.onunequipfn = function(inst, owner)
		if inst.picktask then
			inst.picktask:Cancel()
			inst.picktask = nil
			inst.amulet_fx:Remove()
		end
		DoAbility[2][inst.abilityid](inst, owner)--关闭恒温效果
	end
	--穿戴装备时
	inst.components.equippable.onequipfn = function(inst, owner)
		DoAbility[2][inst.abilityid](inst, owner)	--关闭1次恒温效果
		DoAbility[1][inst.abilityid](inst,owner)	--再开启恒温效果
	end

	local LL_PICKUP_MUST_TAGS = { "_inventoryitem" }
	local LL_PICKUP_CANT_TAGS = { "INLIMBO", "NOCLICK", "knockbackdelayinteraction", "catchable", "fire", "minesprung", "mineactive" }
	inst:ListenForEvent("skillwitch", function(inst)
		local enable = inst.skillwitch:value()
		if enable then
			local owner = inst.components.inventoryitem.owner
			local ba = owner:GetBufferedAction()--ByLaoluFix 2021-06-28 重写结构 
			inst.picktask = inst:DoPeriodicTask(TUNING.ORANGEAMULET_ICD, function(inst)--0.33
				if owner and owner.components.inventory then
					local x, y, z = owner.Transform:GetWorldPosition()
					local ents = TheSim:FindEntities(x, y, z, TUNING.ORANGEAMULET_RANGE,LL_PICKUP_MUST_TAGS,LL_PICKUP_CANT_TAGS)--4
					for i, v in ipairs(ents) do
						if v and v:IsValid() and not cantpickli[v.prefab] then--修复刷物品bug--2021-07-17
							-- if v.components.inventoryitem and v.components.inventoryitem.owner == nil
									-- and not v.components.health and owner.components.inventory:CanAcceptCount(v, 1) > 0 then
							--ByLaoluFix 2021-06-28 重写结构 
							if v.components.inventoryitem ~=nil and v.components.inventoryitem.canbepickedup and
							v.components.inventoryitem.cangoincontainer and
							owner.components.inventory:CanAcceptCount(v, 1) > 0 and
							(ba == nil or ba.action ~= ACTIONS.PICKUP or ba.target ~= v) then
							--迭代处理
								if v.components.stackable ~=nil then
									v = v.components.stackable:Get()
								end
								owner.components.inventory:GiveItem(v)
								return
							end
						end
					end
				end
			end)
			inst.amulet_fx = SpawnPrefab("amulet_fx001")
			inst.amulet_fx.Transform:SetPosition(0,1.3,0)
			inst.amulet_fx.entity:SetParent(owner.entity)
		else
			if inst.picktask then
				inst.picktask:Cancel()
				inst.picktask = nil
				inst.amulet_fx:Remove()
			end
		end
	end)
end)