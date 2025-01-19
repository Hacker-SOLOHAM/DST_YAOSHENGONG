--所属模块:击杀公告
local worldname = GetModConfigData("worldname")

local function GetInstName(inst)
    return inst and inst:GetDisplayName() or "*无名*"
end

local function GetAttacker(data)
    return data and data.attacker and data.attacker:GetDisplayName() or "*无名*"
end
--中立生物
--格洛姆
AddPrefabPostInit("glommer", function (inst)
	--公告1
    local function beigongji(inst, data)
        TheNet:Announce(" ★ "..worldname.." ★ 的".."【 "..GetInstName(inst).." 】正遭受【 "..GetAttacker(data).." 】的攻击！")
    end
	--公告2
    local function chumo(inst)
        TheNet:Announce(" ★ "..worldname.." ★ ".." 可爱的【 "..GetInstName(inst).." 】出现了,快去领回家！")
    end
	--公告3
    local function siwangongao(inst, data)
        TheNet:Announce(" ★ "..worldname.." ★ 的".."【 "..GetInstName(inst).." 】被【 "..GetAttacker(data).." 】残忍杀害了！")
    end
    local function siwang(inst)
        inst:ListenForEvent("attacked", siwangongao)
    end
    inst:ListenForEvent("startfollowing", chumo)
    inst:ListenForEvent("attacked", beigongji)
    inst:ListenForEvent("death", siwang)
end)

--格罗姆花采集
AddPrefabPostInit("statueglommer", function (inst)
    if not _G.TheWorld.ismastersim then
        return inst
    end
    local function OnPicked(inst, picker, loot)
        local glommer = TheSim:FindFirstEntityWithTag("glommer")
        if glommer ~= nil and glommer.components.follower.leader ~= loot then
            glommer.components.follower:StopFollowing()
            glommer.components.follower:SetLeader(loot)
        end
        TheNet:Announce("【 "..GetInstName(picker).." 】从".." ★ "..worldname.." ★ 的".."【 "..GetInstName(inst).." 】上采摘了".."【 "..GetInstName(glommer).." 】的花 ")
        inst:DoTaskInTime(2,function() if math.random()<.33 then TheNet:Announce("【 "..GetInstName(glommer).." 】貌似很喜欢".."【 "..GetInstName(picker).." 】呢！") end end)
    end
    inst.components.pickable.onpickedfn = OnPicked
end)

--小海象
AddPrefabPostInit("little_walrus", function (inst)
    local function siwangongao(inst, data)
        TheNet:Announce(" ★ "..worldname.." ★ 的".."【 "..GetInstName(inst).." 】被【 "..GetAttacker(data).." 】残忍杀害了！")
    end
    local function siwang(inst)
        inst:ListenForEvent("attacked", siwangongao)
    end
    inst:ListenForEvent("death", siwang)
end)

--海象
AddPrefabPostInit("walrus", function (inst)
    local function siwangongao(inst, data)
        TheNet:Announce(" ★ "..worldname.." ★ 的".."【 "..GetInstName(inst).." 】被【 "..GetAttacker(data).." 】击杀 ")
    end
    local function siwang(inst)
        inst:ListenForEvent("attacked", siwangongao)
    end
	inst:ListenForEvent("death", siwang)
end)

--蚁狮
AddPrefabPostInit("antlion", function (inst)
    local function siwangongao(inst, data)
        TheNet:Announce(" ★ "..worldname.." ★ 的".."【 "..GetInstName(inst).." 】被【 "..GetAttacker(data).." 】击杀 ")
    end
    local function siwang(inst)
        inst:ListenForEvent("attacked", siwangongao)
    end
    local function shanchu(inst)
        TheNet:Announce(" ★ "..worldname.." ★ 的".."【 "..GetInstName(inst).." 】消失 ")
    end
    --inst:AddComponent("health")
    --inst.components.health:StartRegen(5, 1)
    inst:DoTaskInTime(.5, function(inst)
        TheNet:Announce(" ★ "..worldname.." ★ 的".."【 "..GetInstName(inst).." 】出现了 ")
    end)
	inst:ListenForEvent("death", siwang)
    inst:ListenForEvent("onremove", shanchu)
end)

--巨鹿
AddPrefabPostInit("deerclops", function (inst)
    local function siwangongao(inst, data)
        TheNet:Announce(" ★ "..worldname.." ★ 的".."【 "..GetInstName(inst).." 】被【 "..GetAttacker(data).." 】击杀 ")
    end
    local function siwang(inst)
        inst:ListenForEvent("attacked", siwangongao)
    end
    local function shanchu(inst)
        TheNet:Announce(" ★ "..worldname.." ★ 的".."【 "..GetInstName(inst).." 】消失 ")
    end
    inst:DoTaskInTime(.5, function(inst)
        TheNet:Announce(" ★ "..worldname.." ★ 的".."【 "..GetInstName(inst).." 】出现了 ")
    end)
	inst:ListenForEvent("death", siwang)
    inst:ListenForEvent("onremove", shanchu)
end)

--鹿鸭
AddPrefabPostInit("moose", function (inst)
    local function siwangongao(inst, data)
        TheNet:Announce(" ★ "..worldname.." ★ 的".."【 "..GetInstName(inst).." 】被【 "..GetAttacker(data).." 】击杀 ")
    end
    local function siwang(inst)
        inst:ListenForEvent("attacked", siwangongao)
    end
	inst:ListenForEvent("death", siwang)
end)

--克劳斯袋子
AddPrefabPostInit("klaus_sack", function (inst)
    local function shanchu(inst)
        TheNet:Announce(" ★ "..worldname.." ★ 的".."【 "..GetInstName(inst).." 】被打开 ")
    end
    inst:DoTaskInTime(.5, function(inst)
        TheNet:Announce(" ★ "..worldname.." ★ 的".." 克劳斯的【 "..GetInstName(inst).." 】出现了 ")
    end)
    inst:ListenForEvent("onremove", shanchu)
end)

--所有boss击杀公告
local boss_name ={
	"beequeen",       --蜂王
	"dragonfly",      --龙蝇
	"toadstool",      --蛤蟆
	"toadstool_dark", --变异蛤蟆99999
	--"moose",          --春鸭
	--"antlion",        --蚁狮
	"bearger",        --秋熊
	--"deerclops",      --巨鹿
	"stalker",        --森林守护者
	"stalker_atrium", --远古影织者
	"stalker_forest", --远古狩猎者
	"minotaur",       --犀牛
	"malbatross",     --邪天翁
	"warg",           --座狼
	"spiderqueen",    --蜘蛛女王
	"tigershark",     --虎鲨
}

for k, v in pairs(boss_name) do	
	AddPrefabPostInit(v, function(inst)
        local function siwangongao(inst, data)
            TheNet:Announce(" ★ "..worldname.." ★ 的".."【 "..GetInstName(inst).." 】被【 "..GetAttacker(data).." 】击杀 ")
        end
        local function siwang(inst)
            inst:ListenForEvent("attacked", siwangongao)
        end
        inst:DoTaskInTime(.5, function(inst)
            TheNet:Announce(" ★ "..worldname.." ★ 的".."【 "..GetInstName(inst).." 】出现了 ")
        end)
	    inst:ListenForEvent("death", siwang)
	end)
end

--女王蜂巢出现
AddPrefabPostInit("beequeenhivegrown",function(inst)
	inst:ListenForEvent("physraddirty", function()
		TheNet:Announce(" ★ "..worldname.." ★ 的".."【 "..GetInstName(inst).." 】".."已刷新 ")
	end)
end)

--龙蝇出现
AddPrefabPostInit("dragonfly_spawner",function(inst)
	inst:ListenForEvent("timerdone", function()
		TheNet:Announce(" ★ "..worldname.." ★ 的".."【 ".."龙蝇".." 】".."已刷新 ")
	end)
end)

--邪天翁
AddPrefabPostInit("malbatross",function(inst)
	inst:ListenForEvent("timerdone", function()
		TheNet:Announce(" ★ "..worldname.." ★ 的".."【 "..GetInstName(inst).." 】".."已刷新 ")
	end)
end)

--蟾蜍菇出现
AddPrefabPostInit("toadstool_cap",function(inst)
	inst:ListenForEvent("ms_spawntoadstool", function()
		TheNet:Announce(" ★ "..worldname.." ★ 的".."【 "..GetInstName(inst).." 】".."已刷新 ")
	end)
end)

--远古大门刷新
AddPrefabPostInit("atrium_gate",function(inst)
	inst:ListenForEvent("timerdone", function()
		if inst.components.trader.enabled == true then
			TheNet:Announce(" ★ "..worldname.." ★ 的".."【 "..GetInstName(inst).." 】".."已刷新 ")
		end
	end)
end)

--克劳斯击杀公告
AddPrefabPostInit("klaus", function(inst)
    local function announcement(inst, data)
    	local lastattacker = inst.components.combat and inst.components.combat.lastattacker
    	if lastattacker ~= nil then
    		TheNet:Announce(" ★ "..worldname.." ★ 的".."【 "..inst:GetDisplayName().." 】被【 "..lastattacker.name.." 】击杀 ")
    	else
    		TheNet:Announce(" ★ "..worldname.." ★ 的".."【 "..inst:GetDisplayName().." 】".."被击杀 ")
    	end
    end
    inst:DoTaskInTime(.5, function(inst)
        TheNet:Announce(" ★ "..worldname.." ★ 的".."【 "..GetInstName(inst).." 】出现了 ")
    end)
    local function extinction(inst)
        if inst:IsUnchained() then
		    inst:ListenForEvent("attacked", announcement)
		end
    end
    inst:ListenForEvent("death", extinction)
end)

--猎犬攻击天数
local Widget = GLOBAL.require('widgets/widget')

local DAYS_IN_ADVANCE = 2

local secADay = 8*60

local function second2Day(val) 
	return math.floor(val / secADay)
end
local function attackString(timeToAttack)
	if timeToAttack == 0 then
		return '猎犬今日来袭'
	else
		return '猎犬倒计时'..timeToAttack..'天'
	end
end
local function HoundAttack(inst)
	inst:ListenForEvent("cycleschanged",
		function(inst)
			if GLOBAL.TheWorld:HasTag("cave") then
				return
			end
			if not GLOBAL.TheWorld.components.hounded then
				return
			end
			local _timeToAttack = GLOBAL.TheWorld.components.hounded:GetTimeToAttack()
			local timeToAttack  = second2Day(_timeToAttack)
			if timeToAttack <= DAYS_IN_ADVANCE and GLOBAL.TheWorld.state.cycles ~= 0 then
				for i, v in ipairs(GLOBAL.AllPlayers) do v.components.talker:Say(attackString(timeToAttack),10,true,true,false) end
			end
			print("Hound attack: " .. _timeToAttack)
		end,
	GLOBAL.TheWorld)
end
AddPrefabPostInit("world", HoundAttack)