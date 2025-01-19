local Aoe_Projectile = Class(function(self, inst)
    self.inst = inst
    self.owner = nil    
    self.dest = nil
    self.speed = nil
    self.hitdist = 1.2  
    self.onhit = nil
    self.onmiss = nil
end)

function Aoe_Projectile:SetSpeed(speed) 
    self.speed = speed
end

function Aoe_Projectile:SetRange(range) 
    self.range = range
end

function Aoe_Projectile:SetHitDist(dist) 
    self.hitdist = dist
end

function Aoe_Projectile:SetOnHitFn(fn)  
    self.onhit = fn
end

function Aoe_Projectile:SetOnMissFn(fn)  
    self.onmiss = fn
end

function Aoe_Projectile:Throw(owner, dest)
    self.owner = owner
    self.dest = dest 
    self.inst.Transform:SetRotation(dest)
    self.inst.Physics:SetMotorVel(self.speed,0,0)
    self.inst:StartUpdatingComponent(self) 
end

function Aoe_Projectile:Miss()
    self:Stop()
    if self.onmiss then
        self.onmiss(self.inst)
    end
end

function Aoe_Projectile:Stop()
    self.inst:StopUpdatingComponent(self)
    self.owner = nil
end

function Aoe_Projectile:Hit(target)
	local attacker = self.owner
    self:Stop()
    self.inst.Physics:Stop()
	
	--计算伤害
	
	local damage = 50
	if attacker.components.rg_guaiwu ~= nil then
		damage = damage + math.ceil(attacker.components.rg_guaiwu.level/100)
	end
	if target.components.combat then
		target.components.combat:GetAttacked(attacker or self.inst, damage)
	end
    if self.onhit then
        self.onhit(self.inst, attacker, target)
    end
end

function Aoe_Projectile:OnUpdate(dt)
	local x,y,z =  self.inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x,0,z, self.hitdist,{"_combat","_health"},{"INLIMBO","playerghost","rg_guaiwu"})

	for i,v in pairs(ents) do
		if v and v:IsValid() and self.inst:IsValid() and self.inst:IsNear(v, self.hitdist + (v.Physics and v.Physics:GetRadius() or 0)) and v ~= self.owner 
			and v.components.health ~=nil and v.components.combat ~=nil  and not v.components.health:IsDead() then
			self:Hit(v)
		end
	end  
end

return Aoe_Projectile
