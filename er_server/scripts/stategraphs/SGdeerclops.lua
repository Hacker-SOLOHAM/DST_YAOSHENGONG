--巨鹿SG
require("stategraphs/commonstates")

local actionhandlers = {
	ActionHandler(ACTIONS.HAMMER, "attack"),
	ActionHandler(ACTIONS.GOHOME, "taunt"),
}

local SHAKE_DIST = 40				--摄像机抖动
local ICE_NUM_RINGS = 5				--冰环数量
local ICE_DAMAGE_RINGS = 4			--冰环伤害
local ICE_DESTRUCTION_RINGS = 5		--冰环
local ICE_RING_DELAY = 0.2			--冰环延迟

--巨鹿踩踏
local function DeerclopsFootstep(inst)  
	inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/step")
	ShakeAllCameras(CAMERASHAKE.VERTICAL, .5, .03, 2, inst, SHAKE_DIST)
end

--生成冰刺特效
local function SpawnIceFx(inst, target)
	if not inst or not target then
		return
	end
	local numFX = math.random(15, 20)
	local pos = inst:GetPosition()
	local targetPos = target:GetPosition()
	local vec = targetPos - pos
	vec = vec:Normalize()
	local dist = pos:Dist(targetPos)
	local angle = inst:GetAngleToPoint(targetPos:Get())

	for i = 1, numFX do
		inst:DoTaskInTime(math.random() * 0.25, function(inst)
			local prefab = "icespike_fx_" .. math.random(1, 4)
			local fx = SpawnPrefab(prefab)
			if fx then
				local x = GetRandomWithVariance(0, 3)
				local z = GetRandomWithVariance(0, 3)
				local offset = (vec * math.random(dist * 0.25, dist)) + Vector3(x, 0, z)
				fx.Transform:SetPosition((offset + pos):Get())
			end
		end)
	end
end

--技能1
local function Deerclops_Skill1(inst, target)
	if not inst or not target then
		return
	end
	local pos = inst:GetPosition()
	local delay = 0
	for i = 1, ICE_NUM_RINGS do
		inst:DoTaskInTime(delay, function()
			local points = {}
			local radius = 1
			for i = 1, ICE_NUM_RINGS do
				local theta = 0
				local circ = 2 * PI * radius
				local numPoints = circ * .25
				for p = 1, numPoints do
					if not points[i] then
						points[i] = {}
					end
					local offset = Vector3(radius * math.cos(theta), 0, -radius * math.sin(theta))
					local point = pos + offset
					table.insert(points[i], point)
					theta = theta - (2 * PI / numPoints)
				end
				radius = radius + 4
			end									
			for k, v in pairs(points[i]) do
				if i <= ICE_DAMAGE_RINGS or i <= ICE_DESTRUCTION_RINGS then
					local ents = TheSim:FindEntities(v.x, v.y, v.z, 3, nil, "FX", "NOCLICK", "DECOR", "INLIMBO")
					if #ents > 0 then
						if i <= ICE_DAMAGE_RINGS then
							for i, v2 in ipairs(ents) do
								if v2 ~= inst and v2:IsValid() then
									-- Don't net any insects when we do work
									if v2.components.workable ~= nil and
											v2.components.workable:CanBeWorked() and
											v2.components.workable.action ~= ACTIONS.NET then
										local dst = v:Dist(v2:GetPosition())
										local dmg_mult = 1 - dst / 1.34
										v2.components.workable:WorkedBy(inst, 2 * dmg_mult)
										--v2.components.workable:Destroy(inst)
									end
								end
							end
						end
						if i <= ICE_DESTRUCTION_RINGS then
							-- 鹿角怪攻击力
							local defaultdamage = inst.components.combat.defaultdamage
							for i, v2 in ipairs(ents) do
								if v2 ~= inst and v2:IsValid() and v2.components.health ~= nil and not v2.components.health:IsDead() and inst.components.combat:CanTarget(v2) then
									--技能伤害
									v2.components.combat:GetAttacked(inst, defaultdamage*4)
								end
							end
						end
					end
				end

				if TheWorld.Map:IsPassableAtPoint(v:Get()) then
					SpawnPrefab("qm_ice002").Transform:SetPosition(v.x, 0, v.z)
				end
			end
		end)
		delay = delay + ICE_RING_DELAY
	end
end

--技能2
local function Deerclops_Skill2(inst, target)
	if not inst or not target then
		return
	end	
	
	--查找目标范围
	local maxices = math.random(2, 5)
	local delta = (1 + math.random()) * PI / maxices
	local offset = 2 * PI * math.random()
	local angles = {}
	local targets = {}

	local targetPos = target:GetPosition()
	local angle = inst:GetAngleToPoint(targetPos:Get())
	table.insert(angles, angle)

	for i = 1, maxices - 1 do
		table.insert(angles, i * delta + angle + offset)
	end

	local pt = inst:GetPosition()
	local minrange = 4
	local maxrange = 8.75
	for i = 1, 2 do
		local closerange = (minrange + maxrange) * .5
		local objectives = TheSim:FindEntities(pt.x, 0, pt.z, closerange, { "_combat", "_health" }, { "player", "INLIMBO" })
		if #objectives < 1 then
			break
		end
		maxrange = closerange
	end

	local range = GetRandomMinMax(minrange, maxrange)
	while #angles > 0 do
		local theta = table.remove(angles, math.random(#angles))
		local offset = FindWalkableOffset(pt, theta, range, 12, true)
		if offset ~= nil then
			offset.x = offset.x + pt.x
			offset.y = 0
			offset.z = offset.z + pt.z
			table.insert(targets, offset)
		end
	end
	
	if #targets > 0 then
		local pos = inst:GetPosition()
		for _, targetPos in pairs(targets) do			
			--沿直线扇形分段施放冰柱群
			local numFX = math.random(5, 10)
			local angle = inst:GetAngleToPoint(targetPos:Get())
			--多段36度扇形
			for j = 0, 4 do
				inst:DoTaskInTime(1 + 1 * j, function()
					ShakeAllCameras(CAMERASHAKE.VERTICAL, .5, .05, 2, inst, SHAKE_DIST)
				end)
				for i = 1, math.floor(numFX * ((4 - j) * 0.2 + 1)) do
					inst:DoTaskInTime(0.25 + math.random() * 0.75 + 1 * j, function(inst)
						local prefab = "weapon_fx005"
						local fx = SpawnPrefab(prefab)
						if fx then
							local fx_angle = math.random(angle - 18, angle + 18) * DEGREES
							local fx_r = math.random(0, 6) + 6 * j
							local offset = Vector3(fx_r * math.cos(fx_angle), 0, -fx_r * math.sin(fx_angle))
							local pt = pos + offset
							fx.Transform:SetPosition(pt:Get())
							--fx.Transform:SetScale(1.6,3 + 0.5*j,1.6)
							--冰柱伤害
							local r = 1.33
							local center_dmg = (120 - 60 / 18 * fx_r) / 3
							local ceter_destory = 2
							local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, r, nil, "FX", "NOCLICK", "DECOR", "INLIMBO")
							for k, v in pairs(ents) do
								-- 同物种之间可以互相伤害 and v.prefab ~= inst.prefab
								if v and v.components.health and not v.components.health:IsDead() and v ~= inst then
									if v.components.combat then
										v.components.combat:GetAttacked(inst, center_dmg)
									end
								end

								if v and v:IsValid() and v.components.workable and v.components.workable:CanBeWorked() then
									local dst = pt:Dist(v:GetPosition())
									local dmg_mult = 1 - dst / r
									v.components.workable:WorkedBy(inst, ceter_destory * dmg_mult)
								end
							end
						end
					end)
				end
			end
		end
	end
end

--暴怒被动
local function Deerclops_AngerSkill(inst)
	local x, y, z = inst.Transform:GetWorldPosition()        --获取巨鹿的位置
	local ents = {}                                        	 --建立空实体表,用于存储巨鹿要攻击的对象内容
	local ents = TheSim:FindEntities(x, y, z, 20, { "_combat", "_health" }, { "FX", "NOCLICK", "DECOR", "INLIMBO", "smallcreature", "playerghost", "deerclops" })
	if ents[1] ~= nil and inst and not inst:HasTag("bingci")  then
		inst:AddTag("bingci")                --给巨鹿添加"bingci"冰刺标记
		if ents[1] ~= nil then			
			inst:StartThread(function()		--启动线程追踪
				for k = 1, 20 do
					local target = ents[1] and ents[math.random(#ents)] or nil                        --在实体表中,选择目标第一个为目标,并且列入多项,实体表总数或者为空值
					if target ~= nil and target:IsValid() and target.components.health then
						local hurt = math.random(80, 180)                                        --定义一个伤害值,伤害值在80~180的随机值范围
						if inst and inst ~= nil and inst:IsValid() and target and target ~= nil and target:IsValid() then
							local q_1, w_1, e_1 = inst.Transform:GetWorldPosition()
							local q_2, w_2, e_2 = target.Transform:GetWorldPosition()
							local theta = math.random() * 2 * PI                        						--用PI函数,获取一个半径随机角度值,即,随机0~2的圆形角度值
							local radius = math.random(2, 6)                                					--定义一个随机2~6距离
							local result_offset = FindValidPositionByFan(theta, radius, 24, function(offset)	--得到一个偏移值,巨鹿和目标的相对位置           
								local x, y, z = (Vector3(q_1, w_1, e_1) + offset):Get()        					--以巨鹿为偏移点做位置获取
								local ents = TheSim:FindEntities(x, y, z, 1)
								return TheWorld.Map:IsPassableAtPoint(x, y, z) and not next(ents)    			--查找的实体是否在世界中,否则更换下一个实体目标
							end)

							if result_offset then
								--声明巨鹿的偏移位置获取xyz
								local b, n, m = (Vector3(q_1, w_1, e_1) + result_offset):Get()
								local A = SpawnPrefab("ice")
								local ph = A.entity:AddPhysics()
								ph:SetSphere(0)
								A.components.inventoryitem.canbepickedup = false
								A.AnimState:SetBank("ice")
								A.AnimState:SetBuild("shadow_creatures_ground")
								A.Transform:SetPosition(b, 0, m)
								A._on = Vector3(q_2, w_2, e_2)
								if target ~= nil and target:IsValid() and target.components.health and not target.components.health:IsDead() then
									A._me = inst            --定义两个数组接收坐标数据,巨鹿的坐标和目标的坐标
									A._in = target
								else
									A._on = Vector3(q_2, w_2, e_2)    --如果目标不符合条件需求,那么目标数据等于初始化的目标数据
								end
								A._dwuli = A:DoPeriodicTask(7 * FRAMES, function()
									if A._in ~= nil and A._in:IsValid() and A._in.Transform and A._in.components.health and not A._in.components.health:IsDead() then
										A._on = A._in:GetPosition()                --这里重新定义A._on的数据,即,冰特效的位置,等于目标数据实体获取的世界位置数据,因为目标往往是动态的\变化的
									end
									local hp = A:GetPosition()                    --声明 冰特效的位置:hp
									local pt = A._on or (Vector3(5, 0, 5) + hp)    --定义 冰特效的位置为实时获取到的巨鹿攻击目标的坐标,或冰特效的位置的5*5的范围为坐标
									local vel = (hp - pt):GetNormalized()        --求得一个归一化向量值
									local speed = 6 + math.random() * 2            --设置一个随机值:6 + (0~2)的随机值,作为速度值
									local angle = math.atan2(vel.z, vel.x) + DEGREES    --设置一个角度值(归一化向量的反余弦值)+DEGREES 值(ByLaolu注:DEGREES 不清楚他在那里声明的,可能在Tunning.lua中或者他自己声明的一个全局常量值)

									A.Physics:SetMotorVel(-math.cos(angle) * speed, 0, -math.sin(angle) * speed)    --[[调用物理:SetMotorVel()函数,做个持续特效,输入:角度值的负余弦值 * 速度,高度为0,角度值的负正弦值 * 速度]]
									local x, y, z = A:GetPosition():Get()            --获取冰特效的位置
									--取两个绝对值
									local oiu = math.abs(x) - math.abs(A._on.x)            --冰特效x位置被子冰特效x位置相减
									local uio = math.abs(z) - math.abs(A._on.z)            --冰特效y位置被子冰特效y位置相减
									local B = TheSim:FindEntities(x, 0, z, 1)            --查找冰特效坐标范围1码内的实体,创建子冰特效
									--在查找到的实体表中,为每个对象循环执行
									for k, v in pairs(B) do
										--如果有查找到的实体,并且 实体不为空,并且 实体有坐标,并且 实体有生命组件,并且 实体未死亡并且输入坐标和实体坐标值相等,那么执行
										--这里代码有多余的:A._in ~= nil,可能没有注意
										if v and v ~= A and A._in ~= nil and A._in ~= nil and A._in.components.health and not A._in.components.health:IsDead() and v == A._in then
											local prefab = "icespike_fx_"..math.random(1, 4)     --随机创建"icespike_fx_1","icespike_fx_2","icespike_fx_3","icespike_fx_4",特效实体

											local C = SpawnPrefab(prefab)                --创建冰特效
											if C ~= nil then
												C.Transform:SetScale(3, 3, 3)                --设置大小和位置
												C.Transform:SetPosition(v:GetPosition():Get())
												local L = nil                --定义一个无类型的空值
												local L = TheSim:FindEntities(hp.x, 0, hp.z, 3)        --存储查找到的距离冰特效3码范围内的实体数据
												for p, o in pairs(L) do
													--在查找到的实体表中循环执行
													--如果该实体不为空,并且 巨鹿有坐标值,并且 巨鹿坐标值不为空值,并且 实体不是巨鹿自身,并且实体有生命组件且没有死亡,那么执行
													if o ~= nil and A._me and A._me ~= nil and o ~= A._me and o.components.health and not o.components.health:IsDead() 
													and o.components.combat	--ByLaoluFix 2021-06-10 修复无战斗组件错误
													then
														o.components.combat:GetAttacked(A, hurt or 10) --该实体可以进行战斗的范围值为10码或jn值数据
													end
												end
											end
											A:Remove()                --子特效执行后,删除冰特效主对象"ice"实体
										end
									end
									if math.abs(oiu) <= .5 and math.abs(uio) <= .5 then
										--绝对值比较,如果子冰特效xy位置oiu值和uio值(见上面代码段)小于0.5,那么执行
										--重新创建附属子特效(次子冰特效),等于oip或者重新随机创建"icespike_fx_1","icespike_fx_2","icespike_fx_3","icespike_fx_4",特效实体
										local prefab = "icespike_fx_"..math.random(1, 4) or "icespike_fx_" .. math.random(1, 4)

										local C = SpawnPrefab(prefab)            --创建次子冰特效
										if C ~= nil then
											--如果次子冰特效不为空,那么设置他的缩放值和位置
											C.Transform:SetScale(3, 3, 3)
											C.Transform:SetPosition(hp:Get())
											-----------------------------------------特效处理收尾部分-------------------------------
											A.Physics:Stop()            --设置 冰特效物理禁用
											--计时器的返回和中断处理
											if A._dwuli then
												A._dwuli:Cancel()
												A._dwuli = nil
											end
											------再次执行一次 次子冰特效,让动画有个后续缓和过程,注释略
											local L = nil
											local L = TheSim:FindEntities(hp.x, 0, hp.z, 3)
											--重写
											if GetTableSize(L) >0 then
												for p, o in pairs(L) do
													if o ~= nil and o:IsValid() and A ~=nil and A:IsValid() and A._me ~=nil 
													and o ~= A._me and o.components.health and not o.components.health:IsDead() 
													and o.components.combat	--ByLaoluFix 2021-06-10 修复无战斗组件错误
													then
														o.components.combat:GetAttacked(A, hurt or 10)
													end
												end	
											end
											--[[
											for p, o in pairs(L) do
												if o ~= nil and A._me and A._me ~= nil and o ~= A._me and o.components.health and not o.components.health:IsDead() 
												and o.components.combat	--ByLaoluFix 2021-06-10 修复无战斗组件错误
												then
													o.components.combat:GetAttacked(A, hurt or 10)
												end
											end
											]]
										end
										A:Remove()
									else
										local prefab = "icespike_fx_"..math.random(1, 4) or "icespike_fx_" .. math.random(1, 4)
										local C = SpawnPrefab(prefab)
										if C ~= nil then
											C.Transform:SetPosition(hp:Get())
										end
									end
								end)
								--冰特效创建8秒后,执行下面功能
								A._bh1 = A:DoTaskInTime(8, function()
									--如果计时器_dwuli不为空,那么计时器退出,并清空计时器为空值
									if A._dwuli then
										A._dwuli:Cancel()
										A._dwuli = nil
									end
									A.Physics:Stop()    --禁用冰特效的物理
									A:Remove()            --移除冰实体"ice"
								end)
							end
						end
					end
					Sleep(0.5)                                                                --为了避免错误,造成多项判定抖动,这里添加0.5秒的休息cd,类似动作cd间隔
				end
			end)
		end
		inst:DoTaskInTime(25, function()
			inst:RemoveTag("bingci")
		end)                            --巨鹿初始化计时:25秒后执行移除:"bingci"冰刺标记,即,巨鹿战斗或休息25秒后有技能cd重置
	end
end

local events = {
	CommonHandlers.OnLocomote(false, true),
	CommonHandlers.OnSleep(),
	CommonHandlers.OnFreeze(),
	EventHandler("doattack", function(inst)
		if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
			if not inst.components.timer:TimerExists("skill_cd") and not GetBoost(inst,0) then
				if GetBoost(inst,1) then
					inst.sg:GoToState("deerclops_skill1")
				elseif GetBoost(inst,2) then
					inst.sg:GoToState("deerclops_skill2")
				end
			else
				inst.sg:GoToState("attack")
			end
		end
	end),
	EventHandler("attacked", function(inst)
		if inst.components.health ~= nil and not inst.components.health:IsDead() and inst.sg:HasStateTag("frozen") then
			inst.sg:GoToState("hit")
		end
	end),
	CommonHandlers.OnDeath(),
}

local states = {
	State {
		name = "deerclops_skill1",
		tags = { "attack", "busy" },
		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("taunt")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/taunt_grrr")
			local pt = inst:GetPosition()
			SpawnPrefab("groundpoundring_fx").Transform:SetPosition(pt:Get())
			inst.components.health.absorb = .9
			--inst.Light:Enable(true)
			inst.sg:SetTimeout(150 * FRAMES)
		end,
		timeline = {
			TimeEvent(60 * FRAMES, function(inst)
				inst.AnimState:PlayAnimation("taunt")
				inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/taunt_grrr")
				local pt = inst:GetPosition()
				SpawnPrefab("groundpoundring_fx").Transform:SetPosition(pt:Get())
			end),
			TimeEvent(80 * FRAMES, function(inst)
				Deerclops_Skill1(inst, inst.components.combat.target)
				if not inst.components.timer:TimerExists("skill_cd") then
					inst.components.timer:StartTimer("skill_cd", inst.skill_cd or 1)
				end
			end),
			TimeEvent(100 * FRAMES, function(inst)
				inst.sg:GoToState("idle")
			end),
		},
		ontimeout = function(inst)
			inst.sg:GoToState("idle")
		end,
		onexit = function(inst)
			inst.components.health.absorb = 0
		end,
	},

	State {
		name = "deerclops_skill2",
		tags = { "attack", "busy" },
		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("taunt")
		end,
		timeline = {
			TimeEvent(5 * FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/taunt_grrr")
			end),
			TimeEvent(10 * FRAMES, function(inst)
				local x, y, z = inst.Transform:GetWorldPosition()
				local ents = TheSim:FindEntities(x, y, z, 20, {"player"}, {"playerghost"})
				for k, v in pairs(ents) do
					SpawnPrefab("er_tips_label"):set("<拽回>", 1).Transform:SetPosition(v.Transform:GetWorldPosition())
					v.components.locomotor:Stop()
					v:ClearBufferedAction()
					v.AnimState:PlayAnimation("idle_groggy", true)
					v.sg:SetTimeout(3)						
					v.Transform:SetPosition(x, 0, z)
				end               
			end),
			TimeEvent(16 * FRAMES, function(inst)
				Deerclops_Skill2(inst, inst.components.combat.target)
				if not inst.components.timer:TimerExists("skill_cd") then
					inst.components.timer:StartTimer("skill_cd", inst.skill_cd or 1)
				end
			end),
		},
		events = {
			CommonHandlers.OnNoSleepAnimOver("idle"),
		},
		ontimeout = function(inst)
			inst.sg:GoToState("idle", true)
			local target = inst.components.combat.target
			if target and target:HasTag("player") then
				target.sg:GoToState("idle", true)
			end
		end,
		onexit = function(inst)
		end,
	},

	State {
		name = "attack",
		tags = { "attack", "busy" },
		onenter = function(inst, target)
			if inst.components.locomotor ~= nil then
				inst.components.locomotor:StopMoving()
			end
			inst.AnimState:PlayAnimation("atk")
			inst.components.combat:StartAttack()

			inst.sg.statemem.target = target
		end,
		timeline = {
			TimeEvent(0 * FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/attack")
			end),
			TimeEvent(29 * FRAMES, function(inst)
				SpawnIceFx(inst, inst.components.combat.target)
			end),
			TimeEvent(35 * FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/swipe")
				inst.components.combat:DoAttack(inst.sg.statemem.target)
				if inst.bufferedaction and inst.bufferedaction.action == ACTIONS.HAMMER then
					inst.bufferedaction.target.components.workable:SetWorkLeft(1)
					inst:PerformBufferedAction()
				end
				ShakeAllCameras(CAMERASHAKE.FULL, .5, .05, 2, inst, SHAKE_DIST)
			end),
			TimeEvent(36 * FRAMES, function(inst)
				inst.sg:RemoveStateTag("attack")
				if inst.anger and math.random() < 0.3 then
					Deerclops_AngerSkill(inst)
				end
			end),
		},
		events = {
			CommonHandlers.OnNoSleepAnimOver("idle"),
		},
	},

	State {
		name = "gohome",
		tags = { "busy" },
		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("taunt")
			inst:ClearBufferedAction()
			inst.components.knownlocations:RememberLocation("home", nil)
		end,
		timeline = {
			TimeEvent(5 * FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/taunt_grrr")
			end),
			TimeEvent(16 * FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/taunt_howl")
			end),
		},
		events = {
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	},

	State {
		name = "taunt",
		tags = { "busy" },
		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("taunt")

			if inst.bufferedaction and inst.bufferedaction.action == ACTIONS.GOHOME then
				inst:PerformBufferedAction()
			end
		end,
		timeline = {
			TimeEvent(5 * FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/taunt_grrr")
			end),
			TimeEvent(16 * FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/taunt_howl")
			end),
		},
		events = {
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	},

	State {
		name = "death",
		tags = { "busy" },
		onenter = function(inst)
			if inst.components.locomotor then
				inst.components.locomotor:StopMoving()
			end
			inst.AnimState:PlayAnimation("death")
			RemovePhysicsColliders(inst)
		end,
		timeline = {
			TimeEvent(0 * FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/death")
			end),
			TimeEvent(50 * FRAMES, function(inst)
				if TheWorld.state.snowlevel > 0.02 then
					inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/bodyfall_snow")
				else
					inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/bodyfall_dirt")
				end
				ShakeAllCameras(CAMERASHAKE.FULL, .7, .02, 3, inst, SHAKE_DIST)
				DoBoost(inst)
			end),
		},
	},
}

CommonStates.AddWalkStates(states,
{
	starttimeline = {
		TimeEvent(7 * FRAMES, DeerclopsFootstep),
	},
	walktimeline = {
		TimeEvent(23 * FRAMES, DeerclopsFootstep),
		TimeEvent(42 * FRAMES, DeerclopsFootstep),
	},
	endtimeline = {
		TimeEvent(5 * FRAMES, DeerclopsFootstep),
	},
})
CommonStates.AddIdle(states)
CommonStates.AddSleepStates(states, {
	sleeptimeline = {
		--TimeEvent(46*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.grunt) end)
	},
})
CommonStates.AddFrozenStates(states)

return StateGraph("deerclops", states, events, "idle", actionhandlers)