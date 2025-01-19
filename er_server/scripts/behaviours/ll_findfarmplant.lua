--ByLaolu 2021-01-05
local SEE_DIST = 4		-- 照看的距离:8-20
local genericfollowposfn = function(inst) return inst:GetPosition() end--通用的跟随位置,返回 inst的位置
--农作物查找与对话行为节点定义:
LL_FindFarmPlant = Class(BehaviourNode, function(self, inst, action, wantsstressed, getfollowposfn, seedist)
    BehaviourNode._ctor(self, "LL_FindFarmPlant")				--行为指针
    self.inst = inst
    self.wantsstressed = wantsstressed or false
    self.action = action										--AI行为推送
    self.getfollowposfn = getfollowposfn or genericfollowposfn	--获取跟随者位置
	self.seedist = seedist or 10
    -- self.validplantfn = validplantfn or nil 					--有效的种植功能检查
end)
--计算种植者和种植物的距离角度
local function IsNearFollowPos(self, plant)
    local followpos = self.getfollowposfn(self.inst)
    local plantpos = plant:GetPosition()
    return distsq(followpos.x, followpos.z, plantpos.x, plantpos.z) < self.seedist * self.seedist --SEE_DIST * SEE_DIST
end
--Laolu的调试
function LL_FindFarmPlant:DBString()
    return string.format("到农作物: %s", tostring(self.inst.planttarget))
end
	
--行为访问定义:--主逻辑结构:查找农作物
function LL_FindFarmPlant:Visit()
--准备状态
    if self.status == READY then
        self:PickTarget()
        if self.inst.planttarget then
			--做个行为缓冲器推送出去
			local action = BufferedAction(self.inst, self.inst.planttarget, self.action, nil, nil, nil, 0.1)
			self.inst.components.locomotor:PushAction(action, self.shouldrun)
			-- print("运行状态")
			self.status = RUNNING
		else
			-- print("失败状态")
			self.status = FAILED
			
        end
    end
--运行状态    
    if self.status == RUNNING then
        local plant = self.inst.planttarget
		-- print(string.format("到农作物: %s", tostring(self.inst.planttarget)))
        if not plant or not plant:IsValid() or not IsNearFollowPos(self, plant) 
		or not (plant.components.growable == nil or plant.components.growable:GetCurrentStageData().tendable) 
		then
            self.inst.planttarget = nil
			-- print("失败状态")
            self.status = FAILED
        --kick掉官方的苦逼逻辑
        -- elseif plant.components.farmplantstress.stressors.happiness ~= self.wantsstressed then
		elseif plant ~=nil and plant.components.farmplanttendable ~= nil and plant.components.farmplanttendable.tendable ==true then--杂草不对话
            self.inst.planttarget = nil
			-- print("成功状态")
            self.status = SUCCESS
        end
    end
end

local FARMPLANT_MUSTTAGS = { "farmplantstress" }
local FARMPLANT_NOTAGS = { "farm_plant_killjoy" }
function LL_FindFarmPlant:PickTarget()--拾取兴趣检查
    self.inst.planttarget = FindEntity(self.inst, self.seedist, function(plant)
        if IsNearFollowPos(self, plant)
         and (plant.components.growable == nil or plant.components.growable:GetCurrentStageData().tendable) then
            return plant.components.farmplantstress and plant.components.farmplantstress.stressors.happiness == self.wantsstressed
        end
    end, FARMPLANT_MUSTTAGS, FARMPLANT_NOTAGS)
end
