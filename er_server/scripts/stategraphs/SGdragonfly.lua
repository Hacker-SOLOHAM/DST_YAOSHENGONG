--龙蝇SG
require("stategraphs/commonstates")

local ICE_NUM_RINGS = 5				--冰环数量
local ICE_DAMAGE_RINGS = 4			--冰环伤害
local ICE_DESTRUCTION_RINGS = 5		--冰环
local ICE_RING_DELAY = 0.2			--冰环延迟

--技能
local function Dragonfly_Skill(inst, target)
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
				local numPoints = 0.5 * PI * radius
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
									if v2.components.workable ~= nil and
											v2.components.workable:CanBeWorked() and
											v2.components.workable.action ~= ACTIONS.NET then
										local dst = v:Dist(v2:GetPosition())
										local dmg_mult = 1 - dst / 1.34
										v2.components.workable:WorkedBy(inst, 2 * dmg_mult)
									end
								end
							end
						end
						if i <= ICE_DESTRUCTION_RINGS then
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
					SpawnPrefab("rg_flamefx01").Transform:SetPosition(v.x, 0, v.z)
				end
			end
        end)
        delay = delay + ICE_RING_DELAY
    end
end

--暴怒被动
local function Dragonfly_AngerSkill(inst, target)
    if not inst or not target then
        return
    end
	local points = {}
	local radius = 9
	local theta = 0
	for p = 1, 5 do
		if not points then
			points = {}
		end
		local offset = Vector3(radius * math.cos(theta), 0, -radius * math.sin(theta))
		local point = inst:GetPosition() + offset
		table.insert(points, point)
		theta = theta - (2 * PI / 5)
	end
	for k, v in pairs(points) do
		if TheWorld.Map:IsPassableAtPoint(v:Get()) then
			local item = SpawnPrefab("rg_flamefx02")
			item.Transform:SetPosition(v.x, 0, v.z)
			item:DoTaskInTime(.5, function(item)
				local ents = TheSim:FindEntities(v.x, 0, v.z, 25, { "player" }, { "playerghost" })
				if ents and ents[1] and ents[1]:IsValid() and ents[1].components.health and not ents[1].components.health:IsDead() then
					local hp = item:GetPosition()
					local pt = ents[1]:GetPosition()
					local vel = (hp - pt):GetNormalized()
					local angle = math.atan2(vel.z, vel.x) + DEGREES
					local shijian_1 = math.abs(math.abs(hp.x - pt.x) / (math.cos(angle) * 50))
					local shijian_2 = math.floor(shijian_1 * 10)
					local shijian_3 = shijian_2 > 0 and (shijian_2 * 4) or 5
					item.Physics:SetMotorVel(-math.cos(angle) * 50, -5, -math.sin(angle) * 50)
					item:DoTaskInTime(shijian_3 * 1.5 * FRAMES, function(item, yu)
						item.Physics:Stop()
						if yu and ents[1]:IsValid() and yu.components.health and not yu.components.health:IsDead() then
							local defaultdamage = inst.components.combat.defaultdamage
							--技能伤害
							yu.components.combat:GetAttacked(item, defaultdamage)
							Launch(item, yu)
							item:Remove()
						end
					end, ents[1])
				end
			end)
		end
	end
end

local function ChooseAttack(inst)
    inst.sg:GoToState(inst.enraged and inst.can_ground_pound and "pound_pre" or "attack")
    return true
end

local actionhandlers = {
    ActionHandler(ACTIONS.GOHOME, "flyaway"),
}

local events = {
    CommonHandlers.OnLocomote(false, true),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnSleepEx(),
    CommonHandlers.OnWakeEx(),
	EventHandler("doattack", function(inst)
        if not (inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("grounded") or inst.components.health:IsDead()) then
			ChooseAttack(inst)
			if inst.skill_cd ~= nil and not GetBoost(inst,0) then
				if not inst.components.timer:TimerExists("skill_cd") then
					inst.sg:GoToState("dragonfly_skill")
					return true
				end
			end
			inst.sg:GoToState("attack")
			return false
		end
		if math.random() < 0.2 then
			local target = inst.components.combat.target
			if target and target:HasTag("player")  then
				target.components.burnable:Ignite()
			end
		end
    end),
	EventHandler("attacked", function(inst)
        if (not inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("caninterrupt")) and not inst.components.health:IsDead() then
			if inst.sg:HasStateTag("grounded") then
				inst.sg.statemem.knockdown = true
				inst.sg:GoToState("knockdown_hit")
			elseif (inst.sg.mem.last_hit_time or 0) + TUNING.DRAGONFLY_HIT_RECOVERY <= GetTime() then
				inst.sg:GoToState("hit")
			end
		end
    end),
    EventHandler("stunned", function(inst)
        if not inst.components.health:IsDead() then
			inst.sg:GoToState("knockdown")
		end
    end),
    EventHandler("stun_finished", function(inst)
        if inst.sg:HasStateTag("grounded") and not inst.components.health:IsDead() then
			if inst.sg.mem.sleeping then
				inst.sg.statemem.continuesleeping = true
				inst.sg:GoToState("sleeping")
			else
				inst.sg.statemem.knockdown = true
				inst.sg:GoToState("knockdown_pst")
			end
		end
    end),
    EventHandler("spawnlavae", function(inst)
        if not inst.sg.mem.wantstospawn then
			inst.sg.mem.wantstospawn = true
			if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
				inst.sg:GoToState("lavae")
			end
		end
    end),
    EventHandler("transform", function(inst,data)
        if not (inst.sg:HasStateTag("frozen") or inst.sg:HasStateTag("grounded") or inst.sg:HasStateTag("sleeping") or inst.sg:HasStateTag("flight") or inst.components.health:IsDead()) then
			inst.sg:GoToState("transform_"..data.transformstate)
		end
    end),
	EventHandler("stunned", function(inst)
		return
	end),
}

local states = {
	State {
        name = "dragonfly_skill",
        tags = { "attack", "busy" },
        onenter = function(inst)
            inst.Physics:Stop()
			inst.AnimState:PlayAnimation("taunt")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/taunt_grrr")
			local pt = inst:GetPosition()
			SpawnPrefab("groundpoundring_fx").Transform:SetPosition(pt:Get())
            inst.components.health.absorb = .9
            inst.sg:SetTimeout(150 * FRAMES)
        end,
        timeline = {
			TimeEvent(25 * FRAMES, function(inst)
                inst.AnimState:PlayAnimation("taunt")
				inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/taunt_grrr")
				local pt = inst:GetPosition()
				SpawnPrefab("groundpoundring_fx").Transform:SetPosition(pt:Get())
            end),
			TimeEvent(50 * FRAMES, function(inst)
                inst.AnimState:PlayAnimation("taunt")
				inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/taunt_grrr")
				local pt = inst:GetPosition()
				SpawnPrefab("groundpoundring_fx").Transform:SetPosition(pt:Get())
            end),
            TimeEvent(55 * FRAMES, function(inst)
                Dragonfly_Skill(inst, inst.components.combat.target)
                if not inst.components.timer:TimerExists("skill_cd") then
                    inst.components.timer:StartTimer("skill_cd", inst.skill_cd or 1)
                end
            end),
			TimeEvent(65 * FRAMES, function(inst)
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
	
	
    State{
        name = "idle",
        tags = { "idle" },
        onenter = function(inst)
            if inst.sg.mem.sleeping then
                inst.sg:GoToState("sleep")
            elseif inst.sg.mem.wantstospawn then
                inst.sg:GoToState("lavae")
            else
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("idle", true)
            end
        end,
    },

    State{
        name = "walk_start",
        tags = { "moving", "canrotate" },
        onenter = function(inst)
            if inst.enraged then
                inst.AnimState:PlayAnimation("walk_angry_pre")
                inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/angry")
            else
                inst.AnimState:PlayAnimation("walk_pre")
            end
            if inst.sg.mem.flyover then
                if not inst.sg.mem.flyoverphysics then
					inst.sg.mem.flyoverphysics = true
					inst.sg.mem.last_hit_time = GetTime()
					inst.hit_recovery = TUNING.DRAGONFLY_FLYING_HIT_RECOVERY
					inst.Physics:ClearCollisionMask()
					inst.Physics:CollidesWith(COLLISION.WORLD)
					inst.Physics:CollidesWith(COLLISION.GIANTS)
				end
            end
            inst.components.locomotor:WalkForward()
        end,
        timeline = {
            TimeEvent(1*FRAMES, function(inst) if not inst.enraged then inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/blink") end end),
            TimeEvent(2*FRAMES, function(inst) if inst.enraged then inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/blink") end end),
        },
        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg.statemem.walking = true
                    inst.sg:GoToState("walk")
                end
            end),
        },
        onexit = function(inst)
            if not (inst.sg.statemem.walking and inst.sg.mem.flyover) then
                if inst.sg.mem.flyoverphysics then
					inst.sg.mem.flyoverphysics = false
					inst.hit_recovery = TUNING.DRAGONFLY_HIT_RECOVERY
					inst.Physics:ClearCollisionMask()
					inst.Physics:CollidesWith(COLLISION.WORLD)
					inst.Physics:CollidesWith(COLLISION.CHARACTERS)
					inst.Physics:CollidesWith(COLLISION.GIANTS)
				end
            end
        end,
    },

    State{
        name = "walk",
        tags = { "moving", "canrotate" },
        onenter = function(inst)
            if inst.enraged then
                inst.AnimState:PlayAnimation("walk_angry")
                if math.random() < .5 then
                    inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/angry")
                end
            else
                inst.AnimState:PlayAnimation("walk")
            end
            if inst.sg.mem.flyover then
                if not inst.sg.mem.flyoverphysics then
					inst.sg.mem.flyoverphysics = true
					inst.sg.mem.last_hit_time = GetTime()
					inst.hit_recovery = TUNING.DRAGONFLY_FLYING_HIT_RECOVERY
					inst.Physics:ClearCollisionMask()
					inst.Physics:CollidesWith(COLLISION.WORLD)
					inst.Physics:CollidesWith(COLLISION.GIANTS)
				end
            end
            inst.components.locomotor:WalkForward()
        end,
        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg.statemem.walking = true
                    inst.sg:GoToState("walk")
                end
            end),
        },
        onexit = function(inst)
            if not (inst.sg.statemem.walking and inst.sg.mem.flyover) then
                if inst.sg.mem.flyoverphysics then
					inst.sg.mem.flyoverphysics = false
					inst.hit_recovery = TUNING.DRAGONFLY_HIT_RECOVERY
					inst.Physics:ClearCollisionMask()
					inst.Physics:CollidesWith(COLLISION.WORLD)
					inst.Physics:CollidesWith(COLLISION.CHARACTERS)
					inst.Physics:CollidesWith(COLLISION.GIANTS)
				end
            end
        end,
    },

    State{
        name = "walk_stop",
        tags = { "canrotate" },
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation(inst.enraged and "walk_angry_pst" or "walk_pst")
        end,
        timeline = {
            TimeEvent(1*FRAMES, function(inst) if not inst.enraged then inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/blink") end end),
            TimeEvent(2*FRAMES, function(inst) if inst.enraged then inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/blink") end end),
        },
        events = {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "hit",
        tags = { "hit", "busy" },
        onenter = function(inst, cb)
            inst.sg.mem.last_hit_time = GetTime()
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("hit")
            inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/blink")
        end,
        timeline = {
            TimeEvent(9 * FRAMES, function(inst)
                if inst.sg.statemem.doattack then
                    if not inst.components.health:IsDead() and ChooseAttack(inst) then
                        return
                    end
                    inst.sg.statemem.doattack = nil
                end
                inst.sg:RemoveStateTag("busy")
            end),
            TimeEvent(17 * FRAMES, function(inst)
                inst.sg:AddStateTag("busy")
            end),
        },
        events = {
            EventHandler("doattack", function(inst)
                inst.sg.statemem.doattack = true
            end),
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    if inst.sg.statemem.doattack and ChooseAttack(inst) then
                        return
                    end
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "knockdown",
        tags = { "busy", "nosleep" },
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            --Start tracking progress towards breakoff loot
            inst.AnimState:PlayAnimation("hit_large")
            inst.components.damagetracker:Start()
        end,
        timeline = {
            TimeEvent(20*FRAMES, function(inst)
                inst.SoundEmitter:KillSound("flying")
            end),
            TimeEvent(22*FRAMES, function(inst)
                if inst.enraged then
                    inst:TransformNormal()
                    inst.SoundEmitter:KillSound("fireflying")
                end
            end)
        },
        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg.statemem.knockdown = true
                    inst.sg:GoToState("knockdown_idle")
                end
            end),
        },
        onexit = function(inst)
            if inst.sg.statemem.knockdown then
                inst.SoundEmitter:KillSound("flying")
                if inst.enraged then
                    inst:TransformNormal()
                    inst.SoundEmitter:KillSound("fireflying")
                end
            else
                inst.components.damagetracker:Stop()
                if not inst.SoundEmitter:PlayingSound("flying") then
                    inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/fly", "flying")
                end
            end
        end,
    },

    State{
        name = "knockdown_idle",
        tags = { "grounded", "nosleep" },
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("sleep_loop")
        end,
        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg.statemem.knockdown = true
                    inst.sg:GoToState("knockdown_idle")
                end
            end),
        },
        onexit = function(inst)
            if not inst.sg.statemem.knockdown then
                inst.components.damagetracker:Stop()
                if not (inst.sg.statemem.continuesleeping or inst.SoundEmitter:PlayingSound("flying")) then
                    inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/fly", "flying")
                end
            end
        end,
    },

    State{
        name = "knockdown_hit",
        tags = { "busy", "grounded", "nosleep" },
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("hit_ground")
        end,
        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg.statemem.knockdown = true
                    inst.sg:GoToState("knockdown_idle")
                end
            end),
        },
        onexit = function(inst)
            if not inst.sg.statemem.knockdown then
                inst.components.damagetracker:Stop()
                if not (inst.sg.statemem.continuesleeping or inst.SoundEmitter:PlayingSound("flying")) then
                    inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/fly", "flying")
                end
            end
        end,
    },

    State{
        name = "knockdown_pst",
        tags = { "busy", "nosleep" },
        onenter = function(inst)
            inst.AnimState:PlayAnimation("sleep_pst")
            inst.components.damagetracker:Stop()
            --Stop tracking progress towards breakoff loot
        end,
        timeline = {
            TimeEvent(16*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/blink") end),
            TimeEvent(26*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/fly", "flying") end),
        },
        events = {
            CommonHandlers.OnNoSleepAnimOver("idle"),
        },
        onexit = function(inst)
            if not inst.SoundEmitter:PlayingSound("flying") then
                inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/fly", "flying")
            end
        end,
    },

    State{
        name = "flyaway",
        tags = { "flight", "busy", "nosleep", "nofreeze" },
        onenter = function(inst)
            inst.Physics:Stop()
            inst.DynamicShadow:Enable(false)
            inst.components.health:SetInvincible(true)

            inst.AnimState:PlayAnimation("taunt_pre")
            inst.AnimState:PushAnimation("taunt")
            inst.AnimState:PushAnimation("taunt_pst") --59 frames

            inst.AnimState:PushAnimation("walk_angry_pre") -- 75 frames
            inst.AnimState:PushAnimation("walk_angry", true)
        end,
        timeline = {
            TimeEvent(75*FRAMES, function(inst)
                inst.Physics:SetMotorVel(math.random()*4,7+math.random()*2,math.random()*4)
            end),
            TimeEvent(6, function(inst) 
                inst:DoDespawn()
            end)
        },
        onexit = function(inst)
            --You somehow left this state?! (not supposed to happen).
            --Cancel the action to avoid getting stuck.
            print("Dragonfly left the flyaway state! How could this happen?!")
            inst.components.health:SetInvincible(false)
            inst:ClearBufferedAction()
        end,
    },

    State{
        name = "attack",
        tags = { "attack", "busy", "canrotate" },
        onenter = function(inst)
            inst.components.combat:StartAttack()
            inst.sg.statemem.target = inst.components.combat.target
            inst.AnimState:PlayAnimation("atk")
            if inst.enraged then
                local attackfx = SpawnPrefab("attackfire_fx")
                attackfx.Transform:SetPosition(inst.Transform:GetWorldPosition())
                attackfx.Transform:SetRotation(inst.Transform:GetRotation())
            end
        end,
        timeline = {
            TimeEvent(7*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/swipe") end),
            TimeEvent(15*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/punchimpact")
                inst.components.combat:DoAttack(inst.sg.statemem.target)
                if inst.components.combat.target and inst.components.combat.target.components.health and inst.enraged then
                    inst.components.combat.target.components.health:DoFireDamage(5)
                end
				if inst.anger and math.random() < 0.3 then
					Dragonfly_AngerSkill(inst, inst.components.combat.target)
				end
            end),
        },
        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "transform_fire",
        tags = { "busy" },
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.Physics:Stop()
            if inst.enraged then
                inst.sg:GoToState("idle")
            else
                inst.AnimState:PlayAnimation("fire_on")
            end
        end,
        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
        timeline = {
            TimeEvent(2*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/blink") end),
            TimeEvent(7*FRAMES, function(inst)
                inst:TransformFire()
                inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/firedup", "fireflying")
            end),
        },
    },  

    State{
        name = "transform_normal",
        tags = { "busy" },
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.Physics:Stop()
            if not inst.enraged then
                inst.sg:GoToState("idle")
            else
                inst.AnimState:PlayAnimation("fire_off")
            end
        end,
        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
        timeline = {
            TimeEvent(2*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/blink") end),
            TimeEvent(17*FRAMES, function(inst)
                inst:TransformNormal()
                inst.SoundEmitter:KillSound("fireflying")
            end),
        },
    },

    State{
        name = "pound_pre",
        tags = { "busy" },
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt_pre")
        end,
        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("pound")
                end
            end),
        },
        timeline = {
            TimeEvent(2*FRAMES, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/blink") 
            end),
        },
    },

    State{
        name = "pound",
        tags = { "busy" },
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
            local tauntfx = SpawnPrefab("tauntfire_fx")
            tauntfx.Transform:SetPosition(inst.Transform:GetWorldPosition())
            tauntfx.Transform:SetRotation(inst.Transform:GetRotation())

            inst.can_ground_pound = false
            inst.components.timer:StartTimer("groundpound_cd", TUNING.DRAGONFLY_POUND_CD)
        end,
        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("pound_post")
                end
            end),
        },
        timeline = {
            TimeEvent(2*FRAMES, function(inst)
                inst.components.groundpounder:GroundPound()
                inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/buttstomp")
                inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/buttstomp_voice")
            end),
            TimeEvent(9*FRAMES, function(inst)
                inst.components.groundpounder:GroundPound()
                inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/buttstomp")
                inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/buttstomp_voice")
            end),
            TimeEvent(20*FRAMES, function(inst)
                inst.components.groundpounder:GroundPound()
                inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/buttstomp")
                inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/buttstomp_voice")
            end),
        },
    },

    State{
        name = "pound_post",
        tags = { "busy" },
        onenter = function(inst)
            inst.AnimState:PlayAnimation("taunt_pst")
        end,
        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
        timeline = {
            TimeEvent(1*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/blink") end),
        },
    },

    State{
        name = "lavae",
        tags = { "busy" },
        onenter = function(inst)
            inst.Transform:SetTwoFaced()
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("vomit")
            inst.vomitfx = SpawnPrefab("vomitfire_fx")
            inst.vomitfx.Transform:SetPosition(inst.Transform:GetWorldPosition())
            inst.vomitfx.Transform:SetRotation(inst.Transform:GetRotation())
            inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/vomitrumble", "vomitrumble")
        end,
        timeline = {
            TimeEvent(2*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/blink") end),
            TimeEvent(55*FRAMES, function(inst)
                inst.SoundEmitter:KillSound("vomitrumble")
                inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/vomit")
            end),
            TimeEvent(59*FRAMES, function(inst)
                inst.sg.mem.wantstospawn = nil
                if inst.brain ~= nil then
                    inst.brain:OnSpawnLavae()
                end
            end),
        },
        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
        onexit = function(inst)
            inst.Transform:SetSixFaced()
            if inst.vomitfx then
                inst.vomitfx:Remove()
            end
            inst.vomitfx = nil
            inst.SoundEmitter:KillSound("vomitrumble")
        end,
    },

    State{
        name = "sleep",
        tags = { "busy", "sleeping", "nowake", "caninterrupt" },
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("land")
            inst.AnimState:PushAnimation("land_idle", false)
            inst.AnimState:PushAnimation("takeoff", false)
            inst.AnimState:PushAnimation("sleep_pre", false)
        end,
        timeline = {
            TimeEvent(14*FRAMES, function(inst) inst.SoundEmitter:KillSound("flying") end),
            TimeEvent(16*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/blink")
                inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/land")
                if inst.enraged then
                    inst:TransformNormal()
                    inst.SoundEmitter:KillSound("fireflying")
                end
            end),
            TimeEvent(74*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/blink") end),
            TimeEvent(78*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/fly", "flying") end),
            TimeEvent(91*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/blink") end),
            TimeEvent(111*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/sleep_pre") end),
            TimeEvent(202*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/blink")
                inst.SoundEmitter:KillSound("flying")
                inst.sg:RemoveStateTag("caninterrupt")
            end),
            TimeEvent(203*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/land") end),
        },
        events = {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg.statemem.continuesleeping = true
                    inst.sg:GoToState(inst.sg.mem.sleeping and "sleeping" or "wake")
                end
            end),
        },
        onexit = function(inst)
            if not inst.sg.statemem.continuesleeping then
                --V2C: interrupted? bad! restore sound tho
                if not inst.SoundEmitter:PlayingSound("flying") then
                    inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/fly", "flying")
                end
                if inst.components.sleeper ~= nil and inst.components.sleeper:IsAsleep() then
                    inst.components.sleeper:WakeUp()
                end
            end
        end,
    },

    State{
        name = "sleeping",
        tags = { "busy", "sleeping" },
        onenter = function(inst)
            inst.AnimState:PlayAnimation("sleep_loop")
            if not inst.SoundEmitter:PlayingSound("sleep") then
                inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/sleep", "sleep")
            end
        end,
        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg.statemem.continuesleeping = true
                    inst.sg:GoToState("sleeping")
                end
            end),
        },
        onexit = function(inst)
            if not inst.sg.statemem.continuesleeping then
                --V2C: interrupted? bad! restore sound tho
                inst.SoundEmitter:KillSound("sleep")
                inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/fly", "flying")
                if inst.components.sleeper ~= nil and inst.components.sleeper:IsAsleep() then
                    inst.components.sleeper:WakeUp()
                end
            end
        end,
    },

    State{
        name = "wake",
        tags = { "busy", "waking", "nosleep" },
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("sleep_pst")
            inst.SoundEmitter:KillSound("sleep")
            inst.SoundEmitter:KillSound("flying")
            inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/wake")
            if inst.components.sleeper ~= nil and inst.components.sleeper:IsAsleep() then
                inst.components.sleeper:WakeUp()
            end
        end,
        timeline = {
            TimeEvent(16*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/blink") end),
            CommonHandlers.OnNoSleepTimeEvent(26 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/fly", "flying")
                inst.sg:RemoveStateTag("busy")
                inst.sg:RemoveStateTag("nosleep")
            end),
        },
        events = {
            CommonHandlers.OnNoSleepAnimOver("idle"),
        },
        onexit = function(inst)
            --V2C: in case we got interrupted
            if not inst.SoundEmitter:PlayingSound("flying") then
                inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/fly", "flying")
            end
        end,
    },

    State{
        name = "death",
        tags = { "busy" },
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.Light:Enable(false)
            inst.components.propagator:StopSpreading()
            inst.AnimState:PlayAnimation("death")
            inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/death")
            inst:AddTag("NOCLICK")
        end,
        timeline = {
            TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/blink") end),
            TimeEvent(26*FRAMES, function(inst)
                inst.SoundEmitter:KillSound("flying")
                inst.SoundEmitter:KillSound("fireflying")
            end),
            TimeEvent(28*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/land") end),
            TimeEvent(29*FRAMES, function(inst)
                ShakeAllCameras(CAMERASHAKE.FULL, .7, .02, .3, inst, 40)
                DoBoost(inst)
            end),
            TimeEvent(5, ErodeAway),
        },
        onexit = function(inst)
            --Should NOT reach here!
            inst:RemoveTag("NOCLICK")
        end,
    },

    State{
        name = "land",
        tags = { "flight", "busy" },
        onenter = function(inst)
            inst.AnimState:PlayAnimation("walk_angry", true)
            inst.Physics:SetMotorVelOverride(0,-11,0)
        end,
        onupdate = function(inst)
            inst.Physics:SetMotorVelOverride(0,-15,0)
            local x, y, z = inst.Transform:GetWorldPosition()
            if y < 2 then
                inst.Physics:ClearMotorVelOverride()
                inst.Physics:Stop()
                inst.Physics:Teleport(x, 0, z)
                inst.DynamicShadow:Enable(true)
                inst.sg:GoToState("idle", { softstop = true })
                ShakeAllCameras(CAMERASHAKE.FULL, .7, .02, .3, inst, 40)
            end
        end,
        onexit = function(inst)
            local x, y, z = inst.Transform:GetWorldPosition()
            if y > 0 then
                inst.Transform:SetPosition(x, 0, z)
            end
        end,
    },
}

CommonStates.AddFrozenStates(states,
    function(inst) --onoverridesymbols
        inst.SoundEmitter:KillSound("flying")
        if inst.enraged then
            inst:TransformNormal()
            inst.SoundEmitter:KillSound("fireflying")
        end
    end,
    function(inst) --onclearsymbols
        inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/fly", "flying")
    end
)

return StateGraph("dragonfly", states, events, "idle", actionhandlers)