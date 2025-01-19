require("stategraphs/commonforgestates")

--是否就绪
local function IsBannerReady(inst)
	return inst.components.combat.target and GetTime() - inst.components.combat.lastwasattackedtime > 2
end

local events = {
	CommonForgeHandlers.OnAttacked(),
	CommonForgeHandlers.OnKnockback(),
	EventHandler("locomote", function(inst)
		local is_moving = inst.sg:HasStateTag("moving")
		local is_idling = inst.sg:HasStateTag("idle")
		local should_move = inst.components.locomotor:WantsToMoveForward()
		local wants_to_banner = IsBannerReady(inst) and false
		
		if is_moving and (not should_move or wants_to_banner) then
			inst.sg:GoToState("run_stop")
		elseif (is_idling and should_move) then
			inst.sg:GoToState("run_start")
		end
	end),
	CommonHandlers.OnDeath(),
	CommonHandlers.OnSleep(),
	CommonHandlers.OnFreeze(),
	CommonHandlers.OnFossilize(),
	EventHandler("doattack", function(inst, data)
		if not inst.components.health:IsDead() and data.target and data.target:IsValid() then
			local statename = "attack"
			if GetTime() - inst.skillcd2 > 5 then
				statename = "spit"		--冲击波
				inst.skillcd2 = GetTime()
			end
			inst.sg:GoToState(statename,data.target)
		end
	end),
}

local states = {
	State{
		name = "spit",
		tags = {"attack", "busy", "pre_attack"},
		onenter = function(inst, target)
			inst.sg.statemem.target = target
			inst.components.locomotor:Stop()
			inst.components.combat:StartAttack()
			inst.AnimState:PlayAnimation("spit")
		end,
		timeline = {
			TimeEvent(5*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.spit)
			end),
			TimeEvent(13*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.spit2)
				inst.components.combat:DoAttack()
				local target = inst.sg.statemem.target
				local fx = SpawnPrefab("boss_skill_fx015"):set(1.5,1,inst.components.combat.defaultdamage,4)
				MakeFlyitem(inst,target,fx,{10,2,0})
			end),
		},
		events = {
			EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	},

	State{
		name = "spawn",
		tags = {"busy", "canattack"},
		onenter = function(inst, cb)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("taunt")
		end,
		timeline = {
			TimeEvent(0*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.taunt)
			end),
		},
		events = {
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	},

	State{
		name = "build",
		tags = {"busy"},
		onenter = function(inst, data)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("banner_summon")
			inst.SoundEmitter:PlaySound(inst.sounds.taunt_2)
		end,
		timeline = {
			TimeEvent(20*FRAMES, PlayFootstep),
			TimeEvent(20*FRAMES, function(inst)
				SpawnBanner(inst,"forge_biology001",6,{3,6})	--召唤下属
			end),
		},
		events = {
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	},
}

CommonForgeStates.AddIdle(states, nil, nil, {
	TimeEvent(0, function(inst)
		inst.sg:GoToState("build")
	end),
})
CommonStates.AddRunStates(states, {
	runtimeline = {
		TimeEvent(0, PlayFootstep),
	},
})
CommonStates.AddCombatStates(states, {
	attacktimeline = {
		TimeEvent(0, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.attack)
		end),
		TimeEvent(10*FRAMES, function(inst)
			inst.components.combat:DoAttack()
		end),
	},
	deathtimeline = {
		TimeEvent(0, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.death)
		end),
	},
}, {
	attack = "attack",
})
CommonForgeStates.AddTauntState(states, {
	TimeEvent(0, function(inst)
		if GetTime() - inst.skillcd1 > 10 and inst.branch < 6 then
			inst.sg:GoToState("build")
			inst.skillcd1 = GetTime()
		end
		inst.SoundEmitter:PlaySound(inst.AnimState:IsCurrentAnimation("taunt") and inst.sounds.taunt or inst.sounds.taunt_2)
	end),
}, function(inst)
	return math.random(2) == 1 and "taunt" or "taunt_2"
end)
CommonForgeStates.AddSpawnState(states, {
	TimeEvent(0, function(inst)
		inst.SoundEmitter:PlaySound(inst.sounds.taunt)
	end),
})
CommonForgeStates.AddKnockbackState(states)
CommonForgeStates.AddStunStates(states, {
	stuntimeline = {
		TimeEvent(5*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.stun)
		end),
	},
})
CommonForgeStates.AddActionState(states)

return StateGraph("crocommander", states, events, "spawn")