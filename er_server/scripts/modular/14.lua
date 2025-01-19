local	_G = GLOBAL
local t = {
	 ["cbdz0"] = -0.5,
	 ["cbdz1"] = -0.5,
	 ["cbdz2"] = -0.5,
	 ["cbdz3"] = -0.5,
	 ["cbdz4"] = -0.5,
	 ["cbdz5"] = -0.5,
	 ["cbdz6"] = -0.5,
	 ["cbdz7"] = -0.5,
	 ["cbdz8"] = -0.5,
	 ["cbdz9"] = -0.5,
	 ["cbdz10"] = -0.5,
	 ["ly_bobbag"] = 0,
	 ["ly_hehebag"] = -0,
	 ["ly_pandabag"] = -0,
	 ["ly_wingbag"] = -0,
	 
	 -- ["乐园 ● 恶魔之翼"] = -0.5,
	 -- ["乐园 ● 信仰之翼"] = -0.5,
	 -- ["乐园 ● 炎热之火之翼"] = -0.5,
	 -- ["乐园 ● 电光飞驰之翼"] = -0.5,
	 -- ["乐园 ● 湛蓝天空"] = -0.5,
	 -- ["乐园 ● 炎魔之翼"] = -0.5,
	 -- ["乐园 ● 魅惑之光之翼"] = -0.5,
	 -- ["乐园 ● 阿波罗之翼"] = -0.5,
	 -- ["乐园 ● 紫蝶之翼"] = -0.5,
--	["piggyback"] = 10,			--正数腐烂
--	["krampus_sack"] = -10,		--负数返鲜
--	["backpack"] = 0,			--0保鲜
--	["backpack"] = 0,			--0保鲜
}
local Update = nil
local function Update_fn(inst, dt)
	if Update ~= nil then
		if not inst.components.equippable then
			local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner or nil
			if not owner and inst.components.occupier then
				owner = inst.components.occupier:GetOwner()
			end
			if owner ~= nil and owner.components.container and owner.components.container.GetFuBai then
				dt = owner.components.container.GetFuBai(owner, inst, dt) or dt
			end
		end
		return Update(inst, dt)
	end
end
AddComponentPostInit("perishable", function(Perishable)
	if Update == nil then
		local fn = Perishable.StartPerishing
		for i=1, 10 do
			local key, val = _G.debug.getupvalue(fn, i)
			if key == "Update" then
				Update = val
				break
			elseif not val then
				break
			end
		end
	end
	if Update ~= nil then
		function Perishable:StartPerishing()
			if self.updatetask ~= nil then
				self.updatetask:Cancel()
				self.updatetask = nil
			end

			local dt = 10 + math.random()*FRAMES*8
			self.updatetask = self.inst:DoPeriodicTask(dt, Update_fn, math.random()*2, dt)
		end
	end
end)
for k,v in pairs(t) do
	AddPrefabPostInit(k, function(inst)
		if inst.components.container then
			inst.components.container.GetFuBai = function(owner, inst, dt)
				if dt then
					return dt * t[k]
				end
			end
		end
	end)
end