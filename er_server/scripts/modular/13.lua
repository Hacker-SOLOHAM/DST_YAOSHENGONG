--规则：
--renwutbl 表， 是任务发布，和奖励内容
--["guai"] == 击杀任务
--["cai"] == 采集任务
--["shou"] == 收集任务
--["diao"] == 钓鱼任务
--["jiang"] == 奖励内容

--[[饥荒更改
1主世界将玩家推送到人少的建家世界
2吃  砍  杀  采
任务系统
1主线任务：
开局给予玩家一个弓或者杖的经典图纸、模具、矿石，并指引玩家前往中转站的公共锻造工坊打造武器或者直接给予一把绿色远程武器，开局给予玩家一套限时3天的防具。
①造一本科学机器【需要1金子4石头4木头】【奖励1000块】
②造二本科技炼金引擎【需要4木板2石砖2元件】【奖励2000块】
③建造海景别墅【奖励3000块】
④建造花坊【奖励鲜花种子袋10个】
⑤建造农舍【奖励种子袋10个】
⑥建造锻造工坊【奖励经典的图纸 模具 矿石】
⑦前往锻造工坊打造一把武器【奖励妖灵之心】
⑧前往锻造工坊强化【奖励初级增幅书】
⑨指引玩家前往锻造工坊增幅【给予5个绿宝石】
⑩建造附魔台【奖励给予5个绿宝石】
11进行一次附魔【奖励各色宝石5个】
12建造工坊的门【奖励10个经验药水】
二升级任务
①升级至50 【】
②升级至100【】
③升级至150【】
④升级至200【】
⑤升级至250【】
⑥升级至300【】
⑦升级至350【】
⑧升级至400【】
⑨升级至450【】
⑩升级至500【】

三支线任务：24小时刷新一次，妖精之心可以刷新一次
1星任务（奖励300宝石币）
①挖矿50个
②采集200次
③伐木100
④吃海鲜牛排20个
⑤收集树枝40
⑥击杀猎狗10只（妖精级）
⑦击杀齿轮怪（3种都可以）8只
2星任务（奖励450宝石币）
①提交绳子30
②提交石砖30
③提交木板30
④击杀地龙10只（妖精级）
⑤击杀齿轮怪（3种都可以）15只
⑥击杀猎狗3只（妖王级）
3星任务（奖励600宝石币）
①收集大理石40
②收集月亮石40
③收集活木50
④击杀猎狗10只（妖王级）
⑤击杀地龙5只（妖王级）
4星任务（奖励750宝石币）
①击杀地龙10只（妖王级）
②击杀四季BOSS、龙蝇、蜂后、地下BOSS（任意级别）
③击杀猎狗10只（魔王级）
④击杀地龙5只（魔王级）
5星任务（高级别玩家专用（奖励1200宝石币））
①击杀四季BOSS、龙蝇、蜂后、地下BOSS（魔王级别）
②橙色武器回收
③高等物品回收（看你意思，什么东西难弄要什么）
]]


------>        { PTYXB = 游戏币填倍率,    TSYXB = 特殊币填倍率, EXP = 经验值填倍率, YUSHE = 物品【表】 }
------>    例： SetJiang(p, t, e, y) >>  SetJiang(1, 2, 3, { ["物品名1"] = 10, ["物品名2"] = 15 })
------>    SetJiang(1,1,1, { ["fumoshi_1"] = 50, ["carrot"] = 10})
local FISH_DATA = require("prefabs/oceanfishdef")

STRINGS.NAMES[string.upper("moose")] = STRINGS.NAMES["MOOSE1"]

local function SetJiang(p, t, e, y)
    return { PTYXB = p, TSYXB = t, EXP = e, YUSHE = y }
end

local JL01 = { ["fumoshi_1"] = 2 }        --魔石碎片
local JL02 = { ["fumoshi_2"] = 1 }        --浅蓝魔石
local JL03 = { ["fumoshi_1"] = 4 }        --魔石碎片
local JL05 = { ["fumoshi_1"] = 6 }        --魔石碎片
local JL06 = { ["fumoshi_1"] = 8 }        --魔石碎片
local JL07 = { ["fumoshi_1"] = 10 }        --魔石碎片
local JL08 = { ["fumoshi_1"] = 2, ["fumoshi_2"] = 1 }        --魔石碎片 + 浅蓝魔石

local JL09 = { ["fumoshi_1"] = 2, ["phlegm"] = 1 }                --魔石碎片 + 脓鼻涕
local JL10 = { ["fumoshi_1"] = 2, ["minotaurhorn"] = 1 }        --魔石碎片 + 犀牛角
local JL11 = { ["fumoshi_1"] = 2, ["deerclops_eyeball"] = 1 }    --魔石碎片 + 巨鹿眼球

local AllRenWu = {
    ["guai"] = {
        [1] = {                                                        --	一等难度
            { key = "spider", size = { 15, 30 }, li = SetJiang(1, .5, 1, { ["ice"] = 2 } ) }, --地面小蜘蛛
            { key = "spider_warrior", size = { 10, 20 }, li = SetJiang(1, .5, 1, nil) }, --地面绿蜘蛛
            { key = "spider_hider", size = { 10, 20 }, li = SetJiang(1, .5, 1, nil) }, --洞穴蜘蛛
            { key = "spider_spitter", size = { 10, 20 }, li = SetJiang(1, .5, 1, nil) }, --喷射蜘蛛
            { key = "hound", size = { 10, 20 }, li = SetJiang(1, .5, 1, nil) }, --猎犬
            { key = "buzzard", size = { 5, 10 }, li = SetJiang(1, .5, 1, nil) }, --秃鹫
            { key = "mole", size = { 2, 5 }, li = SetJiang(1, .5, 1, nil) }, --鼹鼠
            { key = "merm", size = { 15, 30 }, li = SetJiang(1, .5, 1, nil) }, --鱼人
            { key = "pigman", size = { 8, 16 }, li = SetJiang(1, .5, 1, nil) }, --猪人
            { key = "bunnyman", size = { 8, 16 }, li = SetJiang(1, .5, 1, nil) }, --兔人
            { key = "crow", size = { 5, 15 }, li = SetJiang(1, .5, 1, nil) }, --乌鸦
            { key = "butterfly", size = { 5, 15 }, li = SetJiang(1, .5, 1, nil) }, --蝴蝶
            { key = "bee", size = { 5, 15 }, li = SetJiang(1, .5, 1, nil) }, --蜜蜂
            { key = "mosquito", size = { 5, 10 }, li = SetJiang(1, .5, 1, nil) }, --蚊子
        },
        [2] = {                                                        --	二等难度
            { key = "eyeplant", size = { 5, 10 }, li = SetJiang(1, 1.5, 1, nil) }, --食人花的眼睛
            { key = "tallbird", size = { 5, 10 }, li = SetJiang(1, 1.5, 1, nil) }, --高脚鸟
            { key = "crawlinghorror", size = { 5, 10 }, li = SetJiang(1, 1.5, 1, nil) }, --爬行暗影怪
            { key = "terrorbeak", size = { 5, 10 }, li = SetJiang(1, 1.5, 1, nil) }, --尖嘴暗影怪
            { key = "spider_dropper", size = { 5, 10 }, li = SetJiang(1, 1.5, 1, nil) }, --白蜘蛛
            { key = "frog", size = { 5, 10 }, li = SetJiang(1, 1.5, 1, nil) }, --青蛙
            { key = "perd", size = { 5, 10 }, li = SetJiang(1, 1.5, 1, nil) }, --火鸡
            { key = "koalefant_summer", size = { 1, 3 }, li = SetJiang(1, 1.5, 1, nil) }, --夏象
            { key = "koalefant_winter", size = { 1, 3 }, li = SetJiang(1, 1.5, 1, nil) }, --冬象
            { key = "monkey", size = { 3, 7 }, li = SetJiang(1, 1.5, 1, nil) }, --猴子
            { key = "worm", size = { 2, 4 }, li = SetJiang(1, 1.5, 1, nil) }, --远古虫子
            { key = "bat", size = { 5, 10 }, li = SetJiang(1, 1.5, 1, nil) }, --蝙蝠
            { key = "rocky", size = { 5, 10 }, li = SetJiang(1, 1.5, 1, nil) }, --石虾
            { key = "tentacle", size = { 5, 10 }, li = SetJiang(1, 1.5, 1, nil) }, --触手
            { key = "leif_sparse", size = { 5, 10 }, li = SetJiang(1, 1.5, 1, nil) }, --无果树精
            { key = "krampus", size = { 10, 30 }, li = SetJiang(1, 1.5, 1, nil) }, --坎普斯
            { key = "mossling", size = { 3, 8 }, li = SetJiang(1, 1.5, 1, nil) }, --小鸭子
            { key = "lavae", size = { 5, 8 }, li = SetJiang(1, 1.5, 1, nil) }, --熔岩虫
            { key = "cookiecutter", size = { 5, 10 }, li = SetJiang(1, 1.5, 1, JL01) }, --饼干切割机
        },
        [3] = {                                                        --	三等难度
            { key = "tentacle_pillar", size = { 1, 2 }, li = SetJiang(1, 3, 1, JL08) }, --巨型触手
            { key = "pog", size = { 15, 30 }, li = SetJiang(1, 3, 1, JL08) }, --小呆狐
            { key = "mean_flytrap", size = { 15, 30 }, li = SetJiang(1, 3, 1, JL08) }, --食牙草
            { key = "warg", size = { 1, 2 }, li = SetJiang(1, 3, 1, JL08) }, --座狼
            { key = "spat", size = { 1, 2 }, li = SetJiang(1, 3, 1, JL08) }, --钢羊
            { key = "spiderqueen", size = { 2, 4 }, li = SetJiang(1, 3, 1, JL08) }, --蜘蛛女王
            { key = "deerclops", size = { 1, 1 }, li = SetJiang(1, 5, 1, JL08) }, --巨鹿
            { key = "moose", size = { 2, 2 }, li = SetJiang(1, 5, 1, JL08) }, --大鸭子
            { key = "bearger", size = { 1, 1 }, li = SetJiang(1, 5, 1, JL08) }, --大熊
            { key = "dragonfly", size = { 1, 1 }, li = SetJiang(1, 5, 1, JL08) }, --蜻蜓
            { key = "beequeen", size = { 1, 1 }, li = SetJiang(1, 5, 1, JL08) }, --女王蜂
            { key = "beeguard", size = { 8, 20 }, li = SetJiang(1, 3, 1, JL08) }, --雄峰
            { key = "malbatross", size = { 1, 1 }, li = SetJiang(1, 5, 1, JL08) }, --邪天翁
        },
    },
    ["cai"] = {
        [1] = {
            { key = "bullkelp_plant", size = { 5, 10 }, li = SetJiang(1, .3, 1, nil) }, --公牛海带
            { key = "flower_cave", size = { 5, 10 }, li = SetJiang(1, .3, 1, nil) }, --单朵洞穴花
            { key = "grass", size = { 10, 20 }, li = SetJiang(1, .3, 1, nil) }, --草
            { key = "sapling", size = { 10, 20 }, li = SetJiang(1, .3, 1, nil) }, --树枝
            { key = "berrybush", size = { 10, 20 }, li = SetJiang(1, .3, 1, nil) }, --浆果丛
            { key = "reeds", size = { 10, 20 }, li = SetJiang(1, .3, 1, nil) }, --芦苇
            { key = "cactus", size = { 10, 20 }, li = SetJiang(1, .3, 1, nil) }, --仙人掌
            { key = "lichen", size = { 10, 20 }, li = SetJiang(1, .3, 1, nil) }, --洞穴苔藓
        },
        [2] = {},
    },
    ["shou"] = {
        [1] = {
            { key = "cutgrass", size = { 15, 30 }, li = SetJiang(1, .3, 1, nil) }, --草
            { key = "twigs", size = { 15, 30 }, li = SetJiang(1, .3, 1, nil) }, --树枝
            { key = "log", size = { 10, 20 }, li = SetJiang(1, .3, 1, nil) }, --木头
            { key = "rocks", size = { 10, 20 }, li = SetJiang(1, .3, 1, nil) }, --石头
            { key = "flint", size = { 5, 10 }, li = SetJiang(1, .3, 1, nil) }, --燧石
            { key = "nitre", size = { 10, 20 }, li = SetJiang(1, .3, 1, nil) }, --硝石
            { key = "marble", size = { 3, 5 }, li = SetJiang(1, .3, 1, nil) }, --大理石
            { key = "goldnugget", size = { 10, 20 }, li = SetJiang(1, .3, 1, nil) }, --金块
            { key = "ice", size = { 10, 20 }, li = SetJiang(1, .3, 1, nil) }, --冰块
            { key = "charcoal", size = { 10, 20 }, li = SetJiang(1, .3, 1, nil) }, --木炭
            { key = "ash", size = { 10, 20 }, li = SetJiang(1, .3, 1, nil) }, --灰烬
            { key = "petals", size = { 5, 8 }, li = SetJiang(1, .3, 1, nil) }, --花瓣
            { key = "poop", size = { 5, 8 }, li = SetJiang(1, .3, 1, nil) }, --便便
            { key = "cutreeds", size = { 10, 20 }, li = SetJiang(1, .3, 1, nil) }, --芦苇
            { key = "houndstooth", size = { 5, 8 }, li = SetJiang(1, .3, 1, nil) }, --狗牙
            { key = "silk", size = { 10, 20 }, li = SetJiang(1, .3, 1, nil) }, --蜘蛛丝
            { key = "spidergland", size = { 10, 20 }, li = SetJiang(1, .3, 1, nil) }, --蜘蛛腺体
            { key = "beefalowool", size = { 5, 8 }, li = SetJiang(1, .3, 1, nil) }, --牛毛
            { key = "stinger", size = { 5, 8 }, li = SetJiang(1, .3, 1, nil) }, --蜜蜂刺
            { key = "pigskin", size = { 2, 5 }, li = SetJiang(1, .3, 1, nil) }, --猪皮
            { key = "feather_crow", size = { 10, 20 }, li = SetJiang(1, .3, 1, nil) }, --乌鸦羽毛
            { key = "spoiled_food", size = { 10, 20 }, li = SetJiang(1, .3, 1, nil) }, --腐烂食物
        },
        [2] = {
            { key = "driftwood_log", size = { 5, 8 }, li = SetJiang(1, 1, 1, nil) }, --浮木
            { key = "livinglog", size = { 6, 10 }, li = SetJiang(1, 1, 1, nil) }, --活木
            { key = "cactus_flower", size = { 5, 10 }, li = SetJiang(1, 1, 1, nil) }, --仙人掌花
            { key = "wormlight", size = { 3, 5 }, li = SetJiang(1, 1, 1, nil) }, --发光蓝莓
            { key = "spore_small", size = { 10, 15 }, li = SetJiang(1, 1, 1, nil) }, --绿色孢子
            { key = "spore_medium", size = { 10, 15 }, li = SetJiang(1, 1, 1, nil) }, --红色孢子
            { key = "spore_tall", size = { 10, 15 }, li = SetJiang(1, 1, 1, nil) }, --蓝色孢子
            { key = "moonrocknugget", size = { 5, 8 }, li = SetJiang(1, 1, 1, nil) }, --月亮石
            { key = "purplegem", size = { 2, 5 }, li = SetJiang(1, 1, 1, nil) }, --紫宝石
            { key = "gears", size = { 1, 5 }, li = SetJiang(1, 1, 1, nil) }, --齿轮
            { key = "rottenegg", size = { 10, 15 }, li = SetJiang(1, 1, 1, nil) }, --臭鸡蛋
            { key = "tentaclespots", size = { 2, 4 }, li = SetJiang(1, 1, 1, nil) }, --触手皮
            { key = "manrabbit_tail", size = { 6, 10 }, li = SetJiang(1, 1, 1, nil) }, --兔毛球
            { key = "powcake", size = { 6, 10 }, li = SetJiang(1, 2, 1, JL01) }, --芝士蛋糕
            { key = "butterflymuffin", size = { 6, 10 }, li = SetJiang(1, 2, 1, JL01) }, --奶油玛芬
            { key = "honeyham", size = { 6, 10 }, li = SetJiang(1, 2, 1, JL01) }, --蜜汁火腿
            { key = "honeynuggets", size = { 6, 10 }, li = SetJiang(1, 2, 1, JL01) }, --蜜汁卤肉
            { key = "bonestew", size = { 6, 10 }, li = SetJiang(1, 2, 1, JL01) }, --炖肉汤
            { key = "turkeydinner", size = { 6, 10 }, li = SetJiang(1, 2, 1, JL01) }, --火鸡大餐
            { key = "baconeggs", size = { 6, 10 }, li = SetJiang(1, 2, 1, JL01) }, --培根煎蛋
            { key = "hotchili", size = { 6, 10 }, li = SetJiang(1, 2, 1, JL01) }, --辣椒炖肉
            { key = "frogglebunwich", size = { 6, 10 }, li = SetJiang(1, 2, 1, JL01) }, --蛙腿三明治
            { key = "unagi", size = { 6, 10 }, li = SetJiang(1, 2, 1, JL01) }, --鳗鱼料理
            { key = "stuffedeggplant", size = { 6, 10 }, li = SetJiang(1, 2, 1, JL01) }, --酿茄子
            { key = "dragonpie", size = { 6, 10 }, li = SetJiang(1, 2, 1, JL01) }, --火龙果派
            { key = "surfnturf", size = { 6, 10 }, li = SetJiang(1, 2, 1, JL01) }, --海鲜大排档
            { key = "bandage", size = { 6, 10 }, li = SetJiang(1, 2, 1, JL01) }, --蜂蜜绷带
        },
        [3] = {
            { key = "cookiecuttershell", size = { 1, 3 }, li = SetJiang(1, 3, 1, JL09) }, --饼干切割机壳
            { key = "shroom_skin", size = { 1, 3 }, li = SetJiang(1, 3, 1, JL10) }, --魔蛤皮
            { key = "dragon_scales", size = { 1, 3 }, li = SetJiang(1, 3, 1, JL10) }, --蜻蜓龙鳞片
            { key = "glommerfuel", size = { 1, 3 }, li = SetJiang(1, 3, 1, JL11) }, --咕噜咪的粘液
            { key = "phlegm", size = { 1, 3 }, li = SetJiang(1, 3, 1, JL11) }, --脓鼻涕
            { key = "butter", size = { 1, 3 }, li = SetJiang(1, 3, 1, JL09) }, --黄油
        },
    },
    ["diao"] = {
        [1] = {},
    },
}

for i = 1, NUM_TRINKETS do
    --所有玩具 46 种
    table.insert(AllRenWu.shou[3], { key = "trinket_" .. i, size = { 1, 2 }, li = SetJiang(1, 3, 1, JL08) })
end

local NotYu = { oceanfish_medium_6 = true, oceanfish_medium_7 = true }        --刨除 花锦鲤 金锦鲤

for _, fish_def in pairs(FISH_DATA.fish) do
    --所有海鱼
    if fish_def.prefab and not NotYu[fish_def.prefab] then
        table.insert(AllRenWu.diao[1], { key = fish_def.prefab, size = { 4, 6 }, li = SetJiang(1, 3, 1, JL01) })
    end
end

for i = 1, 12 do
    --所有耕种农作物
    table.insert(AllRenWu.cai[2], { key = string.format("qm_zuowu%03d", i), size = { 4, 9 }, li = SetJiang(1, 3, 1, nil) })
end
--------------------------------------Lv 150
local LvRenWuTbl = {
    [1] = { "cai", "shou" },
    [2] = { "cai", "guai", "shou" },
    [3] = { "cai", "guai", "shou", "diao" },
}

local MORENXULIE = { "cai", "guai", "shou", "diao" }
------------------------------------------------------------------------------------------
local _G = GLOBAL

local function GetXXX(ci, t1, t2, lei)
    local num = #t1
    local tbl = {}
    local tbl2 = t2 or {}
    tbl2[lei] = tbl2[lei] or {}
    tbl2["jiang"] = tbl2["jiang"] or {}
    for i = 1, math.min(num, ci) do
        local key = math.random(num)
        local rbl = t1[tbl[key] or key]
        local wu, size, li = rbl.key, rbl.size, rbl.li
        tbl2[lei][wu] = (tbl2[lei][wu] or 0) + math.random(unpack(size))
        local jiang = tbl2["jiang"]
        jiang.PTYXB = (jiang.PTYXB or 1) * (li.PTYXB or 1)
        jiang.EXP = (jiang.EXP or 1) * (li.EXP or 1)
        jiang.TSYXB = (jiang.TSYXB or 0) + (li.TSYXB or 0)

        if type(li.YUSHE) == "table" then
            jiang.YUSHE = jiang.YUSHE or {}
            for k, v in pairs(li.YUSHE) do
                jiang.YUSHE[k] = (jiang.YUSHE[k] or 0) + v
            end
        end
        tbl[key] = tbl[num] or num
        num = num - 1
    end
    return tbl2
end

AddPlayerPostInit(function(inst)
    inst:AddComponent("er_task")
    inst.FaBuRenWu = function(inst)
        local renwu = inst.components.er_task
        if renwu and not renwu:IsVal() then
            renwu:QingLi()


            local renwu = inst.components.er_task
            local Lv = math.max(1, inst.RWSX and inst.RWSX:GetLv() or 1)
            local lun = renwu:GetNum() % 10
            local ci = (lun > 0 and lun * 0.1) or 1
            local vip = inst.IsVip
            local RenNum = math.clamp(math.ceil(Lv / 60), 1, 7)                --单次发布量
            local LeiLv = math.ceil(Lv * 0.01)
            local RW_Tbl = LvRenWuTbl[LeiLv] or MORENXULIE

            local RenLei = RW_Tbl[math.random(#RW_Tbl)]
            local Zong = AllRenWu[RenLei]

            local playertbl = {}

            if LeiLv > 1 then
                repeat
                    local num = math.ceil(RenNum * 0.5)
                    local num2 = math.random(num, RenNum)
                    playertbl = GetXXX(num2, Zong[math.random(math.min(#Zong, LeiLv))], playertbl, RenLei)
                    RenNum = RenNum - num2
                until RenNum <= 0
            else
                playertbl = GetXXX(1, Zong[1], playertbl, RenLei)
            end

            if next(playertbl) then
                local ptb = playertbl["jiang"]["PTYXB"] or 1
                local texp = playertbl["jiang"]["EXP"] or 1
                playertbl["jiang"]["PTYXB"] = math.ceil((Lv * 11 + Lv * 3) * ptb * (1 + ci) * (vip and 1.5 or 1))
                playertbl["jiang"]["TSYXB"] = math.ceil((playertbl["jiang"]["TSYXB"] or 0) * (vip and 1.2 or 1))
                playertbl["jiang"]["EXP"] = math.ceil((Lv * 303 + Lv * 3) * texp * (1 + ci) * (vip and 1.5 or 1))

                renwu:SetRenWu(playertbl)
                renwu:SetJiangLi(playertbl["jiang"])
                renwu:DoTuiSong()
            end

        end
    end
end)

AddPrefabPostInit("world", function(inst)
    inst._farw = inst:DoPeriodicTask(480 / 10, function(inst)
        for k, v in pairs(_G.AllPlayers) do
            local renwu = v and v.components.er_task
            if renwu and not renwu:IsVal() and v.FaBuRenWu then
                v:FaBuRenWu()
            end
        end
    end)
end)

local function GetUpval(fn, key)
    if fn and key then
        local num = 1
        while true do
            local _key, val = debug.getupvalue(fn, num)
            if _key == key then
                return val
            end
            num = num + 1
            if _key == nil then
                break
            end
        end
    end
end

local CHESS_LOOT

AddPrefabPostInit("tumbleweed", function(inst)
    if CHESS_LOOT == nil then
        local valfn = _G.Prefabs[inst.prefab] and _G.Prefabs[inst.prefab].fn
        if type(valfn) == "function" then
            local _MakeLoot = GetUpval(valfn, "MakeLoot")
            if type(_MakeLoot) == "function" then
                local _CHESS_LOOT = GetUpval(_MakeLoot, "CHESS_LOOT")
                if type(_CHESS_LOOT) == "table" then
                    CHESS_LOOT = _CHESS_LOOT
                    for i = 1, NUM_TRINKETS do
                        --所有玩具 46 种
                        table.insert(CHESS_LOOT, "trinket_" .. i)
                    end
                end
            end
        end
    end
end)

AddPrefabPostInit("oceanfishingrod", function(inst)
    --海鱼API
    if inst.components.oceanfishingrod then
        inst.components.oceanfishingrod.old_ondonefishing = inst.components.oceanfishingrod.ondonefishing
        inst.components.oceanfishingrod.ondonefishing = function(inst, reason, lose_tackle, fisher, target, ...)
            if fisher ~= nil and target ~= nil and target.components.weighable and target.prefab then
                fisher:PushEvent("qm_shangyu", { target = target })
                local weig = target.components.weighable:GetWeight()
                if fisher:HasTag("player") and weig > 0 and weig <= 1000 and fisher.RWSX then
                    fisher.RWSX:Sexp(weig * 13 + 3, false, true)
                end
            end
            if inst.components.oceanfishingrod.old_ondonefishing then
                inst.components.oceanfishingrod.old_ondonefishing(inst, reason, lose_tackle, fisher, target, ...)
            end
        end
    end
end)

--	ThePlayer.components.er_task:DoTuiSong()
--	ThePlayer.HUD.controls.RENWU:TanChuang()
--	ThePlayer.components.er_task:QingLi()
--	ThePlayer:FaBuRenWu(true)
--	ThePlayer.components.er_task:QingLi();ThePlayer:FaBuRenWu(true)
--	ThePlayer.components.er_task:DoWanCheng()
--	print( ThePlayer.components.er_task:dodebug() )
--	local er_task = ThePlayer.components.er_task; er_task:QingLi();ThePlayer:FaBuRenWu(true);print(er_task:dodebug())
---------------------------------------------------------------------------------------------
----------------------------------------增加XX翅膀的反鲜度-----------------------------------------
-- local	_G = GLOBAL
-- local t = {
	 -- ["cbdz0"] = -0.5,
	 -- ["cbdz1"] = -0.5,
	 -- ["cbdz2"] = -0.5,
	 -- ["cbdz3"] = -0.5,
	 -- ["cbdz4"] = -0.5,
	 -- ["cbdz5"] = -0.5,
	 -- ["cbdz6"] = -0.5,
	 -- ["cbdz7"] = -0.5,
	 -- ["cbdz8"] = -0.5,
	 -- ["cbdz9"] = -0.5,
	 -- ["cbdz10"] = -0.5,
	 -- ["ly_bobbag"] = 0,
	 -- ["ly_hehebag"] = -0,
	 -- ["ly_pandabag"] = -0,
	 -- ["ly_wingbag"] = -0,
	 
	 -- -- ["乐园 ● 恶魔之翼"] = -0.5,
	 -- -- ["乐园 ● 信仰之翼"] = -0.5,
	 -- -- ["乐园 ● 炎热之火之翼"] = -0.5,
	 -- -- ["乐园 ● 电光飞驰之翼"] = -0.5,
	 -- -- ["乐园 ● 湛蓝天空"] = -0.5,
	 -- -- ["乐园 ● 炎魔之翼"] = -0.5,
	 -- -- ["乐园 ● 魅惑之光之翼"] = -0.5,
	 -- -- ["乐园 ● 阿波罗之翼"] = -0.5,
	 -- -- ["乐园 ● 紫蝶之翼"] = -0.5,
-- --	["piggyback"] = 10,			--正数腐烂
-- --	["krampus_sack"] = -10,		--负数返鲜
-- --	["backpack"] = 0,			--0保鲜
-- --	["backpack"] = 0,			--0保鲜
-- }
-- local Update = nil
-- local function Update_fn(inst, dt)
	-- if Update ~= nil then
		-- if not inst.components.equippable then
			-- local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner or nil
			-- if not owner and inst.components.occupier then
				-- owner = inst.components.occupier:GetOwner()
			-- end
			-- if owner ~= nil and owner.components.container and owner.components.container.GetFuBai then
				-- dt = owner.components.container.GetFuBai(owner, inst, dt) or dt
			-- end
		-- end
		-- return Update(inst, dt)
	-- end
-- end
-- AddComponentPostInit("perishable", function(Perishable)
	-- if Update == nil then
		-- local fn = Perishable.StartPerishing
		-- for i=1, 10 do
			-- local key, val = _G.debug.getupvalue(fn, i)
			-- if key == "Update" then
				-- Update = val
				-- break
			-- elseif not val then
				-- break
			-- end
		-- end
	-- end
	-- if Update ~= nil then
		-- function Perishable:StartPerishing()
			-- if self.updatetask ~= nil then
				-- self.updatetask:Cancel()
				-- self.updatetask = nil
			-- end

			-- local dt = 10 + math.random()*FRAMES*8
			-- self.updatetask = self.inst:DoPeriodicTask(dt, Update_fn, math.random()*2, dt)
		-- end
	-- end
-- end)
-- for k,v in pairs(t) do
	-- AddPrefabPostInit(k, function(inst)
		-- if inst.components.container then
			-- inst.components.container.GetFuBai = function(owner, inst, dt)
				-- if dt then
					-- return dt * t[k]
				-- end
			-- end
		-- end
	-- end)
-- end