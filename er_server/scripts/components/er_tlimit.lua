local function onstarttime(self, starttime)
	if starttime ~= nil then
		local num = self.addtime - (os.time() - starttime)
		local dotime = num > 0 and num or 1
		self:RemoveItem(dotime)

		local armor = self.inst.components.armor
		if armor then
			armor:InitIndestructible(self.inst.defensive or 0.6)
		end
	end
end

local Er_TLimit = Class(function(self, inst)
	self.inst = inst
	self.addtime = nil		--增加时间
	self.alltime = nil		--总时间
	self.starttime = nil	--起始时间
end,
nil, {
	starttime = onstarttime,
})

function Er_TLimit:GetTime()
	return self.starttime
end

function Er_TLimit:SetTime(second,minute,hour,day)
	local second = math.min(60,second or 0)
	local minute = math.min(60,minute or 0)
	local hour = math.min(24,hour or 0)
	self.addtime = second + minute*60 + hour*3600 + day*86400
	self.alltime = os.time() + self.addtime
	self.starttime = os.time()
end

--移除物品
function Er_TLimit:RemoveItem(dotime) 
	self.inst:DoTaskInTime(dotime,function()
		self.inst:Remove()
	end)
end

function Er_TLimit:OnSave()
	return {
		loadaddtime = self.addtime,
		loadalltime = self.alltime,
		loadstarttime = self.starttime,
	}
end

function Er_TLimit:OnLoad(data)
	if data ~= nil then
		self.addtime = data.loadaddtime
		self.alltime = data.loadalltime
		self.starttime = data.loadstarttime
	end
end

return Er_TLimit