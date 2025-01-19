GD_KiteAndAttack = Class(BehaviourNode, function(self, inst, safe_dist)
    BehaviourNode._ctor(self, "GD_KiteAndAttack")
    self.inst = inst
    -- self.ifrunfn = ifrunfn
    self.safe_dist = safe_dist
    self.numattacks = 0
    
    -- we need to store this function as a key to use to remove itself later
    self.onattackfn = function(inst, data)
        self:OnAttackOther(data.target) 
    end

    self.inst:ListenForEvent("onattackother", self.onattackfn)
    self.inst:ListenForEvent("onmissother", self.onattackfn)
end)

function GD_KiteAndAttack:__tostring()
    return string.format("target %s", tostring(self.inst.components.combat.target))
end

function GD_KiteAndAttack:OnStop()
    self.inst:RemoveEventCallback("onattackother", self.onattackfn)
    self.inst:RemoveEventCallback("onmissother", self.onattackfn)
end

function GD_KiteAndAttack:OnAttackOther(target)
    -- print ("on attack other", target)
    self.numattacks = self.numattacks + 1
    self.startruntime = nil -- reset max chase time timer
end

function GD_KiteAndAttack:GetRunAngle(pt, hp)
    if self.avoid_angle ~= nil then
        local avoid_time = GetTime() - self.avoid_time
        if avoid_time < 1 then
            return self.avoid_angle
        else
            self.avoid_time = nil
            self.avoid_angle = nil
        end
    end

    local angle = self.inst:GetAngleToPoint(hp) + 180 -15-- math.random(30)-15--偏角15度走位
    if angle > 360 then
        angle = angle - 360
    end

    --print(string.format("RunAway:GetRunAngle me: %s, hunter: %s, run: %2.2f", tostring(pt), tostring(hp), angle))

    local radius = 6

    local result_offset, result_angle, deflected = FindWalkableOffset(pt, angle*DEGREES, radius, 8, true, false) -- try avoiding walls
    if result_angle == nil then
        result_offset, result_angle, deflected = FindWalkableOffset(pt, angle*DEGREES, radius, 8, true, true) -- ok don't try to avoid walls, but at least avoid water
        if result_angle == nil then
            return angle -- ok whatever, just run
        end
    end

    result_angle = result_angle / DEGREES
    if deflected then
        self.avoid_time = GetTime()
        self.avoid_angle = result_angle
    end
    return result_angle
end

function GD_KiteAndAttack:GetKitePos(pt, hp, target, attackrange)
    if self.kite_pos ~= nil then
        local kite_time = GetTime() - self.kite_time
        if kite_time < 1 then
            return self.kite_pos
        else
            self.kite_time = nil
            self.kite_pos = nil
        end
    end

    local angle = target:GetAngleToPoint(pt)
    local dist_angle = angle * DEGREES
    local offset = Vector3( attackrange * math.cos(dist_angle), 0, -attackrange * math.sin(dist_angle) )
    self.kite_pos = hp + offset
    self.kite_time = GetTime()

    -- SpawnPrefab("spawn_fx_medium").Transform:SetPosition(self.kite_pos:Get())

    return self.kite_pos
end

-- c_give"rook"(战车)

--特殊怪物处理设置定义--结构说明:
--[[
"walrus" = {	--怪物prefab名称
NK = 1,			--0:不走位击杀;1:走位击杀		--NoKite
CD = 1,			--规避攻击的时间间隔:1秒		--CoolDown
AD = 4,			--强制AI远离该对象的范围		--AwayDist
},

]]

--特殊怪物处理设置定义
local MonsterSetList = {
	["walrus"] = {NK = 0},--海象爸爸
	["bishop"] = {NK = 0},--发条主教
	["knight"] = {NK = 0},--发条骑士
	["deerclops"] = {CD = 1},	--独眼巨鹿
	["moose"] = 	{CD = 1},	--鹿鸭
	["bearger"] = 	{CD = 0.35},--熊大--正常的处理
	["pigman"] =	{AD = 4},	--猪人
	["pigguard"] =	{AD = 4},	--猪人守卫
	["tentacle"] =	{AD = 7.5},	--触手:2:3:6
	["worm"] =	{CD = 1.25,AD = 5},	--触手:2:3:6
}

local function checkObjCD(obj, target)
	if target.prefab == "tentacle" then
		-- print(tostring(target._last_attacked_time))
		-- local current_target = target.components.combat.target
		-- local time = GetTime()
		-- if current_target ~=nil and current_target == target._last_attacker and target._last_attacked_time + 0.2 >= time then
			-- return false
		-- end
		
		-- target:ListenForEvent("attacked", function(target) print(tostring(target._last_attacked_time));return false  end)
		if target.sg:HasStateTag("attack") or target.sg.tags == "" then
			-- obj.components.combat:SetAttackPeriod(1.5)
			-- obj.components.combat:SetRange(3.5)
			return false
		end
	end
	if target.prefab == "worm" then
		if target.sg:HasStateTag("attack") 
		or target.sg:HasStateTag("idle") 
		or (target.sg:HasStateTag("lure") and target.sg:HasStateTag("invisible")) then
			return false
		end
	end
	--"invisible", "dirt"
	-- if target.sg:HasStateTag("taunting") then
	-- if target.sg:HasStateTag("attack") or (target.sg:HasStateTag("invisible") and target.sg:HasStateTag("dirt")) then -- and target.sg:HasStateTag("attack") then attack_pre
		-- return false
	-- end
	return true
	-- target:DoTaskInTime(1, function ()
		-- return true
	-- end)
end
--技能类BOSS的躲避处理
local function checkCD(inst)
	-- inst:ListenForEvent("timerdone", ontimerdone)
	if inst.prefab == "moose" and inst.CanDisarm then
		if inst.CanDisarm == true then return true end			--10秒cd:缴械武器
	elseif inst.prefab == "bearger" and inst.cangroundpound then
		if inst.cangroundpound == true then return false end		--10秒cd:地震:灵服专用处理
		-- if inst.cangroundpound == true then return true end		--正常的处理
	end
	return false
end
--[[todo
--战车
--蠕虫

]]
-- local weaponItem = nil
function GD_KiteAndAttack:Visit()
    local combat = self.inst.components.combat
    if self.status == READY then
        combat:ValidateTarget()

        if combat.target then
            self.inst.components.combat:BattleCry()
            self.startruntime = GetTime()
            self.numattacks = 0
            self.status = RUNNING
        else
            self.status = FAILED
        end
    end

    if self.status == RUNNING then
        -- local is_attacking = self.inst.sg:HasStateTag("attack")
        if not combat.target or not combat.target.entity:IsValid() then
			-- print("状态失败")
            self.status = FAILED
            combat:SetTarget(nil)
            self.inst.components.locomotor:Stop()
        elseif combat.target.components.health and combat.target.components.health:IsDead() then
            self.status = SUCCESS
            combat:SetTarget(nil)
            self.inst.components.locomotor:Stop()
        else
			--ByLaolu 2021-01-12 修复联机版宝宝武器更换问题		
            local equip = self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
			if equip == nil then equip = self.inst.equipslots.HANDS end
			if not checkCD(combat.target) then
				-- if equip ~=nil then weaponItem = equip else weaponItem = weaponItem end
				if equip ~=nil then
					self.inst.components.inventory:Equip(equip)
					self.inst.equipslots.HANDS = nil
					-- TheNet:Announce("lll ")
				-- else
					-- TheNet:Announce("没有武器")
				end
			else
				-- TheNet:Announce("2222")
				if equip ~=nil then
					-- TheNet:Announce("3333")
					self.inst.equipslots.HANDS = equip
					self.inst.components.inventory:Unequip(EQUIPSLOTS.HANDS)				
				end
			end
			-- print(tostring(combat.target.sg))
			if combat.target.prefab == "tentacle" then combat:SetAttackPeriod(1.5) else combat:SetAttackPeriod(0.1) end
			-- ;combat:SetRange(3)
            local tcombat = combat.target.components.combat
			local targetCooldown = tcombat and tcombat:GetCooldown() or 0
            local target_lastattacktime = tcombat and tcombat.laststartattacktime or 0
            local target_lastatk_rgtime = GetTime() - target_lastattacktime
-- TheNet:Announce(tostring(targetCooldown))
-- TheNet:Announce(tostring(target_lastatk_rgtime))
            local hp = Point(combat.target.Transform:GetWorldPosition())
            local pt = Point(self.inst.Transform:GetWorldPosition())
            local dsq = distsq(hp, pt)
			--修复恶意玩家作死的战斗组件消失故障--ByLaolu 2021-07-02
            local attackrange = 4
			if tcombat ~=nil and tcombat.attackrange then 
				attackrange = tcombat.attackrange
			end

			local Ct = MonsterSetList[combat.target.prefab]--转到特殊处理怪物的定义表中
			local max_dist = (Ct ~=nil and Ct.AD) or (attackrange + 1.5)---攻击的安全距离设定			
			if (target_lastatk_rgtime < 0.5 or targetCooldown > ((Ct ~=nil and Ct.CD) or 0.5))
			-- if target_lastatk_rgtime < 0.5
			-- and combat.target.sg:HasStateTag("attack")
			and not combat.target.sg:HasStateTag("attack")
			and not checkCD(combat.target) --判定boss释放技能--灵服的单独处理
			-- and combat.target.prefab ~= "worm"
			then
				-- print("1111")
				--不逃跑,直接搞!
                self.isaway = false--Dodge 躲避\逃跑的CD设定
            end
---DEBUG			
			--处理技能型怪物的攻击CD
			-- if ((tcombat and tcombat.areahitrange == nil) and self.inst ~= combat.target.components.combat.target) then print("ok") else print("no") end
			-- print("攻击距离:"..attackrange,"攻击CD:"..targetCooldown)
			-- print("当前战斗对象战最后攻击时间: "..tostring(target_lastatk_rgtime))		
			-- print(tostring(targetCooldown))
			
--DEBUG end
            if (((tcombat and tcombat.areahitrange == nil) and self.inst ~= combat.target.components.combat.target)
			   or (not self.isaway and targetCooldown > ((Ct ~=nil and Ct.CD) or 0.5))
			   or (Ct ~=nil and Ct.NK == 0))
			  --检查cd技能型怪物.
			   and checkObjCD(self.inst, combat.target)--AI敌对目标绕过测试
			   and not checkCD(combat.target)--检测boss技能
            -- or (noKitePrefabs[combat.target.prefab] and equip ~= nil and equip.components.weapon ~= nil and equip.components.weapon.damage > 30)
            then
                local angle = self.inst:GetAngleToPoint(hp)
                local r= self.inst.Physics:GetRadius()+ (combat.target.Physics and combat.target.Physics:GetRadius() + 0.1 or 0)--0.1
                local running = self.inst.components.locomotor:WantsToRun()
                
                if (running and dsq > r*r) or (not running and dsq > combat:CalcAttackRangeSq() ) then
                    --self.inst.components.locomotor:RunInDirection(angle)
                    local shouldRun = not self.walk
                    self.inst.components.locomotor:GoToPoint(hp, nil, shouldRun)
                elseif not (self.inst.sg and self.inst.sg:HasStateTag("jumping")) then
                    self.inst.components.locomotor:Stop()
                    if self.inst.sg:HasStateTag("canrotate") then
                        self.inst:FacePoint(hp)
                    end                
                end
                if combat:TryAttack() then
				-- if combat:DoAttack() then
				
				-- print("我打中了!")
				--DoAttack()--laoluDebug
				--攻击击中时重置追击计时器,未尝试
                else
                    if not self.startruntime then
                        self.startruntime = GetTime()
                        self.inst.components.combat:BattleCry()
                    end
                end
				self:Sleep(.125)
            else
			-- print("我跑哦~~")
			--AI躲避行为和方法
                self.isaway = true
----[[			--直接逃跑方案:
				-- 跑到敌人刚好攻击范围\或技能之外
					-- local pos = self:GetKitePos(pt, hp, combat.target, attackrange)
					-- if combat.target.prefab == "tentacle" then
						-- attackrange = (Ct ~=nil and Ct.AD)
						-- pos = self:GetKitePos(pt, hp, combat.target, attackrange)
					-- end
					-- self.inst.components.locomotor:GoToPoint(pos)
					----[[
                if targetCooldown == 0 then					
					if combat.target.prefab == "tentacle" then 
						attackrange = (Ct ~=nil and Ct.AD)
					end
					--熊大的单独处理
					if combat.target.prefab == "bearger" then	
						if checkCD(combat.target) then
							local angle = self:GetRunAngle(pt, hp)
							if angle ~= nil then
								self.inst.components.locomotor:RunInDirection(angle)
							else
								self.isaway = false
								self.inst.components.locomotor:Stop()
							end
							if dsq +2 > max_dist * max_dist then
								self.inst.components.locomotor:Stop()
							end
						else
							local pos = self:GetKitePos(pt, hp, combat.target, attackrange+4)
							self.inst.components.locomotor:GoToPoint(pos)
						end--熊大的单独处理完成
					else
						local pos = self:GetKitePos(pt, hp, combat.target, attackrange)
						self.inst.components.locomotor:GoToPoint(pos)-->第一次走位
					end
                else
					-- print("错误")
                    local angle = self:GetRunAngle(pt, hp)
                    if angle ~= nil then
                        self.inst.components.locomotor:RunInDirection(angle)-->第二次修正走位:额外避让
                    else
                        self.isaway = false
                        self.inst.components.locomotor:Stop()
                    end

                    if dsq > max_dist * max_dist then
                        -- self.isaway = false
                        self.inst.components.locomotor:Stop()
                    end
                end
				--]]
                -- self:Sleep(.25)
				self:Sleep(.15)
            end
        end
    end
end
