--所属模块:十格
--重写
--ByLaoluFix 2021-07-14
--修复无端保护声明,造成非玩家无法佩戴装备
--修复 scripts/components/inventoryitem_replica.lua:183 in (method) SetPickupPos (Lua) <177-185> ..'classified' (a nil value) 的错误
local IsServer = TheNet:GetIsServer() or TheNet:IsDedicated()

AddComponentPostInit("resurrectable", function(self, inst)
    local original_FindClosestResurrector = self.FindClosestResurrector
    local original_CanResurrect = self.CanResurrect
    local original_DoResurrect = self.DoResurrect

    self.FindClosestResurrector = function(self)
        if IsServer and self.inst.components.inventory then
            local item = self.inst.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.NECK)
            if item and item.prefab == "amulet" then
                return item
            end
        end
        original_FindClosestResurrector(self)
    end

    self.CanResurrect = function(self)
        if IsServer and self.inst.components.inventory then
            local item = self.inst.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.NECK)
            if item and item.prefab == "amulet" then
                return true
            end
        end
        original_CanResurrect(self)
    end

    self.DoResurrect = function(self)
        self.inst:PushEvent("resurrect")
        if IsServer and self.inst.components.inventory then
            local item = self.inst.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.NECK)
            if item and item.prefab == "amulet" then
                self.inst.sg:GoToState("amulet_rebirth")
                return true
            end
        end
        original_DoResurrect(self)
    end
end)

--变更制造可参与位置
AddComponentPostInit("inventory", function(self, inst)
	if self.inst:HasTag("player") and not self.inst:HasTag("laoluselfbaby") then
		local original_Equip = self.Equip
		self.Equip = function(self, item, old_to_active)
			if original_Equip(self, item, old_to_active) and item and item.components and item.components.equippable then
				local eslot = item.components.equippable.equipslot
				if self.equipslots[eslot] ~= item then
					if eslot == GLOBAL.EQUIPSLOTS.BACK and item.components.container ~= nil then
						self.inst:PushEvent("setoverflow", { overflow = item })
					end
				end
				return true
			else
				return
			end
		end
		self.GetOverflowContainer = function()
			if self.ignoreoverflow then
				return
			end
			local item = self:GetEquippedItem(GLOBAL.EQUIPSLOTS.BACK)
			return item ~= nil and item.components.container or nil
		end
	end
end)

AddPrefabPostInit("inventory_classified", function(inst)
    function GetOverflowContainer(inst)
        local item = inst.GetEquippedItem(inst, GLOBAL.EQUIPSLOTS.BACK)
        return item ~= nil and item.replica.container or nil
    end

    function Count(item)
        return item.replica.stackable ~= nil and item.replica.stackable:StackSize() or 1
    end

    function Has(inst, prefab, amount)
        local count =
            inst._activeitem ~= nil and
            inst._activeitem.prefab == prefab and
            Count(inst._activeitem) or 0

        if inst._itemspreview ~= nil then
            for i, v in ipairs(inst._items) do
                local item = inst._itemspreview[i]
                if item ~= nil and item.prefab == prefab then
                    count = count + Count(item)
                end
            end
        else
            for i, v in ipairs(inst._items) do
                local item = v:value()
                if item ~= nil and item ~= inst._activeitem and item.prefab == prefab then
                    count = count + Count(item)
                end
            end
        end

        local overflow = GetOverflowContainer(inst)
        if overflow ~= nil then
            local overflowhas, overflowcount = overflow:Has(prefab, amount)
            count = count + overflowcount
        end

        return count >= amount, count
    end
    if not IsServer then
        inst.GetOverflowContainer = GetOverflowContainer
        inst.Has = Has
    end
end)

AddStategraphPostInit("wilson", function(sg)
	--未知功能1
	sg.states["death"].onexit = nil					--死亡处理
	--未知功能2
	local interval = 1
	sg.states["emote"].onupdate = function(inst)	--表情处理
		if inst.plantsinger then
			if interval == 333 then						--33约为1秒
				interval = 1							--重置
				local x,y,z = inst.Transform:GetWorldPosition()
				local ents = TheSim:FindEntities(x, y, z, 10, {"er_newplants"})
				for k,v in pairs(ents) do
					local morecrop = v.components.morecrop
					local growthpercent = morecrop:GetPercent()
					morecrop:SetPercent(growthpercent + morecrop.rate/10)
				end
			else
				interval = interval + 1
			end
		end
	end
	--未知功能2
	local old_onattacked = sg.events['attacked'].fn		--人物无视硬直
    sg.events['attacked'] = EventHandler('attacked', function(inst,data,...)
		local hitrank = inst.hitrank or 0
        if math.random() < hitrank then
            if not inst.sg:HasStateTag("frozen") and not inst.sg:HasStateTag("sleeping") then
                return
            end
        end     
        return old_onattacked(inst,data,...)
    end)
	
    for key,value in pairs(sg.states) do
        if value.name == 'amulet_rebirth' then
            local original_amulet_rebirth_onexit = sg.states[key].onexit
            sg.states[key].onexit = function(inst)
                local item = inst.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.NECK)
                if item and item.prefab == "amulet" then
                    item = inst.components.inventory:RemoveItem(item)
                    if item then
                        item:Remove()
                        item.persists = false
                    end
                end
                original_amulet_rebirth_onexit(inst)
            end
        end
    end
end)

--变更背包装备栏
local bag_list = {"icepack","piggyback","backpack","krampus_sack","spicepack","candybag"}
for i,v in ipairs(bag_list) do
	AddPrefabPostInit(v,function(inst)
		inst.components.equippable.equipslot = EQUIPSLOTS.BACK
	end)
end

--变更护符装备栏
local amulet_list = {"yellowamulet","purpleamulet","orangeamulet","greenamulet","amulet","blueamulet"}
for i,v in ipairs(amulet_list) do
	AddPrefabPostInit(v,function(inst)
		inst.components.equippable.equipslot = EQUIPSLOTS.NECK
	end)
end