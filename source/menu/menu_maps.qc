// Since these are built on-the-fly, do not populate here
string menu_maps_buttons[13];

float menu_maps_init;

float(string bsp_name) Menu_Maps_IsSoloBlockedMap =
{
    if (bsp_name == "nzp_warehouse2")
        return true;

    if (bsp_name == "nzp_warehouse")
        return true;

    if (bsp_name == "nzp_xmas2")
        return true;

    if (bsp_name == "christmas_special")
        return true;

    return false;
};

//
// Menu_Maps_Init()
// Array lookup optimization that stores
// the array index of Stock NZ:P maps
// from the user_maps struct.
//
void() Menu_Maps_Init =
{
    menu_maps_init = true;
    user_maps_page = 0;

    for(int i = 0; i < stock_maps.length; i++) {
        if (stock_maps[i].bsp_name == "")
            continue;
        
        for(int j = 0; j < user_maps_count; j++) {
            if (user_maps[j].map_name == stock_maps[i].bsp_name)
                stock_maps[i].array_index = j;
        }
    }
};

void() Menu_Maps_NextPage =
{
    Menu_PlaySound(MENU_SND_ENTER);
    user_maps_page++;
}

void() Menu_Maps_PrevPage =
{
    Menu_PlaySound(MENU_SND_ENTER);
    user_maps_page--;
}

void(string bsp_name) Menu_Maps_LoadMap =
{
    current_selected_bsp = bsp_name;
    last_map_menu = current_menu;
    cvar_set("sv_gamemode", "0");
	cvar_set("sv_difficulty", "0");
	cvar_set("sv_startround", "0");
	cvar_set("sv_magic", "1");
	cvar_set("sv_headshotonly", "0");
	cvar_set("sv_maxai", "24");
	cvar_set("sv_fastrounds", "0");
    current_menu = MENU_LOBBY;
};

string(string prev_id) Menu_Maps_GetNextButton =
{
    if (prev_id == "")
        return menu_maps_buttons[0];

    string ret = menu_maps_buttons[0];

    for(float i = 0; i < menu_maps_buttons.length; i++) {
        if (menu_maps_buttons[i] == prev_id) {
            if (i + 1 >= menu_maps_buttons.length)
                break;

            ret = menu_maps_buttons[i + 1];
            break;
        }
    }

    if (ret == "")
        return menu_maps_buttons[0];

    return ret;
};

string(string next_id) Menu_Maps_GetPreviousButton =
{
    // Get the last populated entry.
    string last_populated_entry = "";
    for(float j = menu_maps_buttons.length - 1; j > 0; j--) {
        if (menu_maps_buttons[j] != "") {
            last_populated_entry = menu_maps_buttons[j];
            break;
        }
    }

    if (next_id == "")
        return last_populated_entry;

    string ret = last_populated_entry;

    for(float i = menu_maps_buttons.length - 1; i > 0; i--) {
        if (menu_maps_buttons[i] == next_id) {
            if (i - 1 < 0)
                break;

            ret = menu_maps_buttons[i - 1];
            break;
        }
    }

    return ret;
};

void() Menu_Maps =
{
    if (!menu_maps_init)
        Menu_Maps_Init();

    Menu_DrawBackground();

    string back_string = "";
    float back_menudest = 0;

    switch(menu_map_mode) {
        case MAP_SOLOSTOCK: Menu_DrawTitle("SELECT MAP: SOLO"); back_string = "Return to Main Menu."; back_menudest = MENU_MAIN; break;
        case MAP_SOLOUSER: Menu_DrawTitle("USER MAPS: SOLO"); back_string = "Return to Stock Map selection."; back_menudest = MENU_SOLO; break;
        case MAP_COOPSTOCK: Menu_DrawTitle("SELECT MAP: COOP"); back_string = "Return to Create Game Menu."; back_menudest = MENU_COOPCREATE; break;
        case MAP_COOPUSER: Menu_DrawTitle("USER MAPS: COOP"); back_string = "Return to Stock Map selection."; back_menudest = MENU_COOPSTOCK; break;
        default: break;
    }

    Menu_DrawMapPanel();

    int i;

    // Reset map button registry
    for(int h = 0; h < 13; h++) {
        menu_maps_buttons[h] = "";
    }

    // Stock Maps
    if (menu_map_mode == MAP_SOLOSTOCK || menu_map_mode == MAP_COOPSTOCK) {
        int visible_stock_count = 0;

        for(i = 0; i < stock_maps.length; i++) {
            if (stock_maps[i].bsp_name == "") {
                Menu_DrawDivider(visible_stock_count + 1.25);
                continue;
            }

            if (menu_map_mode == MAP_SOLOSTOCK && Menu_Maps_IsSoloBlockedMap(stock_maps[i].bsp_name)) {
                continue;
            }

            // Build the map strings
            menu_maps_buttons[visible_stock_count] = sprintf("map_%s", stock_maps[i].bsp_name);

            Menu_MapButton(visible_stock_count + 1, sprintf("map_%s", stock_maps[i].bsp_name), stock_maps[i].bsp_name, stock_maps[i].map_category, -1) ? Menu_Maps_LoadMap(stock_maps[i].bsp_name) : 0;
            visible_stock_count++;
        }
        Menu_DrawDivider(visible_stock_count + 1.25);

		if (menu_map_mode == MAP_SOLOSTOCK) {
			Menu_Button(visible_stock_count + 1.5, "map_nzpusermaps", "USER MAPS", "View User-Created Maps.") ? current_menu = MENU_SOLOUSER : 0;
		} else if (menu_map_mode == MAP_COOPSTOCK) {
			Menu_Button(visible_stock_count + 1.5, "map_nzpusermaps", "USER MAPS", "View User-Created Maps.") ? current_menu = MENU_COOPUSER : 0;
		}

        if (Menu_Button(visible_stock_count + 2.5, "map_randommap", "RANDOM", "Feeling indecisive? Try rolling the dice."))
        {
            int random_candidate_indices[USER_MAPS_MAX];
            int random_candidate_count = 0;

            for(int random_i = 0; random_i < user_maps_count; random_i++) {
                if (menu_map_mode == MAP_SOLOSTOCK && Menu_Maps_IsSoloBlockedMap(user_maps[random_i].map_name))
                    continue;

                random_candidate_indices[random_candidate_count] = random_i;
                random_candidate_count++;
            }

            if (random_candidate_count > 0) {
                int random_candidate_pick = rint(random() * (random_candidate_count - 1));
                int random_map_index = random_candidate_indices[random_candidate_pick];
                Menu_Maps_LoadMap(user_maps[random_map_index].map_name);
            } else {
                Menu_PlaySound(MENU_SND_BEEP);
            }
        }

        // Usermaps and back button registry
        menu_maps_buttons[visible_stock_count] = "map_nzpusermaps";
        menu_maps_buttons[visible_stock_count + 1] = "map_randommap";
        menu_maps_buttons[visible_stock_count + 2] = "map_back";
    } else {
        int filtered_user_map_indices[USER_MAPS_MAX];
        int filtered_user_map_count = 0;

        for (i = 0; i < user_maps_count; i++) {
            if (menu_map_mode == MAP_SOLOUSER && Menu_Maps_IsSoloBlockedMap(user_maps[i].map_name))
                continue;

            filtered_user_map_indices[filtered_user_map_count] = i;
            filtered_user_map_count++;
        }

        if (user_maps_page < 0)
            user_maps_page = 0;

        int max_user_map_page = 0;
        if (filtered_user_map_count > 0)
            max_user_map_page = floor((filtered_user_map_count - 1) / 10);

        if (user_maps_page > max_user_map_page)
            user_maps_page = max_user_map_page;

        // calculate the amount of usermaps we can display on this page.
        int maps_on_page = 10; // default to 10, all that will fit on the UI.
        int maps_start_position = (user_maps_page * 10);

        // Not all 10 slots can be filled..
        if (maps_on_page > filtered_user_map_count - maps_start_position)
            maps_on_page = filtered_user_map_count - maps_start_position;

        for (i = maps_start_position; i < maps_on_page + maps_start_position; i++) {
            int menu_position = (i + 1) - (user_maps_page * 10);
            int user_map_index = filtered_user_map_indices[i];
            string bsp_name = user_maps[user_map_index].map_name;

            // Build the map strings
            menu_maps_buttons[menu_position - 1] = sprintf("map_%s", bsp_name);

            // Kind of a hack but whatever..
            // Make sure we keep the correct badge when viewing
            // official maps in the user maps menu.
            float map_category = MAP_CATEGORY_USER;
            for(int j = 0; j < stock_maps.length; j++) {
                if (user_maps[user_map_index].map_name == stock_maps[j].bsp_name) {
                    map_category = stock_maps[j].map_category;
                }
            }

            Menu_MapButton(menu_position, sprintf("map_%s", bsp_name), bsp_name, map_category, user_map_index) ? Menu_Maps_LoadMap(bsp_name) : 0;
        }

        int current_registry_position = ((i + 1) - (user_maps_page * 10)) - 1;

        Menu_DrawDivider(11.25);

        if (maps_on_page + maps_start_position < filtered_user_map_count) {
            menu_maps_buttons[current_registry_position] = "map_usernext";
            current_registry_position++;
            Menu_Button(-3, "map_usernext", "NEXT PAGE", "Advance to next User Map page.") ? Menu_Maps_NextPage() : 0;
        } else {
            Menu_GreyButton(-3, "NEXT PAGE");
        }

        if (user_maps_page != 0) {
            menu_maps_buttons[current_registry_position] = "map_userprev";
            current_registry_position++;
            Menu_Button(-2, "map_userprev", "PREVIOUS PAGE", "Return to last User Map page.") ? Menu_Maps_PrevPage() : 0;
        } else {
            Menu_GreyButton(-2, "PREVIOUS PAGE");
        }

        menu_maps_buttons[current_registry_position] = "map_back";
    }

    Menu_Button(-1, "map_back", "BACK", back_string) ? current_menu = back_menudest : 0;

	sui_pop_frame();	
};
