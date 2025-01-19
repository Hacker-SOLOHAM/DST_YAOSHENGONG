local MAXRANGE = 3
local NO_TAGS_NO_PLAYERS = { "INLIMBO", "notarget", "noattack", "flight", "invisible", "player","wall","companion","laoluselfbaby"}
local NO_TAGS = { "INLIMBO", "notarget", "noattack", "flight", "invisible", "playerghost","wall","companion","laoluselfbaby" }

local function OnUpdateThorns(inst)
    inst.range = inst.range + .75

    local x, y, z = inst.Transform:GetWorldPosition()
    for i, v in ipairs(TheSim:FindEntities(x, y, z, inst.range + 3, { "_combat" }, inst.canhitplayers and NO_TAGS or NO_TAGS_NO_PLAYERS)) do
        if not inst.ignore[v] and
            v:IsValid() and
            v.entity:IsVisible() and
            v.components.combat ~= nil then
            local range = inst.range + v:GetPhysicsRadius(0)
            if v:GetDistanceSqToPoint(x, y, z) < range * range then
                if inst.owner ~= nil and not inst.owner:IsValid() then
                    inst.owner = nil
                end
                if inst.owner ~= nil then
                    if inst.owner.components.combat ~= nil and inst.owner.components.combat:CanTarget(v) then
                        inst.ignore[v] = true
                        v.components.combat:GetAttacked(v.components.follower ~= nil and v.components.follower:GetLeader() == inst.owner and inst or inst.owner, inst.damage)
                    end
                elseif v.components.combat:CanBeAttacked() then
                    inst.ignore[v] = true
                    v.components.combat:GetAttacked(inst, inst.damage)
                end
            end
        end
    end

    if inst.range >= MAXRANGE then
        inst.components.updatelooper:RemoveOnUpdateFn(OnUpdateThorns)
    end
end

local function SetFXOwner(inst, owner, damage)
    inst.Transform:SetPosition(owner.Transform:GetWorldPosition())
    inst.owner = owner
	inst.damage = damage
    inst.canhitplayers = not owner:HasTag("player") or TheNet:GetPVPEnabled()
    inst.ignore[owner] = true
end

AddPrefabPostInit("bramblefx_rg", function(inst)
    inst:AddComponent("updatelooper")
    inst.components.updatelooper:AddOnUpdateFn(OnUpdateThorns)

    inst:ListenForEvent("animover", inst.Remove)
    inst.persists = false
    inst.damage = 34
    inst.range = .75
    inst.ignore = {}
    inst.canhitplayers = true

    inst.SetFXOwner = SetFXOwner

    return inst
end)
