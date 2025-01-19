local function onCurrent(self, current)
	if self.inst.replica.lr_magic then
		self.inst.replica.lr_magic.current:set(current)
	end
end

local function onMax(self, max)
	if self.inst.replica.lr_magic then
		self.inst.replica.lr_magic.max:set(max)
	end
end

local Lr_Magic = Class(function(self, inst)
	self.inst = inst
	self.current = 100
	self.max = 100
	self.rate = 0 
	self.inst:StartUpdatingComponent(self)
end,
nil, {
	current = onCurrent,
	max = onMax
})

function Lr_Magic:GetMax()
	return self.max
end

function Lr_Magic:SetMax(amount)
	self.max = amount
	self.current = amount
end

function Lr_Magic:GetPercent()
	return self.current / self.max
end

function Lr_Magic:SetPercent(percent)
	self.current = math.clamp(percent * self.max, 0, self.max)
end

function Lr_Magic:SetCurrent(current)
	self.current = current
end

function Lr_Magic:GetCurrent()
	return self.current
end

function Lr_Magic:DoDelta(value)
	self.current = math.clamp(self.current + value, 0, self.max)
end

function Lr_Magic:OnSave()
	return {
		loadcurrent = self.current,
	}
end

function Lr_Magic:OnLoad(data)
	if data ~= nil then
		self.current = data.loadcurrent
    end
end

function Lr_Magic:OnUpdate(dt)
    if not self.inst:HasTag("playerghost") then
        self:DoDelta(self.rate * dt)
    end
end

return Lr_Magic