local Rg_BuffAffect = Class(function(self, inst)
    self.inst = inst
    self.target = nil
	
    self.onstartfn = nil
    self.ondeathfn = nil

end)

function Rg_BuffAffect:SetStartFn(fn)
    self.onstartfn = fn
end

function Rg_BuffAffect:SetDeathFn(fn)
    self.ondeathfn = fn
end

function Rg_BuffAffect:OnStart(target)
    self.target = target
    if self.onstartfn ~= nil then
        self.onstartfn(self.inst, target)
    end
end

function Rg_BuffAffect:OnDeath()
    local target = self.target
    self.name = nil
    self.target = nil
    if self.ondeathfn ~= nil then
        self.ondeathfn(self.inst, target)
    else
		self.inst:Remove()
	end
end

return Rg_BuffAffect
