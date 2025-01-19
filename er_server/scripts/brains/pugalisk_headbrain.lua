require "behaviours/chaseandattack"
require "behaviours/standstill"
local pu = require ("prefabs/pugalisk_util")

local Pugalisk_headBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function doGazeTest(inst)

    if inst.components.combat.target and not inst:HasTag("tail") and inst:GetDistanceSqToInst(inst.components.combat.target) > 5*5 and not inst.sg:HasStateTag("busy") then
        inst:PushEvent("dogaze")
    end
    return true
end
--判定目标距离
local function PressDisFn(inst)
	if inst.components.combat.target and not inst:HasTag("tail") and inst:GetDistanceSqToInst(inst.components.combat.target) > 6*6 and not inst.sg:HasStateTag("busy") then
        inst.wantstogaze = true
    end
	inst.wantstogaze = false
end
local function customLocomotionTest(inst)    
    if not inst.movecommited then--大蛇不移动时,判定要执行的行为
        pu.DetermineAction(inst)    --选择执行的行为    
    end
    if inst.movecommited then
        return false
    end
    return true
end

function Pugalisk_headBrain:OnStart()
    local root =
        PriorityNode(
        {  
            WhileNode(function() return customLocomotionTest(self.inst) and not self.inst.sg:HasStateTag("underground") end, "Be a head", 
                PriorityNode{
                    ChaseAndAttack(self.inst),         
                    StandStill(self.inst),
					-- ActionNode(function() doGazeTest(self.inst) end),
                }),
			-- WhileNode(function() return customLocomotionTest(self.inst) and not self.inst.sg:HasStateTag("underground") end, "Be a head", 
                -- PriorityNode{
					-- IfNode(function() return PressDisFn(self.inst) end, "Snake JNGongJi",
						-- PriorityNode{
							-- ActionNode(function() self.inst:PushEvent("dogaze") end),
						-- }),
                    -- ChaseAndAttack(self.inst,5),         
                    -- StandStill(self.inst),
                -- }),
        },1)
    
    self.bt = BT(self.inst, root)        
end

function Pugalisk_headBrain:OnInitializationComplete()
    --[[
    local home = SpawnPrefab("rocks")
    home.Transform:SetPosition(  self.inst.Transform:GetWorldPosition() )
    self.inst.home = home
    ]]
end

return Pugalisk_headBrain
