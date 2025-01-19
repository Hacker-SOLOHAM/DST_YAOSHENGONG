require("stategraphs/commonforgestates")

--地震
local function GroundPound(inst,key)
	ShakeAllCameras(CAMERASHAKE.FULL, 0.5, 0.03, 0.5, inst, 30)
	inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/bonehit2")
	inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/trails/bodyfall")
	inst.SoundEmitter:PlaySound(inst.sounds.hit_2)
	ShortAttack(inst,inst.components.combat.defaultdamage,6,key)
end

local skillcdli = {8,20,30}		--技能cd
local events = {
	CommonForgeHandlers.OnAttacked(),
	CommonForgeHandlers.OnKnockback(),
	CommonForgeHandlers.OnVictoryPose(),
	CommonHandlers.OnDeath(),
	CommonHandlers.OnFossilize(),
	CommonHandlers.OnFreeze(),
	EventHandler("doattack", function(inst, data)
		if not inst.components.health:IsDead() and data.target and data.target:IsValid() then
		-- local statename = "pose"
			local statename = "attack1"
			if GetTime() - inst.skillcd1 > skillcdli[1] then
				statename = "tantrum"		--连续捶地
				inst.skillcd1 = GetTime()
			elseif GetTime() - inst.skillcd2 > skillcdli[2] then
				statename = "banner_pre"	--召唤
				inst.skillcd2 = GetTime()
			elseif GetTime() - inst.skillcd3 > skillcdli[2] then
				statename = "pose"			--回血
				inst.skillcd3 = GetTime()
			end
			inst.sg:GoToState(statename,data.target)
		end
	end),
	EventHandler("locomote", function(inst, data)
		local is_moving = inst.sg:HasStateTag("moving")
		local is_running = inst.sg:HasStateTag("running")
		local is_idling = inst.sg:HasStateTag("idle")

		local should_move = inst.components.locomotor:WantsToMoveForward()
		local should_run = inst.is_guarding and inst.components.locomotor:WantsToRun()

		if is_moving and not should_move then
			inst.sg:GoToState(is_running and "run_stop" or "walk_stop")
		elseif is_idling and should_move then
			inst.sg:GoToState(should_run and "run_start" or "walk_start")
		end
	end),
}

local states = {
	State{
		name = "idle",
		tags = {"idle", "canrotate"},
		onenter = function(inst, playanim)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("idle_loop", true)
		end,
	},

	State{
		name = "jab",
		tags = {"attack", "busy"},
		onenter = function(inst, target)
			inst.sg.statemem.target = target
			inst.components.locomotor:Stop()
			inst.components.combat:StartAttack()
			inst.AnimState:PlayAnimation("block_counter")
			inst.SoundEmitter:PlaySound(inst.sounds.swipe)
		end,
		timeline = {
			TimeEvent(6*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.attack)
				ShortAttack(inst.sg.statemem.target,inst.components.combat.defaultdamage,4,1)
			end),
		},
		events = {
			CommonForgeHandlers.IdleOnAnimOver(),
		},
	},

	State{
		name = "attack1",
		tags = {"attack", "busy"},
		onenter = function(inst, target)
			inst.sg.statemem.target = target
			inst.components.locomotor:Stop()
			inst.components.combat:StartAttack()
			inst.AnimState:PlayAnimation("attack2", false)
			inst.SoundEmitter:PlaySound(inst.sounds.swipe)
		end,
		timeline = {
			TimeEvent(6*FRAMES, function(inst)
				ShortAttack(inst.sg.statemem.target,inst.components.combat.defaultdamage,4)
			end),
		},
		events = {
			EventHandler("animover", function(inst)
				if math.random() < 0.7 then
					inst.sg:GoToState("attack2", inst.sg.statemem.target)
				else
					inst:DoTaskInTime(0.03, function()
						inst.sg:GoToState("idle")
					end)
				end
			end),
		},
	},

	State{
		name = "attack2",
		tags = {"attack", "busy"},
		onenter = function(inst, target)
			inst.sg.statemem.target = target
			inst.components.locomotor:Stop()
			inst.components.combat:StartAttack()
			inst.AnimState:PlayAnimation("attack3", false)
			inst.SoundEmitter:PlaySound(inst.sounds.swipe)
		end,
		timeline = {
			TimeEvent(7*FRAMES, function(inst)
				ShortAttack(inst.sg.statemem.target,inst.components.combat.defaultdamage,4,1)
			end),
		},
		events = {
			EventHandler("animover", function(inst)
				if math.random() < 0.5 then
					inst.sg:GoToState("attack3", inst.sg.statemem.target)
				else
					inst:DoTaskInTime(0.03, function()
						inst.sg:GoToState("idle")
					end)
				end
			end),
		},
	},

	State{
		name = "attack3",
		tags = {"busy", "slamming", "nofreeze", "keepmoving"},
		onenter = function(inst, target)
			inst.sg.statemem.target = target
			inst.components.locomotor:Stop()
			inst.components.combat:StartAttack()
			inst.AnimState:PlayAnimation("bellyflop_block_pre", false)
			inst.AnimState:PushAnimation("bellyflop", false)
			inst.SoundEmitter:PlaySound(inst.sounds.jump)
		end,
		timeline = {
			TimeEvent(10*FRAMES, function(inst)
				inst.Physics:Teleport(inst.sg.statemem.target.Transform:GetWorldPosition())
			end),
			TimeEvent(23*FRAMES, function(inst)
				inst.components.locomotor:Stop()
				GroundPound(inst,2)
			end),
		},
		events = {
			CommonForgeHandlers.IdleOnAnimOver(),
		},
	},

	State{
		name = "tantrum",
		tags = {"busy"},
		onenter = function(inst, force)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("taunt2")
		end,
		timeline = {
			TimeEvent(8*FRAMES, function(inst)
				GroundPound(inst)
			end),
			TimeEvent(11*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.hit_2)
			end),
			TimeEvent(14*FRAMES, function(inst)
				GroundPound(inst,2)
			end),
			TimeEvent(24*FRAMES, function(inst)
				GroundPound(inst,1)
			end),
		},
		events = {
			CommonForgeHandlers.IdleOnAnimOver(),
		},
	},

	State{
		name = "banner_pre",
		tags = {"busy", "nointerrupt"},
		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("taunt")
		end,
		events = {
			EventHandler("animover", function(inst)
				SpawnBanner(inst,"forge_biology003",6,{3,9})
				inst.sg:GoToState("idle")
			end),
		},
	},

	State{
		name = "hit",
		tags = {"busy", "hit"},
		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("hit")
			inst.SoundEmitter:PlaySound(inst.sounds.hit)
		end,
		events = {
			CommonForgeHandlers.IdleOnAnimOver(),
		},
	},

	State{
		name = "death",
		tags = {"busy"},
		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("death")
			inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
		end,
		timeline = {
			TimeEvent(0, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/death")
				ShakeAllCameras(CAMERASHAKE.FULL, 0.5, 0.03, 0.5, inst, 30)
			end),
			TimeEvent(13*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/slurtle/shatter")
			end),
			TimeEvent(43*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/bonehit2")
				ShakeAllCameras(CAMERASHAKE.FULL, 0.5, 0.03, 0.5, inst, 30)
			end),
			TimeEvent(62*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.hit_2)
				ShakeAllCameras(CAMERASHAKE.FULL, 0.5, 0.03, 0.5, inst, 30)
			end),
		},
	},

	State{
		name = "pose",
		tags = {"busy", "posing" , "idle"},
		onenter = function(inst)
			inst.Physics:Stop()
			-- inst.components.health.invincible = true
			inst.AnimState:PlayAnimation("end_pose_pre", false)
			inst.AnimState:PushAnimation("end_pose_loop", true)
		end,
		onexit = function(inst)
			-- inst.components.health.invincible = false
		end,
		timeline = {
			TimeEvent(1, function(inst)
				inst.AnimState:PushAnimation("end_pose_loop", true)
				inst.components.health:DoDelta(inst.components.health.maxhealth*0.1)
			end),
			TimeEvent(2, function(inst)
				inst.AnimState:PushAnimation("end_pose_loop", true)
				inst.components.health:DoDelta(inst.components.health.maxhealth*0.1)
			end),
			TimeEvent(3, function(inst)
				inst.AnimState:PushAnimation("end_pose_loop", true)
				inst.components.health:DoDelta(inst.components.health.maxhealth*0.1)
			end),
		},
		events = {
			CommonForgeHandlers.IdleOnAnimOver(),
		},
	},
}

CommonStates.AddRunStates(states, {
	runtimeline = {
		TimeEvent(5*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
			ShakeAllCameras(CAMERASHAKE.FULL, 0.25, 0.015, 0.25, inst, 10)
		end),
		TimeEvent(15*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
			ShakeAllCameras(CAMERASHAKE.FULL, 0.25, 0.015, 0.25, inst, 10)
		end),
	},
	endtimeline = {
		TimeEvent(2*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
			ShakeAllCameras(CAMERASHAKE.FULL, 0.25, 0.015, 0.25, inst, 10)
		end),
		TimeEvent(4*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
			ShakeAllCameras(CAMERASHAKE.FULL, 0.25, 0.015, 0.25, inst, 10)
		end),
	},
})
CommonStates.AddWalkStates(states, {
	walktimeline = {
		TimeEvent(0, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
		TimeEvent(15*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
			ShakeAllCameras(CAMERASHAKE.FULL, 0.25, 0.015, 0.25, inst, 10)
		end),
	},
	endtimeline = {
		TimeEvent(7*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
			ShakeAllCameras(CAMERASHAKE.FULL, 0.25, 0.015, 0.25, inst, 10)
		end),
	},
})
local function PlayChestPoundSounds(inst)
	inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boarrior/bonehit2")
	inst.SoundEmitter:PlaySound(inst.sounds.hit_2)
end
CommonForgeStates.AddSpawnState(states, {
	TimeEvent(10*FRAMES, function(inst)
		inst.SoundEmitter:PlaySound(inst.sounds.taunt)
		ShakeAllCameras(CAMERASHAKE.FULL, 0.8, 0.03, 0.5, inst, 30)
	end),
	TimeEvent(24*FRAMES, PlayChestPoundSounds),
	TimeEvent(28*FRAMES, PlayChestPoundSounds),
	TimeEvent(32*FRAMES, PlayChestPoundSounds),
	TimeEvent(36*FRAMES, PlayChestPoundSounds),
})
CommonForgeStates.AddKnockbackState(states)
CommonForgeStates.AddKnockbackState(states)

return StateGraph("swineclops", states, events, "spawn")