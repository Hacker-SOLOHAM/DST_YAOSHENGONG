--回收容器组件结构体:
--ByLaolu 2021-06-21
local Lf_hs = Class(function(self, inst)
    self.inst = inst
    self.chester = nil
	self.inst:DoTaskInTime(2, function()
		self:Spawn()
	end)
end)
local function SetChester(self, chester)
	self.chester = chester
	self.inst.hs_chester = chester
	chester.persists = false
	chester.Transform:SetPosition(0,0,0) 
	chester.entity:SetParent(self.inst.entity)
end

function Lf_hs:Spawn()
	if self.chester == nil then
		local chester = SpawnPrefab("lf_hs_container")--lf_hs_container--er_workshop005
        SetChester(self, chester)
	end
end

function Lf_hs:OnSave()
	-- if self.chester ~= nil then
		-- return { pack = self.chester:GetSaveRecord() }
	-- end
end

function Lf_hs:OnLoad(data)
    -- if data ~= nil and data.pack ~= nil then
		-- local chester = SpawnSaveRecord(data.pack)
		-- self.inst:DoTaskInTime(2, function()
			-- SetChester(self, chester)
		-- end)
	-- end
end

return Lf_hs
