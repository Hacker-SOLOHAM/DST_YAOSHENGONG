local SEE_PLAYER_DIST = 5
local SEE_FOOD_DIST = 10
local MAX_WANDER_DIST = 15
local MAX_CHASE_TIME = 20		--最大追击时间
local MAX_CHASE_DIST = 25		--最大追击距离
local RUN_AWAY_DIST = 6			--逃跑的距离
local STOP_RUN_AWAY_DIST = 8	--停止逃跑的距离

local er_boss_brain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

function er_boss_brain:OnStart()
	local root = PriorityNode({
		WhileNode(function()
			return self.inst.components.combat.target == nil or not self.inst.components.combat:InCooldown()
		end,"AttackMomentarily", ChaseAndAttack(self.inst, MAX_CHASE_TIME)),
		WhileNode(function()
			return self.inst.components.combat.target and self.inst.components.combat:InCooldown()
		end,"Dodge",
		RunAway(self.inst, function()
			return self.inst.components.combat.target
		end, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST)),
		--徘徊
		Wander(self.inst),
	}, .5)
	self.bt = BT(self.inst, root)
end

return er_boss_brain