--所属模块:击杀公告
local health = require "components/health"
local rg_guaiwu = require "components/rg_guaiwu"

--显示血条的怪物表
local creaturelist = {
	"bee",
	"spider_hider",
	"catcoon",
	"bat",
	"birchnutdrake",
	"tentacle_pillar_arm",
	"spider",
	"eyeplant",
	"mosquito",
	"killerbee",
	"penguin",
	"beeguard",
	"shadow_bishop",
	"krampus",
	"tentacle",
	"frog",
	"crawlingnightmare",
	"monkey",
	"walrus",
	"abigail",
	"spider_spitter",
	"merm",
	"mossling",
	"teenbird",
	"smallbird",
	"terrorbeak",
	"shadow_rook",
	"bunnyman",
	"ghost",
	"pigguard",
	"nightmarebeak",
	"spider_dropper",
	"crawlinghorror",
	"shadow_knight",
	"pigman",
	"slurper",
	"buzzard",
	"lightninggoat",
	"spider_warrior",
	"spiderqueen",
	"stalker",
	"worm",
	"beefalo",
	"knight_nightmare",
	"tallbird",
	"slurtle",
	"lavae",
	"koalefant_summer",
	"leif",
	"deer",
	"rook_nightmare",
	"koalefant_winter",
	"spat",
	"shadowtentacle",
	"rook",
	"bishop",
	"bishop_nightmare",
	"knight",
	"hound",
	"firehound",
	"icehound",
	"warg",
	"leif_sparse",
	"beequeen",
	"deerclops",
	"dark_player",
	"dragonfly",
	"klaus",
	"toadstool_dark",
	"toadstool",
	"stalker_atrium",
	"bearger",
	"minotaur",
	"moose",
	"er_boss001",
	"er_boss002",
	"er_boss003",
}
--为了安全加个保护
for k,v in pairs(creaturelist) do
	if v then
		AddPrefabPostInit(v, function(inst)
			if inst.components.health then
				inst:DoTaskInTime(0.01, function()
					inst.net_health_epic:set(inst.components.health.currenthealth)
					inst.net_health_epic_max:set(inst.components.health.maxhealth)
				end)
			end
			if inst.components.rg_guaiwu then
				inst:DoTaskInTime(0.01, function()
					if not inst:HasTag("er_monster") then	--过滤掉特殊怪物
						inst.net_rg_guaiwu_level:set(inst.components.rg_guaiwu.levelinfo)
						inst.net_rg_guaiwu_skill:set(inst.components.rg_guaiwu.skillinfo)
					end
				end)
			end
		end)
	end
end

local function AppendFn(comp, fn_name, fn)
    local old_fn = comp[fn_name]
    comp[fn_name] = function(self, ...)
        local amount = old_fn(self, ...)
        fn(self)
		if amount ~= nil then
			return amount
		end
    end
end

AppendFn(health, "SetCurrentHealth", function(self)
    if self.inst.health_epic ~= nil then
        self.inst.net_health_epic:set(self.currenthealth)
    end
end)

AppendFn(health, "SetMaxHealth", function(self)
    if self.inst.health_epic ~= nil then
		self.inst:DoTaskInTime(0.01, function()
			self.inst.net_health_epic:set(self.currenthealth)
			self.inst.net_health_epic_max:set(self.maxhealth)
		end)
    end
end)

AppendFn(health, "DoDelta", function(self)
    if self.inst.health_epic ~= nil then
        self.inst.net_health_epic:set(self.currenthealth)
    end
end)

AppendFn(health, "OnRemoveFromEntity", function(self)
    if self.inst.health_epic ~= nil then
        self.inst.net_health_epic:set(0)
		self.inst.net_health_epic_max:set(0)
    end
end)

AppendFn(rg_guaiwu, "SetMonsterInfo", function(self)
    if self.inst.health_epic ~= nil then
		self.inst:DoTaskInTime(0.01, function()
			inst.net_rg_guaiwu_level:set(self.levelinfo)
			inst.net_rg_guaiwu_skill:set(self.skillinfo)
		end)
    end
end)