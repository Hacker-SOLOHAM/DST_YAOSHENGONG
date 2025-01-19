--所属模块:房子
--世界状态机制监听
local upvaluehelper = require "ll_upvaluehelper"

--主机接受指令
if not TheNet:GetIsClient() then
	--重置功能
	AddModRPCHandler("hua_resethouse", "hua_resethouse", function(inst)
		if not inst then return end 
		local x,y,z = inst.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x, y, z, 15, {"hua_house"})
		if # ents > 0 then
			if  inst._inhuahouse ~= nil then
				inst._inhuahouse:set_local(false)
				inst._inhuahouse:set(true)
			end
			if  inst._inhuacamea ~= nil then
				inst._inhuacamea:set_local(false)
				inst._inhuacamea:set(true)	
			end
			if inst.components.playercontroller ~= nil then
				inst.components.playercontroller:EnableMapControls(false)
			end
			inst:AddTag("huahousrecipe")
		else
			if inst._inhuahouse ~= nil then
				inst._inhuahouse:set(false)
			end
			if inst._inhuacamea ~= nil then
				inst._inhuacamea:set(false)
			end	
			inst:RemoveTag("huahousrecipe")	
			if inst.components.playercontroller ~= nil then
				inst.components.playercontroller:EnableMapControls(true)
			end		
		end
	end)
end

AddPlayerPostInit(function(inst)
	if TheWorld.ismastersim then
		--加载时获取玩家位置,看玩家是否在房子中
		inst:DoTaskInTime(0.8, function(inst)
			local x,y,z = inst.Transform:GetWorldPosition()
			local ents = TheSim:FindEntities(x, y, z, 15, {"hua_house"})
			if # ents > 0 then
				if  inst._inhuahouse ~= nil then --如果玩家有房子
					inst._inhuahouse:set(true)
				end
				if  inst._inhuacamea ~= nil then --如果玩家是室内摄像机:是否在室内
					inst._inhuacamea:set(true)	
				end
				if inst.components.playercontroller ~= nil then --限制小地图使用
					inst.components.playercontroller:EnableMapControls(false)
				end
				inst:AddTag("huahousrecipe")
			end
		end)
	end
end)

--临时处理
local function checkz(x,z)
	if x ~= nil and z ~=nil then
		local ents = TheSim:FindEntities(x, 0, z, 15, {"NOCLICK","hua_house"},{"INLIMBO"})
		if #ents == 0 then
			return false 
		else
			return true
		end
	end
end

--蘑菇农场 冬天也可以使用
local levels = {
    { amount=6, grow="mushroom_4", idle="mushroom_4_idle", hit="hit_mushroom_4" }, 
    { amount=4, grow="mushroom_3", idle="mushroom_3_idle", hit="hit_mushroom_3" },
    { amount=2, grow="mushroom_2", idle="mushroom_2_idle", hit="hit_mushroom_2" },
    { amount=1, grow="mushroom_1", idle="mushroom_1_idle", hit="hit_mushroom_1" },
    { amount=0, idle="idle", hit="hit_idle" },
}

local HUAHOUSEVISION = {
    day = "images/colour_cubes/identity_colourcube.tex",
    dusk = "images/colour_cubes/identity_colourcube.tex",
    night = "images/colour_cubes/identity_colourcube.tex",
    full_moon = "images/colour_cubes/identity_colourcube.tex",
}

local function setmylevel(inst, level, dotransition)
    if not inst:HasTag("burnt") then
        if inst.anims == nil then
            inst.anims = {}
        end
        if inst.anims.idle == level.idle then
            dotransition = false
        end
        
        inst.anims.idle = level.idle
        inst.anims.hit = level.hit

        if inst.remainingharvests == 0 then
            inst.anims.idle = "expired"
            inst.components.trader:Enable()
            inst.components.harvestable:SetGrowTime(nil)
            inst.components.workable:SetWorkLeft(1)
        --elseif TheWorld.state.issnowcovered then
        --    inst.components.trader:Disable()
        elseif inst.components.harvestable:CanBeHarvested() then
            inst.components.trader:Disable()
        else
            inst.components.trader:Enable()
            inst.components.harvestable:SetGrowTime(nil)
        end

        if dotransition then
            inst.AnimState:PlayAnimation(level.grow)
            inst.AnimState:PushAnimation(inst.anims.idle, false)
            inst.SoundEmitter:PlaySound(level ~= levels[1] and "dontstarve/common/together/mushroomfarm/grow" or "dontstarve/common/together/mushroomfarm/spore_grow")
        else
            inst.AnimState:PlayAnimation(inst.anims.idle)
        end
        
    end
end

--可以在室内安置的对象列表
local CanCanDeployItemlist = {
	["stone_door_item"] = "stone_door_item",
	-- ["stone_door"] = "stone_door",
}

AddPrefabPostInit("world", function(inst)
	if TheWorld.ismastersim then
		--添加组件
		inst:AddComponent("huahouse")
		--延时处理机制
		inst:DoTaskInTime(0.1, function()
			inst.components.huahouse:SetPosition()
			-- inst.components.huahouse:SetBuildRoomType(2)
			-- tmpkkk = inst.components.huahouse:GetBuildRoomType()
			-- print ("当前值"..tmpkkk)
			-- TheNet:Announce("当前值"..tmpkkk)
		end)
	end
end)

AddPrefabPostInit("forest", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	local frograin = upvaluehelper.GetWorldHandle(inst,"israining","components/frograin")
	if  frograin then
		local GetSpawnPoint = upvaluehelper.Get(frograin,"GetSpawnPoint")	
		if GetSpawnPoint ~= nil then
			local old = GetSpawnPoint
			local function newGetSpawnPoint(pt)
				if checkz(pt.x,pt.z) then
					return nil
				end
				return old(pt)
			end
			upvaluehelper.Set(frograin,"GetSpawnPoint",newGetSpawnPoint)
		end		
	end

	local wildfires = upvaluehelper.GetEventHandle(TheWorld,"ms_lightwildfireforplayer","components/wildfires")
	if  wildfires then
		local LightFireForPlayer = upvaluehelper.Get(wildfires,"LightFireForPlayer")	
		if LightFireForPlayer ~= nil then
			local old = LightFireForPlayer
			local function NewLightFireForPlayer(player, rescheduleFn)
				if player ~= nil then
					local x, y, z = player.Transform:GetWorldPosition()
					if checkz(x,z) then
						return
					end
				end
				old(player, rescheduleFn)
			end
			upvaluehelper.Set(wildfires,"LightFireForPlayer",NewLightFireForPlayer)
		end	
	end	
end)

AddPrefabPostInit("mushroom_farm", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	if inst.components.harvestable and inst.components.harvestable.onharvestfn then
		local setlevel = upvaluehelper.Get(inst.components.harvestable.onharvestfn,"setlevel")
		if setlevel ~= nil then
			local old_setlevel = setlevel
			local function newsetlevel(inst, level, dotransition)			
				local x,y,z = inst.Transform:GetWorldPosition()
				if checkz(x,z) then --in the house?
					setmylevel(inst, level, dotransition)
				else
					old_setlevel(inst, level, dotransition)
				end		
			end
			upvaluehelper.Set(inst.components.harvestable.onharvestfn,"setlevel",newsetlevel)
			
			local updatelevel = upvaluehelper.Get(inst.components.harvestable.onharvestfn,"updatelevel")
			if updatelevel ~= nil then
				local old_updatelevel = updatelevel
				local function newupdatelevel(inst, dotransition)
					local x,y,z = inst.Transform:GetWorldPosition()
					if checkz(x,z) then --in the house?
						if not inst:HasTag("burnt") then
							for k, v in pairs(levels) do
								if inst.components.harvestable.produce >= v.amount then
									setmylevel(inst, v, dotransition)
									break
								end
							end
						end
					else
						old_updatelevel(inst, dotransition)
					end
				end
			upvaluehelper.Set(inst.components.harvestable.onharvestfn,"updatelevel", newupdatelevel)
			end
		end
	end
	
	inst:DoTaskInTime(0.1,function(doer)
		if inst.Transform ~= nil then
			local x,y,z = inst.Transform:GetWorldPosition()
			if checkz(x,z) then
				if not inst:HasTag("burnt")  and not inst.components.harvestable:CanBeHarvested() then 
					if TheWorld.state.issnowcovered and inst.components.trader.enabled == false  then
						inst.components.trader:Enable()
					end
				end
			end
		end
	end)
end)

--限制橙色法杖传送(20码)
AddComponentPostInit("blinkstaff", function(self,inst)
	local OldBlink = self.Blink
	function self:Blink(pt, caster)
		local ents = TheSim:FindEntities(pt.x,pt.y,pt.z,20,{"cantblink"})
		if #ents > 0 then
			return false
		else
			return OldBlink(self, pt, caster)
		end
	end
end)

--限制传送法杖
AddPrefabPostInit("telestaff", function(inst)
	if inst.components.spellcaster then
		local old = inst.components.spellcaster.CastSpell
		inst.components.spellcaster.CastSpell = function(self,target, pos)
			local caster = inst.components.inventoryitem.owner or target
			if caster then
				local x,y,z = caster.Transform:GetWorldPosition()
				if checkz(x,z) then  --不想在判定一次房子了 因为在无人烟的地方使用这个 你想上天呀
					if caster and caster.components.talker then
						caster.components.talker:Say(STRINGS.NOHOUSEPURPLESTAFF)
					end
					return false
				end
			end
			return old(self,target, pos)
		end
	end
end)

--使用砂石传送到外面 解除视野锁定
AddPrefabPostInit("townportaltalisman", function(inst)
	if inst.components.teleporter then
		local old = inst.components.teleporter.onActivate
		inst.components.teleporter.onActivate = function(aaa, doer)
			if old ~= nil then old(aaa, doer) end
			if doer and  doer:HasTag("player") then
				if	doer._inhuahouse ~= nil  and doer._inhuahouse:value() ==  true then
					doer._inhuahouse:set(false)
				end
				if	doer._inhuacamea ~= nil  and doer._inhuacamea:value() ==  true then
					doer._inhuacamea:set(false)
				end
				if doer.components.playercontroller ~= nil then
					doer.components.playercontroller:EnableMapControls(true)
				end
				doer:RemoveTag("huahousrecipe")
			end
		end
	end
end)

--暂不知晓用途-能导致中庭BOSS无法产生
AddComponentPostInit("areaaware", function(self)
	local old = self.UpdatePosition
	function self:UpdatePosition(x, y, z,...)
		if checkz(x,z) then
			self.lastpt.x, self.lastpt.z = x, z
			if self.current_area_data ~= nil then
				self.current_area = -1
				self.current_area_data = nil 
				self.inst:PushEvent("changearea", self:GetCurrentArea())
			end
			return	
		end
		return old(self,x, y, z,...)
	end
end)

--这个地方应该渺无鸟烟
AddComponentPostInit("birdspawner", function(self)
	local old_GetSpawnPoint = self.GetSpawnPoint
	function self:GetSpawnPoint(pt)
		if checkz(pt.x,pt.z) then
			return nil
		else 
			return old_GetSpawnPoint(self,pt)
		end
	end
	
	local PickBird = upvaluehelper.Get(self.SpawnBird,"PickBird")
	if PickBird ~= nil then
		local old_PickBird = PickBird
		local function NewPickBird(spawnpoint)
			local old_bird = old_PickBird(spawnpoint)
			local x, y, z = spawnpoint:Get()
			-- local gezi = TheSim:FindEntities(x, y, z, TUNING.BIRD_CANARY_LURE_DISTANCE, { "hua_door" })
			local gezi = TheSim:FindEntities(x, y, z, TUNING.BIRD_CANARY_LURE_DISTANCE, {"hua_house"})
			if #gezi ~= 0  and math.random() < 0.5 then
				return "quagmire_pigeon" --咕咕咕
			else
				return old_bird
			end			
		end
		upvaluehelper.Set(self.SpawnBird,"PickBird",NewPickBird)
	end	
end)

AddComponentPostInit("teleporter", function(self)
	local old_ReceivePlayer = self.ReceivePlayer
	function self:ReceivePlayer(doer)
		old_ReceivePlayer(self,doer)
		if self.inst:HasTag("hua_door") and doer then
			doer:DoTaskInTime(0.2,function(doer)
			local x,y,z = doer.Transform:GetWorldPosition()
			local ents = TheSim:FindEntities(x, y, z, 15, {"hua_door"})
			if # ents > 0 then		
				return
			end
			doer:SnapCamera()
			doer:ScreenFade(true,1)
			if doer._inhuacamea ~= nil then
				doer._inhuacamea:set(false)
			end
			if doer._inhuahouse ~= nil then
				doer._inhuahouse:set(false)
			end
			if doer.components.playercontroller ~= nil then
				doer.components.playercontroller:EnableMapControls(true)
			end
			doer:RemoveTag("huahousrecipe")
			if doer:IsValid() and doer.sg and doer.sg.statemem.teleportarrivestate ~= nil and doer.components.health and 
				not doer.components.health:IsDead() then
				doer.sg:GoToState(doer.sg.statemem.teleportarrivestate)
			end
			for k,v in pairs(Ents) do
				if v:HasTag("multiplayer_portal") then
					x, y, z  = v.Transform:GetWorldPosition()
					doer.Physics:Teleport(x, 0, z)
					break
				end
			end
			end)
		end
	end
end)

AddComponentPostInit("witherable", function(self)
	if self.inst then
		self.inst:DoTaskInTime(0.1,function(crop)
			local x,y,z = crop.Transform:GetWorldPosition()
			if checkz(x,z) then --在房子里面		
				self:Enable(false)
			end
		end)
	end
end)

AddComponentPostInit("crop", function(self)
	local old_DoGrow = self.DoGrow
	function self:DoGrow(dt, nowither)
		local x, y, z = self.inst.Transform:GetWorldPosition()
		if checkz(x,z) then
			if not self.inst:HasTag("withered") then 
				local shouldgrow = nowither or not TheWorld.state.isnight
				if not shouldgrow then
					local x, y, z = self.inst.Transform:GetWorldPosition()
					for i, v in ipairs(TheSim:FindEntities(x, 0, z, 30, { "daylight", "lightsource" })) do
						local lightrad = v.Light:GetCalculatedRadius() * .7
						if v:GetDistanceSqToPoint(x, y, z) < lightrad * lightrad then
							shouldgrow = true
							break
						end
					end
				end
				if shouldgrow then
					local temp_rate =
						(TheWorld.state.israining and 1 + TUNING.CROP_RAIN_BONUS * TheWorld.state.precipitationrate) or
						(TheWorld.state.isspring and 1 + TUNING.SPRING_GROWTH_MODIFIER / 3) or
						1
					self.growthpercent = math.clamp(self.growthpercent + dt * self.rate * temp_rate, 0, 1)
					self.cantgrowtime = 0
				else
					self.cantgrowtime = self.cantgrowtime + dt
					if self.cantgrowtime > TUNING.CROP_DARK_WITHER_TIME and self.inst.components.witherable ~= nil then
						self.inst.components.witherable:ForceWither()
						if self.inst:HasTag("withered") then
							return
						end
					end
				end

				if self.growthpercent < 1 then
					self.inst.AnimState:SetPercent("grow", self.growthpercent)
				else
					self.inst.AnimState:PlayAnimation("grow_pst")
					self:Mature()
					if self.task then
						self.task:Cancel()
						self.task = nil
					end
				end
			end			
		else
			old_DoGrow(self,dt, nowither)
		end
	end
end)

AddComponentPostInit("sinkholespawner", function(self)
	local oldSpawnSinkhole = self.SpawnSinkhole
	function self:SpawnSinkhole(spawnpt)
		if checkz(spawnpt.x,spawnpt.z) then
			return false
		end	
		return oldSpawnSinkhole(self,spawnpt)
	end
end)

--房子里面禁止使用地图
AddComponentPostInit("playercontroller", function(self)
	local oldEnableMapControls = self.EnableMapControls
	function self:EnableMapControls(val)
		if self.ismastersim  and val then
			if self.inst._inhuacamea ~= nil and self.inst._inhuacamea:value() ==  true then
				return
			end
		end
		oldEnableMapControls(self,val)
	end
end)

AddComponentPostInit("playervision", function(self)
	local old_UpdateCCTable = self.UpdateCCTable
	function self:UpdateCCTable()
		old_UpdateCCTable(self)
		if self.currentcctable == nil then 
			if self.inst._inhuahouse ~= nil  and self.inst._inhuahouse:value() ==  true  then
				self.currentcctable = HUAHOUSEVISION
				self.inst:PushEvent("ccoverrides", HUAHOUSEVISION)
			else
				self.inst:PushEvent("ccoverrides", nil)
			end
		end	
	end
end)

--房子里面100%防雨
AddComponentPostInit("moisture", function(self)
	local old = self.GetMoistureRate
	function self:GetMoistureRate()
		if not TheWorld.state.israining then
			return 0
		end	
		if self.inst._inhuahouse ~= nil and self.inst._inhuahouse:value() ==  true then
			return 0
		end
		return old(self)
	end
end)

--如果是服务器或主机
if TheNet:GetIsServer() or TheNet:IsDedicated() then
	---------------------debug
	-- modimport("scripts/ll_tools.lua")
	-- print ("服务器")
	
	-- local old_DEPLOY = ACTIONS.DEPLOY.fn 
	-- ACTIONS.DEPLOY.fn = function(act)
		-- testActPrint(act)
		-- act.doer.components.talker:Say("Debug:这是安置行为")
		-- return true
	-- end
	-- local old_BUILD = ACTIONS.BUILD.fn
	-- ACTIONS.BUILD.fn = function(act)
		-- testActPrint(act)
		-- act.doer.components.talker:Say("Debug:这是建造行为")
		-- return true
	-- end
	---------------------
	local old_CanDeploy = nil
	AddComponentPostInit("deployable", function(self)
		if self.CanDeploy and old_CanDeploy == nil then
			old_CanDeploy = self.CanDeploy
		end
		function self:CanDeploy(pt, ...)
			local prefab = self.inst.prefab
			-- print (prefab)
			if prefab and CanCanDeployItemlist[prefab] then
				
				local x1,z1 = math.floor(pt.x)+0.5, math.floor(pt.z)+0.5
				-- return #GLOBAL.TheSim:FindEntities(x1, 0, z1, 20, {"hua_house"}) ~= 0
				
				--安置算法
				local roomCenter = TheSim:FindEntities(x1, 0, z1, 15, {"hua_house"})
				local cx, cy, cz = 0,0,0
				if #roomCenter ~= 0 then
					if cx == 0 then--优化逻辑		
						for k,v in pairs(roomCenter) do --找房间心点坐标
							cx, cy, cz = v.Transform:GetWorldPosition()
							break
						end
					end
					--得到房间心点:cx, cy, cz
					--户型接口
					local width = 16 	--房间宽度 	接口
					local depth = 12	--房间深度	接口					
					local Zoffset = width/2 --12
					local Xoffset = depth/2	--8
					
					--写入不可安置的区域
					--保留上面一条线的区域(0.25)可安置,并舍弃房间宽度方向上(左右)2个向量距离
					if (pt.x <= cx - (Xoffset + 0.25) and pt.x >= cx - (Xoffset + 0.5) )
					and (pt.z >= cz -(Zoffset -2) and pt.z <= cz +(Zoffset -2)) then--矫正
						-- self.inst.AnimState:PlayAnimation("stone_east")
						return true
					--保留左侧一条线的区域(0.25)可安置,并舍弃房间深度方向上(上下)2个向量距离
					elseif (pt.z <= cz - (Zoffset-0.25) and pt.z >= cz - (Zoffset) ) 
					and (pt.x >= cx -(Xoffset -2) and pt.x <= cx +(Xoffset -2)) then
						return true
						--右侧待续,将来整理到一起.
					else
						-- self.inst.AnimState:PlayAnimation("stone_north")
						return false
					end
				else
					return false --不在室内禁止安置
				end
			end
			return old_CanDeploy and old_CanDeploy(self, pt, ...)
		end
	end)
end