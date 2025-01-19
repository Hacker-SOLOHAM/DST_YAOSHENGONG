require("stategraphs/commonforgestates")

local skillcdli = {5,10,15,10}		--技能cd
local events = {
	CommonForgeHandlers.OnAttacked(),
	CommonForgeHandlers.OnKnockback(),
	CommonHandlers.OnDeath(),
	CommonHandlers.OnSleep(),
	CommonHandlers.OnFossilize(),
	EventHandler("attacked", function(inst, data)
		local target = inst.components.combat.target
		if target and GetTime() - inst.skillcd4 > skillcdli[4] then
			inst.sg:GoToState("dash",inst.components.combat.target)	--瞬击
			inst.skillcd4 = GetTime()
		end
	end),
	EventHandler("doattack", function(inst, data)
		if not inst.components.health:IsDead() and data.target and data.target:IsValid() then
			local statename = "attack1"
			if GetTime() - inst.skillcd1 > skillcdli[1] then
				statename = "attack_slam"	--钉耙
				inst.skillcd1 = GetTime()
			elseif GetTime() - inst.skillcd2 > skillcdli[2] then
				statename = "attack_spin"	--转转转
				inst.skillcd2 = GetTime()
			elseif GetTime() - inst.skillcd3 > skillcdli[2] then
				statename = "banner_pre"	--召唤
				inst.skillcd3 = GetTime()
			end
			inst.sg:GoToState(statename,data.target)
		end
	end),
	CommonHandlers.OnLocomote(false,true),
}

local states = {
	State{
		name = "banner_pre",
		tags = {"busy", "nointerrupt"},
		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("banner_pre")
			SpawnBanner(inst,"forge_biology001",6,{6,12})
		end,
		timeline = {
			TimeEvent(5*FRAMES, function(inst)
				inst.AnimState:PlayAnimation("banner_loop", true)
				inst.SoundEmitter:PlaySound(inst.sounds.banner_call_a)
			end),
			TimeEvent(18*FRAMES, function(inst)
				inst.AnimState:PlayAnimation("banner_loop", true)
				inst.SoundEmitter:PlaySound(inst.sounds.banner_call_a)
			end),
			TimeEvent(31*FRAMES, function(inst)
				inst.AnimState:PlayAnimation("banner_loop", true)
				inst.SoundEmitter:PlaySound(inst.sounds.banner_call_a)
			end),
			TimeEvent(46*FRAMES, function(inst)
				inst.AnimState:PlayAnimation("banner_pst", true)
			end),
		},
		events = {
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	},

	State{
		name = "attack1",
		tags = {"attack", "busy", "pre_attack"},
		onenter = function(inst, target)
			inst.sg.statemem.target = target
			inst.components.combat:StartAttack()
			inst.components.locomotor:Stop()
			inst:ForceFacePoint(target:GetPosition())
			inst.AnimState:PlayAnimation("attack1")
			inst.SoundEmitter:PlaySound(inst.sounds.swipe_pre)
			ShortAttack(inst.sg.statemem.target,inst.components.combat.defaultdamage,4)
		end,
		timeline = {
			TimeEvent(6*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.swipe)
			end),
		},
		events = {
			EventHandler("animqueueover", function(inst)
				if math.random() < 0.7 then
					inst.sg:GoToState("attack2", inst.sg.statemem.target)
				else
					inst.AnimState:PlayAnimation("attack1_pst", false)
					inst:DoTaskInTime(0.4, function()
						inst.sg:GoToState("idle")
					end)
				end
			end),
		},
	},

	State{
		name = "attack2",
		tags = {"attack", "busy", "pre_attack"},
		onenter = function(inst, target)
			inst.sg.statemem.target = target
			inst.components.locomotor:Stop()
			inst:ForceFacePoint(target:GetPosition())
			inst.AnimState:PlayAnimation("attack2")
			inst.Physics:SetMotorVelOverride(10,0,0)
			inst.SoundEmitter:PlaySound(inst.sounds.swipe_pre)
			ShortAttack(target,inst.components.combat.defaultdamage,4,2)
		end,
		timeline = {
			TimeEvent(6, function(inst)
				inst.Physics:ClearMotorVelOverride()
				inst.SoundEmitter:PlaySound(inst.sounds.swipe)
			end),
		},
		events = {
			EventHandler("animqueueover", function(inst)
				if math.random() < 0.5 then
					inst.sg:GoToState("attack3", inst.sg.statemem.target)
				else
					inst.AnimState:PlayAnimation("attack1_pst", false)
					inst:DoTaskInTime(0.4, function()
						inst.sg:GoToState("idle")
					end)
				end
			end),
		},
	},

	State{
		name = "attack3",
		tags = {"attack", "busy", "pre_attack"},
		onenter = function(inst, target)
			inst.sg.statemem.target = target
			inst.components.locomotor:Stop()
			inst:ForceFacePoint(target:GetPosition())
			inst.AnimState:PlayAnimation("attack3")
			inst.Physics:SetMotorVelOverride(10,0,0)
			inst.SoundEmitter:PlaySound(inst.sounds.swipe_pre)
			ShortAttack(inst.sg.statemem.target,inst.components.combat.defaultdamage,4,1)
		end,
		timeline = {
			TimeEvent(6*FRAMES, function(inst)
				inst.Physics:ClearMotorVelOverride()
				inst.SoundEmitter:PlaySound(inst.sounds.swipe)
				inst.SoundEmitter:PlaySound(inst.sounds.taunt_2)
				ShakeAllCameras(CAMERASHAKE.FULL, 0.5, 0.02, 0.2, inst, 30)
			end),
		},
		events = {
			EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	},

	State{
		name = "attack_slam",
		tags = {"attack", "busy", "pre_attack"},
		onenter = function(inst, target)
			inst.sg.statemem.target = target
			inst.Transform:SetEightFaced()
			inst.components.locomotor:Stop()
			inst.SoundEmitter:PlaySound(inst.sounds.grunt)
			inst.AnimState:PlayAnimation("attack5")
			inst.components.combat:StartAttack()
		end,
		onexit = function(inst)
			inst.Transform:SetFourFaced()
		end,
		timeline = {
			TimeEvent(12*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.attack_5)
			end),
			TimeEvent(15*FRAMES, function(inst)
				inst:FacePoint(inst.sg.statemem.target_pos)
				ShortAttack(inst.sg.statemem.target,inst.components.combat.defaultdamage,6,2)
				ShakeAllCameras(CAMERASHAKE.FULL, 0.5, 0.02, 0.2, inst, 30)
			end),
			TimeEvent(35*FRAMES, function(inst)
				ShortAttack(inst.sg.statemem.target,inst.components.combat.defaultdamage,6,1)
				inst.SoundEmitter:PlaySound(inst.sounds.attack_5_fire_1)
			end),
			TimeEvent(37*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.attack_5_fire_2)
			end),
		},
		events = {
			EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	},

	State{
		name = "attack_spin",
		tags = {"busy", "pre_attack"},
		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("attack4")
			inst.components.combat:StartAttack()
		end,
		timeline = {
			TimeEvent(0*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.spin)
			end),
			TimeEvent(12*FRAMES, function(inst)
				ShortAttack(inst,inst.components.combat.defaultdamage,6)
			end),
			TimeEvent(21*FRAMES, function(inst)
				ShortAttack(inst,inst.components.combat.defaultdamage,6,2)
			end),
			TimeEvent(30*FRAMES, function(inst)
				ShortAttack(inst,inst.components.combat.defaultdamage,6,1)
			end),
		},
		events ={
			EventHandler("onhitother", function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.swipe)
			end),
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	},

	State{
		name = "dash",
		tags = { "nointerrupt", "moving", "canrotate", "attack" },
		onenter = function(inst, target)
			inst.sg.statemem.target = target
			inst.AnimState:PlayAnimation("dash")
			inst.SoundEmitter:PlaySound(inst.sounds.grunt)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end,
		onexit = function(inst)
			ShortAttack(inst,inst.components.combat.defaultdamage,6,1)
		end,
		timeline = {
			TimeEvent(2*FRAMES, function(inst)
				inst.components.locomotor:WalkForward()
			end),
			TimeEvent(5*FRAMES, function(inst)
				inst.Physics:Teleport(inst.sg.statemem.target.Transform:GetWorldPosition())
			end),
			TimeEvent(13*FRAMES, function(inst)
				ShakeAllCameras(CAMERASHAKE.FULL, 0.5, 0.02, 0.2, inst, 30)
				inst.SoundEmitter:PlaySound(inst.sounds.step)
			end),
		},
		events = {
			EventHandler("animover", function(inst)
				inst.components.locomotor:StopMoving()
				inst.sg:GoToState("idle")
			end),
		},
	},

	State{
		name = "hit",
		tags = {"busy", "hit"},
		onenter = function(inst, cb)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("hit")
			inst.SoundEmitter:PlaySound(inst.sounds.hit)
		end,
		events = {
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	},
}

CommonForgeStates.AddIdle(states)
CommonStates.AddWalkStates(states, {
	walktimeline = {
		TimeEvent(0, function(inst)
			ShakeAllCameras(CAMERASHAKE.FULL, 0.5, 0.02, 0.2, inst, 30)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
		TimeEvent(10*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.grunt)
		end),
		TimeEvent(20*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
	},
	endtimeline = {
		TimeEvent(0, function(inst)
			ShakeAllCameras(CAMERASHAKE.FULL, 0.5, 0.02, 0.2, inst, 30)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
	}
})
CommonStates.AddDeathState(states, {
	TimeEvent(0, function(inst)
		inst.Physics:ClearCollidesWith(COLLISION.FLYERS)
		inst.SoundEmitter:PlaySound(inst.sounds.death)
	end),
	TimeEvent(30*FRAMES, function(inst)
		inst.SoundEmitter:PlaySound(inst.sounds.bonehit1)
	end),
	TimeEvent(50*FRAMES, function(inst)
		inst.SoundEmitter:PlaySound(inst.sounds.bonehit1)
	end),
	TimeEvent(55*FRAMES, function(inst)
		ShakeAllCameras(CAMERASHAKE.FULL, 0.7, 0.03, 0.5, inst, 30)
		inst.SoundEmitter:PlaySound(inst.sounds.death_bodyfall)
	end),
	TimeEvent(70*FRAMES, function(inst)
		inst.SoundEmitter:PlaySound(inst.sounds.bonehit2)
	end),
}, "death2")
CommonForgeStates.AddSpawnState(states, {
	TimeEvent(15*FRAMES, function(inst)
		ShakeAllCameras(CAMERASHAKE.FULL, 0.7, 0.03, 0.5, inst, 30)
		inst.SoundEmitter:PlaySound(inst.sounds.taunt)
	end),
})
CommonForgeStates.AddStunStates(states, {
	stuntimeline = {
		TimeEvent(5*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.stun)
		end),
		TimeEvent(10*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.stun)
		end),
		TimeEvent(15*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.stun)
		end),
		TimeEvent(20*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.stun)
		end),
	},
}, nil, nil, nil, {
	stopstun = {
		EventHandler("animover", function(inst)
			if inst.banner_call_timer then
				inst.sg:GoToState("banner_pre")
			else
				inst.sg:GoToState("idle")
			end
		end),
	},
})
CommonForgeStates.AddActionState(states, {
	TimeEvent(0, function(inst)
		inst.SoundEmitter:PlaySound(inst.sounds.step)
	end),
}, "walk_pst")
CommonForgeStates.AddKnockbackState(states)

return StateGraph("boarrior", states, events, "spawn")