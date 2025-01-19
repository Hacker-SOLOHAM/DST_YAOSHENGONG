
--TUNING.DRAGONFLY_HEALTH = 10000
--TUNING.WORM_DAMAGE = 33
--所属模块:怪物
TUNING.RG_GWLEVEL = GetModConfigData("rg_gwlevel")				--设置怪物强化等级
local variation = GetModConfigData("rg_variation")
TUNING.RG_VARIATION = {		--设置怪物变异权重
	[0] = variation[1],
	[1] = variation[2],
	[2] = variation[3],
	[3] = variation[4],
	[4] = variation[5]
}
TUNING.RG_BOSS = GetModConfigData("rg_boss")					--设置是否世界刷新boss
TUNING.RG_BOSSSTRENGTH = GetModConfigData("rg_bossstrength")	--设置boss强度
local worldname = GetModConfigData("worldname")					--世界名称

if not TheNet:GetIsServer() then
    return
end
--小型生物
local small = {
	"spider",				--蜘蛛		100		
	"spider_moon",			--破碎蜘蛛	250		
	"spider_dropper",		--悬居蜘蛛	400		
	"spider_spitter",		--喷射蜘蛛	350		
	"spider_hider",			--洞穴蜘蛛	225		
	"spider_warrior",		--蜘蛛战士	400		
	"knight",				--骑士	900		
	"rook",					--战车	900		
	"bishop",				--主教	900		
	"knight_nightmare",		--损坏的骑士  900	
	"bishop_nightmare",		--损坏的主教  900
	"rook_nightmare",		--损坏的战车  900
	"walrus",				--海象	300		33
--	"icehound",				--冰狗	100		30
	"firehound",			--火狗	100		30
	"hound",				--猎犬	150		25
	"krampus",				--坎普斯300		50
	"squid",				--乌贼	170		
	"bat",					--蝙蝠	50		20
	"tentacle",				--触手	500		34
	"crawlingnightmare",	--爬行梦魇 300		
	"nightmarebeak",		--梦魇尖嘴 400
	"lavae",				--岩浆虫 400
	"mossling",				--小鸭子
	
	"slurtle",				--蜗牛
	
	"beefalo",				--牛	
	"lightninggoat",		--羊		
	"koalefant_summer",		--大象
	"koalefant_winter",		--大象
	"rocky",				--石虾
	
	"merm",					--鱼人
	"pigguard",				--猪人守卫	500	
	"stalker",				--复活的骨架
	
	"fruitdragon",			--螈蝾

}

--中型生物
local middle = {"spat","warg","spiderqueen","leif_sparse","leif","worm",}

--BOSS
local boss = {"deerclops","bearger","dragonfly","moose","minotaur","beequeen","antlion","toadstool","toadstool_dark","klaus","stalker_atrium",}

--无强化生物
local other = {"rg_kulou001","rg_kulou002","er_boss001","er_boss002","er_boss003"}

--小怪 掉落物品设置
local smalllootdrop = {

	[1] = {		--精灵级
		[1] ={"thulecite","er_sundries009",},						--铥矿	经验药水小					--必掉物品 到地上
		[2] ={"er_sundries006","er_sundries012",},					--金币小	魔晶				--随机物品 到个人背包
		[3] ={"rg_armor001","rg_armor002","rg_armor003","rg_helmet001","rg_helmet002","rg_helmet003"},	--随机盔甲
	},
	[2] = {		--妖精级
		[1] ={"thulecite","er_sundries009",},						--铥矿	经验药水小					--必掉物品 到地上
		[2] ={"er_sundries006","er_sundries012","er_sundries009",},	--金币小	魔晶	经验药水小	--随机物品 到个人背包
		[3] ={"rg_armor001","rg_armor002","rg_armor003","rg_helmet001","rg_helmet002","rg_helmet003"},	--随机盔甲
	},
	[3] = {		--妖王级
		[1] ={"thulecite","er_sundries010",},						--铥矿	经验药水大		
		[2] ={"er_sundries007","er_mould1","er_drawing001","opalpreciousgem",},		--金币小	核心1	图纸1			--随机物品 到个人背包
		[3] ={"rg_armor001","rg_armor002","rg_armor003","rg_helmet001","rg_helmet002","rg_helmet003"},
	},
	[4] = {		--魔王级
		[1] ={"thulecite","er_sundries010","opalpreciousgem",},						--铥矿	经验药水大	
		[2] ={"er_sundries007","er_mould1","er_drawing001","er_sundries036","er_sundries037","opalpreciousgem",},	--金币小 核心1 图纸1 武器强化石 护甲强化石
		[3] ={"rg_armor001","rg_armor013","rg_armor009","rg_helmet010","rg_helmet012","rg_helmet013"},
	},
	
}

--中型怪 掉落物品设置
local middlelootdrop = {
	[1] = {		--精灵级
		[1] ={"thulecite","er_sundries009",},						--铥矿	经验药水大					--必掉物品 到地上
		[2] ={"er_sundries006","er_sundries012",},					--金币小	魔晶				--随机物品 到个人背包
		[3] ={"rg_armor001","rg_armor002","rg_armor003","rg_helmet001","rg_helmet002","rg_helmet003"},
	},
	[2] = {		--妖精级
		[1] ={"thulecite","er_sundries010","opalpreciousgem",},						--铥矿	经验药水大
		[2] ={"er_sundries007","er_sundries010","er_sundries012","opalpreciousgem",},	--金币中	经验药水大	魔晶	--随机物品 到个人背包
		[3] ={"rg_armor001","rg_armor013","rg_armor009","rg_helmet010","rg_helmet012","rg_helmet013"},
	},
	[3] = {		--妖王级
		[1] ={"thulecite","er_sundries010","opalpreciousgem",},						--铥矿	经验药水大
		[2] ={"er_sundries007","er_mould1","er_drawing001","opalpreciousgem",},		--金币中	核心1	图纸1			--随机物品 到个人背包
		[3] ={"rg_armor008","rg_armor011","rg_armor012","rg_helmet008","rg_helmet009","rg_helmet011"},
	},
	[4] = {		--魔王级
		[1] ={"thulecite","er_sundries010","er_sundries036","er_sundries037","opalpreciousgem",},							--铥矿	经验药水大 武器强化石 护甲强化石
		[2] ={"er_sundries007","er_mould1","er_drawing001","er_sundries036","er_sundries037","opalpreciousgem",},			--金币小 核心1 图纸1 武器强化石 护甲强化石
		[3] ={"rg_armor008","rg_armor011","rg_armor012","rg_helmet008","rg_helmet009","rg_helmet011"},
	},
}

--boss 掉落物品设置
local bosslootdrop = {
	[1] = {		--精灵级
		[1] ={"er_sundries037","opalpreciousgem","er_sundries036","opalpreciousgem",}, 	--护甲强化石 武器强化石 妖灵之心
		[2] ={"er_mould1","er_drawing001","er_sundries036","er_sundries037","opalpreciousgem","opalpreciousgem",},		-- 核心1 图纸1 武器强化石 护甲强化石 妖灵之心
		[3] ={"rg_armor001","rg_armor002","rg_armor003","rg_helmet001","rg_helmet002","rg_helmet003"},
	},
	[2] = {		--妖精级
		[1] ={"er_sundries037","opalpreciousgem","er_sundries036","opalpreciousgem",}, 	--护甲强化石 武器强化石 紫漓花
		[2] ={"er_mould2","er_drawing002","er_sundries036","er_sundries037","opalpreciousgem","opalpreciousgem",},		-- 核心2 图纸2 武器强化石 护甲强化石 紫漓花
		[3] ={"rg_armor001","rg_armor002","rg_armor003","rg_helmet001","rg_helmet002","rg_helmet003"},
	},
	[3] = {		--妖王级
		[1] ={"er_sundries037","opalpreciousgem","er_sundries036","opalpreciousgem",}, 	--护甲强化石 武器强化石 玲珑玉
		[2] ={"er_mould3","er_drawing003","er_sundries036","er_sundries037","opalpreciousgem","opalpreciousgem",},		-- 核心3 图纸3 武器强化石 护甲强化石 玲珑玉
		[3] ={"rg_armor005","rg_armor006","rg_armor007","rg_helmet005","rg_helmet006","rg_helmet007"},
	},
	[4] = {		--魔王级
		[1] ={"er_sundries037","opalpreciousgem","er_sundries036","opalpreciousgem",}, 	--护甲强化石 武器强化石 炎阳纹章
		[2] ={"er_mould3","er_drawing003","er_sundries036","er_sundries037","opalpreciousgem","opalpreciousgem",},		-- 核心3 图纸3 武器强化石 护甲强化石 炎阳纹章
		[3] ={"rg_armor005","rg_helmet005"},
	},
}
--ByLaolufix 2021-05-27
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
--定制武器不在之内
-- for i=1,10 do
	-- local str = string.format("%03d",i)
	-- table.insert(weaponnamelist, "pweapon"..str)
-- end

--添加到原有掉落设置表中
for i=1,2 do
	for k,v in pairs(weaponnamelist) do
		table.insert(bosslootdrop[i][2], v)
	end
end
--Fixend

--使用列表
local useli = {
	{		--世界掉落倍率
		["1"] = 10,
		["2"] = 2,
		["3"] = 3,
	},{		--金币袋
		["er_sundries006"] = true,
		["er_sundries007"] = true,
		["er_sundries008"] = true
	}
}
--通过id获取当前世界玩家
local function GetTheWorldPlayerById(id)
    for _,p in pairs(AllPlayers) do
        if p.userid == id then 
            return p
        end
    end
	return nil
end
local GUAIWU_BEILV = 0.0175	--怪物经验总生命值折算经验的倍率---原来是0.07
--怪物死亡
local function death(inst)
	-- local health = inst.components.health	--这里有严重问题
	-- if health:IsDead() then 					--这里有严重问题
	-- ByLaolufix 2021-01-01
	if inst and inst.components and inst.components.health and inst.components.health:IsDead() then
	--FixEnd
		local rg_guaiwu = inst.components.rg_guaiwu
		local allexp = inst.components.health.maxhealth*GUAIWU_BEILV	--总经验
		local alldamage = 1						--总伤害
		local players = {}
		
		--伤害累加
		for k,v in pairs(rg_guaiwu.attackers) do
			alldamage = alldamage + v
			table.insert(players,{damage = v,userid = k})
		end
		--按照伤害排序(由大到小)
		table.sort(players,function(a,b)
			return a.damage > b.damage
		end)
		
		--排行打印
		-- for k, v in pairs(players) do
			-- print("伤害第"..k.."名",v.damage)
			-- print("玩家id",v.userid)
		-- end

		local wrank = useli[1][TheShard:GetShardId()] or 1
		--给战利品
		local function GiveSpoils(itemlists,master)
			--物品列表无内容退出
			if next(itemlists) == nil then
				return
			end
			if master then
				for i = 1, wrank do
					GiveMaster(itemlists,master)
				end
			else
				--如果输出排行有数据
				if #players > 0 then
					local userid = players[1].userid	--获取输出排行第一的玩家id
					for i = 1, wrank do
						GiveMaster(itemlists,userid)
					end
				end
			end
		end
		--[[
		--经验分配
		for k2,v2 in pairs(rg_guaiwu.attackers) do
			--获取伤害占比
			local share = v2 / alldamage
			for k,v in pairs(AllPlayers) do
				if v and v:IsValid() and v.userid == k2 then
					-- print("玩家"..k2.."获得"..math.floor(allexp*share + 0.5).."点经验")
					v.components.er_leave:DoPromote(math.floor(allexp*share + 0.5) * v.drugexpup)
				end
			end
		end
		]]
		
		----------------------------------------------------------------------------------------------------
		--ByLaoluFix 2021-09-17 重构经验分配
		local G_Queue = _G.G_Queue
		local oldtbl = rg_guaiwu.attackers	--结算玩家获取的经验值
		local newtbl = {}		--缓存玩家的经验值
		local Allps = {}		--当前世界所有玩家表
		local duilie = {}
		if next(rg_guaiwu.attackers) ~=nil then
			--在当前世界索引玩家,并计算小队总经验值
			for i,v in pairs(AllPlayers) do
				if v and not v:HasTag("playerghost") then--排除死亡的玩家
					Allps[v.userid] = v
					local exp = oldtbl[v.userid] or 0	--获取玩家击杀的经验值
					local dui_id = G_Queue["curworld"][v.userid]--找玩家属于的小队
					if not dui_id then --玩家没队伍
						--执行老的经验分配
						for k2,v2 in pairs(rg_guaiwu.attackers) do
							--获取伤害占比
							local share = v2 / alldamage
							if v and v:IsValid() and v.userid == k2 then
								print(allexp,share,v2,alldamage)--10	0.99067599067599	106.25 107.25
								-- TheNet:Announce("玩家1:"..(v:GetDisplayName() or "未知玩家").."   获得:"..math.floor(allexp*share + 0.5).."点经验")--7
								-- print("玩家"..k2.."获得"..math.floor(allexp*share + 0.5).."点经验")
								v.components.er_leave:DoPromote(math.floor(allexp*share + 0.5) * (v.drugexpup or 1))
								break
							end
						end
					else
						--初始化小队经验
						if not duilie[dui_id] then
							duilie[dui_id] = 0
						end
						duilie[dui_id] = duilie[dui_id] + math.floor((exp/ alldamage*allexp +0.5)* (v.drugexpup or 1))
					end
					newtbl[v.userid] = oldtbl[v.userid] or 0
				end
			end
			
			--DEBUG
			-- TheNet:Announce("")
			
			--结算经验值
			for k,v in pairs(duilie) do
				if G_Queue["xiaodui"][k] then
					--平均分配经验------------------------------------------
					--小队经验值*小队人数*0.2
					-- local guaiwuEXP = v * GUAIWU_BEILV
					local zebv = v * (1 + ( #G_Queue["xiaodui"][k] - 1 )*0.05 )----太高了，带小号 原先数据为0.2
					--小队经验值*小队人数*0.2 / 小队人数
					local exp = math.ceil(zebv / #G_Queue["xiaodui"][k])
					--------------------------------------------------------
					--分配小队成员经验值
					for k1,v1 in pairs(G_Queue["xiaodui"][k]) do
						local exptarget = Allps[v1]
						if exptarget and exptarget:IsValid() then
							--执行新的经验分配
							-- print(v,zebv,exp)
							local plname = exptarget:GetDisplayName() or "未知玩家"
							-- TheNet:Announce("玩家2:"..plname.."   获得:"..math.floor(exp + 0.5)* (exptarget.drugexpup or 1).."点经验")
							exptarget.components.er_leave:DoPromote(math.floor(exp + 0.5) * (exptarget.drugexpup or 1))
						end
					end
				end
			end
			rg_guaiwu.attackers ={}
		end
		--Fix end
		----------------------------------------------------------------------------------------------------
		
		--掉落方式
		local function dropfn(inst,list,key,mathnum,defnum)	--实体/掉落列表/key/随机数/护甲值
			if list then
				local itemlists = {}
				local lootdropper = inst.components.lootdropper
				if key == 1 then		--必定掉落
					if inst.master then			--属于有主怪物
						for i,v in ipairs(list) do
							if useli[2][v] and inst.goldbagup then
								itemlists[#list+1] = list[i]	--额外掉落金币处理(仅限于一次)
							end
							itemlists[i] = list[i]
						end
						GiveSpoils(itemlists,inst.master)
					else
						for i,v in ipairs(list) do
							if useli[2][v] and inst.goldbagup then
								lootdropper:SpawnLootPrefab(v, inst:GetPosition())
							end
							lootdropper:SpawnLootPrefab(v, inst:GetPosition())
						end
					end
				elseif key == 2 then	--随机掉落
					for k =1, #list do
						if math.random() < mathnum then		--每件物品概率掉落:
							itemlists[k] = list[k]
						end
					end
					GiveSpoils(itemlists)
				elseif key == 3 then	--盔甲掉落
					if math.random() < 0.05 * mathnum then		--爆率为怪物级别*0.01(PS：随怪物品质上升),即1%~4%概率
						local item = list[math.random(#list)]	--获取甲类型
						local armor = lootdropper:SpawnLootPrefab(item, inst:GetPosition())
						armor.defensive = defnum	--设定防御力
						armor.components.armor.absorb_percent = defnum
					end
				end
			end
		end
		
		if inst:HasTag("rg_guaiwu_up") then
			--掉落设定
			if rg_guaiwu then
				local rank = rg_guaiwu.rank

				--自定义掉落
				if rg_guaiwu.monstertype == 1 then		--小型怪
					if smalllootdrop[rank] ~= nil then
						local items1 = smalllootdrop[rank][1]
						dropfn(inst,items1,1)
						local items2 = smalllootdrop[rank][2]
						dropfn(inst,items2,2,0.2)
					end
				elseif rg_guaiwu.monstertype == 2 then  --中型怪
					if middlelootdrop[rank] ~= nil then
						local items1 = middlelootdrop[rank][1]
						dropfn(inst,items1,1)
						local items2 = middlelootdrop[rank][2]
						dropfn(inst,items2,2,0.3)
						local items3 = middlelootdrop[rank][3]
						local defnum = 0.65 + 0.01* math.random(-5,5)	--随机护甲(护甲值在5%上下浮动 PS：随怪物品质上升)
						dropfn(inst,items3,3,rank,defnum)
					end
				elseif rg_guaiwu.monstertype == 3 then	--boss
					if bosslootdrop[rank] ~= nil then
						local items1 = bosslootdrop[rank][1]
						dropfn(inst,items1,1)--必定掉落
						local items2 = bosslootdrop[rank][2]
						dropfn(inst,items2,2,0.01*rank)--随机掉落--1%~4%概率
						local items3 = bosslootdrop[rank][3]
						local defnum = 0.40 + rank*0.1 + 0.01*math.random(-5,10)
						dropfn(inst,items3,3,rank,defnum)--盔甲掉落
					end
				end
			end
		end
	end
end

--受击不僵直
local function onattacked(sg)
	local old_hit = sg.events['attacked']
	if old_hit then
		sg.events['attacked'] = EventHandler('attacked', function(inst,data,...)
			if inst:HasTag("rg_guaiwu_up") then
				return
			end		
			old_hit.fn(inst,data,...)
		end)
	end
end

for k,v in pairs(small) do
	AddPrefabPostInit(v, function(inst)
		inst:AddComponent("rg_guaiwu")
		inst.components.rg_guaiwu.monstertype = 1
		inst.components.rg_guaiwu:Suiji()
		--ByLaoluFix 2021-09-12 与怪物祭坛的创建冲突,叠加了计算,这里修复处理
		inst.components.rg_guaiwu.isseting = true
		inst:ListenForEvent("onremove", death)
	end)

	AddStategraphPostInit(v, function(sg)
		onattacked(sg)
	end)
end

for k,v in pairs(middle) do
	AddPrefabPostInit(v, function(inst)
		inst:AddComponent("rg_guaiwu")
		inst.components.rg_guaiwu.monstertype = 2
		inst.components.rg_guaiwu:Suiji()
		--ByLaoluFix 2021-09-12 与怪物祭坛的创建冲突,叠加了计算,这里修复处理
		inst.components.rg_guaiwu.isseting = true
		inst:ListenForEvent("onremove", death)
	end)
	AddStategraphPostInit(v, function(sg)
		onattacked(sg)
	end)
end

for k,v in pairs(boss) do
	AddPrefabPostInit(v, function(inst)
		inst:AddComponent("rg_guaiwu")
		inst.components.rg_guaiwu.monstertype = 3		
		inst.components.rg_guaiwu:Suiji()
		--ByLaoluFix 2021-09-12 与怪物祭坛的创建冲突,叠加了计算,这里修复处理
		inst.components.rg_guaiwu.isseting = true
		inst:ListenForEvent("onremove", death)
	end)
	AddStategraphPostInit(v, function(sg)
		onattacked(sg)
	end)
end

--特殊怪物
for k,v in pairs(other) do
	AddPrefabPostInit(v, function(inst)
		inst:AddTag("er_monster")
		inst:AddComponent("rg_guaiwu")
		inst:ListenForEvent("onremove", death)
	end)	
end

--修改部分组件为了实现某些功能
AddPlayerPostInit(function(inst)
	inst:AddComponent("rg_buff")
	--攻击miss
	if inst.components.combat then
		local old_DoAttack = inst.components.combat.DoAttack
		inst.components.combat.DoAttack = function(self,targ, ...)
			if self.inst.components.rg_buff and self.inst.components.rg_buff:HasDeBuff("rg_debuff_miss") then
				return
			end
			old_DoAttack(self,targ, ...)
		end
	end
	--锁血
	if inst.components.health then
		local old_DoDelta = inst.components.health.DoDelta
		inst.components.health.DoDelta = function(self,amount, ...)
			if self.inst.components.rg_buff and self.inst.components.rg_buff:HasDeBuff("rg_debuff_suoxue") then
				if amount > 0 then 
					amount = 0
				end
			end
			old_DoDelta(self,amount, ...)
		end
	end
end)

AddComponentPostInit("combat", function(self,inst)
	self.lr_SetTarget = self.SetTarget
	function self:SetTarget(target)
		if not self.inst:IsValid() then
			return false
		end
		if target and target:HasTag("rg_guaiwu") and self.inst:HasTag("rg_guaiwu") then
			return false
		end

		if self.lr_SetTarget then
			return self:lr_SetTarget(target)
		end
	end
	
	self.lr_DoAttack = self.DoAttack
	function self:DoAttack(target_override, weapon, projectile, stimuli, instancemult)
		local targ = target_override or self.target
		if target and target:HasTag("rg_guaiwu") and self.inst:HasTag("rg_guaiwu") then
			return false
		end

		if self.lr_DoAttack then
			return self:lr_DoAttack(target_override, weapon, projectile, stimuli, instancemult)
		end
	end
	
	self.lr_GetAttacked = self.GetAttacked
	function self:GetAttacked(attacker, damage, weapon, stimuli)
		if attacker and attacker:HasTag("rg_guaiwu") and self.inst:HasTag("rg_guaiwu") then
			return false
		end
		if self.lr_GetAttacked then
			local health = self.inst.components.health
			if health and not health:IsDead() then
				return self:lr_GetAttacked(attacker, damage, weapon, stimuli)
			end
		end
	end
end)

--巨鹿
AddPrefabPostInit("deerclops", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end
	--计时器修复 ByLaolu 2020-11-27
	if inst.components.timer == nil then inst:AddComponent("timer") end
	inst.skill_cd = 10
	local loot = {	"meat","meat","meat","meat","meat","meat","deerclops_eyeball"	}
	AddLootItems(loot, {
		--		{	item = "mandrake_planted",				chance = 1,		},
		{	item = "chesspiece_deerclops_sketch",	chance = 0.1,	},
	})
	AddLootChestItems(loot)					--添加战利品箱物品
	inst.components.lootdropper:SetLoot(loot)
	--发作周期 2
	AddAnger(inst, 0.2, 2, true, function (inst, oldAtkPre)
		if inst.anger then
			inst.skill_cd = 5	--暴怒时技能CD
		else
			inst.skill_cd = 10	--技能CD
		end
	end)
	--不攻击属下
	inst.components.combat.notags = {"moose", "mossling","deerclops","bearger","dragonfly","beequeen","monster","chess"}
end)

--熊獾
AddPrefabPostInit("bearger", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end
	--计时器修复 ByLaolu 2020-11-27
	if inst.components.timer == nil then inst:AddComponent("timer") end
	
	inst.skill_cd = 5
	local loot = {"meat", "meat", "meat", "meat", "meat", "meat", "bearger_fur"}
	AddLootItems(loot, {
		{	item = "chesspiece_bearger_sketch",		chance = 0.1,	},
--		{	item = "mandrake", 						chance = 0.33,	},
	})
	AddLootChestItems(loot)
	inst.components.lootdropper:SetLoot(loot)
	AddAnger(inst, 0.2, 2, true, function (inst, oldAtkPre)
		if inst.anger then
			inst.skill_cd = 4
		else
			inst.skill_cd = 8
		end
	end)
	
	local upscale = 0.1									--暴怒攻击力成长系数
	local combat = inst.components.combat
	--属性重构
	if GetBoost(inst,2) then
		upscale = 0.3
		combat.damagemultiplier = 2
	end
	
	inst:DoPeriodicTask(60, function(inst)
		local x, y, z = inst.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x, 0, z, 25, {"player"})
		if #ents > 0 then
			combat.defaultdamage = combat.defaultdamage * (1 + upscale)
			TheNet:Announce(" ★ "..worldname.." ★ 的【熊獾】发怒了，攻击力成长".. upscale*100 .."%,请尽快击杀!")
		end
	end)
	
	inst.components.combat.notags = {"moose", "mossling","deerclops","bearger","dragonfly","beequeen","monster","chess"}
end)

--龙蝇
AddPrefabPostInit("dragonfly", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end
	--计时器修复 ByLaolu 2020-11-27
	if inst.components.timer == nil then inst:AddComponent("timer") end
	inst.skill_cd = 15
	local loot = {"meat", "meat", "meat", "meat", "meat", "meat", "meat", "meat", "dragon_scales"}
	AddLootItems(loot, {
	{	item = "chesspiece_dragonfly_sketch",		chance = 0.05,	},
	{	item = "dragonflyfurnace_blueprint",		chance = 1,		},
	{	item = "lavae_egg",							chance = 0.33,	},
	{	item = "redgem", 			count = 2,		chance = 1,		},
	{	item = "bluegem",			count = 2,		chance = 1,		},
	{	item = "purplegem",							chance = 1,		},
	{	item = "orangegem",							chance = 1,		},
	{	item = "yellowgem",							chance = 1,		},
	{	item = "greengem",							chance = 1,		},
	{	item = "purplegem",							chance = 0.5,	},
	{	item = "orangegem",							chance = 0.5,	},
	{	item = "yellowgem",							chance = 0.5,	},
	{	item = "greengem",							chance = 0.5,	},
	})
	AddLootChestItems(loot)
	inst.components.lootdropper:SetLoot(loot)
	
	local combat = inst.components.combat
	local walkspeed = 7									--龙蝇移速
	local attackperiod = 3								--龙蝇攻击周期
	local upscale = 0.1									--暴怒攻击力成长系数
	
	--属性重构
	if GetBoost(inst,2) then
		--免疫睡眠
		inst.components.sleeper.AddSleepiness = function()
			return
		end
		walkspeed = 9
		attackperiod = 2
		upscale = 0.3
		combat.damagemultiplier = 2
		inst.components.health:SetMaxHealth(TUNING.DRAGONFLY_HEALTH * 1.5)
		-- inst.components.health:SetAbsorptionAmount(1)
	end
	
	inst.components.locomotor.walkspeed = walkspeed		--设定移速
	combat:SetAttackPeriod(attackperiod)				--设定周期
	
	inst:DoPeriodicTask(60, function(inst)
		local x, y, z = inst.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x, 0, z, 25, {"player"})
		if #ents > 0 and not inst:HasTag("tooanger") then
			--触发暴怒
			inst:PushEvent("transform", { transformstate = "fire" })
		end
	end)
	
	AddAnger(inst, 0.2, 2, true, function(inst, oldAtkPre)
		if inst.anger then
			inst.skill_cd = 10
		else
			inst.skill_cd = 15
		end
	end)
	
	--暴怒状态
	inst.TransformFire = function(inst)
		inst:AddTag("tooanger")
		inst.AnimState:SetBuild(IsSpecialEventActive(SPECIAL_EVENTS.WINTERS_FEAST) and "dragonfly_fire_yule_build" or "dragonfly_fire_build")
		inst.enraged = true
		inst.can_ground_pound = true
		
		inst.components.locomotor.walkspeed = walkspeed
		combat:SetAttackPeriod(attackperiod-1)
		combat.defaultdamage = combat.defaultdamage * (1 + upscale)
		TheNet:Announce(" ★ "..worldname.." ★ 的【龙蝇】发怒了，攻击力成长".. upscale*100 .."%,请尽快击杀!")
		combat:SetRange(4, 6)

		inst.Light:Enable(true)
		inst.components.propagator:StartSpreading()
		inst.components.moisture:DoDelta(-inst.components.moisture:GetMoisture())
		inst.components.freezable:SetResistance(1000)	--冰冻免疫
		if inst.reverttask then
			inst.reverttask:Cancel()
			inst.reverttask = nil
		end
		inst.reverttask = inst:DoTaskInTime(30, function(inst)	--龙蝇怒火持续时间
			inst.reverttask = nil
			if inst.enraged then 
				inst:PushEvent("transform", { transformstate = "normal" })
			end
		end)
	end
	
	--正常状态
    inst.TransformNormal = function(inst)
		inst:RemoveTag("tooanger")
		inst.AnimState:SetBuild(IsSpecialEventActive(SPECIAL_EVENTS.WINTERS_FEAST) and "dragonfly_yule_build" or "dragonfly_build")
		inst.enraged = false
		inst.components.locomotor.walkspeed = walkspeed - 2
		combat:SetAttackPeriod(attackperiod)
		combat:SetRange(4, 5)

		inst.components.freezable:SetResistance(12)

		inst.components.propagator:StopSpreading()
		inst.Light:Enable(false)
	end
	
	combat.notags = {"moose", "mossling","deerclops","bearger","dragonfly","beequeen","monster","chess"}
end)

--岩浆虫
AddPrefabPostInit("lavae", function(inst)
	inst.components.health:SetInvincible(true)
	inst:DoTaskInTime(60, inst.Remove)
	inst:RemoveComponent("freezable")
end)

--麋鹿鹅
AddPrefabPostInit("moose", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end
	--计时器修复 ByLaolu 2020-11-27
	if inst.components.timer == nil then inst:AddComponent("timer") end
	inst.skill_cd = 15
	local loot = {"meat", "meat", "meat", "meat", "meat", "goose_feather", "goose_feather"}
	AddLootItems(loot, {
		{item = "chesspiece_moosegoose_sketch",	chance = 0.01,	},
	})
	AddLootChestItems(loot)
	inst.components.lootdropper:SetLoot(loot)
	AddAnger(inst, 0.2, 2, true, function (inst, oldAtkPre)
		if inst.anger then
			inst.skill_cd = 10
			inst.sg:GoToState("layegg")
		else
			inst.skill_cd = 15
		end
	end)
	
	local upscale = 0.1									--暴怒攻击力成长系数
	local combat = inst.components.combat
	--属性重构
	if GetBoost(inst,2) then
		upscale = 0.3
		combat.damagemultiplier = 2
	end
	
	inst:DoPeriodicTask(60, function(inst)
		local x, y, z = inst.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x, 0, z, 25, {"player"})
		if #ents > 0 then
			combat.defaultdamage = combat.defaultdamage * (1 + upscale)
			TheNet:Announce(" ★ "..worldname.." ★ 的【麋鹿鹅】发怒了，攻击力成长".. upscale*100 .."%,请尽快击杀!")
		end
	end)
	
	inst.components.burnable.lightningimmune = true		-- 免疫雷电
	combat.notags = {"moose", "mossling","deerclops","bearger","dragonfly","beequeen","monster","chess"}
end)

-- 鸭蛋
AddPrefabPostInit("mooseegg", function(inst)
	inst.powerup = true
	
	local function OnLightning(inst, data)
		if not inst.EggHatched then
			if inst.sg:HasStateTag("egg") then
				inst.sg:GoToState("crack")
			end
		end
	end

	inst:ListenForEvent("attacked", function(inst, data)
		inst.components.combat:ShareTarget(data.attacker, 30, function (dude) 
			return dude:HasTag("moose") 
		end, 10)
	end)
	inst.lightningpriority = 2		-- 吸引雷电优先级
	inst:ListenForEvent("lightningstrike", OnLightning)
end)

-- 小鸭子
AddPrefabPostInit("mossling", function(inst)
	inst.powerup = true
	
	local SEE_DIST = 40
	local TARGET_DIST = 6
	local function RetargetFn(inst)
		return FindEntity(inst, TARGET_DIST, function (guy)
			return inst.components.combat:CanTarget(guy)
		end,
		nil,
		{ "prey", "smallcreature", "mossling", "moose" },
		{ "monster", "player"})
	end
	
	inst.components.combat:SetRetargetFunction(1.5, RetargetFn)
	inst.components.combat.notags = {"moose", "mossling","deerclops","bearger","dragonfly","beequeen","monster","chess"}	-- 不攻击同类
	local old_CreateHerd = inst.components.herdmember.CreateHerd
	function inst.components.herdmember:CreateHerd()
		if self.enabled and not self.herd then
			local findEgg = FindEntity(inst, SEE_DIST, function (guy)
				return guy.prefab == "mooseegg"
			end,
			nil,
			{ "INLIMBO", "NOCLICK" })
			
			if findEgg ~= nil then
				inst.components.herdmember.herd = findEgg
			else
				old_CreateHerd(self)
			end
		end
	end
end)

--远古犀牛
AddPrefabPostInit("minotaur", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end
	--计时器修复 ByLaolu 2020-11-27
	if inst.components.timer == nil then inst:AddComponent("timer") end
	inst:AddComponent("groundpounder")
	inst.skill_cd = 15
	local loot = {"meat", "meat", "meat", "meat", "meat"}
	AddLootItems(loot, {
		{item = "chesspiece_moosegoose_sketch",	chance = 0.01,	},
		{item = "drumstick",	count = 2,		chance = 1,		},
		{item = "er_sundries021",	count = 2,		chance = 1,		},
	})
	AddLootChestItems(loot)
	inst.components.lootdropper:SetLoot(loot)
	AddAnger(inst, 0.2, 1, true, function (inst, oldAtkPre)
		if inst.anger then
			inst.skill_cd = 10
		else
			inst.skill_cd = 15
		end
	end)
	
	local upscale = 0.1									--暴怒攻击力成长系数
	local combat = inst.components.combat
	--属性重构
	if GetBoost(inst,2) then
		upscale = 0.3
		combat.damagemultiplier = 2
	end
	
	inst:DoPeriodicTask(60, function(inst)
		local x, y, z = inst.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x, 0, z, 25, {"player"})
		if #ents > 0 then
			combat.defaultdamage = combat.defaultdamage * (1 + upscale)
			TheNet:Announce(" ★ "..worldname.." ★ 的【远古犀牛】发怒了，攻击力成长".. upscale*100 .."%,请尽快击杀!")
		end
	end)
	
	combat.notags = {"moose", "mossling","deerclops","bearger","dragonfly","beequeen","monster","chess"}
end)

modimport "scripts/prefabs/rg_boss_master.lua"			--是否生成boss
-- modimport "scripts/prefabs/rg_pigking_master.lua"	--猪王定期刷怪
modimport "scripts/prefabs/rg_buffs_master.lua"			--预设物的服务端代码
modimport "scripts/prefabs/rg_attack_orb_master.lua"
modimport "scripts/prefabs/rg_kulou_master.lua"
modimport "scripts/actions/loots.lua"					--掉落
modimport "scripts/actions/anger.lua"					--怒气