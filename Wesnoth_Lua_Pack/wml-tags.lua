
local required_version = "1.9.7+svn"
local sufficient = wesnoth.compare_versions and wesnoth.compare_versions(required_version, "<=", wesnoth.game_config.version)
if not sufficient then
	error(string.format("The Wesnoth Lua Pack requires Battle for Wesnoth %s or greater!", required_version))
end

local helper = wesnoth.require "lua/helper.lua"
local wlp_utils = wesnoth.require "~add-ons/Wesnoth_Lua_Pack/wlp_utils.lua"

-- to make code shorter. Yes, it's global.
wml_actions = wesnoth.wml_actions

--! [animate_path]
--! Alarantalara
-- move an image or set of images along any on screen path
-- see animation.lua for complete details
--? Should the interpolation methods table returned be added to the set of globals?
wesnoth.dofile '~add-ons/Wesnoth_Lua_Pack/animation.lua'

-- we need this file to use GUI-based stuff. Elvish_Hunter
wesnoth.dofile '~add-ons/Wesnoth_Lua_Pack/gui-tags.lua'

--! [store_shroud]
--! melinath

-- Given side= and variable=, stores that side's shroud data in that variable
-- Example:
-- [store_shroud]
--     side=1
--     variable=shroud_data
-- [/store_shroud]

function wml_actions.store_shroud(cfg)
	local team_number = cfg.side or helper.wml_error("Missing required side= attribute in [store_shroud]")
	local variable = cfg.variable or helper.wml_error("Missing required variable= attribute in [store_shroud].")
	local side = wesnoth.get_side(team_number)
	local current_shroud = side.__cfg.shroud_data
	wesnoth.set_variable(variable, current_shroud)
end

--! [set_shroud]
--! melinath

-- Given shroud data, removes the shroud in the marked places on the map.
-- Example:
-- [set_shroud]
--     side=1
--     shroud_data=$shroud_data # stored with store_shroud, for example!
-- [/set_shroud]

function wml_actions.set_shroud(cfg)
	local team_number = cfg.side or helper.wml_error("Missing required side= attribute in [set_shroud]")
	local shroud_data = cfg.shroud_data or helper.wml_error("Missing required shroud_data= attribute in [set_shroud]")

	if shroud_data == nil then helper.wml_error("[set_shroud] was passed an empty shroud string")
	elseif string.sub(shroud_data,1,1) ~= "|" then helper.wml_error("[set_shroud] was passed an invalid shroud string")
	else
		-- yes, I prefer long variable names. I think that they make the code more understandable. E_H.
		local width, height, border = wesnoth.get_map_size()
		local shroud_x = ( 1 - border )

		-- my variation: to make code faster (hopefully), and avoid multiple callings of remove_shroud
		-- I append every location to a table, convert them as strings, and invoke remove_shroud
		-- only once, with these lists of locations. E_H.
		local rows, columns = {}, {}

		for row in string.gmatch ( shroud_data, "|(%d*)" ) do
			local shroud_y = ( 1 - border )
			for column in string.gmatch ( row, "%d" ) do
				if column == "1" then
					-- I tend to confuse them, so better specify: x are columns and y are rows. E_H.
					table.insert( rows, shroud_y ) -- appending them to the tables.
					table.insert( columns, shroud_x )
				end
				shroud_y = shroud_y + 1
			end
			shroud_x = shroud_x + 1
		end

		-- converting them to strings with separator
		local locs_x = table.concat( columns, "," )
		local locs_y = table.concat( rows, "," )

		if not wesnoth.get_side( team_number ).__cfg.shroud then
			wml_actions.modify_side { side = team_number, shroud = true } -- in case that shroud was removed by modify_side
		end

		wml_actions.place_shroud { side = team_number, x = string.format("%d-%d", 1 - border, height + border ), y = string.format("%d-%d", 1 - border, width + border ) }
		wml_actions.remove_shroud { side = team_number, x = locs_x, y = locs_y }
	end
end

--! [save_map],[load_map]
--! silene

--The [save_map] and [load_map] tags store and retrieve map data in a WML variable;
-- useful for dealing with dynamically modified yet persistent maps. They take a
-- variable=.
-- Example:
-- [save_map]
--     variable=saved_map[1].map
-- [/save_map]
-- [load_map]
--     variable=saved_map[1].map
-- [/load_map]

function wml_actions.save_map(cfg)
	local variable = cfg.variable or helper.wml_error "[save_map] missing required variable= attribute"
	local width, height, border = wesnoth.get_map_size()
	local t = {} -- not table, to avoid overriding the table library!

	for y = 1 - border, height + border do
		local row = {}

		for x = 1 - border, width + border do
			row[ x + border ] = wesnoth.get_terrain ( x, y )
		end

		t[ y + border ] = table.concat ( row, ',' )
	end

	local s = table.concat( t, '\n' ) -- not string, to avoid overriding the string library!
	wesnoth.set_variable ( variable, string.format ( "border_size=%d\nusage=map\n\n%s", border, s ) )
end

function wml_actions.load_map(cfg)
	local variable = cfg.variable or helper.wml_error "[load_map] missing required variable= attribute"
	wml_actions.replace_map { map = wesnoth.get_variable ( variable ), expand = true, shrink = true }
end

--! [narrate]
--! silene

-- shortcut for a [message] tag spoken by the narrator.

function wml_actions.narrate(cfg)
	local message = cfg.message
	local image = cfg.image or "wesnoth-icon.png"
	wml_actions.message { speaker = "narrator", message = message, image = image }
end

local function flash(red,green,blue)
	-- usage: call this function by specifying the maximum values for each color. Don't go above 100.
	wml_actions.color_adjust { red = (red * 0.67), green = (green * 0.67), blue = (blue * 0.67) }
	wml_actions.color_adjust { red = red, green = green, blue = blue }
	wml_actions.color_adjust { red = (red * 0.33), green = (green * 0.33), blue = (blue * 0.33) }
	wml_actions.color_adjust { red = 0, green = 0, blue = 0 }
end

function wml_actions.flash_color(cfg)
	local red = tonumber(cfg.red) or helper.wml_error("[flash_color] is missing required red= attribute")
	local green = tonumber(cfg.green) or helper.wml_error("[flash_color] is missing required green= attribute")
	local blue = tonumber(cfg.blue) or helper.wml_error("[flash_color] is missing required blue= attribute")

	flash( red, green, blue )
end

function wml_actions.flash_screen(cfg)
	local color = cfg.color or helper.wml_error("[flash_screen] is missing required color= attribute")
	if color == "white" then
		flash( 100, 100, 100 )
	elseif color == "red" then
		flash( 100, 0, 0 )
	elseif color == "green" then
		flash( 0, 100, 0 )
	elseif color == "blue" then
		flash( 0, 0, 100 )
	elseif color == "magenta" or color == "fuchsia" then
		flash( 100, 0, 100 )
	elseif color == "yellow" then
		flash( 100, 100, 0 )
	elseif color == "cyan" or color == "aqua" then
		flash( 0, 100, 100 )
	elseif color == "purple" then
		flash( 50, 0, 50 )
	elseif color == "orange" then
		flash( 100, 65, 0 )
	elseif color == "black" then
		flash( -100, -100, -100 )
	else
		helper.wml_error("Unsupported color in [flash_screen]")
	end
end

function wml_actions.nearest_hex(cfg)
	local starting_x = tonumber(cfg.starting_x) or helper.wml_error("Missing required starting_x in [nearest_hex]")
	local starting_y = tonumber(cfg.starting_y) or helper.wml_error("Missing required starting_y in [nearest_hex]")
	local filter = (helper.get_child(cfg, "filter_location")) or helper.wml_error("Missing required [filter_location] in [nearest_hex]")
	local variable = cfg.variable or "nearest_hex" -- default

	local current_distance = math.huge -- feed it the biggest value possible
	local nearest_hex_found

	for index,location in ipairs(wesnoth.get_locations(filter)) do
		local distance = helper.distance_between( starting_x, starting_y, location[1], location[2] )
		if distance < current_distance then
			current_distance = distance
			nearest_hex_found = location
		end
	end

	if nearest_hex_found then
		wesnoth.set_variable( variable, { x = nearest_hex_found[1], y = nearest_hex_found[2], terrain = wesnoth.get_terrain( nearest_hex_found[1], nearest_hex_found[2] ) })
	else wesnoth.message( "WML", "No suitable location found by [nearest_hex]" )
	end
end

function wml_actions.nearest_unit(cfg)
	local starting_x = tonumber(cfg.starting_x) or helper.wml_error("Missing required starting_x in [nearest_unit]")
	local starting_y = tonumber(cfg.starting_y) or helper.wml_error("Missing required starting_y in [nearest_unit]")
	local filter = (helper.get_child(cfg, "filter")) or helper.wml_error("Missing required [filter] in [nearest_unit]")
	local variable = cfg.variable or "nearest_unit" -- default

	local current_distance = math.huge -- feed it the biggest value possible
	local nearest_unit_found

	for index,unit in ipairs(wesnoth.get_units(filter)) do
		local distance = helper.distance_between( starting_x, starting_y, unit.x, unit.y )
		if distance < current_distance then
			current_distance = distance
			nearest_unit_found = unit
		end
	end

	if nearest_unit_found then
		wml_actions.store_unit( { variable = variable, { "filter", { id = nearest_unit_found.id } } } )
	else wesnoth.message( "WML", "No suitable unit found by [nearest_unit]" )
	end
end

-- to store unit defense
function wesnoth.wml_actions.get_unit_defense(cfg)
	local filter = wesnoth.get_units(cfg)
	local variable = cfg.variable or "defense"

	for index, unit in ipairs(filter) do
		local terrain = wesnoth.get_terrain ( unit.x, unit.y )
		-- it is WML defense: the lower, the better. Converted to normal defense with 100 -
		local defense = 100 - wesnoth.unit_defense ( unit, terrain )
		wesnoth.set_variable ( string.format ( "%s[%d]", variable, index - 1 ), { id = unit.id, x = unit.x, y = unit.y, terrain = terrain, defense = defense } )
	end
end

local _ = wesnoth.textdomain "wesnoth"
-- #textdomain wesnoth

function wml_actions.slow(cfg)
	for index, unit in ipairs(wesnoth.get_units(cfg)) do
		if unit.valid and not unit.status.slowed then
			unit.status.slowed = true
			if unit.__cfg.gender == "female" then
				wesnoth.float_label( unit.x, unit.y, string.format("<span color='red'>%s</span>", tostring( _"female^slowed" ) ) )
			else
				wesnoth.float_label( unit.x, unit.y, string.format("<span color='red'>%s</span>", tostring( _"slowed" ) ) )
			end
		end
	end
end

function wml_actions.poison(cfg)
	for index, unit in ipairs(wesnoth.get_units(cfg)) do
		if unit.valid and not unit.status.poisoned then
			unit.status.poisoned = true
			if unit.__cfg.gender == "female" then
				wesnoth.float_label(unit.x, unit.y, string.format("<span color='red'>%s</span>", tostring( _"female^poisoned" ) ) )
			else
				wesnoth.float_label(unit.x, unit.y, string.format("<span color='red'>%s</span>", tostring( _"poisoned" ) ) )
			end
		end
	end
end

function wml_actions.unpoison(cfg) -- removes poison from all units matching the filter.
	for index, unit in ipairs(wesnoth.get_units(cfg)) do
		if unit.valid then unit.status.poisoned = nil end
	end
end

function wml_actions.unslow(cfg) -- removes slow from all units matching the filter.
	for index, unit in ipairs(wesnoth.get_units(cfg)) do
		if unit.valid then unit.status.slowed = nil end
	end
end

local function fade( value, delay ) -- equivalent to FADE_STEP WML macro
	wml_actions.color_adjust { red = value, green = value, blue = value }
	wesnoth.delay( delay )
	wml_actions.redraw {}
end

function wml_actions.fade_to_black(cfg) -- replaces FADE_TO_BLACK macro
	for value = -32, -224, -32 do
		fade( value, 5 )
	end
end

function wml_actions.fade_to_black_hold(cfg) -- replaces FADE_TO_BLACK_HOLD macro
	local delay = tonumber( cfg.delay ) or helper.wml_error( "Missing delay= in [fade_to_black_hold]" )

	for value = -32, -192, -32 do
		fade( value, 5 )
	end

	fade( -224, delay )
end

function wml_actions.fade_in(cfg) -- replaces FADE_IN macro
	for value = -224, 0, 32 do
		fade( value, 5 )
	end
end

function wml_actions.fade_to_white(cfg) -- similar to a theoretical FADE_TO_WHITE macro
	for value = 32, 224, 32 do
		fade( value, 5 )
	end
end

function wml_actions.fade_to_white_hold(cfg) -- like a FADE_TO_WHITE_HOLD macro
	local delay = tonumber( cfg.delay ) or helper.wml_error( "Missing delay= in [fade_to_black_hold]" )

	for value = 32, 192, 32 do
		fade( value, 5 )
	end

	fade( 224, delay )
end

function wml_actions.fade_in_from_white(cfg) -- use after [fade_to_white] or [fade_to_white_hold]
	for value = 224, 0, -32 do
		fade( value, 5 )
	end
end

function wml_actions.scatter_units(cfg) -- replacement for SCATTER_UNITS macro
	local locations = wesnoth.get_locations( helper.get_child( cfg, "filter_location" ) ) or helper.wml_error( "Missing required [filter_location] in [scatter_units]" )
	local unit_string = cfg.unit_types or helper.wml_error( "Missing required unit_types= in [scatter_units]" )
	local units = tonumber( cfg.units ) or helper.wml_error( "Missing or wrong required units= in [scatter_units]" )
	local scatter_radius =  tonumber( cfg.scatter_radius ) -- not mandatory, if nil cycle will be jumped
	local unit_table = helper.parsed( helper.get_child( cfg, "wml" ) ) or {} -- initialize as empty table, just in need

	local unit_types = {} -- create a table, then append each value after splitting with string.gmatch.

	for value in string.gmatch( unit_string, "[^%s,][^,]*" ) do
		table.insert( unit_types, value )
	end

	if #locations <=0 then return -- if no locations, end
	else
		repeat -- repeat cycle is executed at least once
			local rand_locs = "1.." .. #locations -- concatenation for use by WML rand
			local rand_units = "1.." .. #unit_types
			local index = helper.rand( rand_locs ) -- use helper.rand, to avoid OOS errors
			local index2 = helper.rand( rand_units )
			local where_to_place = locations[index]

			local unit_to_put = unit_table
			unit_to_put.type = unit_types[index2]

			local free_x, free_y = wesnoth.find_vacant_tile( where_to_place[1], where_to_place[2], unit_to_put)
			-- to avoid placing units in strange terrains, or overwriting, in case that the WML coder placed a wrong filter;
			-- in such case, respect of scatter_radius is not guaranteed, exactly like in SCATTER_UNITS

			unit_to_put.x, unit_to_put.y = free_x, free_y
			wesnoth.put_unit( unit_to_put )
			table.remove( locations, index ) -- to remove such location from the available list, because it's already busy, and avoid overwriting already placed units
			if scatter_radius then -- loop for scatter_radius; will remove every location within the radius
				-- apparently, a reversed ipairs like below is the best way to check every location
				-- and remove those that are too close
				-- using standard ipairs jumps some locations
				for index = #locations, 1, -1 do --lenght of locations, until 1, step -1
					local distance = helper.distance_between( where_to_place[1], where_to_place[2], locations[index][1], locations[index][2] )

					if distance < scatter_radius then
						table.remove( locations, index )
					end
				end
			end

			units = units - 1 -- counter variable
		until units <= 0 or #locations <= 0
	end
end

--[[ [find_path]
A WML interface to the pathfinder, as described by Sapient in FutureWML.
[traveler]: SUF, only 1st matching unit
[destination]: SLF, only 1st matching hex
variable = 'path' as default
allow_multiple_turns = yes/no, no as default
ignore_visibility = yes/no, yes as default
ignore_teleport = yes/no, no as default
ignore_units = yes/no, no as default ]]

function wml_actions.find_path(cfg)
	local filter_unit = (helper.get_child(cfg, "traveler")) or helper.wml_error("[find_path] missing required [traveler] tag")
	local filter_location = (helper.get_child(cfg, "destination")) or helper.wml_error("[find_path] missing required [destination] tag")
	local variable = cfg.variable or "path"
	local ignore_units = cfg.ignore_units
	local ignore_teleport = cfg.ignore_teleport
	local allow_multiple_turns = cfg.allow_multiple_turns
	if cfg.ignore_visibility ~= false then local viewing_side = 0 end --default yes

	local unit = wesnoth.get_units(filter_unit)[1] -- only the first unit matching
	local locations = wesnoth.get_locations(filter_location) -- only the location with the lowest distance and lowest movement cost will match. If there will still be more than 1, only the 1st maching one.
	if not allow_multiple_turns then local max_cost = unit.moves end --to avoid wrong calculation on already moved units
	local current_distance, current_cost = math.huge, math.huge
	local current_location = {}

	local width,heigth,border = wesnoth.get_map_size() -- data for test below

	for index, location in ipairs(locations) do
		-- we test if location passed to pathfinder is invalid (border); if is, do nothing, do not return and continue the cycle
		if location[1] == 0 or location[1] == ( width + 1 ) or location[2] == 0 or location[2] == ( heigth + 1 ) then
		else
			local distance = helper.distance_between ( unit.x, unit.y, location[1], location[2] )
			-- if we pass an unreachable locations an high value will be returned
			local path, cost = wesnoth.find_path( unit, location[1], location[2], { max_cost = max_cost, ignore_units = ignore_units, ignore_teleport = ignore_teleport, viewing_side = viewing_side } )

			if ( distance < current_distance and cost <= current_cost ) or ( cost < current_cost and distance <= current_distance ) then -- to avoid changing the hex with one with less distance and more cost, or vice versa
				current_distance = distance
				current_cost = cost
				current_location = location
			end
		end
	end

	if #current_location == 0 then wesnoth.message( "WML", "No matching location found by [find_path]" ) else
		local path, cost = wesnoth.find_path( unit, current_location[1], current_location[2], { max_cost = max_cost, ignore_units = ignore_units, ignore_teleport = ignore_teleport, viewing_side = viewing_side } )
		local turns

		if cost == 0 then -- if location is the same, of course it doesn't cost any MP
			turns = 0
		else
			turns = math.ceil( ( ( cost - unit.moves ) / unit.max_moves ) + 1 )
		end

		if cost >= 42424242 then -- it's the high value returned for unwalkable or busy terrains
			wesnoth.set_variable ( string.format("%s", variable), { length = 0 } ) -- set only length, nil all other values
		return end

		if not allow_multiple_turns and turns > 1 then -- location cannot be reached in one turn
			wesnoth.set_variable ( string.format("%s", variable), { length = 0 } )
		return end -- skip the cycles below

		wesnoth.set_variable ( string.format( "%s", variable ), { length = current_distance, from_x = unit.x, from_y = unit.y, to_x = current_location[1], to_y = current_location[2], movement_cost = cost, required_turns = turns } )

		for index, path_loc in ipairs(path) do
			local sub_path, sub_cost = wesnoth.find_path( unit, path_loc[1], path_loc[2], { max_cost = max_cost, ignore_units = ignore_units, ignore_teleport = ignore_teleport, viewing_side = viewing_side } )
			local sub_turns

			if sub_cost == 0 then
				sub_turns = 0
			else
				sub_turns = math.ceil( ( ( sub_cost - unit.moves ) / unit.max_moves ) + 1 )
			end

			wesnoth.set_variable ( string.format( "%s.step[%d]", variable, index - 1 ), { x = path_loc[1], y = path_loc[2], terrain = wesnoth.get_terrain( path_loc[1], path_loc[2] ), movement_cost = sub_cost, required_turns = sub_turns } ) -- this structure takes less space in the inspection window
		end
	end
end

-- math functions by Espreon
--[[ examples of usage:
[set_variable]
	name=test_math_1
	value=-12
[/set_variable]
[absolute_value]
	variable=test_math_1
	result_variable=test_math_1_abs
[absolute_value]
	variable=test_math_1
[/absolute_value]
[get_numerical_minimum]
	first_value=12
	other_value=24
	result_variable=test_math_2
[/get_numerical_minimum]
[get_numerical_maximum]
	first_value=12
	other_value=24
	result_variable=test_math_3
[/get_numerical_maximum]
[get_percentage]
	value=750
	percentage=2.5
	variable=test_math_4
[/get_percentage]
[get_ratio_as_percentage]
	numerator=22
	denominator=7
	variable=test_math_5
[/get_ratio_as_percentage] ]]
function wml_actions.absolute_value(cfg)
	local variable = cfg.variable or
		helper.wml_error "[absolute_value] missing required variable= attribute"

	local variable_value = wesnoth.get_variable(variable)
	local result = math.abs(variable_value)

	if cfg.result_variable == nil then
		wesnoth.set_variable(variable, result)
	else
		wesnoth.set_variable(cfg.result_variable, result)
	end
end

function wml_actions.get_numerical_minimum(cfg)
	local first_value = cfg.first_value or
		helper.wml_error "[get_numerical_minimum] missing required first_value= attribute"
	local other_value = cfg.other_value or
		helper.wml_error "[get_numerical_minimum] missing required other_value= attribute"
	local result_variable = cfg.result_variable or
		helper.wml_error "[get_numerical_minimum] missing required result_variable= attribute"

	local result

	if other_value < first_value then
		result = other_value
	else
		result = first_value
	end

	wesnoth.set_variable(result_variable, result)
end

function wml_actions.get_numerical_maximum(cfg)
	local first_value = cfg.first_value or
		helper.wml_error "[get_numerical_maximum] missing required first_value= attribute"
	local other_value = cfg.other_value or
		helper.wml_error "[get_numerical_maximum] missing required other_value= attribute"
	local result_variable = cfg.result_variable or
		helper.wml_error "[get_numerical_maximum] missing required result_variable= attribute"

	local result

	if other_value > first_value then
		result = other_value
	else
		result = first_value
	end

	wesnoth.set_variable(result_variable, result)
end

function wml_actions.get_percentage(cfg)
	local value = cfg.value or
		helper.wml_error "[get_percentage] missing required value= attribute"
	local percentage = cfg.percentage or
		helper.wml_error "[get_percentage] missing required percentage= attribute"
	local variable = cfg.variable or
		helper.wml_error "[get_percentage] missing required variable= attribute"

	local result = (value * percentage) / 100
	wesnoth.set_variable(variable, result)
end

function wml_actions.get_ratio_as_percentage(cfg)
	local numerator = cfg.numerator or
		helper.wml_error "[get_ratio_as_percentage] missing required numerator= attribute"
	local denominator = cfg.denominator or
		helper.wml_error "[get_ratio_as_percentage] missing required denominator= attribute"
	local variable = cfg.variable or
		helper.wml_error "[get_ratio_as_percentage] missing required variable= attribute"

	local result = (100 * numerator) / denominator
	wesnoth.set_variable(variable, result)
end

-- [unknown_message], by Espreon, with modifications by Elvish_Hunter
--[[ usage:
[unknown_message]
	message=_"Hi"
	color=2
	caption = _ "WesnothAI"
	right = yes/no
[/unknown_message] ]]
function wml_actions.unknown_message(cfg)
	local message = cfg.message or
		helper.wml_error "[unknown_message] missing required message= attribute"
	local image

	if type(cfg.color) == "string" then
		image = string.format("units/unknown-unit.png~RC(magenta>%s)", cfg.color)
	elseif type(cfg.color) == "number" then
		image = string.format("units/unknown-unit.png~TC(%d,magenta)", cfg.color)
	else -- if cfg.color is nil, table, or whatever else
		image = "units/unknown-unit.png"
	end

	if cfg.right then
		image = image .. "~RIGHT()"
	end

	wml_actions.message { speaker="narrator", message=cfg.message, caption=cfg.caption, image=image }
end

-- [get_movement_type], by silene
--[[ Usage:
[get_movement_type]
  # a Standard Unit Filter
  x,y=$x1,$y1
  # a variable name or "movement_type" if missing
  variable=variable_name
[/get_movement_type]
Stores the unit's movement type in the given variable. ]]
function wml_actions.get_movement_type(cfg)
	local unit = wesnoth.get_units(cfg)[1] or helper.wml_error "[get_movement_type] filter didn't match any unit"
	local unit_type = wesnoth.get_unit_type( unit.__cfg.type )
	local variable = cfg.variable or "movement_type"
	wesnoth.set_variable( variable, unit_type.__cfg.movement_type )
end

