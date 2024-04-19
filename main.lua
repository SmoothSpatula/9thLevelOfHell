log.info("Successfully loaded ".._ENV["!guid"]..".")
mods.on_all_mods_loaded(function() for k, v in pairs(mods) do if type(v) == "table" and v.hfuncs then Helper = v end end end)

local initialized_diff = false

local enabled = false
local stored_time = 0
local current_char = 0
local credits_init = false
local run_start_init = false

local director = nil

local icon_path = _ENV["!plugins_mod_folder_path"].."/9th.png"
local icon_path2x = _ENV["!plugins_mod_folder_path"].."/9th2x.png"
local diff_icon = gm.sprite_add(icon_path, 5, false, false, 12, 9)
local diff_icon2x = gm.sprite_add(icon_path2x, 4, false, false, 25, 19)
if diff_gray ~= -1 and diff_color ~= -1 then log.info("Loaded difficulty icon sprites.")
else log.info("Failed to load difficulty icon sprites.") end

local diff_sfx = gm.audio_create_stream(_ENV["!plugins_mod_folder_path"].."/9th.ogg")
if diff_sfx ~= -1 then log.info("Loaded difficulty sfx.")
else log.info("Failed to load difficulty sfx.") end

local diff_id = -2


-- Parameters
-- * Remember to update the description text below if modified
local point_scaling = 1.0
local speed_bonus = 0.5
local healing_reduction = 1.0


-- ========== Main ==========

gui.add_imgui(function()
    if ImGui.Begin("9th Level Of Hell") then
        -- Description
        ImGui.Text("Adds a fifth difficulty option, for\nthose who have conquered Monsoon and Deluge.\n\nIncreases Director Credits by 100%,\nenemy attack and move speed by 50%,\ndisables healing, and reduces player speed\nand attack speed by 25%.")
    end

    ImGui.End()
end)


gm.pre_script_hook(gm.constants.actor_heal_networked, function(self, other, result, args)
    -- Disable player healing
    if enabled and args[1].value.object_index == gm.constants.oP then
        args[2].value = 0
    end
end)


gm.pre_script_hook(gm.constants.step_actor, function(self, other, result, args)
    -- Apply speed and attack speed reduction to players
    if enabled and self.team == 2.0 and self.ninth_speed_boost == nil then
        self.ninth_speed_boost = true

        if self.pHmax ~= nil then
            self.pHmax = self.pHmax * (1 + speed_bonus)
            self.pHmax_base = self.pHmax
        end

        -- Reduce attack speed
        if self.attackSpeed ~= nil then
            self.attackSpeed = self.attackSpeed * (1 + speed_bonus)
            self.attackSpeedBase = self.attackSpeed
        end
    end
end)


gm.pre_script_hook(gm.constants.__input_system_tick, function()
    -- Initialize difficulty
    if not initialized_diff then
        initialized_diff = true

        diff_id = gm.difficulty_create("amdunes", "9th Level Of Hell")   -- Namespace, Identifier
        local class_diff = gm.variable_global_get("class_difficulty")[diff_id + 1]
        local values = {
            "9th Level Of Hell", -- Updated name
            "Adds a fourth difficulty option, for\nthose who have conquered Monsoon.\n\nIncreases Director Credits by 100%,\nenemy attack and move speed by 50%,\ndisables healing, and reduces player speed\nand attack speed by 25%.",
            diff_icon,
            diff_icon2x,
            7554098,
            diff_sfx,
            0.16,
            3.0,
            1.7 * (1 + point_scaling),
            true,
            true
        }
        for i = 2, 12 do gm.array_set(class_diff, i, values[i - 1]) end
    end


    -- Reset some variables on the character select screen
    local select_ = Helper.find_active_instance(gm.constants.oSelectMenu)
    if Helper.instance_exists(select_) then
        enabled = false
        current_char = select_.choice
        run_start_init = false
    end


    -- Check if 9th Level Of Hell is on
    if gm._mod_game_getDifficulty() == diff_id then
        enabled = true

        if Helper.instance_exists(director) then

            -- Reset variables when starting a new run
            if director.time_start <= 0 then
                if not run_start_init then
                    stored_time = 0
                    credits_init = false
                    run_start_init = true

                    -- Reduce player health regen
                    player = Helper.get_client_player()
                    if Helper.instance_exists(player) then
                        if player.hp_regen ~= nil then
                            player.hp_regen = player.hp_regen * (1.0 - healing_reduction)
                            player.hp_regen_base = player.hp_regen
                            player.hp_regen_level = player.hp_regen_level * (1.0 - healing_reduction)
                        end
                    end
                end
            else run_start_init = false
            end


            -- Run this every second
            if stored_time < director.time_start then
                stored_time = director.time_start

                -- Increase points by another 1 point per second
                -- This is because the 1.5x scaling from point_scale does not apply to the initial 2 pps
                director.points = director.points + (2 * point_scaling)
            end
        else director = Helper.find_active_instance(gm.constants.oDirectorControl)
        end
    end
end)
