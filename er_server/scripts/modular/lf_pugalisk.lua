--ByLaoluFix 2021-09-11
--普加利斯克服务器端转定义文件
------------------------
--声明接口文件
--大蛇头尸体挖掘后的战利品
local PUGALISK_HEALTH = 100000		--大蛇的生命值
local pugalisk_lootTable = {"spear_wathgrithr","spear_wathgrithr","spear_wathgrithr"}
-----------------------------
local pu = require ("prefabs/pugalisk_util")
require("brains/pugalisk_headbrain")
require("brains/pugalisk_tailbrain")
require "stategraphs/SGpugalisk_head"
------------------------
--凝视技能处理
local function onupdate(inst, dt)
	if dt then
		inst.timeremaining = inst.timeremaining - dt
		local dist = Remap(inst.timeremaining, inst.timeremainingMax, 0, 2, 6)
		inst.components.creatureprox:SetDist(dist,dist+1)
	end
end
local function oncollide(inst, other)
    if other.components.freezable and not other.components.freezable:IsFrozen( ) and other ~= inst.host then
    	if inst.host and other.components.combat then
    		other:PushEvent("attacked", {attacker = inst.host, damage = 0, weapon = inst})
    	end
        other.components.freezable:AddColdness(5)
        other.components.freezable:SpawnShatterFX()
    end
end

local function oncollide2(inst, other)
    if other.components.freezable and not other.components.freezable:IsFrozen( ) and other ~= inst.host then
		if not other:HasTag("player") then
			if inst.host and other.components.combat then
				other:PushEvent("attacked", {attacker = inst.host, damage = 0, weapon = inst})
			end
			other.components.freezable:AddColdness(5)
			other.components.freezable:SpawnShatterFX()
		end	
	end
end

AddPrefabPostInit("gaze_beam", function(inst)
	inst:AddComponent("genericonupdate")
    inst.components.genericonupdate:Setup(onupdate)
	
	inst:AddComponent("creatureprox")
    inst.components.creatureprox.inproxfn = oncollide
    inst.components.creatureprox.period = 0.001
    inst.components.creatureprox:SetDist(3,4)	
    inst.components.creatureprox.piggybackfn = onupdate
    inst.components.creatureprox.all = true
	-- inst.SoundEmitter:PlaySound("Hamlet/creatures/boss/pugalisk/gaze_LP","gaze")
	-- inst.SoundEmitter:PlaySound("LF_Snake/pugalisk/gaze_LP","gaze")
	
	inst:ListenForEvent("animover", function(inst, data)
		if inst.components.creatureprox.enabled then
			inst.components.creatureprox.enabled = false
			inst.AnimState:PlayAnimation("loop_pst")
			inst.SoundEmitter:KillSound("gaze")
			inst:Remove()
		else
			inst:Remove()
		end
	end) 
end)
AddPrefabPostInit("gaze_beam2", function(inst)
	inst:AddComponent("genericonupdate")
    inst.components.genericonupdate:Setup(onupdate)
	
	inst:AddComponent("creatureprox")
    inst.components.creatureprox.inproxfn = oncollide2
    inst.components.creatureprox.period = 0.001
    inst.components.creatureprox:SetDist(3,4)	
    inst.components.creatureprox.piggybackfn = onupdate
    inst.components.creatureprox.all = true
	-- inst.SoundEmitter:PlaySound("Hamlet/creatures/boss/pugalisk/gaze_LP","gaze")
	-- inst.SoundEmitter:PlaySound("LF_Snake/pugalisk/gaze_LP","gaze")
	
	inst:ListenForEvent("animover", function(inst, data)
		if inst.components.creatureprox.enabled then
			inst.components.creatureprox.enabled = false
			inst.AnimState:PlayAnimation("loop_pst")
			inst.SoundEmitter:KillSound("gaze")
			inst:Remove()
		else
			inst:Remove()
		end
	end) 
end)
--------------------------------------------------------------------
--大蛇的处理
------------------------
--大蛇头的尸体
local function onfinishcallback(inst, worker)
    -- inst.MiniMapEntity:SetEnabled(false)
    inst:RemoveComponent("workable")
    inst.components.hole.canbury = true

    SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())

    if worker then
		--找出哪一边掉落战利品
        local pt = Vector3(inst.Transform:GetWorldPosition())
        local hispos = Vector3(worker.Transform:GetWorldPosition())

        local he_right = ((hispos - pt):Dot(TheCamera:GetRightVec()) > 0)
        
        if he_right then
            inst.components.lootdropper:DropLoot(pt - (TheCamera:GetRightVec()*(math.random()+1)))           
        else
            inst.components.lootdropper:DropLoot(pt + (TheCamera:GetRightVec()*(math.random()+1)))            
        end       
        inst:Remove()
    end 
end
AddPrefabPostInit("pugalisk_corpse", function(inst)
	inst:AddComponent("lootdropper")
	inst:AddComponent("hole")
	inst:AddComponent("inspectable")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetWorkLeft(1)
    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot(pugalisk_lootTable or "poop")--bonestaff
    inst.components.workable:SetOnFinishCallback(onfinishcallback)
end)
------------------------
--通用
local function redirecthealth(inst, amount, overtime, cause, ignore_invincible)

    local originalinst = inst

    if inst.startpt then
        inst = inst.startpt
    end

    if amount < 0 and( (inst.components.segmented and inst.components.segmented.vulnerablesegments == 0) or inst:HasTag("tail") or inst:HasTag("head") ) then
--        if cause == GetPlayer().prefab then
--            GetPlayer().components.talker:Say(GetString(GetPlayer().prefab, "ANNOUNCE_PUGALISK_INVULNERABLE"))        
--        end
        inst.SoundEmitter:PlaySound("dontstarve/common/destroy_metal",nil,.25)
        inst.SoundEmitter:PlaySound("dontstarve/wilson/hit_metal")

    elseif amount and inst.host then

        local fx = SpawnPrefab("collapse_small")--"snake_scales_fx")  
        fx.Transform:SetScale(1.5,1.5,1.5)
        local pt= Vector3(originalinst.Transform:GetWorldPosition())
        fx.Transform:SetPosition(pt.x,pt.y + 2 + math.random()*2,pt.z)

        inst:PushEvent("dohitanim")
        inst.host.components.health:DoDelta(amount, overtime, cause, ignore_invincible, true)
        inst.host:PushEvent("attacked")
    end    
end

--大蛇蛇头(主要)
local function onhostdeath(inst)
--    TheCamera:Shake("FULL",3, 0.05, .2)
    local mb = inst.components.multibody
	if mb then
		if mb.bodies then
			for i,body in ipairs(mb.bodies)do
				if body and body.components.health then
					body.components.health:Kill()
				end
			end
		end
		if mb.tail and mb.tail.components.health then
		   mb.tail:Remove() -- mb.tail.components.health:Kill()
		end
		--重新激活大蛇窝
		if inst.home and inst.home.reactivate then
			inst.home.reactivate(inst.home)
		end    
		mb:Kill()
	end
	--做个安全防护,再次执行一次蛇窝功能重置
    local ent = TheSim:FindFirstEntityWithTag("pugalisk_trap_door")
    if ent and ent.reactivate then
        ent.reactivate(ent)
    end
	--处理死亡音效
	-- SetEngaged(inst, false)
end
--蛇头
AddPrefabPostInit("pugalisk", function(inst)
	inst:AddComponent("health")
    inst.components.health:SetMaxHealth(PUGALISK_HEALTH)
    inst.components.health.destroytime = 5
    inst.components.health:StartRegen(1, 2)
    inst.components.health.redirect = redirecthealth
	
	inst:AddComponent("multibody")    
    inst.components.multibody:Setup(5,"pugalisk_body")
	
    inst:ListenForEvent("bodycomplete", function(inst, data) 
        local pt = pu.findsafelocation( data.pos , data.angle/DEGREES )
        inst.Transform:SetPosition(pt.x,0,pt.z)
        inst:DoTaskInTime(0.75, function() 

--            local player = GetClosestInstWithTag("player", inst, SHAKE_DIST)
--            if player then
--                player:ShakeCamera(CAMERASHAKE.SIDE, 1, .02, .25)			
--                player.components.playercontroller:ShakeCamera(inst, "VERTICAL", 0.3, 0.03, 1, SHAKE_DIST)
--            end            
            inst.components.groundpounder:GroundPound()
            -- inst.SoundEmitter:PlaySound("Hamlet/creatures/boss/pugalisk/emerge","emerge")
			inst.SoundEmitter:PlaySound("LF_Snake/pugalisk/emerge","emerge")
            inst.SoundEmitter:SetParameter( "emerge", "start", math.random() )         
            pu.DetermineAction(inst)
        end)
    end)
	
	inst:ListenForEvent("bodyfinished", function(inst, data) 
            inst.components.multibody:RemoveBody(data.body)
        end)
	inst:ListenForEvent("death", function(inst, data) 
		inst.SoundEmitter:KillSound("LF_Snake")   
        onhostdeath(inst)
    end)
	
	inst.spawntask = inst:DoTaskInTime(0,function() 
            inst.spawned = true
        end)
		
	inst:SetStateGraph("SGpugalisk_head")
    local brain = require "brains/pugalisk_headbrain"
    inst:SetBrain(brain)
	-- inst:RestartBrain()
	
end)
----------------
--大蛇身体
local function segment_deathfn(segment)
	--死亡爆率
    -- segment.SoundEmitter:PlaySound("Hamlet/creatures/boss/pugalisk/explode")
	segment.SoundEmitter:PlaySound("LF_Snake/pugalisk/explode")
    local pt= Vector3(segment.Transform:GetWorldPosition())

    local bone = segment.components.lootdropper:SpawnLootPrefab("snake_bone",pt)
       
    if math.random()<0.6 then
        local bone = segment.components.lootdropper:SpawnLootPrefab("boneshard",pt)
    end        
    if math.random()<0.2 then
        local bone = segment.components.lootdropper:SpawnLootPrefab("monstermeat",pt)
    end
    if math.random()<0.005 then
        local bone = segment.components.lootdropper:SpawnLootPrefab("redgem", pt)
    end
    if math.random()<0.005 then
        local bone = segment.components.lootdropper:SpawnLootPrefab("bluegem", pt)
    end
    if math.random()<0.05 then
        local bone = segment.components.lootdropper:SpawnLootPrefab("spoiled_fish", pt)
    end
    
    local fx = SpawnPrefab("collapse_small")--"snake_scales_fx")    
    fx.Transform:SetScale(1.5,1.5,1.5)
    fx.Transform:SetPosition(pt.x,pt.y + 2 + math.random()*2,pt.z)
end
--蛇身
AddPrefabPostInit("pugalisk_body", function(inst)
	inst:AddComponent("segmented")
    inst.components.segmented.segment_deathfn = segment_deathfn
	inst:AddComponent("health")
    inst.components.health:SetMaxHealth(PUGALISK_HEALTH)
    inst.components.health.destroytime = 5
    inst.components.health.redirect = redirecthealth
end)
--蛇尾
AddPrefabPostInit("pugalisk_tail", function(inst)
	inst:AddComponent("health")
    inst.components.health:SetMaxHealth(PUGALISK_HEALTH)
    inst.components.health.destroytime = 5
    inst.components.health.redirect = redirecthealth
	
	inst:SetStateGraph("SGpugalisk_head")
    local brain = require "brains/pugalisk_tailbrain"
    inst:SetBrain(brain)
end)
--蛇分段
AddPrefabPostInit("pugalisk_segment", function(inst)
	inst:AddComponent("health")
    inst.components.health:SetMaxHealth(PUGALISK_HEALTH)
    inst.components.health.destroytime = 5
    inst.components.health.redirect = redirecthealth
end)