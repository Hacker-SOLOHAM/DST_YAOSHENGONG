require("stategraphs/commonstates")
local actionhandlers ={}
local events = {
    CommonHandlers.OnLocomote(true, false),
    --CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnAttack(),
}
local sounds = {
    walk = "dontstarve/beefalo/walk",
    grunt = "dontstarve/beefalo/grunt",
    yell = "dontstarve/beefalo/yell",
    swish = "dontstarve/beefalo/tail_swish",
    curious = "dontstarve/beefalo/curious",
    angry = "dontstarve/beefalo/angry",
    sleep = "dontstarve/beefalo/sleep",
}

local function DoMountSound(inst, mount, sound, ispredicted)
    inst.SoundEmitter:PlaySound(sounds[sound], nil, nil, ispredicted)
end

local function DoMountedFoleySounds(inst)
    inst.SoundEmitter:PlaySound("dontstarve/beefalo/saddle/war_foley", nil, nil, true)
end

local DoRunSounds = function(inst)
    if inst.sg.mem.footsteps > 3 then
        PlayFootstep(inst, .6, true)
    else
        inst.sg.mem.footsteps = inst.sg.mem.footsteps + 1
        PlayFootstep(inst, 1, true)
    end
end

local states = {
    State{
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst, pushanim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle_loop", true)
        end,
    },

    State{
        name = "run_start",
        tags = {"moving", "running", "canrotate"},
        onenter = function(inst)
            inst.components.locomotor:RunForward()
            inst.AnimState:PlayAnimation("run_pre")
			inst.sg.mem.footsteps =0
        end,
        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("run")
                end
            end),
        },
        timeline = {
            TimeEvent(5 * FRAMES, function(inst)
                PlayFootstep(inst, nil, true)
            end),
        },
    },

    State{
        name = "run",
        tags = {"moving", "running", "canrotate"},
        onenter = function(inst)
            inst.components.locomotor:RunForward()
			if not inst.AnimState:IsCurrentAnimation("run_loop") then
                inst.AnimState:PlayAnimation("run_loop", true)
            end
			inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength() + .5 * FRAMES)
        end,
        timeline = {
            TimeEvent(0 * FRAMES, function(inst)
                if inst.rg_mount then
                    DoMountedFoleySounds(inst)
                end
            end),
            TimeEvent(5 * FRAMES, function(inst)
                if inst.rg_mount then
                    DoRunSounds(inst)
                end
            end),
            TimeEvent(7 * FRAMES, function(inst)
                if not inst.rg_mount then
                    DoRunSounds(inst)
                end
            end),
            TimeEvent(15 * FRAMES, function(inst)
                if not inst.rg_mount then
                    DoRunSounds(inst)
                end
            end),
        },
        ontimeout = function(inst)
            inst.sg:GoToState("run")
        end,
    },

    State{
        name = "run_stop",
        tags = {"canrotate", "idle"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("run_pst")
        end,
        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "attack",
        tags = {"attack", "notalking", "abouttoattack", "busy"},
        onenter = function(inst)
            inst.sg.statemem.target = inst.components.combat.target
            inst.components.combat:StartAttack()
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("atk_pre")
            inst.AnimState:PushAnimation("atk", false)  
			local cooldown = inst.components.combat.min_attack_period + .5 * FRAMES			
			if inst.rg_mount then
				DoMountSound(inst, nil, "angry", true)
				cooldown = math.max(cooldown, 16 * FRAMES)	
			else
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon",nil,nil,true)
				cooldown = math.max(cooldown, 13 * FRAMES)				
			end
			
			inst.sg:SetTimeout(cooldown)
            if inst.components.combat.target ~= nil and inst.components.combat.target:IsValid() then
                inst:FacePoint(inst.components.combat.target.Transform:GetWorldPosition())
            end
        end,
        timeline = {
            TimeEvent(8*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) inst.sg:RemoveStateTag("abouttoattack") end),
        },
        ontimeout = function(inst)
            inst.sg:RemoveStateTag("attack")
            inst.sg:AddStateTag("idle")
        end,
        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "death",
        tags = {"busy"},
        onenter = function(inst)
            inst.Physics:Stop()
			if inst.rg_mount then
				inst.AnimState:PlayAnimation("fall_off")
				DoMountSound(inst, nil, "yell")
			else
				inst.AnimState:PlayAnimation("death")
				inst.SoundEmitter:PlaySound("dontstarve/wilson/death")
			end
			inst.components.lootdropper:DropLoot(inst:GetPosition())
        end,
        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
					ErodeAway(inst)
					inst:DoTaskInTime(1,inst.Remove)
                end
            end),
        },
    },
}

return StateGraph("rg_kulou", states, events, "idle", actionhandlers)