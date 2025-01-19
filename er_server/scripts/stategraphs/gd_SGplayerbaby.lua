require("stategraphs/commonstates")

local function DoEquipmentFoleySounds(inst)
    for k, v in pairs(inst.components.inventory.equipslots) do
        if v.foleysound ~= nil then
            inst.SoundEmitter:PlaySound(v.foleysound, nil, nil, true)
        end
    end
end

local function DoFoleySounds(inst)
    DoEquipmentFoleySounds(inst)
    if inst.foleysound ~= nil then
        inst.SoundEmitter:PlaySound(inst.foleysound, nil, nil, true)
    end
end

local function DoHurtSound(inst)
    if inst.hurtsoundoverride ~= nil then
        inst.SoundEmitter:PlaySound(inst.hurtsoundoverride)
    elseif not inst:HasTag("mime") then
        inst.SoundEmitter:PlaySound((inst.talker_path_override or "dontstarve/characters/")..(inst.soundsname or inst.babydata.prefab).."/hurt")
    end
end

local function DoTalkSound(inst)
    if inst.talksoundoverride ~= nil then
        inst.SoundEmitter:PlaySound(inst.talksoundoverride, "talk")
        return true
    elseif not inst:HasTag("mime") then
        inst.SoundEmitter:PlaySound((inst.talker_path_override or "dontstarve/characters/")..(inst.soundsname or inst.babydata.prefab).."/talk_LP", "talk")
        return true
    end
end

local function DoMountSound(inst, mount, sound, ispredicted)
    if mount ~= nil and mount.sounds ~= nil then
        inst.SoundEmitter:PlaySound(mount.sounds[sound], nil, nil, ispredicted)
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

local function GetLeader(inst)
    -- print("检查老卢宝宝的状态", inst.babydata, inst.babydata.canChop)
    return inst.components.follower.leader or GetTheWorldPlayerById(inst.babydata.userid)
end

--检查可种植的其他物品
local function CheckPlantableOtherItems(obj)
	if obj.components.plantable == nil then
	    return false
	end
	return obj.prefab and obj.prefab ~= "seeds"
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
--检查宝宝身上的是否有需要的物品
local function CheckBodyItems(inst,tag)
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
local actionhandlers =
{
	--钓鱼\垂钓
	ActionHandler(ACTIONS.FISH,"fishing_pre"),
    ActionHandler(ACTIONS.CHOP,
        function(inst)
            if not inst.sg:HasStateTag("prechop") then
                return inst.sg:HasStateTag("chopping")
                    and "chop"
                    or "chop_start"
            end
        end),
    ActionHandler(ACTIONS.MINE, 
        function(inst) 
            if not inst.sg:HasStateTag("premine") then
                return inst.sg:HasStateTag("mining")
                    and "mine"
                    or "mine_start"
            end
        end),
    ActionHandler(ACTIONS.DIG,
        function(inst)
            if not inst.sg:HasStateTag("predig") then
                return inst.sg:HasStateTag("digging")
                    and "dig"
                    or "dig_start"
            end
        end),
    ActionHandler(ACTIONS.HAMMER,
        function(inst)
            if not inst.sg:HasStateTag("prehammer") then
                return inst.sg:HasStateTag("hammering")
                    and "hammer"
                    or "hammer_start"
            end
        end),
    ActionHandler(ACTIONS.NET,
        function(inst)
            return not inst.sg:HasStateTag("prenet")
                and (inst.sg:HasStateTag("netting") and
                    "bugnet" or
                    "bugnet_start")
                or nil
        end),
	--新农田种植
    ActionHandler(ACTIONS.PLANTSOIL,"plantsoil"),--"dolongaction"),--
	--新农田:对话
    ActionHandler(ACTIONS.INTERACT_WITH,"interact_with"),
	--种植
    ActionHandler(ACTIONS.PLANT,"plant"),
	--施肥
	ActionHandler(ACTIONS.FERTILIZE,"fertilize"),
	--采集
    ActionHandler(ACTIONS.PICK,
        function(inst, action)
            return action.target ~= nil
                and action.target.components.pickable ~= nil
                and (   (action.target.components.pickable.jostlepick and "dojostleaction") or
                        (action.target.components.pickable.quickpick and "doshortaction") or
                        "dolongaction"  )
                or nil
        end),
    ActionHandler(ACTIONS.HARVEST, "dolongaction"),
    ActionHandler(ACTIONS.PICKUP, "doshortaction"),
    ActionHandler(ACTIONS.SLEEPIN, 
		function(inst, action)
			if action.invobject then
                if action.invobject.onuse then
                    action.invobject.onuse()
                end
				return "bedroll"
			else
				return "doshortaction"
			end
		end),
    ActionHandler(ACTIONS.EAT,
        function(inst, action)
            if inst.sg:HasStateTag("busy") then
                return
            end
            local obj = action.target or action.invobject
            if obj == nil or obj.components.edible == nil then
                return
            elseif not inst.components.eater:PrefersToEat(obj) then
                inst:PushEvent("wonteatfood", { food = obj })
                return
            end
            return (inst:HasTag("beaver") and "beavereat")
                or (obj.components.edible.foodtype == FOODTYPE.MEAT and "eat")
                or "quickeat"
        end),
}

local events =
{
    CommonHandlers.OnLocomote(true, false),
    -- CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    EventHandler("attacked", function(inst, data)
        if not inst.components.health:IsDead() then
            if data.weapon ~= nil and data.weapon:HasTag("tranquilizer") and inst.sg:HasStateTag("knockout") then
                return --Do nothing
            elseif inst.sg:HasStateTag("transform") or inst.sg:HasStateTag("dismounting") then
                -- don't interrupt transform or when bucked in the air
                inst.SoundEmitter:PlaySound("dontstarve/wilson/hit")
                DoHurtSound(inst)
            elseif inst.sg:HasStateTag("bedroll") or inst.sg:HasStateTag("sleeping") then
                inst.SoundEmitter:PlaySound("dontstarve/wilson/hit")
                DoHurtSound(inst)
                if inst.sleepingbag ~= nil then
                    inst.sleepingbag.components.sleepingbag:DoWakeUp()
                    inst.sleepingbag = nil
                else
                    inst.sg.statemem.iswaking = true
                    inst.sg:GoToState("wakeup")
                end
            elseif not inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("frozen") then
                inst.sg:GoToState("hit")
            end
        end
    end),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnAttack(),
    EventHandler("eat", function(inst, data) 
        if inst.components.health ~= nil and not inst.components.health:IsDead() then
            inst.sg:GoToState(data.food.components.edible.foodtype == FOODTYPE.MEAT and "eat" or "quickeat", data)
        end
    end),
    EventHandler("ontalk", function(inst, data)
        if inst.sg:HasStateTag("idle") then
            if inst.prefab == "wes" then
				inst.sg:GoToState("mime")
            else
				inst.sg:GoToState("talk", data.noanim)
			end
        end
    end),
    EventHandler("gotosleep", function(inst)
        if inst.components.health ~= nil and not inst.components.health:IsDead() then
            inst.sg:GoToState("bedroll")
        end
    end),
	EventHandler("wakeup", function(inst)
        inst.sg:GoToState("wakeup")
    end), 
	--监听钓鱼退出事件
    EventHandler("fishingcancel",
        function(inst)
            if inst.sg:HasStateTag("fishing") and not inst:HasTag("busy") then
                inst.sg:GoToState("fishing_pst")
            end
        end),	
	EventHandler("knockedout", function(inst)
        if inst.sg:HasStateTag("knockout") then
            inst.sg.statemem.cometo = nil
        elseif not (inst.sg:HasStateTag("sleeping") or inst.sg:HasStateTag("bedroll") or inst.sg:HasStateTag("tent") or inst.sg:HasStateTag("waking")) then
            inst.sg:GoToState("knockout")
        end
    end),
    EventHandler("dance", function(inst)
        if not (inst.sg:HasStateTag("dancing") or inst.sg:HasStateTag("busy")) then
            inst.sg:GoToState("dance")
        end
    end),
}

local states =
{
    State{
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst, pushanim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle_loop", true)

            if inst.components.combat.target == nil then
                local leader = GetLeader(inst)
                if leader and leader.hxsleep then inst.sg:GoToState("bedroll") end
            end
        end,
    },

    State{
        name = "talk",
        tags = { "idle", "talking" },

        onenter = function(inst, noanim)
            if not noanim then
                inst.AnimState:PlayAnimation(
                    inst.components.inventory:IsHeavyLifting() and
                    not (inst.components.rider ~= nil and inst.components.rider:IsRiding()) and
                    "heavy_dial_loop" or
                    "dial_loop",
                    true)
            end
            DoTalkSound(inst)
            inst.sg:SetTimeout(1.5 + math.random() * .5)
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("idle")
        end,

        events =
        {
            EventHandler("donetalking", function(inst)
                inst.sg:GoToState("idle")
            end),
        },

        onexit = function(inst)
            inst.SoundEmitter:KillSound("talk")
        end,
    },

    State{
        name = "run_start",
        tags = { "moving", "running", "canrotate", "autopredict" },

        onenter = function(inst)
            if inst.components.rider ~= nil and inst.components.rider:IsRiding() then
                inst.sg.statemem.riding = true
                inst.sg:AddStateTag("nodangle")
            elseif inst.components.inventory:IsHeavyLifting() then
                inst.sg.statemem.heavy = true
            end

            inst.components.locomotor:RunForward()
            inst.AnimState:PlayAnimation(
                (inst.sg.statemem.heavy and "heavy_walk_pre") or
                (inst:HasTag("groggy") and "idle_walk_pre") or
                "run_pre"
            )

            inst.sg.mem.footsteps = 0
        end,

        onupdate = function(inst)
            inst.components.locomotor:RunForward()
        end,

        timeline =
        {
            --mounted
            TimeEvent(0, function(inst)
                if inst.sg.statemem.riding then
                    DoMountedFoleySounds(inst)
                end
            end),

            --heavy lifting
            TimeEvent(1 * FRAMES, function(inst)
                if inst.sg.statemem.heavy then
                    PlayFootstep(inst, nil, true)
                    DoFoleySounds(inst)
                end
            end),

            --unmounted
            TimeEvent(4 * FRAMES, function(inst)
                if not (inst.sg.statemem.riding or inst.sg.statemem.heavy) then
                    PlayFootstep(inst, nil, true)
                    DoFoleySounds(inst)
                end
            end),

            --mounted
            TimeEvent(5 * FRAMES, function(inst)
                if inst.sg.statemem.riding then
                    PlayFootstep(inst, nil, true)
                end
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("run")
                end
            end),
        },
    },

    State{
        name = "run",
        tags = { "moving", "running", "canrotate", "autopredict" },

        onenter = function(inst) 
            if inst.components.rider ~= nil and inst.components.rider:IsRiding() then
                inst.sg.statemem.riding = true
                inst.sg:AddStateTag("nodangle")
            elseif inst.components.inventory:IsHeavyLifting() then
                inst.sg.statemem.heavy = true
            end

            inst.components.locomotor:RunForward()

            local anim =
                (inst.sg.statemem.heavy and "heavy_walk") or
                (inst:HasTag("groggy") and "idle_walk") or
                "run_loop"
            if not inst.AnimState:IsCurrentAnimation(anim) then
                inst.AnimState:PlayAnimation(anim, true)
            end

            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
        end,

        onupdate = function(inst)
            inst.components.locomotor:RunForward()
        end,

        timeline =
        {
            --unmounted
            TimeEvent(7 * FRAMES, function(inst)
                if not (inst.sg.statemem.riding or inst.sg.statemem.heavy) then
                    if inst.sg.mem.footsteps > 3 then
                        PlayFootstep(inst, .6, true)
                    else
                        inst.sg.mem.footsteps = inst.sg.mem.footsteps + 1
                        PlayFootstep(inst, 1, true)
                    end
                    DoFoleySounds(inst)
                end
            end),
            TimeEvent(15 * FRAMES, function(inst)
                if not (inst.sg.statemem.riding or inst.sg.statemem.heavy) then
                    if inst.sg.mem.footsteps > 3 then
                        PlayFootstep(inst, .6, true)
                    else
                        inst.sg.mem.footsteps = inst.sg.mem.footsteps + 1
                        PlayFootstep(inst, 1, true)
                    end
                    DoFoleySounds(inst)
                end
            end),

            --heavy lifting
            TimeEvent(11 * FRAMES, function(inst)
                if inst.sg.statemem.heavy then
                    PlayFootstep(inst, inst.sg.mem.footsteps > 3 and .6 or 1, true)
                    DoFoleySounds(inst)
                    inst.sg.mem.footsteps = inst.sg.mem.footsteps + 1
                end
            end),
            TimeEvent(36 * FRAMES, function(inst)
                if inst.sg.statemem.heavy then
                    PlayFootstep(inst, inst.sg.mem.footsteps > 3 and .6 or 1, true)
                    DoFoleySounds(inst)
                    if inst.sg.mem.footsteps > 12 then
                        inst.sg.mem.footsteps = math.random(4, 6)
                        inst:PushEvent("encumberedwalking")
                    else
                        inst.sg.mem.footsteps = inst.sg.mem.footsteps + 1
                    end
                end
            end),

            --mounted
            TimeEvent(0 * FRAMES, function(inst)
                if inst.sg.statemem.riding then
                    DoMountedFoleySounds(inst)
                end
            end),
            TimeEvent(5 * FRAMES, function(inst)
                if inst.sg.statemem.riding then
                    if inst.sg.mem.footsteps > 3 then
                        PlayFootstep(inst, .6, true)
                    else
                        inst.sg.mem.footsteps = inst.sg.mem.footsteps + 1
                        PlayFootstep(inst, 1, true)
                    end
                end
            end),
        },

        ontimeout = function(inst)
            inst.sg:GoToState("run")
        end,
    },

    State{
        name = "run_stop",
        tags = { "canrotate", "idle", "autopredict" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            if inst.components.rider ~= nil and inst.components.rider:IsRiding() then
                inst.sg:AddStateTag("nodangle")
                inst.AnimState:PlayAnimation(inst:HasTag("groggy") and "idle_walk_pst" or "run_pst")
            elseif inst.components.inventory:IsHeavyLifting() then
                inst.AnimState:PlayAnimation("heavy_walk_pst")
            else
                inst.AnimState:PlayAnimation(inst:HasTag("groggy") and "idle_walk_pst" or "run_pst")
            end
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    -- State{
    --     name = "attack",
    --     tags = {"attack", "notalking", "abouttoattack", "busy"},

    --     onenter = function(inst)
    --         inst.onoldequiphands(inst)
    --         inst.sg.statemem.target = inst.components.combat.target
    --         inst.components.combat:StartAttack()
    --         inst.Physics:Stop()
    --         inst.AnimState:PlayAnimation("atk")
    --         inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_nightsword")

    --         if inst.components.combat.target ~= nil and inst.components.combat.target:IsValid() then
    --             inst:FacePoint(inst.components.combat.target.Transform:GetWorldPosition())
    --         end
    --     end,

    --     timeline =
    --     {
    --         TimeEvent(8*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) inst.sg:RemoveStateTag("abouttoattack") end),
    --         TimeEvent(12*FRAMES, function(inst)
    --             inst.sg:RemoveStateTag("busy")
    --         end),
    --         TimeEvent(13*FRAMES, function(inst)
    --             inst.sg:RemoveStateTag("attack")
    --         end),
    --     },

    --     events =
    --     {
    --         EventHandler("animover", function(inst)
    --             if inst.AnimState:AnimDone() then
    --                 inst.sg:GoToState("idle")
    --             end
    --         end),
    --     },
    -- },

    State{
        name = "attack",
        tags = { "attack", "notalking", "abouttoattack", "autopredict" },

        onenter = function(inst)
			--战斗前的预准备处理
            inst.onoldequiphands(inst)--卸下当前手里的任何工具
            local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            inst.sg.statemem.target = inst.components.combat.target
            inst.components.combat:StartAttack()
            -- inst.components.locomotor:Stop()
			-----------------------
			-- inst.Physics:Stop()
            -- inst.AnimState:PlayAnimation("atk")
            -- inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon")
            -- inst.SoundEmitter:KillSound("eating")
			-----------------------
			----[[
			---------------------------------------------
			--基数:
			-- FRAMES:0.33333333
			--cooldown:0.1+ 0.15
			---------------------------------------------
            inst.Physics:Stop()
            local cooldown = inst.components.combat.min_attack_period + .5 * FRAMES--帧延迟差一点点,一会具体测试,比玩家低0.5
			-- local cooldown = 0.1
            if inst.components.rider ~= nil and inst.components.rider:IsRiding() then --宝宝骑行攻击的处理
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk", false)
                DoMountSound(inst, inst.components.rider:GetMount(), "angry", true)
                cooldown = math.max(cooldown, 16 * FRAMES)
            elseif equip ~= nil and equip:HasTag("whip") then--远程武器的处理:whip鞭子
                inst.AnimState:PlayAnimation("whip_pre")
                inst.AnimState:PushAnimation("whip", false)
                inst.sg.statemem.iswhip = true
                inst.SoundEmitter:PlaySound("dontstarve/common/whip_pre", nil, nil, true)
                cooldown = math.max(cooldown, 17 * FRAMES)
				
				
            elseif equip ~= nil and equip.components.weapon ~= nil and not equip:HasTag("punch") then--宝宝携带武器的攻击处理
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk", false)
                inst.SoundEmitter:PlaySound(
                    (equip:HasTag("icestaff") and "dontstarve/wilson/attack_icestaff") or
                    (equip:HasTag("shadow") and "dontstarve/wilson/attack_nightsword") or
                    (equip:HasTag("firestaff") and "dontstarve/wilson/attack_firestaff") or
                    "dontstarve/wilson/attack_weapon",
                    nil, nil, true
                )
				-- print("正常装备武器攻击!".."帧率计时:"..tostring(cooldown))
                cooldown = math.max(cooldown, 13 * FRAMES)
            elseif equip ~= nil and (equip:HasTag("light") or equip:HasTag("nopunch")) then--宝宝携带照明装备的处理
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk", false)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon", nil, nil, true)
                cooldown = math.max(cooldown, 13 * FRAMES)--攻击速率正确
            elseif inst:HasTag("beaver") then--海狸形态攻击的处理
                inst.sg.statemem.isbeaver = true
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk", false)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh", nil, nil, true)
                cooldown = math.max(cooldown, 13 * FRAMES)
            else
                inst.AnimState:PlayAnimation("punch")--额,宝宝赤手空拳战斗的处理(手撕??!?)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh", nil, nil, true)
                cooldown = math.max(cooldown, 24 * FRAMES)
            end
--]]
            if inst.components.combat.target ~= nil and inst.components.combat.target:IsValid() then
                inst:FacePoint(inst.components.combat.target.Transform:GetWorldPosition())
            end
        end,

        timeline =
        {
            TimeEvent(8*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) inst.sg:RemoveStateTag("abouttoattack") end),
            TimeEvent(12*FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
            TimeEvent(13*FRAMES, function(inst)--13
                inst.sg:RemoveStateTag("attack")
            end),
            -- TimeEvent(13*FRAMES, function(inst)--24
                -- inst.sg:RemoveStateTag("attack")
            -- end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "eat",
        tags = { "busy", "nodangle" },

        onenter = function(inst, foodinfo)
            inst.components.locomotor:Stop()

            local feed = foodinfo and foodinfo.feed
            if feed ~= nil then
                inst.components.locomotor:Clear()
                inst:ClearBufferedAction()
                inst.sg.statemem.feed = foodinfo.feed
                inst.sg.statemem.feeder = foodinfo.feeder
                inst.sg:AddStateTag("pausepredict")
            elseif inst:GetBufferedAction() then
                feed = inst:GetBufferedAction().invobject
            end

            if feed == nil or
                feed.components.edible == nil or
                feed.components.edible.foodtype ~= FOODTYPE.GEARS then
                inst.SoundEmitter:PlaySound("dontstarve/wilson/eat", "eating")
            end

            if inst.components.inventory:IsHeavyLifting() and
                not (inst.components.rider ~= nil and inst.components.rider:IsRiding()) then
                inst.AnimState:PlayAnimation("heavy_eat")
            else
                inst.AnimState:PlayAnimation("eat_pre")
                inst.AnimState:PushAnimation("eat", false)
            end

            inst.components.hunger:Pause()
        end,

        timeline =
        {
            TimeEvent(28 * FRAMES, function(inst)
                if inst.sg.statemem.feed ~= nil then
                    inst.components.eater:Eat(inst.sg.statemem.feed, inst.sg.statemem.feeder)
                else
                    inst:PerformBufferedAction()
                end
            end),

            TimeEvent(30 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
                inst.sg:RemoveStateTag("pausepredict")
            end),

            TimeEvent(70 * FRAMES, function(inst)
                inst.SoundEmitter:KillSound("eating")
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            inst.SoundEmitter:KillSound("eating")
            inst.components.hunger:Resume()
            if inst.sg.statemem.feed ~= nil and inst.sg.statemem.feed:IsValid() then
                inst.sg.statemem.feed:Remove()
            end
        end,
    },

    State{
        name = "quickeat",
        tags = { "busy" },

        onenter = function(inst, foodinfo)
            inst.components.locomotor:Stop()

            local feed = foodinfo and foodinfo.feed
            if feed ~= nil then
                inst.components.locomotor:Clear()
                inst:ClearBufferedAction()
                inst.sg.statemem.feed = foodinfo.feed
                inst.sg.statemem.feeder = foodinfo.feeder
                inst.sg:AddStateTag("pausepredict")
            elseif inst:GetBufferedAction() then
                feed = inst:GetBufferedAction().invobject
            end

            if feed == nil or
                feed.components.edible == nil or
                feed.components.edible.foodtype ~= FOODTYPE.GEARS then
                inst.SoundEmitter:PlaySound("dontstarve/wilson/eat", "eating")
            end

            if inst.components.inventory:IsHeavyLifting() and
                not (inst.components.rider ~= nil and inst.components.rider:IsRiding()) then
                inst.AnimState:PlayAnimation("heavy_quick_eat")
            else
                inst.AnimState:PlayAnimation("quick_eat_pre")
                inst.AnimState:PushAnimation("quick_eat", false)
            end

            inst.components.hunger:Pause()
        end,

        timeline =
        {
            TimeEvent(12 * FRAMES, function(inst)
                if inst.sg.statemem.feed ~= nil then
                    inst.components.eater:Eat(inst.sg.statemem.feed, inst.sg.statemem.feeder)
                else
                    inst:PerformBufferedAction()
                end
                inst.sg:RemoveStateTag("busy")
                inst.sg:RemoveStateTag("pausepredict")
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            inst.SoundEmitter:KillSound("eating")
            inst.components.hunger:Resume()
            if inst.sg.statemem.feed ~= nil and inst.sg.statemem.feed:IsValid() then
                inst.sg.statemem.feed:Remove()
            end
        end,
    },

    State{
        name = "bedroll",
        tags = { "bedroll", "busy", "nomorph" },

        onenter = function(inst)
            inst.components.locomotor:Stop()

            inst.AnimState:OverrideSymbol("swap_bedroll", "swap_bedroll_straw", "bedroll_straw")
            inst.AnimState:PlayAnimation("bedroll",true) 
            inst.AnimState:PlayAnimation("action_uniqueitem_pre")
            inst.AnimState:PushAnimation("bedroll", false)
        end,

        timeline =
        {
            TimeEvent(20 * FRAMES, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve/wilson/use_bedroll")
            end),
        },

        events =
        {
            EventHandler("firedamage", function(inst)
                if inst.sg:HasStateTag("sleeping") then
                    inst.sg.statemem.iswaking = true
                    inst.sg:GoToState("wakeup")
                end
            end),
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    if (inst.components.health ~= nil and inst.components.health.takingfiredamage) or
                        (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
                        inst:PushEvent("performaction", { action = inst.bufferedaction })
                        inst:ClearBufferedAction()
                        inst.sg.statemem.iswaking = true
                        inst.sg:GoToState("wakeup")
                    elseif inst:GetBufferedAction() then
                        inst:PerformBufferedAction()
                        inst.sg:AddStateTag("sleeping")
                        inst.sg:AddStateTag("silentmorph")
                        inst.sg:RemoveStateTag("nomorph")
                        inst.sg:RemoveStateTag("busy")
                        inst.AnimState:PlayAnimation("bedroll_sleep_loop", true)
                    else
                        inst.AnimState:PlayAnimation("bedroll_sleep_loop", true)
                    end
                end
            end),
        },

        onexit = function(inst)
            if inst.sleepingbag ~= nil then
                inst.sleepingbag.components.sleepingbag:DoWakeUp(true)
                inst.sleepingbag = nil
            end
        end,
    },

    State{
        --Alternative to doshortaction but animated with your held tool
        --Animation mirrors attack action, but are not "auto" predicted
        --by clients (also no sound prediction)
        name = "dojostleaction",
        tags = { "doing", "busy" },

        onenter = function(inst)
            local buffaction = inst:GetBufferedAction()
            local target = buffaction ~= nil and buffaction.target or nil
            local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            inst.components.locomotor:Stop()
            local cooldown
            if inst.components.rider ~= nil and inst.components.rider:IsRiding() then
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk", false)
                DoMountSound(inst, inst.components.rider:GetMount(), "angry")
                cooldown = 16 * FRAMES
            elseif equip ~= nil and equip:HasTag("whip") then
                inst.AnimState:PlayAnimation("whip_pre")
                inst.AnimState:PushAnimation("whip", false)
                inst.sg.statemem.iswhip = true
                inst.SoundEmitter:PlaySound("dontstarve/common/whip_pre")
                cooldown = 17 * FRAMES
            elseif equip ~= nil and equip.components.weapon ~= nil and not equip:HasTag("punch") then
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk", false)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon")
                cooldown = 13 * FRAMES
            elseif equip ~= nil and (equip:HasTag("light") or equip:HasTag("nopunch")) then
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk", false)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon")
                cooldown = 13 * FRAMES
            elseif inst:HasTag("beaver") then
                inst.sg.statemem.isbeaver = true
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk", false)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
                cooldown = 13 * FRAMES
            else
                inst.AnimState:PlayAnimation("punch")
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
                cooldown = 24 * FRAMES
            end

            if target ~= nil and target:IsValid() then
                inst:FacePoint(target:GetPosition())
            end

            inst.sg.statemem.action = buffaction
            inst.sg:SetTimeout(cooldown)
        end,

        timeline =
        {
            --beaver: frame 4 remove busy, frame 6 action
            --whip: frame 8 remove busy, frame 10 action
            --other: frame 6 remove busy, frame 8 action
            TimeEvent(4 * FRAMES, function(inst)
                if inst.sg.statemem.isbeaver then
                    inst.sg:RemoveStateTag("busy")
                end
            end),
            TimeEvent(6 * FRAMES, function(inst)
                if inst.sg.statemem.isbeaver then
                    inst:PerformBufferedAction()
                elseif not inst.sg.statemem.iswhip then
                    inst.sg:RemoveStateTag("busy")
                end
            end),
            TimeEvent(8 * FRAMES, function(inst)
                if inst.sg.statemem.iswhip then
                    inst.sg:RemoveStateTag("busy")
                elseif not inst.sg.statemem.isbeaver then
                    inst:PerformBufferedAction()
                end
            end),
            TimeEvent(10 * FRAMES, function(inst)
                if inst.sg.statemem.iswhip then
                    inst:PerformBufferedAction()
                end
            end),
        },

        ontimeout = function(inst)
            --anim pst should still be playing
            inst.sg:GoToState("idle", true)
        end,

        events =
        {
            EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
        },

        onexit = function(inst)
            if inst.bufferedaction == inst.sg.statemem.action then
                inst:ClearBufferedAction()
            end
        end,
    },

    State
    {
        name = "dolongaction",
        tags = { "doing", "busy", "nodangle" },

        onenter = function(inst, timeout)
            local buffaction = inst:GetBufferedAction()
            local targ = buffaction.target or nil
            if targ then targ:PushEvent("startlongaction") end

            inst.sg.statemem.action = inst.bufferedaction
            inst.sg:SetTimeout(timeout or 1)
            inst.components.locomotor:Stop()
            inst.SoundEmitter:PlaySound("dontstarve/wilson/make_trap", "make")
            inst.AnimState:PlayAnimation("build_pre")
            inst.AnimState:PushAnimation("build_loop", true)
        end,

        timeline =
        {
            TimeEvent(4 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
        },

        ontimeout = function(inst)
            inst.SoundEmitter:KillSound("make")
            inst.AnimState:PlayAnimation("build_pst")
            inst:PerformBufferedAction()
        end,

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            inst.SoundEmitter:KillSound("make")
            if inst.bufferedaction == inst.sg.statemem.action then
                inst:ClearBufferedAction()
            end
        end,
    },

    State
    {
        name = "doshortaction",
        tags = { "doing", "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("pickup")
            inst.AnimState:PushAnimation("pickup_pst", false)

            inst.sg.statemem.action = inst.bufferedaction
            inst.sg:SetTimeout(10 * FRAMES)
        end,

        timeline =
        {
            TimeEvent(4 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
            TimeEvent(6 * FRAMES, function(inst)
                inst:PerformBufferedAction()
            end),
        },

        ontimeout = function(inst)
            --pickup_pst should still be playing
            inst.sg:GoToState("idle", true)
        end,

        onexit = function(inst)
            if inst.bufferedaction == inst.sg.statemem.action then
                inst:ClearBufferedAction()
            end
        end,
    },

    State{
        name = "knockout",
        tags = { "busy", "knockout", "nopredict", "nomorph" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()

            inst.sg.statemem.isinsomniac = inst:HasTag("insomniac")

            if inst.components.rider ~= nil and inst.components.rider:IsRiding() then
                inst.sg:AddStateTag("dismounting")
                inst.AnimState:PlayAnimation("fall_off")
                inst.SoundEmitter:PlaySound("dontstarve/beefalo/saddle/dismount")
            else
                inst.AnimState:PlayAnimation(inst.sg.statemem.isinsomniac and "insomniac_dozy" or "dozy")
            end

            inst.sg:SetTimeout(TUNING.KNOCKOUT_SLEEP_TIME)
        end,

        ontimeout = function(inst)
            if inst.components.grogginess == nil then
                inst.sg.statemem.iswaking = true
                inst.sg:GoToState("wakeup")
            end
        end,

        events =
        {
            EventHandler("firedamage", function(inst)
                if inst.sg:HasStateTag("sleeping") then
                    inst.sg.statemem.iswaking = true
                    inst.sg:GoToState("wakeup")
                else
                    inst.sg.statemem.cometo = true
                end
            end),
            EventHandler("cometo", function(inst)
                if inst.sg:HasStateTag("sleeping") then
                    inst.sg.statemem.iswaking = true
                    inst.sg:GoToState("wakeup")
                else
                    inst.sg.statemem.cometo = true
                end
            end),
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    if inst.sg:HasStateTag("dismounting") then
                        inst.sg:RemoveStateTag("dismounting")
                        if inst.components.rider ~= nil then
                            inst.components.rider:ActualDismount()
                        end
                        inst.AnimState:PlayAnimation(inst.sg.statemem.isinsomniac and "insomniac_dozy" or "dozy")
                    elseif inst.sg.statemem.cometo then
                        inst.sg.statemem.iswaking = true
                        inst.sg:GoToState("wakeup")
                    else
                        inst.AnimState:PlayAnimation(inst.sg.statemem.isinsomniac and "insomniac_sleep_loop" or "sleep_loop", true)
                        inst.sg:AddStateTag("sleeping")
                    end
                end
            end),
        },

        onexit = function(inst)
            if inst.sg:HasStateTag("dismounting") and inst.components.rider ~= nil then
                --Interrupted
                inst.components.rider:ActualDismount()
            end
        end,
    },

    ------------------SLEEPING-----------------

	-- State{
    --     name = "sleep",
    --     tags = {"busy", "sleeping"},

    --     onenter = function(inst)
    --         inst.components.locomotor:Stop()

    --         inst.AnimState:OverrideSymbol("swap_bedroll", "swap_bedroll_straw", "bedroll_straw")
    --         inst.AnimState:PlayAnimation("bedroll",true) 
    --         inst.AnimState:PlayAnimation("action_uniqueitem_pre")
    --         inst.AnimState:PushAnimation("bedroll", false)
    --     end,

    --     events=
    --     {
    --         EventHandler("animqueueover", function(inst) inst.sg:GoToState("sleeping") end ),
    --         EventHandler("onwakeup", function(inst) inst.sg:GoToState("wakeup") end),
    --     },

    --     timeline=
    --     {
    --         TimeEvent(20 * FRAMES, function(inst) 
    --             inst.SoundEmitter:PlaySound("dontstarve/wilson/use_bedroll")
    --         end),
    --     },
    -- },

    -- State{
    --     name = "sleeping",
    --     tags = {"busy", "sleeping"},

    --     onenter = function(inst)
    --         inst.AnimState:PlayAnimation("bedroll_sleep_loop", true)
    --     end,

    --     events=
    --     {
    --         EventHandler("animover", function(inst) inst.sg:GoToState("sleeping") end ),
    --         EventHandler("onwakeup", function(inst) inst.sg:GoToState("wakeup") end),
    --     },
    -- },

    State{
        name = "wakeup",

        onenter = function(inst)
            if inst.AnimState:IsCurrentAnimation("bedroll") or
                inst.AnimState:IsCurrentAnimation("bedroll_sleep_loop") then
                inst.AnimState:PlayAnimation("bedroll_wakeup")
            elseif not (inst.AnimState:IsCurrentAnimation("bedroll_wakeup") or
                        inst.AnimState:IsCurrentAnimation("wakeup")) then
                inst.AnimState:PlayAnimation("wakeup")
				
            end
            inst.components.health:SetInvincible(true)
        end,
        
        onexit = function(inst)
            inst.components.health:SetInvincible(false)
        end,
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "frozen",
        tags = { "busy", "frozen", "nopredict", "nodangle" },
        
        onenter = function(inst)
            if inst.components.pinnable ~= nil and inst.components.pinnable:IsStuck() then
                inst.components.pinnable:Unstick()
            end

            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()

            inst.AnimState:OverrideSymbol("swap_frozen", "frozen", "frozen")
            inst.AnimState:PlayAnimation("frozen")
            inst.SoundEmitter:PlaySound("dontstarve/common/freezecreature")

            -- inst.components.inventory:Hide()
            -- inst:PushEvent("ms_closepopups")

            --V2C: cuz... freezable component and SG need to match state,
            --     but messages to SG are queued, so it is not great when
            --     when freezable component tries to change state several
            --     times within one frame...
            if inst.components.freezable == nil then
                inst.sg:GoToState("hit", true)
            elseif inst.components.freezable:IsThawing() then
                inst.sg.statemem.isstillfrozen = true
                inst.sg:GoToState("thaw")
            elseif not inst.components.freezable:IsFrozen() then
                inst.sg:GoToState("hit", true)
            end
        end,

        events =
        {
            EventHandler("onthaw", function(inst)
                inst.sg.statemem.isstillfrozen = true
                inst.sg:GoToState("thaw")
            end),
            EventHandler("unfreeze", function(inst)
                inst.sg:GoToState("hit", true)
            end),
        },

        onexit = function(inst)
            -- if not inst.sg.statemem.isstillfrozen then
            --     inst.components.inventory:Show()
            -- end
            inst.AnimState:ClearOverrideSymbol("swap_frozen")
        end,
    },

    State{
        name = "thaw",
        tags = { "busy", "thawing", "nopredict", "nodangle" },

        onenter = function(inst) 
            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()

            inst.AnimState:OverrideSymbol("swap_frozen", "frozen", "frozen")
            inst.AnimState:PlayAnimation("frozen_loop_pst", true)
            inst.SoundEmitter:PlaySound("dontstarve/common/freezethaw", "thawing")

            -- inst.components.inventory:Hide()
            -- inst:PushEvent("ms_closepopups")
        end,

        events =
        {
            EventHandler("unfreeze", function(inst)
                inst.sg:GoToState("hit", true)
            end),
        },

        onexit = function(inst)
            -- inst.components.inventory:Show()
            inst.SoundEmitter:KillSound("thawing")
            inst.AnimState:ClearOverrideSymbol("swap_frozen")
        end,
    },

    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.components.locomotor:Clear()
            inst:ClearBufferedAction()

            inst.SoundEmitter:PlaySound("dontstarve/wilson/death")

            if not inst:HasTag("mime") then
                inst.SoundEmitter:PlaySound((inst.talker_path_override or "dontstarve/characters/")..(inst.soundsname or inst.babydata.prefab).."/death_voice")
            end

            -- inst.components.inventory:DropEverything(true)

            inst.AnimState:Hide("swap_arm_carry")
            inst.AnimState:PlayAnimation("death")

            inst.components.burnable:Extinguish()

            --Don't process other queued events if we died this frame
            inst.sg:ClearBufferedEvents()
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst:Remove()
                end
            end),
        },
    },

    State{
        name = "hit",
        tags = {"busy"},

        onenter = function(inst)
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("hit")
            inst.Physics:Stop()
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        timeline =
        {
            TimeEvent(3*FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
        },
    },

    State{
        name = "stunned",
        tags = {"busy", "canrotate"},

        onenter = function(inst)
            inst:ClearBufferedAction()
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle_sanity_pre")
            inst.AnimState:PushAnimation("idle_sanity_loop", true)
            inst.sg:SetTimeout(5)
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("idle")
        end,
    },

    State{
        name = "chop_start",
        tags = {"prechop", "working"},

        onenter = function(inst)
            local buffaction = inst:GetBufferedAction()
            if buffaction ~= nil then
                -- inst.onequipwork(inst, buffaction.action)
                inst.sg.statemem.target = buffaction.target
            end

            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("chop_pre")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("chop")
                end
            end),
        },
    },
    State{--改进版本的砍树
        name = "chop",
        tags = {"prechop", "chopping", "working"},
        onenter = function(inst)
            local buffaction = inst:GetBufferedAction()
            inst.sg.statemem.target = buffaction ~= nil and buffaction.target or nil
            inst.AnimState:PlayAnimation("chop_loop")
        end,

        timeline=
        {
            TimeEvent(2*FRAMES, function(inst) 
                    inst:PerformBufferedAction() 
            end),
            TimeEvent(5 * FRAMES, function(inst)--9
		if inst then
                inst.sg:RemoveStateTag("prechop")
		end
            end),

            TimeEvent(12*FRAMES, function(inst)--12
		if inst then
                inst.sg:RemoveStateTag("chopping")
		end
            end),
        },
        
        events=
        {
            EventHandler("animover", function(inst) 
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end ),            
        },        
    },
	
    State{
        name = "mine_start",
        tags = {"premine", "working"},

        onenter = function(inst)
            local buffaction = inst:GetBufferedAction()
            if buffaction ~= nil then
                -- inst.onequipwork(inst, buffaction.action)
                inst.sg.statemem.target = buffaction.target
            end

            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("pickaxe_pre")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("mine")
                end
            end),
        },
    },

    State{
        name = "mine",
        tags = {"premine", "mining", "working"},

        onenter = function(inst)
            local buffaction = inst:GetBufferedAction()
            if buffaction ~= nil then
                -- inst.onequipwork(inst, buffaction.action)
                inst.sg.statemem.target = buffaction.target
            end

            inst.AnimState:PlayAnimation("pickaxe_loop")
        end,

        timeline =
        {
            TimeEvent(7 * FRAMES, function(inst)
                local target = inst.sg.statemem.target
                if target ~= nil and target:IsValid() then
                    if target.Transform ~= nil then
                        SpawnPrefab("mining_fx").Transform:SetPosition(target.Transform:GetWorldPosition())
                    end
                    inst.SoundEmitter:PlaySound(target:HasTag("frozen") and "dontstarve_DLC001/common/iceboulder_hit" or "dontstarve/wilson/use_pick_rock")
                end
                inst:PerformBufferedAction()
            end),

            TimeEvent(9 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("premine")
            end),
        },

        events =
        {
            EventHandler("animover", function(inst) 
                if inst.AnimState:AnimDone() then
                    inst.AnimState:PlayAnimation("pickaxe_pst") 
                    inst.sg:GoToState("idle", true)
                end
            end),
        },
    },

    State{
        name = "dig_start",
        tags = {"predig", "working"},

        onenter = function(inst)
            local buffaction = inst:GetBufferedAction()
            if buffaction ~= nil then
                -- inst.onequipwork(inst, buffaction.action)
                inst.sg.statemem.target = buffaction.target
            end

            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("shovel_pre")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("dig")
                end
            end),
        },
    },

    State{
        name = "dig",
        tags = {"predig", "digging", "working"},

        onenter = function(inst)
            local buffaction = inst:GetBufferedAction()
            if buffaction ~= nil then
                -- inst.onequipwork(inst, buffaction.action)
                inst.sg.statemem.target = buffaction.target
            end

            inst.AnimState:PlayAnimation("shovel_loop")
        end,

        timeline =
        {
            TimeEvent(15 * FRAMES, function(inst)
                inst:PerformBufferedAction()
                inst.SoundEmitter:PlaySound("dontstarve/wilson/dig")
            end),

            TimeEvent(35 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("predig")
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.AnimState:PlayAnimation("shovel_pst")
                    inst.sg:GoToState("idle", true)
                end
            end),
        },
    },

    State{
        name = "hammer_start",
        tags = { "prehammer", "working" },

        onenter = function(inst)
            local buffaction = inst:GetBufferedAction()
            if buffaction ~= nil then
                -- inst.onequipwork(inst, buffaction.action)
                inst.sg.statemem.target = buffaction.target
            end

            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("pickaxe_pre")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("hammer")
                end
            end),
        },
    },

    State{
        name = "hammer",
        tags = { "prehammer", "hammering", "working" },

        onenter = function(inst)
            local buffaction = inst:GetBufferedAction()
            if buffaction ~= nil then
                -- inst.onequipwork(inst, buffaction.action)
                inst.sg.statemem.target = buffaction.target
            end
            
            inst.AnimState:PlayAnimation("pickaxe_loop")
        end,

        timeline =
        {
            TimeEvent(7 * FRAMES, function(inst)
                inst:PerformBufferedAction()
                inst.sg:RemoveStateTag("prehammer")
                inst.SoundEmitter:PlaySound("dontstarve/wilson/hit")
            end),

            TimeEvent(9 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("prehammer")
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.AnimState:PlayAnimation("pickaxe_pst")
                    inst.sg:GoToState("idle", true)
                end
            end),
        },
    },
	--开始捕虫
    State{
        name = "bugnet_start",
        tags = { "prenet", "working", "autopredict" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("bugnet_pre")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("bugnet")
                end
            end),
        },
    },

    State{--抓捕
        name = "bugnet",
        tags = { "prenet", "netting", "working", "autopredict" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("bugnet")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/use_bugnet", nil, nil, true)
        end,

        timeline =
        {
            TimeEvent(10*FRAMES, function(inst) 
                inst:PerformBufferedAction() 
                inst.sg:RemoveStateTag("prenet") 
                inst.SoundEmitter:PlaySound("dontstarve/wilson/dig")
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },
	--钓鱼\垂钓--------------
    State{
        name = "fishing_pre",
        tags = { "prefish", "fishing" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("fishing_pre")
            inst.AnimState:PushAnimation("fishing_cast", false)
        end,

        timeline =
        {
            TimeEvent(13*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_cast") end),
            TimeEvent(15*FRAMES, function(inst) inst:PerformBufferedAction() end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_baitsplash")
                    inst.sg:GoToState("fishing")
                end
            end),
        },
    },
    State{
        name = "fishing",
        tags = { "fishing" },

        onenter = function(inst, pushanim)
            if pushanim then
                if type(pushanim) == "string" then
                    inst.AnimState:PlayAnimation(pushanim)
                end
                inst.AnimState:PushAnimation("fishing_idle", true)
            else
                inst.AnimState:PlayAnimation("fishing_idle", true)
            end
            local equippedTool = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
			--print("输出值为:"..tostring(equippedTool.prefab))
            if equippedTool and equippedTool.components.fishingrod then
                equippedTool.components.fishingrod:WaitForFish()
            end
        end,

        events = --等待鱼上钩事件(服务器端基于钓鱼组件发出的事件)
        {
            EventHandler("fishingnibble", function(inst) inst.sg:GoToState("fishing_nibble") end),
        },
    },
	--停止\终止\打断\钓鱼的处理
    State{
        name = "fishing_pst",

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("fishing_pst")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },
    State{--鱼咬食
        name = "fishing_nibble",
        tags = { "fishing", "nibble" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("bite_light_pre")
            inst.AnimState:PushAnimation("bite_light_loop", true)
            inst.sg:SetTimeout(1 + math.random())
            inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_fishinwater", "splash")
        end,
        timeline =
        {
            -- TimeEvent(2*FRAMES, function(inst) print("鱼咬勾了！！！！！") end),
			TimeEvent(15*FRAMES, function(inst) inst.sg:GoToState("fishing_strain") end),
		},
		--咬食时,超时就返回继续钓鱼
        ontimeout = function(inst)
            inst.sg:GoToState("fishing", "bite_light_pst")
        end,

        -- events = --once leftmouse --第一次鼠标点击,"上钩"触发的事件,客户端事件
        -- {
            -- EventHandler("fishingstrain", function(inst) inst.sg:GoToState("fishing_strain") end),
        -- },

        onexit = function(inst)
            inst.SoundEmitter:KillSound("splash")
        end,
    },

    State{
        name = "fishing_strain",
        tags = { "fishing" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("bite_heavy_pre")
            inst.AnimState:PushAnimation("bite_heavy_loop", true)
            inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_fishinwater", "splash")
            inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_strain", "strain")
        end,
        timeline =
        {
            -- TimeEvent(5*FRAMES, function(inst) print("收线啦!!!") end),
			----[[
			TimeEvent(25*FRAMES, function(inst)
				-- print("输出事件1")
				local equippedTool = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
				if equippedTool and equippedTool.components.fishingrod then
					-- print("输出事件2")
					-- equippedTool.components.fishingrod:Reel()
					-- local a = equippedTool.components.fishingrod.target	--pond_cave
					-- local a = equippedTool.components.fishingrod.hookedfish --nil
					-- local a = equippedTool.components.fishingrod.fisherman --pigguard
					-- local a = equippedTool.components.fishingrod.target.components.fishable:HookFish(inst.prefab)
					-- if a ~= nil then print(type(a),a.prefab) else print("是空值") end
					-- if a ~= nil then print(type(a)) else print("是空值") end
					--正确的处理：
					--由于不是调用鱼竿的组件:fishingrod:Hook()函数进入的该状态,所以需要手动填充Hook函数的返回值:148行
					----先追踪垂钓到的鱼对象
                    local target = equippedTool.components.fishingrod.target
                    if target then
                        --设置鱼竿fishingrod组件的钓到的鱼赋值.
                        equippedTool.components.fishingrod.hookedfish = target.components.fishable:HookFish(inst.prefab)
                        equippedTool.components.fishingrod:Reel()--调用鱼竿起竿(抽出调到的鱼)的函数,触发下面events里面的事件监听处理
                    end
				end
			end),
			--]]
			--分支宝宝高级钓鱼技能的预留接口
			-- TimeEvent(25*FRAMES, function(inst) inst.sg:GoToState("catchfish") end),--直接获得钓到鱼的状态
		},

        events = --second leftmouse --第二次鼠标点击,"收线".触发的事件,客户端事件
        {
            EventHandler("fishingcatch", function(inst, data)
				-- if data ~=nil then print("有成功数据") else print("无成功数据") end
                inst.sg:GoToState("catchfish", data.build)
            end),
            EventHandler("fishingloserod", function(inst)--这里暂时可以无视
				-- if data ~=nil then print("有失败数据") else print("无失败数据") end
                inst.sg:GoToState("loserod")
            end),

        },

        onexit = function(inst)
            inst.SoundEmitter:KillSound("splash")
            inst.SoundEmitter:KillSound("strain")
        end,
    },

    State{--钓鱼成功!
        name = "catchfish",
        tags = { "fishing", "catchfish", "busy" },
		
        onenter = function(inst, build)
            inst.AnimState:PlayAnimation("fish_catch")
            --print("Using ", build, " to swap out fish01")
            -- inst.AnimState:OverrideSymbol("fish01", "fish01", "fish01")
	
			-- inst.AnimState:OverrideSymbol("fish01", "fish01", "fish01")
			inst.AnimState:OverrideSymbol("fish01", build, "fish01")

            -- inst.AnimState:OverrideSymbol("fish_body", build, "fish_body")
            -- inst.AnimState:OverrideSymbol("fish_eye", build, "fish_eye")
            -- inst.AnimState:OverrideSymbol("fish_fin", build, "fish_fin")
            -- inst.AnimState:OverrideSymbol("fish_head", build, "fish_head")
            -- inst.AnimState:OverrideSymbol("fish_mouth", build, "fish_mouth")
            -- inst.AnimState:OverrideSymbol("fish_tail", build, "fish_tail")
        end,

        timeline =
        {
			-- TimeEvent(3*FRAMES, function(inst) print("急速钓鱼成功!") end),
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_fishcaught") end),
            TimeEvent(10*FRAMES, function(inst) inst.sg:RemoveStateTag("fishing") end),
            TimeEvent(23*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_fishland") end),
            TimeEvent(24*FRAMES, function(inst)
				--------
				-- local fishcrop = SpawnPrefab("fish")
				-- fishcrop.Transform:SetPosition(inst.Transform:GetWorldPosition())
				
				-- inst.components.inventory:GiveItem(SpawnPrefab("fish"))--或者直接给宝宝钓鱼的成果
				--------
				--官方的方法:
				-- local fishcrop = SpawnPrefab("fish")
				-- --设计钓上来的鱼的方法
				-- local spawnPos = inst.Transform:GetWorldPosition()--inst:GetPosition()
				-- local target = nil
				
				-- local equippedTool = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
				-- if equippedTool and equippedTool.components.fishingrod and target ~=nil then
					-- target = equippedTool.components.fishingrod.target
					-- local offset = spawnPos - target:GetPosition()
					-- spawnPos = spawnPos + offset:GetNormalized()
					-- if fishcrop.Physics ~= nil then
						-- fishcrop.Physics:SetActive(true)
						-- fishcrop.Physics:Teleport(spawnPos:Get())
					-- else
						-- fishcrop.Transform:SetPosition(spawnPos:Get())
					-- end
				-- end
				---------
                local equippedTool = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                if equippedTool and equippedTool.components.fishingrod then
                    equippedTool.components.fishingrod:Collect()
                end
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            inst.AnimState:ClearOverrideSymbol("fish01")
            -- inst.AnimState:ClearOverrideSymbol("fish_body")
            -- inst.AnimState:ClearOverrideSymbol("fish_eye")
            -- inst.AnimState:ClearOverrideSymbol("fish_fin")
            -- inst.AnimState:ClearOverrideSymbol("fish_head")
            -- inst.AnimState:ClearOverrideSymbol("fish_mouth")
            -- inst.AnimState:ClearOverrideSymbol("fish_tail")
        end,
    },

    State{--钓鱼收线失败
        name = "loserod",
        tags = { "busy", "nopredict" },

        onenter = function(inst)
            local equippedTool = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if equippedTool and equippedTool.components.fishingrod then
                equippedTool.components.fishingrod:Release()
                equippedTool:Remove()
            end
            inst.AnimState:PlayAnimation("fish_nocatch")
        end,

        timeline =
        {
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_lostrod") end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },	
	
	----------------------------------------------------------------------
	--新农田种植
    State--种植
    {
        name = "plantsoil",
        tags = { "doing", "busy" },

        onenter = function(inst, timeout)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("build_pre")
            inst.AnimState:PushAnimation("build_loop", true)
        end,

        timeline =
        {
            TimeEvent(9 * FRAMES, function(inst)
				local targ = inst:GetBufferedAction() and inst:GetBufferedAction().target or nil	--目标
				if targ and targ:IsValid() then
					local seed = CheckBodyItems(inst, "seeds") --临时方案,宝宝身上拿取
					if seed ~= nil then
						if seed.components.stackable and seed.components.stackable:IsStack() then--如果是堆叠的多个,只拿取1个使用
							seed = seed.components.stackable:Get(1)
						else
							seed = seed
						end
						PlantSoilItemsPress(inst, seed, targ)
					end
				end
				inst:PerformBufferedAction()
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
            end),
        },
        onexit = function(inst)
			if inst.AnimState:AnimDone() then
				inst.sg:GoToState("idle")
			end
        end,
    },
    State--对话
    {
        name = "interact_with",
        tags = { "doing", "busy" },

        onenter = function(inst, timeout)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("build_pre")
            inst.AnimState:PushAnimation("build_loop", true)
        end,

        timeline =
        {
            TimeEvent(9 * FRAMES, function(inst)
				--print("执行对话")
				inst:PerformBufferedAction()
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
            end),
        },
        onexit = function(inst)
			if inst.AnimState:AnimDone() then
				inst.sg:GoToState("idle")
			end
        end,
    },
	
    State--种植
    {
        name = "plant",
        tags = { "doing", "busy" },

        onenter = function(inst, timeout)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("build_pre")
            inst.AnimState:PushAnimation("build_loop", true)
        end,

        timeline =
        {
            TimeEvent(9 * FRAMES, function(inst)
				local targ = inst:GetBufferedAction() and inst:GetBufferedAction().target or nil
				if targ and targ:IsValid() and targ.components.grower and targ.components.grower:IsEmpty()
				and targ.components.grower:IsFertile() --检查农田是否贫瘠(肥沃度检查)
				then
				local seed = CheckBodyItems(inst, "seeds") --临时方案,宝宝身上拿取
				-- local bx = CheckBodyItems(inst) or nil--定义种子是自身上拿去还是去冰箱或仓库拿:临时方案,宝宝身上拿取
				if seed ~= nil then
					if seed.components.stackable and seed.components.stackable:IsStack() then--如果是堆叠的多个,只拿取1个使用
						seed = seed.components.stackable:Get(1)
					else
						seed = seed
					end
					targ.components.grower:PlantItem(seed)
				end
			end
			inst:PerformBufferedAction()
					inst.sg:RemoveStateTag("busy")
			inst.sg:GoToState("idle")
            end),
        },
        onexit = function(inst)
			if inst.AnimState:AnimDone() then
				inst.sg:GoToState("idle")
			end
        end,
    },
	--农田施肥
    State--施肥
    {
        name = "fertilize",
        tags = { "doing", "busy" },

        onenter = function(inst, timeout)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("build_pre")
            inst.AnimState:PushAnimation("build_loop", true)
        end,			
        timeline =
        {
            TimeEvent(9 * FRAMES, function(inst)
				local targ = inst:GetBufferedAction() and inst:GetBufferedAction().target or nil
				if targ and targ:IsValid() and targ.components.grower and targ.components.grower:IsEmpty()
				and targ.components.grower:GetFertilePercent() < .3 then
					local fertilizers = CheckBodyItems(inst, "fertilizer")
					if fertilizers ~= nil and targ.components.grower:Fertilize(fertilizers, inst) then
						if fertilizers.components.stackable and fertilizers.components.stackable:IsStack() then--如果是堆叠的多个,只拿取1个使用
							fertilizers = fertilizers.components.stackable:Get(1)
						else
							fertilizers = fertilizers
						end					
						targ.components.grower:Fertilize(fertilizers, inst)
					end
				end
				-- if inst.components.inventory then
					-- inst.components.inventory:DropEverything(false,false)
				-- end
				inst:PerformBufferedAction()
						inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
			end),
        },
        onexit = function(inst)
			if inst.AnimState:AnimDone() then
				inst.sg:GoToState("idle")
			end
        end,
    },
	
    State{--跳舞
        name = "dance",
        tags = {"idle", "dancing"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()
            if inst.AnimState:IsCurrentAnimation("run_pst") then
                inst.AnimState:PushAnimation("emoteXL_pre_dance0")
            else
                inst.AnimState:PlayAnimation("emoteXL_pre_dance0")
            end
            inst.AnimState:PushAnimation("emoteXL_loop_dance0", true)
        end,
    },
	------------------------------------------
	--青木的行为SG参考

	
	
	------------------------------------------
	--[[
	--增加其他协调表情系统
    State{
        name = "facepalm",
        tags = {"idle", "dancing"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()
            if inst.AnimState:IsCurrentAnimation("run_pst") then
                inst.AnimState:PushAnimation("emoteXL_pre_dance0")
            else
                inst.AnimState:PlayAnimation("emoteXL_pre_dance0")
            end
            inst.AnimState:PushAnimation("emoteXL_loop_dance0", true)
        end,
    },
	]]
}

return StateGraph("gd_playbaby", states, events, "idle", actionhandlers)
