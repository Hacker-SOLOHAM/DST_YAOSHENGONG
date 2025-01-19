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
			if GetTime() - inst.skillcd > 10 then
				statename = "attack_spit"	--毒液
				inst.skillcd = GetTime()
			end
			inst.sg:GoToState(statename,data.target)
		end
	end),
}

--喷射毒液
local function AcidSpit(inst)
	local target = inst.components.combat.target
	if target then
		local x, y, z = inst.Transform:GetWorldPosition()
		local angle = -inst:GetAngleToPoint(target:GetPosition():Get()) * DEGREES
		local offset = 4.25
		local pos = Point(x + (offset * math.cos(angle)), 0, z + (offset * math.sin(angle)))
		local spit = SpawnPrefab("peghook_fx1")
		spit.thrower = inst		--设定抛射者
		spit.Transform:SetPosition(inst:GetPosition():Get())
		spit.components.complexprojectile:Launch(pos, inst)
	end
end

local states = {
	State{
		name = "attack_spit",
		tags = {"attack", "busy", "pre_attack"},
		onenter = function(inst)
			inst.attack_spit_ready = false
			inst.components.locomotor:Stop()
			inst.components.combat:StartAttack()
			inst.AnimState:PlayAnimation("attack_pre")
			inst.AnimState:PushAnimation("spit", false)
		end,
		onexit = function(inst)
			if inst.attack_spit_cooldown_timer then
				inst.attack_spit_cooldown_timer:Cancel()
				inst.attack_spit_cooldown_timer = nil
			end
			inst.attack_spit_ready = false
			inst.attack_spit_cooldown_timer = inst:DoTaskInTime(6, function(inst)
				inst.attack_spit_ready = true
			end)
		end,
		timeline = {
			TimeEvent(0, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.grunt)
			end),
			TimeEvent(12*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.taunt)
			end),
			TimeEvent(15*FRAMES, function(inst)
				AcidSpit(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.spit)
				inst.sg:RemoveStateTag("pre_attack")
			end),
			TimeEvent(17*FRAMES, function(inst)
				inst.sg:RemoveStateTag("busy")
				inst.sg:RemoveStateTag("attack")
			end),
		},
		events = {
			EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	},
}

CommonForgeStates.AddIdle(states)
CommonStates.AddRunStates(states, {
	runtimeline = {
		TimeEvent(1*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
		TimeEvent(8*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
		TimeEvent(12*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
		TimeEvent(15*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
		TimeEvent(20*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
		TimeEvent(25*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
		TimeEvent(30*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
		TimeEvent(36*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
		TimeEvent(44*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
	},
})
CommonStates.AddCombatStates(states, {
	attacktimeline = {
		TimeEvent(0, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.grunt)
			inst.AnimState:PushAnimation("attack", false)
			inst.sg:AddStateTag("pre_attack")
		end),
		TimeEvent(12*FRAMES, function(inst)
			if inst.components.combat.target then
				inst:ForceFacePoint(inst.components.combat.target:GetPosition()) 
			end
		end),
		TimeEvent(12*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.attack)
		end),
		TimeEvent(15*FRAMES, function(inst)
			inst.components.combat:DoAttack()
			inst.sg:RemoveStateTag("pre_attack")
		end),
		TimeEvent(17*FRAMES, function(inst)
			inst.sg:RemoveStateTag("busy")
			inst.sg:RemoveStateTag("attack")
		end),
	},
	deathtimeline = {
		TimeEvent(0, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.death)
		end),
		TimeEvent(5*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.bodyfall)
		end),
	},
},{
	attack = "attack_pre",
})

local taunt_timeline = {
	TimeEvent(0, function(inst)
		inst.SoundEmitter:PlaySound(inst.sounds.taunt)
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
		TimeEvent(25*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.stun)
		end),
		TimeEvent(30*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.stun)
		end),
		TimeEvent(35*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.stun)
		end),
		TimeEvent(40*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.stun)
		end),
	},
})

return StateGraph("scorpeon", states, events, "spawn")