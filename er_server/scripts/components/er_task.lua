local CIHUI = {
	["guai"] = "请完成以下[@ff0000猎杀任务]",
	["cai"] = "请完成以下[@ffff00采集任务]",
	["shou"] = "请完成以下[@00ffff收集任务]",
	["diao"] = "请完成以下[@1C83AA钓鱼任务]",
}


local function renwukill(inst, data)
	--{ victim = self.inst, aoe = aoe, yuansu = yuansu }
	--local duiwu = QMmh:GetDuiLie(inst)
	local yushe = data.victim and data.victim.prefab
	local er_task = inst.components.er_task
	if yushe and er_task and er_task:IsVal() then
		er_task:TiJiao(yushe)
	end
end

local function renwucai(inst, data)
	--{ object = self.inst, loot = loot }
	local er_task = inst.components.er_task
	local yushe = data.object and data.object.prefab
	if yushe and er_task and er_task:IsVal() then
		er_task:TiJiao(yushe)
	end
end

local function renwudiaoyu(inst, data)
	local er_task = inst.components.er_task
	local yushe = data.target and data.target.prefab
	if yushe and er_task and er_task:IsVal() then
		er_task:TiJiao(yushe)
	end
end

local Er_Task = Class(function(self, inst)
    self.inst = inst
	self.renwunum = 0
	inst:ListenForEvent("renwujisha", renwukill)
	inst:ListenForEvent("picksomething", renwucai)
	inst:ListenForEvent("qm_shangyu", renwudiaoyu)
	inst:ListenForEvent("qmpick_pick", renwucai)
end)

function Er_Task:OnRemoveFromEntity()
	self.inst:RemoveEventCallback("renwujisha", renwukill)
	self.inst:RemoveEventCallback("picksomething", renwucai)
	self.inst:RemoveEventCallback("qm_shangyu", renwudiaoyu)
	self.inst:RemoveEventCallback("qmpick_pick", renwucai)
end

function Er_Task:SetRenWu(data)
	self.renwu = nil
	if data then
		self.renwu = {}
		if type(data) == "table" then
			for k,v in pairs(data) do
				if CIHUI[k] then
					self.renwu[k] = {}
					if type(v) == "table" then
						for k1,v1 in pairs(v) do
							self.renwu[k][k1] = { x = 0, y = v1 }
						end
					elseif type(v) == "function" then
						local rentbl = v(self.inst, ( self.inst.RWSX and self.inst.RWSX:GetLv() or 1 ))
						if rentbl then
							for k1,v1 in pairs(rentbl) do
								self.renwu[k][k1] = { x = 0, y = v1 }
							end
						end
					end
				end
			end
		end
		if type(self.renwu) ~= "table" or next(self.renwu) == nil then
			self.renwu = nil
		end
	end
end

function Er_Task:SetJiangLi(data)
	--{ PTYXB = 0,	TSYXB = 0, EXP = 0, YUSHE = {} }
	self.jiangli = data
end

function Er_Task:GetJiangLi(data)
	--{ PTYXB = 0,	TSYXB = 0, EXP = 0, YUSHE = {} }
	return self.jiangli
end

local function qm_GetItem_fn01(p, giver, num, lv)
	if p and num and num > 0 and ( lv == nil or lv <= 300 ) then
		local item = SpawnPrefab(p)
		if item ~= nil then
			local num2 = 1
			if item.components.stackable then
				num2 = math.min(num, item.components.stackable.maxsize)
				item.components.stackable:SetStackSize( num2 )
			end
			num = num - num2
			giver.components.inventory:GiveItem(item)
			if num > 0 then
				lv = ( lv or 1 ) + 1
				qm_GetItem_fn01(p, giver, num, lv)
			end
		end
	end
end

function Er_Task:DoJiangLi(bool)
	--{ PTYXB = 0,	TSYXB = 0, EXP = 0, YUSHE = {} }
	if bool and self.jiangli then
		local inv = self.inst.components.inventory
		if inv then
			local data = self.jiangli
			if data["PTYXB"] and data["PTYXB"] > 0 and self.inst.YXBpt then
				self.inst:YXBpt(data["PTYXB"])
			end
			if data["TSYXB"] and data["TSYXB"] > 0 and self.inst.YXBts then
				self.inst:YXBts(data["TSYXB"])
			end
			if data["EXP"] and data["EXP"] > 0 and self.inst.RWSX then
				self.inst.RWSX:Sexp(data["EXP"], false, true ) --(not self.inst.IsVip)
			end
			if data["YUSHE"] then
				for k,v in pairs(data["YUSHE"]) do
					if type(k) == "string" then
						qm_GetItem_fn01(k, self.inst, v, 200)
					end
				end
			end
			self.inst:PushEvent("DoJiangLi", { yxb = data["TSYXB"], zuan = data["TSYXB"], exp = data["EXP"] } )
		end
	end
	self.jiangli = nil
end


function Er_Task:TiJiao(yushe)
	if self:IsVal() then
		for k,v in pairs(self.renwu) do
			for k1,v1 in pairs(v) do
				if k1 == yushe then
					v1.x = v1.x + 1
				end
			end
		end
	end
end

function Er_Task:IsVal()
	return self.renwu ~= nil
end


-------------------------------
function Er_Task:OnSave()
	if self:IsVal() or self:GetNum() > 0 then
		return { renwu = self.renwu, jiang = self.jiangli, renwunum = self.renwunum }
	end
end

function Er_Task:AddNum(num)
	self.renwunum = math.ceil( ( self.renwunum or 0 ) + (num or 1) )
end

function Er_Task:GetNum()
	return self.renwunum or 0
end

function Er_Task:GetFaKuan()
	return self.jiangli and self.jiangli["PTYXB"] and self.jiangli["PTYXB"] * 3 or 3000
end

function Er_Task:OnLoad(data)
	if data then
		self.renwu = data.renwu
		self.jiangli = data.jiang
		self.renwunum = data.renwunum or 0
	end
end
-------------------------------
local RenWuXuLie = {
	{ key = "guai",		str = "[@DD55A4	%s (%s / %s)]" },
	{ key = "cai",		str = "[@1FE7E7	%s (%s / %s)]" },
	{ key = "shou",		str = "[@1CEA21	%s x %s]" },
	{ key = "diao",		str = "[@1CEA21	%s (%s / %s)]" },
}

function Er_Task:GetStrData()
	--{ PTYXB = 0,	TSYXB = 0, EXP = 0, YUSHE = {} }
	local t = {}
	if self:IsVal() then
		if self.renwu["guai"] then
			table.insert(t, CIHUI["guai"])
			for k,v in pairs(self.renwu["guai"]) do
				local name = STRINGS.NAMES[string.upper(k)] or "未知"
				local x,y = v.x, v.y
				local str = string.format("[@DD55A4	%s ( %s / %s )]", name, x, y)
				table.insert(t, str)
			end
		end
		if self.renwu["cai"] then
			table.insert(t, CIHUI["cai"])
			for k,v in pairs(self.renwu["cai"]) do
				local name = STRINGS.NAMES[string.upper(k)] or "未知"
				local x,y = v.x, v.y
				local str = string.format("[@1FE7E7	%s ( %s / %s )]", name, x, y)
				table.insert(t, str)
			end
		end
		if self.renwu["shou"] then
			table.insert(t, CIHUI["shou"])
			for k,v in pairs(self.renwu["shou"]) do
				local name = STRINGS.NAMES[string.upper(k)] or "未知"
				local x,y = v.x, v.y
				local str = string.format("[@1CEA21	%s x %s]", name, y)
				table.insert(t, str)
			end
		end
		if self.renwu["diao"] then
			table.insert(t, CIHUI["diao"])
			for k,v in pairs(self.renwu["diao"]) do
				local name = STRINGS.NAMES[string.upper(k)] or "未知"
				local x,y = v.x, v.y
				local str = string.format("[@1CEA21	%s ( %s / %s )]", name, x, y)
				table.insert(t, str)
			end
		end
		
		local numn = 10 - #t
		if numn > 0 then
			for i=1, numn do
				table.insert(t, " \n")
			end
		end
		if self.jiangli then
			local dannum = self:GetNum()
			local ci = ( dannum > 0 and (dannum % 10) * 10 ) or 100
			local vip = self.inst.IsVip
			table.insert(t, string.format("任务奖励: %s%%                任务量 :  %s", ci,dannum) )
			local jlp = self.jiangli
			if jlp["PTYXB"] and jlp["PTYXB"] > 0 then
				local str = string.format("[@25E0E0游戏币 : %s]", jlp["PTYXB"])
				table.insert(t, str)
			end
			if jlp["TSYXB"] and jlp["TSYXB"] > 0 then
				local str = string.format("[@DD3CD5钻石币 : %s]", jlp["TSYXB"])
				table.insert(t, str)
			end
			if jlp["EXP"] and jlp["EXP"] > 0 then
				local str = string.format("[@C1E633经验值 : %s]                 VIP加成 : %s%%", jlp["EXP"], (vip and 50 or 0) )
				table.insert(t, str)
			end
			if jlp["YUSHE"] then
				local tt = {}
				for k,v in pairs(jlp["YUSHE"]) do
					local name = STRINGS.NAMES[string.upper(k)] or "未知"
					local str = string.format("[@DD55A4%sx%s]", name, v)
					table.insert(tt, str)
				end
				local str = table.concat(tt, "  ")
				table.insert(t, str)
			end
		end
		--if self.renwu["shou"] then
			local numn = 16 - #t
			if numn > 0 then
				local ss = string.rep(" \n", numn)
				table.insert(t, ss)
			end
			local numb = self:GetFaKuan()
			local anniu = string.format("[@DD55A4#ren  提交任务  ]                        [@DD55A4#cls  取消任务  ]  [@FF0000 需 %s 游戏币]", numb)
			table.insert(t, anniu)
		--end
	else
		table.insert(t, " \n \n \n[@FF0000暂无任务发布]")
	end

	return table.concat(t, "\n")
end

function Er_Task:DoTuiSong()
	if self.inst.player_classified and self.inst.player_classified._RenWu then
		local str = self:GetStrData()
		self.inst.player_classified._RenWu:set_local(str)
		self.inst.player_classified._RenWu:set(str)
	end
end

function Er_Task:QingLi()
	self.renwu = nil
	self.jiangli = nil
end

function Er_Task:CanClsRen(bool)
	local fakuan = self:GetFaKuan()
	if self.inst.QM_PTYXB and self.inst.QM_PTYXB >= fakuan then
		if bool then
			self.inst:YXBpt( -fakuan )
		end
		return true
	end
	return false
end


function Er_Task:CanWan()
	if self:IsVal() then
		for k,v in pairs(self.renwu) do
			if k == "shou" then
				local inv = self.inst.components.inventory
				for k1,v1 in pairs(v) do
					if not inv:Has(k1, v1.y) then
						return false
					end
				end
			else
				for k1,v1 in pairs(v) do
					if v1.x < v1.y then
						return false
					end
				end
			end
		end
		return true
	end
	return false
end


function Er_Task:DoWanCheng()
	if self:CanWan() then
		local data = self.renwu["shou"]
		if data then
			local inv = self.inst.components.inventory
			for k,v in pairs(data) do
				inv:ConsumeByName(k, v.y)
			end
		end
	end
	self:AddNum()
	self:DoJiangLi(true)
	self:QingLi()
end

function Er_Task:dodebug()
	local t = {"{"}
	if self:IsVal() or self:GetNum() > 0 then
		table.insert(t, ( DataDumper(self.renwu, "RenWu", true) ) )
		table.insert(t, ( DataDumper(self.jiangli, "Jiang", true) ) )
		table.insert(t, self.renwunum )
	end
	table.insert(t, "}")
	return table.concat(t, " | ")
end

return Er_Task