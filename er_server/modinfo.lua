name = "妖神宫(服务端)"
description ="商店"
author = "Error"
version = "1.1"
forumthread = ""
api_version = 10
all_clients_require_mod = false
client_only_mod = false
dst_compatible = true
priority = 1

icon_atlas = "modicon.xml"
icon = "modicon.tex"

server_filter_tags = {}

configuration_options = {
	{name = "Title", label = "怪物", options = {{description = "", data = ""},}, default = "",},
	{
		name = "rg_gwlevel",
		label = "怪物强化等级",
		options = 
		{
			{description = "简单", data = 1,hover = "怪物等级 1-100"},
			{description = "普通", data = 2,hover = "怪物等级 100-200"},
			{description = "困难", data = 3,hover = "怪物等级 200-300"},
		},
		default = 1,
	},
	{
		name = "rg_variation",
		label = "怪物变异权重(普通/精灵/妖精/妖王/魔王)",
		options = 
		{
			{description = "简单", data = {50,25,15,6,4},hover = "50/25/15/6/4"},
			{description = "困难", data = {35,30,20,10,5},hover = "35/30/20/10/5"},
			{description = "地狱", data = {15,35,25,15,10},hover = "15/35/25/15/10"},
		},
		default = {50,25,15,6,4},
	},
	{
		name = "rg_boss",
		label = "是否生成boss",
		options = 
		{
			{description = "是", data = 1,hover = "地图上会生成boss"},
			{description = "否", data = 2,hover = "地图上不会生成boss"},
		},
		default = 2,
	},
	{
		name = "rg_bossstrength",
		label = "boss强度",
		options = 
		{
			{description = "正常", data = 0,hover = "原版BOSS"},
			{description = "简单", data = 1,hover = "boss微强化"},
			{description = "困难", data = 2,hover = "BOSS大强化"},
		},
		default = 0,
	},
	{
		name = "worldname", 
		label = "世界名称",
		hover = "多层版需要在每个世界modoverrides里单独设置世界名字",
		options =
		{
			{description = "modoverrides改世界名字", data = "世界名字"},
		},
		default = "世界名字",
	},
}