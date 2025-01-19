local er_monster_brain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

function er_monster_brain:OnStart()
	local root = PriorityNode({
		ChaseAndAttack(self.inst, 15),
		Wander(self.inst,function()
			return self.inst:GetPosition()
		end,20),
	}, 0.25)
	self.bt = BT(self.inst, root)
end

return er_monster_brain