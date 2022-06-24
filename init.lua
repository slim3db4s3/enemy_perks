dofile_once("data/scripts/perks/perk_utilities.lua")


function get_perks()
	dofile_once("data/scripts/perks/perk_list.lua")

	local perks = ""
	for i,perk_data in ipairs( perk_list ) do
		local amount = ModSettingGet("enemy_perks.perk_" .. perk_data.id)

		local kind = type(amount)
		if kind == "boolean" then
			amount = amount and 1 or 0
		elseif kind == "string" then
			amount = amount == "" and 0 or tonumber(amount)
		elseif kind ~= "number" then
			amount = 0
		end

		for _ = 1, amount do
			print(perk_data.id)
			perks = perks .. i .. ","
		end
	end
	return perks
end


function OnModPostInit()
  local perks = get_perks()
  ModSettingSet("enemy_perks.perk_ids", perks)
end

function OnPlayerSpawned(player)
	if GlobalsGetValue("enemy_perks.new_game", "0") == "1" then return end
	GlobalsSetValue("enemy_perks.new_game", "1")
end

ModLuaFileAppend( "data/scripts/director_helpers.lua", "mods/enemy_perks/files/director_helpers_appends.lua")