--远古犀牛SG
require("stategraphs/commonstates")

--技能1
local function Minotaur_Skill1(inst)
	ShakeAllCameras(CAMERASHAKE.FULL, .7, .02, .3, inst, 40)
	inst.components.groundpounder:GroundPound()
	inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/swhoosh")
	inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/groundpound")					
	local dust1 = SpawnPrefab("small_puff")
	dust1.Transform:SetPosition(inst:GetPosition():Get())
	dust1.Transform:SetScale(7, 7, 7)
	local dust2 = SpawnPrefab("small_puff")
	dust2.Transform:SetPosition(inst:GetPosition():Get())
	dust2.Transform:SetScale(5, 5, 5)
end

--技能2
local function Minotaur_Skill2(inst)
    if not inst.components.timer:TimerExists("skill_cd") and not inst:HasTag("minotaur_shadow") then
        local pos = inst:GetPosition()
        local fx = SpawnPrefab("statue_transition_2")
		fx.Transform:SetPosition(pos:Get())
		fx.Transform:SetScale(3,4.5,3)

		local distance = -8
		for i=1,2 do
			local enemy = SpawnPrefab("minotaur")
			enemy:AddTag("minotaur_shadow")
			enemy.components.health:SetInvincible(true)
			enemy.Transform:SetPosition(pos.x+distance, pos.y, pos.z)
			RemovePhysicsColliders(enemy)
			enemy.components.combat:SetTarget(inst.components.combat.target)
			enemy:DoTaskInTime(10, enemy.Remove)
			enemy.sg:GoToState("run")
			enemy.AnimState:SetMultColour(0.4, 0.4, 0.4, 0.4)
			enemy:DoPeriodicTask(2.5, function()
				enemy.sg:GoToState("run")
			end)
			distance = distance + 16
		end

		local offset = FindWalkableOffset(pos, math.random() * 2 * PI, 10, 5)
        if offset ~= nil then
            inst.Transform:SetPosition(pos.x + offset.x,0,pos.z + offset.z)
        end

        inst.SoundEmitter:PlaySound("dontstarve/common/ghost_spawn")
        inst.sg:GoToState("teleport")
    end
end

--暴怒被动
local function Minotaur_AngerSkill(inst)
	if inst._task == nil then
        inst.components.health:SetInvincible(true)
        inst._fx = SpawnPrefab("forcefieldfx")
        inst.SoundEmitter:PlaySound("dontstarve/common/shadowTentacleAttack_1")
        inst.SoundEmitter:PlaySound("dontstarve/common/shadowTentacleAttack_2")
        inst._fx.entity:SetParent(inst.entity)
        inst._fx.Transform:SetPosition(0, -1, 0)
        inst._fx.Transform:SetScale(2.2, 2.2, 2.2)
       
        inst._task = inst:DoTaskInTime(4, function(inst)
            if inst._fx ~= nil then
                inst._fx:kill_fx()
                inst._fx = nil
            end
            if inst:IsValid() then
				inst.components.health:SetInvincible(false)
                if inst._task then
                    inst._task:Cancel()
                    inst._task = nil
                end
            end
        end)
    end
end

local actionhandlers = { }

local events = {
    CommonHandlers.OnLocomote(true, true),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnAttack(),
	CommonHandlers.OnDeath(),
    --CommonHandlers.OnAttacked(),
    EventHandler("attacked", function(inst)
		if inst.components.health and not inst.components.health:IsDead() then
			if inst.components.freezable and inst.components.freezable:IsFrozen() or not inst.sg:HasStateTag("busy") then
				inst.sg:GoToState("hit")
			end
		end
		if inst.anger and math.random() < 0.3 then
			Minotaur_AngerSkill(inst)
		end
	end),
    EventHandler("doattack", function(inst)
        local nstate = "attack"
        if inst.sg:HasStateTag("running") then
            nstate = "runningattack"
        end
        if inst.components.health and not inst.components.health:IsDead()
           and not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState(nstate)
        end
    end),
    EventHandler("locomote", function(inst)
        local is_attacking = inst.sg:HasStateTag("attack") or inst.sg:HasStateTag("runningattack")
        local is_busy = inst.sg:HasStateTag("busy")
        local is_idling = inst.sg:HasStateTag("idle")
        local is_moving = inst.sg:HasStateTag("moving")
        local is_running = inst.sg:HasStateTag("running") or inst.sg:HasStateTag("runningattack")

        if is_attacking or is_busy then return end

        local should_move = inst.components.locomotor:WantsToMoveForward()
        local should_run = inst.components.locomotor:WantsToRun()
        
        if is_moving and not should_move then
            inst.SoundEmitter:KillSound("charge")
            if is_running then
                inst.sg:GoToState("run_stop")
            else
                inst.sg:GoToState("walk_stop")
            end
        elseif (not is_moving and should_move) or (is_moving and should_move and is_running ~= should_run) then
            if should_run then
                inst.sg:GoToState("run_start")
            else
                inst.sg:GoToState("walk_start")
            end
        end 
    end),
}

local states = {
     State{  
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst, playanim)
            inst.Physics:Stop()
            inst.SoundEmitter:KillSound("charge")
            if playanim then
                inst.AnimState:PlayAnimation(playanim)
                inst.AnimState:PushAnimation("idle", true)
            else
                inst.AnimState:PlayAnimation("idle", true)
            end
            inst.SoundEmitter:PlaySound("dontstarve/creatures/rook_minotaur/voice")
        end,
        events = {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{ 
		name = "run_start",
		tags = {"moving", "running", "busy", "atk_pre", "canrotate"},            
		onenter = function(inst)
			inst.Physics:Stop()
			-- inst.components.locomotor:RunForward()
			inst.SoundEmitter:PlaySound("dontstarve/creatures/rook_minotaur/pawground")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/rook_minotaur/voice")
			inst.AnimState:PlayAnimation("atk_pre")
			inst.AnimState:PlayAnimation("paw_loop", true)
			inst.sg:SetTimeout(1.5)
		end,
		ontimeout = function(inst)
			inst.sg:GoToState("run")
			inst:PushEvent("attackstart" )
		end,
		timeline = {
			TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rook_minotaur/pawground") end ),
			TimeEvent(30*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rook_minotaur/pawground") end ),
		},        
		onexit = function(inst)
		end,
	},

    State{
		name = "run",
		tags = {"moving", "running"},    
		onenter = function(inst) 
			inst.components.locomotor:RunForward()
			if not inst.AnimState:IsCurrentAnimation("atk") then
				inst.AnimState:PlayAnimation("atk", true)
			end
			inst.SoundEmitter:PlaySound("dontstarve/creatures/rook_minotaur/step")
		end,
		timeline= {
			TimeEvent(5*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/creatures/rook_minotaur/step")                                        
			end ),
		},
		events = {
			
		},
		ontimeout = function(inst)
			inst.sg:GoToState("run")
		end,
		onexit = function(inst)
			if GetBoost(inst,1) then
				Minotaur_Skill1(inst)
			end
		end
	},

    State{
		name = "teleport",
		tags = {"moving", "running", "busy", "atk_pre", "canrotate"},
		onenter = function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/common/ghost_spawn")
			local fx = SpawnPrefab("statue_transition_2")
			if fx then
				fx.Transform:SetPosition(inst:GetPosition():Get())
				fx.Transform:SetScale(3,4,3)
			end
	
			inst.Physics:Stop()
			--inst.components.locomotor:RunForward()
			inst.SoundEmitter:PlaySound("dontstarve/creatures/rook_minotaur/pawground")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/rook_minotaur/voice")
			inst.AnimState:PlayAnimation("atk_pre")
			inst.AnimState:PlayAnimation("paw_loop", true)
			inst.sg:SetTimeout(.25)
		end,
		ontimeout = function(inst)
			inst.sg:GoToState("run")
			inst:PushEvent("attackstart")
		end,
		timeline = {
			TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rook_minotaur/pawground") end ),
			TimeEvent(30*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rook_minotaur/pawground") end ),
		},        
		onexit = function(inst)
			--inst.SoundEmitter:PlaySound(inst.soundpath .. "charge_LP","charge")
		end,
	},
    
    State{
		name = "run_stop",
		tags = {"canrotate", "idle"},            
		onenter = function(inst) 
			inst.SoundEmitter:KillSound("charge")
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("gore")
		end,           
		timeline = {
			TimeEvent(5*FRAMES, function(inst)
				inst.components.combat:DoAttack()
			end),
		},
		events = {
			EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	},    

   State{
        name = "taunt",
        tags = {"busy"},       
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/rook_minotaur/voice")
        end,
        timeline = {
		    TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rook_minotaur/voice") end ),
		    TimeEvent(27*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rook_minotaur/voice") end ),
        },
        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{  
        name = "runningattack",
        tags = {"runningattack"},        
        onenter = function(inst)
            inst.SoundEmitter:KillSound("charge")
            inst.components.combat:StartAttack()
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("gore")
        end,       
        timeline = {
            TimeEvent(1*FRAMES, function(inst) inst.components.combat:DoAttack() end),
        },       
        events = {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("attack") end),
        },
    },
	
    State{
        name = "attack",
        tags = {"attack", "busy"},       
        onenter = function(inst)
            inst.components.combat:StartAttack()
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("gore")
        end,        
        timeline =
        {
            TimeEvent(5*FRAMES, function(inst) inst.components.combat:DoAttack() end),
        },
        events = {
            EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("idle")
				if GetBoost(inst,2) then
					Minotaur_Skill2(inst)
					if not inst.components.timer:TimerExists("skill_cd") then
						inst.components.timer:StartTimer("skill_cd", inst.skill_cd or 1)
					end
				end
			end)
        },
    },
	
    State{
        name = "hit",
        tags = {"hit", "busy"},
        onenter = function(inst) 
			inst.components.locomotor:StopMoving()
			inst.AnimState:PlayAnimation("hit")
        end,
        hittimeline = {
			TimeEvent(0*FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/rook_minotaur/hurt")
			end)
		},  
        events = {
			EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("idle")
			end)
		},
    },

	State{
        name = "death",
        tags = { "death", "busy" },
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("death")
            inst.persists = false
            inst.components.lootdropper:DropLoot()

            local chest = SpawnPrefab("minotaurchestspawner")
            chest.Transform:SetPosition(inst.Transform:GetWorldPosition())
            chest.minotaur = inst

            inst:AddTag("NOCLICK")
        end,
        timeline = {
            TimeEvent(0, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/rook_minotaur/death")
                inst.SoundEmitter:PlaySound("dontstarve/creatures/rook_minotaur/death_voice")
            end),
            TimeEvent(2, ErodeAway),
        },
        onexit = function(inst)
            inst:RemoveTag("NOCLICK")
        end,
    },
}

CommonStates.AddWalkStates(states,{
    starttimeline = {
	    TimeEvent(0*FRAMES, function(inst) inst.Physics:Stop() end ),
    },
	walktimeline = {
		TimeEvent(0*FRAMES, function(inst) inst.Physics:Stop() end ),
		TimeEvent(7*FRAMES, function(inst) 
			inst.components.locomotor:WalkForward()
		end ),
		TimeEvent(20*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/creatures/rook_minotaur/step")
			ShakeAllCameras(CAMERA.VERTICAL, .5, .05, .1, inst, 40)
			inst.Physics:Stop()
		end ),
	},
}, nil,true)

CommonStates.AddSleepStates(states,{
    starttimeline =  {
		TimeEvent(11*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rook_minotaur/liedown") end ),
    },
	sleeptimeline = {
        TimeEvent(18*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rook_minotaur/sleep") end),
	},
})

CommonStates.AddFrozenStates(states)
return StateGraph("rook", states, events, "idle", actionhandlers)