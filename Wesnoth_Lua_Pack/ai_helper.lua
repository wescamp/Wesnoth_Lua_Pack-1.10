local ai_helper = {}

function ai_helper.my_moves()
	-- Produces a table with each (numerical) field of form:
	--   [1] = { dst = { x = 7, y = 16 },
	--           src = { x = 6, y = 16 } }

	local dstsrc = ai.get_dstsrc()

	local my_moves = {}
	for key,value in pairs(dstsrc) do
		--print("src: ",value[1].x,value[1].y,"    -- dst: ",key.x,key.y)
		table.insert( my_moves,
			{   src = { x = value[1].x , y = value[1].y },
				dst = { x = key.x , y = key.y }
			}
		)
	end

	return my_moves
end


function ai_helper.enemy_moves()
	-- Produces a table with each (numerical) field of form:
	--   [1] = { dst = { x = 7, y = 16 },
	--           src = { x = 6, y = 16 } }

	local dstsrc = ai.get_enemy_dstsrc()

	local enemy_moves = {}
	for key,value in pairs(dstsrc) do
		--print("src: ",value[1].x,value[1].y,"    -- dst: ",key.x,key.y)
		table.insert( enemy_moves,
			{   src = { x = value[1].x , y = value[1].y },
				dst = { x = key.x , y = key.y }
			}
		)
	end

	return enemy_moves
end

function ai_helper.filter(input, condition)
	-- equivalent of filter() function in Formula AI

	local filtered_table = {}

	for i,v in ipairs(input) do
		if condition(v) then
			--print(i, "true")
			table.insert(filtered_table, v)
		end
	end

	return filtered_table
end

function ai_helper.choose(input, value)
	-- equivalent of filter() function in Formula AI

	local max_value = -9e999
	local best_input = nil

	for i,v in ipairs(input) do
		if value(v) > max_value then
			max_value = value(v)
			best_input = v
		end
		--print(i, value(v), max_value)
	end

	return best_input, max_value
end

function ai_helper.next_hop(unit, x, y)
	-- Finds the next "hop" of 'unit' on its way to (x,y)
	-- Returns coordinates of the endpoint of the hop, and movement cost to get there
	local path, cost = wesnoth.find_path(unit, x, y)

	-- If unit cannot get there:
	if cost >= 42424242 then return nil, cost end

	-- If unit can get there in one move:
	if cost <= unit.moves then return {x, y}, cost end

	-- If it takes more than one move:
	local next_hop, nh_cost = {x,y}, 0
	for index, path_loc in ipairs(path) do
		local sub_path, sub_cost = wesnoth.find_path( unit, path_loc[1], path_loc[2])

		if sub_cost <= unit.moves
			then next_hop, nh_cost = path_loc, sub_cost
			else return next_hop, nh_cost
		end
	end
end

-- Get simulate_combat results for unit at 'src' attacking unit at 'target'
-- when on terrain as that at 'dst'
-- All three are arrays of form {x,y}
-- If 'weapon' is set (to number of attack), use that weapon, otherwise use best weapon
function ai_helper.simulate_combat_loc( src, dst, target, weapon)

	local att = wesnoth.get_unit( src[1], src[2])
	local def = wesnoth.get_unit( target[1], target[2])

	local att_dst = wesnoth.copy_unit(att)
	att_dst.x, att_dst.y = dst[1], dst[2]

	if weapon then
		return wesnoth.simulate_combat( att_dst, weapon, def)
	else
		return wesnoth.simulate_combat( att_dst, def)
	end
end

return ai_helper
