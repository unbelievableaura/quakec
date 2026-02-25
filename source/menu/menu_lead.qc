#define MENU_LEADERBOARD_MAX 5

string menu_leader_buttons[1] = {"lb_back"};

var struct menu_leader_entry_s
{
	string name;
	string map;
	float level;
	float ts;
} menu_leader_entries[MENU_LEADERBOARD_MAX];

float menu_leader_count;
float menu_leader_loading;
float menu_leader_error;
float menu_leader_has_data;
float menu_leader_last_fetch_time;
float menu_leader_fetch_reqid;

string(string value, float max_chars, string fallback) Menu_Leaderboard_ClampText =
{
	string working = value;
	if (!working || working == "")
		working = fallback;

	if (strlen(working) <= max_chars)
		return working;

	if (max_chars <= 3)
		return substring(working, 0, max_chars);

	return strcat(substring(working, 0, max_chars - 3), "...");
};

void() Menu_Leaderboard_Clear =
{
	menu_leader_count = 0;
	menu_leader_has_data = false;

	for (int i = 0; i < MENU_LEADERBOARD_MAX; i++) {
		menu_leader_entries[i].name = "";
		menu_leader_entries[i].map = "";
		menu_leader_entries[i].level = 0;
		menu_leader_entries[i].ts = 0;
	}
};

void(string resourcebody) Menu_Leaderboard_ParsePayload =
{
	Menu_Leaderboard_Clear();

	jsonnode root = json_parse(resourcebody);
	if (!root) {
		menu_leader_error = true;
		return;
	}

	jsonnode entries_node = json_find_object_child(root, "entries");
	if (!entries_node || json_get_value_type(entries_node) != JSON_TYPE_ARRAY) {
		json_free(root);
		menu_leader_error = true;
		return;
	}

	int total = json_get_length(entries_node);
	for (int i = 0; i < total && i < MENU_LEADERBOARD_MAX; i++) {
		jsonnode entry = json_get_child_at_index(entries_node, i);
		if (!entry || json_get_value_type(entry) != JSON_TYPE_OBJECT)
			continue;

		jsonnode name_node = json_find_object_child(entry, "name");
		jsonnode map_node = json_find_object_child(entry, "map");
		jsonnode level_node = json_find_object_child(entry, "level");
		jsonnode ts_node = json_find_object_child(entry, "ts");

		menu_leader_entries[menu_leader_count].name = Menu_Leaderboard_ClampText(json_get_string(name_node), 24, "Unknown Soldier");
		menu_leader_entries[menu_leader_count].map = Menu_Leaderboard_ClampText(json_get_string(map_node), 32, "Unknown Map");
		menu_leader_entries[menu_leader_count].level = json_get_integer(level_node);
		menu_leader_entries[menu_leader_count].ts = json_get_integer(ts_node);
		menu_leader_count++;
	}

	menu_leader_has_data = true;
	menu_leader_error = false;
	json_free(root);
};

string() Menu_Leaderboard_ApiBase =
{
	string api = cvar_string("cl_leaderboard_api");
	if (api == "")
		return "/api/leaderboard";
	return api;
};

void() Leaderboard_FetchTop5_Menu =
{
	if (menu_leader_loading)
		return;

	menu_leader_loading = true;
	menu_leader_error = false;
	menu_leader_fetch_reqid += 1;
	uri_get(strcat(Menu_Leaderboard_ApiBase(), "?limit=5"), menu_leader_fetch_reqid);
};

void(float reqid, float responsecode, string resourcebody) URI_Get_Callback =
{
	if (reqid != menu_leader_fetch_reqid)
		return;

	menu_leader_loading = false;
	menu_leader_last_fetch_time = time;

	float is_ok = (responsecode == 0 || (responsecode >= 200 && responsecode < 300));
	if (!is_ok) {
		menu_leader_error = true;
		return;
	}

	Menu_Leaderboard_ParsePayload(resourcebody);
};

string(string prev_id) Menu_Leaderboard_GetNextButton =
{
	if (prev_id == "")
		return menu_leader_buttons[0];
	return menu_leader_buttons[0];
};

string(string next_id) Menu_Leaderboard_GetPreviousButton =
{
	if (next_id == "")
		return menu_leader_buttons[0];
	return menu_leader_buttons[0];
};

void() Menu_Leaderboard =
{
	if (last_menu != MENU_LEADERBOARD)
		Leaderboard_FetchTop5_Menu();

	Menu_DrawBackground();
	Menu_DrawTitle("LEADERBOARD");

	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_fill([6, 80], [285, 176], [0, 0, 0], 0.78, 0);
	sui_fill([6, 80], [285, 2], [0.35, 0.35, 0.35], 1, 0);

	sui_text([14, 90], MENU_TEXT_SMALL, "NAME", [1, 1, 0], 1, 0);
	sui_text([130, 90], MENU_TEXT_SMALL, "MAP", [1, 1, 0], 1, 0);
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);
	sui_text([-14, 90], MENU_TEXT_SMALL, "LEVEL", [1, 1, 0], 1, 0);
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_fill([14, 108], [260, 2], [0.25, 0.25, 0.25], 1, 0);

	for (int i = 0; i < MENU_LEADERBOARD_MAX; i++) {
		float row_y = 116 + (i * 24);
		string row_name = "---";
		string row_map = "---";
		string row_level = "---";

		if (i < menu_leader_count) {
			row_name = menu_leader_entries[i].name;
			row_map = menu_leader_entries[i].map;
			row_level = ftos(menu_leader_entries[i].level);
		}

		sui_text([14, row_y], MENU_TEXT_SMALL, sprintf("%d.", i + 1), [0.9, 0.9, 0.9], 1, 0);
		sui_text([34, row_y], MENU_TEXT_SMALL, row_name, [1, 1, 1], 1, 0);
		sui_text([130, row_y], MENU_TEXT_SMALL, row_map, [1, 1, 1], 1, 0);
		sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);
		sui_text([-14, row_y], MENU_TEXT_SMALL, row_level, [1, 1, 1], 1, 0);
		sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	}

	if (menu_leader_loading) {
		sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_END]);
		sui_text([0, -30], MENU_TEXT_MEDIUM, "Fetching leaderboard...", [1, 1, 1], 1, 0);
		sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	} else if (menu_leader_error) {
		sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_END]);
		sui_text([0, -30], MENU_TEXT_MEDIUM, "Leaderboard refresh failed.", [1, 0.7, 0.7], 1, 0);
		sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	}

	Menu_Button(-1, "lb_back", "BACK", "Return to Main Menu.") ? current_menu = MENU_MAIN : 0;
	sui_pop_frame();
};
