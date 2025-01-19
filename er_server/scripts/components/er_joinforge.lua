local range = 50

local function SpawnItem(self,target,num)
	self.inst:DoTaskInTime(5, function()
		local x,y,z = self.inst.Transform:GetWorldPosition()
		for i = 1, num do
			local item = SpawnPrefab(target)
			local pos = self.inst:GetPosition()
			local offset = FindValidPositionByFan(2 * PI * math.random(), 5, 20, function(offsets)
				local pt = Vector3(x + offsets.x, 0, z + offsets.z)
				return TheWorld.Map:IsPassableAtPoint(pt:Get())
						and not TheWorld.Map:IsPointNearHole(pt)
			end)
			if offset ~= nil then
				pos = pos + offset
			end
			item.Transform:SetPosition(pos:Get())
			item:ListenForEvent("onremove", function()
				self.wavenum = self.wavenum - 1
			end)
		end
	end)
end
local function GoFight(self)
	local waveli = self.tofight[self.fightwave]
	local wavenum = 0
	if waveli then
		for i=1, #waveli do
			SpawnItem(self,waveli[i][1],waveli[i][2])		--召唤怪物
			wavenum = wavenum + waveli[i][2]
		end
	end
	self.wavenum = wavenum
end

local function onjoinnum(self)
	if self.joinnum == 0 and JoinForge then
		TheNet:Announce("当前小队全员阵亡,其余小队可前往副本报名参加!")
		self.inst:DoTaskInTime(10, function()
			self:Er_CleanForge()
		end)
	end
	if self.joinnum == 9 then
		TheNet:Announce("副本已经开启，请各位玩家做好准备,祝好运!")
		JoinForge = true
		GoFight(self)
		for i, v in ipairs(self.fightli) do				--战斗人员增加死亡监听
			v.components.er_leave.gotime = os.date("%m月%d日",os.time())
			v:ListenForEvent("death", function()
				self.joinnum = self.joinnum - 1
				if not v.Network:IsServerAdmin() then	--管理无影响
					local x,y,z = v.Transform:GetWorldPosition()
					SpawnPrefab("er_tips_label"):set("您已死亡，5秒后将强制遣返!", 1).Transform:SetPosition(x,y,z)
					v:DoTaskInTime(5, function()
						if v.player_classified then
							v.player_classified.goworid:set(11)		--强制脱离世界
						end
					end)
				end
			end)
		end
	end
end
local function onfightwave(self)
	if self.fightwave > 1 and JoinForge then		--不为第一波
		GoFight(self)
	end
end
local function onwavenum(self)
	if self.wavenum == 0 and JoinForge then		--当前波次怪物解决完毕
		local newwave = self.fightwave + 1
		if self.tofight[newwave] then				--存在下一波
			TheNet:Announce("第"..self.fightwave.."波结束，即将进入第"..newwave.."波!")
			self.fightwave = newwave
		else
			TheNet:Announce("恭喜各位玩家完成副本，60秒后将强制遣返,请迅速打理战场!")
			for i, v in ipairs(self.fightli) do
				if v and not v.Network:IsServerAdmin() then
					v:DoTaskInTime(60, function()
						if v.player_classified then
							v.player_classified.goworid:set(11)
						end
					end)
				end
			end
			self.inst:DoTaskInTime(62, function()
				self:Er_CleanForge()
			end)
		end
	end
end

local Er_JoinForge = Class(function(self, inst)
    self.inst = inst

	self.nameli = {}	--参与人名字
	self.idli = {}		--参与人Id
	self.joinnum = 0	--参与人数
	self.fightli = {}	--战斗人员
	self.tofight = {	--战斗怪物
		[1] = {
			{"spider_dropper",12}
		},
		[2] = {
			{"spider_spitter",12}
		},
		[3] = {
			{"krampus",12}
		},
		[4] = {
			{"walrus",12}
		},
		[5] = {
			{"rook_nightmare",6},
			{"knight_nightmare",4},
			{"bishop_nightmare",2}
		},
		[6] = {
			{"worm",12}
		},
		[7] = {
			{"spat",12}
		},
		[8] = {
			{"klaus",1}--克劳斯
		},
		[9] = {
			{"beequeen",1}--蜘蛛女王
		},
		[10] = {
			{"minotaur",1}
		},
		[11] = {
			{"deerclops",1}
		},
		[12] = {
			{"dragonfly",1}
		},
		[13] = {
			{"rg_kulou002",5}
		},
		[14] = {
			{"rg_kulou001",3}
		},
		[15] = {
			{"forge_biology001",4}
		},
		[16] = {
			{"forge_biology003",4}
		},
		[17] = {
			{"forge_biology004",4}
		},
		[18] = {
			{"forge_biology002",2}
		},
		[19] = {
			{"forge_biology005",2}
		},
		[20] = {
			{"forge_biology006",2}
		},
		[21] = {
			{"forge_biology009",2}
		},
		[21] = {
			{"er_boss001",1}
		},
	}
	self.fightwave = 1	--战斗波次
	self.wavenum = 0	--波次数

	self.inst:WatchWorldState("cycles", function(inst, cycles)		--每日自检,无玩家重置
		if JoinForge then
			local x,y,z = self.inst.Transform:GetWorldPosition()
			local ents = TheSim:FindEntities(x, y, z, range, {"player"})
			if #ents == 0 then
				self:Er_CleanForge()
			end
		end
	end)
end,
nil,
{
	joinnum = onjoinnum,
	fightwave = onfightwave,
	wavenum = onwavenum,
})

--重置属性
function Er_JoinForge:Er_CleanForge()
	JoinForge = false
	self.nameli = {}
	self.idli = {}
	self.joinnum = 0
	self.fightli = {}
	self.fightwave = 1
	self.wavenum = 0

	local x,y,z = self.inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, range)
	for i, v in ipairs(ents) do
		if v ~= self.inst then
			v:Remove()
		end
	end
end

--报名方法
function Er_JoinForge:ToJoin(player)
	if self.joinnum < 9 then
		table.insert(self.nameli, player:GetDisplayName())
		table.insert(self.idli, player.userid)
		table.insert(self.fightli, player)
		self.joinnum = self.joinnum + 1
	end
end

function Er_JoinForge:OnSave()
	return {
		--loadnameli = self.nameli,
		--loadidli = self.idli,
	}
end

function Er_JoinForge:OnLoad(data)
	if data ~= nil then
		--self.nameli = data.loadnameli
		--self.idli = data.loadidli
    end
end

return Er_JoinForge