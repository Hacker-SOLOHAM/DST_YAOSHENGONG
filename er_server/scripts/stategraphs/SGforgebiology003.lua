require("stategraphs/commonforgestates")

local events = {
	CommonForgeHandlers.OnKnockback(),
	CommonForgeHandlers.OnAttacked(),
	CommonForgeHandlers.OnEnterShield(),
	CommonForgeHandlers.OnExitShield(),
	CommonHandlers.OnDeath(),
	CommonHandlers.OnLocomote(false,true),
	CommonHandlers.OnFossilize(),
	CommonHandlers.OnFreeze(),
	EventHandler("doattack", function(inst, data)
		if not inst.components.health:IsDead() and data.target and data.target:IsValid() then
			local statename = "attack"
			if GetTime() - inst.skillcd > 10 then
				statename = "attack_spin"	--托马斯回旋
				inst.skillcd = GetTime()
			end
			inst.sg:GoToState(statename,data.target)
		end
	end),
}

local states = {
	State {
		name = "attack_spin",
		tags = {"attack", "busy", "nofreeze", "spinning", "keepmoving"},
		onenter = function(inst, target)
			inst.sg.statemem.target = target
			inst.components.locomotor:Stop()
			inst.components.combat:StartAttack()
			inst.AnimState:PlayAnimation("attack2_pre")
		end,
		timeline = {
			TimeEvent(0, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.hide_pre)
			end),
			TimeEvent(20*FRAMES, function(inst)
				ShakeAllCameras(CAMERASHAKE.FULL, 0.1, 0.01, 0.3, inst, 20)
				inst.SoundEmitter:PlaySound(inst.sounds.shell_impact)
			end),
		},
		events = {
			EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("attack_spin_loop", inst.sg.statemem.target)
			end),
		},
	},

	State {
		name = "attack_spin_loop",
		tags = {"attack", "busy", "nointerrupt", "spinning", "nobuff", "nofreeze", "delaysleep", "keepmoving", "hiding"}, -- TODO nobuff?
		onenter = function(inst, target)
			inst.movespeed = 0
			inst.ram_attempt = 1
			inst.spin_state = "accelerating"
			inst.sg.statemem.target = target
			inst.components.locomotor:Stop()
			inst.components.health.invincible = true
			inst:ForceFacePoint(target:GetPosition())
			inst.AnimState:PlayAnimation("attack2_loop")
			inst.SoundEmitter:PlaySound(inst.sounds.attack2_LP, "shell_loop")
			LongAttack(inst, 11*FRAMES, inst.components.combat.defaultdamage, 4, 1)
		end,
		onupdate = function(inst)
			if inst.spin_state == "accelerating" then
				inst.movespeed = math.min(inst.movespeed + 2.5, 30)
				if inst.movespeed >= 30 then
					inst.spin_state = "moving"
				end
			elseif inst.spin_state == "decelerating" then
				inst.movespeed = math.max(inst.movespeed - 2.5, 0)
				if inst.movespeed <= 0 then
					inst.spin_state = "stopped"
				end
			elseif inst.spin_state == "moving" then
					inst.spin_state = "decelerating"
			elseif inst.spin_state == "stopped" then
				if inst.ram_attempt >= 12 then
					inst.sg.statemem.end_spin = true
				else
					inst.ram_attempt = inst.ram_attempt + 1
				end
			end
			inst.Physics:SetMotorVel(inst.movespeed, 0, 0)
		end,
		onexit = function(inst)
			inst.SoundEmitter:KillSound("shell_loop")
		end,
		events = {
			EventHandler("attacked", function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.shell_impact)
			end),
			EventHandler("animover", function(inst)
				if math.random() < 0.3 then		--概率再来一次
					inst.sg:GoToState("attack_spin_loop",inst.sg.statemem.target)
				else
					if inst.sg.statemem.end_spin then
						inst.sg:GoToState("attack_spin_stop")
					else
						inst.AnimState:PlayAnimation("attack2_loop")
					end
				end
			end),
		},
	},

	State {
		name = "attack_spin_stop",
		tags = {"busy", "delaysleep", "keepmoving"},
		onenter = function(inst, data)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("attack2_pst")
			inst.SoundEmitter:PlaySound(inst.sounds.hide_pst)
		end,
		onexit = function(inst)
			inst.components.health.invincible = false
		end,
		events = {
			CommonForgeHandlers.IdleOnAnimOver(),
		},
	},

	State {
		name = "attack_spin_stop_forced",
		tags = {"busy"},
		onenter = function(inst, data)
			inst.Physics:Stop()
			inst.components.health.invincible = true
			inst.AnimState:PlayAnimation("hide_hit")
			inst.AnimState:PushAnimation("hide_pst", false)
			inst.SoundEmitter:PlaySound(inst.sounds.shell_impact)
		end,
		onexit = function(inst)
			inst.components.health.invincible = false
		end,
		timeline = {
			TimeEvent(11*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.hide_pst)
			end),
		},
		events = {
			CommonForgeHandlers.IdleOnAnimOver(),
		},
	},
}

CommonForgeStates.AddIdle(states)
CommonStates.AddWalkStates(states, {
	walktimeline = {
		TimeEvent(0, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.shell_walk)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
		TimeEvent(12*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.shell_walk)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
	},
})
CommonStates.AddCombatStates(states, {
	attacktimeline = {
		TimeEvent(0, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.attack1a)
		end),
		TimeEvent(12*FRAMES, function(inst)
			ShortAttack(inst,inst.components.combat.defaultdamage,4,1)
			inst.SoundEmitter:PlaySound(inst.sounds.attack1b)
		end),
	},
	deathtimeline = {
		TimeEvent(18*FRAMES, function(inst)
			ShakeAllCameras(CAMERASHAKE.FULL, 0.1, 0.01, 0.3, inst, 20)
			inst.SoundEmitter:PlaySound(inst.sounds.death)
		end),
	},
},{
	attack = "attack1",
})
local taunt_timeline = {
	TimeEvent(10*FRAMES, function(inst)
		inst.SoundEmitter:PlaySound(inst.sounds.taunt)
		ShakeAllCameras(CAMERASHAKE.FULL, 0.1, 0.01, 0.3, inst, 20)
	end),
}
CommonForgeStates.AddTauntState(states, taunt_timeline)
CommonForgeStates.AddSpawnState(states, taunt_timeline)
CommonForgeStates.AddKnockbackState(states)
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
	endtimeline = {
		TimeEvent(4*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
			ShakeAllCameras(CAMERASHAKE.FULL, 0.1, 0.01, 0.3, inst, 20)
		end),
	},
}, nil, nil, {
	onstun = function(inst)
		-- inst.components.health.invincible = false
	end,
})

return StateGraph("snortoise", states, events, "spawn")