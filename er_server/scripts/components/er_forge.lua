local uplist = {
	{0.3,0.4,0.5,0.6},	--品阶系数
	{1,2,3,4},			--品阶系数附加
	{20,40,60,80}	--品阶提升
}

--区间获取随机数
local function getRnum(array)
	return math.random(array[1],array[2])
end

--开始锻造
local function doForge(self)
	if self.forgeitem ~= "nothing" then
		self.inst:DoTaskInTime(self.forgetime, function()
			local item = SpawnPrefab(self.forgeitem)
			local pin = self.forgeids[2]			--品阶为图纸品质
			if pin == 4 then
				TheNet:Announce("灵光绽放,"..STRINGS.NAMES[string.upper(item.prefab)].."(橙)诞生于世!")
			end

			--武器组件相关设定
			local weapon = item.components.weapon
			local dmg1 = getRnum(self.forgeids[3])		--矿石提升
			local dmg2 = getRnum(self.forgeids[1])		--铸模提升
			local dmg3 = uplist[3][pin]					--图纸品质提升
			weapon.damage = dmg1 + dmg2 + dmg3			--累加攻击力
			item.damage = weapon.damage					--设定基础攻击力

			--品阶相关设定
			local rgwuqi = item.components.rgwuqi
			rgwuqi.pin = pin
			rgwuqi.dmgrank = uplist[1][pin] + 0.1*GetRandomNum(uplist[2][pin])
			for i=1,self.forgeids[4] do
				table.insert(rgwuqi.slotli,"")	--武器代数对应的孔位数
			end
			rgwuqi:UpdateDamage()

			self.inst.components.container:GiveItem(item)
			self.forgeitem = "nothing"
			if self.inst.fire then
				self.inst.fire:Remove()
			end
			--锻造后,容器可以再次被打开
			if self.inst.components.container then
				self.inst.components.container.canbeopened = true 		--设置容器可以被打开
			end
		end)
		local x,y,z = self.inst.Transform:GetWorldPosition()
		local fire = SpawnPrefab("campfirefire")
		fire.components.firefx:SetLevel(3)
		fire.Transform:SetPosition(x,y+1.6,z)
		self.inst.fire = fire
		--ByLaoluFix 修复在锻造时,禁止打开容器
		if self.inst.components.container then
			self.inst.components.container.canbeopened = false 		--设置容器不可以被打开
		end
	end
end

local Er_Forge = Class(function(self, inst)
    self.inst = inst
	self.forgeitem = "nothing"	--锻造物品
	self.forgetime = 0			--锻造时间
	self.forgeids = {}			--锻造id表
end,
nil,
{
	forgetime = doForge,
})

--获取锻造产物(核心/图纸/矿石)
local function GetForgeItem(data,container)
	local typenum = "weapon"..math.random(1,7)						--获取武器类型
	local typeid = GetRandomNum(data[3][1].forgeid)							--获取武器Id
	local forgeitem = typenum..string.format("%02d", typeid)	--拼接武器名
	local idlist = {}
	idlist[1] = data[1][1].upnum		--铸模提升区间
	idlist[2] = data[2][1].forgeid		--图纸品质上限
	idlist[3] = data[3][1].section		--矿石提升区间
	idlist[4] = typeid					--武器代数
	for i=1,3 do
		container:ConsumeByName(data[i][1].prefab,1)			--消耗一份材料
	end
	return forgeitem,idlist
end

--锻造方法
function Er_Forge:StartForge()
	local container = self.inst.components.container
	local data = {}
	for i=1, 3 do
		local item = container:GetItemInSlot(i)
		if item ~= nil then
			local stackable = item.components.stackable
			local num = stackable and stackable:StackSize() or 1
			table.insert(data, {item, num})
		else
			return
		end
	end
	self:SetForgeInfo(GetForgeItem(data,container))
end

--保存锻造信息
function Er_Forge:SetForgeInfo(forgeitem,forgeids)
	if forgeitem ~= nil then
		self.forgeitem = forgeitem
		self.forgetime = 10
		self.forgeids = forgeids
	end
end

function Er_Forge:OnSave()
	return {
		loadforgeitem = self.forgeitem,
		loadforgetime = self.forgetime,
		loadforgeids = self.forgeids,
	}
end

function Er_Forge:OnLoad(data)
	if data ~= nil then
		self.forgeitem = data.loadforgeitem
		self.forgetime = data.loadforgetime
		self.forgeids = data.loadforgeids
    end
end

return Er_Forge