--所属模块:PVP/遁地
--所有玩家
AddPlayerPostInit(function(inst)
    if TheWorld.ismastersim then
		inst.net_canpvp:set(1)
	end
end)

--主机接受指令
if not TheNet:GetIsClient() then
	AddModRPCHandler("Er_Pvp", "canpvp", function(player)
		if player:HasTag('cantpvp') then
			return
		end
		player:AddTag('cantpvp')
		player:DoTaskInTime(30, function(inst)
			inst:RemoveTag('cantpvp')
		end)
		
		if player.net_canpvp:value() == 1 then
			player.net_canpvp:set(2)
			SpawnPrefab("er_tips_label"):set("30秒后才可解除PVP状态!", 1).Transform:SetPosition(player.Transform:GetWorldPosition())
			player.AnimState:SetMultColour(255/255,19/255,0/255,1)
		else
			player.net_canpvp:set(1)
			player.AnimState:SetMultColour(255/255,255/255,255/255,1)
		end
	end)
end

--遁地
local function droptarget(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 12,{ "_combat"},{"player","playerghost","INLIMBO"})
    for i, v in ipairs(ents) do
        if v and v:IsValid()
            and not (v.components.health ~= nil and
                    v.components.health:IsDead())
            and v.components.combat then
			if v.components.combat.target == inst then
				v.components.combat:GiveUp()
			end
        end
    end
end

AddStategraphState("wilson",
    State {
        name = "underground_idle",
        tags = { "idle", "canrotate","under_ground" },
        onenter = function(inst)
			inst.SoundEmitter:KillSound("move_underground")
            inst.components.locomotor:Stop()
            inst.components.locomotor:Clear()
            if inst.components.drownable ~= nil and inst.components.drownable:ShouldDrown() then
                inst.sg:GoToState("sink_fast")
                return
            end
			inst.AnimState:PlayAnimation("idle_underground", true)
        end,
    }
)

AddStategraphState("wilson",
    State {
        name = "underground_jumpin",
        tags = { "doing", "busy", "canrotate", "nopredict", "nomorph" },
        onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("jump")
            inst:StartThread(function()
                for k = 1, 4 do
					local fx = SpawnPrefab("groundpound_fx")
					fx.Transform:SetPosition(inst.Transform:GetWorldPosition())		
                    Sleep(0.2)
                end
            end)
        end,
        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
					droptarget(inst)
					inst.net_reclusive:set(true)
					inst.AnimState:OverrideSymbol("wormmovefx", "mole_build", "wormmovefx")
					inst.sg:GoToState("underground_idle")
                end
            end),
        },
    }
)

AddStategraphState("wilson",
    State {
        name = "underground_jumpout",
        tags = { "doing", "busy", "canrotate", "nopredict", "nomorph" },
        onenter = function(inst)
			inst.net_reclusive:set(false)
			inst.components.locomotor:Stop()
			--inst.components.health:SetInvincible(true)
            inst:StartThread(function()
                for k = 1, 3 do
					local fx = SpawnPrefab("groundpound_fx")
					fx.Transform:SetPosition(inst.Transform:GetWorldPosition())		
                    Sleep(0.2)
                end
            end)
			inst.AnimState:PlayAnimation("jumpout")
        end,
        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
					inst.sg:GoToState("idle")
                end
            end),
        },
        onexit = function(inst)
			--inst.components.health:SetInvincible(false)
        end,
    }
)

AddStategraphState("wilson",
    State {
        name = "underground_walk_pre",
        tags = { "moving", "running", "canrotate", "autopredict","under_ground"  },
        onenter = function(inst)
            inst.components.locomotor:RunForward()
            inst.AnimState:PlayAnimation("walkunder_pre")
            if not inst.SoundEmitter:PlayingSound("move_underground") then
                inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/mole/move", "move_underground")
            end
        end,
        onupdate = function(inst)
            inst.components.locomotor:RunForward()
        end,
        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("underground_walk")
                end
            end),
        },
    }
)

local function SpawnMoveFx(inst)
    SpawnPrefab("mole_move_fx").Transform:SetPosition(inst.Transform:GetWorldPosition())
end
AddStategraphState("wilson",
    State {
        name = "underground_walk",
        tags = { "moving", "running", "canrotate", "autopredict","under_ground"  },
        onenter = function(inst)
            inst.components.locomotor:RunForward()
            if not inst.AnimState:IsCurrentAnimation("walkunder_loop") then
                inst.AnimState:PlayAnimation("walkunder_loop", true)
            end
			inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength() + .5 * FRAMES)
        end,
        onupdate = function(inst)
            inst.components.locomotor:RunForward()
        end,
        timeline = {
            TimeEvent(0*FRAMES,  SpawnMoveFx),
            TimeEvent(5*FRAMES,  SpawnMoveFx),
            TimeEvent(10*FRAMES, SpawnMoveFx),
            TimeEvent(15*FRAMES, SpawnMoveFx),
            TimeEvent(20*FRAMES, SpawnMoveFx),
            TimeEvent(25*FRAMES, SpawnMoveFx),
        },
        ontimeout = function(inst)
            inst.sg:GoToState("underground_walk")
        end,
    }
)

AddStategraphState("wilson",
    State {
        name = "underground_walk_pst",
        tags = { "canrotate", "idle", "autopredict","under_ground"},
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("walkunder_pst")
			inst.SoundEmitter:KillSound("move_underground")
        end,
        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("underground_idle")
                end
            end),
        },
    }
)

AddStategraphPostInit("wilson", function(sg)
	--ByLaolu 2021-11-25
	if sg and sg.events and sg.events['itemranout'] ~=nil then
		local old_itemranout = sg.events['itemranout'].fn
		if old_itemranout then
			sg.events['itemranout'] = EventHandler('itemranout', function(inst,data,...)
				if inst:HasTag("er_reclusive") then
					return
				end		
				old_itemranout(inst,data,...)
			end)
		end
	end
	
	local idle = sg.states["idle"]
	if idle then
		local old_onenter = idle.onenter
		idle.onenter = function(inst, pushanim)
			if inst:HasTag("er_reclusive") then
				inst.sg:GoToState("underground_idle", pushanim)
				return
			end
			return old_onenter(inst, pushanim)
		end
	end

	local run = sg.states["run"]
	if run ~= nil then
		local old_runonenter = run.onenter
		run.onenter = function(inst,...)
			if inst:HasTag("er_reclusive") then
				inst.sg:GoToState("underground_walk", pushanim)
			else
				old_runonenter(inst,...)
			end
		end
	end
	
	local run_start = sg.states["run_start"]
	if run_start ~= nil then
		local old_run_startonenter = run_start.onenter
		run_start.onenter = function(inst,...)
			if inst:HasTag("er_reclusive")  then
				inst.sg:GoToState("underground_walk_pre", pushanim)
			else
				old_run_startonenter(inst,...)
			end
		end
	end
	
	local run_stop = sg.states["run_stop"]
	if run_stop ~= nil then
		local old_run_stoponenter = run_stop.onenter
		run_stop.onenter = function(inst,...)
			if inst:HasTag("er_reclusive")  then
				inst.sg:GoToState("underground_walk_pst", pushanim)
			else
				old_run_stoponenter(inst,...)
			end
		end
	end
	
	local item_in = sg.states["item_in"]
	if	item_in then
		local old_onenter = item_in.onenter
		item_in.onenter = function(inst, pushanim)
			if inst:HasTag("er_reclusive") then
				inst.sg:GoToState("underground_idle", pushanim)
				if inst.sg.statemem.followfx ~= nil then
					for i, v in ipairs(inst.sg.statemem.followfx) do
						v:Remove()
					end
				end
				return
			end
			return old_onenter(inst, pushanim)
		end
	end

	local item_hat = sg.states["item_hat"]
	if	item_hat then
		local old_onenter = item_hat.onenter
		item_hat.onenter = function(inst, pushanim)
			if inst:HasTag("er_reclusive") then
				inst.sg:GoToState("underground_idle", pushanim)
				return
			end
			return old_onenter(inst, pushanim)
		end
	end

	--终极武器技能SG
	sg.states["er_jump"] = State({
		name = "er_jump",
		tags = {"aoe", "doing", "busy", "noattack", "nopredict", "nomorph", "er_jump"},
		onenter = function(inst, pos, damage)
			local x, y, z = pos:Get()
			inst.sg.statemem.damage = damage
			inst.Transform:SetPosition(x, y, z)
			inst.AnimState:PlayAnimation("atk_leap")
			inst.sg:SetTimeout(1.5)
		end,
		timeline = {
			TimeEvent(0.5, function(inst)
				local weapon = inst.components.combat:GetWeapon()
				if weapon then
					local delay = 0
					local pos = inst:GetPosition()
					for i = 1, 3 do
						inst:DoTaskInTime(delay, function()
							local points = {}
							local radius = 1
							for i = 1, 5 do
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
							--Fix技能伤害宝宝 ByLaolu 2021-05-09
								local ents = TheSim:FindEntities(v.x, v.y, v.z, 3, {"_combat"},{"player","wall","INLIMBO","laoluselfbaby"})
								if #ents > 0 then
									for i, v2 in ipairs(ents) do
										if v2:IsValid() and v2.components.health and not v2.components.health:IsDead() then
											v2.components.combat:GetAttacked(inst, weapon.components.weapon.damage)	--技能伤害
										end
									end
								end
								SpawnPrefab("rg_flamefx01").Transform:SetPosition(v.x, 0, v.z)
							end
						end)
						delay = delay + 0.2
					end
				end
			end)
		},
		ontimeout = function(inst)
			inst.sg:GoToState("idle", true)
		end
	})
end)