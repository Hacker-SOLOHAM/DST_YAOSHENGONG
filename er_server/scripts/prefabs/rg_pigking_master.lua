local bosss = {"rg_kulou001","rg_kulou002"}

local function GetSpawnPoint(pt)
    if not TheWorld.Map:IsAboveGroundAtPoint(pt:Get()) then
        pt = FindNearbyLand(pt, 1) or pt
    end
    local offset = FindWalkableOffset(pt, math.random() * 2 * PI, 10, 1, true)
    if offset ~= nil then
        offset.x = offset.x + pt.x
        offset.z = offset.z + pt.z
        return offset
    end
end

local function OnTimerOver(inst, data)
    if data.name == "定期刷怪上线10只" then
		
		local spawn_pt = GetSpawnPoint(inst:GetPosition())
		
		if spawn_pt ~= nil then --如果没有可生成的位置那么此次不刷新
			local boss = SpawnPrefab(bosss[math.random(#bosss)])--随机的生物
			boss.Physics:Teleport(spawn_pt:Get())
			inst:ListenForEvent("death", inst.onkilled, boss)
			boss.persists = false
			inst.numpets = inst.numpets + 1
		end		
		if inst.numpets < 10 then --没满继续刷
			inst.components.timer:StartTimer("定期刷怪上线10只",  math.random(5,10))
		end
	end
end

local function cool(inst)
	inst.numpets = 0
	inst:AddComponent("timer")
	
	inst.onkilled = function(target)
		inst.numpets = inst.numpets - 1
		if inst.numpets < 10 and not inst.components.timer:TimerExists("定期刷怪上线10只") then
			inst.components.timer:StartTimer("定期刷怪上线10只",  math.random(5,10))
		end
	end
	
	inst.components.timer:StartTimer("定期刷怪上线10只",  math.random(5,10))
	inst:ListenForEvent("timerdone", OnTimerOver)
end
AddPrefabPostInit("pigking", cool)