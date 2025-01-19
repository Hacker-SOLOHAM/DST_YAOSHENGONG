local function onlevel(self)
	self.inst.net_level:set_local(self.level)	--冲洗等级数据,便于头衔刷新
	self.inst.net_level:set(self.level)
	self:UpdateLevel()
end
local function onexp(self)
	self.inst.player_classified.net_exp:set(self.exp)
end
local function onexptotal(self)
	self.inst.player_classified.net_exptotal:set(self.exptotal)
end
local function onachievementnum(self)
	self.inst.player_classified.net_achievementnum:set(self.achievementnum)
end
local function onachievementgroup(self)
	self.inst.player_classified.net_achievementgroup:set(self.achievementgroup)
end
local function onluckynum(self)
	self.inst.luckynum = self.luckynum
end
local function onrunspeed(self)
	self.inst.components.locomotor.runspeed = self.runspeed
end

local Er_Leave = Class(function(self, inst)
    self.inst = inst			--调用者
	self.level = 0				--等级
	self.maxlevel = 10000		--最大等级
	self.exp = 0				--经验值
	self.exptotal = 10			--升级所需经验
	self.achievementnum = 0		--天赋点
	self.achievementgroup = 0	--天赋组
	self.extractlevel = 1		--植物提取等级
	self.repeattable = {}		--天赋重复表
	self.luckynum = 0			--幸运值
	self.runspeed = 6			--移速
	self.gotime = true			--前往副本时间
end,
nil,
{
    level = onlevel,
	exp = onexp,
	exptotal = onexptotal,
	achievementnum = onachievementnum,
	achievementgroup = onachievementgroup,
	luckynum = onluckynum,
	runspeed = onrunspeed,
})

--矿石掉率
local minelist = {
	rock1 = 0.005,
	rock2 = 0.005,
	rock_flintless = 0.005,
	rock_petrified_tree_tall = 0.005,
	rock_moon = 0.005,
	rock_moon_shell = 0.005,
	moonglass_rock = 0.005,
}

--矿石掉落表
local gemlists = {"redgem","bluegem","yellowgem","greengem","orangegem","purplegem"}

--额外掉落表
local lootlist = {
	"er_ore001","er_ore002","er_ore003","er_ore004","er_ore005"
}

--获取攻击力提升
local function getupdamage(level)
	local updamage = 0
	if level < 50 then
		updamage = 12
	elseif level < 200 then
		updamage = 33
	elseif level < 300 then
		updamage = 50
	elseif level < 500 then
		updamage = 100
	end
	return updamage
end

--天赋技能池
local SkillList = {
	--植物
	[1] = function(self,player,form)	--伐木馈赠
		local function effect(inst, data)
			if data.action == ACTIONS.CHOP then
				local lootdropper = data.target.components.lootdropper
				if lootdropper and math.random() < 0.5 then
					lootdropper:SpawnLootPrefab("livinglog")
				end
			end
		end
		if form then
			if player.effect1 then
				player.effect1 = nil
				player:RemoveEventCallback("finishedwork", effect)
			end
		else
			if player.effect1 == nil then
				player.effect1 = true
				player:ListenForEvent("finishedwork", effect)	--执行砍动作获得
			end
		end
	end,
	[2] = function(self,player,form)	--银星植物
		if form then
			self.extractlevel = 1
		else
			self.extractlevel = 2
		end
	end,
	[3] = function(self,player,form)	--金星植物
		if form then
			self.extractlevel = 1
		else
			self.extractlevel = 3
		end
	end,
	[4] = function(self,player,form)	--精品作物
		if form then
			player.cropproductup = false
		else
			player.cropproductup = true
		end
	end,
	[5] = function(self,player,form)	--精品药水
		if form then
			player.wineproductup = false
		else
			player.wineproductup = true
		end
	end,
	[6] = function(self,player,form)	--植株生长
		if form then
			player.fastgrowth = false
		else
			player.fastgrowth = true
		end
	end,
	[7] = function(self,player,form)	--双倍采集
		if form then
			player.harvestup = false
		else
			player.harvestup = true
		end
	end,
	--采矿
	[8] = function(self,player,form)	--黄金矿工
		if self.repeattable[8] == nil then
			self.repeattable[8] = true
			player.components.inventory:GiveItem(SpawnPrefab("er_tool001"))
		end
	end,
	[9] = function(self,player,form)	--轻松掘金
		if form then
			if player.effect9 then
				player.effect9:Cancel()
				player.effect9 = nil
			end
		else
			player.components.builder:UnlockRecipe("er_mine001")
			if player.effect9 == nil then
				player.effect9 = player:DoPeriodicTask(60, function(owner)
					owner.components.hunger:DoDelta(7.5)
					owner.components.sanity:DoDelta(2.5)
				end)
			end
		end
	end,
	[10] = function(self,player,form)	--点石成金
		local function effect(inst, data)
			if data.target then
				local lootdropper = data.target.components.lootdropper
				if lootdropper then
					local probability = minelist[data.target.prefab]
					if probability ~= nil then
						if math.random() < probability then
							lootdropper:SpawnLootPrefab(gemlists[GetRandomNum(#gemlists)])
						end
					end
				end
			end
		end
		if form then
			if player.effect10 then
				player.effect10 = nil
				player:RemoveEventCallback("working", effect)
			end
		else
			if player.effect10 == nil then
				player.effect10 = true
				player:ListenForEvent("working", effect)
			end
		end
	end,
	[11] = function(self,player,form)	--鼹鼠遁地
		player.components.builder:UnlockRecipe("er_tool002")
	end,
	[12] = function(self,player,form)	--寻找矿脉
		local function addmine(mine)
			local x,y,z = mine.Transform:GetWorldPosition()
			local item = string.format("er_mine%03d", math.random(2,3))
			SpawnPrefab(item).Transform:SetPosition(x,y,z)
		end
		local function effect(inst, data)
			if data.action == ACTIONS.MINE then
				if data.target.prefab == "marbleshrub" then	--对大理石单独处理
					local growable = data.target.components.growable
					if math.random() < 0.15 and growable and growable.stage == 3 then
						addmine(data.target)
						return
					end
				else
					if math.random() < 0.07 then
						addmine(data.target)
					end
				end
			end
		end
		if form then
			if player.effect12 then
				player.effect12 = nil
				player:RemoveEventCallback("finishedwork", effect)
			end
		else
			if player.effect12 == nil then
				player.effect12 = true
				player:ListenForEvent("finishedwork", effect)	--执行挖矿动作获得
			end
		end
	end,
	[13] = function(self,player,form)	--强化加成
		if form then
			player.strengthenup = false
		else
			player.strengthenup = true
		end
	end,
	[14] = function(self,player,form)	--结晶剥离
		local function effect(inst, data)
			if math.random() < 0.1 then
				local lootdropper = data.victim.components.lootdropper
				local rg_guaiwu = data.victim.components.rg_guaiwu
				if rg_guaiwu and rg_guaiwu.rank > 1 then
					if lootdropper and data.victim:HasTag("monster") then
						lootdropper:SpawnLootPrefab(lootlist[GetRandomNum(#lootlist)])
					end
				end
			end
		end
		if form then
			if player.effect14 then
				player.effect14 = nil
				player:RemoveEventCallback("killed", effect)
			end
		else
			if player.effect14 == nil then
				player.effect14 = true
				player:ListenForEvent("killed", effect)
			end
		end
	end,
	--幸运
	[15] = function(self,player,form)	--存活运气
		if form then
			player.luckyday = false
		else
			player.luckyday = true
		end
	end,
	[16] = function(self,player,form)	--击杀运气
		local function effect(inst, data)
			local rg_guaiwu = data.victim.components.rg_guaiwu
			if rg_guaiwu and rg_guaiwu.monstertype == 3 then
				local er_leave = inst.components.er_leave
				local addnum = math.random(1,5)
				er_leave.luckynum = er_leave.luckynum + addnum
				inst.components.talker:Say("获得"..addnum.."点幸运值!")
			end
		end
		if form then
			if player.effect16 then
				player.effect16 = nil
				player:RemoveEventCallback("killed", effect)
			end
		else
			if player.effect16 == nil then
				player.effect16 = true
				player:ListenForEvent("killed", effect)
			end
		end
	end,
	[17] = function(self,player,form)	--贪婪金币
		local function effect(player, data)
			data.target.goldbagup = true
		end
		if form then
			if player.effect17 then
				player.effect17 = nil
				player:RemoveEventCallback("onhitother",effect)
			end
		else
			if player.effect17 == nil then
				player.effect17 = true
				player:ListenForEvent("onhitother",effect)
			end
		end
	end,
	[18] = function(self,player,form)	--金币加成
		if form then
			player.moneyup = false
		else
			player.moneyup = true
		end
	end,
	[19] = function(self,player,form)	--冥想净化
		local function effect(player, data)
			if math.random() < 0.1 then
				player.components.rg_buff:RemoveAllDebuff()
				local x, y, z = player.Transform:GetWorldPosition()
				SpawnPrefab("er_tips_label"):set("<冥想净化>", 1).Transform:SetPosition(x,y,z)
			end
		end
		if form then
			if player.effect19 then
				player.effect19 = nil
				player:RemoveEventCallback("onhitother",effect)
			end
		else
			if player.effect19 == nil then
				player.effect19 = true
				player:ListenForEvent("onhitother",effect)
			end
		end
	end,
	[20] = function(self,player,form)	--贪婪经验
		if form then
			player.expup = false
		else
			player.expup = true
		end
	end,
	[21] = function(self,player,form)	--绝地逢生
		if form then
			player.cantdeath = false
		else
			player.cantdeath = true
		end
	end,
	--战斗
	[22] = function(self,player,form)	--食疗加成
		local function effect(inst, data)
			local edible = data.food.components.edible
			if edible then
				inst.components.health:DoDelta(edible.healthvalue * 0.2)
			end
		end
		if form then
			if player.effect22 then
				player.effect22 = nil
				player:RemoveEventCallback("oneat",effect)
			end
		else
			if player.effect22 == nil then
				player.effect22 = true
				player:ListenForEvent("oneat",effect)
			end
		end
	end,
	[23] = function(self,player,form)	--维京号角
		--攻击力提升
		local function updamage(inst)
			local rgwuqi = inst.components.rgwuqi
			if rgwuqi then
				rgwuqi:UpdateDamage(getupdamage(self.level))
			end
		end
		--初始化判定
		local equipweapon = player.components.combat:GetWeapon()
		if equipweapon then
			updamage(equipweapon)
		end
		local function effect1(inst, data)
			if data.eslot == EQUIPSLOTS.HANDS then
				updamage(data.item)
			end
		end
		local function effect2(inst, data)
			if data.eslot == EQUIPSLOTS.HANDS and data.item then
				local rgwuqi = data.item.components.rgwuqi
				if rgwuqi then
					rgwuqi:UpdateDamage()
				end
			end
		end
		if form then
			if player.effect23 then
				player.effect23 = nil
				player:RemoveEventCallback("equip", effect1)
				player:RemoveEventCallback("unequip", effect2)
			end
		else
			if player.effect23 == nil then
				player.effect23 = true
				player:ListenForEvent("equip", effect1)
				player:ListenForEvent("unequip", effect2)
			end
		end
	end,
	[24] = function(self,player,form)	--血量增加
		local health = player.components.health
		if form then
			if player.healthup then
				health.maxhealth = player.healthup
				player.healthup = nil
			end
		else
			if player.healthup == nil then
				player.healthup = health.maxhealth
				health.maxhealth = health.maxhealth * 1.2
			end
		end
	end,
	[25] = function(self,player,form)	--信仰叠加
		player.countnum = 0				--叠加次数
		local function effect(owner, data)
			if player.cancount == nil then
				local damageup = 0.1	--每次增加的攻击倍率
				local maxcount = 4		--最高叠加次数
				local combat = player.components.combat
				if player.countnum < maxcount then
					player.countnum = player.countnum + 1
					if player.countone == nil then
						local damagemultiplier = combat.damagemultiplier or 1
						combat.damagemultiplier = damagemultiplier + damageup
						player.countone = combat.damagemultiplier
					else
						combat.damagemultiplier = player.countone + damageup * (player.countnum - 1)
					end
				else
					player.cancount = true
					player:DoTaskInTime(10, function()
						player.countnum = 0
						player.countone = nil
						player:DoTaskInTime(60, function()
							player.cancount = nil
						end)
						combat.damagemultiplier = combat.damagemultiplier - maxcount * damageup
					end)
				end
			end
		end
		if form then
			if player.effect25 then
				player.effect25 = nil
				player:RemoveEventCallback("onhitother",effect)
			end
		else
			if player.effect25 == nil then
				player.effect25 = true
				player:ListenForEvent("onhitother",effect)
			end
		end
	end,
	[26] = function(self,player,form)	--生命汲取
		local function effect(owner, data)
			owner.components.health:DoDelta(math.random(1,3))
		end
		if form then
			if player.effect26 then
				player.effect26 = nil
				player:RemoveEventCallback("onhitother",effect)
			end
		else
			if player.effect26 == nil then
				player.effect26 = true
				player:ListenForEvent("onhitother",effect)
			end
		end
	end,
	[27] = function(self,player,form)	--维京觉醒
		--暴击率提升
		local function uprank(inst)
			local burstrank = inst.burstrank or 0
			inst.burstrank = burstrank + 0.1
		end
		--初始化判定
		local equipweapon = player.components.combat:GetWeapon()
		if equipweapon then
			uprank(equipweapon)
		end
		local function effect1(inst, data)
			if data.eslot == EQUIPSLOTS.HANDS then
				uprank(data.item)
			end
		end
		local function effect2(inst, data)
			if data.eslot == EQUIPSLOTS.HANDS and data.item then
				local burstrank = data.item.burstrank or 0
				data.item.burstrank = burstrank - 0.1
			end
		end
		if form then
			if player.effect27 then
				player.effect27 = nil
				player:RemoveEventCallback("equip", effect1)
				player:RemoveEventCallback("unequip", effect2)
			end
		else
			if player.effect27 == nil then
				player.effect27 = true
				player:ListenForEvent("equip", effect1)
				player:ListenForEvent("unequip", effect2)
			end
		end
	end,
	[28] = function(self,player,form)	--圣光之体
		local function effect(owner, data)
			if player.canlightup == nil and player.lradius and player.leavelight then
				if player.lradius < 6 then
					player.lradius = player.lradius + 0.3
					player.leavelight.Light:SetRadius(player.lradius)	--光扩大
				else
					player.canlightup = true
					SpawnPrefab("er_magiccircle001"):set(1, 30, 1, 3).entity:SetParent(player.entity)
					local fx = SpawnPrefab("deer_ice_flakes")
					fx.entity:SetParent(player.entity)
					player:DoTaskInTime(30, function()
						fx:Remove()
						player.lradius = 3		--恢复初始光范围
						if player.leavelight ~=nil and player.leavelight.Light ~=nil then--ByLaolufix 2021-05-17
							player.leavelight.Light:SetRadius(player.lradius)
						end
						player:DoTaskInTime(60, function()
							player.canlightup = nil
						end)
					end)
				end
			end
		end
		if form then
			if player.effect28 then
				player.effect28 = nil
				if player.leavelight then	--清除光
					player.leavelight:Remove()
					player.leavelight = nil
				end
				player:RemoveEventCallback("onhitother",effect)
			end
		else
			if player.effect28 == nil then
				player.effect28 = true
				if player.leavelight == nil then
					player.lradius = 3
					local light = SpawnPrefab("hua_light_light")
					light.Light:SetRadius(player.lradius)	--初始光范围
					light.entity:SetParent(player.entity)
					player.leavelight = light
				end
				player:ListenForEvent("onhitother",effect)
			end
		end
	end,
	--魔法
	[29] = function(self,player,form)	--魔能聚合
		if form then
			player.magicdamageup = false
		else
			player.magicdamageup = true
		end
	end,
	[30] = function(self,player,form)	--汇魔之心
		local lr_magic = player.components.lr_magic
		if form then
			if player.magicrateup then
				lr_magic.rate = player.magicrateup
				player.magicrateup = nil
			end
		else
			if player.magicrateup == nil then
				player.magicrateup = lr_magic.rate
				lr_magic.rate = lr_magic.rate + 2
			end
		end
	end,
	[31] = function(self,player,form)	--魔力迸发
		--暴击率提升
		local function uprank(inst)
			if inst:HasTag("er_longrange") then
				local burstrank = inst.burstrank or 0
				inst.burstrank = burstrank + 0.1
			end
		end
		--初始化判定
		local equipweapon = player.components.combat:GetWeapon()
		if equipweapon then
			uprank(equipweapon)
		end
		local function effect1(inst, data)
			if data.eslot == EQUIPSLOTS.HANDS then
				uprank(data.item)
			end
		end
		local function effect2(inst, data)
			if data.eslot == EQUIPSLOTS.HANDS and data.item then
				if data.item.burstrank then
					data.item.burstrank = data.item.burstrank - 0.3
				end
			end
		end
		if form then
			if player.effect31 then
				player.effect31 = nil
				player:RemoveEventCallback("equip", effect1)
				player:RemoveEventCallback("unequip", effect2)
			end
		else
			if player.effect31 == nil then
				player.effect31 = true
				player:ListenForEvent("equip", effect1)
				player:ListenForEvent("unequip", effect2)
			end
		end
	end,
	[32] = function(self,player,form)	--魔力扩散
		if form then
			player.magicrange = 1
		else
			player.magicrange = 2
		end
	end,
	[33] = function(self,player,form)	--静谧之心
		local function effect1(inst, data)
			if data.eslot == EQUIPSLOTS.HANDS then
				if data.item and data.item:HasTag("er_longrange") then
					data.item.components.spellcaster.quickcast = true
				end
			end
		end
		local function effect2(inst, data)
			if data.eslot == EQUIPSLOTS.HANDS then
				if data.item and data.item:HasTag("er_longrange") then
					data.item.components.spellcaster.quickcast = false
				end
			end
		end
		if form then
			if player.effect33 then
				player.effect33 = nil
				player:RemoveEventCallback("equip", effect1)
				player:RemoveEventCallback("unequip",effect2)
			end
		else
			if player.effect33 == nil then
				player.effect33 = true
				player:ListenForEvent("equip", effect1)
				player:ListenForEvent("unequip",effect2)
			end
		end
	end,
	[34] = function(self,player,form)	--贤者之力
		local lr_magic = player.components.lr_magic
		if form then
			if player.magicmaxup then
				lr_magic.max = player.magicmaxup
				player.magicmaxup = nil
			end
		else
			if player.magicmaxup == nil then
				player.magicmaxup = lr_magic.max
				lr_magic.max = lr_magic.max + 1000
			end
		end
	end,
	[35] = function(self,player,form)	--魔力附加
		local function effect(owner, data)
			if player.components.inventory:EquipHasTag("er_longrange") then
				local lr_magic = player.components.lr_magic
				local damage = lr_magic.current / 3
				lr_magic:DoDelta(-5)
				data.target.components.health:DoDelta(-damage)
			end
		end
		if form then
			if player.effect35 then
				player.effect35 = nil
				player:RemoveEventCallback("onhitother",effect)
			end
		else
			if player.effect35 == nil then
				player.effect35 = true
				player:ListenForEvent("onhitother",effect)
			end
		end
	end
}

--更新等级的效果
function Er_Leave:UpdateLevel()
	--升级加成
	local maxhealth = 200 + self.level
	if self.inst.healthup then
		maxhealth = maxhealth * 1.2
	end
	local uphealth = self.inst.uphealth
	if uphealth and uphealth > 0 then
		maxhealth = maxhealth + uphealth
	end

	local health = self.inst.components.health
	local percent = health:GetPercent()
	health.maxhealth = maxhealth
	health:SetPercent(percent)

	self.inst.components.hunger.max = 200 + self.level
	self.inst.components.sanity.max = 200 + self.level
end

--更新模块
function Er_Leave:UpdateModular(form)
	local code = self.achievementgroup
	for i=0, 4 do
		local num = code % 9
		code = math.floor( code / 9 )
		for j=1,num do
			local id = i * 7 + j
			SkillList[id](self,self.inst,form)
		end
	end
	if form then
		self.achievementnum = self.level	--天赋点重置
		self.achievementgroup = 0			--天赋组重置
		self.repeattable = {}				--天赋重复表重置
	end
end

--获取经验
function Er_Leave:DoPromote(amount)
	
	--防止等级溢出
	if (self.level > self.maxlevel) or amount == nil then
		return
	end

	local x,y,z = self.inst.Transform:GetWorldPosition()
	local canlevelup = false
	self.exp = self.exp + amount
	----------------------
	--动态经验系统:Bylaolu 202-09-09
	if TheWorld and TheWorld._expbv and type(TheWorld._expbv) =="number" and TheWorld._expbv > 0 then
		self.exp = self.exp + amount * (TheWorld._expbv or 1)
	end
	amount = math.max(0,amount)
	SpawnPrefab("er_tips_label"):set("经验:+ "..amount, 2).Transform:SetPosition(x,y,z)
	----------------------
	local function LevelUp(exps,exptotal)
		--如果当前经验超过所需经验
		if exps >= exptotal then
			self.level = self.level + 1					--等级加1
			self.achievementnum = self.achievementnum + 1	--天赋点加1
			self.exp = self.exp - self.exptotal			--将溢出的经验变为当前经验
			local rank = 100								--下一级所需经验是当前的1.012倍
			if self.level > 900 then
				rank = 1000
			elseif self.level > 800 then
				rank = 900
			elseif self.level > 700 then
				rank = 800
			elseif self.level > 600 then
				rank = 700
			elseif self.level > 500 then
				rank = 600
			elseif self.level > 400 then
				rank = 500
			elseif self.level > 300 then
				rank = 400
			elseif self.level > 200 then
				rank = 300
			elseif self.level > 100 then
				rank = 200
			end
			self.exptotal = self.exptotal + rank
			canlevelup = true
			return LevelUp(self.exp,self.exptotal)
		end
    end
	LevelUp(self.exp,self.exptotal)
	if canlevelup == true then
		SpawnPrefab("rg_leaveup").Transform:SetPosition(x,y,z)
	end
	-- SpawnPrefab("er_tips_label"):set("等级: "..self.level.."\nEXP: "..self.exp.."/"..self.exptotal, 1).Transform:SetPosition(x,y,z)
end

--保存信息
function Er_Leave:OnSave()
	return {
		loadlevel = self.level,
		loadexp = self.exp,
		loadexptotal = self.exptotal,
		loadachievementnum = self.achievementnum,
		loadachievementgroup = self.achievementgroup,
		loadextractlevel = self.extractlevel,
		loadrepeattable = self.repeattable,
		loadluckynum = self.luckynum,
		loadrunspeed = self.runspeed,
		loadgotime = self.gotime,
	}
end

--加载信息
function Er_Leave:OnLoad(data)
	if data ~= nil then
		self.level = data.loadlevel
		self.exp = data.loadexp
		self.exptotal = data.loadexptotal
		self.achievementnum = data.loadachievementnum
		self.achievementgroup = data.loadachievementgroup
		self.extractlevel = data.loadextractlevel
		self.repeattable =  data.loadrepeattable
		self.luckynum = data.loadluckynum
		self.gotime = data.loadgotime
		
		if data.loadrunspeed then
			self.runspeed = data.loadrunspeed
		end
		self:UpdateModular()
    end
end

return Er_Leave