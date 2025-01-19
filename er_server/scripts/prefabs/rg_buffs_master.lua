local function onstart(inst,target)
    if target and target.components.locomotor ~= nil and target.components.health ~= nil and
        not target.components.health:IsDead() and
        not target:HasTag("playerghost") then
        target.components.locomotor:SetExternalSpeedMultiplier(target, "rg_debuff_speed", 0.5)
    else
        inst:Remove()
    end

end

local function ondeath(inst,target)
	if target and target.components.locomotor ~= nil then
		target.components.locomotor:RemoveExternalSpeedMultiplier(target, "rg_debuff_speed")
	end
	inst:Remove()
end

local function onhstart(inst,target)
    if target then
		target.AnimState:SetMultColour(255/255,19/255,0/255,1)
    else
        inst:Remove()
    end

end

local function onhdeath(inst,target)
	if target then
		target.AnimState:SetMultColour(1,1,1,1)
	end
	inst:Remove()
end

AddPrefabPostInit("rg_debuff_speed", function(inst)
    inst:AddComponent("rg_buffaffect")
    inst.components.rg_buffaffect:SetStartFn(onstart)
    inst.components.rg_buffaffect:SetDeathFn(ondeath)
end)

AddPrefabPostInit("rg_debuff_hunluan", function(inst)
    inst:AddComponent("rg_buffaffect")
    inst.components.rg_buffaffect:SetStartFn(onhstart)
    inst.components.rg_buffaffect:SetDeathFn(onhdeath)
end)