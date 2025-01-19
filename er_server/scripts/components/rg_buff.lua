
local Rg_Buff = Class(function(self, inst)
    self.inst = inst
    self.enable = true
    self.followsymbol = ""
    self.followoffset = Vector3(0, 0, 0)
    self.debuffs = {}
	
    inst:ListenForEvent("death", function()
        self:RemoveAllDebuff()
    end)
end)

 
function Rg_Buff:SetFollowSymbol() 

	if next(self.debuffs) == nil then
		return
	end

	local num = 0
    for k, v in pairs(self.debuffs) do
		if k then
			num = num +1
		end
	end
	local jg =  -50 * (num-1)
	local aa =0
    for k, v in pairs(self.debuffs) do
		if v.inst and v.inst.Follower then
			v.inst.Follower:FollowSymbol(self.inst.GUID, "headbase", jg, -220, 0)
			jg = jg + 100
		end
    end
end

function Rg_Buff:HasDeBuff(name)
    return self.debuffs[name] ~= nil
end

local function RegisterDebuff(self, name, ent,time) 
	self.debuffs[name] =
	{
        inst = ent,
        onremove = function() self.debuffs[name] = nil end,
    }
    self.inst:ListenForEvent("onremove", self.debuffs[name].onremove, ent)
    ent.persists = false
	ent._rgtask = self.inst:DoTaskInTime(time, function() 
		self:RemoveDebuff(name)
	end)		
	ent.entity:SetParent(self.inst.entity)
    if ent.components.rg_buffaffect ~= nil then
        ent.components.rg_buffaffect:OnStart(self.inst)
    end
	self:SetFollowSymbol()
end

function Rg_Buff:AddDebuff(name,time) --添加buff buff名字 持续时间
    if self.enable then
		if self.debuffs[name] == nil then
			local ent = SpawnPrefab(name)
			if ent ~= nil then
				RegisterDebuff(self, name, ent, time) --第一次
			end
		else
            if self.debuffs[name].inst._rgtask then
                self.debuffs[name].inst._rgtask:Cancel()
                self.debuffs[name].inst._rgtask = nil
            end
			self.debuffs[name].inst._rgtask = self.inst:DoTaskInTime(time, function() 
				self:RemoveDebuff(name)
			end)
		end
    end
end

function Rg_Buff:RemoveAllDebuff()
    local k = next(self.debuffs)
    while k ~= nil do
        self:RemoveDebuff(k)
        k = next(self.debuffs)
    end
end

function Rg_Buff:RemoveDebuff(name)
    local debuff = self.debuffs[name]
    if debuff ~= nil then
        self.debuffs[name] = nil
        self.inst:RemoveEventCallback("onremove", debuff.onremove, debuff.inst)
        if debuff.inst.components.rg_buffaffect ~= nil then
            debuff.inst.components.rg_buffaffect:OnDeath()
        else
            debuff.inst:Remove()
        end
		if next(self.debuffs) ~= nil then
			self:SetFollowSymbol()
		end
    end
end

return Rg_Buff
