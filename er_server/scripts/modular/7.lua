--所属模块:UI复活/整组烹饪
if not TheNet:GetIsClient() then
	--复活
	AddModRPCHandler("Er_Revive", "dorevive", function(player, num)
		if num == 1 then
			for k,v in pairs(Ents) do
				if v:HasTag("multiplayer_portal") then
					local x,y,z = v.Transform:GetWorldPosition()
					player.Physics:Teleport(x,y,z)
					player:DoTaskInTime(1, function()
						player:PushEvent('respawnfromghost')
						player:DoTaskInTime(2, function()
							player.components.er_leave:UpdateModular()
						end)
					end)
				end
			end
		else
			player:AddQMYXB(1, player.net_level:value() * -10)
			player:PushEvent('respawnfromghost', { source = player })

			player.components.health.invincible = true
			local shield = SpawnPrefab("forcefieldfx")
			shield.Transform:SetScale(0.7,0.7,0.7)
			shield.entity:SetParent(player.entity)
			player:DoTaskInTime(2, function()
				player.components.er_leave:UpdateModular()
			end)
			player:DoTaskInTime(10, function()
				shield:kill_fx()
				player.components.health.invincible = false
			end)
		end
	end)
end

--整组烹饪
local cooking = require("cooking")
local Stewer = require "components/stewer"

local function dospoil(inst, self)
    self.task = nil
    self.targettime = nil
    self.spoiltime = nil

    if self.onspoil ~= nil then
        self.onspoil(inst)
    end
end

local function dostew(inst, self)
    self.task = nil
    self.targettime = nil
    self.spoiltime = nil

    if self.ondonecooking ~= nil then
        self.ondonecooking(inst)
    end

    if self.product == self.spoiledproduct then
        if self.onspoil ~= nil then
            self.onspoil(inst)
        end
    elseif self.product ~= nil then
        local prep_perishtime = cooking.GetRecipe(inst.prefab, self.product).perishtime or 0
        if prep_perishtime > 0 then
            local prod_spoil = self.product_spoilage or 1
            self.spoiltime = prep_perishtime * prod_spoil
            self.targettime = GetTime() + self.spoiltime
            self.task = self.inst:DoTaskInTime(self.spoiltime, dospoil, self)
        end
    end

    self.done = true
end

function Stewer:StartCooking()
    if self.targettime == nil and self.inst.components.container ~= nil then
        self.done = nil
        self.spoiltime = nil

        if self.onstartcooking ~= nil then
            self.onstartcooking(self.inst)
        end

        local ings = {}

        local num = {}
        for k, v in pairs(self.inst.components.container.slots) do
            table.insert(ings, v.prefab)
            table.insert(num, v.components.stackable and v.components.stackable:StackSize() or 1)
        end
        self.stack = math.min(unpack(num)) or 1

        local cooktime = 1
        self.product, cooktime = cooking.CalculateRecipe(self.inst.prefab, ings)
        local productperishtime = cooking.GetRecipe(self.inst.prefab, self.product).perishtime or 0

        if productperishtime > 0 then
            local spoilage_total = 0
            local spoilage_n = 0
            for k, v in pairs(self.inst.components.container.slots) do
                if v.components.perishable ~= nil then
                    spoilage_n = spoilage_n + 1
                    spoilage_total = spoilage_total + v.components.perishable:GetPercent()
                end
            end
            self.product_spoilage = 1
            if spoilage_total > 0 then
                self.product_spoilage = spoilage_total / spoilage_n
                self.product_spoilage = 1 - (1 - self.product_spoilage) * .5
            end
        else
            self.product_spoilage = nil
        end

        cooktime = math.floor(TUNING.BASE_COOK_TIME * cooktime * 1.5 * math.sqrt(self.stack) + 0.5)
        self.targettime = GetTime() + cooktime
        if self.task then
            self.task:Cancel()
            self.task = nil
        end
        self.task = self.inst:DoTaskInTime(cooktime, dostew, self)

        self.inst.components.container:Close()
        for k, v in pairs(self.inst.components.container.slots) do
            if v.components.stackable ~= nil then
                v.components.stackable:Get(self.stack or 1):Remove()
            else
                v:Remove()
            end
        end
        self.inst.components.container.canbeopened = false
    end
end

function Stewer:OnSave()
    local remainingtime = self.targettime ~= nil and self.targettime - GetTime() or 0
    return {
        done = self.done,
        product = self.product,
        product_spoilage = self.product_spoilage,
        spoiltime = self.spoiltime,
        remainingtime = remainingtime > 0 and remainingtime or nil,
        stack = self.stack or nil
    }
end

function Stewer:OnLoad(data)
    if data.product ~= nil then
        self.done = data.done or nil
        self.product = data.product
        self.product_spoilage = data.product_spoilage
        self.spoiltime = data.spoiltime
        self.stack = data.stack or nil
        if self.task then
            self.task:Cancel()
            self.task = nil
        end
        self.targettime = nil

        if data.remainingtime ~= nil then
            self.targettime = GetTime() + math.max(0, data.remainingtime)
            if self.done then
                self.task = self.inst:DoTaskInTime(data.remainingtime, dospoil, self)
                if self.oncontinuedone ~= nil then
                    self.oncontinuedone(self.inst)
                end
            else
                self.task = self.inst:DoTaskInTime(data.remainingtime, dostew, self)
                if self.oncontinuecooking ~= nil then
                    self.oncontinuecooking(self.inst)
                end
            end
        elseif self.product ~= self.spoiledproduct and data.product_spoilage ~= nil then
            self.targettime = GetTime()
            self.task = self.inst:DoTaskInTime(0, dostew, self)
            if self.oncontinuecooking ~= nil then
                self.oncontinuecooking(self.inst)
            end
        elseif self.oncontinuedone ~= nil then
            self.oncontinuedone(self.inst)
        end

        if self.inst.components.container ~= nil then
            self.inst.components.container.canbeopened = false
        end
    end
end

function Stewer:Harvest(harvester)
    if self.done then
        if self.onharvest ~= nil then
            self.onharvest(self.inst)
        end

        if self.product ~= nil then
            local recipe = cooking.GetRecipe(self.inst.prefab, self.product)
            for i = 1, recipe and recipe.stacksize or 1 do
                local loot = SpawnPrefab(self.product)
                if loot ~= nil then
                    local stacksize = self.stack or 1
                    if stacksize > 1 then
                        loot.components.stackable:SetStackSize(stacksize)
                    end
                    if self.spoiltime ~= nil and loot.components.perishable ~= nil then
                        local spoilpercent = self:GetTimeToSpoil() / self.spoiltime
                        loot.components.perishable:SetPercent(self.product_spoilage * spoilpercent)
                        loot.components.perishable:StartPerishing()
                    end
                    if harvester ~= nil and harvester.components.inventory ~= nil then
                        harvester.components.inventory:GiveItem(loot, nil, self.inst:GetPosition())
                    else
                        LaunchAt(loot, self.inst, nil, 1, 1)
                    end
                end
            end
            self.product = nil
        end
        if self.task then
            self.task:Cancel()
            self.task = nil
        end
        self.targettime = nil
        self.done = nil
        self.spoiltime = nil
        self.product_spoilage = nil

        if self.inst.components.container ~= nil then
            self.inst.components.container.canbeopened = true
        end

        return true
    end
end