--ByLaolu.er,
---------------------------------------------------------------------- 
--全局配置
local RBURST_JL = 0.5	--魔爆触发几率:默认0.5, 50%触发
local CAN_DMG_TAGS = {"_health","_combat"}
local CANT_DMG_TAGS = {"playerghost", "INLIMBO", "player", "companion", "wall", "laoluselfbaby"}
--远程类的额外处理:TODO..
------------------------------------
--定制武器配置表
local PWEAPON_SET =
{
	-- pweapon011 狂暴:狂暴状态:1:默认攻击力\2:狂暴几率\3:持续时间\4:攻击倍率\5:眩晕目标时间
	["pweapon011"]={800, 0.15, 0.2, 1.5, 5},
}

----------------------------------------------------------------------
--通用的判断是否能进行攻击的函数
local function CanAttack(attacker, target)
	if attacker and target and attacker:IsValid() and target:IsValid() then
		return true
	end
	return false
end

local function trypetrify(inst)
	if not TheWorld.ismastersim then
		return inst
	end
	local STAGE_PETRIFY_PREFABS = {
		"rock_petrified_tree_short",
		"rock_petrified_tree_med",
		"rock_petrified_tree_tall",
		"rock_petrified_tree_old",
	}
    local STAGE_PETRIFY_FX = {
		"petrified_tree_fx_short",
		"petrified_tree_fx_normal",
		"petrified_tree_fx_tall",
		"petrified_tree_fx_old",
	}
	local function dopetrify(inst, stage, instant)
		local x, y, z = inst.Transform:GetWorldPosition()
		local r, g, b = inst.AnimState:GetMultColour()
		inst:Remove()
		local rock = SpawnPrefab(STAGE_PETRIFY_PREFABS[stage])
		if rock ~= nil then
			rock.AnimState:SetMultColour(r, g, b, 1)
		rock.Transform:SetPosition(x, 0, z)
		if not instant then
			local fx = SpawnPrefab(STAGE_PETRIFY_FX[stage])
			fx.Transform:SetPosition(x, y, z)
			fx:InheritColour(r, g, b)
		end
	end
	end
	if (inst:HasTag("evergreens")) and not inst:HasTag("stump") then
		local growable = inst.components.growable
		if growable and growable.stage then
			dopetrify(inst, growable.stage)
		end
	end
end

local function NoHoles(pt)	--判断是不是有洞
	return not TheWorld.Map:IsPointNearHole(pt)
end

--对怪物造成伤害
local function ToHurt(player,weapon,target,damage)	
	local health = target.components.health
	--ByLaoluFix 2021-06-06 修复宝宝等非玩家使用武器造成伤害的bug
	if player and player.components.er_leave then
		damage = damage * (player.components.er_leave.level/100)		--原初伤害 (技能基本伤害*人物等级/100)
	else
		damage = damage
	end--Fixend
	if weapon and target and target:IsValid() and health and not health:IsDead() then
		local rate = 1				--魔爆伤害倍数
		--ByLaoluFix 2021-07-03 修复魔爆无效
		if weapon.mburst then
			if math.random() < RBURST_JL then
				rate = weapon.mburst
			end
		end
		if target.components and target.components.combat then--ByLaoluFix2021-08-28修复新韦博召唤物无组件的报错
			target.components.combat:GetAttacked(player,damage * rate)	--计算后受到伤害 原初伤害*附魔加成
		end
	end
end
-----------------------------------------------------------------------
--通用类技能函数库
local S_Scale,M_Scale,L_Scale = 1,2,2.5
local S_Pos,M_Pos,L_Pos = 1,2,3.5
local function SpawnStunFx( target, scale, pos, t)
    local fx = SpawnPrefab("rg_axefxfx")
	local tt = math.max(0.5, t- 0.5)
    fx.Transform:SetScale(scale, scale, scale)
	fx.entity:SetParent(target.entity)
	fx.Transform:SetPosition(0, pos, 0)
	fx:DoTaskInTime(tt, fx.Remove)
end
local function Stuntarget(target,stuntime)
	local obj,stuntime = target or nil,stuntime or 1
	if obj ~=nil and obj:IsValid() then
		-- if obj:HasTag("stuning") then return end
		if obj.brain ~= nil and obj.components.locomotor ~= nil then
			-- TheNet:Announce(stuntime)
			obj:AddTag("stuning")
			obj.brain:Stop()
			obj.components.locomotor:Stop()
			local scale = (obj:HasTag("smallcreature") and S_Scale)
				or (obj:HasTag("largecreature") and L_Scale)
				or M_Scale
			local pos = (obj:HasTag("smallcreature") and S_Pos)
				or (obj:HasTag("largecreature") and L_Pos)
				or M_Pos
			SpawnStunFx(obj, scale,pos,stuntime)	
			obj:DoTaskInTime(stuntime,function(obj) 
				-- TheNet:Announce("眩晕结束了！")
				if obj:IsValid() then
					if obj.brain ~= nil then
						obj.brain:Start()
					end
					if obj.components.locomotor ~= nil then
						obj.components.locomotor:SetShouldRun() 
					end
					obj:RemoveTag("stuning")
				end
			end)
		end
	end
end

-----------------------------------------------------------------------
--技能伤害
local skilldamage = {240,280,400,320,320,320,400,320}
--近战武器技能
local AttackShortFns = {
	--横扫之刃
	[1] = function(player, data)
		--如果是冷却中 那么直接返回 没有技能效果
		local rechargeable = data.weapon.components.rechargeable
		if rechargeable then
			if rechargeable.recharging == true then
				return
			end
			if CanAttack(player, data.target) then
				-- player.sg:GoToState("chop")
				local map = TheWorld.Map
				local x1,y1,z1 = player.Transform:GetWorldPosition()					--人物坐标
				--Fix技能伤害宝宝 ByLaolu 2021-05-09
				local ents = TheSim:FindEntities(x1, y1, z1, 3.5, CAN_DMG_TAGS,CANT_DMG_TAGS)	--获取半径为5的所有实体
				local ang = player.Transform:GetRotation()								--获取人物的面向角度   0-180   正负
				local spike = SpawnPrefab("weapon_fx001")								--生成实体
				spike.Transform:SetPosition(x1,y1,z1)									--设定实体出现坐标
				spike.Transform:SetRotation(ang)										--设置旋转角度

				for k,v in pairs(ents) do
					local x2,y2,z2 = v.Transform:GetWorldPosition()						--受击者坐标
					local angle = player:GetAngleToPoint(x2,0,z2)						--返回人物对受击者坐标点的方向
					local drot = math.abs( ang - angle )								--取绝对值
					while drot > 180 do
						drot = math.abs(drot - 360)
					end
					--在半圆里
					if drot <= 90 then
						if v and v:IsValid() and data ~=nil then
							ToHurt(player,data.weapon,v,skilldamage[1])
						end
					end
				end
			end
			--开始进入冷却
			rechargeable:StartRecharging()
		end
	end,
	--圣剑裁决
	[2] = function(player, data)
		local rechargeable = data.weapon.components.rechargeable
		if rechargeable then
			if rechargeable.recharging == true then
				return
			end
			if CanAttack(player, data.target) then
				local x, y, z = data.target.Transform:GetWorldPosition()
				local fx = SpawnPrefab("weapon_fx002")
				fx.Transform:SetPosition(x,y,z)
				fx.Transform:SetScale(2, 2, 2)
				--Fix技能伤害宝宝 ByLaolu 2021-05-09
				local ents = TheSim:FindEntities(x, y, z, 4,CAN_DMG_TAGS,CANT_DMG_TAGS)

				for k, v in pairs(ents) do
					if v and v:IsValid() and data ~=nil then--ByLaoluFix 2020-11-27 做安全保护
						ToHurt(player,data.weapon,v,skilldamage[2])
					end
				end
			end
			rechargeable:StartRecharging()
		end
	end,
	--地狱业火
	[3] = function(player, data)
		local rechargeable = data.weapon.components.rechargeable
		if rechargeable then
			if rechargeable.recharging == true then
				return
			end
			if CanAttack(player, data.target) then
				local x, y, z = data.target.Transform:GetWorldPosition()
				local fx = SpawnPrefab("weapon_fx003")
				fx.Transform:SetPosition(x,y,z)
				fx.Transform:SetScale(2.5, 2.5, 2.5)
				--Fix技能伤害宝宝 ByLaolu 2021-05-09
				local ents = TheSim:FindEntities(x, y, z, 4,CAN_DMG_TAGS,CANT_DMG_TAGS)
				for k, v in pairs(ents) do
					if v and v:IsValid() and data ~=nil then--ByLaoluFix 2020-11-27 做安全保护
						ToHurt(player,data.weapon,v,skilldamage[3])
					end
				end
			end
			rechargeable:StartRecharging()
		end
	end,
	--晶能射线
	[4] = function(player, data)
		local rechargeable = data.weapon.components.rechargeable
		if rechargeable then
			if rechargeable.recharging == true then
				return
			end
			if CanAttack(player, data.target) then
				local spacing = data.target:GetPosition() - player:GetPosition()
				local range = {2, 4, 6, 8, 10}  --在玩家向着怪物一定距离处生成特效
				local t = 0
				for i,v in ipairs(range) do
					player:DoTaskInTime(t, function()
						local pt = spacing * v + player:GetPosition()
						for i = 1,8 do
							--在圆心为pt，半径为1的圆周上随机生成prefab
							local offset = FindWalkableOffset(pt, math.random() * 2 * PI, 1, 1, true, true, NoHoles)
							if offset ~= nil then
								offset.x = offset.x + pt.x
								offset.z = offset.z + pt.z
								local spike = SpawnPrefab("weapon_fx004")
								spike.Transform:SetScale(0.8,0.8,0.8)
								spike.Transform:SetPosition(offset.x, 0, offset.z)
								--Fix技能伤害宝宝 ByLaolu 2021-05-09
								local ents = TheSim:FindEntities(offset.x, 0, offset.z, 1,CAN_DMG_TAGS,CANT_DMG_TAGS)
								for k ,v in pairs(ents) do
									if v and v:IsValid() and data ~=nil then--ByLaoluFix 2020-11-27 做安全保护
										ToHurt(player,data.weapon,v,skilldamage[4])
									end
								end

							end
						end
					end)
					t = t + 0.1
				end
			end
			rechargeable:StartRecharging()
		end
	end,
	--冰霜突刺
	[5] = function(player, data)
		local rechargeable = data.weapon.components.rechargeable
		if rechargeable then
			if rechargeable.recharging == true then
				return
			end
			if CanAttack(player, data.target) then
				player.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/swipe")
				local pos = player:GetPosition()
				local targetPos = data.target:GetPosition()
				local vec = targetPos - pos
				vec = vec:Normalize()
				local dist = pos:Dist(targetPos)

				for i = 1, 20 do
					player:DoTaskInTime(math.random() * 1, function(player)
						local prefab = "weapon_fx005"
						local spike = SpawnPrefab(prefab)
						local offset = (vec * math.random(dist * 0.25, dist)) + Vector3(GetRandomWithVariance(0, 5), 0, GetRandomWithVariance(0, 5))
						spike.Transform:SetPosition((offset + pos):Get())
						local x,y,z = spike.Transform:GetWorldPosition()
						--Fix技能伤害宝宝 ByLaolu 2021-05-09
						local ents = TheSim:FindEntities(x, y, z, 2.5, CAN_DMG_TAGS,CANT_DMG_TAGS)
						for k, v in pairs(ents) do
							if v and v:IsValid() and data ~=nil then--ByLaoluFix 2020-11-27 做安全保护
								ToHurt(player,data.weapon,v,skilldamage[5])
								if v.components.freezable then
									v.components.freezable:AddColdness(5)
									v.components.freezable:SpawnShatterFX()
								end
							end
						end
					end)
				end
			end
			rechargeable:StartRecharging()
		end
	end,
	--冰痕之印
	[6] = function(player, data)
		local rechargeable = data.weapon.components.rechargeable
		if rechargeable then
			if rechargeable.recharging == true then
				return
			end
			if CanAttack(player, data.target) then
				local x, y, z = data.target.Transform:GetWorldPosition()
				local spike = SpawnPrefab("weapon_fx006")
				spike.Transform:SetPosition(x,y,z)
				--Fix技能伤害宝宝 ByLaolu 2021-05-09
				local ents = TheSim:FindEntities(x, y, z, 4,CAN_DMG_TAGS,CANT_DMG_TAGS)
				for k, v in pairs(ents) do
					if v and v:IsValid() and data ~=nil then--ByLaoluFix 2020-11-27 做安全保护
						local freezable = v.components.freezable
						if freezable then
							ToHurt(player,data.weapon,v,skilldamage[6])
							freezable:AddColdness(5)
						end
					end
				end
			end
			rechargeable:StartRecharging()
		end
	end,
	--粒子爆破
	[7] = function(player, data)
		local rechargeable = data.weapon.components.rechargeable
		if rechargeable then
			if rechargeable.recharging == true then
				return
			end
			if CanAttack(player, data.target) then
				local spawnpoints = {}
				local x, y, z = player.Transform:GetWorldPosition()
				local spacing = 1.7		--间距
				local radius = 1		--半径
				local deltaradius = .1	--三角函数半径
				local angle = 2 * PI * math.random()
				--选择释放顺逆
				local deltaanglemult = (player.reversespikes and -2 or 2) * PI * spacing
				player.reversespikes = not player.reversespikes
				local delay = 0
				local deltadelay = FRAMES
				local num = 30
				local map = TheWorld.Map
				for i = 1, num do
					local oldradius = radius
					radius = radius + deltaradius
					--新的圆周长(旧半径+新半径)
					local circ = PI * (oldradius + radius)
					--差值的比例
					local deltaangle = deltaanglemult / circ
					--下个等距点
					angle = angle + deltaangle
					local x1 = x + radius * math.cos(angle)
					local z1 = z + radius * math.sin(angle)
					--判断坐标位置是不是海
					if map:IsPassableAtPoint(x1, 0, z1) then
						--向spawnpoints表中插入数据(键值对)
						table.insert(spawnpoints, {
							t = delay,						--特效出现时间
							pts = { Vector3(x1, 0, z1) },	--特效出现坐标
						})
						delay = delay + deltadelay
					end
				end

				if #spawnpoints > 0 then
					local flames = {}
					local flameperiod = .8
					for i, v in ipairs(spawnpoints) do
						flames[math.floor(v.t / flameperiod)] = true
						player:DoTaskInTime(v.t, function()
							for i, v in ipairs(v.pts) do
								local spike = SpawnPrefab("weapon_fx007")
								local x1, y1, z1 = v:Get()
								spike.Transform:SetPosition(x1, y1, z1)
								--Fix技能伤害宝宝 ByLaolu 2021-05-09
								local ents = TheSim:FindEntities(x1, y1, z1, 2, CAN_DMG_TAGS,CANT_DMG_TAGS)
								for k ,v in pairs(ents) do
									if v and v:IsValid() and v.components.combat ~= nil and data ~=nil then --ByLaoluFix 2020-11-27 做安全保护
										ToHurt(player,data.weapon,v,skilldamage[7])
									end
								end
							end
						end)
					end
					if player ~= nil and player.SoundEmitter ~= nil then
						for k, v in pairs(flames) do
							player:DoTaskInTime(k, function()
								player.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/flame")
							end, player)
						end
					end
				end
			end
			rechargeable:StartRecharging()
		end
	end,
	--弯月突袭
	[8] = function(player, data)
		local rechargeable = data.weapon.components.rechargeable
		if rechargeable then
			if rechargeable.recharging == true then
				return
			end
			if CanAttack(player, data.target) then
				local x, y, z = data.target.Transform:GetWorldPosition()
				local spikepos = {}
				for k = -2, 2 do
					table.insert(spikepos, {
						t = k,
						pts = { Vector3(x, 0, z+k/3) },
					})
				end
				for k, v in pairs(spikepos) do
					for i, j in ipairs(v.pts) do
						local x1, y1, z1 = j:Get()
						local spike = SpawnPrefab("weapon_fx008")
						spike.Transform:SetPosition(player.Transform:GetWorldPosition())
						spike.injured = {}
						spike:FacePoint(x1, y1, z1)
						spike.Physics:SetCollisionCallback(function(inst, other)
							if other and not inst.injured[other] and other:IsValid() and inst:IsValid()
							--Fix技能伤害宝宝 ByLaolu 2021-05-09
									and not (other:HasTag("player") or other:HasTag("wall") or other:HasTag("laoluselfbaby") ) then
								ToHurt(player,data.weapon,other,skilldamage[8])
								inst.injured[other] = true
							end
						end)
						spike.Physics:SetMotorVel(30, 3, 0) --飞行
						spike:StartUpdatingComponent(spike) --更新
					end
				end
			end
			rechargeable:StartRecharging()
		end
	end,
	--技能9
	[9] = function(player, data)
		local rechargeable = data.weapon.components.rechargeable
		if rechargeable then
			if rechargeable.recharging == true then
				return
			end
			if CanAttack(player, data.target) then
				local vars = {1, 2, 3, 4, 5, 6, 7}
				local used = {}
				local queued = {}
				local delaytoggle = 0
				--获取在世界上的坐标
				local x, y, z = player.Transform:GetWorldPosition()
				--获取实体的面向角度   0-180   正负
				local angle = player.Transform:GetRotation()
				--菱形算法
				local spikepos = {}

				local delay = 0
				local deltadelay = FRAMES

				--对称轴左侧算法
				for k = 0, 8 do
					table.insert(spikepos, {
						t = delay,						--特效出现时间
						pts = {Vector3(k, 0, k/2+2)},	--特效出现坐标
					})
					table.insert(spikepos, {
						t = delay,
						pts = {Vector3(k, 0, -k/2-2)},
					})
					delay = delay + deltadelay
				end
				--对称右侧算法
				for k = 9, 18 do
					table.insert(spikepos, {
						t = delay,
						pts = {Vector3(k, 0, k/2-10)},
					})
					table.insert(spikepos, {
						t = delay,
						pts = {Vector3(k, 0, -k/2+10)},
					})
					delay = delay + deltadelay
				end
				--右侧顶点
				table.insert(spikepos, {
					t = delay,
					pts = {Vector3(19, 0, 0)},
				})

				--遍历表生成实体
				for k, v in pairs(spikepos) do
					local mouse = unpack(v.pts)
					local r = math.sqrt(mouse.x^2 + mouse.z^2)/1.5
					local o = (math.atan(mouse.z/mouse.x)*RADIANS+angle)*DEGREES
					mouse.x = r*math.cos(o)
					mouse.z = r*math.sin(o)
					spikepos[k] = {
						t = v.t,
						pts = {Vector3(x+mouse.x, y, z-mouse.z)},
					}
				end

				local map = TheWorld.Map
				for k, v in pairs(spikepos) do
					local pos1 = unpack(v.pts)
					if map:IsPassableAtPoint(pos1.x, 0, pos1.z) and not map:IsPointNearHole(pos1) then
						player:DoTaskInTime(v.t, function()
							for i, v in ipairs(v.pts) do
								if v then--ByLaoluFix 2020-11-27 做安全保护
									local spike = SpawnPrefab("weapon_fx009")
									spike.Transform:SetPosition(v:Get())
								end
							end
						end)
					end
				end
			end
			rechargeable:StartRecharging()
		end
	end,
	[14] = function(player, data)
		local rechargeable = data.weapon.components.rechargeable
		if rechargeable then
			if rechargeable.recharging == true then
				return
			end
			if CanAttack(player, data.target) then
				local x, y, z = data.target.Transform:GetWorldPosition()
				local fx = SpawnPrefab("weapon_fx014")
				fx.Transform:SetPosition(x,y,z)
				--Fix技能伤害宝宝 ByLaolu 2021-05-09
				local ents = TheSim:FindEntities(x, y, z, 4,CAN_DMG_TAGS,CANT_DMG_TAGS)
				for k ,v in pairs(ents) do
					if v and v:IsValid() and data ~=nil then--ByLaoluFix 2020-11-27 做安全保护
						ToHurt(player,data.weapon,v,-140)
					end
				end
			end
			rechargeable:StartRecharging()
		end
	end
}

--远程武器技能
local AttackLongFns = {
	[1] = function(inst, target, pos)
		local rechargeable = inst.components.rechargeable
		if rechargeable and rechargeable.recharging == true then
			return
		end
		local workable = inst.components.inventoryitem.owner
		if workable then
			local lr_magic = workable.components.lr_magic
			if lr_magic.current < 100 then
				workable.components.talker:Say("魔法值不足！")
				return
			end
			local x,y,z = pos:Get()
			--ByLaoluFix 2021-07-03 --修复杖类武器可攻击建筑等错误
			local ents = TheSim:FindEntities( x, y, z, 5 * workable.magicrange)--,CAN_DMG_TAGS,CANT_DMG_TAGS)
			for k,v in pairs(ents) do
				if v.components.workable ~= nil and v.components.workable:CanBeWorked() then
				   SpawnPrefab("collapse_small").Transform:SetPosition(v.Transform:GetWorldPosition())
				   SpawnPrefab("fossilspike2").Transform:SetPosition(v.Transform:GetWorldPosition())
				   v.components.workable:Destroy(inst)
				end
			end
			lr_magic:DoDelta(-100)
		end
		rechargeable:StartRecharging()
	end,
	[2] = function(inst, target, pos)
		local rechargeable = inst.components.rechargeable
		if rechargeable and rechargeable.recharging == true then
			return
		end
		local workable = inst.components.inventoryitem.owner
		if workable then
			local lr_magic = workable.components.lr_magic
			if lr_magic.current < 100 then
				workable.components.talker:Say("魔法值不足！")
				return
			end
			local x,y,z = pos:Get()
			--Fix技能伤害宝宝 ByLaolu 2021-05-09
			local ents = TheSim:FindEntities( x, y, z, 2.6 * workable.magicrange,CAN_DMG_TAGS,CANT_DMG_TAGS)
			local size = workable.magicrange
			local spike = SpawnPrefab("weapon_fx017")
			spike.AnimState:SetScale(size,size,size)
			spike.Transform:SetPosition(x,y,z)
			local hurt = 100
			if workable.magicdamageup then
				--Fix宝宝使用的错误 ByLaolu 2021-06-06
				if workable.components.er_leave then
					hurt = hurt + workable.components.er_leave.level * 0.5
				end
			end
			for k,v in pairs(ents) do
				if v.components.health then
					v.components.health:DoDelta(-hurt)
				end
			end
			lr_magic:DoDelta(-100)
		end
		rechargeable:StartRecharging()
	end,
	[3] = function(inst, target, pos)
		local rechargeable = inst.components.rechargeable
		if rechargeable and rechargeable.recharging == true then
			return
		end
		local workable = inst.components.inventoryitem.owner
		if workable then
			local lr_magic = workable.components.lr_magic
			if lr_magic.current < 100 then
				workable.components.talker:Say("魔法值不足！")
				return
			end
			local pt = Vector3(workable.Transform:GetWorldPosition())

			local ents = TheSim:FindEntities( pt.x, pt.y, pt.z, 15  * workable.magicrange)
			for k,v in pairs(ents) do
				if v ~= nil and v:HasTag("player") then
					v.components.health:DoDelta(50)
				end
				if v:HasTag("playerghost") then
					v:PushEvent('respawnfromghost', { source = workable })
				end
			end
			lr_magic:DoDelta(-100)
		end
		rechargeable:StartRecharging()
	end,
	[4] = function(inst, target, pos)
		local rechargeable = inst.components.rechargeable
		if rechargeable and rechargeable.recharging == true then
			return
		end
		local workable = inst.components.inventoryitem.owner
		if workable then
			local lr_magic = workable.components.lr_magic
			if lr_magic.current < 100 then
				workable.components.talker:Say("魔法值不足！")
				return
			end
			local x,y,z = pos:Get()
			local ents = TheSim:FindEntities( x, y, z, 5 * workable.magicrange)
			for k,v in pairs(ents) do
				if v.components.pickable ~= nil and v.prefab ~= "flower"  then
				v.components.pickable:Pick(workable)
				end
				if v.components.crop ~= nil  then
				v.components.crop:Harvest(workable)
				end
			end
			lr_magic:DoDelta(-100)
		end
		rechargeable:StartRecharging()
	end,
	[5] = function(inst, target, pos)
		local rechargeable = inst.components.rechargeable
		if rechargeable and rechargeable.recharging == true then
			return
		end
		local workable = inst.components.inventoryitem.owner
		if workable then
			local lr_magic = workable.components.lr_magic
			if lr_magic.current < 100 then
				workable.components.talker:Say("魔法值不足！")
				return
			end
			local x,y,z = pos:Get()
			local ents = TheSim:FindEntities(x, y, z, 15 * workable.magicrange, nil, "stump")
			if #ents > 0 then
				trypetrify(table.remove(ents, math.random(#ents)))
				if #ents > 0 then
					local timevar = 1 - 1 / (#ents + 1)
					for i,v in pairs(ents) do
						v:DoTaskInTime(timevar * math.random(), trypetrify)--不确定安全--ByLaoluFix 2020-11-27 做安全保护
					end
				end
			end
			local ents = TheSim:FindEntities(x, y, z, 5 * workable.magicrange)
			for k,v in pairs(ents) do
				if v.components.sleeper~= nil and not v:HasTag("player")  then
					v.components.sleeper:AddSleepiness(5, TUNING.PANFLUTE_SLEEPTIME)
				end
				if v.components.grogginess~= nil and not v:HasTag("player") then
					v.components.grogginess:AddGrogginess(5, TUNING.PANFLUTE_SLEEPTIME)
				end    
			end
			lr_magic:DoDelta(-100)
		end
		rechargeable:StartRecharging()
	end
}

--玩家定制武器技能
local PAttackFns = {
	[1] = function(player, data)
		if math.random() < 0.25 then
			local health = data.target.components.health
			if data.target and data.target:IsValid() and health and not health:IsDead() then
				local pcombat = player.components.combat
				if pcombat and pcombat:GetWeapon() then
					local damage = pcombat:GetWeapon().components.weapon.damage or 0
					health:DoDelta(-damage*3)
					if math.random() < 0.5 then
						player.components.health:DoDelta(damage*0.05)
					else
						local lr_magic = player.components.lr_magic
						if lr_magic then
							lr_magic:DoDelta(damage*0.05)
						end
					end
					local x,y,z = player.Transform:GetWorldPosition()
					SpawnPrefab("er_tips_label"):set("[祝语]", 1).Transform:SetPosition(x,y,z)
				end
			end
		end
	end,
	[2] = function(player, data)
		local weapon  = player.components.combat:GetWeapon()
		if weapon and weapon.pskid == 2 then
			player.components.health:DoDelta(player.components.health.maxhealth*0.01)
			if math.random() < 0.15  then
				if data.target and data.target:IsValid() then
					local health = data.target.components.health
					if health and not health:IsDead() then
						local damage = weapon.components.weapon.damage
						health:DoDelta(-damage*2)
					end
					local x,y,z = player.Transform:GetWorldPosition()
					SpawnPrefab("er_tips_label"):set("[剑影]", 1).Transform:SetPosition(x,y,z)
				end
			end
		end
	end,
	[4] = function(player, data)--ByLaoluFix 2021-07-02 修复玩家生命组件调用的逻辑顺序错误.
		local weapon  = player.components.combat:GetWeapon()
		if weapon and math.random() < 0.25  then			
			if data.target and data.target:IsValid() then
				local health = data.target.components.health
				if health and not health:IsDead() then
					local damage = weapon.components.weapon.damage
					health:DoDelta(-damage*3)
					player.components.health:DoDelta(player.components.health.maxhealth*0.05)
					local x,y,z = player.Transform:GetWorldPosition()
					SpawnPrefab("er_tips_label"):set("[伯爵再现]", 1).Transform:SetPosition(x,y,z)
				end
			end
		end
	end,
	--pwaepon011 狂暴:狂暴状态 持续3秒,攻击附带双倍攻击,眩晕目标3秒
	--狂暴:狂暴状态:1:默认攻击力\2:狂暴几率\3:持续时间\4:攻击倍率\5:眩晕目标时间
	-- ["pweapon011"]={800, 0.2, 3, 2, 5},
	[5] = function(player, data)
		local weapon  = data.weapon or player.components.combat:GetWeapon()
		local obj_t = PWEAPON_SET[weapon.prefab]
		if weapon then--and math.random() < obj_t[2] then		
			--触发与预准备逻辑
			if player and player.components.health and not player.components.health:IsDead() then
				--逻辑处理
				if data and data.target and data.target:IsValid() then
					if math.random() < obj_t[2] then
						-- TheNet:Announce("开启狂暴模式!")
						player:AddTag("kuangbao_cd")
						if player.kuangbao_cd ~=nil then
							player.kuangbao_cd:Cancel()
							player.kuangbao_cd = nil
						end
						player.kuangbao_cd = player:DoTaskInTime(obj_t[3], function()
							-- TheNet:Announce("狂暴结束!")
							player:RemoveTag("kuangbao_cd")
						end)
					end
					if player:HasTag("kuangbao_cd") then	
						local health = data.target.components.health
						if health and not health:IsDead() then	
							local damage = weapon.components.weapon.damage
							--VC1:直接扣血伤害模式
							health:DoDelta(-damage*obj_t[4])--伤害处理
							--VC2:正常伤害兼容模式	
							-- local damage = 10--weapon.components.weapon.damage
							-- damage = damage*obj_t[4])
							-- if data.target.components.combat ~= nil then
								-- data.target.components.combat:GetAttacked(player, damage)
							-- end
							--眩晕处理
							if not data.target:HasTag("stuning") then--处理眩晕累积逻辑
								local stuntime = obj_t[5]--math.min(3, obj_t[5] or 1)
								Stuntarget(data.target,stuntime)
							end
							local x,y,z = player.Transform:GetWorldPosition()--提示
							SpawnPrefab("er_tips_label"):set("[梵我]", 1).Transform:SetPosition(x,y,z)
						end
					end
				end
			end
		end
	end,
}

--攻击监听
local function HitOther(player, data)
	if data and data.weapon then
		if data.weapon.skid ~= 0 and AttackShortFns[data.weapon.skid] then
			AttackShortFns[data.weapon.skid](player,data)
		end
	end
end

--武器通用装备函数
local function weaponequip(inst,anim,speed)
	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(function(inst, owner)
		owner.AnimState:OverrideSymbol("swap_object", anim, inst.prefab)
		owner.AnimState:Show("ARM_carry")
		owner.AnimState:Hide("ARM_normal")
		owner:ListenForEvent("onhitother", HitOther)
		if inst.pskid and PAttackFns[inst.pskid] then
			owner:ListenForEvent("onhitother", PAttackFns[inst.pskid])
		end
	end)
	inst.components.equippable:SetOnUnequip(function(inst, owner)
		owner.AnimState:Hide("ARM_carry")
		owner.AnimState:Show("ARM_normal")
		owner:RemoveEventCallback("onhitother", HitOther)
		if inst.pskid and PAttackFns[inst.pskid] then
			owner:RemoveEventCallback("onhitother", PAttackFns[inst.pskid])
		end
	end)
	if speed then
		inst.components.equippable.walkspeedmult = speed
	end
	return inst
end

local function ratefn(inst)
	local rate = 1
	if inst.skcd then
		rate =  inst.skcd
	end
	return rate
end

AddPrefabPostInit("final_weapon",function(inst)
	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(100)
	inst.components.weapon:SetRange(5, 5)

	inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetRechargeTime(30)
	inst.components.rechargeable:SetRechargeRate(ratefn)
	inst.components.weapon:SetProjectile("projectile005")
	
	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(function(inst, owner)
		owner.AnimState:Show("ARM_carry")
		owner.AnimState:Hide("ARM_normal")
		if inst.animation == nil then
			inst.frame = "1"
			inst.animation = inst:DoPeriodicTask(0.1, function()
				owner.AnimState:OverrideSymbol("swap_object", "final_weapon", "image" .. inst.frame)
				inst.frame = string.format("%01d", (inst.frame % 8) + 1)	--计算帧数，到尾帧自动重置
			end)
		end

		owner:ListenForEvent("onhitother", HitOther)
		if inst.pskid and PAttackFns[inst.pskid] then
			owner:ListenForEvent("onhitother", PAttackFns[inst.pskid])
		end
	end)
	inst.components.equippable:SetOnUnequip(function(inst, owner)
		owner.AnimState:Hide("ARM_carry")
		owner.AnimState:Show("ARM_normal")
		if inst.animation then
			inst.animation:Cancel()
			inst.animation = nil
		end

		owner:RemoveEventCallback("onhitother", HitOther)
		if inst.pskid and PAttackFns[inst.pskid] then
			owner:RemoveEventCallback("onhitother", PAttackFns[inst.pskid])
		end
	end)
end)

--各系每代攻击力
local shapelist = {1,1,2,3,4}	--箭矢色号
local prolist = {1,2,3,4,5}		--法球色号
for i=1,5 do
	--剑
	local name1 = string.format("weapon1%02d",i)
	AddPrefabPostInit(name1,function(inst)
		inst:AddComponent("weapon")
		inst.components.weapon:SetRange(1.5, 2)

		inst:AddComponent("rechargeable")
		inst.components.rechargeable:SetRechargeTime(40)
		inst.components.rechargeable:SetRechargeRate(ratefn)

		weaponequip(inst,"weapons")
	end)
	--枪
	local name2 = string.format("weapon2%02d",i)
	AddPrefabPostInit(name2,function(inst)
		inst:AddComponent("weapon")
		inst.components.weapon:SetRange(1.5, 2)

		inst:AddComponent("rechargeable")
		inst.components.rechargeable:SetRechargeTime(40)
		inst.components.rechargeable:SetRechargeRate(ratefn)

		weaponequip(inst,"weapons")
	end)
	--弓
	local name3 = string.format("weapon3%02d",i)
	AddPrefabPostInit(name3,function(inst)
		inst:AddTag("er_bow")			--箭矢动作
		inst:AddTag("skillchange")		--技能切换
		inst.er_shape = shapelist[i]	--箭矢色号
		inst.discount = 0.5				--远程增益削减
		inst.switchid = 1				--切换id

		inst:AddComponent("weapon")
		inst.components.weapon:SetRange(5, 5)
		inst.components.weapon:SetProjectile("bowprojectile_close")

		inst:AddComponent("rechargeable")
		inst.components.rechargeable:SetRechargeTime(50)
		inst.components.rechargeable:SetRechargeRate(ratefn)

		weaponequip(inst,"weapons")
	end)
	--镰
	local name4 = string.format("weapon4%02d",i)
	AddPrefabPostInit(name4,function(inst)
		inst:AddComponent("weapon")
		inst.components.weapon:SetRange(1.5, 2)

		inst:AddComponent("rechargeable")
		inst.components.rechargeable:SetRechargeTime(40)
		inst.components.rechargeable:SetRechargeRate(ratefn)

		weaponequip(inst,"weapons")
	end)
	--刀
	local name5 = string.format("weapon5%02d",i)
	AddPrefabPostInit(name5,function(inst)
		inst:AddComponent("weapon")
		inst.components.weapon:SetRange(1.5, 2)

		inst:AddComponent("rechargeable")
		inst.components.rechargeable:SetRechargeTime(40)
		inst.components.rechargeable:SetRechargeRate(ratefn)

		weaponequip(inst,"weapons")
	end)
	--斧
	local name6 = string.format("weapon6%02d",i)
	AddPrefabPostInit(name6,function(inst)
		inst:AddComponent("weapon")
		inst.components.weapon:SetRange(1.5, 2)

		inst:AddComponent("rechargeable")
		inst.components.rechargeable:SetRechargeTime(40)
		inst.components.rechargeable:SetRechargeRate(ratefn)

		weaponequip(inst,"weapons")
	end)
	--杖
	local name7 = string.format("weapon7%02d",i)
	AddPrefabPostInit(name7,function(inst)
		inst:AddTag("er_longrange")
		inst.discount = 0.5

		inst:AddComponent("weapon")
		inst.components.weapon:SetRange(5, 5)
		inst.components.weapon:SetProjectile(string.format("projectile%03d",prolist[i]))

		inst:AddComponent("spellcaster")
		inst.components.spellcaster.canuseonpoint = true
		inst.components.spellcaster:SetSpellFn(AttackLongFns[i])

		inst:AddComponent("rechargeable")
		inst.components.rechargeable:SetRechargeTime(60)
		inst.components.rechargeable:SetRechargeRate(ratefn)

		weaponequip(inst,"weapons")
	end)
end

--定制武器
AddPrefabPostInit("pweapon001",function(inst)
	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(100)
	inst.components.weapon:SetRange(5, 5)
	inst.components.weapon:SetProjectile("projectile005")

	inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetRechargeTime(50)
	inst.components.rechargeable:SetRechargeRate(ratefn)

	weaponequip(inst,"pweapons")
end)
AddPrefabPostInit("pweapon002",function(inst)
	inst:AddTag("er_bow")
	inst:AddTag("skillchange")
	inst.er_shape = 3
	inst.discount = 0.5
	inst.switchid = 1

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(100)
	inst.components.weapon:SetRange(7, 7)
	inst.components.weapon:SetProjectile("bowprojectile_close")

	inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetRechargeTime(50)
	inst.components.rechargeable:SetRechargeRate(ratefn)

	weaponequip(inst,"pweapons")
end)
AddPrefabPostInit("pweapon003",function(inst)
	inst:AddTag("er_bow")
	inst:AddTag("skillchange")
	inst.er_shape = 2
	inst.discount = 0.75
	inst.pskid = 1	--定制技能id
	inst.switchid = 1

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(100)
	inst.components.weapon:SetRange(7, 7)
	inst.components.weapon:SetProjectile("bowprojectile_close")

	inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetRechargeTime(50)
	inst.components.rechargeable:SetRechargeRate(ratefn)

	weaponequip(inst,"pweapons")
end)
AddPrefabPostInit("pweapon004",function(inst)
	inst:AddTag("er_bow")
	inst:AddTag("skillchange")
	inst.er_shape = 3
	inst.discount = 0.5
	inst.switchid = 1

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(100)
	inst.components.weapon:SetRange(5, 5)
	inst.components.weapon:SetProjectile("bowprojectile_close")

	inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetRechargeTime(50)
	inst.components.rechargeable:SetRechargeRate(ratefn)

	weaponequip(inst,"pweapons")
end)
AddPrefabPostInit("pweapon005",function(inst)
	inst:AddTag("er_bow")
	inst:AddTag("skillchange")
	inst.er_shape = 3
	inst.discount = 0.5
	inst.switchid = 1

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(100)
	inst.components.weapon:SetRange(5, 5)
	inst.components.weapon:SetProjectile("bowprojectile_close")

	inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetRechargeTime(50)
	inst.components.rechargeable:SetRechargeRate(ratefn)

	weaponequip(inst,"pweapons")
end)
AddPrefabPostInit("pweapon006",function(inst)
	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(100)
	inst.components.weapon:SetRange(1.5, 2)

	inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetRechargeTime(50)
	inst.components.rechargeable:SetRechargeRate(ratefn)

	weaponequip(inst,"pweapons")
end)
AddPrefabPostInit("pweapon007",function(inst)
	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(100)
	inst.components.weapon:SetRange(5, 5)
	inst.components.weapon:SetProjectile("projectile005")

	inst:AddComponent("spellcaster")
	inst.components.spellcaster.canuseonpoint = true
	inst.components.spellcaster.quickcast = true
	inst.components.spellcaster:SetSpellFn(function(inst, target, pos)
		local workable = inst.components.inventoryitem.owner
		if workable then
			local x,y,z = pos:Get()
			workable.Physics:Teleport(x,y,z)
		end
		workable.SoundEmitter:PlaySound("dontstarve/common/staff_blink")
	end)

	inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetRechargeTime(30)
	inst.components.rechargeable:SetRechargeRate(ratefn)
	weaponequip(inst,"pweapons",1.25)
end)
AddPrefabPostInit("pweapon008",function(inst)
	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(100)
	inst.components.weapon:SetRange(5, 5)
	inst.components.weapon:SetProjectile("projectile005")

	inst:AddComponent("spellcaster")
	inst.components.spellcaster.canuseonpoint = true
	inst.components.spellcaster:SetSpellFn(function(inst, target, pos)
		local rechargeable = inst.components.rechargeable
		if rechargeable and rechargeable.recharging == true then
			return
		end
		local workable = inst.components.inventoryitem.owner
		if workable:HasTag("player") then
			local x,y,z = pos:Get()
			local fx = SpawnPrefab("weapon_fx020")
			fx.Transform:SetScale(2,2,2)
			fx.Transform:SetPosition(x,y,z)
			fx:DoTaskInTime(10, inst.Remove)
			fx:DoPeriodicTask(1, function()
				local ents = TheSim:FindEntities(x, y, z, 4, {"player"})
				for k,v in pairs(ents) do
					if v and v.components.health and not v.components.health:IsDead() then
						v.components.health:DoDelta(30)
					end
				end
			end)
		end
		rechargeable:StartRecharging()
	end)

	inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetRechargeTime(30)
	inst.components.rechargeable:SetRechargeRate(ratefn)

	weaponequip(inst,"pweapons")
end)
AddPrefabPostInit("pweapon009",function(inst)
	inst.pskid = 2
	inst.switchid = 2
	inst:AddTag("skillchange")

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(100)
	inst.components.weapon:SetRange(1.5, 2)

	inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetRechargeTime(50)
	inst.components.rechargeable:SetRechargeRate(ratefn)

	weaponequip(inst,"pweapons")
end)
AddPrefabPostInit("pweapon010",function(inst)
	inst.pskid = 4

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(100)
	inst.components.weapon:SetRange(1.5, 2)

	inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetRechargeTime(50)
	inst.components.rechargeable:SetRechargeRate(ratefn)

	weaponequip(inst,"pweapons")
end)
-------------------------
local function no_landfn(inst,data)
	if inst then
		-- inst.Light:Enable(false)
		-- TheNet:Announce("被持有!")
		if inst.fx ~=nil then
			inst.fx:Remove()
			inst.fx =nil			
		end
	end
end
local function on_landfn(inst)
	if inst then
		-- inst.Light:Enable(true)
		-- TheNet:Announce("在地上!")
		--特效
		inst.fx = SpawnPrefab("positronpulse")
		inst.fx.entity:SetParent(inst.entity)
		inst.fx.Transform:SetPosition(0, 0, 0)
		inst.fx.AnimState:OverrideMultColour(198/255, 159/255, 96/255,1)
		-- inst.fx.AnimState:SetScale(1.2, 1.2, 1.2)
		-- inst.fx.SoundEmitter:KillSound("beam")
		-- inst.fx.SoundEmitter:PlaySound("dontstarve/common/together/moonbase/beam_stop")
		inst.fx:Show()
	end
end
AddPrefabPostInit("pweapon011",function(inst)
	inst.pskid = 5

	inst.entity:AddLight()
	
	-- inst.Light:SetFalloff(.9)
	-- inst.Light:SetIntensity(0.35)
	-- inst.Light:SetRadius(6)
	-- inst.Light:SetColour(245/85,85/85,245/85)
	-- inst.Light:Enable(true)

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(PWEAPON_SET["pweapon011"][1] or 800)
	inst.components.weapon:SetRange(5, 5)

	inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetRechargeTime(30)
	inst.components.rechargeable:SetRechargeRate(ratefn)
	
	--狂暴的技能处理
	weaponequip(inst,"pweapons")
	if inst.components.inventoryitem ==nil then inst:AddComponent("inventoryitem") end
	
	inst:ListenForEvent("onputininventory", no_landfn)
	inst:ListenForEvent("on_landed", on_landfn)
	
end)



