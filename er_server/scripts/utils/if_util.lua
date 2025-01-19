--Er的垃圾函数库

--附加Debuff
local function DoEffect(key, inst, target)
	if key == 1 then		--击飞
		inst:PushEvent("knockback", {knocker = target or inst, radius = 5})
	elseif key == 2 then	--击晕
		local pc = inst.components.playercontroller
		if pc and inst.effect1 == nil then
			pc:Enable(false)
			inst.components.locomotor:StopMoving()
			inst.AnimState:PlayAnimation("idle_groggy", true)
			SpawnPrefab("er_tips_label"):set("<眩晕>", 1).Transform:SetPosition(inst.Transform:GetWorldPosition())
			local spike = SpawnPrefab("rg_vertigofx")
			spike.entity:AddFollower()
			spike.Follower:FollowSymbol(inst.GUID, "swap_hat", 0, -80, 0)
			inst.effect1 = inst:DoTaskInTime(3, function()
				pc:Enable(true)
				inst.effect1:Cancel()
				inst.effect1 = nil
			end)
		end
	end
end

--连续范围攻击
function LongAttack(inst, timecd, damage, radius, effect)
	local NotValTarget = {}
	local selfcd, cd, task = GetTime(), GetTime
	task = inst:DoPeriodicTask(FRAMES * 3, function()
		if cd() - selfcd <= timecd and inst:IsValid() then
			local x,y,z = inst.Transform:GetWorldPosition()
			local ents = TheSim:FindEntities(x, 0, z, radius or 5, {"player"},{"shadowboss","playerghost"})
			for k,v in pairs(ents) do
				if not NotValTarget[v] and v.components.health.canheal and inst.components.combat:CanTarget(v) then
					NotValTarget[v] = true
					v.components.combat:GetAttacked(inst, damage or 10)
					if effect then
						DoEffect(effect, v, inst)
					end
				end
			end
		else
			NotValTarget = nil
			task:Cancel()
		end
	end)
	return task
end

--单次范围攻击
function ShortAttack(inst, damage, radius, effect)
	if inst then
		local x,y,z = inst.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x, y, z, radius, {"player"},{"shadowboss","playerghost"})
		for k,v in pairs(ents) do
			if v and v.components.health and not v.components.health:IsDead() then
				v.components.combat:GetAttacked(v, damage)
				if effect then
					DoEffect(effect, v, inst)
				end
			end
		end
	else
		print("无对象!")
	end
end

--特效飞行
function MakeFlyitem(inst, target, fx, speeds)
	fx.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	fx:FacePoint(target.Transform:GetWorldPosition())
	fx.Physics:SetMotorVelOverride(speeds[1],speeds[2],speeds[3])
end

--多实体角度飞行
function AngleFly(target, inst, num, phys)
	local x,y,z = target.Transform:GetWorldPosition()
	inst.Transform:SetPosition(x, 0, z)
	local angle = -target.Transform:GetRotation() 
	local offset = Vector3(math.cos(angle*DEGREES), 0, math.sin(angle*DEGREES))
	local pos = inst:GetPosition() + offset
	angle = inst:GetAngleToPoint(pos:Get())
	angle = angle + num		--偏离角度
	if angle < 0 then		--获得最终面向角度
		angle = angle + 360
	elseif angle > 360 then
		angle = angle - 360
	end
	inst.Transform:SetRotation(angle)
	inst.Physics:SetMotorVelOverride(phys[1],phys[2],phys[3])
end

--获取随机数(获得大数字的概率变低)
function GetRandomNum(rank)
	local num = rank * 0.5 * (rank + 1)
	local result = 0
	local r = math.random()
	for i=1,rank do
		r = r - (rank- i + 1) / num
		if r <= 0 then
			result = i
			break
		end
	end
	return result
end

--周边召唤
function SpawnItem(inst,target,radius,numli)
	local x,y,z = inst.Transform:GetWorldPosition()
	local item = SpawnPrefab(target)
	local pos = inst:GetPosition()
	local offset = FindValidPositionByFan(2 * PI * math.random(), radius, radius*4, function(offsets)
		local pt = Vector3(x + offsets.x, 0, z + offsets.z)
		return TheWorld.Map:IsPassableAtPoint(pt:Get())
				and not TheWorld.Map:IsPointNearHole(pt)
	end)
	if offset ~= nil then
		pos = pos + offset
	end
	item.Transform:SetPosition(pos:Get())
	if numli then
		inst.branch = inst.branch + 1
		item:ListenForEvent("onremove", function()	--触发监听失去下属
			if inst and inst.branch then
				inst.branch = inst.branch - 1
			end
		end)
	end
end

--召唤下属(本体/对象/范围/监听/方案)
function SpawnBanner(inst,target,radius,numli)
	if numli and inst.branch then			--多体召唤
		if inst.branch < numli[2] then		--下属上限
			for i=1, numli[1] do			--生成次数
				SpawnItem(inst,target,radius,numli)
			end
		end
	end
end

local skli = {
	"横扫之刃","圣剑裁决","地狱业火","晶能射线","冰霜突刺","冰痕之印","粒子爆破","弯月突袭"
}

--ByLaoluFix 插入随机掉落武器和随机属性修改 2021-05-27----------------------------------
--声明和创建掉落武器物品表--------
local weaponnamelist ={"final_weapon"}
for i=1,5 do
	table.insert(weaponnamelist, "weapon10"..i)
	table.insert(weaponnamelist, "weapon20"..i)
	table.insert(weaponnamelist, "weapon30"..i)
	table.insert(weaponnamelist, "weapon40"..i)
	table.insert(weaponnamelist, "weapon50"..i)
	table.insert(weaponnamelist, "weapon60"..i)
	table.insert(weaponnamelist, "weapon70"..i)
end
-- for i=1,11 do
	-- local str = string.format("%03d",i)
	-- table.insert(weaponnamelist, "pweapon"..str)
-- end
----------------------------------
--创建武器结构表
local weaponconlist ={}
for i,v in pairs(weaponnamelist) do
	weaponconlist[v] = true
end

local function CreatPrefabAndUDP(inst)
	if inst.components and inst.components.rgwuqi then
		inst:set(math.random(100,500), math.random(1,4), 0, 1)--攻击力:随机值100-500,品阶:随机1-4,增幅值=0,系数=1
		
		local slotliNum = math.random(1,5)--随机开1-5孔
		for i=1,slotliNum do
			inst.components.rgwuqi:Untie()
		end
		-- inst.components.rgwuqi--可能为了兼容属性触发,需要初始化一次.
	end
end
--Fixend

--给予指定玩家指定物品
function GiveMaster(itemli,userid,gift)
	local master = nil
	for k,v in pairs(AllPlayers) do
		if v and v:IsValid() and v.userid == userid then
			master = v
			break
		end
	end
	if master then
		local inventory = master.components.inventory
		if inventory then
			if gift then
				local gift = SpawnPrefab("gift")
				local spawn_items = {}
				for i = 1,#itemli do
					local item = SpawnPrefab(itemli[i][1])
					spawn_items[i] = item
					if item.components.stackable then
						item.components.stackable.stacksize = itemli[i][2]
					end
					if itemli[i][3] then
						local rgwuqi = item.components.rgwuqi
						if rgwuqi.weapon then
							item:set(unpack(itemli[i][3]))	--重定义武器属性
							if itemli[i][4] then
								rgwuqi.skid = itemli[i][4]
								rgwuqi.skname = skli[itemli[i][4]]
							end
						end
						if rgwuqi.armor then
							item.defensive = 0.7
							rgwuqi.armor.absorb_percent = item.defensive
						end
					end
					item:Remove()
				end
				gift.components.unwrappable:WrapItems(spawn_items)
				inventory:GiveItem(gift)
			else
				for k,v in pairs(itemli) do
					-- inventory:GiveItem(SpawnPrefab(v))--soucecode
					--ByLaoluFix
					-- if type(v) == string then
						local Itemobj = SpawnPrefab(v)
						if Itemobj and weaponconlist[Itemobj.prefab] then--处理属性
							CreatPrefabAndUDP(Itemobj)
						end
						inventory:GiveItem(Itemobj)
					-- end
					--Fix end
				end
			end
		end
	end
end

--判断是否增强
function GetBoost(inst, num)
	local revive = inst.revive
	if revive == 0.5 then
		revive = 0
	elseif revive == 1.5 then
		revive = 1
	end
	if revive then
		if revive == num then
			return true
		else
			return false
		end
	end
	if TUNING.RG_BOSSSTRENGTH == num then
		return true
	end
	return false
end
--掉落表
local dropli = {

	[0] = {
		{ "rg_giftbag003",1 },		--神话灵剑
		{ "er_sundries013", 1 }, --妖灵之心
		{ "purplegem",1 },		--紫宝石
		{ "greengem", 1 },		--绿宝石
		{ "orangegem",1 },		--橙宝石
		{ "yellowgem",1 },		--黄宝石
		{ "opalpreciousgem",1 },--彩石
	},
	[0.5] = {
		{ "rg_giftbag004",1 },		--神话灵剑
		{ "er_sundries014",1 },		--紫漓花
		{ "purplegem",3 },		--紫宝石
		{ "greengem", 3 },		--绿宝石
		{ "orangegem",3 },		--橙宝石
		{ "yellowgem",3 },		--黄宝石
		{ "opalpreciousgem",3 },--彩石
	},
	[1] = {
		{ "rg_giftbag004",1 },		--神话灵剑
		{ "er_sundries015",1 },		--玲珑玉
		{ "purplegem",5 },		--紫宝石
		{ "greengem", 5 },		--绿宝石
		{ "orangegem",5 },		--橙宝石
		{ "yellowgem",5 },		--黄宝石
		{ "opalpreciousgem",5 },--彩石
	},
	[1.5] = {
		{ "rg_giftbag005",1 },		--神话灵剑
		{ "er_sundries016",1 },		--炎阳纹章
		{ "purplegem",10 },		--紫宝石
		{ "greengem", 10 },		--绿宝石
		{ "orangegem",10 },		--橙宝石
		{ "yellowgem",10 },		--黄宝石
		{ "opalpreciousgem",10 },--彩石
	},
	[2] = {
		{ "rg_giftbag006",1 },		--神话灵剑
		{ "er_sundries017",1 },		--火龙精粹
		{ "purplegem",20 },		--紫宝石
		{ "greengem", 20 },		--绿宝石
		{ "orangegem",20 },		--橙宝石
		{ "yellowgem",20 },		--黄宝石
		{ "opalpreciousgem",20 },--彩石
	},


--[[
	[0] = {
		{"rg_helmet001",1,{100,4,0,0,0},1},	--物品 个数 属性 技能id
		{"rg_armor002",1,{100,4,0,0,0}},
	},
	[0.5] = {
		{"ice",1},
		{"ice",1},
	},
	[1] = {
		{"rg_helmet001",1,{100,4,0,0,0},1},
		{"rg_armor002",1,{100,4,0,0,0}},
	},
	[1.5] = {
		{"rg_helmet001",1,{100,4,0,0,0},1},
		{"rg_armor002",1,{100,4,0,0,0}},
	},
	[2] = {
		{"pweapon010",1,{100,4,0,0,0},1},
		{"rg_armor002",1,{100,4,0,0,0}},
	},
	]]
}
function DoBoost(inst)
	inst:DoTaskInTime(1, function()
		local x,y,z = inst.Transform:GetWorldPosition()
		if inst.revive then
			if inst.canrevive and inst.revive < 2 then			--可复活且未达到上限
				local boss = SpawnPrefab(inst.prefab)
				boss.Transform:SetPosition(x,y,z)
				boss.components.health:SetMaxHealth(inst.components.health.maxhealth*4)
				boss.components.combat.defaultdamage  = inst.components.combat.defaultdamage * 2

				boss.canrevive = true
				boss.master = inst.master
				boss.revive = inst.revive + 0.5
				boss:DoTaskInTime(600, function()
					boss.canrevive = nil			--不可复活
					boss.components.health:Kill()
				end)
			elseif inst.revive == 2 then								--掉落最高级别物品
				GiveMaster(dropli[2],inst.master,true)
			elseif inst.canrevive==nil and inst.revive-0.5>=0 then	--不可复活且有上级掉落
				GiveMaster(dropli[inst.revive-0.5],inst.master,true)
			end
		else
			inst.components.lootdropper:DropLoot(Vector3(x,y,z))
		end
	end)
end