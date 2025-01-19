--ByLaolu 2021-08-28
require("stategraphs/commonforgestates")

local events = {
	CommonForgeHandlers.OnAttacked(),
	CommonForgeHandlers.OnKnockback(),
	CommonHandlers.OnDeath(),
	CommonHandlers.OnSleep(),
	CommonHandlers.OnLocomote(true,false),
	CommonHandlers.OnFreeze(),
	CommonHandlers.OnFossilize(),
	EventHandler("doattack", function(inst, data)
		if not inst.components.health:IsDead() and data.target and data.target:IsValid() then
			local statename = "attack"
			-- if GetTime() - inst.skillcd > 10 then
			if GetTime() - inst.skillcd > (math.random(30,45)) then--削弱冲撞cd的触发几率
				statename = "attack_dash"	--冲撞
				inst.skillcd = GetTime()
			end
			inst.sg:GoToState(statename,data.target)
		end
	end),
}

local states = {
	State{
		name = "attack",
		tags = {"attack", "busy", "pre_attack"},
		 onenter = function(inst, target)
			inst.sg.statemem.target = target
			inst.components.combat:StartAttack()
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("attack1")
		end,
		timeline = {
			TimeEvent(6*FRAMES, function(inst)
				inst:ForceFacePoint(inst.sg.statemem.target:GetPosition())
			end),
			TimeEvent(12*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/boaron/attack_1")
			end),
			TimeEvent(12*FRAMES, function(inst)
				inst.components.combat:DoAttack(inst.sg.statemem.target)
				inst.sg:RemoveStateTag("pre_attack")
			end),
		},
		events = {
			EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	},

	State {
		name = "attack_dash",
		tags = {"attack", "busy", "keepmoving", "pre_attack"},
		onenter = function(inst, target)
			inst.sg.statemem.target = target
			inst.Transform:SetEightFaced()
			inst.components.combat:StartAttack()
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("attack2")
		end,
		onexit = function(inst)
			inst.Transform:SetSixFaced()
		end,
		timeline = {
			TimeEvent(10*FRAMES, function(inst)
				inst:ForceFacePoint(inst.sg.statemem.target:GetPosition())
			end),
			TimeEvent(18*FRAMES, function(inst)
				inst.Physics:SetMotorVel(35, 0, 0)
				inst.sg:RemoveStateTag("pre_attack")
				LongAttack(inst, 11*FRAMES, inst.components.combat.defaultdamage, 4, 1)
			end),
			TimeEvent(20*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.attack_2)
			end),
			TimeEvent(26*FRAMES, function(inst)
				inst.Physics:ClearMotorVelOverride()
				inst.components.locomotor:Stop()
			end),
		},
		events = {
			EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	},
}

CommonStates.AddRunStates(states, {
	runtimeline = {
		TimeEvent(0, PlayFootstep),
	},
})
CommonStates.AddDeathState(states, {
	TimeEvent(0, function(inst)
		inst.SoundEmitter:PlaySound(inst.sounds.death)
	end),
})
CommonForgeStates.AddIdle(states)
CommonForgeStates.AddKnockbackState(states)
CommonForgeStates.AddStunStates(states)
CommonForgeStates.AddSpawnState(states)

return StateGraph("pitpig", states, events, "spawn")