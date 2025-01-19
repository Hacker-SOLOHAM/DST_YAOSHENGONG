--所属模块:植物/部分世界RPC
ACTIONS.CULTIVATION.fn = function(act)
	local seed = act.invobject		--种子
	local soil = act.target			--培养土
	local player = act.doer			--玩家
	if seed and soil and soil.hasplant == false then
		seed.components.cultivation:Planting(seed,soil,player)
		return true
	end
end

ACTIONS.COLLECTION.fn = function(act)
	local plant = act.target		--作物
	if plant then
		plant.components.morecrop:Collection(act.doer)
		return true
	end
end
-- ACTIONS.COLLECTION.validfn = function(act)
    -- return act.target and act.target:HasTag("mature")
-- end

--世界进入限制列表
local limitlist = { 
	{	--私人限制
		["91"] = {"KU_HQp7AzTo","KU_nLkjcp9N","KU_3RvV9QUz","KU_UH_rwZQK","KU_BwE_SY2T","KU_OfyhzlTr","KU_sv5Nu0sT","KU_A4nBAsWv","KU_3RvV9QSs","KU_0vPtVly_","KU_Ofyhzfz5"},
	},
	{	--副本世界
		["61"] = true,
	},
	{	--等级限制
		["51"] = 100,
		["52"] = 200,
		["53"] = 400,
		["54"] = 600,
		["55"] = 800,
		["56"] = 1000,
		["57"] = 1200,
		["58"] = 1400,
		["59"] = 1600,
		["60"] = 1800,
	},
}
--主机接受指令
GLOBAL.JoinForge = false
if not TheNet:GetIsClient() then
	AddModRPCHandler("ER_WORLD", "worldcheck", function(player, key, id)
		if key == "goworld" then
			--验证是否战斗
			if JoinForge then
				player.components.talker:Say("我不要做逃兵,要战斗到生命的最后一刻!")
				return
			end

			--验证世界是否属于私人(一级优先)
			local check = limitlist[1][id]
			if check then
				local result = false
				for i,v in ipairs(check) do
					if player.userid == v then
						result = true
						break
					end
				end
				--指定玩家或者管理员
				if result or player.Network:IsServerAdmin() then
					player.player_classified.goworid:set(id)
					return
				else
					player.components.talker:Say("这是别人的私人世界!")
					return
				end
			end

			--验证世界是否是副本世界(二级优先)
			local goforge = limitlist[2][id]
			if goforge then
				local today = os.date("%m月%d日",os.time())
				local result = false
				if player.components.er_leave.gotime ~= today then	--今日可前往副本
					result = true
				end
				--指定玩家或者管理员
				if result or player.Network:IsServerAdmin() then
					player.player_classified.goworid:set(id)
					return
				else
					player.components.talker:Say("今日副本前往次数已达上限，请明日再来!")
					return
				end
			end

			local level = limitlist[3][id]
			--验证世界是否有等级限制(三级优先)
			if level then
				local result = false
				if player.components.er_leave.level >= level then	--等级达到需求
					result = true
				end
				--指定玩家或者管理员
				if result or player.Network:IsServerAdmin() then
					player.player_classified.goworid:set(id)
					return
				else
					player.components.talker:Say("请将等级提升至"..level.."级再来挑战该世界!")
					return
				end
			end

			player.player_classified.goworid:set(id)
		elseif key == "joingorge" then
			if player.joinforge then
				player.joinforge.components.er_joinforge:ToJoin(player)
			end
		end
	end)
end