require("stategraphs/commonstates")

--获取技能
local function getsk(num)
	return math.random(1,num)
end
local events = {
	CommonHandlers.OnLocomote(true, false),
    -- EventHandler("attacked", function(inst, data)
	-- end),
	-- EventHandler("test", function(inst, data)
		-- if not inst.components.health:IsDead() and not inst.sg:HasStateTag("skill") then
			-- local target=data.target or inst.components.combat.target
			-- if target then
				-- inst.sg:GoToState("skill2",target)
			-- end
		-- end
	-- end),
    EventHandler("doattack", function(inst, data)
        if not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") then
			if data.target then
				local statename = "attack"
				if inst.mode then
					if inst.mode == 1 then           --位移类
						inst.skcd1 = GetTime()
						statename = inst.skli1[getsk(#inst.skli1)]
					elseif inst.mode == 2 then      --伤害类
						inst.skcd2 = GetTime()
						statename = inst.skli2[getsk(#inst.skli2)]
					elseif inst.mode == 3 then      --大招类
						inst.skcd3 = GetTime()
						statename = inst.skli3[getsk(#inst.skli3)]
					end
				end
				inst.sg:GoToState(statename,data.target)
			end
        end
    end),
    EventHandler("death", function(inst)
        inst.sg:GoToState("death")
    end),
}

local states = {
	--突刺
	State{
		name="skill1",
		tags = {"attack","jumping","canrotate","busy"},	--jumping不能少,如果没有该标签会被behavior结点里被stop
		onenter = function(inst,target)
			inst.components.locomotor:Stop()
			inst.components.locomotor:StopMoving()
			inst.sg:SetTimeout(11*FRAMES)
			inst:ForceFacePoint(target.Transform:GetWorldPosition())
			LongAttack(inst,11*FRAMES,inst.damage,4)
		end,
		ontimeout = function(inst)
			inst.sg:GoToState("idle")
		end,
		timeline = {		
			TimeEvent(1*FRAMES, function(inst)
				inst.AnimState:PlayAnimation("spearjab")
				inst.Physics:SetMotorVel(100,0,0)
				local x,y,z = inst.Transform:GetWorldPosition()
				local fx = SpawnPrefab("boss_skill_fx010"):set(4)
				fx.Transform:SetPosition(x,3,z)
				fx.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
				fx.Transform:SetRotation(inst.Transform:GetRotation())
			end),
			TimeEvent(10*FRAMES, function(inst) 
				inst.Physics:Stop()
				inst.components.locomotor:Stop()
			end),
		},
		onexit = function(inst)
		end,
	},

	--天降
	State{
        name = "skill2",
        tags = {"busy", "skill", "jumping","busy"},
		onenter = function(inst,target)
            inst.components.locomotor:StopMoving()
			inst.AnimState:PlayAnimation("jumpout")
			inst.sg:SetTimeout(20*FRAMES)
			inst.sg.statemem.target = target
			inst:ForceFacePoint(target.Transform:GetWorldPosition())
			inst.distance = inst:GetPosition():Dist(target:GetPosition())
        end,
		ontimeout = function(inst)
			inst.sg:GoToState("idle")
		end,
		timeline = {
			TimeEvent(1 * FRAMES, function(inst)
				inst.Physics:SetMotorVel(inst.distance, 20*10, 0)
			end),
			TimeEvent(10 * FRAMES, function(inst)
				inst.Physics:SetMotorVel(inst.distance, -20*10, 0)
				local x,y,z = inst.Transform:GetWorldPosition()
				local fx = SpawnPrefab("boss_skill_fx007"):set(8)
				fx.Transform:SetPosition(x,2,z)
				inst.Transform:SetPosition(x,0,z)
				ShortAttack(inst,inst.damage,6)
			end),
		},
		onexit = function(inst)
		end
	},

	--旋转打击
	State{
        name = "skill3",
        tags = {"busy", "skill"},
		onenter = function(inst,target)
            inst.components.locomotor:StopMoving()
			inst.Physics:Stop()
			inst.sg:SetTimeout(32*FRAMES)
			inst.sg.statemem.target = target
        end,
		ontimeout = function(inst)
			inst.sg:GoToState("idle")
		end,
		timeline = {
			TimeEvent(1*FRAMES, function(inst)
				inst.Transform:SetPosition(inst.sg.statemem.target.Transform:GetWorldPosition())
				inst.AnimState:PlayAnimation("rotate")
				local x,y,z = inst.Transform:GetWorldPosition()
				local fx = SpawnPrefab("boss_skill_fx002"):set(5)
				fx.Transform:SetPosition(x,2,z)
				ShortAttack(inst,inst.damage,4)
			end),
			TimeEvent(11*FRAMES, function(inst)
				inst.AnimState:PlayAnimation("rotate")
				local x,y,z = inst.Transform:GetWorldPosition()
				local fx = SpawnPrefab("boss_skill_fx002"):set(5)
				fx.Transform:SetPosition(x,2,z)
				ShortAttack(inst,inst.damage,4)
			end),
			TimeEvent(21*FRAMES, function(inst)
				inst.AnimState:PlayAnimation("rotate")
				local x,y,z = inst.Transform:GetWorldPosition()
				local fx = SpawnPrefab("boss_skill_fx002"):set(5)
				fx.Transform:SetPosition(x,2,z)
				ShortAttack(inst,inst.damage,4)
			end),
		},
		onexit = function(inst)
		end
	},

	--气功波
	State{
        name = "skill4",
        tags = {"busy", "skill"},
		onenter = function(inst,target)
            inst.components.locomotor:StopMoving()
			inst.Physics:Stop()
			inst.sg:SetTimeout(32*FRAMES)
			inst.sg.statemem.target = target
        end,
		ontimeout = function(inst)
			inst.sg:GoToState("idle")
		end,
		timeline = {
			TimeEvent(1*FRAMES, function(inst)
				inst.AnimState:PlayAnimation("shove")
				local target = inst.sg.statemem.target
				inst:ForceFacePoint(target.Transform:GetWorldPosition())
				local fx = SpawnPrefab("boss_skill_fx009"):set(3,1,inst.damage,4)
				MakeFlyitem(inst,target,fx,{10,2,0})
			end),
			TimeEvent(11*FRAMES, function(inst)
				inst.AnimState:PlayAnimation("shove")
				local target = inst.sg.statemem.target
				inst:ForceFacePoint(target.Transform:GetWorldPosition())
				local fx = SpawnPrefab("boss_skill_fx009"):set(3,1,inst.damage,4)
				MakeFlyitem(inst,target,fx,{10,2,0})
			end),
			TimeEvent(21*FRAMES, function(inst)
				inst.AnimState:PlayAnimation("shove")
				local target = inst.sg.statemem.target
				inst:ForceFacePoint(target.Transform:GetWorldPosition())
				local fx = SpawnPrefab("boss_skill_fx009"):set(3,1,inst.damage,4)
				MakeFlyitem(inst,target,fx,{10,2,0})
			end),
		},
		onexit = function(inst)
		end	
	},

	--龙卷风
	State{
        name = "skill5",
        tags = {"attack", "notalking", "busy", "skill"},
        onenter = function(inst,target)
			inst.components.locomotor:StopMoving()
			inst.Physics:Stop()
			inst.sg:SetTimeout(50*FRAMES)
            inst.sg.statemem.target = target
            inst.AnimState:PlayAnimation("jumpout")
        end,
		ontimeout = function(inst)
			inst.sg:GoToState("idle")
			local x,y,z = inst.Transform:GetWorldPosition()
			inst.Transform:SetPosition(x, 0, z)
		end,
        timeline = {
			TimeEvent(1*FRAMES, function(inst)
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition(x, 7, z)
            end),
            TimeEvent(26*FRAMES, function(inst)
				inst.AnimState:PlayAnimation("raise")
				local anglelist = {0,51.5,103,154.5,206,257.8,308}
				for k,v in pairs(anglelist) do
					local fx = SpawnPrefab("boss_skill_fx008"):set(3,1,inst.damage,4,1)
					AngleFly(inst,fx,v,{10,0,0})
				end
            end),
        },
		onexit = function(inst)
		end,
    },

	--光刃
	State{
        name = "skill6",
        tags = {"busy", "skill"},
		onenter = function(inst,target)
            inst.components.locomotor:StopMoving()
			inst.Physics:Stop()
			inst.sg:SetTimeout(16*FRAMES)
			inst.AnimState:PlayAnimation("chop_loop")
			inst:ForceFacePoint(target.Transform:GetWorldPosition())
        end,
		ontimeout = function(inst)
			inst.sg:GoToState("idle")
		end,
		timeline = {
			TimeEvent(13*FRAMES, function(inst)
				local anglelist = {-39,-26,-13,0,13,26,39}
				for k,v in pairs(anglelist) do
					local fx = SpawnPrefab("boss_skill_fx018"):set(3,1,inst.damage,4,1)
					fx.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
					AngleFly(inst,fx,v,{10,2,0})
				end
			end),
		},
		onexit = function(inst)
		end
	},
--====================================================-基础SG-==============================================
    State{
        name = "death",
        tags = {"busy"},
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:Hide("swap_arm_carry")
            inst.AnimState:PlayAnimation("death")
            inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
			TheNet:Announce(STRINGS.NAMES[string.upper(inst.prefab)].."被勇士们击杀!")
			if inst.uptarget then
				local x,y,z = inst.Transform:GetWorldPosition()
				local ents = TheSim:FindEntities(x, y, z, 100, {inst.prefab})
				if #ents > 1 then
					TheNet:Announce("勇士们请注意!残存的"..STRINGS.NAMES[string.upper(inst.prefab)].."开始吸收散逸的恐惧之力!")
				end
				for k,v in pairs(ents) do
					if v and v.components.health and not v.components.health:IsDead() then
						v.sg:GoToState("levelup")
					end
				end
			end
        end,
    },
	
	--升级
	State{
        name = "levelup",
        tags = {"busy", "skill", "jumping"},
		onenter = function(inst)
            inst.components.locomotor:StopMoving()
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("powerup")
			inst.sg:SetTimeout(150*FRAMES)
        end,
		ontimeout = function(inst)
			local x,y,z = inst.Transform:GetWorldPosition()
			local uptarget = SpawnPrefab(inst.uptarget)
			uptarget.Transform:SetPosition(x,0,z)
			TheNet:Announce("进化完成!"..STRINGS.NAMES[string.upper(uptarget.prefab)].."降临世界!")

			local fx = SpawnPrefab("boss_skill_fx007"):set(8)
			fx.Transform:SetPosition(x,2,z)
			ShortAttack(uptarget,uptarget.damage,6)
			inst:Remove()
		end,
		timeline = {
			TimeEvent(43 * FRAMES, function(inst)
				inst.AnimState:PlayAnimation("jumpout")
			end),
			TimeEvent(46 * FRAMES, function(inst)
				inst.Physics:SetMotorVel(0, 200, 0)
			end),
			TimeEvent(50 * FRAMES, function(inst)
				local x,y,z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition(x,100,z)
			end),
		},
		onexit = function(inst)
		end
	},

    State{
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst, pushanim)     
            inst.components.locomotor:Stop()
            local anims = {"idle_loop"}          
            local anim = "idle_loop"                      
            if pushanim then
                for k,v in pairs (anims) do
					inst.AnimState:PushAnimation(v, k == #anims)
				end
            else
                inst.AnimState:PlayAnimation(anims[1], #anims == 1)
                for k,v in pairs (anims) do
					if k > 1 then
						inst.AnimState:PushAnimation(v, k == #anims)
					end
				end
            end  
            inst.sg:SetTimeout(math.random()*4+2)
        end,
    },
	
	State{
        name = "attack",
        tags = {"attack", "notalking", "abouttoattack", "busy"},
        onenter = function(inst,target)
            inst.sg.statemem.target = target
            inst.components.combat:StartAttack()
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("atk")  
        end,
        timeline = {	
            TimeEvent(6*FRAMES, function(inst)
                inst.sg:RemoveStateTag("abouttoattack")
                inst.components.combat:DoAttack(inst.sg.statemem.target)
            end),
			TimeEvent(10*FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
				inst.sg:RemoveStateTag("attack")
            end),
        },
        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end ),
        },
    },    
   
    State{
        name = "run_start",
        tags = {"moving", "running", "canrotate"},       
        onenter = function(inst)
			inst.components.locomotor:RunForward()
            inst.AnimState:PlayAnimation("run_pre")
            inst.sg.mem.foosteps = 0
        end,
        onupdate = function(inst)
            inst.components.locomotor:RunForward()
        end,
        events = {   
            EventHandler("animover", function(inst)
				inst.sg:GoToState("run")
			end),        
        },
        timeline = {
            TimeEvent(4*FRAMES, function(inst)
            end),
        },
    },

    State{
        name = "run",
        tags = {"moving", "running", "canrotate"},       
        onenter = function(inst) 
            inst.components.locomotor:RunForward()
            inst.AnimState:PlayAnimation("run_loop")
        end,
        onupdate = function(inst)
            inst.components.locomotor:RunForward()
        end,
        timeline = {
            TimeEvent(7*FRAMES, function(inst)
				inst.sg.mem.foosteps = inst.sg.mem.foosteps + 1 
            end),
            TimeEvent(15*FRAMES, function(inst)
				inst.sg.mem.foosteps = inst.sg.mem.foosteps + 1
            end),
        },
        events = {   
            EventHandler("animover", function(inst)
				inst.sg:GoToState("run")
			end),        
        },
    },
    
    State{
        name = "run_stop",
        tags = {"canrotate", "idle"},
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("run_pst")
        end,
        events = {   
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),        
        },       
    },    
}
    
return StateGraph("zg_ch3_mihawk", states, events, "idle")