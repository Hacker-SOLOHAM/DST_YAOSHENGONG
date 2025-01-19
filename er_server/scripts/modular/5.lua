--所属模块:皮肤卡/弓箭
if TheNet:GetIsServer() or TheNet:IsDedicated() then
	local function DoPiFuKa(inst, data)
		if not inst:HasTag("playerghost") and inst.components.health and not inst.components.health:IsDead() then
			local ar = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.SKIN)
			if inst.prefab and inst.prefab ~= "woodie" then
				local skinner = inst.components.skinner
				if ar and not inst:HasTag("playerghost") then
					-- skinner:ClearAllClothing()
					-- inst.AnimState:ClearOverrideSymbol("swap_body")
					inst.AnimState:ClearOverrideSymbol("torso_pelvis")
					inst.AnimState:ClearOverrideSymbol("torso")
					-- inst.AnimState:OverrideSymbol("swap_body", ar.prefab, "swap_body")
					inst.AnimState:SetBuild(ar.prefab)
				else
					skinner:SetSkinName(skinner.skin_name)
				end
			end
			if ar and ar.canefx then
				if inst.canefx == nil or not inst.canefx:IsValid() then
					inst.canefx = SpawnPrefab("cane_victorian_fx")
					inst.canefx.entity:SetParent(inst.entity)
				end
			else
				if inst.canefx ~= nil and inst.canefx:IsValid() then
					inst.canefx:Remove()
					inst.canefx = nil
				end
			end
		end
	end
	
	AddPlayerPostInit(function(inst)
		inst:DoTaskInTime(0, DoPiFuKa)
		inst:ListenForEvent("unequip", DoPiFuKa)
		inst:ListenForEvent("equip", DoPiFuKa)
		inst:ListenForEvent("ms_respawnedfromghost", DoPiFuKa)
	end)
	
	--射箭动作SG(服务端)
	AddStategraphState("wilson", State({
		name = "bowattack",
		tags = { "attack", "notalking", "abouttoattack", "autopredict" },
		onenter = function(inst)
			local buffaction = inst:GetBufferedAction()
			local target = buffaction ~= nil and buffaction.target or nil
			local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
			inst.components.combat:SetTarget(target)
			inst.components.locomotor:Stop()			
			if not equip:HasTag("er_bow") or target == nil or not target:IsValid() then
				inst.sg:GoToState("idle")
				return
			end				
			inst.components.combat:StartAttack()
			inst.AnimState:PlayAnimation("bow_attack")
			inst.components.combat:BattleCry()
			inst:FacePoint(target.Transform:GetWorldPosition())
			inst.sg.statemem.attacktarget = target
		end,
		timeline = {		
			TimeEvent(6 * FRAMES, function(inst)
				inst:PerformBufferedAction()
				inst.sg:RemoveStateTag("abouttoattack")
			end),			
			TimeEvent(11 * FRAMES, function(inst)
				inst.sg:RemoveStateTag("attack")
			end)		
		},
		events = {
			EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
			EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
			EventHandler("animqueueover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("idle")
				end
			end),
		},
		onexit = function(inst)
			inst.components.combat:SetTarget(nil)
			if inst.sg:HasStateTag("abouttoattack") then
				inst.components.combat:CancelAttack()
			end
		end,		
	}))
	
	AddStategraphPostInit("wilson", function(sg)
		for k1, v1 in pairs(sg.actionhandlers) do
			if v1.action == ACTIONS.ATTACK then
				local OriginalDestStateATTACK = v1.deststate
				v1.deststate = function(inst, action)
					local weapon = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
					if weapon and weapon:HasTag("er_bow") and not inst.components.health:IsDead() and not inst.sg:HasStateTag("attack") then
						return "bowattack"
					end
					return OriginalDestStateATTACK(inst, action)
				end
			end
		end
	end)
end