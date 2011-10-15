local helper = wesnoth.require "lua/helper.lua"
local wlp_utils = wesnoth.require "~add-ons/Wesnoth_Lua_Pack/wlp_utils.lua"

-- to make code shorter. Yes, it's global.
wml_actions = wesnoth.wml_actions

-- metatable for GUI tags
local T = helper.set_wml_tag_metatable {}

-- support for translatable strings, custom textdomain
local _ = wesnoth.textdomain "wesnoth-Wesnoth_Lua_Pack"
-- #textdomain wesnoth-Wesnoth_Lua_Pack

-- [show_quick_debug]
-- This tag is meant for use inside a [set_menu_item], because it gets the unit at x1,y1
-- It allows modifying all those unit parameters that don't require accessing the .__cfg field.
-- Shows also read only parameters.
-- Usage:
-- [set_menu_item]
--	id=quick_debug
--	description=Quick Debug
--	[command]
--		[show_quick_debug]
--		[/show_quick_debug]
--	[/command]
-- [/set_menu_item]

function wml_actions.show_quick_debug ( cfg )
	-- acquire unit with get_units, if unit.valid show dialog
	local lua_dialog_unit = wesnoth.get_unit ( wesnoth.current.event_context.x1, wesnoth.current.event_context.y1 ) -- clearly, at x1,y1 there could be only one unit, hence get_unit
	local max_attacks = 10 -- make it possible to increase over unit.max_attacks; no idea what would be a sensible value
	if lua_dialog_unit and lua_dialog_unit.valid then -- to avoid indexing a nil value
		--creating dialog here
		-- read only labels
		local read_only_panel = T.grid { T.row { T.column { horizontal_alignment = "left",
								    border = "all",
								    border_size = 5,
								    T.label { label = _"X" } },
							 T.column { horizontal_alignment = "left",
								    border = "all",
								    border_size = 5,
								    T.label { id = "unit_x" } } }, --unit.x
						 T.row { T.column { horizontal_alignment = "left",
								    border = "all",
								    border_size = 5,
								    T.label { label = _"Y" } },
							 T.column { horizontal_alignment = "left",
								    border = "all",
								    border_size = 5,
								    T.label { id = "unit_y" } } }, --unit.y
						 T.row { T.column { horizontal_alignment = "left",
								    border = "all",
								    border_size = 5,
								    T.label { label = _"ID" } },
							 T.column { horizontal_alignment = "left",
								    border = "all",
								    border_size = 5,
								    T.label { id = "unit_id" } } }, --unit.id
						 T.row { T.column { horizontal_alignment = "left",
								    border = "all",
								    border_size = 5,
								    T.label { label = _"Valid" } },
							 T.column { horizontal_alignment = "left",
								    border = "all",
								    border_size = 5,
								    T.label { id = "unit_valid" } } }, --unit.valid
						 T.row { T.column { horizontal_alignment = "left",
								    border = "all",
								    border_size = 5,
								    T.label { label = _"Type" } },
							 T.column { horizontal_alignment = "left",
								    border = "all",
								    border_size = 5,
								    T.label { id = "unit_type" } } }, --unit.type
						 T.row { T.column { horizontal_alignment = "left",
								    border = "all",
								    border_size = 5,
								    T.label { label = _"Name" } },
							 T.column { horizontal_alignment = "left",
								    border = "all",
								    border_size = 5,
								    T.label { id = "unit_name" } } }, --unit.name
						 T.row { T.column { horizontal_alignment = "left",
								    border = "all",
								    border_size = 5,
								    T.label { label = _"Can recruit" } },
							 T.column { horizontal_alignment = "left",
								    border = "all",
								    border_size = 5,
								    T.label { id = "unit_canrecruit" } } }, --unit.canrecruit
						}

		local status_checkbuttons = T.grid { T.row { T.column { horizontal_alignment = "left",
									border = "all",
									border_size = 5,
									T.toggle_button { label = _"Poisoned", id = "poisoned_checkbutton" } },
							     T.column { horizontal_alignment = "left",
									border = "all",
									border_size = 5,
									T.toggle_button { label = _"Slowed", id = "slowed_checkbutton" } },
							     T.column { horizontal_alignment = "left",
									border = "all",
									border_size = 5,
									T.toggle_button { label = _"Petrified", id = "petrified_checkbutton" } },
							     T.column { horizontal_alignment = "left",
									border = "all",
									border_size = 5,
									T.spacer { } } },
						     T.row { T.column { horizontal_alignment = "left",
									border = "all",
									border_size = 5,
									T.toggle_button { label = _"Uncovered", id = "uncovered_checkbutton" } },
							     T.column { horizontal_alignment = "left",
									border = "all",
									border_size = 5,
									T.toggle_button { label = _"Guardian", id = "guardian_checkbutton" } },
							     T.column { horizontal_alignment = "left",
									border = "all",
									border_size = 5,
									T.toggle_button { label = _"Unhealable", id = "unhealable_checkbutton" } },
							     T.column { horizontal_alignment = "left",
									border = "all",
									border_size = 5,
									T.toggle_button { label = _"Stunned", id = "stunned_checkbutton" } }
						    } }


		local facing_radiobutton = T.horizontal_listbox { id = "facing_listbox",
								  T.list_definition { T.row { T.column { T.toggle_button { id = "facing_radiobutton" } } } },
													 T.list_data {
															T.row { horizontal_alignment = "left",
															       border = "all",
															       border_size = 5,
															       T.column { label = _"nw" } },
															T.row { horizontal_alignment = "left",
															       border = "all",
															       border_size = 5,
															       T.column { label = _"ne" } },
															T.row { horizontal_alignment = "left",
															       border = "all",
															       border_size = 5,
															       T.column { label = _"n" } },
															T.row { horizontal_alignment = "left",
															       border = "all",
															       border_size = 5,
															       T.column { label = _"sw" } },
															T.row { horizontal_alignment = "left",
															       border = "all",
															       border_size = 5,
															       T.column { label = _"se" } },
															T.row { horizontal_alignment = "left",
															       border = "all",
															       border_size = 5,
															       T.column { label = _"s" } }
								} }


		local misc_checkbuttons = T.grid { T.row { T.column { horizontal_alignment = "left",
								      border = "all",
								      border_size = 5,
								      T.toggle_button { label = _"Resting", id = "resting_checkbutton" } }, --unit.resting
							   T.column { horizontal_alignment = "left",
								      border = "all",
								      border_size = 5,
								      T.toggle_button { label = _"Hidden", id = "hidden_checkbutton" } } },--unit.hidden
						 }

		-- buttonbox
		local buttonbox = T.grid { T.row { T.column { T.button { label = _"OK", return_value = 1 } },
						   T.column { T.spacer { width = 10 } },
						   T.column { T.button { label = _"Cancel", return_value = 2 } }
					 } }

		-- widgets for modifying unit
		local modify_panel = T.grid { -- side slider
						T.row { T.column { horizontal_alignment = "right",
								 border = "all",
								 border_size = 5,
								 T.label { label = _"Side" } },
							T.column { vertical_grow = true,
								 horizontal_grow = true,
								 border = "all",
								 border_size = 5,
								 T.slider { minimum_value = 1,
									    maximum_value = math.max( 2, #wesnoth.sides ), -- to avoid crash if there is only one side
									    step_size = 1,
									    id = "unit_side_slider" } } },--unit.side
						-- hitpoints slider
						T.row { T.column { horizontal_alignment = "right",
								 border = "all",
								 border_size = 5,
								 T.label { label = _"Hitpoints" } },
							T.column { vertical_grow = true,
								 horizontal_grow = true,
								 border = "all",
								 border_size = 5,
								 T.slider { minimum_value = math.min(0, lua_dialog_unit.hitpoints),
									    maximum_value = math.max(lua_dialog_unit.max_hitpoints, lua_dialog_unit.hitpoints),
									    minimum_value_label = _"Kill unit",
									    maximum_value_label = _"Full health",
									    step_size = 1,
									    id = "unit_hitpoints_slider" } } },--unit.hitpoints
						-- experience slider
						T.row { T.column { horizontal_alignment = "right",
								 border = "all",
								 border_size = 5,
								 T.label { label = _"Experience" } },
							T.column { vertical_grow = true,
								 horizontal_grow = true,
								 border = "all",
								 border_size = 5,
								 T.slider { minimum_value = math.min(0, lua_dialog_unit.experience),
									    maximum_value = math.max(lua_dialog_unit.max_experience, lua_dialog_unit.experience),
									    maximum_value_label = _"Level up",
									    step_size = 1,
									    id = "unit_experience_slider" } } },--unit.experience
						-- moves slider
						T.row { T.column { horizontal_alignment = "right",
								 border = "all",
								 border_size = 5,
								 T.label { label = _"Moves" } },
							T.column { vertical_grow = true,
								 horizontal_grow = true,
								 border = "all",
								 border_size = 5,
								 T.slider { minimum_value = 0,
									    -- to avoid crashing if max_moves == 0
									    maximum_value = math.max(10, lua_dialog_unit.max_moves, lua_dialog_unit.moves),
									    step_size = 1,
									    id = "unit_moves_slider" } } },--unit.moves
						-- attacks slider
						T.row { T.column { horizontal_alignment = "right",
								 border = "all",
								 border_size = 5,
								 T.label { label = _"Attacks left" } },
							T.column { vertical_grow = true,
								 horizontal_grow = true,
								 border = "all",
								 border_size = 5,
								 T.slider { minimum_value = 0,
									    -- to avoid crashing if unit has max_attacks == 0
									    maximum_value = math.max(1, max_attacks, lua_dialog_unit.attacks_left),
									    step_size = 1,
									    id = "unit_attacks_slider" } } },--unit.attacks_left
						-- extra recruit
						T.row { T.column { horizontal_alignment = "right",
								  border = "all",
								  border_size = 5,
								  T.label { label = _"Extra recruit" } },
							T.column { vertical_grow = true,
								  horizontal_grow = true,
								  border = "all",
								  border_size = 5,
								  T.text_box { id = "textbox_extra_recruit", history = "other_recruits" } } },--unit.extra_recruit
						-- advances to
						T.row { T.column { horizontal_alignment = "right",
								  border = "all",
								  border_size = 5,
								  T.label { label = _"Advances to" } },
							T.column { vertical_grow = true,
								  horizontal_grow = true,
								  border = "all",
								  border_size = 5,
								  T.text_box { id = "textbox_advances_to", history = "other_advancements" } } },--unit.advances_to
						-- role
						T.row { T.column { horizontal_alignment = "right",
								 border = "all",
								 border_size = 5,
								 T.label { label = _"Role" } },
							T.column { vertical_grow = true,
								 horizontal_grow = true,
								 border = "all",
								 border_size = 5,
								 T.text_box { id = "textbox_role", history = "other_roles" } } },--unit.role
						-- statuses
						T.row { T.column { horizontal_alignment = "right",
								 border = "all",
								 border_size = 5,
								 T.label { label = _"Status" } },
							T.column { horizontal_alignment = "left",
								 status_checkbuttons } },
						-- facing
						T.row { T.column { horizontal_alignment = "right",
								 border = "all",
								 border_size = 5,
								 T.label { label = _"Facing" } },
							T.column { horizontal_alignment = "left",
								 border = "all",
								 border_size = 5,
								 facing_radiobutton } },
						-- misc
						T.row { T.column { horizontal_alignment = "right",
								  border = "all",
								  border_size = 5,
								  T.label { label = _"Misc" } },
							T.column { horizontal_alignment = "left",
								  misc_checkbuttons } },
						}

		local debug_dialog = { T.helptip { id="tooltip_large" }, -- mandatory field
			 T.tooltip { id="tooltip_large" }, -- mandatory field
			 T.grid { -- Title
				 T.row { T.column { horizontal_alignment = "left",
						    grow_factor = 1, -- this one makes the title bigger and golden
						    border = "all",
						    border_size = 5,
						    T.label { definition = "title", label = _"Quick Debug Menu" } } },
				 -- Subtitile
				 T.row { T.column { horizontal_alignment = "left",
						    border = "all",
						    border_size = 5,
						    T.label { label = _"Set the desired parameters, then press OK to confirm or Cancel to exit" } } },
				 -- non-modifiable proxies, melinath's layout
				 T.row { T.column { T.grid {
							     T.row { T.column { vertical_alignment = "top",
										T.grid { T.row { T.column { vertical_alignment = "center",
													    horizontal_alignment = "center",
													    border = "all",
													    border_size = 5,
													    T.image { id = "unit_image" } } }, -- unit sprite
											 T.row { T.column { read_only_panel } }
										} }, -- terminator for read-only proxies
								     -- modification part
								     T.column { modify_panel } } } } }, -- terminator for grid
				 -- button box
				 T.row { T.column { buttonbox } }
				} }

		local temp_table = { } -- to store values before checking if user allowed modifying

		local function preshow()
			-- here set all widget starting values
			-- set read_only labels
			wesnoth.set_dialog_value ( lua_dialog_unit.x, "unit_x" )
			wesnoth.set_dialog_value ( lua_dialog_unit.y, "unit_y" )
			wesnoth.set_dialog_value ( lua_dialog_unit.id, "unit_id" )
			wesnoth.set_dialog_value ( lua_dialog_unit.valid, "unit_valid" )
			wesnoth.set_dialog_value ( lua_dialog_unit.type, "unit_type" )
			wesnoth.set_dialog_value ( lua_dialog_unit.name, "unit_name" )
			wesnoth.set_dialog_value ( lua_dialog_unit.canrecruit, "unit_canrecruit" )
			wesnoth.set_dialog_value ( string.format("%s~TC(%d,magenta)", lua_dialog_unit.__cfg.image or "", lua_dialog_unit.side), "unit_image" )
			-- set sliders
			wesnoth.set_dialog_value ( lua_dialog_unit.side, "unit_side_slider" )
			wesnoth.set_dialog_value ( lua_dialog_unit.hitpoints, "unit_hitpoints_slider" )
			wesnoth.set_dialog_value ( lua_dialog_unit.experience, "unit_experience_slider" )
			wesnoth.set_dialog_value ( lua_dialog_unit.moves, "unit_moves_slider" )
			wesnoth.set_dialog_value ( lua_dialog_unit.attacks_left, "unit_attacks_slider" )
			-- set textboxes
			wesnoth.set_dialog_value ( table.concat( lua_dialog_unit.extra_recruit, "," ), "textbox_extra_recruit" )
			wesnoth.set_dialog_value ( table.concat( lua_dialog_unit.advances_to, "," ), "textbox_advances_to" )
			wesnoth.set_dialog_value ( lua_dialog_unit.role, "textbox_role" )
			-- set checkbuttons
			wesnoth.set_dialog_value ( lua_dialog_unit.status.poisoned, "poisoned_checkbutton" )
			wesnoth.set_dialog_value ( lua_dialog_unit.status.slowed, "slowed_checkbutton" )
			wesnoth.set_dialog_value ( lua_dialog_unit.status.petrified, "petrified_checkbutton" )
			wesnoth.set_dialog_value ( lua_dialog_unit.status.uncovered, "uncovered_checkbutton" )
			wesnoth.set_dialog_value ( lua_dialog_unit.status.guardian, "guardian_checkbutton" )
			wesnoth.set_dialog_value ( lua_dialog_unit.status.unhealable, "unhealable_checkbutton" )
			wesnoth.set_dialog_value ( lua_dialog_unit.status.stunned, "stunned_checkbutton" )
			-- set radiobutton for facing
			local temp_facing
			if lua_dialog_unit.facing == "nw" then temp_facing = 1
			elseif lua_dialog_unit.facing == "ne" then temp_facing = 2
			elseif lua_dialog_unit.facing == "n" then temp_facing = 3
			elseif lua_dialog_unit.facing == "sw" then temp_facing = 4
			elseif lua_dialog_unit.facing == "se" then temp_facing = 5
			elseif lua_dialog_unit.facing == "s" then temp_facing = 6
			end
			wesnoth.set_dialog_value ( temp_facing, "facing_listbox" )
			-- other checkbuttons
			wesnoth.set_dialog_value ( lua_dialog_unit.resting, "resting_checkbutton" )
			wesnoth.set_dialog_value ( lua_dialog_unit.hidden, "hidden_checkbutton" )
		end

		local function sync()
			local temp_table = { } -- to store values before checking if user allowed modifying

			local function postshow()
				-- here get all the widget values in variables; store them in temp variables
				-- sliders
				temp_table.side = wesnoth.get_dialog_value ( "unit_side_slider" )
				temp_table.hitpoints = wesnoth.get_dialog_value ( "unit_hitpoints_slider" )
				temp_table.experience = wesnoth.get_dialog_value ( "unit_experience_slider" )
				temp_table.moves = wesnoth.get_dialog_value ( "unit_moves_slider" )
				temp_table.attacks_left = wesnoth.get_dialog_value ( "unit_attacks_slider" )
				-- text boxes
				temp_table.advances_to = wesnoth.get_dialog_value "textbox_advances_to"
				temp_table.extra_recruit = wesnoth.get_dialog_value "textbox_extra_recruit"
				temp_table.role = wesnoth.get_dialog_value "textbox_role"
				-- checkbuttons
				temp_table.poisoned = wesnoth.get_dialog_value "poisoned_checkbutton"
				temp_table.slowed = wesnoth.get_dialog_value "slowed_checkbutton"
				temp_table.petrified = wesnoth.get_dialog_value "petrified_checkbutton"
				temp_table.uncovered = wesnoth.get_dialog_value "uncovered_checkbutton"
				temp_table.guardian = wesnoth.get_dialog_value "guardian_checkbutton"
				temp_table.unhealable = wesnoth.get_dialog_value "unhealable_checkbutton"
				temp_table.stunned = wesnoth.get_dialog_value "stunned_checkbutton"
				-- put facing here
				local facings = { "nw", "ne", "n", "sw", "se", "s" }
				-- wesnoth.get_dialog_value ( "facing_listbox" ) returns a number, that was 2 for the second radiobutton and 5 for the fifth, hence the table above
				temp_table.facing = facings[ wesnoth.get_dialog_value ( "facing_listbox" ) ] -- it is setted correctly, but for some reason it is not shown
				-- misc; checkbuttons
				temp_table.resting = wesnoth.get_dialog_value "resting_checkbutton"
				temp_table.hidden = wesnoth.get_dialog_value "hidden_checkbutton"
			end

			local return_value = wesnoth.show_dialog( debug_dialog, preshow, postshow )

			return { return_value = return_value, { "temp_table", temp_table } }
		end

		local return_table = wesnoth.synchronize_choice(sync)
		local return_value = return_table.return_value
		local temp_table = helper.get_child( return_table, "temp_table" )

		if return_value == 1 or return_value == -1 then -- if used pressed OK or Enter, modify unit
			-- sliders
			if wesnoth.sides[temp_table.side] then
				lua_dialog_unit.side = temp_table.side
			end
			lua_dialog_unit.hitpoints = temp_table.hitpoints
			lua_dialog_unit.experience = temp_table.experience
			lua_dialog_unit.moves = temp_table.moves
			lua_dialog_unit.attacks_left = temp_table.attacks_left
			-- text boxes
			-- we do this empty table/gmatch/insert cycle, because get_dialog_value returns a string from a text_box, and the value required is a "table with unnamed indices holding strings"
			-- moved here because synchronize_choice needs a WML object, and a table with unnamed indices isn't
			local temp_advances_to = {}
			local temp_extra_recruit = {}
			for value in wlp_utils.split( temp_table.extra_recruit ) do
				table.insert( temp_extra_recruit, wlp_utils.chop( value ) )
			end
			for value in wlp_utils.split( temp_table.extra_recruit ) do
				table.insert( temp_advances_to, wlp_utils.chop( value ) )
			end
			lua_dialog_unit.advances_to = temp_advances_to
			lua_dialog_unit.extra_recruit = temp_extra_recruit
			lua_dialog_unit.role = temp_table.role
			-- checkbuttons
			lua_dialog_unit.status.poisoned = temp_table.poisoned
			lua_dialog_unit.status.slowed = temp_table.slowed
			lua_dialog_unit.status.petrified = temp_table.petrified
			lua_dialog_unit.status.uncovered = temp_table.uncovered
			lua_dialog_unit.status.guardian = temp_table.guardian
			lua_dialog_unit.status.unhealable = temp_table.unhealable
			lua_dialog_unit.status.stunned = temp_table.stunned
			lua_dialog_unit.facing = temp_table.facing
			-- misc; checkbuttons
			lua_dialog_unit.resting = temp_table.resting
			lua_dialog_unit.hidden = temp_table.hidden
			-- for some reason, without this delay the death animation isn't played
			wesnoth.delay(1)
			-- fire events if needed
			if lua_dialog_unit.hitpoints <= 0 then -- do not try to advance a dead unit
				wml_actions.kill( { id = lua_dialog_unit.id, animate = true, fire_event = true } )
			elseif lua_dialog_unit.experience >= lua_dialog_unit.max_experience then
				wml_actions.store_unit { { "filter", { id = lua_dialog_unit.id } }, variable = "Lua_store_unit", kill = true }
				wml_actions.unstore_unit { variable = "Lua_store_unit", find_vacant = false, advance = true, fire_event = true }
				wesnoth.set_variable ( "Lua_store_unit")
			end
			-- finally, redraw to be sure of showing changes
			wml_actions.redraw {}
		elseif return_value == 2 or return_value == -2 then -- if user pressed Cancel or Esc, nothing happens
		else wesnoth.message( tostring( _"Quick Debug" ), tostring( _"Error, return value :" ) .. return_value ) end -- any unhandled case is handled here
	-- if user clicks on empty hex, do nothing
	end
end

-- [show_side_debug]
-- This tag is meant for use inside a [set_menu_item], because it gets the unit at x1,y1
-- It allows modifying all those side parameters that don't require accessing the .__cfg field.
-- Shows also read only parameters.
-- Usage:
-- [set_menu_item]
--	id=side_debug
--	description=Side Debug
--	[command]
--		[show_side_debug]
--		[/show_side_debug]
--	[/command]
-- [/set_menu_item]

function wml_actions.show_side_debug ( cfg )
	local side_unit = wesnoth.get_unit ( wesnoth.current.event_context.x1, wesnoth.current.event_context.y1 )
	if side_unit and side_unit.valid then
		local side_number = side_unit.side -- clearly, at x1,y1 there could be only one unit, hence get_unit

		local lua_dialog_side = wesnoth.get_side ( side_number )

		-- experimenting with macrowidgets... sort of
		--buttonbox
		local buttonbox = T.grid { T.row { T.column { T.button { label = _"OK", return_value = 1 } },
						   T.column { T.spacer { width = 10 } },
						   T.column { T.button { label = _"Cancel", return_value = 2 } } } }

		-- read-only labels
		-- fields here: total_income, fog, shroud, hidden, name, color
		local read_only_panel = T.grid { T.row { T.column { horizontal_alignment = "left", border = "all", border_size = 5, T.label { label = _"Total income" } },
							 T.column { horizontal_alignment = "left", border = "all", border_size = 5, T.label { id = "total_income_label" } } },
						 T.row { T.column { horizontal_alignment = "left", border = "all", border_size = 5, T.label { label = _"Fog" } },
							 T.column { horizontal_alignment = "left", border = "all", border_size = 5, T.label { id = "fog_label" } } },
						 T.row { T.column { horizontal_alignment = "left", border = "all", border_size = 5, T.label { label = _"Shroud" } },
							 T.column { horizontal_alignment = "left", border = "all", border_size = 5, T.label { id = "shroud_label" } } },
						 T.row { T.column { horizontal_alignment = "left", border = "all", border_size = 5, T.label { label = _"Hidden" } },
							 T.column { horizontal_alignment = "left", border = "all", border_size = 5, T.label { id = "hidden_label" } } },
						 T.row { T.column { horizontal_alignment = "left", border = "all", border_size = 5, T.label { label = _"Name" } },
							 T.column { horizontal_alignment = "left", border = "all", border_size = 5, T.label { id = "name_label" } } },
						 T.row { T.column { horizontal_alignment = "left", border = "all", border_size = 5, T.label { label = _"Color" } },
							 T.column { horizontal_alignment = "left", border = "all", border_size = 5, T.label { id = "color_label" } } }
						}

		-- controller radiobutton
		-- values here: ai, human, null, human_ai, network, network_ai
		local radiobutton = T.horizontal_listbox { id = "controller_listbox",
							   T.list_definition { T.row { T.column { T.toggle_button { id = "controller_radiobutton" } } } },
							   T.list_data { T.row { horizontal_alignment = "left", border = "all", border_size = 5, T.column { label = _"ai" } },
									 T.row { horizontal_alignment = "left", border = "all", border_size = 5, T.column { label = _"human" } },
									 T.row { horizontal_alignment = "left", border = "all", border_size = 5, T.column { label = _"human_ai" } },
									 T.row { horizontal_alignment = "left", border = "all", border_size = 5, T.column { label = _"network" } },
									 T.row { horizontal_alignment = "left", border = "all", border_size = 5, T.column { label = _"network_ai" } },
									 T.row { horizontal_alignment = "left", border = "all", border_size = 5, T.column { label = _"null" } } }
							 }

		-- modifications panel
		-- fields here: gold, village_gold, base_income, user_team_name, objectives_changed, team_name, controller
		local modify_panel = T.grid { T.row { T.column { horizontal_alignment = "right", border = "all", border_size = 5, T.label { label = _"Gold" } },
						      T.column { horizontal_alignment = "left", border = "all", border_size = 5,
								 T.slider { minimum_value = math.min( 0, lua_dialog_side.gold ),
									    maximum_value = math.max( 1000, lua_dialog_side.gold ),
									    step_size = 1,
									    id = "side_gold_slider" } } },
					      T.row { T.column { horizontal_alignment = "right", border = "all", border_size = 5, T.label { label = _"Village gold" } },
						      T.column { horizontal_alignment = "left", border = "all", border_size = 5,
								 T.slider { minimum_value = math.min( 0, lua_dialog_side.village_gold ),
									    maximum_value = math.max( 10, lua_dialog_side.village_gold ),
									    step_size = 1,
									    id = "side_village_gold_slider" } } },
					      T.row { T.column { horizontal_alignment = "right", border = "all", border_size = 5, T.label { label = _"Base income" } },
						      T.column { horizontal_alignment = "left", border = "all", border_size = 5,
								 T.slider { minimum_value = math.min( -2, lua_dialog_side.base_income ),
									    maximum_value = math.max( 18, lua_dialog_side.base_income ),
									    step_size = 1,
									    id = "side_base_income_slider" } } },
					      T.row { T.column { horizontal_alignment = "right", border = "all", border_size = 5, T.label { label = _"User team name" } },
						      T.column { horizontal_alignment = "left", border = "all", border_size = 5,
								 T.text_box { id = "user_team_name_textbox", history = "other_user_team_names" } } },
					      T.row { T.column { horizontal_alignment = "right", border = "all", border_size = 5, T.label { label = _"Objectives changed" } },
						      T.column { horizontal_alignment = "left", border = "all", border_size = 5,
								 T.toggle_button { label = _"Yes", id = "objectives_changed_checkbutton" } } },
					      T.row { T.column { horizontal_alignment = "right", border = "all", border_size = 5, T.label { label = _"Team name" } },
						      T.column { horizontal_alignment = "left", border = "all", border_size = 5,
								 T.text_box { id = "team_name_textbox", history = "other_team_names" } } },
					      T.row { T.column { horizontal_alignment = "right", border = "all", border_size = 5, T.label { label = _"Controller" } },
						      T.column { horizontal_alignment = "left", border = "all", border_size = 5,
								 radiobutton } }
					    }

		local side_dialog = { T.helptip { id="tooltip_large" }, -- mandatory field
				      T.tooltip { id="tooltip_large" }, -- mandatory field
				      T.grid { -- Title
					       T.row { T.column { horizontal_alignment = "left",
								  grow_factor = 1, -- this one makes the title bigger and golden
								  border = "all",
								  border_size = 5,
								  T.label { definition = "title", label = _"Side Debug Menu" } } },
					       -- Subtitile
					       T.row { T.column { horizontal_alignment = "left",
								  border = "all",
								  border_size = 5,
								  T.label { label = _"Set the desired parameters, then press OK to confirm or Cancel to exit" } } },
					       T.row { T.column { T.grid {
									   T.row { T.column { vertical_alignment = "top", read_only_panel },
										   T.column { modify_panel } }
						     } } },
					       T.row { T.column { buttonbox } }
					     }
				    }

		local function preshow()
			-- set widget values
			-- read-only labels
			wesnoth.set_dialog_value ( lua_dialog_side.total_income, "total_income_label" )
			wesnoth.set_dialog_value ( lua_dialog_side.fog, "fog_label" )
			wesnoth.set_dialog_value ( lua_dialog_side.shroud, "shroud_label" )
			wesnoth.set_dialog_value ( lua_dialog_side.hidden, "hidden_label" )
			wesnoth.set_dialog_value ( lua_dialog_side.name, "name_label" )
			local color_names = { _"Red", _"Blue", _"Green", _"Purple", _"Black", _"Brown", _"Orange", _"White", _"Teal" }
			local color_number = tonumber( lua_dialog_side.color )
			wesnoth.set_dialog_value ( color_names[ color_number ], "color_label" )
			-- sliders
			wesnoth.set_dialog_value ( lua_dialog_side.gold, "side_gold_slider" )
			wesnoth.set_dialog_value ( lua_dialog_side.village_gold, "side_village_gold_slider" )
			wesnoth.set_dialog_value ( lua_dialog_side.base_income, "side_base_income_slider" )
			-- text boxes
			--wesnoth.set_dialog_value ( lua_dialog_side.objectives, "side_objectives_textbox" )
			wesnoth.set_dialog_value ( lua_dialog_side.user_team_name, "user_team_name_textbox" )
			wesnoth.set_dialog_value ( lua_dialog_side.team_name, "team_name_textbox" )
			-- checkbutton
			wesnoth.set_dialog_value ( lua_dialog_side.objectives_changed, "objectives_changed_checkbutton" )
			-- radiobutton
			local temp_controller

			if lua_dialog_side.controller == "ai" then
				temp_controller = 1
			elseif lua_dialog_side.controller == "human" then
				temp_controller = 2
			elseif lua_dialog_side.controller == "human_ai" then
				temp_controller = 3
			elseif lua_dialog_side.controller == "network" then
				temp_controller = 4
			elseif lua_dialog_side.controller == "network_ai" then
				temp_controller = 5
			elseif lua_dialog_side.controller == "null" then
				temp_controller = 6
			end
			wesnoth.set_dialog_value ( temp_controller, "controller_listbox" )
		end

		local function sync()
			local temp_table = { } -- to store values before checking if user allowed modifying

			local function postshow()
				-- get widget values
				-- sliders
				temp_table.gold = wesnoth.get_dialog_value ( "side_gold_slider" )
				temp_table.village_gold = wesnoth.get_dialog_value ( "side_village_gold_slider" )
				temp_table.base_income = wesnoth.get_dialog_value ( "side_base_income_slider" )
				-- text boxes
				temp_table.user_team_name = wesnoth.get_dialog_value ( "user_team_name_textbox" )
				temp_table.team_name = wesnoth.get_dialog_value ( "team_name_textbox" )
				-- checkbutton
				temp_table.objectives_changed = wesnoth.get_dialog_value ( "objectives_changed_checkbutton" )
				-- radiobutton
				local controllers = { "ai", "human", "human_ai", "network", "network_ai", "null" }
				temp_table.controller = controllers[ wesnoth.get_dialog_value ( "controller_listbox" ) ]
			end

			local return_value = wesnoth.show_dialog( side_dialog, preshow, postshow )

			return { return_value = return_value, { "temp_table", temp_table } }
		end
		local return_table = wesnoth.synchronize_choice(sync)
		local return_value = return_table.return_value
		local temp_table = helper.get_child(return_table, "temp_table")

		if return_value == 1 or return_value == -1 then -- if used pressed OK or Enter, modify unit
			lua_dialog_side.gold = temp_table.gold
			lua_dialog_side.village_gold = temp_table.village_gold
			lua_dialog_side.base_income = temp_table.base_income
			lua_dialog_side.user_team_name = temp_table.user_team_name
			lua_dialog_side.team_name = temp_table.team_name
			lua_dialog_side.objectives_changed = temp_table.objectives_changed
			lua_dialog_side.controller = temp_table.controller
		elseif return_value == 2 or return_value == -2 then -- if user pressed Cancel or Esc, nothing happens
		else wesnoth.message( tostring( _"Side Debug" ), tostring( _"Error, return value :" ) .. return_value ) end -- any unhandled case is handled here
		-- if user clicks on empty hex, do nothing
	end
end

-- [item_dialog]
-- an alternative interface to pick items
-- could be used in place of [message] with [option] tags
function wml_actions.item_dialog( cfg )
	local image_and_description = T.grid { T.row { T.column { vertical_alignment = "center",
								  horizontal_alignment = "center",
								  border = "all",
								  border_size = 5,
								  T.image { id = "image_name" } },
						       T.column { horizontal_alignment = "left",
								  border = "all",
								  border_size = 5,
								  T.scroll_label { id = "item_description" } }
		                              } }

	local buttonbox = T.grid { T.row { T.column { T.button { id = "take_button", return_value = 1 } },
					   T.column { T.spacer { width = 10 } },
					   T.column { T.button { id = "leave_button", return_value = 2 } }
				  } }

	local item_dialog = { T.helptip { id="tooltip_large" }, -- mandatory field
			      T.tooltip { id="tooltip_large" }, -- mandatory field
			      maximum_height = 320,
			      maximum_width = 480,
			      T.grid { -- Title, will be the object name
				      T.row { T.column { horizontal_alignment = "left",
							  grow_factor = 1, -- this one makes the title bigger and golden
							  border = "all",
							  border_size = 5,
							  T.label { definition = "title", id = "item_name" } } },
				      -- Image and item description
				      T.row { T.column { image_and_description } }, -- grid teminator
				      -- Effect description
				      T.row { T.column { horizontal_alignment = "left",
							  border = "all",
							  border_size = 5,
							  T.label { wrap = true, id = "item_effect" } } }, -- how to format?
				      -- button box
				      T.row { T.column { buttonbox } }
				    }
			    }

	local function item_preshow()
		-- here set all widget starting values
		wesnoth.set_dialog_value ( cfg.name, "item_name" )
		wesnoth.set_dialog_value ( cfg.image or "", "image_name" )
		wesnoth.set_dialog_value ( cfg.description, "item_description" )
		wesnoth.set_dialog_value ( cfg.effect, "item_effect" )
		wesnoth.set_dialog_value ( cfg.take_string or tostring( _"Take it" ), "take_button" )
		wesnoth.set_dialog_value ( cfg.leave_string or tostring( _"Leave it" ), "leave_button" )
	end

	local function sync()
		local function item_postshow()
			-- here get all widget values
		end

		local return_value = wesnoth.show_dialog( item_dialog, item_preshow, item_postshow )

		return { return_value = return_value }
	end

	local return_table = wesnoth.synchronize_choice(sync)
	if return_table.return_value == 1 or return_table.return_value == -1 then
		wesnoth.set_variable ( cfg.variable or "item_picked", "yes" )
	else wesnoth.set_variable ( cfg.variable or "item_picked", "no" )
	end
end
