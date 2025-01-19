--配方
--ByLaoluFix 重写并添加注释.2021-07-13
local formulalists = {
	{--精炼
		{
			{"er_crop_fruit031", 1},
			{"nightmarefuel", 2},
			makeitem = {"redgem","bluegem"},
			maketime = 30
		},
		{
			{"er_crop_fruit032", 1},
			{"nightmarefuel", 5},
			makeitem = {"yellowgem","purplegem","orangegem","greengem"},
			maketime = 30
		},
		-- {
			-- {"er_crop_fruit033", 5},
			-- {"nightmarefuel", 10},
			-- makeitem = {"er_ore001","er_ore002","er_ore003","er_ore004","er_ore005"},
			-- maketime = 30
		-- },
		{
			{"er_crop_fruit033", 2},
			{"nightmarefuel", 10},
			makeitem = "opalpreciousgem",
			maketime = 30
		},
		{
			{"yellowgem", 5},
			{"bluegem", 5},
			makeitem = "black1",
			maketime = 30
		},
		{
			{"greengem", 5},
			{"redgem", 5},
			makeitem = "black1",
			maketime = 30
		},
		{
			{"moonrocknugget", 7},
			{"nightmarefuel", 1},
			makeitem = "moonglass",
			maketime = 30
		}
	},
	{--织布
		{
			{"er_crop_fruit021", 3},		--主材--木棉lv1 *3
			{"silk", 30},					--辅材--蜘蛛网 *30
			makeitem = "er_sundries018",	--产品--棉布 *1
			maketime = 30					--制造时间:30秒
		},
		{
			{"er_crop_fruit022", 2},		--主材--木棉lv2 *2
			{"beefalowool", 30},			--辅材--牛毛 *30
			makeitem = "er_sundries019",	--产品--羽丝棉 *1
			maketime = 30
		},
		{
			{"er_crop_fruit023", 1},		--主材--木棉lv3 *1
			{"manrabbit_tail", 30},			--辅材--兔毛 *30
			makeitem = "er_sundries020",	--产品--云中锦 *1
			maketime = 30
		},
	},
	{--精酿
		--LV1
		{
			{"er_flower_fruit011", 3},	--玫瑰花lv1 *3
			{"moon_tree_blossom", 3},	--月树花 *3
			makeitem = "lf_drug001_1",	--攻击药水lv1 *1
			maketime = 30
		},
		{
			{"er_flower_fruit041", 3},	--矮牵牛lv1 *3
			{"cactus_flower", 3},		--仙人掌花 *3
			makeitem = "lf_drug002_1",	--回复药水lv1
			maketime = 30
		},
		{
			{"er_flower_fruit031", 3},	--皓月莲lv1 *3
			{"succulent_picked", 10},	--多肉植物 *10
			makeitem = "lf_drug003_1",	--移速药水lv1
			maketime = 30
		},
		{
			{"er_flower_fruit021", 3},	--夜心花lv1 *3
			{"petals_evil", 10},		--恶魔花瓣 *10
			makeitem = "lf_drug004_1",	--魔法药水lv1
			maketime = 30
		},
		{
			{"wormlight", 3},			--发光浆果 *3
			{"lightbulb", 10},			--荧光果 *10
			makeitem = "lf_drug005_1",	--发光药水lv1
			maketime = 30
		},
		{
			{"er_flower_fruit051", 3},	--幸运草lv1 *3
			{"butter", 3},				--黄油 *3
			makeitem = "lf_drug006_1",	--幸运药水lv1
			maketime = 30
		},
		{
			{"er_crop_fruit041", 3},	--莴笋lv1 *3
			{"moonglass", 2},			--月亮碎片 *2
			makeitem = "lf_drug007_1",	--植物药水lv1
			maketime = 30
		},
		{
			{"er_crop_fruit051", 3},	--草莓lv1 *3
			{"berries", 5},				--浆果 *5
			makeitem = "lf_drug009_1",	--白兰地[抗热] lv1
			maketime = 30
		},
		{
			{"er_crop_fruit011", 3},	--玉米lv1 *3
			{"berries", 5},				--浆果 *5
			makeitem = "lf_drug008_1",	--伏特加[抗寒] lv1
			maketime = 30
		},
		--LV2
		{
			{"er_flower_fruit012", 3},	--玫瑰花Lv2 *3
			{"moon_tree_blossom", 3},	--月树花 *3
			makeitem = "lf_drug001_2",	--攻击药水Lv2 *1
			maketime = 30
		},
		{
			{"er_flower_fruit042", 3},	--矮牵牛Lv2 *3
			{"cactus_flower", 3},		--仙人掌花 *3
			makeitem = "lf_drug002_2",	--回复药水Lv2
			maketime = 30
		},
		{
			{"er_flower_fruit032", 3},	--皓月莲Lv2 *3
			{"succulent_picked", 10},	--多肉植物 *10
			makeitem = "lf_drug003_2",	--移速药水Lv2
			maketime = 30
		},
		{
			{"er_flower_fruit022", 3},	--夜心花Lv2 *3
			{"petals_evil", 10},		--恶魔花瓣 *10
			makeitem = "lf_drug004_2",	--魔法药水Lv2
			maketime = 30
		},
		{
			{"wormlight", 3},			--发光浆果 *3
			{"lightbulb", 10},			--荧光果 *10
			makeitem = "lf_drug005_2",	--发光药水Lv2
			maketime = 30
		},
		{
			{"er_flower_fruit052", 3},	--幸运草Lv2 *3
			{"butter", 3},				--黄油 *3
			makeitem = "lf_drug006_2",	--幸运药水Lv2
			maketime = 30
		},
		{
			{"er_crop_fruit042", 3},	--莴笋Lv2 *3
			{"moonglass", 2},			--月亮碎片 *2
			makeitem = "lf_drug007_2",	--植物药水Lv2
			maketime = 30
		},
		{
			{"er_crop_fruit052", 3},	--草莓Lv2 *3
			{"berries", 5},				--浆果 *5
			makeitem = "lf_drug009_2",	--白兰地[抗热] lv2
			maketime = 30
		},
		{
			{"er_crop_fruit012", 3},	--玉米Lv2 *3
			{"berries", 5},				--浆果 *5
			makeitem = "lf_drug008_2",	--伏特加[抗寒] lv2
			maketime = 30
		},
		--LV3
		{
			{"er_flower_fruit013", 3},	--玫瑰花Lv3 *3
			{"moon_tree_blossom", 3},	--月树花 *3
			makeitem = "lf_drug001_3",	--攻击药水Lv3 *1
			maketime = 30
		},
		{
			{"er_flower_fruit043", 3},	--矮牵牛Lv3 *3
			{"cactus_flower", 3},		--仙人掌花 *3
			makeitem = "lf_drug002_3",	--回复药水Lv3
			maketime = 30
		},
		{
			{"er_flower_fruit033", 3},	--皓月莲Lv3 *3
			{"succulent_picked", 10},	--多肉植物 *10
			makeitem = "lf_drug003_3",	--移速药水Lv3
			maketime = 30
		},
		{
			{"er_flower_fruit023", 3},	--夜心花Lv3 *3
			{"petals_evil", 10},		--恶魔花瓣 *10
			makeitem = "lf_drug004_3",	--魔法药水Lv3
			maketime = 30
		},
		{
			{"wormlight", 3},			--发光浆果 *3
			{"lightbulb", 10},			--荧光果 *10
			makeitem = "lf_drug005_3",	--发光药水Lv3
			maketime = 30
		},
		{
			{"er_flower_fruit053", 3},	--幸运草Lv3 *3
			{"butter", 3},				--黄油 *3
			makeitem = "lf_drug006_3",	--幸运药水Lv3
			maketime = 30
		},
		{
			{"er_crop_fruit043", 3},	--莴笋Lv3 *3
			{"moonglass", 2},			--月亮碎片 *2
			makeitem = "lf_drug007_3",	--植物药水Lv3
			maketime = 30
		},
		{
			{"er_crop_fruit053", 3},	--草莓Lv3 *3
			{"berries", 5},				--浆果 *5
			makeitem = "lf_drug009_3",	--白兰地[抗热] Lv3
			maketime = 30
		},
		{
			{"er_crop_fruit013", 3},	--玉米Lv3 *3
			{"berries", 5},				--浆果 *5
			makeitem = "lf_drug008_3",	--伏特加[抗寒] Lv3
			maketime = 30
		}
	},
}

--开始制造
local function doMake(self)
	if self.makeitem ~= "nothing" then
		self.inst:DoTaskInTime(self.maketime, function()
			self.inst.components.container:GiveItem(SpawnPrefab(self.makeitem))
			self.makeitem = "nothing"
			self:StartMake(self.extractlevel)
		end)
		self.inst.AnimState:PlayAnimation(self.inst.prefab.."_on",true)
	end
end

local Er_Make = Class(function(self, inst)
    self.inst = inst
	self.makeitem = "nothing"	--制造物品
	self.maketime = 0			--制造时间
	self.extractlevel = 1		--提取等级
end,
nil,
{
	maketime = doMake,
})

--获取提取物
local function GeterExtractItem(item,container,extractlevel)
	local extractid = item.extractid
	local makeitem = "nothing"
	if extractid then
		if item:HasTag("crop_fruit") then
			makeitem = string.format("er_crop_seed%02d", extractid)..math.random(1,extractlevel)
		elseif item:HasTag("flower_fruit") then
			makeitem = string.format("er_flower_seed%02d", extractid)..math.random(1,extractlevel)
		end
		container:ConsumeByName(item.prefab,1)
		return makeitem,10
	end
end

--获取制造产物
local function GetMakeItem(data,container,workshoptype)
	for i,v in ipairs(formulalists[workshoptype]) do
		local result = true
		for i=1,2 do
			--格子里的物品不属于配方或数量低于配方设定数
			if not (data[i][1]==v[i][1] and data[i][2]>=v[i][2]) then
				result = false
				break
			end
		end
		if result then
			container:ConsumeByName(v[1][1],v[1][2])
			container:ConsumeByName(v[2][1],v[2][2])
			if type(v.makeitem) == "string" then
				return v.makeitem,v.maketime
			else
				return v.makeitem[GetRandomNum(#v.makeitem)],v.maketime
			end
		end
	end
end

--制造方法
function Er_Make:StartMake(extractlevel)
	self.inst.AnimState:PlayAnimation(self.inst.prefab.."_off")		--更新动画
	local container = self.inst.components.container
	local workshoptype = self.inst.workshoptype
	if workshoptype < 4 then
		local data = {}
		for i=1, 2 do
			local item = container:GetItemInSlot(i)
			if item ~= nil then
				local stackable = item.components.stackable
				local num = stackable and stackable:StackSize() or 1
				table.insert(data, {item.prefab, num})
			else
				return
			end
		end
		self:SetMakeInfo(GetMakeItem(data,container,workshoptype))
	else
		local item = container:GetItemInSlot(1)
		if item ~= nil then
			self.extractlevel = extractlevel
			self:SetMakeInfo(GeterExtractItem(item,container,self.extractlevel))
		end
	end
end

--保存制造信息
function Er_Make:SetMakeInfo(makeitem,maketime)
	if makeitem ~= nil and maketime ~= nil then
		self.makeitem = makeitem
		self.maketime = maketime
	end
end

function Er_Make:OnSave()
	return {
		loadmakeitem = self.makeitem,
		loadmaketime = self.maketime,
	}
end

function Er_Make:OnLoad(data)
	if data ~= nil then
		self.makeitem = data.loadmakeitem
        self.maketime = data.loadmaketime
    end
end

return Er_Make