//This script and its support scripts are in the public domain.
//If you want to disable it while having it installed, type "set disable_source_terminal_gui=true" in the GCLI. To re-enable, "set disable_source_terminal_gui=false".

since 17.4; //the earliest main release that is usable in modern KOL (cookie bug)
import "relay/Guide/Support/HTML.ash";
import "relay/Guide/Support/Strings.ash"
import "relay/Guide/Support/Library.ash"
//Libary import could be changed in the future; right now it includes a bunch of things we don't need and a few things we do.
string __version = "1.0.2";

boolean __setting_enabled = !get_property("disable_source_terminal_gui").to_boolean();

boolean __setting_debug = false;
string __setting_background_colour = "#C0C0C0";
string __setting_second_level_colour = "#DEDEDE";
int __setting_surrounding_margin_width = 0;
string __setting_left_padding = "15px";
boolean __setting_test_all_extrusions = false;

if (!__setting_debug) __setting_test_all_extrusions = false;


//Active:
int __enhancements_remaining = 0;
int __extrusions_remaining = 0;
boolean [string] __chips = getInstalledSourceTerminalSingleChips();

//This exists but is currently unused.
//Not sure if I should enable it or not.
void sourceTerminalGUICheckForUpdates()
{
	if (true)
		return;
	if (get_property("_svnUpdated").to_boolean())
		return;
	string already_checked_property_name = "_sourceTerminalGUICheckedForUpdates";
	string svn_name = "Ezandora-Source-Terminal-GUI-branches-Release";
	if (!svn_exists(svn_name))
		return;
	if (get_property(already_checked_property_name).to_boolean())
		return;
	if (svn_at_head(svn_name))
		return;
	set_property(already_checked_property_name, true);
	print("Updating " + svn_name + "...");
	cli_execute("svn update " + svn_name);
}


Record LeftSideButton
{
	string title;
	string description;
	boolean highlighted;
	boolean greyed_out;
};

LeftSideButton LeftSideButtonMake(string title, string description, boolean highlighted, boolean greyed_out)
{
	LeftSideButton button;
	button.title = title;
	button.description = description;
	button.highlighted = highlighted;
	button.greyed_out = greyed_out;
	return button;
}

void listAppend(LeftSideButton [int] list, LeftSideButton entry)
{
	int position = list.count();
	while (list contains position)
		position += 1;
	list[position] = entry;
}

//Remember how clean guide's source code was?
//Keep remembering, because this isn't guide.

buffer generateSourceTerminalLeftSide()
{
	buffer result;
	result.append(HTMLGenerateTagPrefix("div", mapMake("style", "float:left;width:33%;")));
	
	string font_size = "28px;";
	
	string active_enquiry = get_property("sourceTerminalEnquiry").replace_string(".enq", "");
	
	boolean [skill] active_skills = getActiveSourceTerminalSkills();
	LeftSideButton [int] buttons;
	string educate_description = active_skills.listInvert().listJoinComponents(", ", "and");
	int skill_limit = 1;
	if (__chips["DRAM"])
		skill_limit = 2;
	if (active_skills.count() < skill_limit)
	{
		if (educate_description == "")
			educate_description += HTMLGenerateSpanOfStyle("Not yet learned", "color:black;");
		else
			educate_description += HTMLGenerateSpanOfStyle(" (learn another)", "color:black;");
	}
	buttons.listAppend(LeftSideButtonMake("Educate", educate_description, true, false));
	buttons.listAppend(LeftSideButtonMake("Enhance", __enhancements_remaining > 0 ? (pluralise(__enhancements_remaining, "buff", "buffs")): "", false, __enhancements_remaining == 0));
	buttons.listAppend(LeftSideButtonMake("Extrude", __extrusions_remaining > 0 ? (pluralise(__extrusions_remaining, "item", "items")): "", false, __extrusions_remaining == 0));
	buttons.listAppend(LeftSideButtonMake("Enquiry", active_enquiry == "" ? HTMLGenerateSpanOfStyle("Not yet set", "color:black;").to_string() : active_enquiry.capitaliseFirstLetter(), false, false));
	buttons.listAppend(LeftSideButtonMake("Terminal", "", false, false));
	
	result.append(HTMLGenerateTagPrefix("div", mapMake("style", "display:table;width:100%;height:350px;border-spacing:0px;")));
	
	
	foreach key, button in buttons	
	{
		result.append(HTMLGenerateTagPrefix("div", mapMake("style", "display:table-row;")));
		
		string class_name = "left_button";
		if (button.highlighted)
			class_name += " left_button_highlighted";
		else
			class_name += " left_button_unhighlighted";
		string id = "left_" + button.title.to_lower_case();
		result.append(HTMLGenerateTagPrefix("div", mapMake("class", class_name, "id", id, "onclick", "leftNavigationClick(event,'" + button.title.to_lower_case() + "');")));
		string span_style = "font-size:" + font_size + ";font-weight:bold;";
		if (button.greyed_out)
			span_style += "color:grey;";
		result.append(HTMLGenerateSpanOfStyle(button.title, span_style));
		
		if (button.description != "")
		{
			result.append(HTMLGenerateDivOfStyle(button.description, "position:absolute;font-size:12px;margin-left:15px;color:#555555"));
		}
		
		result.append("</div>");
		result.append("</div>");
	}
	
	
	result.append("</div>");
	result.append("</div>");
	
	
	return result;
}

Record SourceTerminalButtonDisplay
{
	string image_url;
	string title;
	string description;
	string notes;
	string corner_text;
	boolean highlighted;
	boolean greyed_out;
};

SourceTerminalButtonDisplay SourceTerminalButtonDisplayMake(string image_url, string title, string description, string notes, boolean highlighted, boolean greyed_out, string corner_text)
{
	SourceTerminalButtonDisplay button;
	button.image_url = image_url;
	button.title = title;
	button.description = description;
	button.notes = notes;
	button.highlighted = highlighted;
	button.greyed_out = greyed_out;
	button.corner_text = corner_text;
	
	return button;
}

SourceTerminalButtonDisplay SourceTerminalButtonDisplayMake(string image_url, string title, string description, string notes, boolean highlighted, boolean greyed_out)
{
	return SourceTerminalButtonDisplayMake(image_url, title, description, notes, highlighted, greyed_out, "");
}

void listAppend(SourceTerminalButtonDisplay [int] list, SourceTerminalButtonDisplay entry)
{
	int position = list.count();
	while (list contains position)
		position += 1;
	list[position] = entry;
}

SourceTerminalButtonDisplay [int] SourceTerminalButtonDisplayListMakeBlank()
{
	SourceTerminalButtonDisplay [int] list;
	return list;
}

string generateSourceTerminalEffectDescription(effect e)
{
	if (e.have_effect() == 0)
		return "";
	return "Have " + pluralise(e.have_effect(), "turn", "turns");
}

string generateSourceTerminalItemDescription(item it)
{
	if (can_interact() || it.available_amount() == 0)
		return "";
	return "Have " + it.available_amount();
}

buffer generatePageTable(string page_name, SourceTerminalButtonDisplay [int] button_data, boolean is_shadow_table)
{
	//A shadow table is an identical table, floating above the original one, in order to show corner text, due to how cell alignment works.
	buffer result;
	
	//string table_style = "display:table;width:100%;height:305px;border-spacing:10px;";
	string table_style = "display:table;width:335px;height:305px;border-spacing:10px;";
	if (is_shadow_table)
		table_style += "position:absolute;z-index:4";
	
	boolean need_to_always_output_notes = false;
	boolean found_corner_text = false;
	foreach key, button in button_data
	{
		if (button.notes != "")
		{
			need_to_always_output_notes = true;
			break;
		}
		if (button.corner_text != "")
			found_corner_text = true;
	}
	if (!found_corner_text && is_shadow_table) //don't generate a shadow table if there's no reason to
		return result;
		
	result.append(HTMLGenerateTagPrefix("div", mapMake("style", table_style)));
	boolean use_compressed_form = false;
	if (button_data.count() > 6)
		use_compressed_form = true;
	boolean use_supercompressed_form = false;
	if (button_data.count() > 9)
		use_supercompressed_form = true;
	
	boolean need_to_output_end_row_div = false;
	foreach key, button in button_data
	{
		boolean is_new_row = false;
		int entries_per_row = 2;
		if (use_compressed_form)
			entries_per_row = 3;
		if (key % entries_per_row == 0)
			is_new_row = true;
		
		if (is_new_row)
		{
			if (need_to_output_end_row_div)
			{
				result.append("</div>");
				need_to_output_end_row_div = false;
			}
				
			result.append(HTMLGenerateTagPrefix("div", mapMake("style", "display:table-row;")));
			need_to_output_end_row_div = true;
		}
		
		
		string cell_style = "";
		string cell_class = "right_button";
		boolean clickable = false;
		if (use_compressed_form)
			cell_class += " right_button_compressed";
		if (button.greyed_out)
		{
			cell_style += "opacity:0.5;";
			if (is_shadow_table)
				cell_style += "border-color:rgba(235,235,235, 0.0);";
		}
		if (!is_shadow_table)
		{
			cell_class += " right_button_visible";
		}
		//else
			//cell_style += "pointer-events: none;";
		if (button.highlighted)
		{
			if (!is_shadow_table)
				cell_class += " right_button_highlighted";
		}
		else if (!button.greyed_out || page_name == "Educate") //assumption: if they aren't highlighted, then they are clickable
			clickable = true;
			
		if (clickable)
			cell_class += " right_button_clickable";
			
		string [string] cell_map = mapMake("style", cell_style, "class", cell_class);
		
		if (clickable)
		{
			cell_map["onclick"] = "actionButtonClicked(event, '" + page_name + "','" + button.title + "');";
		}
		
		result.append(HTMLGenerateTagPrefix("div", cell_map));
		//if (button.corner_text != "")// && use_compressed_form)
			//result.append(HTMLGenerateDivOfStyle(button.corner_text, "position:absolute;margin-top:-5px;margin-left:2px;font-size:12px;color:grey;"));
			
		if (!is_shadow_table)
		{
			if (button.image_url != "")
				result.append(HTMLGenerateTagPrefix("img", mapMake("src", button.image_url, "width", "30", "height", "30")));
			
			int font_size = 15;
			if (use_compressed_form)
				font_size = 12;
			result.append(HTMLGenerateDivOfStyle(button.title, "font-weight:bold;font-size:" + font_size + "px;"));
			if (!use_supercompressed_form)
				result.append(HTMLGenerateDivOfStyle(button.description, "font-size:11px;color:#555555;"));
			if (!use_compressed_form)
			{
				if (button.notes != "" || need_to_always_output_notes)
					result.append(HTMLGenerateDivOfStyle((button.notes == "" ? "&nbsp;" : button.notes), "font-size:11px;color:#555555;"));
			}
		}
		else
		{
			if (button.corner_text != "")
				result.append(HTMLGenerateDivOfStyle(button.corner_text, "position:absolute;margin-top:5px;margin-left:5px;font-size:12px;color:grey;"));
			else
				result.append(HTMLGenerateDivOfStyle("&nbsp;", ""));
		}
		result.append("</div>");
	}
	if (need_to_output_end_row_div)
	{
		result.append("</div>");
		need_to_output_end_row_div = false;
	}

	result.append("</div>");
	
	return result;
}

buffer generateSourceTerminalRightSides()
{
	//Initialise data sources:
	string [string] page_titles;
	string [string] page_subtitles;
	SourceTerminalButtonDisplay [string][int] button_data;
	string [string] raw_html_to_add;
	
	
    int digitisations = get_property_int("_sourceTerminalDigitizeUses");
    int digitisation_limit = 1;
    if (__chips["TRAM"])
        digitisation_limit += 1;
    if (__chips["TRIGRAM"])
        digitisation_limit += 1;
    int digitisations_remaining = clampi(digitisation_limit - digitisations, 0, 3);
	string digitise_description = "";
	if (digitisations_remaining > 0)
		digitise_description = pluralise(digitisations_remaining, "use", "uses") + " remaining";
	
	
	page_titles["Educate"] = "Learn combat skills";
	page_titles["Enhance"] = "Acquire buffs";
	page_titles["Extrude"] = "Create items";
	if (__enhancements_remaining > 0)
		page_titles["Enhance"] = "Acquire " + pluraliseWordy(__enhancements_remaining, "more buff", "more buffs");
	else
		page_titles["Enhance"] = HTMLGenerateSpanOfStyle("Out of buffs", "color:grey");
	if (__extrusions_remaining > 0)
		page_titles["Extrude"] = "Create " + pluraliseWordy(__extrusions_remaining, "more item", "more items");
	else
		page_titles["Extrude"] = HTMLGenerateSpanOfStyle("Out of creations", "color:grey");
	
	page_titles["Enquiry"] = "Set rollover buff";
	page_titles["Terminal"] = "Terminal";
	
	
	int skill_mp_cost = 20;
	if (__chips["ASHRAM"])
		skill_mp_cost -= 5;
	skill_mp_cost -= get_property_int("sourceTerminalSpam");
	skill_mp_cost = clampi(skill_mp_cost, 5, 20);
	
	int enhancement_length = 25;
	if (__chips["INGRAM"])
		enhancement_length += 25;
	enhancement_length += get_property_int("sourceTerminalPram") * 5;
	enhancement_length = clampi(enhancement_length, 25, 100);
	
	int enquiry_length = 50;
	if (__chips["DIAGRAM"])
		enquiry_length += 50;
	enquiry_length += get_property_int("sourceTerminalGram") * 10;
	enquiry_length = clampi(enquiry_length, 50, 200);
		
	
	page_subtitles["Educate"] = skill_mp_cost + " MP";
	page_subtitles["Enhance"] = "Lasts " + enhancement_length + " turns";
	page_subtitles["Extrude"] = $item[source essence].item_amount() + " essence";
	if ($item[source essence].item_amount() == 0)
		page_subtitles["Extrude"] = "No essence";
	page_subtitles["Enquiry"] = "Lasts " + enquiry_length + " turns";
	page_subtitles["Terminal"] = "It's a UNIX system... I know this...";
	
	foreach s in $strings[Educate,Enhance,Extrude,Enquiry,Terminal]
		button_data[s] = SourceTerminalButtonDisplayListMakeBlank();
		
	boolean [skill] active_skills = getActiveSourceTerminalSkills();
	//Educate:
	button_data["Educate"].listAppend(SourceTerminalButtonDisplayMake("images/itemimages/syringe2.gif", "Extract", "Extract source essence", "", active_skills[$skill[extract]], false));
	int total_duplicate_uses_available = 1;
	if (my_path_id() == PATH_THE_SOURCE)
		total_duplicate_uses_available = 5;
	int duplicate_uses_remaining = clampi(total_duplicate_uses_available - get_property_int("_sourceTerminalDuplicateUses"), 0, total_duplicate_uses_available);
	int overheated_turns_remaining = $effect[Overheated].have_effect();
	button_data["Educate"].listAppend(SourceTerminalButtonDisplayMake("images/itemimages/lightning.gif", "Turbo", "Restores MP", (overheated_turns_remaining > 0 ? "In " + pluralise(overheated_turns_remaining, "turn", "turns") : ""), active_skills[$skill[turbo]], overheated_turns_remaining > 0));
	button_data["Educate"].listAppend(SourceTerminalButtonDisplayMake("images/itemimages/10101.gif", "Digitise", "Arrow Monster", digitise_description, active_skills[$skill[digitize]], digitisations_remaining == 0));
	button_data["Educate"].listAppend(SourceTerminalButtonDisplayMake("images/itemimages/golddice.gif", "Duplicate", "Doubles items dropped", total_duplicate_uses_available == 1 ? "Once/day" : pluraliseWordy(duplicate_uses_remaining, "cast", "casts").capitaliseFirstLetter() + " left", active_skills[$skill[duplicate]], duplicate_uses_remaining == 0));
	int portscan_uses_remaining = clampi(3 - get_property_int("_sourceTerminalPortscanUses"), 0, 3);
	button_data["Educate"].listAppend(SourceTerminalButtonDisplayMake("images/itemimages/plug.gif", "Portscan", my_path_id() == PATH_THE_SOURCE ? "Lures Source Agent" : "Lures Government Agent", (portscan_uses_remaining > 0 ? pluralise(portscan_uses_remaining, "more use", "uses remaining") : ""), active_skills[$skill[portscan]], portscan_uses_remaining == 0));
	button_data["Educate"].listAppend(SourceTerminalButtonDisplayMake("images/itemimages/braces.gif", "Compress", "Damages monster", "", active_skills[$skill[compress]], false)); //reticle.gif
	//Enhance:
	boolean have_enhancements_remaining = __enhancements_remaining > 0;
	button_data["Enhance"].listAppend(SourceTerminalButtonDisplayMake("images/itemimages/potion9.gif", "Items", "+30% item", generateSourceTerminalEffectDescription($effect[items.enh]), false, !have_enhancements_remaining));
	button_data["Enhance"].listAppend(SourceTerminalButtonDisplayMake("images/itemimages/meat.gif", "Meat", "+60% meat", generateSourceTerminalEffectDescription($effect[meat.enh]), false, !have_enhancements_remaining));
	button_data["Enhance"].listAppend(SourceTerminalButtonDisplayMake("images/itemimages/fast.gif", "Init", "+50% init", generateSourceTerminalEffectDescription($effect[init.enh]), false, !have_enhancements_remaining));
	button_data["Enhance"].listAppend(SourceTerminalButtonDisplayMake("images/itemimages/fitposter.gif", "Substats", "+3 stats/fight", generateSourceTerminalEffectDescription($effect[substats.enh]), false, !have_enhancements_remaining));
	button_data["Enhance"].listAppend(SourceTerminalButtonDisplayMake("images/itemimages/reticle.gif", "Critical", "+10% critical/spell critical", generateSourceTerminalEffectDescription($effect[critical.enh]), false, !have_enhancements_remaining));
	button_data["Enhance"].listAppend(SourceTerminalButtonDisplayMake("images/itemimages/rrainbow.gif", "Damage", "+5 prismatic damage", generateSourceTerminalEffectDescription($effect[damage.enh]), false, !have_enhancements_remaining));
	//Extrude:
	int source_essence_available = $item[source essence].item_amount();
	boolean have_extrusions_remaining = __extrusions_remaining > 0;
	button_data["Extrude"].listAppend(SourceTerminalButtonDisplayMake("images/itemimages/browsercookie.gif", "Browser cookie", "Epic food", generateSourceTerminalItemDescription($item[browser cookie]), false, !have_extrusions_remaining || source_essence_available < 10, "10"));
	button_data["Extrude"].listAppend(SourceTerminalButtonDisplayMake("images/itemimages/martini.gif", "Hacked gibson", "Epic booze", generateSourceTerminalItemDescription($item[hacked gibson]), false, !have_extrusions_remaining || source_essence_available < 10, "10"));
	if ($item[source shades].available_amount() < 3 || __setting_test_all_extrusions)
		button_data["Extrude"].listAppend(SourceTerminalButtonDisplayMake("images/itemimages/morphshades.gif", "Source shades", "+10% item accessory", "Improves extractions", false, !have_extrusions_remaining || source_essence_available < 100, "100"));
	if (!(!can_interact() && source_essence_available < 10000) || __setting_test_all_extrusions)
		button_data["Extrude"].listAppend(SourceTerminalButtonDisplayMake("images/itemimages/softwarebug.gif", "Software bug", "Familiar", "", false, !have_extrusions_remaining || source_essence_available < 10000, "10k"));
	//FIXME all the chips, if we don't have them
	int [item] total_chips_wanted;
	total_chips_wanted[$item[source terminal GRAM chip]] = clampi(10 - get_property_int("sourceTerminalGram"), 0, 10);
	total_chips_wanted[$item[source terminal PRAM chip]] = clampi(10 - get_property_int("sourceTerminalPram"), 0, 10);
	total_chips_wanted[$item[source terminal SPAM chip]] = clampi(10 - get_property_int("sourceTerminalSpam"), 0, 10);
	if (!__chips["DRAM"] || __setting_test_all_extrusions)
		total_chips_wanted[$item[source terminal DRAM chip]] = 1;
	if (!__chips["CRAM"] || __setting_test_all_extrusions)
		total_chips_wanted[$item[source terminal CRAM chip]] = 1;
	if (!__chips["TRAM"] || __setting_test_all_extrusions)
		total_chips_wanted[$item[source terminal TRAM chip]] = 1;
	
	string [item] chip_descriptions;
	chip_descriptions[$item[source terminal GRAM chip]] = "Longer enquiries";
	chip_descriptions[$item[source terminal PRAM chip]] = "Longer enhancements";
	chip_descriptions[$item[source terminal SPAM chip]] = "Lower skill MP costs";
	chip_descriptions[$item[source terminal DRAM chip]] = "Two skills simultaneously";
	chip_descriptions[$item[source terminal CRAM chip]] = "+1 enhance buff";
	chip_descriptions[$item[source terminal TRAM chip]] = "+1 digitise";
	foreach chip, amount in total_chips_wanted
	{
		if (amount == 0 && __setting_test_all_extrusions)
			amount = 7;
		if (amount <= 0)
			continue;
		int remaining = MAX(0, amount - chip.available_amount());
		if (remaining <= 0)
			continue;
		int essence_needed = 100;
		if ($items[source terminal CRAM chip,source terminal DRAM chip,source terminal TRAM chip] contains chip)
			essence_needed = 1000;
		
		string name = chip;
		name = name.replace_string("Source terminal", "");
		name = name.replace_string("chip", "");
			
		string secondary_description;
		if (remaining > 1)
			secondary_description = "Need " + remaining + " more";
		button_data["Extrude"].listAppend(SourceTerminalButtonDisplayMake("images/itemimages/ic.gif", name, chip_descriptions[chip], secondary_description, false, !have_extrusions_remaining || source_essence_available < essence_needed, essence_needed));
		
	}
	
	//Enquiry:
	string enquiry_set = get_property("sourceTerminalEnquiry");
	button_data["Enquiry"].listAppend(SourceTerminalButtonDisplayMake("images/itemimages/blackcat.gif", "Familiar", "+5 familiar weight", "", enquiry_set == "familiar.enq", false));
	button_data["Enquiry"].listAppend(SourceTerminalButtonDisplayMake("images/itemimages/skinknife.gif", "Monsters", "+25 monster level", "", enquiry_set == "monsters.enq", false));
	button_data["Enquiry"].listAppend(SourceTerminalButtonDisplayMake("images/itemimages/dna.gif", "Stats", "+100% all stats", "", enquiry_set == "stats.enq", false));
	button_data["Enquiry"].listAppend(SourceTerminalButtonDisplayMake("images/itemimages/elesphere.gif", "Protect", "+3 all resistance", "", enquiry_set == "protect.enq", false)); //fire.gif


	raw_html_to_add["Terminal"] = "&nbsp;";

	buffer result;
	
	foreach page_name in page_titles
	{
		string page_description = page_titles[page_name];
		string page_subdescription = page_subtitles[page_name];
		
		string container_style;
		if (page_name != "Educate" && true)
			container_style = "display:none;";
		string main_style = "background-color:" + __setting_second_level_colour + ";border-top-right-radius:10px;border-bottom-right-radius:10px;margin-left:33%;";
		if (page_name != "Educate")
			main_style += "border-top-left-radius:10px;";
		if (page_name != "Terminal")
			main_style += "border-bottom-left-radius:10px;";
		result.append(HTMLGenerateTagPrefix("div", mapMake("id", "right_" + page_name.to_lower_case(), "style", container_style)));
		result.append(HTMLGenerateTagPrefix("div", mapMake("style", main_style))); //display:flex;height:100%;
		string page_description_style = "font-size:18px;margin-left:auto;margin-left:auto; margin-right:auto;text-align:center;padding-top:10px;display:block;";
		//if (page_subdescription == "")
			//page_description_style += "padding-bottom:14px;";
		result.append(HTMLGenerateDivOfStyle(page_description, page_description_style));
		if (page_subdescription == "")
			page_subdescription = "&nbsp;";
		result.append(HTMLGenerateDivOfStyle(page_subdescription, "font-size:14px;margin-left:auto;margin-left:auto; margin-right:auto;text-align:center;display:block;color:#444444;height:14px;"));
		
		
		result.append(generatePageTable(page_name, button_data[page_name], true));
		result.append(generatePageTable(page_name, button_data[page_name], false));
		
		if (raw_html_to_add contains page_name)
			result.append(raw_html_to_add[page_name]);
		
		result.append("</div>");
		result.append("</div>");
	}
	
	
	return result;
}


void sourceTerminalInitialise()
{
    int enhancement_limit = 1;
    if (__chips["CRAM"]) //CRAM chip installed
        enhancement_limit += 1;
    if (__chips["SCRAM"]) //SCRAM chip installed
        enhancement_limit += 1;
    __enhancements_remaining = clampi(enhancement_limit - get_property_int("_sourceTerminalEnhanceUses"), 0, enhancement_limit);
    __extrusions_remaining = clampi(3 - get_property_int("_sourceTerminalExtrudes"), 0, 3);
    
    if (false)
    {
	    __extrusions_remaining = MAX(__extrusions_remaining, 1);
	    __enhancements_remaining = MAX(__enhancements_remaining, 2);
	}
}

buffer generateSourceTerminalCore(boolean include_main_container)
{
	sourceTerminalInitialise();
	buffer result;
	
	if (include_main_container)
	{
		//FIXME bad
		result.append("<script type=\"text/javascript\" src=\"Source_Terminal_GUI.js\"></script>");
		result.append("<style type=\"text/css\">");
		result.append("\n.left_button { display:table-cell;vertical-align:middle;padding-left:" + __setting_left_padding + ";padding-right:" + __setting_left_padding + "; cursor:pointer;cursor:hand; }");
		result.append("\n.left_button_highlighted { border-top-left-radius:10px;border-bottom-left-radius:10px;background-color:" + __setting_second_level_colour + ";}");
		result.append("\n.left_button_unhighlighted:hover { border-top-left-radius:10px;border-bottom-left-radius:10px;background-color:#CCCCCC; }");
		result.append("\n.right_button { display:table-cell;width:50%; border-radius:10px;border:2px;border-color:white;border-style:solid;}");
		result.append("\n.right_button_visible { background-color:white;text-align:center;vertical-align:middle;}");
		result.append("\n.right_button_compressed { width:33%; }");
		result.append("\n.right_button_highlighted { border-color:black;}");
		result.append("\n.right_button_clickable { cursor:pointer;cursor:hand; }");
		result.append("\n.right_button_clickable:hover { border-color:grey;}");
		result.append("\n.source_terminal_gui_terminal_return { position:absolute;z-index:2;left:450px;top:50px;font-size:24px;background-color:black;color:green;padding:10px;border-color:green;border-style:solid;border-width:1px;font-weight:bold; cursor:pointer;cursor:hand; visibility:hidden; font-family: 'FixedSys', monospace; }");
		result.append("\n.source_terminal_gui_terminal_return:hover { color:#00FF00; border-color:#00FF00;}");
		result.append("\n.source_terminal_gui_popup_container { position:absolute;left:50px;top:50px;z-index:2;font-family:Arial,Helvetica,sans-serif; width:500px;text-align:center;}");
		result.append("\n.source_terminal_gui_popup { background-color:white; background-image:url('images/source_terminal_gui/popup_background.png'); padding:5px; top:310px; position:absolute;margin-left:auto;margin-right:auto;left:0;right:0; border-width:1px; border-color:grey; border-style: solid; box-shadow: 0px 0px 5.0px grey; transition:opacity 1.0s linear;height:16px;font-size:14px;}"); //transition:opacity 1.0s linear;
	
		result.append("</style>");
		
		result.append(HTMLGenerateTagWrap("div", "GUI", mapMake("id", "source_terminal_gui_terminal_return", "class", "source_terminal_gui_terminal_return", "onclick", "deactivateTerminal()")));
		result.append(HTMLGenerateTagPrefix("div", mapMake("id", "source_terminal_gui_popup_container", "class", "source_terminal_gui_popup_container")));
		result.append("</div>");
		
        result.append(HTMLGenerateTagPrefix("img", mapMake("src", "images/source_terminal_gui/glyphs8.png", "id", "matrix_glyphs", "style", "display:none;")));
	
	
		result.append(HTMLGenerateTagPrefix("div", mapMake("style", "opacity:0;visibility:hidden;background:black;position:absolute;top:50px;left:50px;z-index:10;width:500px;height:350px;", "id", "matrix_canvas_holder", "onclick", "matrixCanvasStop();", "onmousemove", "matrixCanvasStop();")));
        result.append(HTMLGenerateTagWrap("canvas", "", mapMake("width", "1", "height", "1", "id", "matrix_canvas", "style", "")));
        result.append("</div>");
        
		result.append(HTMLGenerateTagPrefix("div", mapMake("id", "source_terminal_gui_main_container", "class", "source_terminal_gui_main_container", "onmousemove", "matrixCanvasStop();")));
		
	}
	
	
	
	
	
	
	result.append("<div style=\"height: 350px; width: 500px; text-align: left; padding: 0px;position: absolute;left: 50px;top: 50px;overflow: hidden; background-color:" + __setting_background_colour + ";border-radius:15px;font-family:Arial,Helvetica,sans-serif;\">");
	
	//Mid-90s compatibility:
	if (false)
		result.append(HTMLGenerateDivOfStyle(listMake("&nbsp;&nbsp;&nbsp;&nbsp;🍎", "File", "Edit", "View", "Label", "Special").listJoinComponents("&nbsp;&nbsp;&nbsp;&nbsp;"), "width:100%;background-color:white;position:absolute;top:0px;"));
	
	result.append(HTMLGenerateTagPrefix("div", mapMake("style", "width:" + (500 - __setting_surrounding_margin_width * 2) + "px; height:" + (350 - __setting_surrounding_margin_width * 2) + "px; margin:" + __setting_surrounding_margin_width + "px;")));
	
	result.append(generateSourceTerminalLeftSide());
	result.append(generateSourceTerminalRightSides());
	
	//result.append(HTMLGenerateTagWrap("div", "V " + __version, mapMake("style", "position:absolute;top:337px;left:460px;font-size:10px;color:grey;")));
	
	result.append("</div>");
	
	
	if (true)
	{
		//Noise GIF, removed:
		//result.append(HTMLGenerateTagPrefix("img", mapMake("src", "images/source_terminal_gui/noise.gif", "width", "500", "height", "350", "style", "position:absolute;mix-blend-mode:multiply;top:0px;left:0px;opacity:0.05;pointer-events: none;")));
		//result.append(HTMLGenerateTagPrefix("img", mapMake("src", "images/source_terminal_gui/noise_alternate.gif", "width", "500", "height", "350", "style", "position:absolute;mix-blend-mode:multiply;top:0px;left:0px;opacity:0.03;pointer-events: none;")));
		
		/*result.append(HTMLGenerateTagPrefix("img", mapMake("src", "images/source_terminal_gui/multiply_overlay.png", "width", "500", "height", "350", "style", "position:absolute;mix-blend-mode:multiply;top:0px;left:0px;pointer-events: none;", "id", "source_terminal_gui_overlay"))); //;z-index:11;
		result.append(HTMLGenerateTagPrefix("img", mapMake("src", "images/source_terminal_gui/multiply_overlay_alternate.png", "width", "500", "height", "350", "style", "position:absolute;top:0px;left:0px;pointer-events: none;visibility:hidden;", "id", "source_terminal_gui_overlay_alternate"))); //;z-index:11;*/
		result.append(HTMLGenerateTagPrefix("img", mapMake("src", "images/source_terminal_gui/multiply_overlay_alternate.png", "width", "500", "height", "350", "style", "position:absolute;top:0px;left:0px;pointer-events: none;z-index:11;", "id", "source_terminal_gui_overlay_alternate"))); //;z-index:11;
	}
	result.append("</div>");
	
	if (include_main_container)
		result.append("</div>");
	return result;
}

void handleSourceTerminalChoiceOverride(string page_text)
{
	if (!__setting_enabled)
	{
		write(page_text);
		return;
	}
	
	sourceTerminalGUICheckForUpdates();
	buffer page_text_out;
	
	page_text_out.append(page_text);
	//page_text_out = page_text_out.replace_string("#term {", "#term {display:none;");
	//page_text_out = page_text_out.replace_string("#term {", "#term { -webkit-filter:brightness(1.01);");
	
	buffer core_addition = generateSourceTerminalCore(true);
	page_text_out = page_text_out.replace_string("<div id=\"term\">", core_addition.to_string() + "<div id=\"term\" style=\"visibility:hidden;\">");
	page_text_out = page_text_out.replace_string("bgcolor=blue><b>Source Terminal</b></td>", "bgcolor=blue><b>Source Terminal GUI v" + __version + "</b></td>");
	page_text_out = page_text_out.replace_string("$('#text').text('');", "$('#text').text(''); objDiv.style.visibility = 'visible';"); //HACK: reset visibility when they execute a command
	//This is due to using visibility to hide the regular terminal.
	//We could also use z-index, which we've tried, but it has side effects that require managing.
	string extra_javascript_commands = "var input_value = $('#input').val(); if (input_value == 'startx' || input_value == 'win' || input_value == 'gui') { e.preventDefault(); $('#text').text(''); $('#input').val(''); deactivateTerminal(); return; }";
	page_text_out = page_text_out.replace_string("$('form').submit(function () {", "$('form').submit(function (e) {");
	page_text_out = page_text_out.replace_string("if ($('#input').val() == 'exit') { document.location = '/campground.php'; return;  } ", "if ($('#input').val() == 'exit') { document.location = '/campground.php'; return;  } " + extra_javascript_commands);
	
	page_text_out = page_text_out.replace_string("<body", "<body onload=\"sourceTerminalGUILoad()\"");
	
	write("<!DOCTYPE html>"); //prevent IE8 from running in compability mode, desire HTML5
	write(page_text_out);
}

string removeHTMLFromText(string text)
{
	buffer out;
	//absolute minimum-effort implementation:
	//in the future, use substr and index_of?
	boolean within_tag = false;
	
	for i from 0 to text.length() - 1
	{
		string c = text.char_at(i);
		
		if (c == "<")
			within_tag = true;
		else if (c == ">")
			within_tag = false;
		else if (!within_tag)
			out.append(c);
	}
	return out;
}

void handleButtonClicked(string page_name, string button_title)
{
	//print_html("page_name = " + page_name + " button_title = " + button_title);
	
	//Execute the command, then write out the core:
	string terminal_command;
	boolean should_refresh = false;
	if (page_name == "Educate")
	{
		string skill_to_learn;
		if ($strings[Extract,Turbo,Duplicate,Portscan,Compress] contains button_title)
			skill_to_learn = button_title.to_lower_case() + ".edu";
		else if (button_title == "Digitise")
			skill_to_learn = "digitize.edu";
		if (skill_to_learn != "")
			terminal_command = "educate " + skill_to_learn;
	}
	else if (page_name == "Enquiry")
	{
		string target;
		if ($strings[Familiar,Monsters,Stats,Protect] contains button_title)
			target = button_title.to_lower_case() + ".enq";
		if (target != "")
			terminal_command = "enquiry " + target;
	}
	else if (page_name == "Enhance")
	{
		//enhance!
		string target;
		if ($strings[Items,Meat,Init,Substats,Critical,Damage] contains button_title)
			target = button_title.to_lower_case() + ".enh";
		if (target != "")
		{
			terminal_command = "enhance " + target;
			should_refresh = true;
		}
	}
	else if (page_name == "Extrude")
	{
		string [string] file_name_for_input;
		file_name_for_input["Browser cookie"] = "food.ext";
		file_name_for_input["Hacked gibson"] = "booze.ext";
		file_name_for_input["Source shades"] = "goggles.ext";
		file_name_for_input["GRAM"] = "gram.ext";
		file_name_for_input["PRAM"] = "pram.ext";
		file_name_for_input["SPAM"] = "spam.ext";
		file_name_for_input["CRAM"] = "cram.ext";
		file_name_for_input["DRAM"] = "dram.ext";
		file_name_for_input["TRAM"] = "tram.ext";
		file_name_for_input["Software bug"] = "familiar.ext";
		if (file_name_for_input contains button_title)
		{
			terminal_command = "extrude -f " + file_name_for_input[button_title];
		}
	}
	
	string [string] response;
	
	if (terminal_command != "")
	{
		//print_html("terminal_command = " + terminal_command);
		
		buffer terminal_text = visit_url("choice.php?whichchoice=1191&option=1&input=" + terminal_command + "&pwd=" + my_hash());
		if (!terminal_text.contains_text("<b>Source Terminal</b>")) //they've left the choice adventure - reload it, and resubmit
		{
			visit_url("campground.php?action=terminal");
			terminal_text = visit_url("choice.php?whichchoice=1191&option=1&input=" + terminal_command + "&pwd=" + my_hash());
		}
		//Parse terminal text:
		//<div id="term">
		//<br>
		string [int][int] match_level_1 = terminal_text.group_string("<div id=\\\"term\\\">(.*)<br />");
		string [int][int] match_level_2 = match_level_1[0][1].group_string("<div>(.*?)</div>");
		//print_html("match_level_2 = " + match_level_2.to_json().entity_encode());
		
		if (false)
		{
			foreach key in match_level_2
			{
				string event = match_level_2[key][1];
				if (event == "")
					continue;
				print_html("match_level_2[" + key + "] = " + event.entity_encode());
			}
		}
		
		string latest_terminal_result = "";
		if (match_level_2.count() >= 2)
			latest_terminal_result = match_level_2[match_level_2.count() - 2][1];
			
			
		//latest_terminal_result = "You acquire an effect: init.enh (duration: 100 Adventures)";
		//latest_terminal_result = "You acquire an item: <a href=\"#\" style=\"text-decoration: none; font-weight: bold\" onclick=\"descitem(484716153)\">hacked gibson</a>";
			
		latest_terminal_result = removeHTMLFromText(latest_terminal_result);
		//print_html("latest_terminal_result = \"" + latest_terminal_result.entity_encode() + "\"");
		
		
		//You acquire an effect: init.enh (duration: 100 Adventures)
		//You acquire an effect: items.enh (duration: 100 Adventures)
		//You acquire an effect: meat.enh (duration: 100 Adventures)
		//You acquire an item: <a href="#" style="text-decoration: none; font-weight: bold" onclick="descitem(484716153)">hacked gibson</a>
		if (latest_terminal_result.contains_text("You acquire an item: "))
		{
			latest_terminal_result = latest_terminal_result.replace_string("You acquire an item: ", "");
			latest_terminal_result = "+1 " + latest_terminal_result;
		}
		else if (latest_terminal_result.contains_text("You acquire an effect: "))
		{
			//latest_terminal_result = latest_terminal_result.replace_string("You acquire an effect: ", ""));
			string [int][int] effect_match = latest_terminal_result.group_string("You acquire an effect: (.*) \\(duration: ([0-9]*) Adv");
			//print_html("effect_match = " + effect_match.to_json());
			if (effect_match[0].count() == 3)
			{
				//latest_terminal_result = "+" + effect_match[0][2] + " turns of " + effect_match[0][1];
				latest_terminal_result = "Gained " + effect_match[0][1] + " (" + effect_match[0][2] + " turns)";
			}
			//latest_terminal_result = latest_terminal_result;
		}
		
		boolean reject_output = false;
		if (page_name == "Educate" && latest_terminal_result.contains_text("active skills: ")) //active skills: blahblah, extract.edu
			reject_output = true;
		if (page_name == "Enquiry" && latest_terminal_result.contains_text("enquiry mode set: ")) //enquiry mode set: familiar.enq
			reject_output = true;
		
		string popup_text;
		popup_text = latest_terminal_result;
		
		if (!reject_output)
			response["popup result"] = popup_text;
		
		if (should_refresh)
			refresh_status();
	}
	
	buffer core_text = generateSourceTerminalCore(false);
	
	response["core html"] = core_text;
	
	write(response.to_json());
}

void handleRefresh()
{
	string [string] response;
	buffer core_text = generateSourceTerminalCore(false);
	
	response["core html"] = core_text;
	
	write(response.to_json());
	
}

void handleRelayRequest(string [string] form_fields)
{
	string type = form_fields["type"];
	if (type == "button_clicked")
	{
		handleButtonClicked(form_fields["page_name"], form_fields["button_title"]);
	}
	else if (type == "refresh")
	{
		handleRefresh();
	}
}

void main()
{
	//We are only called by our javascript querying via XMLHTTPRequest; choice.ash calls one of our functions directly.
	string [string] form_fields = form_fields();
	if (form_fields.count() > 0)
	{
		handleRelayRequest(form_fields);
	}
}