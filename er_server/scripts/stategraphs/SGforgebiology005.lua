require("stategraphs/commonforgestates")

local skillcdli = {5,15}		--技能cd
local events = {
	CommonForgeHandlers.OnAttacked(),
	CommonForgeHandlers.OnKnockback(),
	CommonForgeHandlers.OnEnterShield(),
	CommonForgeHandlers.OnExitShield(),
	CommonHandlers.OnSleep(),
	CommonHandlers.OnDeath(),
	CommonHandlers.OnLocomote(true,false),
	CommonHandlers.OnFreeze(),
	CommonHandlers.OnFossilize(),
	EventHandler("doattack", function(inst, data)
		if not inst.components.health:IsDead() and data.target and data.target:IsValid() then
			local statename = "attack"
			if GetTime() - inst.skillcd1 > skillcdli[1] then
				statename = "attack_slam"		--锤击
				inst.skillcd1 = GetTime()
			elseif GetTime() - inst.skillcd2 > skillcdli[2] then
				statename = "attack_roll_pre"	--翻滚
				inst.skillcd2 = GetTime()
			end
			inst.sg:GoToState(statename,data.target)
		end
	end),
}

local states = {
	State{
		name = "attack_slam",
		tags = {"attack", "busy", "jumping", "keepmoving", "pre_attack"},
		onenter = function(inst, target)
			inst.sg.statemem.target = target
			inst.components.locomotor:Stop()
			inst.components.combat:StartAttack()
			inst:FacePoint(target:GetPosition())
			inst.AnimState:PlayAnimation("attack1")
		end,
		timeline = {
			TimeEvent(10*FRAMES, function(inst)
				local pos_i = inst:GetPosition()
				local pos_t = inst.sg.statemem.target:GetPosition()
				local speed = math.sqrt(distsq(pos_i.x, pos_i.z, pos_t.x, pos_t.z)) / (13 * FRAMES)
				inst:ForceFacePoint(pos_t:Get())
				inst.Physics:SetMotorVel(speed, 0, 0)
				inst.sg:RemoveStateTag("pre_attack")
				inst.SoundEmitter:PlaySound(inst.sounds.grunt)
			end),
			TimeEvent(18*FRAMES, function(inst)
				inst.components.locomotor:Stop()
			end),
			TimeEvent(20*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.attack1)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/bodyfall_dirt")
				ShakeAllCameras(CAMERASHAKE.FULL, 1.2, .03, .7, inst, 30)
			end),
			TimeEvent(23*FRAMES, function(inst)
				SpawnPrefab("groundpoundring_fx").Transform:SetPosition(inst:GetPosition():Get())
				ShortAttack(inst,inst.components.combat.defaultdamage,6,1)
			end),
		},
		events = {
			EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	},

	State{
		name = "attack_roll_pre",
		tags = {"busy", "attack", "keepmoving", "pre_attack"},
		onenter = function(inst, target)
			inst.sg.statemem.target = target
			inst.components.locomotor:Stop()
			inst.components.combat:StartAttack()
			inst.AnimState:PlayAnimation("roll_pre")
		end,
		events = {
			EventHandler("animover", function(inst)
				inst.goroll = inst:DoTaskInTime(5.2, function(inst)
					inst.goroll = nil
				end)
				inst.sg:GoToState("attack_roll_loop", inst.sg.statemem.target)
			end),
		},
	},

	State{
		name = "attack_roll_loop",
		tags = {"attack", "busy", "rolling", "delaysleep", "nofreeze", "keepmoving", "pre_attack"},
		onenter = function(inst, target)
			inst.sg.statemem.target = target
			inst.Physics:SetMotorVelOverride(inst.components.locomotor.walkspeed*1.5, 0, 0)
			inst.AnimState:PlayAnimation("roll_loop")
			LongAttack(inst, 11*FRAMES, inst.components.combat.defaultdamage, 4, 1)
		end,
		onupdate = function(inst)
			local target = inst.sg.statemem.target
			if target and inst.components.combat:IsValidTarget(target) then
				local oldpos = inst.Transform:GetRotation()
				local angle = (oldpos - inst:GetAngleToPoint(target:GetPosition()) + 180) % 360 - 180
				local newpos = math.abs(angle) <= 3.5 and angle or 3.5 * (angle < 0 and -1 or 1)
				inst.Transform:SetRotation(oldpos - newpos)
			end
		end,
		timeline = {
			TimeEvent(0, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.step)
				ShakeAllCameras(CAMERASHAKE.FULL, .5, .02, .2, inst, 30)
			end),
			TimeEvent(6*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.step)
			end),
			TimeEvent(12*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.step)
			end),
		},
		events = {
			EventHandler("animover", function(inst)
				local target = inst.sg.statemem.target
				if inst.goroll and target and inst.components.combat:IsValidTarget(target) then
					inst.sg:GoToState("attack_roll_loop", target)
				else
					if inst.goroll then
						inst.goroll:Cancel()
						inst.goroll = nil
					end
					inst.sg:GoToState("attack_roll_pst", target)
				end
			end),
		},
	},

	State{
		name = "attack_roll_pst",
		tags = {"busy", "attack", "rolling", "keepmoving", "delaysleep", "pre_attack"},
		onenter = function(inst, target)
			inst.sg.statemem.target = target
			inst.AnimState:PlayAnimation("roll_pst")
			inst.Physics:SetMotorVelOverride(inst.components.locomotor.walkspeed*1.5, 0, 0)
		end,
		timeline = {
			TimeEvent(0, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.step)
				ShakeAllCameras(CAMERASHAKE.FULL, .5, .02, .2, inst, 30)
			end),
			TimeEvent(6*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.step)
			end),
			TimeEvent(9*FRAMES, function(inst)
				if inst.components.combat:IsValidTarget(inst.sg.statemem.target) then
					inst.sg:GoToState("attack_slam", inst.sg.statemem.target)
				end
			end),
			TimeEvent(12*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.step)
				inst.components.locomotor:Stop()
				inst.sg:RemoveStateTag("rolling")
			end),
		},
		events = {
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	},
}

CommonForgeStates.AddIdle(states)
CommonStates.AddRunStates(states, {
	runtimeline = {
		TimeEvent(0, function(inst)
			inst.components.locomotor:WalkForward()
			inst.SoundEmitter:PlaySound(inst.sounds.run)
		end),
		TimeEvent(2*FRAMES, function(inst)
			inst.components.locomotor:RunForward()
			inst.SoundEmitter:PlaySound(inst.sounds.step)
			ShakeAllCameras(CAMERASHAKE.FULL, .5, .02, .2, inst, 30)
		end),
		TimeEvent(11*FRAMES, function(inst)
			inst.components.locomotor:WalkForward()
		end),
	},
	endtimeline = {
		TimeEvent(0, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
	},
})
CommonStates.AddCombatStates(states, {
	attacktimeline = {
		TimeEvent(0, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.grunt)
			inst.sg:AddStateTag("pre_attack")
		end),
		TimeEvent(7*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.swish)
		end),
		TimeEvent(13*FRAMES, function(inst)
			LongAttack(inst, 11*FRAMES, inst.components.combat.defaultdamage, 4, 1)
			inst.SoundEmitter:PlaySound(inst.sounds.attack2)
			inst.sg:RemoveStateTag("pre_attack")
		end),
	},
	deathtimeline = {
		TimeEvent(0, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.taunt)
		end),
		TimeEvent(11*FRAMES, function(inst)
			ShakeAllCameras(CAMERASHAKE.FULL, .5, .02, .2, inst, 30)
			inst.SoundEmitter:PlaySound(inst.sounds.bodyfall)
			inst.SoundEmitter:PlaySound(inst.sounds.hide_pre)
		end),
	},
},{
	attack = "attack2",
})
CommonForgeStates.AddSpawnState(states, {
	TimeEvent(20*FRAMES, function(inst)
		ShakeAllCameras(CAMERASHAKE.FULL, 0.8, .03, .5, inst, 30)
		inst.SoundEmitter:PlaySound(inst.sounds.step)
		inst.SoundEmitter:PlaySound(inst.sounds.taunt)
	end),
})
CommonForgeStates.AddKnockbackState(states)
CommonForgeStates.AddStunStates(states, {
	stuntimeline = {
		TimeEvent(5*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.hit)
		end),
		TimeEvent(10*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.hit)
		end),
		TimeEvent(15*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.hit)
		end),
		TimeEvent(20*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.hit)
		end),
		TimeEvent(25*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.hit)
		end),
	},
}, nil, {
	stun = "grunt",
	hit = "grunt",
})
CommonForgeStates.AddHideStates(states, {
	starttimeline = {
		TimeEvent(7*FRAMES, function(inst)
			inst.sg:AddStateTag("nointerrupt")
		end),
		TimeEvent(10*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.hide_pre)
		end),
	},
	endtimeline = {
		TimeEvent(10*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.hide_pst)
		end),
	},
})

return StateGraph("boarilla", states, events, "spawn")