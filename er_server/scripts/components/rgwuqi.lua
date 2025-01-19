local function onpin(self, pin)	--品阶
    if self.inst.rgcolour then
		self.inst.rgcolour:set(pin)
	end
	self:UpdateDamage()
	self:SetName()
end

local function onron(self)		--强化值
	self:UpdateDamage()
	self:SetName()
end

--技能id变更
local function onskid(self)
	self.inst.skid = self.skid
end

local abilityli = {
	{0.05,0.08,0.14,0.16,0.18,0.2,0.22,0.24,0.26,0.3},	--1穿甲率
	{0.1,0.14,0.18,0.22,0.26,0.3,0.34,0.38,0.42,0.5},	--2暴击率
	{100,200,400,800,1600,2400,4800,9600,19200},		--3耐久加成
	{0.95,0.9,0.8,0.7,0.6,0.5,0.4,0.3,0.2,0.1},			--4冷却系数
	{100,200,300,400,500,600,700,800,900,1000},			--5蓝量加成
	{0.9,0.8,0.7,0.6,0.5,0.4,0.3,0.2,0.1,0},			--6抗冷热系数
	{100,200,300,400,500,600,700,800,900,1000},			--7反震伤害{50,100,150,200,250,300,350,400,450,500},
	{100,200,300,400,500,600,700,800,900,1000},			--8反伤伤害
	{0.0005,0.001,0.0015,0.002,0.0025,0.003,0.0035,0.004,0.0045,0.005},			--9生命回复	最大生命*附魔值
	{0.04,0.08,0.12,0.16,0.2,0.24,0.28,0.32,0.36,0.4},	--10抗性
	{0.005,0.01,0.015,0.020,0.025,0.03,0.035,0.040,0.045,0.05},	--11吸血		10%几率  回复 最大生命*附魔值
	{1,2,3,4,5,6,7,8,9,10},								--12无敌时间
	{0.1,0.11,0.12,0.13,0.14,0.16,0.18,0.20,0.22,0.24},	--13闪避率
	{2,3,4,5,6,7,8,9,10,11},							--14魔爆伤害
}
local enchantfn = {
	["mold1"] = {
		function(self,level)
			self.inst.penetrate = abilityli[1][level]
		end,
		function(self,level)
			local function attackedfn(owner,data)
				if GetTime() - owner.godcd >= 120 then
					owner.godcd = GetTime()
					owner.components.health.invincible = true
					local shield = SpawnPrefab("forcefieldfx")
					shield.Transform:SetScale(0.7,0.7,0.7)
					shield.entity:SetParent(owner.entity)
					self.inst:DoTaskInTime(abilityli[12][level], function()
						shield:kill_fx()
						owner.components.health.invincible = false
					end)
				end
			end
			self.inst:ListenForEvent("equipped",function(inst, data)
				if data and data.owner then
					data.owner.godcd = 0
					inst:ListenForEvent("attacked", attackedfn, data.owner)
				end
			end)
			self.inst:ListenForEvent("unequipped",function(inst, data)
				if data and data.owner then
					data.owner.godcd = nil
					inst:RemoveEventCallback("attacked", attackedfn, data.owner)
				end
			end)
		end,
		function(self,level)
			self.inst:ListenForEvent("equipped",function(inst, data)
				if data and data.owner then
					if data.owner.dodge then
						data.owner.dodge = abilityli[13][level]
					else
						data.owner.dodge = abilityli[13][level]
						local combat = data.owner.components.combat
						local oldGetAttacked = combat.GetAttacked
						combat.GetAttacked = function(self, attacker, damage, weapon, stimuli,...)
							if math.random() < data.owner.dodge then
								SpawnPrefab("er_tips_label"):set("闪避", 1).Transform:SetPosition(data.owner.Transform:GetWorldPosition())
								return false
							end
							return oldGetAttacked(self, attacker, damage, weapon, stimuli,...)
						end
					end
				end
			end)
			self.inst:ListenForEvent("unequipped",function(inst, data)
				if data and data.owner then
					data.owner.dodge = 0
				end
			end)
		end,
	},
	["mold2"] = {
		function(self,level)
			local function atkfn(player, data)
				if math.random() < 0.15 then
					if data and data.weapon then
						local health = player.components.health
						health:DoDelta(health.maxhealth * abilityli[11][level])
					end
				end
			end
			local function changefn(owner,add)
				if add then
					owner:ListenForEvent("onhitother", atkfn)
				else
					owner:RemoveEventCallback("onhitother", atkfn)
				end
			end
			self.inst:ListenForEvent("equipped",function(inst, data)
				if data and data.owner then
					changefn(data.owner,true)
				end
			end)
			self.inst:ListenForEvent("unequipped",function(inst, data)
				if data and data.owner then
					changefn(data.owner)
				end
			end)
		end,
		function(self,level)
			self.inst:ListenForEvent("equipped",function(inst, data)
				if data and data.owner then
					data.owner.resistrank = abilityli[10][level]
				end
			end)
			self.inst:ListenForEvent("unequipped",function(inst, data)
				if data and data.owner then
					data.owner.resistrank = 0
				end
			end)
		end,
		function(self,level)
			local function changefn(owner,add)
				if add == false then
					if owner.ehpup ~=nil then
						owner.ehpup:Cancel() --ByLaoluFix 2021-06-07
						owner.ehpup = nil
					end
				else
					owner.ehpup = owner:DoPeriodicTask(1, function()
						local health = owner.components.health
						health:DoDelta(health.maxhealth * abilityli[9][level])
					end)					
				end
				-- owner.ehpup = nil
				-- if add == true then
					-- owner.ehpup = owner:DoPeriodicTask(1, function()
						-- local health = owner.components.health
						-- health:DoDelta(health.maxhealth * abilityli[9][level])
					-- end)
				-- else
					-- if owner.ehpup ~=nil then owner.ehpup:Cancel() end --ByLaoluFix 2021-06-07
				-- end
			end
			self.inst:ListenForEvent("equipped",function(inst, data)
				if data and data.owner then
					changefn(data.owner,true)
				end
			end)
			self.inst:ListenForEvent("unequipped",function(inst, data)
				if data and data.owner then
					changefn(data.owner,false)
				end
			end)
		end,
	},
	["mold3"] = {
		function(self,level)
			self.inst.rburst = abilityli[2][level]
		end,
		function(self,level)
			local function attackedfn(owner,data)
				local er_leave = owner.components.er_leave
				if data.damage and er_leave then
					--反震算法--ByLaolu 2021-06-18
					local rank = 1
					if er_leave.level >=1000 then rank = 1.5
					elseif er_leave.level >=2000 then rank = 2
					elseif er_leave.level >=3000 then rank = 3
					elseif er_leave.level >=4000 then rank = 4
					end
					SpawnPrefab("bramblefx_rg"):SetFXOwner(owner, rank * abilityli[7][level])
					--FixEnd
					owner.SoundEmitter:PlaySound("dontstarve/common/together/armor/cactus")
				end
			end
			self.inst:ListenForEvent("equipped",function(inst, data)
				if data and data.owner then
					inst:ListenForEvent("attacked", attackedfn, data.owner)
				end
			end)
			self.inst:ListenForEvent("unequipped",function(inst, data)
				if data and data.owner then
					inst:RemoveEventCallback("attacked", attackedfn, data.owner)
				end
			end)
		end,
		function(self,level)
			local function attackedfn(owner,data)
				local er_leave = owner.components.er_leave
				if data.attacker and er_leave and data.target then
					local combat = data.target.components and data.target.components.combat--ByLaoluFix 2021-06-22 修复反伤目标的错误
					local health = data.attacker.components.health
					if data.attacker:IsValid() and combat and health and not health:IsDead() then
						-- combat:GetAttacked(owner, er_leave.level * abilityli[8][level])--ByLaoluFix 2021-06-14 修复反伤算法
						local rank = 1
						if er_leave.level >=1000 then rank = 1.5
						elseif er_leave.level >=2000 then rank = 2
						elseif er_leave.level >=3000 then rank = 3
						elseif er_leave.level >=4000 then rank = 4
						end
						--玩家等级获取rank值 * 反伤附魔的级别(1-10)的伤害值100-1000, 得到100-4000的反伤值,最高4000反伤
						combat:GetAttacked(owner, rank *abilityli[8][level])----ByLaolu 2021-06-18 修复反伤算法
						--玩家等级 * 0.1 * 反伤等级系数对应的伤害(100,200,300,...1000)
						-- combat:GetAttacked(owner, er_leave.level*0.1*abilityli[8][level])--ByLaoluFix 2021-06-14 修复反伤算法
					end
				end
			end
			self.inst:ListenForEvent("equipped",function(inst, data)
				if data and data.owner then
					inst:ListenForEvent("attacked", attackedfn, data.owner)
				end
			end)
			self.inst:ListenForEvent("unequipped",function(inst, data)
				if data and data.owner then
					inst:RemoveEventCallback("attacked", attackedfn, data.owner)
				end
			end)
		end,
	},
	["mold4"] = {
		function(self,level)
			self.inst.mburst = abilityli[14][level]
		end,
		function(self,level)
			local function changefn(owner,add)
				local lr_magic = owner.components.lr_magic
				if lr_magic then
					local num = abilityli[5][level]
					local percent = lr_magic:GetPercent()
					if add then
						lr_magic.max = lr_magic.max + num
					else
						lr_magic.max = lr_magic.max - num
					end
					lr_magic:SetPercent(percent)
				end
			end
			self.inst:ListenForEvent("equipped",function(inst, data)
				if data and data.owner then
					changefn(data.owner,true)
				end
			end)
			self.inst:ListenForEvent("unequipped",function(inst, data)
				if data and data.owner then
					changefn(data.owner)
				end
			end)
		end,
		function(self,level)
			local function changefn(inst,owner,add)
				local num = abilityli[6][level]
				--热抗
				local health = owner.components.health
				if add then
					health.externalfiredamagemultipliers:SetModifier(inst, num)
				else
					num = 0
					health.externalfiredamagemultipliers:RemoveModifier(inst)
				end
				--免疫冻结
				local freezable = owner.components.freezable
				local OldAddcoldness = freezable.AddColdness
				freezable.AddColdness = function(self, coldness, freezetime, nofreeze)
					if math.random() > num then
						return
					end
					return OldAddcoldness(self, coldness, freezetime, nofreeze)
				end
			end
			self.inst:ListenForEvent("equipped",function(inst, data)
				if data and data.owner then
					changefn(inst,data.owner,true)
				end
			end)
			self.inst:ListenForEvent("unequipped",function(inst, data)
				if data and data.owner then
					changefn(inst,data.owner)
				end
			end)
		end,
	},
	["mold5"] = {
		function(self,level)
			self.inst.skcd = abilityli[4][level]
			--冷却组件更新处理：ByLaolu 2021-06-19
			local function ratefn(inst)
				local rate = 1
				if inst.skcd then
					rate = inst.skcd
				end
				return rate
			end
			
			if self.inst.components then
				self.inst.components.rechargeable:SetRechargeRate(ratefn)
			end
			--冷却处理借宿
		end,
		function(self,level)
			local armor = self.inst.components.armor
			if abilityli[3][level] then
				armor.maxcondition = armor.maxcondition + abilityli[3][level]
				armor:SetCondition(armor.condition)
			else
				armor:InitIndestructible(self.inst.defensive)
			end
		end,
		function(self,level)
			local armor = self.inst.components.armor
			if abilityli[3][level] then
				armor.maxcondition = armor.maxcondition + abilityli[3][level]
				armor:SetCondition(armor.condition)
			else
				armor:InitIndestructible(self.inst.defensive)
			end
		end,
	},
}
--附魔触发
local function ontrigger(self)
	for k, v in pairs(self.slotli) do
		if v ~= "" then
			enchantfn[v[1]][self.type](self,v[2])
		end
	end
	self:SetName()
end

local Rgwuqi = Class(function(self, inst)
    self.inst = inst

	self.pin = 0				--装备品阶
	self.ron = 0				--装备熔炼值
	self.dmgrank = 0			--攻击力加成系数
	self.userid = nil			--装备默认的绑定ID
	self.username = "未绑定"	--装备默认的绑定名字
	self.skid = 0				--技能id
	self.skname = "未技觉"		--装备技能名
	self.type = 1				--类型id
	self.slotli = {}			--孔位
	self.trigger = nil			--触发

	inst:AddTag("rgwuqi")

	--认主
	inst:ListenForEvent("onputininventory", function(inst)
		if self.userid ~= nil then
			local owner = inst.components.inventoryitem:GetGrandOwner()
			if owner and owner:HasTag("player") then
				if owner.components.inventory and owner.userid~=self.userid then
					owner:DoTaskInTime(0, function()
						owner.components.inventory:DropItem(inst, false, true)
						owner.components.talker:Say("不是我的东西,我不能捡!")
					end)
				end
			end
		end
	end)

	inst:DoTaskInTime(0.1, function()
		self:SetName()
		local armor = inst.components.armor
		if armor then
			local oldonfinished = armor.onfinished
			armor.onfinished = function(armor)
				self:Separate()		--爆甲掉落宝石
				if oldonfinished then
					oldonfinished()
				end
			end
		end
	end)
end,
nil,
{
    pin = onpin,
	ron = onron,
	skid = onskid,
	trigger = ontrigger
})

--开孔
function Rgwuqi:Untie()
	table.insert(self.slotli,"")
	self.trigger = true
end

--附魔
--ByLaoluFix 2021-07-02
--方案设计:
-- vc1:
-- 1.当附魔石和装备的附魔相匹配时
-- 2.当附魔石lv >= 装备的附魔lv 时
-- 3.装备的附魔lv = 附魔石lv - 装备的附魔lv
-- 如:装备lv3,附魔石lv5,那么升级附魔后,装备匹配的附魔lv5

-- vc2:
-- 1.当附魔石和装备的附魔相匹配时
-- 2.当附魔石lv >= 装备的附魔lv 时
-- 3.装备的附魔lv = 附魔石lv - 装备的附魔lv
-- 如:装备lv3,附魔石lv5,那么升级附魔后,装备匹配的附魔lv5
-- 4.当附魔石lv < 装备的附魔lv时
-- 5.装备的附魔lv = 装备的附魔lv +1
-- 如:装备lv3,附魔石lv2,那么升级附魔后,装备匹配的附魔lv4
function Rgwuqi:Enchant(mold,level)
	--附魔等级增加
	local result = true
	for k, v in pairs(self.slotli) do
		if v[1] == mold then	
			self.slotli[k][2] = level or v[2] + 1
			result = nil
		end
	end
	--添加新附魔
	if result ==true then
		for k, v in pairs(self.slotli) do
			if v == "" then
				self.slotli[k] = {mold,level or 1}
				break
			end
		end
	end
	self.trigger = true
end

--解体
local function dropitem(weapon,item,master)
	local x, y, z = weapon.Transform:GetWorldPosition()
	item.Transform:SetPosition(x,y,z)
	if item.components.inventoryitem then
		item.components.inventoryitem:OnDropped(true)
		if master then
			--重新认主
			item.components.named:SetName((item.oldName or item.name or "") .." .已绑定.\n".."所有者："..master.name)
			item.er_itemlocker = master.userid
		end
	end
end
function Rgwuqi:Separate(master)
	--解离附魔石
	for k, v in pairs(self.slotli) do
		if v ~= "" then
			local dropped = SpawnPrefab("er_gem00"..self.type)
			dropped:set(tonumber(string.match(v[1],"mold(%d)")),v[2])
			dropitem(self.inst,dropped,master)
		end
	end
	--解离技能书
	if self.skid ~= 0 then
		local dropped = SpawnPrefab(string.format("er_awaken%03d", self.skid))
		dropitem(self.inst,dropped)
	end
	--额外获取附魔石
	local dropped = SpawnPrefab("er_gem00"..self.type)
	dropped:set(math.random(1,5),1)
	dropitem(self.inst,dropped,master)
end

--更新伤害	(基本攻击力+强化加成)*品阶加成*加成倍率
local pinuplist = {0.5,0.7,0.8,0.9,1,1.2}--ByRG 202-09-24
function Rgwuqi:UpdateDamage(updamage)
	local weapon = self.inst.components.weapon
	if weapon then
		local ronup = self.ron or 0					--强化加成
		local pinup = pinuplist[self.pin+1] or 0	--品阶加成
		local rank = self.dmgrank or 0				--加成倍率
		if self.inst.discount then
			rank = rank * self.inst.discount		--远程武器折扣
		end
		
		local damage = weapon.damage
		if self.inst.damage then
			damage = self.inst.damage
		end
		if ronup >0 then
			damage = self.inst.damage + ronup
		end
		if updamage ~= nil then
			damage = damage + updamage
		end
		--ByLaoluFix 2021-07-02 修复武器初始化伤害=0的严重错误
		if pinup > 0 then
			damage = damage * pinup
		end
		if rank >0 then
			damage = damage* rank
		end
		weapon.damage = damage
		-- self.inst.damage = weapon.damage
	end
end

--强化值增加
function Rgwuqi:DoStrengthen(canup)
	local chance = 0.01
	if self.ron < 2000 then
		chance = 1
	elseif self.ron < 3000 then
		chance = 0.8
	elseif self.ron < 4000 then
		chance = 0.7
	elseif self.ron < 5000 then
		chance = 0.6
	elseif self.ron < 6000 then
		chance = 0.5
	elseif self.ron < 7000 then
		chance = 0.4
	elseif self.ron < 8000 then
		chance = 0.3
	elseif self.ron < 9000 then
		chance = 0.2
	elseif self.ron < 10000 then
		chance = 0.1
	end
	if canup then
		chance = chance + 0.1
	end
	local x,y,z = self.inst.Transform:GetWorldPosition()
	if math.random() <= chance then
		self.ron = self.ron + 1
		SpawnPrefab("er_tips_label"):set("强化成功!", 1).Transform:SetPosition(x,y,z)
	else
		SpawnPrefab("er_tips_label"):set("强化失败!", 1).Transform:SetPosition(x,y,z)
	end
end

--系数变更
function Rgwuqi:DoRise(uprank)
	self.dmgrank = self.dmgrank + uprank
	self:UpdateDamage()
	self:SetName()
end

local enameli = {
	{
		["mold1"] = "穿甲",
		["mold2"] = "嗜血",
		["mold3"] = "暴击",
		["mold4"] = "魔爆",
		["mold5"] = "冷却"
	},{
		["mold1"] = "无敌",
		["mold2"] = "抗性",
		["mold3"] = "反震",
		["mold4"] = "法力",
		["mold5"] = "永恒"
	},{
		["mold1"] = "闪避",
		["mold2"] = "生命",
		["mold3"] = "反伤",
		["mold4"] = "冻烧",
		["mold5"] = "永恒"
	}
}
--特殊武器技能命名
local pskill = {"祝语","剑影","无双","伯爵再现","狂暴"}
function Rgwuqi:SetName()
	if self.inst.components.named then
		local name = STRINGS.NAMES[string.upper(self.inst.prefab or "ice")]
		self.inst.components.named:SetName(name)
		
		-------------------------
		--转换新的函数输出字符串
		self.inst.needothershow = function(inst, str)
			if self.username then
				table.insert(str,{"绑定者", self.username})
			end
			if self.skname then
				table.insert(str,{"技觉", self.skname})
			end
			if pskill[self.inst.pskid] then
				table.insert(str,{"特殊技", pskill[self.inst.pskid] or "无"})
			end
			if self.type == 1 then
				table.insert(str,{"强化", (self.ron or 0)})
				table.insert(str,{"攻击加成", (self.dmgrank or 0)})
			end			
			if self.slotli then
				for i,v in pairs(self.slotli) do
					if v == "" then
						table.insert(str,{"孔位", "无"})
					else
						table.insert(str,{enameli[self.type][v[1]], "Lv."..v[2]})
					end
				end
			end
		end
	end
end
function Rgwuqi:GetStr()
	local str = {}
	if self.username then
		table.insert(str,{"绑定者", self.username})
	end
	if self.skname then
		table.insert(str,{"技觉", self.skname})
	end
	if pskill[self.inst.pskid] then
		table.insert(str,{"特殊技", pskill[self.inst.pskid] or "无"})
	end
	if self.type == 1 then
		table.insert(str,{"强化", (self.ron or 0)})
		table.insert(str,{"攻击加成", (self.dmgrank or 0)})
	end			
	if self.slotli then
		for i,v in pairs(self.slotli) do
			if v == "" then
				table.insert(str,{"孔位", "无"})
			else
				table.insert(str,{enameli[self.type][v[1]], "Lv."..v[2]})
			end
		end
	end
	return str
end
function Rgwuqi:Save(...)
	local t = {}
	for i, v in ipairs(arg) do
		t[v] = self[v]
	end
	return t
end

function Rgwuqi:OnSave()
	return self:Save("pin","ron","dmgrank","userid","username","skid","skname","slotli")
end

function Rgwuqi:OnLoad(data)
    if data then
        for k, v in pairs(data) do
			self[k] = v or 0
		end
		self.trigger = true
    end
end

return Rgwuqi