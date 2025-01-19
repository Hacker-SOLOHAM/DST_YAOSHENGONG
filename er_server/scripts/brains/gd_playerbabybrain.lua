--ByLaolu 2021-01-3--12
--log
--微调和优化了行为树执行的速度,微调了行为逻辑
--添加了超级鱼竿的支持,只有特定皮肤的宝宝才支持.rg_pifu001..rg_pifu007
--添加了新旧农场兼容机制的支持(废置旧农场.)
require "behaviours/wander"
require "behaviours/faceentity"
require "behaviours/gd_kiteandattack"
require "behaviours/chaseandattack"
require "behaviours/panic"
require "behaviours/follow"
require "behaviours/attackwall"
require "behaviours/standstill"
require "behaviours/leash"
require "behaviours/runaway"
require "behaviours/ll_findfarmplant" --查找新农田种子对话:INTERACT_WITH

local PlayerBabyBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

--Images will help chop, mine and fight.
local BB_HIGH_ATTACK_LEVEL = 3	--宝宝转换一般战斗技巧到高级战斗技巧的限制等级
local MIN_FOLLOW_DIST = 1		--最小跟随距离:0-1
local TARGET_FOLLOW_DIST = 4	--触发的跟随距离:6-3
local MAX_FOLLOW_DIST = 5		--最大跟随距离:8-4

local START_FACE_DIST = 3		--宝宝开始面朝主人的触发距离:6
local KEEP_FACE_DIST = 4		--宝宝保持面朝主人的触发距离:8

local KEEP_WORKING_DIST = 60	--保持工作的距离--14
-- local KEEP_WORKING_DIST2 = 30	--保持工作的距离2
local SEE_WORK_DIST = 10		--工作目标实体的距离

local KEEP_DANCING_DIST = 2		--保持跳舞的距离:10,当主人跳舞,宝宝跑向主人身边(2码范围内)跳舞

local KITING_DIST = 3			--保持风筝战斗机会的距离,	--3--12
local STOP_KITING_DIST = 5		--停止风筝战斗的距离		--5--3.4
local STOP_KITING_EX_DIST = 12	--停止加强版风筝战斗的距离	--6--0

local RUN_AWAY_DIST = 5			--逃跑的距离
local STOP_RUN_AWAY_DIST = 8	--停止逃跑的距离

local AVOID_EXPLOSIVE_DIST = 5	--规避爆炸的距离
local FERTILE_PERCEBT = 0.3		--宝宝要施肥对象的肥沃度(低于该肥沃度定义,开始对这个对象施肥行为)

local SEE_DIST = TARGET_FOLLOW_DIST -1	--宝宝照看农作物的距离

local WORK_TAGS = {}
--行为执行与过滤框架结构:使用参看下方样例
--[[
WORK_TAGS[ACTIONS.xxx] = {			--xxx,你要执行的行为标记
    tags = {"stump", "grave"},		--执行带此标记过滤的对象
	noprefabs = {flower = true,},	--不被执行的对象
	skeleton = true,				--执行的对象Prefab名称,=false表示不执行,用于临时调试更改
}
]]
WORK_TAGS[ACTIONS.DIG] = {
    tags = {
	"stump",
	"green_mushroom",
	--"grave"
	},
	prefabs = {
		-- green_mushroom = true--挖绿蘑菇
		farm_soil_debris = true,
	},
}
WORK_TAGS[ACTIONS.HAMMER] = {
    noprefabs = {
        -- 前辈骨头
        skeleton = true,
        -- scorched_skeleton = true,
        skeleton_player = true,
    },
}
--宝宝不采集的对象
WORK_TAGS[ACTIONS.PICK] = {
    noprefabs = {
        -- 花
        flower = true,
        -- 传送阵插座
        gemsocket = true,
    },
    finishCall = true,
}
--这里添加收获的对象,暂时未完成!ByLaolu TODO
WORK_TAGS[ACTIONS.HARVEST] = {
    finishCall = true,
}
--这里添加宝宝地面不进行拾取的物品(Prefab名称=true 表示不拾取)
WORK_TAGS[ACTIONS.PICKUP] = {
    notags = {
	"weapon",
	},
    noprefabs = {
        -- 萤火虫
        fireflies = true,
		gift = true	--礼物
    },
    finishCall = true,
}
--这里添加宝宝抓捕的对象
WORK_TAGS[ACTIONS.NET] = {
    fireflies = true,	--萤火虫
    butterfly = true,	--蝴蝶
	spore_small = true,	--绿色孢子
	spore_medium = true,--红色孢子
	spore_tall = true,	--蓝色孢子
	-- bee = true,			--蜜蜂--抓不得，惹祸！~~
}
--可种植的对象
WORK_TAGS[ACTIONS.PLANT] = {
    slow_farmplot = true,	--基础农田
    fast_farmplot = true,	--高级农田
	--蘑菇农场的处理要单独写处理给予机制
	--第三方mod农业,请这里添加
}
--新种植行为
--可种植的对象
WORK_TAGS[ACTIONS.PLANTSOIL] = {
	farm_soil = true,	--新农田
	--第三方mod农业,请这里添加
}
--可施肥的对象和物品定义
WORK_TAGS[ACTIONS.FERTILIZE] = {
	objprefab = {
		slow_farmplot = true,	--基础农田
		fast_farmplot = true,	--高级农田
	},
	itemprefab = {
		fertilizer = true,	--便便桶
		poop = true,		--便便(猪屎\牛粪)
		guano = true,		--鸟粪(各种鸟拉的便便,如蝙蝠或普通鸟笼里的鸟)
		spoiled_food = true,--腐烂食物
		-- 第三方mod施肥材料,请这里添加
	}
}
--可以进行钓鱼的对象\渔具判定
WORK_TAGS[ACTIONS.FISH] = {
	isfishableObj = {
		pond = true,		--普通池塘
		pond_mos = true,	--沼泽池塘
		pond_cave = true,	--洞穴池塘
		oasislake = true,	--沙漠湖泊	
	},
	fishingrods ={
		fishingrod = true,	--钓竿
		--第三方mod可钓鱼作用对象,请这里添加
		er_fishingrod = true,	--无耐久的超级钓竿
	},
	characters ={--这些角色的bb才允许使用超级鱼竿
		["rg_pifu001"] = true,
		["rg_pifu002"] = true,
		["rg_pifu003"] = true,
		["rg_pifu004"] = true,
		["rg_pifu005"] = true,
		["rg_pifu006"] = true,
		["rg_pifu007"] = true,
	},
}
--标记检测函数
local function checkTable(target, tagtable)
	if target and tagtable ~= nil then
		for i, v in ipairs(tagtable) do
			if target:HasTag(v) then
				return true	
			end
		end
		return false
	end
end
--通过id获取当前世界玩家
local function GetTheWorldPlayerById(id)
    for _,p in pairs(AllPlayers) do
        if p.userid == id then 
            return p
        end
    end
	return nil
end
-- local function ShouldKite_1(target, inst)
    -- return target ~= nil
        -- and target == inst.components.combat.target
        -- and target.components.health ~= nil
        -- and not target.components.health:IsDead()
-- end
-- local function AtAKing(inst)
	-- return inst.babydata.canAtk and ShouldKite_1(inst.components.combat.target, inst)
-- end

local function GetLeader(inst)--检测跟随的主人
    -- print("检查宝宝状态", inst.leadercmd.follow)
	-- if AtAKing(inst) then return nil end --如果宝宝在战斗,返回主人为空
    if not inst.leadercmd.follow then return nil end--跟随不输出主人
    return inst.components.follower.leader or GetTheWorldPlayerById(inst.babydata.userid)
end

--获取主人位置或自身位置
local function GetLeaderPos(inst)
	local pos = inst:GetPosition()
	if inst and inst.components and inst.components.follower.follower and inst.components.follower.leader then
		pos = inst.components.follower.leader:GetPosition()
	end
	return pos
end

local function GetFaceTargetFn(inst)
    local target = FindClosestPlayerToInst(inst, START_FACE_DIST, true)
	--应该添加个宝宝面朝主人时触发的随机唠嗑话语
    return target ~= nil and not target:HasTag("notarget") and target or nil
end

local function IsNearLeader(inst, dist)
    local leader = GetLeader(inst)
    -- return leader ~= nil and leader:IsValid() and inst and inst:IsValid() and inst:IsNear(leader, dist)
	return leader ~= nil and inst:IsValid() and inst:IsNear(leader, dist)
end

local function NiceBufferedAction(inst, target, action)
    if inst.onequipwork(inst, action) then
        local buffaction = BufferedAction(inst, target, action)
        if WORK_TAGS[action] ~= nil and WORK_TAGS[action].finishCall then
            buffaction:AddSuccessAction(function()
                inst:PushEvent("finishedwork", { target = target, action = action })
            end)
        end
        return buffaction
    end
end

--检查是否是肥料
local function fertilizerObj(obj)
	if obj.components.fertilizer ~= nil then
		return true
	end
	return false
end

--检查种子是否可种植
local function CheckPlantableSeeds(obj)
	if obj.components.plantable == nil then
	    return false
	end
	return true
end
--[[
--检查宝宝身上的是否有需要的物品
local function CheckBodyItems(inst)
	--先检查可种植的农田
	-- local nc = GetNongChangZZ(inst)
	
	local itemobj = nil
	local inventory = inst.components.inventory
	--无物品检查
	if inventory:NumItems() == 0 then
		return itemobj
	end
	for i = 1, inventory.maxslots do
		local v = inventory.itemslots[i]--获取这个物品
		if v ~=nil and CheckPlantableSeeds(v) then--检查这个物品
			itemobj = v
			break
		end
	end
	return itemobj
end
]]
--宝宝包裹物品检查是否有鱼竿,有的话,就装备上
local function Checkfishtool(inst)
	local inventory = inst.components.inventory
	local fishtool = nil
	for i = 1, inventory.maxslots do
		local v = inventory.itemslots[i]--获取这个物品
		-- if v ~=nil and WORK_TAGS[ACTIONS.FISH].fishingrods[v.prefab] then
		if v ~=nil
		and (WORK_TAGS[ACTIONS.FISH].fishingrods[v.prefab] and v.prefab == "fishingrod"
		or WORK_TAGS[ACTIONS.FISH].fishingrods[v.prefab] and WORK_TAGS[ACTIONS.FISH].characters[inst.babydata.prefab] ) then		
			inst.components.inventory:Equip(v)
			fishtool = v
			break
		end
	end
	return fishtool
end


--检查宝宝是否装备了鱼竿
local function CheckBodyEquippedItem(inst)
	--执行一次原有手持物检查
	if inst.oldHands ~= nil then
		inst.components.inventory:Equip(inst.oldHands)
		inst.oldHands = nil
		inst.oldtool = nil
	end
	--再检测手持物是否为钓竿
	local tool = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
	if tool ~=nil
	and ((WORK_TAGS[ACTIONS.FISH].fishingrods[tool.prefab] and tool.prefab == "fishingrod")
	or (WORK_TAGS[ACTIONS.FISH].fishingrods[tool.prefab] and WORK_TAGS[ACTIONS.FISH].characters[inst.babydata.prefab] )) then
		return true
	end
	--再检测包裹内有没有
	if Checkfishtool(inst) ~=nil then return true end
	return false
end

--检查宝宝身上的是否有需要的物品
local function CheckBodyItems(inst,tag)
	
	local itemobj = nil
	local inventory = inst.components.inventory
	--无物品检查
	if inventory:NumItems() == 0 then
		return itemobj
	end
	for i = 1, inventory.maxslots do
		local v = inventory.itemslots[i]--获取这个物品
		if v ~=nil then
			if tag == "seeds" and CheckPlantableSeeds(v) then--检查这个种子物品
				itemobj = v
				break
		    elseif tag == "fertilizer" and fertilizerObj(v) then--检查这个肥料物品
				itemobj = v
				break
			end
		end
	end
	return itemobj
end
------------debug
--[[
local function OnDeploy(inst, pt, deployer) --, rot)
    local plant = SpawnPrefab("farm_plant_randomseed")
    plant.Transform:SetPosition(pt.x, 0, pt.z)
    plant:PushEvent("on_planted", {in_soil = false, doer = deployer, seed = inst})
    TheWorld.Map:CollapseSoilAtPoint(pt.x, 0, pt.z)
    --plant.SoundEmitter:PlaySound("dontstarve/wilson/plant_seeds")
    inst:Remove()
end
	local owner = inst.components.follower.leader or nil
	if owner ~= nil then
		local pt = owner:GetPosition()--获取主人的位置
]]
------------debug
--新农田栽种行为的栽种处理
local function PlantSoilItemsPress(inst, item, target)
	if item and item.components.deployable
	and inst and inst:IsValid() and inst.components.follower
	and target
	then
		local pt = target:GetPosition() or nil
		local deployer = inst.components.follower.leader or nil
		if pt ~=nil and deployer ~=nil then
			item.components.deployable.ondeploy(item, pt, deployer)
		end
	end
end
-- 获得工作内容
local function GetTargetWork(inst, leader, target)
    if target ~= nil and target:IsValid() then
        -- 不可见或不能点击正在燃烧等对象或离主人过远直接不工作
		-- print("发现目标")
        if target:IsInLimbo() or target:HasTag("NOCLICK")--[[ and  WORK_TAGS[PLANTSOIL][target.prefab] )]] or target:HasTag("event_trigger")
           or (target.components.burnable ~= nil and (target.components.burnable:IsBurning() or target.components.burnable:IsSmoldering()))
           or not target.entity:IsVisible()
           or not target:IsNear(leader, KEEP_WORKING_DIST)
        then return nil end

        local workAction = nil
        if target.components.workable ~= nil and target.components.workable:CanBeWorked() then
            workAction = target.components.workable:GetWorkAction()
			--额外处理的工作过滤
			if workAction ~= nil and workAction ~= ACTIONS.MINE then 
				if inst.canWork[workAction] then
					if WORK_TAGS[workAction] ~= nil then
						if WORK_TAGS[workAction].prefabs ~= nil and WORK_TAGS[workAction].prefabs[target.prefab] then return workAction end
						if WORK_TAGS[workAction].tags ~= nil then
							for i, v in ipairs(WORK_TAGS[workAction].tags) do
								if target:HasTag(v) then return workAction end
							end
						end
					else
						return workAction
					end
				end
			end
        end
		--垂钓\钓鱼
        workAction = ACTIONS.FISH
        if inst.canWork[workAction] then
            if target.components.fishable ~= nil-- and target.ownerlist == nil
			-- and ((target.ownerlist
			-- and (target.ownerlist.master == inst.babydata.userid or target.ownerlist.master == inst.components.follower.leader.userid ))
			-- or target.ownerlist == nil )--权限物品的排除
			and WORK_TAGS[workAction].isfishableObj[target.prefab]
			-- and --插入检测鱼塘\池塘内是否有鱼的检查.无鱼,就不钓鱼了(额,有点BT)
			and not inst.components.inventory:IsFull()--当宝宝背包满时,就不钓鱼了额.
			-- and CheckBodyHasItemsAndEquipIt(inst)--检测宝宝身上的钓鱼竿,如果有,那么装备上,继续钓鱼.
			-- and (CheckBodyHasItemsAndEquipIt(inst) or CheckBodyEquippedItem(inst))--合并逻辑
			and CheckBodyEquippedItem(inst)--检查宝宝是否装备了鱼竿,如果没有,检测宝宝身上的钓鱼竿,如果有,那么装备上,继续钓鱼,否则,停止钓鱼行为
			and not inst.sg:HasStateTag("fishing") and not inst.sg:HasStateTag("catchfish")--宝宝不是在钓鱼状态行为中(判定是否正在钓鱼流程中)
			-- and IsNearLeader(inst,3)--设置宝宝在主人某范围内执行钓鱼,暂时废置
			then
			-- print(inst.babydata.userid)
			-- print(inst.babydata.userid)
			-- print(inst.components.follower.leader.userid)
                return workAction
            end
        end
		--宝宝开采行为的控制
		workAction = ACTIONS.MINE
		if inst.canWork[workAction] then
			if target.components.workable ~= nil then
				if target.ownerlist == nil then
					return workAction
				else
					local leader = GetLeader(inst)
					if leader~=nil and leader.userid then
						if target.ownerlist.master == leader.userid then
							return workAction
						end
					end
				end
			end
		end
		--宝宝锤砸的处理
		-- HAMMER
        workAction = ACTIONS.HAMMER
        if inst.canWork[workAction] then
            if (target.components.workable ~= nil
			and (target.prefab == "houndbone" or (target:HasTag("weighable_OVERSIZEDVEGGIES") ))) 
			and target.ownerlist == nil--权限物品的排除
			then
                return workAction
            end
        end
		--采集
        workAction = ACTIONS.PICK
        if inst.canWork[workAction] then
            if ((target.components.pickable ~= nil and target.components.pickable.caninteractwith and target.components.pickable:CanBePicked()) or target.prefab == "worm")
               and not WORK_TAGS[workAction].noprefabs[target.prefab]
			   and not inst.components.inventory:IsFull()--当宝宝背包满时,就不采集了.
			   and target.ownerlist == nil--权限物品的排除
            then
                return workAction
            end
        end
		--收获物品的处理(烹饪锅上面的东西\农田上的作物等)
        workAction = ACTIONS.HARVEST
        if inst.canWork[workAction] then
            if target.components.crop and target.components.crop:IsReadyForHarvest()
               or target.components.dryer and target.components.dryer:IsDone()
               or target.components.stewer and target.components.stewer:IsDone()
			   and not inst.components.inventory:IsFull()--当宝宝背包满时,就不收获.
			   and target.ownerlist == nil--权限物品的排除
            then
                return workAction
            end
        end
		--拾取
        workAction = ACTIONS.PICKUP
        if inst.canWork[workAction] then
			local pt = (target and target:IsValid() and target:GetPosition()) or nil
			
            if target.ownerlist == nil and target.components.health == nil--权限物品的排除
               and target.components.inventoryitem ~= nil and (target.components.inventoryitem.canbepickedup or (target.components.inventoryitem.canbepickedupalive and not inst:HasTag("player")))
               and target.components.inventoryitem.cangoincontainer
               and not (target.components.projectile ~= nil and target.components.projectile:IsThrown())
               and not WORK_TAGS[workAction].noprefabs[target.prefab]
			   -- and not checkTable(target, WORK_TAGS[workAction].notags)--检测排除过滤的标记
			   --ByLaoluFix 2019-03-22 修复:当宝宝背包满时,不工作.
			   and not inst.components.inventory:IsFull()
			   --Fixed
			   --检查对象是否在水中
			   and (target.components.floater ~=nil and not target.components.floater:IsFloating())
			   and pt ~=nil --位置检查
            then
                return workAction
            end
        end
		--抓孢子\萤火虫\蝴蝶\
        workAction = ACTIONS.NET
        if inst.canWork[workAction] then
            if target.components.workable ~= nil and target.ownerlist == nil--权限物品的排除
			--and (target.prefab == "fireflies" or target.prefab == "butterfly" or target.prefab == "spore" --[[ or target.prefab == "bee"]] ) 
			and WORK_TAGS[workAction][target.prefab]
			and not inst.components.inventory:IsFull()--当宝宝背包满时,就不捕虫了额.
			then
                return workAction
            end
        end
		--种植:基础农田和高级农田
        -- workAction = ACTIONS.PLANT
        -- if inst.canWork[workAction] then
            -- if target.components.workable ~= nil and target.ownerlist == nil--权限物品的排除
			-- and target.components.grower and target.components.grower:IsEmpty() and target.components.grower:IsFertile()--仅在不需要施肥的农田上种植,贫瘠的农田上不种植
			-- and WORK_TAGS[workAction][target.prefab]
			-- and not inst.components.inventory:IsFull()--当宝宝背包满时,不进行种植行为.
			-- and CheckBodyItems(inst, "seeds") ~=nil --当宝宝身上没可种植的种子时,停止种植
			-- then
                -- return workAction
            -- end
        -- end
		----[[
		--新种植行为:farm_soil
		-- print("执行1")
        workAction = ACTIONS.PLANTSOIL
        if inst.canWork[workAction] then
		
            if target and target.ownerlist == nil--权限物品的排除
			and WORK_TAGS[workAction][target.prefab]
			and not inst.components.inventory:IsFull()--当宝宝背包满时,不进行种植行为.
			and CheckBodyItems(inst, "seeds") ~=nil --当宝宝身上没可种植的种子时,停止种植
			then
				-- LL_FindFarmPlant(inst, ACTIONS.INTERACT_WITH, true, GetLeaderPos)
				return workAction
            end
        end
		--]]		
		--农田等作物施肥技能
        workAction = ACTIONS.FERTILIZE
        if inst.canWork[workAction] then
            if target.components.workable ~= nil and target.ownerlist == nil--权限物品的排除
			and target.components.grower and target.components.grower:IsEmpty() and target.components.grower:GetFertilePercent() < FERTILE_PERCEBT --仅在肥沃度小于该值的农田上施肥
			and WORK_TAGS[workAction].objprefab[target.prefab]--检查施肥的目标
			--and CheckBodyHasItems(inst) --检查要施肥的物品
			and not inst.components.inventory:IsFull()--当宝宝背包满时,不进行施肥行为.
			and CheckBodyItems(inst, "fertilizer") ~=nil --当宝宝身上没可施肥的物品时,停止施肥行为
			-- and WORK_TAGS[workAction].itemprefab[CheckBodyItems(inst, "fertilizer")]--检查要施肥的物品是否在预设表里
			then
                return workAction
            end
        end
    end
	
    return nil
end

local function FindEntityToWorkAction(inst)
    -- print("老卢的工作信息:", inst, action, addtltags)
    local leader = GetLeader(inst)
    if leader ~= nil then
        --是否保留现有的目标处理?
        local target = inst.sg.statemem.target
        local workAction = GetTargetWork(inst, leader, target)
        if workAction == nil then
            --查找新的目标
            -- target = FindEntity(leader, SEE_WORK_DIST, nil, { "CHOP_workable", "MINE_workable", "DIG_workable" }, { "fire", "smolder", "event_trigger", "INLIMBO", "NOCLICK" }, addtltags)
            -- target = FindEntity(leader, SEE_WORK_DIST, function(guy)
            --     local workAction = GetTargetWork(inst, leader, guy)
            --     return workAction ~= nil and true or false
            -- end, nil, { "fire", "smolder", "event_trigger", "INLIMBO", "NOCLICK" }) -- , { "CHOP_workable", "MINE_workable", "DIG_workable" }

            -- 寻找新的工作目标
            local x, y, z = leader.Transform:GetWorldPosition()
            local ents = TheSim:FindEntities(x, y, z, SEE_WORK_DIST, nil, { "fire", "smolder", "event_trigger", "INLIMBO", "NOCLICK" })
            for i, v in ipairs(ents) do
                workAction = GetTargetWork(inst, leader, v)
                if workAction ~= nil then
                    target = v
                    break
                end
            end
        end

        if workAction ~= nil then
            return NiceBufferedAction(inst, target, workAction)
        end
    end
end
--]]--
-----------------------------------------------------------------------

-----------------------------------------------------------------------
---[[
local function KeepFaceTargetFn(inst, target)
    return not target:HasTag("notarget") and inst:IsNear(target, KEEP_FACE_DIST)
end

local function DanceParty(inst)
    inst:PushEvent("dance")
end

local function ShouldDanceParty(inst)
    local leader = GetLeader(inst)
    return leader ~= nil and leader.sg:HasStateTag("dancing")
end

local function ShouldAvoidExplosive(target)
    return target.components.explosive == nil
        or target.components.burnable == nil
        or target.components.burnable:IsBurning()
end

local function ShouldRunAway(target, inst)
    return not inst.babydata.canAtk
        and not (target.components.health ~= nil and target.components.health:IsDead())
        and (target.components.combat ~= nil and target.components.combat:HasTarget())
        -- and (not target:HasTag("shadowcreature") or (target.components.combat ~= nil and target.components.combat:HasTarget()))
end

local function ShouldKite(target, inst)
    return target ~= nil
        and target == inst.components.combat.target
        and target.components.health ~= nil
        and not target.components.health:IsDead()
end



--获取创建位置
local function GetSpawnPoint(pt,radius)
    local theta = math.random() * 2 * PI

	local offset = FindWalkableOffset(pt, theta, radius, 12, true)
	if offset then
		return pt+offset
	end
end

--宝宝不跟随主人时,自己游走的处理
local function GetNoLeaderHomePos(inst)
	--插入玩家的位置,一定范围内的一个随机坐标值.
	local owner = inst.components.follower.leader or nil
	if owner ~= nil then
		local pt = owner:GetPosition()--获取主人的位置
		local newpoint = GetSpawnPoint(pt,15)--获取主人15码范围内的一个随机位置
		-- print(newpoint:Get())
		return newpoint
	else
		--print("无主人")
		return nil
	end
	-- return inst.components.knownlocations and inst.components.knownlocations:GetLocation("home")
    -- return inst.components.knownlocations and inst.components.knownlocations:GetLocation("home")
end

--]]
-------------------------------------------------------------------
function PlayerBabyBrain:OnStart()
    local root = PriorityNode(
    {
	--[[
		--青木的AI DEBUG
		 WhileNode(function() return ShouldKite_3(self.inst.components.combat.target, self.inst) and (ShouldKite_1(self.inst.components.combat.target, self.inst) 
			or ShouldKite_2(self.inst.components.combat.target, self.inst)) end, "Dodge",
					RunAway(self.inst, { fn = ShouldKite, tags = { "_combat", "_health" }, notags = { "INLIMBO" } }, 12, 
			self.inst.baobao_b.bao_taoli or 3.4)),

		ChaseAndAttack(self.inst, 5),
		]]
		--青木的AI
		----------------------
        --#1.优先的AI是:主人在跳舞时,宝宝在身边一起跳舞.
        WhileNode(function() return ShouldDanceParty(self.inst) end, "Dance Party",
            PriorityNode({
                -- 跑到离主人多少码范围内(注释掉即为原地跳舞,不跑向主人)
                Leash(self.inst, GetLeaderPos, KEEP_DANCING_DIST, KEEP_DANCING_DIST),--基于参数,跑向主人
                ActionNode(function() DanceParty(self.inst) end),
        }, .25)),
		----[[
		--在主人30码范围内才做的工作内容
        WhileNode(function() return IsNearLeader(self.inst, KEEP_WORKING_DIST) end, "Leader In Range",
            PriorityNode({
			----[[
                --AI躲避 爆发范围内设置的爆炸物
                RunAway(self.inst, { fn = ShouldAvoidExplosive, tags = { "explosive" }, notags = { "INLIMBO" } }, AVOID_EXPLOSIVE_DIST, AVOID_EXPLOSIVE_DIST),
                --AI逃跑前尝试战斗的方法
                IfNode(function() return self.inst.babydata.canAtk end, "Attacking",
                    PriorityNode({
                        IfNode(function() return self.inst.babydata.level >= BB_HIGH_ATTACK_LEVEL end, "High Attacking",--高级战斗技巧
                            GD_KiteAndAttack(self.inst, STOP_KITING_EX_DIST)),
                        IfNode(function() return self.inst.babydata.level < BB_HIGH_ATTACK_LEVEL end, "Low Attacking",	--一般战斗技巧
                            PriorityNode({
                                WhileNode(function() return self.inst.components.combat:GetCooldown() > .5 and ShouldKite(self.inst.components.combat.target, self.inst) end, "Dodge",
                                    RunAway(self.inst, { fn = ShouldKite, tags = { "_combat", "_health" }, notags = { "INLIMBO" } }, KITING_DIST, STOP_KITING_DIST)),
                                ChaseAndAttack(self.inst,5),--追杀5秒
                        }, .25)),
                }, .25)),
                --AI将从该危险点逃离
                RunAway(self.inst, { fn = ShouldRunAway, oneoftags = { "monster", "hostile" }, notags = { "player", "INLIMBO" } }, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST),
				--]]
				----------------------------------------
                --宝宝如果不是逃离状态,就进行自动工作.(自动工作时的条件判定和逻辑设计)
                IfNode(function() return self.inst.components.hunger.current > 0 and self.inst.components.combat.target == nil and self.inst.canWork ~= nil
				--ByLaoluFix 2019-03-22 修复:当宝宝背包满时,不工作.
				--and not self.inst.components.inventory:IsFull()
				--Fixed
				end,
				"Keep Working",
                    DoAction(self.inst, function() return FindEntityToWorkAction(self.inst) end)),
				----------------------------------------
				
        }, .15)),
		--]]
		--有主人在身边时,进行种植,已移植到自动工作内容中
		--抓孢子\萤火虫\蝴蝶--已移植到自动工作内容中
		--跟随主人
				-- IfNode(function() return self.inst.components.combat.target == nil end,
					-- "interact_with",
					-- FindFarmPlant(self.inst, ACTIONS.INTERACT_WITH, true, GetLeaderPos)),
        Follow(self.inst, GetLeader, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST),--0,3,8
		LL_FindFarmPlant(self.inst, ACTIONS.INTERACT_WITH, true, GetLeaderPos, SEE_DIST),
		--朝向主人
        WhileNode(function() return GetLeader(self.inst) ~= nil end, "Has Leader",
            FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn)),

		--宝宝闲逛
		Wander(self.inst, GetNoLeaderHomePos, 20,
		{
			minwalktime = .5,
			randwalktime = 2,
			minwaittime = 2,
			randwaittime = 3,
    		})
    }, .15)

    self.bt = BT(self.inst, root)--返回行为树
end

return PlayerBabyBrain
