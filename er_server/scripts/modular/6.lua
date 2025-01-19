--所属模块:武器
modimport("scripts/weaponsfx.lua")
modimport "scripts/prefabs/rg_amulets_master.lua"
modimport "scripts/prefabs/rg_xxfx_master.lua"

-- TUNING.ARMOR_RUINSHAT_ABSORPTION = 0.6					-- 远古头盔	90
-- TUNING.ARMORRUINS_ABSORPTION = 0.6						-- 远古铠甲	90
-- TUNING.ARMORGRASS_ABSORPTION = 0.3						-- 草甲		60
-- TUNING.ARMORWOOD_ABSORPTION = 0.4						-- 木甲		80
-- TUNING.ARMORMARBLE_ABSORPTION = 0.66					-- 大理石甲	95
-- TUNING.ARMORSNURTLESHELL_ABSORPTION = 0.55				-- 蜗牛甲	60
-- TUNING.ARMOR_FOOTBALLHAT_ABSORPTION = 0.4				-- 猪帽		80
-- TUNING.ARMORDRAGONFLY_ABSORPTION = 0.55					-- 蜻蜓甲	70
-- TUNING.ARMOR_WATHGRITHRHAT_ABSORPTION = 0.55			-- 武神帽	80
-- TUNING.ARMOR_SLURTLEHAT_ABSORPTION = 0.6				-- 蜗牛帽	90
-- TUNING.ARMOR_BEEHAT_ABSORPTION = 0.4					-- 蜂帽		80
-- TUNING.ARMOR_SANITY_ABSORPTION = 0.6					-- 影甲		95
-- TUNING.ARMOR_COOKIECUTTERHAT_ABSORPTION = 0.55			-- 饼干切割机帽		70
-- TUNING.ARMOR_SKELETONHAT_ABSORPTION = 0.55				-- 骨头头盔			70
-- TUNING.ARMOR_HIVEHAT_ABSORPTION = 0.5					-- 蜂后帽			70
-- TUNING.ARMORBRAMBLE_ABSORPTION = 0.5					-- 荆棘外壳			65

--血量 服务端
AddComponentPostInit("health",function(self,inst)
	--血量显示
	inst:ListenForEvent("healthdelta", function(inst, data)
		if inst.components.health then
			local amount = data.newpercent * inst.components.health.maxhealth - data.oldpercent * inst.components.health.maxhealth
			if data.amount and math.abs(data.amount) < math.abs(amount) then
				amount = data.amount
			end
			if math.abs(amount) > 0.1 then
				if amount < 0 then
					SpawnPrefab("er_tips_label"):set(string.format("%.1f",amount),2,40,5).Transform:SetPosition(inst.Transform:GetWorldPosition())
				else
					SpawnPrefab("er_tips_label"):set(string.format("+%.1f",amount),2,30,2).Transform:SetPosition(inst.Transform:GetWorldPosition())
				end
			end
		end
	end)
end)

--饥饿度保存
AddComponentPostInit("hunger", function(self,inst)
	function self:OnSave()
		return {
			loadcurrent = self.current,
		}
	end
	function self:OnLoad(data)
		if data then
			if data.loadcurrent then
				self.current = data.loadcurrent
			end
		end
	end
end)