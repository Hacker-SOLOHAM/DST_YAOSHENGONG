AddPrefabPostInit("rg_giftbag001",function(inst)
	inst:AddComponent("unwrappable")
	inst.components.unwrappable:SetOnUnwrappedFn(function(inst, pos, doer)
		doer:AddQMYXB(1,100000)
		doer.components.talker:Say("获得100000金币!")
		inst:Remove()
	end)
end)

AddPrefabPostInit("rg_giftbag008",function(inst)
	inst:AddComponent("unwrappable")
	inst.components.unwrappable:SetOnUnwrappedFn(function(inst, pos, doer)
		local item1 = SpawnPrefab("weapon103")
		local rgwuqi = item1.components.rgwuqi
		rgwuqi.pin = 2
		local item2 = SpawnPrefab("surfnturf")
		local item3 = SpawnPrefab("er_sundries008")
		local item4 = SpawnPrefab("er_fishingrod")
		local inventory = doer.components.inventory
		if inventory then
			inventory:GiveItem(item1)
			inventory:GiveItem(item2)
			inventory:GiveItem(item3)
			inventory:GiveItem(item4)
		end
		inst:Remove()
	end)
end)
--ByLaolu 2021-06-03
local function BatPress(prefab)
	AddPrefabPostInit(prefab,function(inst)
		local giftlists = {}
		--可以被抽到的武器库(灵服全部武器)----------------------
		--table.insert(giftlists, "final_weapon")--终极武器.禁止随便获取
		for i=1,5 do
			table.insert(giftlists, string.format("weapon1%02d",i))
			table.insert(giftlists, string.format("weapon2%02d",i))
			table.insert(giftlists, string.format("weapon3%02d",i))
			table.insert(giftlists, string.format("weapon4%02d",i))
			table.insert(giftlists, string.format("weapon5%02d",i))
			table.insert(giftlists, string.format("weapon6%02d",i))
			table.insert(giftlists, string.format("weapon7%02d",i))
		end
		--专属定制武器,禁止随便抽取
		-- for i=1,10 do
			-- table.insert(giftlists, string.format("pweapon%03d",i))
		-- end
		----------------------------------------------------------
		--逻辑处理
		if inst.components.unwrappable == nil then inst:AddComponent("unwrappable") end --安全防护
		--礼包打开后的逻辑
		inst.components.unwrappable:SetOnUnwrappedFn(function(inst, pos, doer)
			--随机属性设置
			local id = math.random(1,#giftlists)	--礼物内随机武器
			--礼物内武器的随机属性定义
			local dmg =  0			--攻击力
			local pin =  0			--品阶
			if inst.prefab == "rg_giftbag002" then dmg = math.ceil(math.random(120,160));pin = 1		--84-114
			elseif inst.prefab == "rg_giftbag003" then dmg = math.ceil(math.random(160,200));pin = 2	--128-160
			elseif inst.prefab == "rg_giftbag004" then dmg = math.ceil(math.random(180,240));pin = 3	--162-216
			elseif inst.prefab == "rg_giftbag005" then dmg = math.ceil(math.random(300,400));pin = 4	--200-300
			elseif inst.prefab == "rg_giftbag006" then dmg = 1000;pin = 4
--			elseif inst.prefab == "rg_giftbag007" then dmg = math.ceil(math.random(150,300));pin = math.random(3,4)	
			end
			
			local ron =  0			--增幅值
			local rank = 1			--系数
			
			local item = nil
			if inst.prefab == "rg_giftbag006" then item = SpawnPrefab("final_weapon") else item = SpawnPrefab(giftlists[id]) end
			local rgwuqi = item.components.rgwuqi
			local instcom = item.components
			if instcom ~=nil and instcom.rgwuqi ~=nil and instcom.weapon ~=nil then
				item:set(dmg,pin,ron,rank)	--重定义武器属性 攻击力/品阶/增幅值/系数
			end
			--发放逻辑
			local inventory = doer.components.inventory
			if inventory then
				inventory:GiveItem(item)
			end
			inst:Remove()
		end)
	end)
end
--添加这个礼包物品
-- ..\mods\er_modular_client\scripts\prefabs\rg_giftbags.lua
--访问和设置礼包属性等
local CustomGiftTab = {"rg_giftbag002","rg_giftbag003","rg_giftbag004","rg_giftbag005","rg_giftbag006",}
for k,v in pairs(CustomGiftTab) do
	BatPress(v)
end


























