local Cultivation = Class(function(self, inst)
    self.inst = inst
    self.product = nil		--作物名
    self.growtime = nil		--生长时间
end)

--设定作物名
function Cultivation:SetProduct(product)
    self.product = product
end

--获取作物名
function Cultivation:GetProduct()
    return self.product
end

--设定生长时间
function Cultivation:SetGrowTime(growtime)
    self.growtime = growtime
end

--获取生长时间
function Cultivation:GetGrowTime()
    return self.growtime
end

--栽种
function Cultivation:Planting(seed,soil,player)
    seed.components.stackable:Get(1):Remove()
	soil.hasplant = true
	soil:AddTag("isplant")
	soil.SoundEmitter:PlaySound("dontstarve/common/plant")
	soil.AnimState:PlayAnimation("planted")
	soil:DoTaskInTime(1, function()
		local cultivation = seed.components.cultivation
		local growtime = cultivation:GetGrowTime()
		if player.fastgrowth then
			growtime = growtime * 0.8
		end
		--生成植株
		local plant = SpawnPrefab("er_newplants")
		plant.build = seed.build
		plant.AnimState:SetBuild(plant.build)
		plant.Transform:SetPosition(soil.Transform:GetWorldPosition())
		plant.components.morecrop:StartGrowing(cultivation:GetProduct(), growtime, 0)
	end)
end

function Cultivation:OnSave()
    return {
        product = self.product,
        growtime = self.growtime,
    }
end

function Cultivation:OnLoad(data)
    if data ~= nil then
        self.product = data.product
		self.growtime = data.growtime
    end
end

return Cultivation