--麋鹿鹅SG
require("stategraphs/commonstates")

--呼风唤雨
local function LightningStrike(inst)
    local rad = math.random(1,15)
    local angle = math.random() * 2 * PI
    local target = inst.components.combat and inst.components.combat.target or inst
    local pos = target:GetPosition() + Vector3(rad * math.cos(angle), 0, -rad * math.sin(angle))
	TheWorld:PushEvent("ms_sendlightningstrike", pos)
	TheWorld:PushEvent("ms_forceprecipitation", true)
end

local function GetSpawnLocation(inst, target)
    local tarPos = target:GetPosition()
    local pos = inst:GetPosition()
    local vec = tarPos - pos
    vec = vec:Normalize()
    local dist = pos:Dist(tarPos)
    return pos + (vec * (dist * .15))
end

--春鸭龙卷风
local function SpawnTornado(inst,target)
    if inst then
		--制造变异龙卷风
		local tornado = SpawnPrefab("tornado")
		tornado.Transform:SetScale(2, 2, 2)
		tornado:AddComponent("timer")
		tornado:ListenForEvent("timerdone", function(inst)
			if math.random() < 0.25 then
				LightningStrike(inst)
			end
		end)
		tornado:SetStateGraph("SGtornado_moose")
		if tornado.task then
			tornado.task:Cancel()
			tornado.task = nil
		end
		if inst.anger then
			tornado:SetDuration(1.5)
		else
			tornado:SetDuration(5)
		end
		
		if target then
			local spawnPos = inst:GetPosition() + TheCamera:GetDownVec()
			local totalRadius = target.Physics and target.Physics:GetRadius() or 0.5 + tornado.Physics:GetRadius() + 0.5
			local targetPos = target:GetPosition() + (TheCamera:GetDownVec() * totalRadius)
			tornado.Transform:SetPosition(GetSpawnLocation(inst, target):Get())
			tornado.components.knownlocations:RememberLocation("target", targetPos)
		else
			local targetPos = inst:GetPosition()
			tornado.Transform:SetPosition(GetSpawnLocation(inst, inst):Get())
			tornado.components.knownlocations:RememberLocation("target", targetPos)
		end
    end
end

--产蛋
local function SpawnEgg(inst)
	if GetBoost(inst,1) then
		local findEgg = FindEntity(inst, 25, function(guy)
			return guy.prefab == "mooseegg" --and guy.EggHatched
		end,
		nil,
		{ "INLIMBO", "NOCLICK" })
		local egg = findEgg or SpawnPrefab("mooseegg")
		local eggPos = nil
		if findEgg == nil then
			local offset = FindWalkableOffset(inst:GetPosition(), math.random() * 2 * math.pi, 4, 12) or Vector3(0,0,0)
			eggPos = offset + inst:GetPosition()
			egg.Transform:SetPosition(eggPos:Get())
		else
			eggPos = findEgg:GetPosition()
		end
		TheWorld:PushEvent("ms_sendlightningstrike", eggPos)
		inst.components.entitytracker:TrackEntity("egg", egg)
		egg.components.entitytracker:TrackEntity("mother", inst)
		if egg.components.guardian ~= nil then
			egg.components.guardian:SetGuardian(inst)
		end
		egg:InitEgg()
	end
end

--暴怒被动
local function Moose_AngerSkill(inst)
	TUNING.MOOSE_ATTACK_PERIOD = 1
	for i =1,3 do
		SpawnTornado(inst,inst.components.combat.target)
	end
end

local actionhandlers = {
	ActionHandler(ACTIONS.EAT, "eat_loop"),
	ActionHandler(ACTIONS.PICKUP, "action"),
	ActionHandler(ACTIONS.HARVEST, "action"),
	ActionHandler(ACTIONS.PICK, "action"),
	ActionHandler(ACTIONS.LAYEGG, "layegg"),
	ActionHandler(ACTIONS.GOHOME, "flyaway"),
}

local events= {
	EventHandler("locomote",
	function(inst)
		if (not inst.sg:HasStateTag("idle") and not inst.sg:HasStateTag("moving")) then
			return
		end
		if not inst.components.locomotor:WantsToMoveForward() then
			if not inst.sg:HasStateTag("idle") then
				inst.sg:GoToState("idle", {softstop = true})
			end
		else
			if not inst.sg:HasStateTag("hopping") then
				inst.sg:GoToState("hop")
			end
		end
	end),
	CommonHandlers.OnSleep(),
	CommonHandlers.OnFreeze(),
	EventHandler("doattack", function(inst)
		if inst.components.health and not inst.components.health:IsDead() and (inst.sg:HasStateTag("hit") or not inst.sg:HasStateTag("busy")) then
			if inst.CanDisarm then
				inst.sg:GoToState("disarm")
			else
				inst.sg:GoToState("attack")
			end
			if inst.skill_cd and not inst.components.timer:TimerExists("skill_cd") then
				if GetBoost(inst,1) then
					inst.sg:GoToState("moose_skill1")
				elseif GetBoost(inst,2) then
					inst.sg:GoToState("moose_skill2")
				end
			end
		end
		if math.random() < 0.2 then
			local target = inst.components.combat.target
			if target and target:HasTag("player") then
				SpawnPrefab("er_tips_label"):set("<触电中>", 1).Transform:SetPosition(target.Transform:GetWorldPosition())
				target.components.locomotor:Stop()
				target.sg:GoToState("electrocute")
			end
		end
	end),
	CommonHandlers.OnAttacked(),
	CommonHandlers.OnDeath(),
	EventHandler("flyaway", function(inst)
		if not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") then
			inst.sg:GoToState("flyaway")
		end
	end),
}

local states = {
	State{
        name = "moose_skill1",
        tags = {"attack", "busy"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt_pre")
            inst.AnimState:PushAnimation("taunt")
            inst.AnimState:PushAnimation("taunt_pst", false)

			SpawnTornado(inst, inst.components.combat.target)
			if not inst.components.timer:TimerExists("skill_cd") then
				inst.components.timer:StartTimer("skill_cd", inst.skill_cd or 1)
			end
			
			if inst and not inst.components.combat.target then
				inst.sg:GoToState("idle")
			end
        end,
        timeline = {
			TimeEvent(9*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/flap")
			end),
            TimeEvent(11*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/taunt")
			end),
            TimeEvent(17*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/flap") 
            	inst.components.burnable:Extinguish()
			end),
        },
        events = {
            EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("idle")
			end),
        },
		ontimeout = function(inst)
			inst.sg:GoToState("idle", true)
			local target = inst.components.combat.target 
			if target and target:HasTag("player")  then
				target.sg:GoToState("idle", true)
			end
		end,
		onexit = function(inst)
			if inst.components.playercontroller then
				inst.components.playercontroller:Enable(true)
			end
			local target = inst.components.combat.target 
			if target and target:HasTag("player") then
				if target.components.playercontroller then
					target.components.playercontroller:Enable(true)
				end
			end
		end,
    },

	State{
        name = "moose_skill2",
        tags = {"attack", "busy"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt_pre")
            inst.AnimState:PushAnimation("taunt")
            inst.AnimState:PushAnimation("taunt_pst", false)
			
			local x, y, z = inst.Transform:GetWorldPosition()
			local targetlist = TheSim:FindEntities(x, y, z, 20, {"player"}, {"playerghost"})
			for k, v in pairs(targetlist) do
				SpawnPrefab("er_tips_label"):set("<触电中>", 1).Transform:SetPosition(v.Transform:GetWorldPosition())
				v.components.locomotor:Stop()
				v.sg:GoToState("electrocute")
				SpawnTornado(inst, v)
			end
			if not inst.components.timer:TimerExists("skill_cd") then
				inst.components.timer:StartTimer("skill_cd", inst.skill_cd or 1)
			end
			
			if inst and not inst.components.combat.target then
				inst.sg:GoToState("idle")
			end
        end,
		onupdate = function(inst)
			
		end,
        timeline = {
			TimeEvent(9*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/flap")
			end),
            TimeEvent(11*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/taunt")
			end),
            TimeEvent(17*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/flap") 
            	inst.components.burnable:Extinguish()
			end),
        },
        events = {
            EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("idle")
			end),
        },
		ontimeout = function(inst)
			inst.sg:GoToState("idle", true)
			local target = inst.components.combat.target 
			if target and target:HasTag("player")  then
				target.sg:GoToState("idle", true)
			end
		end,
		onexit = function(inst)
			if inst.components.playercontroller then
				inst.components.playercontroller:Enable(true)
			end
			local target = inst.components.combat.target 
			if target and target:HasTag("player") then
				if target.components.playercontroller then
					target.components.playercontroller:Enable(true)
				end
			end
			--inst.Light:Enable(false)
		end,
    },
	
	State{
		name = "idle",
		tags = {"idle", "canrotate"},
		onenter = function(inst, data)
			inst.Physics:Stop()
			if data and data.softstop then
				inst.AnimState:PushAnimation("idle", true)
			else
				inst.AnimState:PlayAnimation("idle", true)
			end
			inst.sg:SetTimeout(math.random()*10+2)
		end,
		timeline = {},
		ontimeout= function(inst)
			inst.sg:GoToState((math.random() < 0.5 and "preen" or "twitch"))
		end,
	},

	State{
		name = "twitch",
		tags = {"idle"},
		onenter = function(inst, playanim)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("idle_2")
		end,
		events = {
			EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("idle")
			end)
		}
	},

	State{
		name = "preen",
		tags = {"idle"},
		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("idle_3")
		end,
		events = {
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end)
		},
		timeline = {
			TimeEvent(11*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/preen")
			end),
			TimeEvent(14*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/preen_feathers")
			end),
		},
	},

	State{
		name = "hop",
		tags = {"moving", "canrotate", "hopping"},
		onenter = function(inst)
			inst.AnimState:PlayAnimation("hop")
			PlayFootstep(inst)
			inst.components.locomotor:WalkForward()
			inst.sg:SetTimeout(math.random()+.5)
		end,
		onupdate= function(inst)
			if not inst.components.locomotor:WantsToMoveForward() then
				inst.sg:GoToState("idle")
			end
		end,
		timeline = {
			TimeEvent(1*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/attack")
			end),
			TimeEvent(9*FRAMES, function(inst)
				inst.Physics:Stop()
				ShakeAllCameras(CAMERASHAKE.FULL, .35, .02, 1.25, inst, 40)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/land")
			end),
		},
		ontimeout = function(inst)
            inst.sg:GoToState("hop")
		end,
	},

	State{
		name = "action",
		tags = {"busy"},
		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("action")
			inst.AnimState:PushAnimation("eat", false)
		end,
		timeline = {
			TimeEvent(FRAMES*1, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/attack") end),
			TimeEvent(10*FRAMES, function(inst)
				inst:PerformBufferedAction()
				inst.sg:RemoveStateTag("busy")
                if inst.brain ~= nil then
                    inst.brain:ForceUpdate()
                end
				inst.sg:AddStateTag("wantstoeat")
			end),
		},
		events = {
			EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("eat_pst")
			end)
		},
	},

	State{
		name = "eat_loop",
		tags = {"busy"},
		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PushAnimation("eat", true)
			inst.sg:SetTimeout(math.random()*2+1)
		end,
		timeline = {},
		ontimeout = function(inst)
			inst:PerformBufferedAction()
			inst.sg:GoToState("eat_pst")
		end,
	},

	State{
		name = "eat_pst",
		tags = {"busy"},
		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("eat_pst")
		end,
		timeline = {},
		events = {
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	},

	State{
		name = "taunt",
		tags = {"busy"},
		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("taunt_pre")
			inst.AnimState:PushAnimation("taunt")
			inst.AnimState:PushAnimation("taunt_pst", false)
		end,
		timeline = {
			TimeEvent(9*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/flap")
			end),
			TimeEvent(11*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/taunt")
			end),
		},
		events = {
			EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	},

	State{
		name = "glide",
		tags = {"flight", "busy"},
		onenter= function(inst)
			inst.AnimState:PlayAnimation("glide", true)
			inst.Physics:SetMotorVelOverride(0,-11,0)
			inst.flapSound = inst:DoPeriodicTask(6*FRAMES,
			function(inst)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/flap")
			end)
		end,
		onupdate = function(inst)
			inst.Physics:SetMotorVelOverride(0,-15,0)
			local pt = Point(inst.Transform:GetWorldPosition())
			if pt.y < 2 then
				inst.Physics:ClearMotorVelOverride()
				pt.y = 0
				inst.Physics:Stop()
				inst.Physics:Teleport(pt.x,pt.y,pt.z)
				inst.AnimState:PlayAnimation("land")
				inst.DynamicShadow:Enable(true)
				inst.sg:GoToState("idle", {softstop = true})
				ShakeAllCameras(CAMERASHAKE.FULL, .35, .02, 1.25, inst, 40)
			end
		end,
		onexit = function(inst)
			if inst.flapSound then
				inst.flapSound:Cancel()
				inst.flapSound = nil
			end
			if inst:GetPosition().y > 0 then
				local pos = inst:GetPosition()
				pos.y = 0
				inst.Transform:SetPosition(pos:Get())
			end
			inst.components.knownlocations:RememberLocation("landpoint", inst:GetPosition())
		end,
	},

	State{
		name = "flyaway",
		tags = {"flight", "busy"},
		onenter = function(inst)
			inst.Physics:Stop()
			inst.DynamicShadow:Enable(false)
			inst.AnimState:PlayAnimation("takeoff_pre_vertical")
			inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/flap")
			inst.sg.statemem.flapSound = 9*FRAMES
		end,
		onupdate = function(inst, dt)
			inst.sg.statemem.flapSound = inst.sg.statemem.flapSound - dt
			if inst.sg.statemem.flapSound <= 0 then
				inst.sg.statemem.flapSound = 6*FRAMES
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/flap")
			end
		end,
		timeline = {
			TimeEvent(9*FRAMES, function(inst)
				inst.AnimState:PushAnimation("takeoff_vertical", true)
				inst.Physics:SetMotorVel(math.random()*4,7+math.random()*2,math.random()*4)
			end),
			TimeEvent(10, function(inst) inst:Remove() end)
		}
	},

	State{
		name = "disarm",
		tags = {"busy"},
		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("honk")
		end,
		timeline = {
			TimeEvent(2*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/flap") end),
			TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/flap") end),
			TimeEvent(11*FRAMES, function(inst)
				PlayFootstep(inst)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/swhoosh")
			end),
			TimeEvent(12*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/honk")
				if inst.components.combat.target and inst.components.combat.target.ShakeCamera then
					inst.components.combat.target:ShakeCamera(CAMERASHAKE.FULL, 0.75, 0.01, 2, 40)
				end
			end),
			TimeEvent(15*FRAMES, function(inst)
				--解除武装
				local target = inst.components.combat.target
				local item = nil
				if target and target.components.inventory then
					item = target.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
				end
				if item and item.Physics then
					target.components.inventory:DropItem(item)
					local x, y, z = item:GetPosition():Get()
					y = .1
					item.Physics:Teleport(x,y,z)
					local hp = target:GetPosition()
					local pt = inst:GetPosition()
					local vel = (hp - pt):GetNormalized()
					local speed = 5 + (math.random() * 2)
					local angle = math.atan2(vel.z, vel.x) + (math.random() * 20 - 10) * DEGREES
					item.Physics:SetVel(math.cos(angle) * speed, 10, math.sin(angle) * speed)
				end
				inst.CanDisarm = false
				
				if inst.components.entitytracker:GetEntity("egg") then
            		LightningStrike(inst)
                end
			end),
			TimeEvent(29*FRAMES, function(inst)
				PlayFootstep(inst)
				if not inst.components.entitytracker:GetEntity("egg") then
					SpawnEgg(inst)
				end
			end),
		},
		events = {
			EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("idle")
			end ),
		},
	},

	State{
		name = "layegg",
		tags = {"busy"},
		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("honk")
			inst.AnimState:PushAnimation("idle", false)
		end,
		timeline = {
			TimeEvent(2*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/flap")
			end),
			TimeEvent(10*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/flap")
			end),
			TimeEvent(12*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/honk")
			end),
			TimeEvent(15*FRAMES, function(inst)
				TheWorld:PushEvent("ms_forceprecipitation", true)
			end),
			TimeEvent(50*FRAMES, function(inst)
				SpawnEgg(inst)
			end),
		},
		events = {
			EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("idle")
			end ),
		},

	},

	State {
		name = "death",
		tags = { "busy" },
		onenter = function(inst)
			if inst.components.locomotor then
				inst.components.locomotor:StopMoving()
			end
			inst.AnimState:PlayAnimation("death")
			RemovePhysicsColliders(inst)
		end,
		timeline = {
			TimeEvent(0*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/death")
			end),
			TimeEvent(22*FRAMES, function(inst)
				ShakeAllCameras(CAMERASHAKE.FULL, .7, .02, 3., inst, 40)
				DoBoost(inst)
			end)
		},
	},

	State {
		name = "attack",
		tags = { "attack", "busy", "canrotate" },
		onenter = function(inst)
			if inst.components.locomotor then
				inst.components.locomotor:StopMoving()
			end
			inst.components.combat:StartAttack()
			inst.AnimState:PlayAnimation("atk")
		end,
		timeline = {
			TimeEvent(0*FRAMES, function(inst)
				PlayFootstep(inst)
			end),
			TimeEvent(13*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/swhoosh")
			end),
			TimeEvent(19*FRAMES, function(inst)
				PlayFootstep(inst)
			end),
			TimeEvent(20*FRAMES, function(inst)
				if not inst.components.timer:TimerExists("DisarmCooldown") then
					inst.components.timer:StartTimer("DisarmCooldown", 10)
				end
				inst.components.combat:DoAttack(inst.sg.statemem.target)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/attack")
			end),
			TimeEvent(25*FRAMES, function(inst)
				inst.sg:RemoveStateTag("attack")
			end),
		},
		events = {
			EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("idle")
				if inst.anger and math.random() < 0.3 then
					Moose_AngerSkill(inst)
				end
			end),
		},
	},
}

CommonStates.AddFrozenStates(states)
CommonStates.AddSleepStates(states,{
	sleeptimeline = {
		TimeEvent(22*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/sleep")
		end),
	},
})

return StateGraph("moose", states, events, "idle", actionhandlers)