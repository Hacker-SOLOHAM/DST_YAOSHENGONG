--ByLaolu 2020-05-31
local InteriorCreator = Class(function(self, inst)
	self.inst = inst
	self.roomtype = 2
	self.num = 1
	self.maxnum = 400
	self.RoomPosTable = {}		--房间数据
	self.RoomPosTable_ing = {}	--已使用的房间数据
end)
--框架设计:
--静态框架
-- 1.世界创建后,创建房间心点坐标数据,提供给玩家使用.
-- 2.共享数据到客户端,要写服务端和客户端两个组件才行.
-- 3.在该房间创建器中,建立一个创建房间的函数,反正都在锁定摄像机的情况下
-- 直接在组件中创建需要对象即可,然后吧功能函数的触发暴露给玩家调用.

--创建函数:创建房间需要的配置函数
-- 框架:
-- 房间
--[[
TB =
{
	[Player.GUID] = 
	{
		[inst] =
		{	
			RoomType = 0,	RCCoord = {x,y,z},--RoomCenterCoord
			data =
			{
				[RoomClassName] = {inst,data = {x,y,z},fn,...},
			}
		},
	}
}
]]
--更新函数:用于客户端更新世界房间数据表
--存储与加载函数:常规,保存世界房间数据.
-- 4.调用函数.新建一个暂存房间数据的表,当房间移除时,将该表的键值数据回填回源房间数据表中,完成重复使用
--单纯使用FindEntity访问物质表Ents太浪费资源和性能.

--动态框架(搁置)
-- 1.动态创建和修改世界房间数据表(暂时么想好怎么折腾,青木说可以用两个表转换,然,这还是静态框架)
function InteriorCreator:OnSave()
    return
    {
        num = self.num,				--存储当前世界房间数量
		rpt = self.RoomPosTable,	--存储世界房间心点数据
    }
end

function InteriorCreator:OnLoad(data)
    if data.num ~= nil then
		self.num = data.num
	end
    if data.rpt ~= nil then
		self.RoomPosTable = data.rpt
	end
end

return InteriorCreator