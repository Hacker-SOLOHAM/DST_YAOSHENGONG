--去除卵石路
AddLevelPreInitAny(function(level)
	if level.location ~= "forest" then
		return
	end
	--测试修改
	
	level.overrides.roads = "never"
end)
