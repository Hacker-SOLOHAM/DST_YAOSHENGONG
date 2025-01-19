require("stategraphs/commonforgestates")

local actionhandlers = {
	ActionHandler(ACTIONS.REVIVE_CORPSE, "reviving_bro"),
}

local function FootShake(inst)
	ShakeAllCameras(CAMERASHAKE.FULL, .2, .01, .1, inst, 8)
end

local function StartCheerCooldown(inst)
	inst.cheer_ready = false
	if inst.cheer_task then
		inst.cheer_task:Cancel()
		inst.cheer_task = nil
	end
	inst.cheer_task = inst:DoTaskInTime(15, function(inst)
		inst.cheer_ready = true
	end)
end

local function FaceBro(inst)
	if inst.bro and not inst.bro.components.health:IsDead() then
		local pos = inst.bro:GetPosition()
		inst:ForceFacePoint(pos:Get())
	end
end

local events = {
	CommonForgeHandlers.OnAttacked(),
	CommonForgeHandlers.OnKnockback(),
	CommonForgeHandlers.OnVictoryPose(),
	CommonHandlers.OnAttack(),
	CommonHandlers.OnSleep(),
	CommonHandlers.OnLocomote(true,false),
	CommonHandlers.OnFossilize(),
	EventHandler("startcheer", function(inst)
		if not inst.sg:HasStateTag("cheering") and TheWorld.components.lavaarenaevent.victory == nil then
			if not (inst.sg:HasStateTag("attack") or inst.sg:HasStateTag("frozen") or inst.sg:HasStateTag("busy")) then
				inst.sg:GoToState("cheer_pre")
			else
				inst.sg.mem.wants_to_cheer = true
				if inst.sg:HasStateTag("sleeping") then
					inst.sg:GoToState("wake")
				end
			end
		end
	end),
	EventHandler("death", function(inst, data)
		inst.sg:GoToState("corpse")
	end),
	EventHandler("respawnfromcorpse", function(inst, reviver)
		if inst:HasTag("corpse") and reviver then
			inst.sg:GoToState("death_post", reviver)
		end
	end),
	EventHandler("chest_bump", function(inst, data)
		inst.sg:GoToState("chest_bump", data)
	end),
}

local states = {
	State{
		name = "idle",
		tags = {"idle", "canrotate"},
		onenter = function(inst, playanim)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("idle_loop", true)
			-- if inst.sg.mem.wants_to_cheer then
				-- if inst.bro.sg:HasStateTag("cheering") then
					-- inst.sg:GoToState("cheer_pre")
				-- else
					-- inst.sg.mem.wants_to_cheer = nil
					-- StartCheerCooldown(inst)
				-- end
			-- end
		end,
	},

	State{
		name = "attack",
		tags = {"attack", "busy", "pre_attack"},
		onenter = function(inst, target)
			inst.sg.statemem.target = target or inst.components.combat.target
			inst.components.combat:StartAttack()
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("attack")
			inst.SoundEmitter:PlaySound(inst.sounds.attack_2)
		end,
		timeline = {
			TimeEvent(13*FRAMES, function(inst)
				if inst then ShortAttack(inst.sg.statemem.target,inst.components.combat.defaultdamage,3) end
				--´ýÐÞ¸´.ByLaolu2021-06-19
			end),
		},
		events = {
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	},

	State{
		name = "run_start",
		tags = { "moving", "running", "canrotate" },
		onenter = function(inst)
			local target = inst.components.combat.target
			if inst.attack_charge_ready and target and not (inst.bro and inst.bro:HasTag("corpse")) and not inst.cheer_ready and inst.components.combat:IsValidTarget(target) then
				inst.sg:GoToState("charge", target)
			else
				inst.components.locomotor:RunForward()
				inst.AnimState:PlayAnimation("run_pre")
			end
		end,
		events = {
			EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("run")
			end),
		},
	},

	State{
		name = "run",
		tags = { "moving", "running", "canrotate" },
		onenter = function(inst)
			inst.Transform:SetEightFaced()
			local target = inst.components.combat.target
			if inst.attack_charge_ready and target and not (inst.bro and inst.bro:HasTag("corpse")) and not inst.cheer_ready and inst.components.combat:IsValidTarget(target) then
				inst.sg:GoToState("charge", target)
			else
				inst.components.locomotor:RunForward()
				inst.AnimState:PlayAnimation("run_loop")
			end
		end,
		timeline = {
			TimeEvent(9*FRAMES, PlayFootstep),
			TimeEvent(9*FRAMES, FootShake),
			TimeEvent(18*FRAMES, PlayFootstep),
			TimeEvent(18*FRAMES, FootShake),
		},
		events = {
			EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("run")
			end),
		},
		onexit = function(inst)
			inst.Transform:SetSixFaced()
		end,
	},

	State{
		name = "run_stop",
		tags = { "idle" },
		onenter = function(inst)
			inst.components.locomotor:StopMoving()
			inst.AnimState:PlayAnimation("run_pst")
		end,
		timeline = {
			TimeEvent(16*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.grunt)
			end),
		},
		events = {
			EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	},

	State{
		name = "charge",
		tags = {"busy", "charging", "keepmoving", "delaysleep"},
		onenter = function(inst, target)
			inst._hashittarget = nil
			--inst.components.locomotor:RunForward()
			inst.components.locomotor:Stop()

			if inst.components.combat.target and not inst._hashittarget then
				if inst.components.combat.target:IsValid() then
					inst:ForceFacePoint(target:GetPosition())
					inst.sg.statemem.target = inst.components.combat.target
				end
			end

			inst.Transform:SetEightFaced()
			ToggleOffCharacterCollisions(inst)
			inst.attack_charge_ready = false

			inst.SoundEmitter:PlaySound(inst.sounds.attack)
			inst.AnimState:PlayAnimation("attack2_pre")

			inst.Physics:SetMotorVelOverride(inst.components.locomotor.runspeed * 1.15, 0, 0)
		end,
		onexit = function(inst)
			inst:DoTaskInTime(TUNING.FORGE.RHINOCEBRO.CHARGE_CD, function(inst)
				inst.attack_charge_ready = true
			end)
			inst.Transform:SetSixFaced()
			ToggleOnCharacterCollisions(inst)
		end,
		timeline = {
			TimeEvent(9*FRAMES, PlayFootstep),
			TimeEvent(9*FRAMES, FootShake),
			TimeEvent(18*FRAMES, PlayFootstep),
			TimeEvent(18*FRAMES, FootShake),
		},
		events = {
			EventHandler("animover", function(inst)
				if not inst.sg.statemem.target_hit and inst.sg.statemem.target and inst.components.combat:IsValidTarget(inst.sg.statemem.target) and not inst.sg.mem.sleep_duration then
					inst.sg:GoToState("charge_loop", inst.sg.statemem.target)
				else
					inst.sg:GoToState("charge_pst", inst.sg.statemem.target)
				end
			end),
			EventHandler("onattackother", function(inst, data)
				if data.target == inst.sg.statemem.target then
					inst.sg.statemem.target_hit = true
				end
			end),
		},
	},

	State{
		name = "charge_loop",
		tags = {"attack", "busy", "charging", "keepmoving", "delaysleep"},
		onenter = function(inst, target)
			if target and not inst._hashittarget then
				if inst.components.combat:IsValidTarget(target) then
					--inst:FacePoint(target:GetPosition())
					inst.sg.statemem.target = target
				end
			end
			inst.Transform:SetEightFaced()
			ToggleOffCharacterCollisions(inst)
			inst.Physics:SetMotorVelOverride(inst.components.locomotor.runspeed*1.15, 0, 0)
			inst.AnimState:PlayAnimation("attack2_loop")
		end,
		onupdate = function(inst)
			if not inst.sg.statemem.target_hit and inst.sg.statemem.target and inst.components.combat:IsValidTarget(inst.sg.statemem.target) then -- TODO currently the same as Boarillas roll, if not changed commonize it???
				local current_rotation = inst.Transform:GetRotation()
				local angle_to_target = inst:GetAngleToPoint(inst.sg.statemem.target:GetPosition())
				local angle = (current_rotation - angle_to_target + 180) % 360 - 180 -- -180 <= angle < 180, 181 = -179
				local next_rotation = math.abs(angle) <= 5 and angle or 5 * (angle < 0 and -1 or 1)
				inst.Transform:SetRotation(current_rotation - next_rotation)
			end
		end,
		onexit = function(inst)
			inst.Transform:SetSixFaced()
			ToggleOnCharacterCollisions(inst)
		end,
		timeline = {
			TimeEvent(9*FRAMES, PlayFootstep),
			TimeEvent(9*FRAMES, FootShake),
			TimeEvent(18*FRAMES, PlayFootstep),
			TimeEvent(18*FRAMES, FootShake),
		},
		events = {
			EventHandler("animover", function(inst)
				if not inst.sg.statemem.target_hit and inst.sg.statemem.target and inst.components.combat:IsValidTarget(inst.sg.statemem.target) and not inst.sg.mem.sleep_duration and (not inst.bro or not inst.bro.components.health:IsDead())then
					inst.sg:GoToState("charge_loop", inst.sg.statemem.target)
				else
					inst.sg:GoToState("charge_pst", inst.sg.statemem.target)
				end
			end),
			EventHandler("onattackother", function(inst, data)
				if data.target == inst.sg.statemem.target then
					inst.sg.statemem.target_hit = true
				end
			end),
		},
	},

	State{
		name = "charge_pst",
		tags = {"busy"},
		onenter = function(inst, target)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("attack2_pst")
		end,
		events = {
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	},

	State{
		name = "cheer_pre",
		tags = {"busy", "cheering", "nosleep"},
		onenter = function(inst, data)
			if inst.bro and inst.bro.components.health and not inst.bro.components.health:IsDead() and not inst.bro.sg:HasStateTag("cheering") then -- TODO need health checks? is it possible to get here with a dead bro?
				FaceBro(inst)
				inst.bro:PushEvent("startcheer")
			end
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("cheer_pre")
		end,
		timeline = {},
		onexit = function(inst)
			inst.sg.mem.wants_to_cheer = nil
			StartCheerCooldown(inst)
		end,
		events = {
			EventHandler("animover", function(inst)
				inst.sg:GoToState("cheer_loop")
			end),
		},
	},

	State{
		name = "cheer_loop",
		tags = {"busy", "cheering", "nosleep"},
		onenter = function(inst, data)
			inst.AnimState:PlayAnimation("cheer_loop")
			inst.SoundEmitter:PlaySound(inst.sounds.cheer)
			inst.sg.statemem.buff_ready = data and data.buff_ready
			inst.sg.statemem.buffed = data and data.buffed
			inst.sg.statemem.end_cheer = data and data.end_cheer
			if not (inst.bro and inst.bro.sg:HasStateTag("cheering") or inst.sg.statemem.buffed) then
				inst.sg:SetTimeout(data and data.timeout or 5)
			end
		end,
		timeline = {
			TimeEvent(9*FRAMES, function(inst)
				if inst.sg.statemem.end_cheer then
					inst.sg:GoToState("cheer_pst")
				end
			end)
		},
		ontimeout = function(inst)
			if not inst.bro.sg:HasStateTag("cheering") then
				inst.sg:RemoveStateTag("cheering")
				inst.sg.statemem.end_cheer = true
			end
		end,
		onexit = function(inst)
			StartCheerCooldown(inst)
		end,
		events = {
			EventHandler("animover", function(inst)
				if inst.sg.statemem.end_cheer then
					inst.sg:GoToState("cheer_pst")
				else
					local bro_is_cheering = inst.bro and inst.bro.sg.currentstate.name == "cheer_loop"
					local buff_ready = inst.sg.statemem.buff_ready
					local buffed = inst.sg.statemem.buffed
					local end_cheer = buffed or not (bro_is_cheering or inst.bro.sg.mem.wants_to_cheer)

					if buff_ready and bro_is_cheering then
						inst:SetBuffLevel(inst.bro_stacks + 1)
						buffed = true
						end_cheer = false
					end
					inst.sg:GoToState("cheer_loop", {buffed = buffed, buff_ready = not (buff_ready or buffed) and bro_is_cheering, end_cheer = end_cheer, timeout = inst.sg.timeout})
				end
			end),
		},
	},

	State{
		name = "cheer_pst",
		tags = {"busy", "nosleep"},
		onenter = function(inst, data)
			inst.AnimState:PlayAnimation("cheer_post")
		end,
		events = {
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	},

	State{
		name = "pose",
		tags = {"busy", "posing" , "idle"},
		onenter = function(inst)
			inst.Physics:Stop()
			if inst.bro and inst.bro.components.health and not inst.bro.components.health:IsDead() then
				FaceBro(inst)
				local rotation = inst.Transform:GetRotation()
				inst.Transform:SetRotation(rotation - 180)
			end
			inst.AnimState:PlayAnimation("pose_pre", false)
			inst.AnimState:PushAnimation("pose_loop", true)
		end,
		timeline = {
			TimeEvent(15*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.cheer)
			end),
		},
	},

	State{
		name = "corpse",
		tags = {"busy", "nointerrupt"},
		onenter = function(inst, data)
			inst.SoundEmitter:PlaySound(inst.sounds.death)
			inst.AnimState:PlayAnimation("death")
			inst.Physics:Stop()
			inst:AddTag("NOCLICK")
			
			if not inst.IsTrueDeath or inst:IsTrueDeath() then
				inst:DoTaskInTime(1.5, function(inst)
					inst.sg:GoToState("death")
				end)
				if inst.bro then
					inst.bro:DoTaskInTime(1, function(inst)
						inst.sg:GoToState("death")
					end)
				end
			end
			--ChangeToObstaclePhysics(inst)
			--RemovePhysicsColliders(inst)
		end,
		timeline = {
			TimeEvent(14*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.bodyfall)
				ShakeAllCameras(CAMERASHAKE.FULL, 0.5, 0.02, 0.3, inst, 10)
			end),
		},
		events = {
			EventHandler("animover", function(inst)
				--inst.sg:AddStateTag("corpse")
			end),
			EventHandler("attacked", function(inst)
				if inst:HasTag("corpse") then
					inst.AnimState:PlayAnimation("death_hit", false)
				end
			end),
		},
	},

	State{
		name = "reviving_bro",
		tags = {"doing", "busy", "reviving"},
		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("revive_pre", false)
			inst.AnimState:PushAnimation("revive_loop", false)
			inst.AnimState:PushAnimation("revive_loop", false)
			inst.AnimState:PushAnimation("revive_pst", false)
			inst.SoundEmitter:PlaySound(inst.sounds.revive_lp, "reviveLP")
			inst.sg.statemem.action = inst:GetBufferedAction()
		end,
		onexit = function(inst)
			inst.SoundEmitter:KillSound("reviveLP")
			if inst.bufferedaction == inst.sg.statemem.action then
				inst:ClearBufferedAction()
			end
		end,
		timeline = {
			TimeEvent(14*FRAMES, function(inst) -- TODO was 7, need to figure out what frame the bro revives on
				inst:PerformBufferedAction()
			end),
		},
		events = {
			EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	},

	State{
		name = "death_post",
		tags = { "busy", "nointerrupt"},
		onenter = function(inst)
			inst:RemoveTag("NOCLICK")
			inst.AnimState:PlayAnimation("death_post")
			inst.components.health:SetPercent(TUNING.FORGE.RHINOCEBRO.REV_PERCENT)
			inst.components.health:SetInvincible(true)
		end,
		timeline = {},
		events = {
			EventHandler("animqueueover", function(inst)
				if inst.bro and inst.bro.sg:HasStateTag("idle") then
					inst:PushEvent("chest_bump", {initiator = true})
					inst.bro:PushEvent("chest_bump")
				else
					inst.sg:GoToState("idle")
				end
			end),
		},
		onexit = function(inst)
			inst.components.health:SetInvincible(false)
			ChangeToCharacterPhysics(inst)
		end,
	},

	State{
		name = "chest_bump",
		tags = { "busy", "nointerrupt" },
		onenter = function(inst, data)
			inst.sg.statemem.initiator = data and data.initiator
			inst.Transform:SetEightFaced()
			inst.components.locomotor:StopMoving()
			inst.AnimState:PlayAnimation("chest_bump")
			FaceBro(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.grunt)
		end,
		timeline = {
			TimeEvent(16*FRAMES, function(inst)
				if inst.bro.sg.currentstate.name == "chest_bump" then
					if inst.sg.statemem.initiator then
						local pos = inst:GetPosition()
						local bro_pos = inst.bro:GetPosition()
						local distance_to_bro = distsq(pos, bro_pos)
						local dist = math.sqrt(distance_to_bro) / 2
						local angle = -inst:GetAngleToPoint(bro_pos) * DEGREES
						local offset = Point(dist*math.cos(angle), 0, dist*math.sin(angle))
						local bump_pos = pos + offset
						-- COMMON_FNS.DoFrontAOE(inst, 150 + 25 * inst.bro_stacks, 0, bump_radius, nil, nil, bump_pos)
					end
				end
			end),
		},
		onexit = function(inst)
			inst.Transform:SetSixFaced()
		end,
		events = {
			EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	},

	State{
		name = "death",
		tags = {"busy"},
		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("death_finalfinal")
			inst.SoundEmitter:PlaySound(inst.sounds.death_final_final)
		end,
		timeline = {
			TimeEvent(21*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.bodyfall)
				ShakeAllCameras(CAMERASHAKE.FULL, 0.5, 0.02, 0.3, inst, 10)
			end),
		},
		events = {
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					if inst.should_fadeout then
						inst:DoTaskInTime(inst.should_fadeout, ErodeAway)
					end
				end
			end),
		},
	},
}
CommonStates.AddHitState(states, {
	TimeEvent(0, function(inst)
		inst.sg.mem.last_hit_time = GetTime()
	end),
})
CommonForgeStates.AddTauntState(states, {
	TimeEvent(10*FRAMES, function(inst)
		inst.SoundEmitter:PlaySound(inst.sounds.taunt)
	end),
})
CommonForgeStates.AddSpawnState(states, {
	TimeEvent(10*FRAMES, function(inst)
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
		TimeEvent(30*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.hit)
		end),
		TimeEvent(35*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.hit)
		end),
		TimeEvent(40*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.hit)
		end),
	},
}, nil, {
	stun = "grunt",
	hit = "grunt",
},{
	onstun = function(inst, data)
		inst.sg.statemem.flash = 0
	end,
	onexitstun = function(inst)
		inst.components.health:SetInvincible(false)
		inst.components.health:SetAbsorptionAmount(0)
		--inst.components.bloomer:PopBloom("leap") -- TODO needed?
		--inst.components.colouradder:PopColour("leap")
	end,
})
CommonForgeStates.AddActionState(states)

return StateGraph("rhinocebro", states, events, "spawn", actionhandlers)