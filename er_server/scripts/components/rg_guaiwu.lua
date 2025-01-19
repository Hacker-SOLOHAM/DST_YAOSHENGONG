--技能名
local skillsname = {"冰冻","汲取","雷击","击飞","禁锢","弹幕","减速","锁血"}

--技能池
local skill_lists = {
	[1] = function(attacker, target) --冰冻
		if target ~= nil then
			local x, y, z = target.Transform:GetWorldPosition()
			for i, v in ipairs(TheSim:FindEntities(x, 0, z, 8, {"freezable",}, {"playerghost", "INLIMBO"}))do
				if v:IsValid() and v ~= attacker and not (v.components.health ~= nil and v.components.health:IsDead()) then
					local monsters = TheSim:FindEntities(x, y, z, 5)
					attacker:DoTaskInTime(.1,function()
						local fx = SpawnPrefab("weapon_fx005")--冰冻特效
						fx.Transform:SetPosition(x,y,z)
					end)
					if v.components.freezable ~= nil then
						if v.components.freezable:IsFrozen() then
							v.components.freezable:AddColdness(.1, 1)
						else
							v.components.freezable:AddColdness(v.components.freezable:ResolveResistance())
							v.components.freezable:SpawnShatterFX()
						end
					end
                end
            end
			SpawnPrefab("er_tips_label"):set("<冻结>", 1).Transform:SetPosition(x,y,z)
		end
	end,
	[2] = function(attacker, target) --汲取
		if target:IsValid() and target.components.health ~= nil and not target.components.health:IsDead() then
			local diaoxue = target.components.health.currenthealth * 0.5 or 0
			target.components.health:DoDelta(-diaoxue,false,attacker.prefab)
			if attacker and target.components.health ~= nil and not target.components.health:IsDead() then
				attacker.components.health:DoDelta(diaoxue, false, attacker.prefab)
			end
			local x,y,z = target.Transform:GetWorldPosition()
			SpawnPrefab("er_tips_label"):set("<被吸血>", 1).Transform:SetPosition(x,y,z)
		end
	end,
	[3] = function(attacker, target) --雷击
		attacker:DoTaskInTime(.1, function()
			if target ~= nil then
				local x, y, z = target.Transform:GetWorldPosition()
				for i, v in ipairs(TheSim:FindEntities(x, 0, z, 8, {"player"}, {"playerghost", "INLIMBO"}))do
					if v:IsValid() and not (v.components.health ~= nil and v.components.health:IsDead()) then
						if v.sg then
							v.sg:GoToState("electrocute")
						end
						if v.components.health ~= nil and not v.components.health:IsDead() then
							local monsters = TheSim:FindEntities(x, y, z, 5)
							attacker:DoTaskInTime(.1,function()
								local fx = SpawnPrefab("lavaarena_creature_teleport_medium_fx")
									fx.Transform:SetPosition(x,y,z)
							end)
							v.components.health:DoDelta(-80, false, attacker.prefab)
						end
					end
				end
			end
		end)	
	end,
	[4] = function(attacker, target) --击飞
		if target ~= nil then
			local x, y, z = target.Transform:GetWorldPosition()
			for i, v in ipairs(TheSim:FindEntities(x, 0, z, 8, {"player"}, {"playerghost", "INLIMBO"}))do
				if v:IsValid() and not (v.components.health ~= nil and v.components.health:IsDead()) then
					v:PushEvent("knockback", {knocker = attacker, radius = 5})
                end
            end
			SpawnPrefab("er_tips_label"):set("<击飞>", 1).Transform:SetPosition(x,y,z)
		end
	end,
	[5] = function(attacker, target)--禁锢
		if target ~= nil and target:IsValid() then
			local x, y, z = target.Transform:GetWorldPosition()
			local islarge = target:HasTag("largecreature")
			local r = target:GetPhysicsRadius(0) + (islarge and 1.5 or .5)
			local num = islarge and 12 or 6
			local vars = { 1, 2, 3, 4, 5, 6, 7 }
			local used = {}
			local queued = {}
			local dtheta = PI * 2 / num
			local thetaoffset = math.random() * PI * 2
			local delaytoggle = 0
			local map = TheWorld.Map
			for theta = math.random() * dtheta, PI * 2, dtheta do
				local x1 = x + r * math.cos(theta)
				local z1 = z + r * math.sin(theta)
				if map:IsPassableAtPoint(x1, 0, z1) and not map:IsPointNearHole(Vector3(x1, 0, z1)) then
					local spike = SpawnPrefab("fossilspike")
					spike.Transform:SetPosition(x1, 0, z1)

					local delay = delaytoggle == 0 and 0 or .2 + delaytoggle * math.random() * .2
					delaytoggle = delaytoggle == 1 and -1 or 1

					local duration = GetRandomWithVariance(TUNING.STALKER_SNARE_TIME, TUNING.STALKER_SNARE_TIME_VARIANCE)

					local variation = table.remove(vars, math.random(#vars))
					table.insert(used, variation)
					if #used > 3 then
						table.insert(queued, table.remove(used, 1))
					end
					if #vars <= 0 then
						local swap = vars
						vars = queued
						queued = swap
					end
					spike:RestartSpike(delay, duration, variation)
				end
			end

			if target.components.combat and target.components.health ~= nil and not target.components.health:IsDead() then
				target.components.combat:GetAttacked(attacker,200) --骨牢100伤害的攻击
			end
			SpawnPrefab("er_tips_label"):set("<禁锢>", 1).Transform:SetPosition(x,y,z)
		end
	end,
	[6] = function(attacker, target) --弹幕
        local pt = Vector3(attacker.Transform:GetWorldPosition())
		local k =4
		for i =1 ,k do
			local beam = SpawnPrefab("rg_attack_orb_samll")
			if i > 1 then
				local a = (i - 1)*360/k
				beam.Transform:SetPosition(pt.x,1,pt.z)
				beam.AnimState:PlayAnimation("spin_loop",true) 
				if beam.components.rg_projectile then
					beam.components.rg_projectile:Throw(attacker, a)
					--ByLaoluFix 2021-06-18 修复服务器卡死bug
					beam:DoTaskInTime(3, function()
						beam.components.rg_projectile:Stop()
						beam.Physics:Stop()
						beam:Remove()
					end)
					--FixEnd
				end
			end
		end
	end,
	[7] = function(attacker, target) --减速 50% 10秒
		if target:IsValid() and target.components.rg_buff ~= nil then
			target.components.rg_buff:AddDebuff("rg_debuff_speed",10)
			local x,y,z = target.Transform:GetWorldPosition()
			SpawnPrefab("er_tips_label"):set("<减速>", 1).Transform:SetPosition(x,y,z)
		end
	end,
	[8] = function(attacker, target)--锁血 15秒
		if target:IsValid() and target.components.rg_buff ~= nil then
			target.components.rg_buff:AddDebuff("rg_debuff_suoxue",15)
			local x,y,z = target.Transform:GetWorldPosition()
			SpawnPrefab("er_tips_label"):set("<锁血>", 1).Transform:SetPosition(x,y,z)
		end
	end,
}

-- local skill_lists = {
	-- [3] = function(attacker, target) --致盲	 8秒
		-- if target:IsValid() and target.components.rg_buff ~= nil then
			-- target.components.rg_buff:AddDebuff("rg_debuff_miss",8)
			-- local x,y,z = target.Transform:GetWorldPosition()
			-- SpawnPrefab("er_tips_label"):set("<致盲>", 1).Transform:SetPosition(x,y,z)
		-- end
	-- end,
	-- [9] = function(attacker, target) --混乱 10秒
		-- if target:IsValid() and target.components.rg_buff ~= nil then
			-- target.components.rg_buff:AddDebuff("rg_debuff_hunluan",10)
			-- local x,y,z = target.Transform:GetWorldPosition()
			-- SpawnPrefab("er_tips_label"):set("<混乱>", 1).Transform:SetPosition(x,y,z)
		-- end
	-- end,
-- }

--组件开始  
local rg_guaiwu = Class(function(self, inst)
    self.inst = inst
	self.rank = 1 			--怪物品阶
	self.level = 1			--怪物等级
	self.monstertype= 1		--怪物类型
	self.levelinfo = nil
	self.skillinfo = nil
	self.attackers = {}		--记录攻击参与者
	--ByLaoluFix 2021-09-13
	self.isseting = false
	self.oldhealth = nil
	self.olddmg = nil
	inst:AddTag("rg_guaiwu")
	
	--监听怪物受击
	self.inst:ListenForEvent("attacked",function(inst,data)
		if data ~=nil then
			local attacker = data.attacker
			local damage = data.damageresolved or 0
			if self and attacker:HasTag("player") then
				local userid = attacker.userid
				self.attackers[userid] = (self.attackers[userid] or 0) + damage
			end
		end
	end)
end)
--回复血量表
local allreplyhpli = {
	{2,3,5},		--精灵
	{40,60,80},		--妖精
	{80,100,120},	--妖王
	{120,160,180}	--魔王
}
local level = TUNING.RG_GWLEVEL		--普通怪的等级设置
local levelli = {
	[1] = 1,
	[2] = 10,
	[3] = 50,
	[4] = 100,
	[5] = 500,
	[6] = 1000,
	[7] = 2000,
	[8] = 3000,
	[9] = 4000,
	[10] = 5000,
}
--普通怪/精灵怪 按照设置的概率改变
function rg_guaiwu:Suiji(rank)
	local combat = self.inst.components.combat
	local health = self.inst.components.health
	local variation = TUNING.RG_VARIATION
	local levelinfo = ""	--初始化等级显示内容
	local skillinfo = ""	--初始化技能显示内容

	self.rank = weighted_random_choice(variation)
	if rank then
		self.rank = rank
	end
	if self.rank > 0 then
		self.inst:AddTag("rg_guaiwu_up")
--		self.level = math.random(100,400)			--怪物等级
		self.level = 100							--怪物等级
		local rankname = "[精灵]"					--怪物级别名
		local skillnum = math.random(1,3)			--持有技能个数
		local absorb = 0.3							--防御力
		local replyhpli = allreplyhpli[1]			--回复血量
		local runspeed = 6							--移速
	
		if self.rank == 2 then
--			self.level = math.random(400,1200)
			self.level = 200
			rankname = "[妖精]"
			skillnum = math.random(2,5)
			absorb = 0.6
			replyhpli = allreplyhpli[2]
			runspeed = 8
		elseif self.rank == 3 then
--			self.level = math.random(1200,4800)
			self.level = 500
			rankname = "[妖王]"
			skillnum = math.random(4,7)
			absorb = 0.8
			replyhpli = allreplyhpli[3]
			runspeed = 10
		elseif self.rank == 4 then
--			self.level = math.random(4800,10000)
			self.level = 1000
			rankname = "[魔王]"
			skillnum = 8
			absorb = 0.9
			replyhpli = allreplyhpli[4]
			runspeed = 12
		end

		levelinfo = rankname.."  等级:"..self.level
		
		--精灵怪攻击力修改
		if combat then
			local damagexs = 0.05					--小型
			if self.monstertype == 2 then			--中型
				damagexs = 0.1
			elseif self.monstertype == 3 then		--boss
				damagexs = 0.2
			end
			damagexs = math.min(1,self.level*damagexs)
			--ByLaoluFix 2021-09-12 与怪物祭坛的创建冲突,叠加了计算,这里修复处理,避免累加计算
			if not self.isseting then
				self.olddmg = combat.defaultdamage or 0
				combat.defaultdamage = combat.defaultdamage*damagexs
			else
				self.olddmg = self.olddmg or 0
				combat.defaultdamage = self.olddmg*damagexs
			end
			--闪避
			local old_GetAttacked = combat.GetAttacked
			combat.GetAttacked = function (aaa,attacker,...)
				--闪避几率为怪物强化级别*0.06
				if math.random() < self.rank*0.06 then
					local x,y,z = self.inst.Transform:GetWorldPosition()
					SpawnPrefab("er_tips_label"):set("<闪避>", 1).Transform:SetPosition(x,y,z)
					return false
				end
				return old_GetAttacked(aaa,attacker,...)
			end
			--伤害转移函数
			combat.redirectdamagefn = function(target, attacker, damage, weapon, stimuli)
				local newtarget = nil
				--如果玩家有混乱buff
				if attacker and attacker:HasTag("player") and attacker.components.rg_buff ~= nil and attacker.components.rg_buff:HasDeBuff("rg_debuff_hunluan") then
					local x, y, z = attacker.Transform:GetWorldPosition()
					for i, v in ipairs(TheSim:FindEntities(x, 0, z, 8, {"player"}, {"playerghost", "INLIMBO"}))do
						if v:IsValid() and not (v.components.health ~= nil and v.components.health:IsDead())  and v ~= attacker then
							newtarget = v
							break
						end
					end	
				end
				return newtarget
			end
		end

		local burnable = self.inst.components.burnable
		if burnable then
			burnable.Ignite = function(aaa,...)
				return
			end
		end

		local freezable = self.inst.components.freezable
		if freezable then
			freezable.AddColdness = function(aaa,...)
				return
			end
			freezable.Freeze = function(aaa,...)
				return
			end
		end
		
		--精灵怪血量修改
		if health then
			local healthup = 1					--小型
			local replyhp = replyhpli[1]
			if self.monstertype == 2 then		--中型的
				healthup = 2
				replyhp = replyhpli[2]
			elseif self.monstertype == 3 then	--boss
				healthup = 5
				replyhp = replyhpli[3]
			end
			healthup = math.max(1,self.level*healthup)
			--ByLaoluFix 2021-09-12 与怪物祭坛的创建冲突,叠加了计算,这里修复处理,避免累加计算
			if not self.isseting then
				self.oldhealth = health.maxhealth or 0
				local maxhealth = health.maxhealth*healthup
				health:SetMaxHealth(maxhealth)
			else
				health:SetMaxHealth(self.oldhealth*healthup)
			end
			health.newabsorb = absorb										--减伤

			if self.inst.replyhp == nil then
				self.inst.replyhp = self.inst:DoPeriodicTask(1, function()	--回复血量
					if not health:IsDead() then
						health:DoDelta(replyhp)
					end
				end)
			end
			health.externalfiredamagemultipliers:SetModifier("rg_guaiwu_up", 0)	--免疫火烧
		end
		
		local locomotor = self.inst.components.locomotor
		--精灵怪移速修改
		if locomotor then
			locomotor.runspeed = runspeed
		end

		--在技能池随机取得对应数量的不同技能
		local skills = {}
		local t = {}
		local maxnum = #skill_lists
		for i=1,skillnum do
			local num = math.random(maxnum)
			table.insert(skills,t[num] or num)
			t[num] = t[maxnum]or maxnum
			maxnum = maxnum - 1
		end
		
		local skilllie = ""
		if next(skills) ~= nil then			--如果技能池不是空的
			for i ,v in ipairs(skills) do
				skilllie = skilllie.." "..skillsname[v]
			end
			skillinfo = "技能:"..skilllie
			--兼听攻击 触发判定
			self.inst:ListenForEvent("onhitother", function(inst,data)
				local other = data.target
				--30%的几率触发技能
				if other and other:HasTag("player") and math.random() < 0.5 then
					local resistrank = other.resistrank or 0
					if math.random() > resistrank then
						if skill_lists[skills[math.random(#skills)]] ~= nil then
							--技能池里面随机触发一个
							skill_lists[skills[math.random(#skills)]](inst,other)
						end
					end
				end
			end)
		end
		
		--体型变大
		local oldscale = self.inst.Transform:GetScale()	 						--获取原来的放大倍数
		self.inst.Transform:SetScale(oldscale*1.5,oldscale*1.5,oldscale*1.5)	--放大1.5倍
		--防止睡眠
		if self.inst.components.sleeper then
			self.inst.components.sleeper.AddSleepiness = function(sleeper,...)
				return
			end
		end
------------------------------------------普通怪强化------------------------------------------------------
	else
		--ByLaoluFix 2021-09-12 与怪物祭坛的创建冲突,叠加了计算,这里修复处理,避免累加计算		
		self.level = levelli[level] or levelli[#levelli]
		--怪物伤害调整
		levelinfo = "普通怪".."  等级:"..self.level
		--攻击力修改		
		if combat ~= nil then
			local damagexs =  0.01				--小型的
			if self.monstertype == 2 then 		--中型的
				damagexs =  0.03
			elseif self.monstertype == 3 then 	--boss
				damagexs =  0.05
			end
			damagexs = math.min(1,self.level*damagexs)
			if not self.isseting then
				self.olddmg = combat.defaultdamage or 0
				combat.defaultdamage  = combat.defaultdamage*damagexs
			else
				combat.defaultdamage = self.olddmg*damagexs
			end
		end
		
		--怪物血量调整
		if health ~= nil then
			local healthup = 1					--小型
			--local absorb = 0
			if self.monstertype == 2 then		--中型的
				healthup = 2
				--absorb = 0
			elseif self.monstertype == 3 then	--boss
				healthup = 5
				--absorb = 0
			end
			healthup = math.max(1,self.level*healthup)
			if not self.isseting then
				self.oldhealth = health.maxhealth or 0
				local maxhealth = health.maxhealth*healthup
				health:SetMaxHealth(maxhealth)
				--health.newabsorb = absorb
			else
				health:SetMaxHealth(self.oldhealth*healthup)
			end
		end
	end

	if levelinfo ~= nil then
		self.levelinfo = levelinfo
	end
	if skillinfo ~= nil then
		self.skillinfo = skillinfo
	end
end

return rg_guaiwu