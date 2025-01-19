local _G = GLOBAL

local function PickLootRandomItems(number, loot)
	local refinedloot = {}
	for i = 1, number do
		local num = math.random(#loot)
		table.insert(refinedloot, loot[num])
	end
	return refinedloot
end

function AddLootItems(srcLoot, loot, num)
	if srcLoot == nil then
		srcLoot = {}
	end
	if loot ~= nil then
		local numloot = num or #loot
		local rdLoot = loot
		if #loot > numloot then
			rdLoot = PickLootRandomItems(numloot, loot)
		end
		for k, itemtype in ipairs(rdLoot) do
			local itemToSpawn = itemtype.item or itemtype
			if type(itemToSpawn) == "table" then
				itemToSpawn = itemToSpawn[math.random(#itemToSpawn)]
			end
			local spawn = math.random() <= (itemtype.chance or 1)
			local count = itemtype.count or 1
			if spawn then
				for i = 1, count do
					table.insert(srcLoot, itemToSpawn)
				end
			end
		end
		return srcLoot
	end
end

local items = 
{
--	{	item = "armorruins", chance = 0.33		},
--	{	item = "ruinshat",chance = 0.33			},
--	{	item = {"ruins_bat"},	chance = 0.25	},
--	{	item = {"ruins_bat", "orangestaff", "yellowstaff"},chance = 0.25	},
	{	item = "thulecite",	count = math.random(7, 14),chance = 0.75,	},
--	{	item = "thulecite_pieces",count = math.random(7, 14),chance = 0.5,	},
--	{	item = "nightmarefuel",count = math.random(5, 10),chance = 0.75,	},
	{	item = {"redgem", "bluegem", "purplegem"},count = math.random(3, 6),chance = 0.66,	},
	{	item = {"yellowgem", "orangegem", "greengem"},count = math.random(3, 6),chance = 0.45,	},
--	{	item = "gears",count = math.random(3, 6),chance = 0.33,	},
--	{	item = "chesspiece_bishop_sketch",chance = 0.12,	},
--	{	item = "chesspiece_knight_sketch",chance = 0.09,	},
--	{	item = "chesspiece_rook_sketch",chance = 0.1,	},
}

function AddLootChestItems(srcLoot)
	return AddLootItems(srcLoot, items, 1)
end