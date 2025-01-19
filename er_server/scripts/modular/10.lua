--所属模块:建筑
--ByLaoluFix 重构
-- 全局配置
--------------------------------------------------------------------
local ZENGFU_GAILV = 0.3 --增幅成功的概率.默认值 30%概率成功(取值范围:0-1浮点数)
--------------------------------------------------------------------
local worldname = GetModConfigData("worldname")

local monster_list = {
	knight = 40,			--发条骑士
	bishop = 30,			--发条主教
	rook = 25,				--发条战车
	merm = 20,				--鱼人
	spider_warrior = 15,	--蜘蛛战士
	nightmarebeak = 10,		--尖嘴暗影怪
	-- rg_kulou001 = 5,			--骷髅1
	-- rg_kulou002 = 5,			--骷髅2
	worm = 15,				--蠕虫
	deerclops = 1,			--巨鹿
	bearger = 1,			--熊獾
	-- moose = 1,				--麋鹿鹅
	--minotaur = 1,			--远古犀牛
	dragonfly = 1,			--龙蝇
}
local monsterboss_list = {
	deerclops = 1,			--巨鹿
	bearger = 1,			--熊獾
	-- moose = 1,				--麋鹿鹅
	--minotaur = 1,			--远古犀牛
	dragonfly = 1,			--龙蝇
}

--极难附魔设置
local chanceli = {
	--成功率:附魔石1-10等级,升级装备附魔1-10等级对应概率
	{ 0.5, 0.3, 0.2, 0.15, 0.1, 0.05, 0.03, 0.01, 0.005, 0.001},--1级附魔石 升级装备附魔1-10等级对应概率
	{0, 0.5, 0.3, 0.2, 0.15, 0.1, 0.05, 0.03, 0.01, 0.005, 0.001},--2级附魔石
	{0,0, 0.5, 0.3, 0.2, 0.15, 0.1, 0.05, 0.03, 0.01, 0.005, 0.001},--3级附魔石
	{0,0,0, 0.5, 0.3, 0.2, 0.15, 0.1, 0.05, 0.03, 0.01, 0.005, 0.001},--4级附魔石
	{0,0,0,0, 0.5, 0.3, 0.2, 0.15, 0.1, 0.05, 0.03, 0.01, 0.005, 0.001},--5级附魔石
	{0,0,0,0,0, 0.5, 0.3, 0.2, 0.15, 0.1, 0.05, 0.03, 0.01, 0.005, 0.001},--6级附魔石
	{0,0,0,0,0,0, 0.5, 0.3, 0.2, 0.15, 0.1, 0.05, 0.03, 0.01, 0.005, 0.001},--7级附魔石
	{0,0,0,0,0,0,0, 0.5, 0.3, 0.2, 0.15, 0.1, 0.05, 0.03, 0.01, 0.005, 0.001},--8级附魔石
	{0,0,0,0,0,0,0,0, 0.5, 0.3, 0.2, 0.15, 0.1, 0.05, 0.03, 0.01, 0.005, 0.001},--9级附魔石
	{0,0,0,0,0,0,0,0,0, 0.5, 0.3, 0.2, 0.15, 0.1, 0.05, 0.03, 0.01, 0.005, 0.001},--10级附魔石
}
--主机接受指令
if not TheNet:GetIsClient() then
	AddModRPCHandler("ER_WORKSHOP", "doworkshop", function(player, inst, key)
		--屏蔽处理玩家高频发
		if player:HasTag("frequently") then
			player.components.talker:Say("访问过于频繁, 请1秒后再试!")
			return
		end
		player:AddTag("frequently")
		player:DoTaskInTime(1, function(inst)
			inst:RemoveTag("frequently")
		end)
		------
		local x,y,z = inst.Transform:GetWorldPosition()
		local container = inst.components.container
		--制造方法
		if key == "domake" then
			container:Close(player)
			if inst.components.er_make.makeitem ~= "nothing" then
				SpawnPrefab("er_tips_label"):set("机器正在运作呢!", 1).Transform:SetPosition(x,y,z)
				return
			end
			local er_leave = player.components.er_leave
			local extractlevel = er_leave and er_leave.extractlevel or 1
			inst.components.er_make:StartMake(extractlevel)
		--献祭方法
		elseif key == "doaltar" then
			local item = container:GetItemInSlot(1)
			container:Close(player)
			
			if item ~= nil then
				if inst.OnGenerate == nil then
					local times = 10
					local num = item.components.stackable:StackSize()
					container:RemoveItemBySlot(1):Remove()
					--刷怪
					inst.OnGenerate = inst:DoPeriodicTask(times, function(inst)
						local rank = 1			--怪物品阶
						local monstertype = 0	--怪物类型
						num = num - 1			--计数减一
						--"魔晶","妖灵之心","紫漓花","玲珑玉","炎阳纹章","火龙精粹"
						local monstername = weighted_random_choice(monster_list)
						if item.strengthen == 0 then		--随机怪物
							rank = 0
							monstertype = 1
						elseif item.strengthen == 1 then	--随机精灵
							rank = 1
							monstertype = 1
						elseif item.strengthen == 2 then	--随机妖精
							rank = 2
							monstertype = 2
						elseif item.strengthen == 3 then	--随机妖王
							rank = 3
							monstertype = 2
						elseif item.strengthen == 4 then	--随机魔王
							rank = 3
							monstertype = 3
						elseif item.strengthen == 5 then	--随机魔王BOSS
							rank = 4
							monstertype = 3
							monstername = weighted_random_choice(monsterboss_list)
						end
						
						local monster = SpawnPrefab(monstername)
						monster.master = player.userid		--主人
						local pos = inst:GetPosition()
						
						local offset = FindValidPositionByFan(2 * PI * math.random(), 9, 36, function(offsets)
							local pt = Vector3(x + offsets.x, 0, z + offsets.z)
							return TheWorld.Map:IsPassableAtPoint(pt:Get())
								and not TheWorld.Map:IsPointNearHole(pt)
						end)
						if offset ~= nil then
							pos = pos + offset
						end
						monster.Transform:SetPosition(pos:Get())
						
						if monster.components.rg_guaiwu == nil then
							monster:AddComponent("rg_guaiwu")
						end
						monster.components.rg_guaiwu.monstertype = monstertype
						monster.components.rg_guaiwu:Suiji(rank)
			
						--怪物周边120秒无人则自动消失
						monster:DoPeriodicTask(120, function(inst)
							local x, y, z = inst.Transform:GetWorldPosition()
							local ents = TheSim:FindEntities(x, 0, z, 25, {"player"})
							if #ents <= 0 and not inst:HasTag("tooanger") then
								inst:Remove()
							end
						end)
						
						--计数低于1清除刷怪
						if num <= 0 then
							if inst.OnGenerate then
								inst.OnGenerate:Cancel()
								inst.OnGenerate = nil
							end
							inst.AnimState:PlayAnimation("close")
						end
					end)
					inst.AnimState:PlayAnimation("open",true)
				else
					SpawnPrefab("er_tips_label"):set("怪物祭坛正在生成怪物!", 1).Transform:SetPosition(x,y,z)
				end
			end
		--增幅方法
		elseif key == "doqualityup" then
			local x,y,z = inst.Transform:GetWorldPosition()
			local container = inst.components.container
			local item1 = container:GetItemInSlot(1)--物品
			local item2 = container:GetItemInSlot(2)--增幅书
			local item3 = container:GetItemInSlot(3)--保护卡
			
			--处理批量增幅
			--武器和增幅书
			if item1 and item2 then
				local rgwuqi = item1.components.rgwuqi
				-- if rgwuqi.weapon then
				--ByLaoluFix 2021-06-05 修复无效和安全漏洞
				if rgwuqi then
					-- TheWorld:PushEvent("ms_sendlightningstrike", Vector3(x,y,z))		--降下闪电
					local size1 = 1
					local n1,n2 =0,0 --成功与失败数量
					if item2.components.stackable then
						size1 = item2.components.stackable:StackSize()
						item2.components.stackable:Get(size1):Remove()
					end

					local function overrunon()		--增幅成功
						n1 = n1+1
						rgwuqi:DoRise(0.1)
						-- SpawnPrefab("er_tips_label"):set("增幅成功!", 1).Transform:SetPosition(x,y,z)
						-- TheNet:Announce("恭喜玩家【" .. player:GetDisplayName() .."】在 ★ "..worldname.." ★ 武器增幅成功,当前攻击系数为"..rgwuqi.dmgrank.."!")
					end
					local function overrunoff()	--增幅失败
						n2 = n2+1
						if rgwuqi.dmgrank > 0 then
							rgwuqi:DoRise(-0.1)
						end
						-- SpawnPrefab("er_tips_label"):set("增幅失败!", 1).Transform:SetPosition(x,y,z)
						-- player.components.health:DoDelta(-99999, nil, "er_workshop006", true, nil, true)	--玩家死亡
						-- TheNet:Announce("玩家【" .. player:GetDisplayName() .."】在 ★ "..worldname.." ★ 武器增幅失败,当前攻击系数为"..rgwuqi.dmgrank.."!")
					end
					
					if size1 > 0 then
						for i=1,size1 do
							--保护券消耗(2.8以下无惩罚)
							local p1,p2 = true,true
							if item3 and item3.overrun and item3:IsValid() then
								-- if item3.overrun == "on" then	--紫金卡直接增幅
									-- overrunon()
									-- p1 = false
								-- end
								--武器增幅大于2.8的处理
								if rgwuqi.dmgrank then 
									if rgwuqi.dmgrank >= 2.8 then
										if item3.overrun == "on" then	--紫金卡直接增幅
											overrunon()
											p1 = false
										end
										--大于2.8的时候进行惩罚
										if item3.overrun =="off" then
											-- SpawnPrefab("er_tips_label"):set("增幅失败!有保护卡,不进行惩罚!", 1).Transform:SetPosition(x,y,z)--失败保护卡
											p2 = false
										end	
										--移除的处理
										if item3.components.stackable and item3.components.stackable:IsStack() then
											-- TheNet:Announce("移除紫金卡1")
											item3.components.stackable:Get():Remove()
										else
											-- TheNet:Announce("移除紫金卡2")
											item3:Remove()
										end
									end
								end
							end
							if p1 == true then
								if math.random() > ZENGFU_GAILV then
									-- TheNet:Announce("失败")
									if rgwuqi.dmgrank and rgwuqi.dmgrank >= 2.8 then
										if p2 == true then--失败保护卡
											overrunoff()
										end
									end
								else
									-- TheNet:Announce("成功")
									overrunon()
								end
							end
							--无保护手段增幅,10%成功
							-- if p == true then		
								-- if math.random() < 0.9 then
									-- overrunoff()
								-- else
									-- overrunon()
								-- end
							-- end
						end
						SpawnPrefab("er_tips_label"):set("增幅成功:"..n1.."次.".."增幅失败:"..n2.."次", 1).Transform:SetPosition(x,y,z)
						TheNet:Announce("玩家【" .. player:GetDisplayName() .."】在 ★ "..worldname.." ★ 武器增幅处理,当前攻击系数为"..rgwuqi.dmgrank.."!")
					end
					--[[
					--保护券消耗(2.8以下无惩罚)
					if item3 and item3.overrun then
						if rgwuqi.dmgrank and rgwuqi.dmgrank >= 2.8 then
							if item3.components.stackable and item3.components.stackable:IsStack() then
								item3.components.stackable:Get():Remove()
							else
								item3:Remove()
							end
						end
						if item3.overrun=="on" then			--紫金卡直接增幅
							overrunon()
							return
						end
					end
					--无保护手段增幅
					if math.random() > 0.01 then
						if rgwuqi.dmgrank and rgwuqi.dmgrank > 2.8 then		--大于2.8的时候进行惩罚
							if item3 and item3.overrun=="off" then
								return
							end
							overrunoff()
						end
					else
						overrunon()
					end
					]]
				else
					SpawnPrefab("er_tips_label"):set("该装备不支持增幅!", 1).Transform:SetPosition(x,y,z)
				end
				--把装备还给玩家.ToDo,ByLaoluFix 2021-07-16
				--[[
				if player and player:IsValid() and player:HasTag("player") then
					-- TheNet:Announce("成功")
					local item_weapon = container:RemoveItemBySlot(1)
					if item_weapon ~=nil then TheNet:Announce("成功") else TheNet:Announce("失败") end
					player.components.inventory:GiveItem(item_weapon)
				end
				]]
				container:Close()--ByLaoluFix 2021-06-26  增幅时,关闭容器 
			end
		--锻造方法
		elseif key == "doforge" then
			container:Close()
			if inst.components.er_forge.forgeitem ~= "nothing" then
				SpawnPrefab("er_tips_label"):set("机器正在运作呢!", 1).Transform:SetPosition(x,y,z)
				return
			end
			inst.components.er_forge:StartForge()
		--解体方法
		elseif key == "doseparate" then
			return
			--转到回收容器中处理
			-- local item = container:GetItemInSlot(1)
			-- if item then
				-- local er_tlimit = item.components.er_tlimit
				-- if er_tlimit and er_tlimit.alltime then
					-- SpawnPrefab("er_tips_label"):set("限时物品无法分解哦!", 1).Transform:SetPosition(x,y,z)
				-- else
					-- local rgwuqi = item.components.rgwuqi
					-- if rgwuqi then
						-- rgwuqi:Separate(player)		--解离附魔石
						-- if rgwuqi.pin > 0 then		--品质装备解体
							-- local gemcoin = (item.weaponid or 0)*50 + (rgwuqi.pin or 0)*100 + (rgwuqi.ron or 0)*25
							-- player:AddQMYXB(3, gemcoin)
							-- SpawnPrefab("er_tips_label"):set("解体完毕!获得"..gemcoin.."宝石币!", 1).Transform:SetPosition(x,y,z)
						-- else
							-- SpawnPrefab("er_tips_label"):set("解体完毕!!", 1).Transform:SetPosition(x,y,z)
						-- end
						-- item:Remove()
					-- else
						-- SpawnPrefab("er_tips_label"):set("该物品无解体价值!", 1).Transform:SetPosition(x,y,z)
					-- end
				-- end
			-- end
		--打孔方法
		elseif key == "getslot" then
			local wuqi = container:GetItemInSlot(1)
			local item = container:GetItemInSlot(2)
			local rankli = {1,0.8,0.6,0.4,0.2}
			if wuqi and item then
				container:Close()--ByLaoluFix 2021-07-01  打孔时,关闭容器 
				if item.prefab == "er_sundries021" then
					local rgwuqi = wuqi.components.rgwuqi
					if #rgwuqi.slotli < 5 then
						if math.random() < rankli[#rgwuqi.slotli+1] then
							rgwuqi:Untie()
							SpawnPrefab("er_tips_label"):set("开孔成功!", 1).Transform:SetPosition(x,y,z)
						else
							SpawnPrefab("er_tips_label"):set("开孔失败!", 1).Transform:SetPosition(x,y,z)
						end
						item.components.stackable:Get():Remove()
					else
						SpawnPrefab("er_tips_label"):set("孔位已满!", 1).Transform:SetPosition(x,y,z)
					end
				else
					SpawnPrefab("er_tips_label"):set("请使用打孔器进行打孔!", 1).Transform:SetPosition(x,y,z)
				end
			end
		--附魔方法
		elseif key == "dotofumo" then
			--ByLaoluFix 2021-07-23 修复容器叠加作弊bug.	
			if inst == nil then return end--安全保护
			local container = nil
			container = inst.components.container
			if container == nil then return end--安全保护
			local x,y,z = inst.Transform:GetWorldPosition()
			--FixEnd 
			--DEBUG:检查容器inst对象数量
			--
			-- TheNet:Announce(inst.prefab) 
			local wuqi = container:GetItemInSlot(1)
			local item1 = container:GetItemInSlot(2)
			local item2 = container:GetItemInSlot(3)
			container:Close()
			if wuqi and item1 then
				local rgwuqi = wuqi.components.rgwuqi
				if rgwuqi.type == item1.type then
					local mold = "mold"..item1.mold
					local level = nil
					for i,v in pairs(rgwuqi.slotli) do
						if v=="" or v[1]==mold  then
							level = v[2] or 0
							break
						end
					end
					
					if level then
						if level < 10 then
							----------------------
							--ByLaoluFix 2021-07-01
							--逻辑设计:
							-- 1.附魔石等级 > 装备附魔等级,当前装备附魔等级=附魔石等级
							-- 2.有保护卡,当前装备附魔等级+1
							-- 1.无保护卡,走概率机制
							-- 3.概率机制:附魔石等级对应装备附魔等级概率表
							-- 4.无论成功,失败,都花销和扣除附魔物品\保护卡
							--step:1
							if item1.level > level then
								rgwuqi:Enchant(mold,item1.level)--高等级附魔石,直接替换装备附魔等级
								--处理附魔石的移除
								if item1.components.stackable then --附魔石
									item1.components.stackable:Get():Remove()
								else
									item1:Remove()
								end
								---
								if item2 and item2.prefab == "er_sundries022" then--附魔保护物品
									if item2.components.stackable then
										item2.components.stackable:Get():Remove()
									else
										item2:Remove()
									end
								end
								local fx = SpawnPrefab("deer_ice_burst")
								fx.Transform:SetPosition(x,y,z)
								fx.Transform:SetScale(2, 2, 2)
								SpawnPrefab("er_tips_label"):set("附魔成功!", 1).Transform:SetPosition(x,y,z)
								return
							end
							--step:2
							if item2 and item2.prefab == "er_sundries022" then--有保护的处理
								rgwuqi:Enchant(mold)
							else
								if math.random() >= chanceli[item1.level][level] then
									SpawnPrefab("er_tips_label"):set("附魔失败!", 1).Transform:SetPosition(x,y,z)
									--处理附魔石的移除
									if item1.components.stackable then --附魔石
										item1.components.stackable:Get():Remove()
									else
										item1:Remove()
									end
									return
								else
									rgwuqi:Enchant(mold)
								end
							end
							--------------------
							-- 成功后的处理.
							local fx = SpawnPrefab("deer_ice_burst")
							fx.Transform:SetPosition(x,y,z)
							fx.Transform:SetScale(2, 2, 2)
							SpawnPrefab("er_tips_label"):set("附魔成功!", 1).Transform:SetPosition(x,y,z)
							--处理附魔石和其他
							if item1.components.stackable then --附魔石
								item1.components.stackable:Get():Remove()
							else
								item1:Remove()
							end

							if item2 and item2.prefab == "er_sundries022" then--附魔保护物品
								if item2.components.stackable then
									item2.components.stackable:Get():Remove()
								else
									item2:Remove()
								end
							end
						else
							SpawnPrefab("er_tips_label"):set("该附魔等级已达到最大值!", 1).Transform:SetPosition(x,y,z)
						end
					else
						SpawnPrefab("er_tips_label"):set("没有孔位接受新附魔!", 1).Transform:SetPosition(x,y,z)
					end
				end
			end
		end
	end)

	--展示物品显示功能
	local function commodityShow(inst)
		if inst and inst.components.container then
			local container = inst.components.container
			local maxItemNum = container:GetNumSlots()
			local commodity_itemList = {}

			for i = 1, maxItemNum do						--查找容器内的所有物品
				local item = container:GetItemInSlot(i)		--当前插槽的物品
				inst.AnimState:ClearOverrideSymbol("SWAP_SIGN"..i)
				if item ~= nil and item.replica.inventoryitem ~= nil  then
					local image = item.replica.inventoryitem:GetImage()
					local build = item.replica.inventoryitem:GetHuaAtlas()
					local t = {image,build,i}
					table.insert(commodity_itemList,t)
				end
			end
			--开始显示
			for k, v in pairs(commodity_itemList) do
				if commodity_itemList ~= nil then
					if v then
						inst.AnimState:OverrideSymbol("SWAP_SIGN"..tostring(v[3]), v[2], v[1])
					end	
				end
			end
		end
	end

	AddPrefabPostInit("ll_cabinet", function(inst)
		inst:ListenForEvent("itemget", commodityShow )
		inst:ListenForEvent("itemlose", commodityShow )
	end)
end