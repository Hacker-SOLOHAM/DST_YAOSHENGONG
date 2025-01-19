local function getrandomposition()

	local centers = {}
	for i, node in ipairs(TheWorld.topology.nodes) do
		if TheWorld.Map:IsPassableAtPoint(node.x, 0, node.y) and node.type ~= NODE_TYPE.SeparatedRoom then
			table.insert(centers, {x = node.x, z = node.y})
		end
	end
	if #centers > 0 then
		local pos = centers[math.random(#centers)]
		return Point(pos.x, 0, pos.z)
	else
		return nil
	end
end

local function ondeath(inst)
	local killer = "未知玩家"
	local lastattacker = inst.components.combat and inst.components.combat.lastattacker or nil
	if lastattacker ~= nil then
		killer = lastattacker:GetDisplayName()
	end
	TheNet:Announce(killer.."击杀了".."☆☆"..inst:GetDisplayName().."☆☆")
	TheWorld:DoTaskInTime(120, function(inst) --五秒之后刷新新的
		if inst.newboss~= nil then
			inst.newboss() 
		end
	end)
end

local function newboss() --生成新的
	local locpos = getrandomposition()
	if locpos ~= nil then
		local boss = SpawnPrefab("er_boss003")
		if boss.Physics ~= nil then
			boss.Physics:Teleport(locpos.x, 0, locpos.z)
		else
			boss.Transform:SetPosition(locpos.x, 0, locpos.z)
		end
		boss:ListenForEvent("death", ondeath)
		--公告可以自己改
		TheNet:Announce(boss:GetDisplayName().." 在世界"..TheShard:GetShardId().."刷新了")
	end
end

if TUNING.RG_BOSS == 1 then --开启选项

	local function cool(inst)
		if inst:HasTag("cave") then  --洞穴不需要
			return
		end
		inst.newboss = newboss
		local boss = nil
		inst:DoTaskInTime(5, function() --五秒之后检测 如果没有就生成
			for k,v in pairs(Ents) do
				if v and v.prefab == "er_boss003" then
					boss = v
					break
				end
			end
			
			if boss ~= nil then  --如果存在那么就兼听死亡
				boss:ListenForEvent("death", ondeath)
			else --否则就生成一个新的
				inst.newboss()
			end
		
		
		end)
	end
AddPrefabPostInit("world", cool)

end