--ByLaolu 2021-07-12
--重写机制解决性能问题
AddPrefabPostInit("rg_attack_orb_samll", function(inst)
	
    inst.persists = false

	inst:AddComponent("rg_projectile")
	inst.components.rg_projectile:SetSpeed(60)
	inst.components.rg_projectile:SetOnMissFn(inst.Remove)
	inst.components.rg_projectile:SetOnHitFn(function(inst, owner, target)
		local explosion = SpawnPrefab("rg_attack_orb_explosion")
		-- explosion.Transform:SetPosition(inst.Transform:GetWorldPosition())  
		explosion.Transform:SetPosition(inst.Transform:GetWorldPosition())  
		-- explosion.entity:SetParent(inst.entity)
		explosion.Transform:SetScale(0.35,0.35,0.35)
		inst:Remove()
		end)
    inst:DoTaskInTime(1.2,function() inst:Remove() end)
	
end)

AddPrefabPostInit("rg_attack_orb_explosion", function(inst)
	inst.persists = false

    inst:ListenForEvent("animover", function(inst) inst:Remove() end)
end)
