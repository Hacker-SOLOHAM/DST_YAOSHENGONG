local HuaHouse = Class(function(self, inst)
	self.inst = inst
	self.roomtype = nil			--默认户型3*4
	self.num = 1
	self.maxnum = 400
	self.RoomPosTable = nil		--房间数据
	self.RoomPosTable_ing = {}	--已使用的房间数据
end)

function HuaHouse:BuildHouse()
	self.num = self.num + 1
end

function HuaHouse:IsMax()
	return self.num >= self.maxnum
end

--设置户型
function HuaHouse:SetBuildRoomType(typeNum)
	self.roomtype = typeNum
end
--获取户型
function HuaHouse:GetBuildRoomType()
	return self.roomtype
end

--创建房间中心坐标点平铺数据的世界房间单位分割 RCC ：RoomCenterCoord
function HuaHouse:GreatRCCTileFn(MAX, MAY, interval, w, h, typeID)
	local V3tbl = {}
	--local MAX,MAY = 450,450--TheWorld.Map:GetSize()363 450
	local MAX_X,MAX_Y = (MAX * 4), (MAY * 4)					--做世界大小缩放用于,切割处理的范围
	local Space = interval or 60								--区块间的间距(如果无值,15个地块间距)
	local MIN_X, MIN_Y = w or 16, h or 16						--每个区块尺寸(如果无值,那么最小值按4*4的地块大小)
	local numX = math.floor( MAX_X / ( MIN_X + Space ) )  		--X	分割数量
	local numY = math.floor( MAX_Y / ( MIN_Y + Space ) )		--Z 分割数量
	local DistanceX = ( MAX_X - MIN_X * numX ) / ( numX + 1 )	--基于X分割数量做个自动间隔间距测算
	local DistanceY = ( MAX_Y - MIN_Y * numY ) / ( numY + 1 )	--基于X分割数量做个自动间隔间距测算
	for i1=1, numY do
		for i=1, numX do
			local x = DistanceX * i + ( i - 1 ) * MIN_X + MIN_X * 0.5 - MAX_X * 0.5
			local z = DistanceY * i1 + i1 * MIN_Y * 0.5 + (i1-1) * MIN_Y * 0.5 - MAX_Y * 0.5
			--把得到的坐标,换算到地皮中心点上
			local tilecenter_x, tilecenter_y, tilecenter_z  = TheWorld.Map:GetTileCenterPoint(x, 0, z)
			-- 修正地块数据
			-- if math.mod(tilecenter_x,2) ~= 0 then tilecenter_x = tilecenter_x +1 end
			-- if math.mod(tilecenter_z,2) ~= 0 then tilecenter_z = tilecenter_z +1 end
			--房间心点在地块中心
			if typeID == 0 then
				table.insert(V3tbl, Point(tilecenter_x, 0, tilecenter_z))
			--房间心点在地块角
			elseif typeID == 1 then
				table.insert(V3tbl, Point(tilecenter_x+2, 0, tilecenter_z+2))
			--房间心点在地块x上侧边的中间
			elseif typeID == 2 then
				-- V3tbl = {}
				table.insert(V3tbl, Point(tilecenter_x+2, 0, tilecenter_z))
			--房间心点在地块z右侧边的中间
			elseif typeID == 3 then
				table.insert(V3tbl, Point(tilecenter_x, 0, tilecenter_z+2))
			end
			--任意位置,暂不使用
			-- table.insert(V3tbl, Point(x, 0, z))
		end
	end
	return V3tbl
end
--DEBUG
-- GreatRCCTileFn(nil,16,24)

--创建房间中心坐标点平铺 表数据
function HuaHouse:GreatRCCTileTable(MAX,MAY)
-- local function GreatRCCTileTable(MAX,MAY)
	--local MAX,MAY = 450,450--TheWorld.Map:GetSize()
	local OX,OZ = MAX * 4, MAY * 4 --当前地图中心偏距
	local FJTABLE  = {
	--[n]:id	hw:房间长宽单位		typeID:房间心点是否在地块中心1:在0:不在2:在    of:偏移值    data:坐标数据容器(表数据)
	--[[
		[1] = { hw = {16,16}, 	typeID = 1,	of = Point(-OX,0,-OZ), 	data = {} },	--4*4	--左下角--ok
		[2] = { hw = {16,24}, 	typeID = 1,	of = Point(OX,0,OZ), 	data = {} },	--4*6 	--右上角--ok
		
		[3] = { hw = {4,4}, 	typeID = 0,	of = Point(OX,0,-OZ), 	data = {} },	--1*1	--右下角
		[4] = { hw = {8,8}, 	typeID = 1,	of = Point(-OX,0,OZ), 	data = {} },	--2*2	--左上角
		
		[5] = { hw = {12,12}, 	typeID = 0,	of = Point(0,0,-OZ), 	data = {} },	--3*3	--下方
		[6] = { hw = {12,20}, 	typeID = 0,	of = Point(0,0,OZ), 	data = {} },	--3*5	--上方
		--备用房间规格
		[7] = { hw = {12,16}, 	typeID = 3,	of = Point(-OX,0,0), 	data = {} },	--3*4	--左侧--ok
		[8] = { hw = {16,16}, 	typeID = 1,	of = Point(OX,0,0), 	data = {} },	--4*4	--右侧
		]]
		-------------------------------------------------
		[1] = { hw = {12,16}, 	typeID = 3,	of = Point(-OX,0,-OZ), 	data = {} },	--3*4	--左下角--ok
		[2] = { hw = {8,12}, 	typeID = 2,	of = Point(OX,0,OZ), 	data = {} },	--2*3	--右上角--ok
		[3] = { hw = {8,8}, 	typeID = 1,	of = Point(OX,0,-OZ), 	data = {} },	--2*2	--右下角--ok
		[4] = { hw = {12,20}, 	typeID = 0,	of = Point(-OX,0,OZ), 	data = {} },	--3*5	--左上角--ok
		
		[5] = { hw = {12,12}, 	typeID = 0,	of = Point(0,0,-OZ), 	data = {} },	--3*3	--下方--noTest
		[6] = { hw = {12,20}, 	typeID = 0,	of = Point(0,0,OZ), 	data = {} },	--3*5	--上方--noTest

		[7] = { hw = {12,16}, 	typeID = 3,	of = Point(-OX,0,0), 	data = {} },	--3*4	--左侧--noTest
		[8] = { hw = {16,16}, 	typeID = 1,	of = Point(OX,0,0), 	data = {} },	--4*4	--右侧--noTest
	}
	--根据建立的函数填充表数据内容
	for k,v in pairs(FJTABLE) do
		local data = v.data
		local offsetpos = v.of
		local w,h = v.hw[2], v.hw[1]
		local typeID = v.typeID
		-- print ("长度: "..h.."  ".."宽度: "..w)
		--不给固定间隔设置,使用房间户型和数量自动测算.-------------户型接口
		local V3tbl = self:GreatRCCTileFn(MAX,MAY,nil, w, h, typeID)
		--local V3tbl = self:GreatRCCTileFn(60, 4, 4)
		--取2400~-2400以内的安全坐标xz值
		for k1,v1 in ipairs(V3tbl) do
			local checkX = false
			local checkZ = false
			local checkVal = MAX*5
			-- if (x1 and x1 >= xmax *2 and x1 <= xmax*5) and (z1 and z1 >= zmax*2 and z1 <= zmax*5) then
			local v1Tmp = (v1 + offsetpos )
			-- if v1Tmp.x <= checkVal and v1Tmp.x >= -checkVal then checkX = true end
			-- if v1Tmp.z <= checkVal and v1Tmp.z >= -checkVal then checkZ = true end
            if math.abs(v1Tmp.x) <= checkVal then checkX = true end
			if math.abs(v1Tmp.z) <= checkVal then checkZ = true end
			if checkX == true and checkZ == true then
				-- table.insert(data, (v1 + offsetpos ))
				-- math.ceil(v1Tmp.x)
				-- math.ceil(v1Tmp.z)
				table.insert(data, v1Tmp)
			end
		end
		V3tbl = nil
		collectgarbage("step") --清理内存
	end
	self.RoomPosTable = FJTABLE
end
--DEBUG
-- GreatRCCTileTable()
--暂不使用
function HuaHouse:SetPosition()
	-- 如果没有房间数据,那么创建
	if self.RoomPosTable == nil then
		-- print ("没有房间数据！")
		local MAX,MAY = TheWorld.Map:GetSize()--;print (MAX,MAY)true false
		self:GreatRCCTileTable(MAX,MAY)
	else
		-- print ("有房间数据！")
	end
end
function HuaHouse:GetPosition()
	if self:IsMax() then
		return
	end
	
	-- local MAX,MAY = TheWorld.Map:GetSize()--;print (MAX,MAY)true false
	-- self:GreatRCCTileTable(MAX,MAY)
	--[[
	--如果没有房间数据,那么创建
	if self.RoomPosTable == nil then
		print ("没有房间数据！")
		local MAX,MAY = TheWorld.Map:GetSize()--;print (MAX,MAY)true false
		self:GreatRCCTileTable(MAX,MAY)
	else
		print ("有房间数据！")
	end
	]]
	local x,z = 1500,1500--初始化调试值
	--目标:排除已使用的房间数据,重复使用未使用的房间数据
	local RoomType = self.roomtype
	local RoomNum = self.num
	local RoomTB = self.RoomPosTable
	-- #map.RoomPosTable[RoomType].data
	if RoomTB ~=nil then
		-- print (RoomType)
		local TagetRoomData = RoomTB[RoomType].data--访问不同户型的数据表		
		for k,v in pairs(TagetRoomData) do		
		--老的方案
			x,z = v.x, v.z
			-- TagetRoomData[k] = nil
			-- self.RoomPosTable_ing[k] = {v.x, v.z}
			local ents = TheSim:FindEntities(x, 0, z, 15, {"hua_house"})--检查该区域是否有房间
			if #ents == 0 then return x, z end
		--新的方案
		end
	end
	return x, z
end
-- GreatRoom 函数参数说明:
-- BuildObj:房间出去索引的对象,用于引导房间出去后的目标对象位置.
-- RoomType:户型,.1:3x4;	2:2x3;	3:2x2;	4:3x5	5:4x4	6:4x6	7:2x3	8::2x4
-- HouseCenterPoint:建立房间原点的Prefab定义:如:"hua_house"
-- FurnitureObj:房间自带的物品:如:{"soil",3,4}
-- LightObj:房间内的灯光对象名称:如:"light_floral_scallop"
-- OutDoorObj:房间内出去的对象,一般为门.需要具有传送组件.如:"hua_door_exit"
-- floorID:室内地板对象.如:"ll_floor"
-- WallPaperID:室内墙壁对象.如:"hua_wallpaper"
-- NoDarwObj:室内周围放置玩家跑出去的阻挡物.如:"nodraw_wall"
-- RefObj:建立一个房间心点的参照物:--treasurechest--wall_stone
--引用样例:
-- TheWorld.components.huahouse:GreatRoom(inst,1,"hua_house","light_floral_scallop",nil,"hua_door_exit","ll_floor","hua_wallpaper","nodraw_wall","minisign")
function HuaHouse:GreatRoom(BuildObj,RoomType,HouseCenterPoint,FurnitureObj,LightObj,OutDoorObj,floorID,WallPaperID,NoDarwObj,RefObj)
	--if BuildObj:HasTag("SetCanUseRoomObjTag")	then --将来插入任意对象接口:需要填充组件和功能.暂时搁置
	--设置户型
	self:SetBuildRoomType(RoomType)
	--创建并获取房间心点位置
	local x,z = self:GetPosition()
	-- print (x,z)
	--清空一次该区域
	local removeents = TheSim:FindEntities(x, 0, z, 15)
	for i,v in ipairs(removeents) do
		v:Remove()
	end
	-----------------	构造户型配置表	--------------
	--户型配置表	
	local RoomConfigTable = {
		[1] = {HW = {12,16},RTID = 1,Pt = Point(0,0,0)},	--3*4	--左下角--ok
		[2] = {HW = {8,12},	RTID = 2,Pt = Point(0,0,0)},	--2*3	--右上角--ok
		[3] = {HW = {8,8},	RTID = 3,Pt = Point(0,0,0)},	--2*2	--右下角--ok
		[4] = {HW = {12,20},RTID = 4,Pt = Point(0,0,0)},	--3*5	--左上角--ok
	}
	local RCDataTable = {
		L_of = 			{},	--灯的偏移值
		W_of = 			{},	--窗户的偏移值
		OutDoor_of = 	{},	--出口对象的偏移值
		F_of = 			{},	--室内构造地板对象的偏移值
		WP_of = 		{},	--室内构造墙壁对象的偏移值
		RefObj_of = 	{},	--室内中心点构造的参考对象的偏移值
		--或者其他配置
	}
	--把RCDataTable的表构造添加到RoomConfigTable表中
	for _,v in pairs(RCDataTable) do
		for k,obj in pairs(RoomConfigTable) do
			obj[_] = v
		end
	end

	--根据户型配置 RoomConfigTable 表
	local RCFT_ID = RoomConfigTable[RoomType]--户型数据表ID映射
	
	local pAnim = "idle"
	--3*4
	if RoomType == 1 then
		pAnim = "idle3x4"
		RCFT_ID.HW 		= {12,16}												--建立房间户型大小:(深度*宽度)
		RCFT_ID.RTID 	= 1														--户型模式
		RCFT_ID.Pt 		= {x,0,z,0,0,0,1,1,1}									--房间心点对象--1-3位置\4-6旋转\7-9缩放
		RCFT_ID.L_of 	= {x,0,z,0,0,0,1,1,1}									--灯光对象
		RCFT_ID.W_of	= {x,0,z,0,0,0,1,1,1}									--窗户对象
		RCFT_ID.OutDoor_of	= {x + RCFT_ID.HW[1]/2 -1.5,0,z,0,0,0,1,1,1,"idle"}	--出去的门对象
		RCFT_ID.F_of		= {x,0,z,-90,0,0,1,1,1,pAnim}						--地板
		RCFT_ID.WP_of		= {x,0,z,0,0,0,1,1,1,pAnim}							--墙壁222
		RCFT_ID.RefObj_of	= {x,0,z,0,0,0,1,1,1}								--建立的额外心点参照物
	--2*3
	elseif RoomType == 2 then
		pAnim = "idle2x3"
		RCFT_ID.HW 		= {8,12}
		RCFT_ID.Pt 		= {x,0,z,0,0,0,1,1,1}
		RCFT_ID.L_of 	= {x,-0.5,z,0,0,0,0.8,0.8,0.8}
		RCFT_ID.W_of	= {x,0,z,0,0,0,1,1,1}
		RCFT_ID.OutDoor_of	= {x + RCFT_ID.HW[1]/2 -1.5,0,z,0,0,0,1,1,1,"idle"}
		RCFT_ID.F_of		= {x,0,z,-90,0,0,1,1,1,pAnim}
		RCFT_ID.WP_of		= {x,0,z,0,0,0,1,1,1,pAnim}--1.45,1.5,1.5
		RCFT_ID.RefObj_of	= {x,0,z,0,0,0,1,1,1}
	--2*2
	elseif RoomType == 3 then
		pAnim = "idle2x2"
		RCFT_ID.HW 		= {8,8}
		RCFT_ID.Pt 		= {x,0,z,0,0,0,1,1,1}
		RCFT_ID.L_of 	= {x,-0.5,z,0,0,0,0.8,0.8,0.8}
		RCFT_ID.W_of	= {x,0,z,0,0,0,1,1,1}
		RCFT_ID.OutDoor_of	= {x + RCFT_ID.HW[1]/2 -1.5,0,z,0,0,0,1,1,1,"idle"}
		RCFT_ID.F_of		= {x,0,z,-90,0,0,1,1,1,pAnim}
		RCFT_ID.WP_of		= {x,0,z,0,0,0,1,1,1,pAnim}
		RCFT_ID.RefObj_of	= {x,0,z,0,0,0,1,1,1}
	--3*5
	elseif RoomType == 4 then
		pAnim = "idle3x5"
		RCFT_ID.HW 		= {12,20}
		RCFT_ID.Pt 		= {x,0,z,0,0,0,1,1,1}
		RCFT_ID.L_of 	= {x,0,z,0,0,0,1,1,1}
		RCFT_ID.W_of	= {x,0,z,0,0,0,1,1,1}
		RCFT_ID.OutDoor_of	= {x + RCFT_ID.HW[1]/2 -1.5,0,z,0,0,0,1,1,1,"idle"}
		RCFT_ID.F_of		= {x,0,z,-90,0,0,1,1,1,pAnim}
		RCFT_ID.WP_of		= {x,0,z,0,0,0,1,1,1,pAnim}
		RCFT_ID.RefObj_of	= {x,0,z,0,0,0,1,1,1}
	end
	
	--建立房间原点(中心点)
	if HouseCenterPoint ~=nil then
		local HCP = SpawnPrefab(HouseCenterPoint)
		HCP.Transform:SetPosition(RCFT_ID.Pt[1],RCFT_ID.Pt[2],RCFT_ID.Pt[3])
		HCP.RoomTypeSet = RCFT_ID.HW	--RoomType or 1 --传递户型数据
		-- HCP.RoomCameraMode = RoomType--self:GetBuildRoomType()
		HCP._RoomCameraMode:set(self:GetBuildRoomType())--网络传输
	end
	--房间自带的物品
	if FurnitureObj ~= nil then
		local x = RCFT_ID.L_of[1] - 6.5
		local y = RCFT_ID.L_of[2]
		local z = RCFT_ID.L_of[3] - 6
		if FurnitureObj == 4 then
			--左侧建筑
			local item1 = SpawnPrefab("pig_mechanic")
			-- item1.Transform:SetPosition(x+7,y,z+1)
			item1.Transform:SetPosition(x+5,y,z+6)
			--中间建筑
			local item2 = SpawnPrefab("er_workshop006")
			-- item2.Transform:SetPosition(x+7,y,z+6)
			item2.Transform:SetPosition(x+9,y,z+6)
			local item3 = SpawnPrefab("ll_cabinet")
			item3.Transform:SetPosition(x+2,y,z+2)
			local item4 = SpawnPrefab("ll_cabinet")
			item4.Transform:SetPosition(x+2,y,z+10)
			--右侧建筑
			-- local item5 = SpawnPrefab("er_workshop007")
			-- item5.Transform:SetPosition(x+7,y,z+11)
		elseif FurnitureObj == 3 then
			for i=1,3 do
				SpawnPrefab("er_crop_soil").Transform:SetPosition(x+3*i,y,z)
				for j=1,4 do
					SpawnPrefab("er_crop_soil").Transform:SetPosition(x+3*i,y,z+3*j)
				end
			end
		elseif FurnitureObj == 2 then
			for i=1,3 do
				SpawnPrefab("er_flower_soil").Transform:SetPosition(x+3*i,y,z)
				for j=1,4 do
					SpawnPrefab("er_flower_soil").Transform:SetPosition(x+3*i,y,z+3*j)
				end
			end
		elseif FurnitureObj == 1 then
			SpawnPrefab("er_workshop001").Transform:SetPosition(x+3,y,z+12)--右上
			SpawnPrefab("er_workshop002").Transform:SetPosition(x+12,y,z+12)--右下
			SpawnPrefab("er_workshop003").Transform:SetPosition(x+12,y,z)--左下
			SpawnPrefab("er_workshop004").Transform:SetPosition(x+3,y,z)--左上
		end
	end
	--灯
	if LightObj ~=nil then
		local LightObjSet = SpawnPrefab(LightObj)
		LightObjSet.Transform:SetPosition(RCFT_ID.L_of[1],RCFT_ID.L_of[2],RCFT_ID.L_of[3])
		LightObjSet.Transform:SetScale(RCFT_ID.L_of[7],RCFT_ID.L_of[8],RCFT_ID.L_of[9])
		LightObjSet.objscale = {RCFT_ID.L_of[7],RCFT_ID.L_of[8],RCFT_ID.L_of[9]}--记录缩放系数.
	end
	--创建出去的门
	if OutDoorObj ~=nil and BuildObj ~=nil then
		local outdoor = SpawnPrefab(OutDoorObj)
		outdoor.Transform:SetPosition(RCFT_ID.OutDoor_of[1],RCFT_ID.OutDoor_of[2],RCFT_ID.OutDoor_of[3])
		if FurnitureObj == 4 then--锻造房,单独调整出去门的位置
			local x = RCFT_ID.L_of[1] - 6.5
			local y = RCFT_ID.L_of[2]
			local z = RCFT_ID.L_of[3] - 6
			outdoor.Transform:SetPosition(x+9.5,y,z+1.5)
		end
		--出口的处理
		outdoor.components.teleporter:Target(BuildObj)
		BuildObj.components.teleporter:Target(outdoor)
	end
	--建立地板
	if floorID ~= nil then
		local floorObjSet = SpawnPrefab("ll_floor")
		floorObjSet.Transform:SetPosition(RCFT_ID.F_of[1],RCFT_ID.F_of[2],RCFT_ID.F_of[3])
		floorObjSet.Transform:SetScale(RCFT_ID.F_of[7],RCFT_ID.F_of[8],RCFT_ID.F_of[9])
		floorObjSet.Transform:SetRotation(RCFT_ID.F_of[4])
		floorObjSet.objRot = RCFT_ID.F_of[4]
		floorObjSet.objscale = {RCFT_ID.F_of[7],RCFT_ID.F_of[8],RCFT_ID.F_of[9]}
		floorObjSet.objAnim = RCFT_ID.F_of[10]--户型匹配
		floorObjSet.AnimState:PlayAnimation(RCFT_ID.F_of[10])--激活更新一次
		if floorID ~= 0 then
			floorObjSet.AnimState:OverrideSymbol("image", "ll_floors", string.format("image%03d", floorID))
			floorObjSet._huaskin = floorID
		end
	end
	--建立墙壁
	if WallPaperID ~= nil then	
		local wallPaperObjSet = SpawnPrefab("ll_wallpaper")
		wallPaperObjSet.Transform:SetPosition(RCFT_ID.WP_of[1],RCFT_ID.WP_of[2],RCFT_ID.WP_of[3])
		wallPaperObjSet.Transform:SetScale(RCFT_ID.WP_of[7],RCFT_ID.WP_of[8],RCFT_ID.WP_of[9])
		wallPaperObjSet.objscale = {RCFT_ID.WP_of[7],RCFT_ID.WP_of[8],RCFT_ID.WP_of[9]}
		wallPaperObjSet.objAnim = RCFT_ID.WP_of[10]--户型匹配
		wallPaperObjSet.AnimState:PlayAnimation(RCFT_ID.WP_of[10])--激活更新一次
		if WallPaperID ~= 0 then
			if WallPaperID > 3 then
				wallPaperObjSet.AnimState:OverrideSymbol("image", "ll_wallpaper2", string.format("image%03d", WallPaperID))
			elseif WallPaperID > 0 then
				wallPaperObjSet.AnimState:OverrideSymbol("image", "ll_wallpaper1", string.format("image%03d", WallPaperID))
			end
			wallPaperObjSet._huaskin = WallPaperID
		end
	end
	--房间周围防止玩家出去的隐形碰撞墙
	if NoDarwObj ~= nil then
		local function addwall(x,z)
			local wall = SpawnPrefab(NoDarwObj) --nodraw_wall
			if wall ~= nil then 
				wall.Physics:SetCollides(false)
				wall.Physics:Teleport(x, 0, z)
				wall.Physics:SetCollides(true)
			end			
		end
		local a1,a2 = math.abs(RCFT_ID.HW[1]/2), math.abs(RCFT_ID.HW[2]/2)
		--3*4 {12,16}
		for i = -a2, a2 do
			addwall(x - (a1 + 1.25),z + i)--上:主要装饰墙壁,多预留0.75+0.5个单位
			addwall(x + (a1 + 0.5),z + i)--下:预留一个奇葩的负向装饰物(中型的对象间距1.25个单位)
		end
		for i = -(a1+1), (a1+1) do
			addwall(x + i,z - (a2 + 0.75))--左:次要装饰墙壁:给0.5算了
			addwall(x + i,z + (a2 + 0.75))--右:次要装饰墙壁
		end
	end
	--建立一个房间心点的参照物
	if RefObj ~= nil then
		SpawnPrefab(RefObj).Transform:SetPosition(RCFT_ID.RefObj_of[1],RCFT_ID.RefObj_of[2],RCFT_ID.RefObj_of[3])
	end
	self:BuildHouse()--更新下世界房间建造的数量
end

function HuaHouse:OnSave()
    return {
        num = self.num,
		rpt = self.RoomPosTable
    }
end

function HuaHouse:OnLoad(data)
	if data.num then
		self.num = data.num
	end
	if data.rpt then
		self.RoomPosTable = data.rpt
	end
end

return HuaHouse