--所属模块:宝宝系统
--函数**************************************
-- 移除指定文件监听方法并返回原始Fn
local function RemoveEventCallbackEx(inst, event, filepath, source)
	source = source or inst
	local old_event_key, old_event = nil, nil

	-- 移除指定监听方法
	if source.event_listeners ~= nil and source.event_listeners[event] ~= nil and source.event_listeners[event][inst] ~= nil then
		--print("find event begin")
		for i, fn in ipairs(source.event_listeners[event][inst]) do
			local info = GLOBAL.debug.getinfo(fn,"LnS")
			if string.find(info.source, filepath) then
				old_event_key = i
				old_event = fn
				break
				--print(string.format("      %s = function - %s", i, info.source..":"..tostring(info.linedefined)))
			end				
		end
		--print("find event end")
	end

	-- 移除指定监听方法
	if old_event ~= nil and source.event_listeners ~= nil and source.event_listeners[event] ~= nil and source.event_listeners[event][inst] ~= nil then
		-- source.event_listening[event][inst] = nil
		-- source.event_listeners[event][inst] = nil
		-- source.event_listening[event][inst][old_event_key] = OnEvent
		-- source.event_listeners[event][inst][old_event_key] = OnEvent
		inst:RemoveEventCallback(event, old_event, source)
	end

	return old_event
end
--说话功能
local function PlayerSay(player, msg, delay, duration, noanim, force, nobroadcast, colour)
	if player ~= nil and player.components.talker then
		player:DoTaskInTime(delay or 0.01, function ()
			player.components.talker:Say(msg, duration or 2.5, noanim, force, nobroadcast, colour)
		end)
	end
end
--通过id获取当前世界玩家
function GetTheWorldPlayerById(id)
	for _,p in pairs(AllPlayers) do
		if p.userid == id then 
			return p
		end
	end
	return nil
end
--函数结束**************************************
--暂时去掉不支持的角色 ByLaolu 2021-01-04
local original = {"wx78","wathgrithr","wolfgang","wickerbottom","wilson","webber","wendy","willow","wes","waxwell","woodie","winona","warly"}--"wortox","wormwood","wurt"}
local extend = {"rg_pifu001","rg_pifu002","rg_pifu003","rg_pifu004","rg_pifu005","rg_pifu006","rg_pifu007"}
--c_give"charcoal"(木炭)			--移除宝宝
--c_give"plantmeat"(食人花肉)
--c_give"cactus_meat"(仙人掌肉)
-- c_give"seafoodgumbo"--海鲜秋葵汤
-- DST_CHARACTERLIST =

-- 处理宝宝残留物
AddPrefabPostInit("pigguard", function(inst)
	local OldOnSave=inst.OnSave
	inst.OnSave = function(inst,data)
		if OldOnSave~=nil then
			OldOnSave(inst,data)
		end
		if inst.babydata ~= nil then
			data.isbaby = true
		end
	end
	
	local OldOnLoad=inst.OnLoad
	inst.OnLoad = function(inst,data)
		if OldOnLoad~=nil then
			OldOnLoad(inst,data)
		end
		if data ~= nil and data.isbaby then
			inst:DoTaskInTime(0, function(inst)
				inst:Remove()
			end)
		end
	end
end)

-- 处理青蛙攻击宝宝不掉落
AddPrefabPostInit("frog", function(inst)
	local old_OnHitOtherFn = inst.components.combat.onhitotherfn
	inst.components.combat.onhitotherfn = function(inst, other, damage)
		if other.babydata ~= nil then return end
		if old_OnHitOtherFn ~= nil then
			old_OnHitOtherFn(inst, other, damage)
		end
	end
end)

-- 处理宝宝击杀影怪给主人回脑残
local shadow_table = {
	"crawlinghorror",     -- 暗影爬行怪
	"terrorbeak",         -- 巨喙梦魇
}

local function GetBabyLeader(inst)
	return inst.components.follower.leader or GetTheWorldPlayerById(inst.babydata.userid)
end

local function ShadowKilledByOtherFn(inst)
	local old_OnKilledByOtherFn = inst.components.combat.onkilledbyother
	inst.components.combat.onkilledbyother = function(inst, attacker)
		if attacker and attacker.babydata ~= nil then
			local leader = GetBabyLeader(attacker)
			if leader and leader.components.sanity then
				leader.components.sanity:DoDelta(inst.sanityreward or TUNING.SANITY_SMALL)
			end
		elseif old_OnKilledByOtherFn ~= nil then
			old_OnKilledByOtherFn(inst, attacker)
		end
	end
end

for k,name in pairs(shadow_table) do
	AddPrefabPostInit(name, ShadowKilledByOtherFn)
end

--从岩穴获得宝宝
AddPrefabPostInit("critterlab", function(inst)
	inst:AddComponent("trader")

	inst.components.trader:SetAcceptTest(function(inst, item, giver)
		local combaby = giver.components.gd_playerbaby
		if item.prefab == "er_sundries033" and combaby then
			if combaby.baby == nil and combaby._respawntask == nil then
				return true
			end
			PlayerSay(giver, "我做不到,只能换一个宝宝")
		end
		--给予木炭删除宝宝
		if combaby and item.prefab == "charcoal" then
			return true
		end
	end)

	local old_onaccept = inst.components.trader.onaccept
	inst.components.trader.onaccept = function(inst, giver, item)
		local combaby = giver.components.gd_playerbaby
		--删除宝宝 
		if item.prefab == "charcoal" then
			----------------------------ByLaoluFix 2021-06-14 修复宝宝一直以来遗留的删除错误
			--DEBUG:
			-- if ThePlayer.components.gd_playerbaby.baby == nil then print("宝宝无") else print("宝宝有") end
			
			----------------------------
			-- inst:DoTaskInTime(20/30, function(inst, item, giver)
				--如果玩家有宝宝,且宝宝存活时
				if combaby then
					if combaby.baby ~= nil then
						--移除前的预置设定
						
						--清空bb的装备
						local equippedTool = combaby.baby.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
						if equippedTool ~=nil then 
							combaby.baby.components.inventory:DropItem( combaby.baby.components.inventory:Unequip(EQUIPSLOTS.HANDS))
						end
						local equippedbody = combaby.baby.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
						if equippedbody ~=nil then
							combaby.baby.components.inventory:DropItem(combaby.baby.components.inventory:Unequip(EQUIPSLOTS.BODY) )
						end
						local equippedhead = combaby.baby.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
						if equippedhead ~=nil then 
							combaby.baby.components.inventory:DropItem(combaby.baby.components.inventory:Unequip(EQUIPSLOTS.HEAD) )
						end
						--东西全给老子扔出来
						combaby:DropAll()
						------清空bb的装备
						if combaby.equipslots ~=nil then
						-- TheNet:Announce("run1")
							combaby.equipslots = {
								["HANDS"]=nil,	--weapon 	武器
								["BODY"]=nil,	--body		衣服
								["HEAD"]=nil,	--hat		头盔
								--..TODO:添加其他装备插槽
							}
						end
						if combaby.baby.equipslots then
							for i,v in pairs(combaby.baby.equipslots) do
								-- TheNet:Announce("run..")
								if v ~=nil then v =nil end	
							end
						end
						combaby:SaveData(true)
						
						combaby.sysRemove = true	
						combaby.baby:Remove()
						if combaby.babydata.prefab ~= nil then combaby.babydata.prefab = nil end
						
						------清空bb的装备 end
						if combaby._respawntask ~=nil then
							combaby:StopRespawnTimer()
						end
						--重置玩家状态
						if combaby.baby then
							combaby.baby = nil
						end
						combaby.sysRemove = false
						combaby._respawntask = nil
						
						PlayerSay(giver, "我好不忍心啊~宝贝额,再见了~!")
					else
						if old_onaccept ~= nil then old_onaccept(inst, giver, item) end
					end
				else
					if old_onaccept ~= nil then old_onaccept(inst, giver, item) end
				end
				
			-- end, item, giver)
			----------------------------
		end
		if item.prefab == "er_sundries033" and combaby and combaby.baby == nil and combaby._respawntask == nil then
			--生成宝宝
			inst:DoTaskInTime(20/30, function(inst, item, giver)
				if math.random() < 0.1 then		--10%概率获得皮肤
					combaby:MakePlayer(extend[math.random(1,#extend)])
				else
					combaby:MakePlayer(original[math.random(1,#original)])
				end
			end, item, giver)
		elseif old_onaccept ~= nil then
			old_onaccept(inst, giver, item)
		end
	end
end)

AddPlayerPostInit(function(inst)
	inst:AddComponent("gd_playerbaby")

	local old_OnDespawn = inst._OnDespawn
	function inst._OnDespawn(inst, ...)
		if old_OnDespawn then
			old_OnDespawn(inst, ...)
		end
		inst.components.gd_playerbaby:SaveData()
	end

	local old_OnSleepIn = inst.OnSleepIn
	local old_OnWakeUp = inst.OnWakeUp
	function inst.OnSleepIn(inst)
		old_OnSleepIn(inst)
		inst.hxsleep = true
		
		if inst.components.gd_playerbaby.baby and inst.components.gd_playerbaby.baby:IsValid()
		and (not inst.components.gd_playerbaby.baby.sg:HasStateTag("busy") or
			inst.components.gd_playerbaby.baby.sg:HasStateTag("frozen"))
		then
			inst.components.gd_playerbaby.baby:PushEvent("gotosleep")
		end
	end

	function inst.OnWakeUp(inst)
		old_OnWakeUp(inst)
		inst.hxsleep = false
		
		if inst.components.gd_playerbaby.baby and inst.components.gd_playerbaby.baby:IsValid()
		and (inst.components.gd_playerbaby.baby.sg:HasStateTag("sleeping") or
			inst.components.gd_playerbaby.baby.sg:HasStateTag("bedroll") or
			inst.components.gd_playerbaby.baby.sg:HasStateTag("tent") or
			inst.components.gd_playerbaby.baby.sg:HasStateTag("waking"))
		then
			inst.components.gd_playerbaby.baby:PushEvent("wakeup")
		end
	end

	-- 当被宝宝击杀时需要显示击杀者是xxx的宝宝而不是猪人守卫
	local old_deathFn = RemoveEventCallbackEx(inst, "death", "scripts/prefabs/player_common.lua")
	if old_deathFn ~= nil then
		local function OnPlayerDeath(inst, data)
			if data ~= nil and data.afflicter ~= nil and data.afflicter.babydata ~= nil then
				data.afflicter.overridepkname = data.afflicter.name
			end

			old_deathFn(inst, data)
		end

		inst:ListenForEvent("death", OnPlayerDeath)
	end

	local function OnKilled(inst, data)
		if inst.components.gd_playerbaby.baby and inst.components.gd_playerbaby.baby:IsValid() then
			data.babymaster = true
			inst.components.gd_playerbaby.baby:PushEvent("killed", data)
		end
	end
	inst:ListenForEvent("killed", OnKilled)
end)

AddPrefabPostInitAny(function(inst)
	if inst.components.equippable ~= nil and inst.components.tradable == nil then
		inst:AddComponent("tradable")
	end
end)

-- 查看物品
local old_LOOKAT = ACTIONS.LOOKAT.fn 
ACTIONS.LOOKAT.fn = function(act)
	if act.target and act.target.babydata ~= nil then
		PlayerSay(act.doer, act.target.GetBabyInfoString())
		return true
	end
	
	return old_LOOKAT(act)
end

--钓鱼行为入侵
local old_FISH = ACTIONS.FISH.fn
ACTIONS.FISH.fn = function(act)
	if act.doer and act.doer.babydata ~=nil then
		local fishtool = nil
		if act.doer.components.inventory then
			fishtool = act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
			if fishtool and fishtool.components.fishingrod then
				--print("开始钓鱼")
				fishtool.components.fishingrod:StartFishing(act.target, act.doer)
			end
		end
		return true
		-- if fishtool and fishtool.components.fishingrod then
			-- local fishingrod = fishtool.components.fishingrod
			-- fishingrod:StartFishing(act.target, act.doer)
			-- print("宝宝钓鱼OK")
			-- return true
		-- end
	end
	return old_FISH(act)
end