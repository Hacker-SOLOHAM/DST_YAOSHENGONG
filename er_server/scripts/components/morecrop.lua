local MoreCrop = Class(function(self, inst)
    self.inst = inst
    self.prefabname = nil		--产品预制
    self.growthpercent = 0		--生长百分比
    self.rate = 0				--生长系数
end)

--设定作物产物
function MoreCrop:SetProduct(prefabname)
	self.prefabname = prefabname
end

--获取作物产物
function MoreCrop:GetProduct()
	return self.prefabname
end

--设定生长百分比
function MoreCrop:SetPercent(amount)
	self.growthpercent = amount
end

--获取生长百分比
function MoreCrop:GetPercent()
	return self.growthpercent
end

--生长更新
function MoreCrop:UpdateGrow()
	if self.task then
		self.task:Cancel()
		self.task = nil
	end
	self.task = self.inst:DoPeriodicTask(1, function()
		local newgrowthpercent = self.growthpercent + self.rate
		--增加生长百分比
		self.growthpercent = math.min(1, newgrowthpercent)
		self.inst:PushEvent("startgrowing")
		if self.growthpercent >= 1 then
			self.inst:AddTag("mature")
		end
	end)
end

--开始生长
function MoreCrop:StartGrowing(prefabname, grow_time, growthpercent)
	self.prefabname = prefabname
	self.rate = 1 / grow_time
	self.growthpercent = growthpercent
    self:UpdateGrow()
end

local cantup = {
	["er_flower_fruit061"] = true,
	["er_flower_fruit062"] = true,
	["er_flower_fruit063"] = true
}

--采集方法
function MoreCrop:Collection(player)
	local product = SpawnPrefab(self.prefabname)
	if product ~= nil and player ~= nil then
		local stacksize = 1
		if math.random() < 0.3 and player.harvestup then
			stacksize = 2
		end
		if cantup[self.prefabname] then	--取消指定作物的双倍
			stacksize = 1
		end
		player.components.er_leave:DoPromote(100)	--采摘获得100经验
		product.components.stackable:SetStackSize(stacksize)
		player.components.inventory:GiveItem(product)
		--移除作物
		self.inst:Remove()
		local x,y,z = self.inst.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x, y, z, 1, {"er_soil"})
		for k,v in pairs(ents) do
			--培养土/花盆恢复
			v.AnimState:PlayAnimation("planting")
			v.hasplant = false
			v:RemoveTag("isplant")
		end
		--植物播放收获动画
		self.inst.AnimState:PlayAnimation("er_crop_harvest")
		self.inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_lightbulb")
		self.inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_reeds")
    end
end

function MoreCrop:OnSave()
    return {
        prefabname = self.prefabname,
        growthpercent = self.growthpercent,
        rate = self.rate,
    }
end

function MoreCrop:OnLoad(data)
    if data ~= nil then
        self.prefabname = data.prefabname
		self.growthpercent = data.growthpercent
		if data.rate ~=nil then self.rate = data.rate end
    end
end

return MoreCrop