require "behaviours/wander"
require "behaviours/faceentity"
require "behaviours/gd_kiteandattack"
require "behaviours/chaseandattack"
require "behaviours/panic"
require "behaviours/follow"
require "behaviours/attackwall"
require "behaviours/standstill"
require "behaviours/leash"
require "behaviours/runaway"

local GJ_AI = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

--获取创建位置
local function GetSpawnPoint(pt,radius)
    local theta = math.random() * 2 * PI
	local offset = FindWalkableOffset(pt, theta, radius, 12, true)
	if offset then
		return pt+offset
	end
end

--宝宝不跟随主人时,自己游走的处理
local function GetNoLeaderHomePos(inst)
	if inst ~= nil then
		print("aiaiaiiaiai")
		local pt = inst:GetPosition()
		local newpoint = GetSpawnPoint(pt,15)--获取15码范围内的一个随机位置
		-- print(newpoint:Get())
		return newpoint
	else
		return nil
	end
end

-------------------------------------------------------------------
function GJ_AI:OnStart()
    local root = PriorityNode(
    {
		Wander(self.inst, GetNoLeaderHomePos, 20,
		{
			minwalktime = .5,
			randwalktime = 2,
			minwaittime = 2,
			randwaittime = 3,
    		})
    }, .25)

    self.bt = BT(self.inst, root)--返回行为树
end

return GJ_AI
