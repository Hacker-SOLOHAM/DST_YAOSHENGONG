--ByLaoluFix
--远古浩克转定义文件
local brain = require("brains/ancient_hulkbrain")
require "stategraphs/SGancient_hulk"

AddPrefabPostInit("ancient_hulk", function(inst)
	inst:SetStateGraph("SGancient_hulk")
    inst:SetBrain(brain)
end)

local function setfires(x,y,z, rad)
    for i, v in ipairs(TheSim:FindEntities(x, 0, z, rad, nil, { "laser", "DECOR", "INLIMBO" })) do 
        if v.components.burnable then
            v.components.burnable:Ignite()
        end
    end
end

local function applydamagetoent(inst,ent, targets, rad, hit)
    local x, y, z = inst.Transform:GetWorldPosition()
    if hit then 
        targets = {}
    end    
    if not rad then 
        rad = 0
    end
    local v = ent
    if not targets[v] and v:IsValid() and not v:IsInLimbo() and not (v.components.health ~= nil and v.components.health:IsDead()) and not v:HasTag("laser_immune") then            
        local vradius = 0
        if v.Physics then
            vradius = v.Physics:GetRadius()
        end

        local range = rad + vradius
        if hit or v:GetDistanceSqToPoint(Vector3(x, y, z)) < range * range then
            local isworkable = false
            if v.components.workable ~= nil then
                local work_action = v.components.workable:GetWorkAction()
                --V2C: nil action for campfires
                isworkable =
                    (   work_action == nil and v:HasTag("campfire")    ) or
                    
                        (   work_action == ACTIONS.CHOP or
                            work_action == ACTIONS.HAMMER or
                            work_action == ACTIONS.MINE or   
                            work_action == ACTIONS.DIG 
                            --work_action == ACTIONS.BLANK  --这个动作没有
                        )
            end
            if isworkable then
                targets[v] = true
                v:DoTaskInTime(0.6, function() 
                    if v.components.workable then
                        v.components.workable:Destroy(inst) 
                        local vx,vy,vz = v.Transform:GetWorldPosition()
                        v:DoTaskInTime(0.3, function() setfires(vx,vy,vz,1) end)
                    end
                 end)
                if v:IsValid() and v:HasTag("stump") then
                   -- v:Remove()
                end
            elseif v.components.pickable ~= nil
                and v.components.pickable:CanBePicked()
                and not v:HasTag("intense") then
                targets[v] = true
                local num = v.components.pickable.numtoharvest or 1
                local product = v.components.pickable.product
                local x1, y1, z1 = v.Transform:GetWorldPosition()
                v.components.pickable:Pick(inst) -- only calling this to trigger callbacks on the object
                if product ~= nil and num > 0 then
                    for i = 1, num do
                        local loot = SpawnPrefab(product)
                        loot.Transform:SetPosition(x1, 0, z1)
                        targets[loot] = true
                    end
                end

            elseif v.components.health then            
                inst.components.combat:DoAttack(v)                                    
                if v:IsValid() then
                    if not v.components.health or not v.components.health:IsDead() then
                        if v.components.freezable ~= nil then
                            if v.components.freezable:IsFrozen() then
                                v.components.freezable:Unfreeze()
                            elseif v.components.freezable.coldness > 0 then
                                v.components.freezable:AddColdness(-2)
                            end
                        end
                        if v.components.temperature ~= nil then
                            local maxtemp = math.min(v.components.temperature:GetMax(), 10)
                            local curtemp = v.components.temperature:GetCurrent()
                            if maxtemp > curtemp then
                                v.components.temperature:DoDelta(math.min(10, maxtemp - curtemp))
                            end
                        end
                    end
                end                   
            end
            if v:IsValid() and v.AnimState then
                SpawnPrefab("laserhit"):SetTarget(v) --新的预设物
            end
        end
    end 
    return targets   
end

local function DoDamage(inst, rad, startang, endang, spawnburns)
    local targets = {}
    local x, y, z = inst.Transform:GetWorldPosition()
    local angle = nil
    if startang and endang then
        startang = startang + 90
        endang = endang + 90
        
        local down = TheCamera:GetDownVec()             
        angle = math.atan2(down.z, down.x)/DEGREES
    end

    setfires(x,y,z, rad)
    for i, v in ipairs(TheSim:FindEntities(x, 0, z, rad, nil, { "laser", "DECOR", "INLIMBO" })) do
        local dodamage = true
        if startang and endang then
            local dir = inst:GetAngleToPoint(Vector3(v.Transform:GetWorldPosition())) 

            local dif = angle - dir         
            while dif > 450 do
                dif = dif - 360 
            end
            while dif < 90 do
                dif = dif + 360
            end                       
            if dif < startang or dif > endang then                
                dodamage = nil
            end
        end
        if dodamage then
            targets = applydamagetoent(inst,v, targets, rad)
        end
    end
end

local function onnearmine(inst, ents)    
    local detonate = false
    for i,ent in ipairs(ents)do
        if not ent:HasTag("ancient_hulk") then
            detonate = true
            break
        end
    end
    if inst.primed and detonate then
        inst.SetLightValue(inst, 0,0.75,0.2 )
        inst.AnimState:PlayAnimation("red_loop", true)
        --start beep
        -- inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/active_LP","boom_loop")
        -- inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro")
        inst:DoTaskInTime(0.8,function() 
            --explode, end beep
        -- inst.SoundEmitter:KillSound("boom_loop")
            --local player = GetClosestInstWithTag("player", inst, SHAKE_DIST)
            --if player then
                --player.components.playercontroller:ShakeCamera(inst, "VERTICAL", 0.5, 0.03, 2, SHAKE_DIST)
				--player:ShakeCamera(CAMERASHAKE.FULL, 0.5, 0.03, 2, 40)
				ShakeAllCameras(CAMERASHAKE.FULL, 0.5, 0.03, 2, inst, 40)
            --end
            inst:Hide()
            local ring = SpawnPrefab("laser_ring") --新的预设物
            ring.Transform:SetPosition(inst.Transform:GetWorldPosition())
            inst:DoTaskInTime(0.3,function() DoDamage(inst, 3.5) inst:Remove() end)    
            
            local explosion = SpawnPrefab("laser_explosion") --新的预设物
            explosion.Transform:SetPosition(inst.Transform:GetWorldPosition())
            -- inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/smash_3")                          
        end)
    end
end

AddPrefabPostInit("ancient_hulk_mine", function(inst)
	inst:AddComponent("creatureprox")
    inst.components.creatureprox.period = 0.01
    inst.components.creatureprox:SetDist(3.5,5) 
    inst.components.creatureprox:SetOnPlayerNear(onnearmine)
end)
-----------------------