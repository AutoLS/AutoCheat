REPO_EXE_NAME :: "REPO.exe";
REPO_MODULE_NAME :: "UnityPlayer.dll";

Repo :: struct
{
    found_base_address: bool;

    money: s32;
    hp: s32;
    max_hp: s32;
    saved_hp: s32;
    saved_max_hp: s32;
    jumps: s32;
    stamina: float32;
    max_stamina: float32;
    strength: float = 1.0;
    range: float = 2.5;
    sprint_speed: float = 5.0;
    gravity: float = 30.0;

    unlimited_stamina: bool;
    god_mode: bool;
    unlimited_jumps: bool;
    disable_overcharge: bool;

    money_addr: *u64;
    stamina_addr: *u64;
    max_stamina_addr: *u64;
    gravity_addr: *u64;
    hp_addr: *u64;
    hp_prev_addr: *u64;
    max_hp_addr: *u64;
    strength_addr: *u64;
    range_addr: *u64;
    sprint_speed_addr: *u64;
    extra_jumps_addr: *u64;
    god_mode_addr: *u64;
    disable_overcharge_addr: *u64;

    position_addr: [3] *u64;

    tp_data: Teleport_Data;
}

/* 
PlayerController: 
0x110 - SprintSpeed
0x168 - JumpExtra
0x174 - Gravity
0x194 - Stamina
0x199 - DisableOvercharge

PhysGrabber:
0x118 - grabRange
0x230 - grabStrength

Inventory: 
0x20 - InventorySpots
    0x20 - Item[0]
    0x28 - Item[1]

ItemBattery:RemoveFullBar+3b - 48 63 47 74           - movsxd  rax,dword ptr [rdi+74] (729040739)
ItemBattery:RemoveFullBar+3f - 2B 45 F0              - sub eax,[rbp-10]
*/

init_repo_cheat :: (using cheat: *Repo, game: Process_Attach)
{
    money_addr = get_dynamic_memory_allocation_addr
    (
        game, 0x01D1F7A8, 
        u32.[0x158, 0x80, 0x978, 0x48]
    );

    hp_addr = get_dynamic_memory_allocation_addr
    (
        game, 0x01C28DC0, 
        u32.[0x78, 0x9E0, 0x68, 0xB4]
    );

    hp_prev_addr = get_address_with_offset(hp_addr, 0x4);
    max_hp_addr = get_address_with_offset(hp_addr, 0x8);
    god_mode_addr = get_address_with_offset(hp_addr, 0xC);

    position_addr[1] = get_dynamic_memory_allocation_addr
    (
        game, 0x01D1F4D8,
        u32.[0x1D0, 0xF80, 0xCD0, 0x960, 0x0, 0x154]
    );
    position_addr[0] = get_address_with_offset(position_addr[1], -4);
    position_addr[2] = get_address_with_offset(position_addr[1], 4);

    sprint_speed_addr = get_dynamic_memory_allocation_addr
    (
        game, 0x01D002A8,
        u32.[0x640, 0x1A0, 0x300, 0x110]
    );

    stamina_addr = get_address_with_offset(sprint_speed_addr, 0x94);
    //max_stamina_addr = get_address_with_offset(stamina_addr, -0x4);
    extra_jumps_addr = get_address_with_offset(sprint_speed_addr, 0x58);
    gravity_addr = get_address_with_offset(sprint_speed_addr, 0x64);
    disable_overcharge_addr = get_address_with_offset(sprint_speed_addr, 0x89);

    range_addr = get_dynamic_memory_allocation_addr
    (
        game, 0x01CFFA88,
        u32.[0x3E0, 0xD10, 0x3F0, 0x118]
    );

    strength_addr = get_address_with_offset(range_addr, 0x118);

    // if !found_base_address
    // {
    //     mono, mono_size := get_module_base_addr(game.proc_id, "mono-2.0-bdwgc.dll");
    //     repo, repo_size := get_module_base_addr(game.proc_id, "REPO.exe");
    //     app, app_size := get_module_base_addr(game.proc_id, "steamclient64.dll");
    //     test := aob_scan_module(game.process, mono, mono_size, u8.[0x2B, 0x45, 0xF0]);
    //     found_base_address = true;
    // }
}

repo_tp_menu :: (using repo: *Repo, game: Process_Attach)
{
    using repo.tp_data;
    position: Vector3;
    pos_x: float32;
    pos_y: float32;
    pos_z: float32;

    read_value(game, position_addr[0], *pos_x);
    read_value(game, position_addr[1], *pos_y);
    read_value(game, position_addr[2], *pos_z);

    // temp_pos: Vector3;
    // temp_pos_addr: *u64 = xx 0x1E78ECEFEB0;
    // read_value(game, temp_pos_addr, *temp_pos);

    position = Vector3.{xx pos_x, xx pos_y, xx pos_z};

    position_previous_address := cast(*u64)(cast(*u8)sprint_speed_addr+0xb0);

    ImGui.Text("Teleport");
    ImGui.Text("(%, %, %)", cast(int)position.x, cast(int)position.y, cast(int)position.z);

    ImGui.SetNextItemWidth(150);
    ImGui.InputFloat3("Custom Coordinate", *custom_coordinate_tp);
    if ImGui.Button("Teleport##0")
    {
        print("Teleporting to position: %\n", custom_coordinate_tp);
        pos_x: float32 = xx custom_coordinate_tp[0];
        pos_y: float32 = xx custom_coordinate_tp[1]; 
        pos_z: float32 = xx custom_coordinate_tp[2];

        write_value(game, position_previous_address, *pos_x);
        write_value(game, xx (cast(*u8)position_previous_address+4), *pos_y);
        write_value(game, xx (cast(*u8)position_previous_address+8), *pos_z);

        write_value(game, position_addr[0], *pos_x);
        write_value(game, position_addr[1], *pos_y);
        write_value(game, position_addr[2], *pos_z);
    }

    ImGui.SetNextItemWidth(200);
    ImGui.InputText("Name", location_name_text.data, location_name_text.count);
    if ImGui.IsItemHovered() 
    {
        ImGui.BeginTooltip();
        ImGui.PushTextWrapPos(400);
        ImGui.TextUnformatted("Add your current location into teleport list to teleport.");
        ImGui.PopTextWrapPos();
        ImGui.EndTooltip();
    }
    if ImGui.Button("Add")
    {
        name := copy_string(cast(string)location_name_text);
        array_add(*saved_location_names, name);
        
        table_add(*saved_location, name, position);

        for location_name_text
        {
            location_name_text[it_index] = xx "";
        }
    }

    location_names: [..] *u8;
    location_names.allocator = temp;

    for saved_location_names array_add(*location_names, to_c_string(it));

    ImGui.SetNextItemWidth(200);
    if location_names.count > 0
    {
        combo_box("Locations", location_names, *selected_location_index);
        if ImGui.Button("Teleport##1")
        {
            pos, found := table_find(*saved_location, saved_location_names[selected_location_index]);
            if found
            {
                print("Teleporting to position: %\n", pos);
                pos_x: float32 = xx pos.x;
                pos_y: float32 = xx pos.y; 
                pos_z: float32 = xx pos.z;

                write_value(game, position_previous_address, *pos_x);
                write_value(game, xx (cast(*u8)position_previous_address+4), *pos_y);
                write_value(game, xx (cast(*u8)position_previous_address+8), *pos_z);


                write_value(game, position_addr[0], *pos_x);
                write_value(game, position_addr[1], *pos_y);
                write_value(game, position_addr[2], *pos_z);
            }
        }
        if ImGui.IsItemHovered() 
        {
            ImGui.BeginTooltip();
            ImGui.PushTextWrapPos(400);
            ImGui.TextUnformatted("You may have to click few times for it to work.");
            ImGui.PopTextWrapPos();
            ImGui.EndTooltip();
        }
    }
}

repo_checkbox_cheats :: (using repo: *Repo, game: Process_Attach)
{
    ImGui.Checkbox("Unlimited Stamina", *unlimited_stamina);
    if unlimited_stamina
    {
        value: float32 = -1;
        write_value(game, stamina_addr, *value);
    }

    ImGui.Checkbox("God Mode", *god_mode);

    if god_mode
    {
        write_value(game, god_mode_addr, *god_mode);    
    }

    ImGui.Checkbox("Disable Overcharge Meter", *disable_overcharge);

    if disable_overcharge
    {
        write_value(game, disable_overcharge_addr, *disable_overcharge);    
    }

    if ImGui.Checkbox("Unlimited Jumps", *unlimited_jumps)
    {
        if unlimited_jumps
        {
            read_value(game, extra_jumps_addr, *jumps);
        }
        else
        {
            write_value(game, extra_jumps_addr, *jumps);
        }
    }

    if unlimited_jumps
    {
        temp_jumps: s32 = 999;
        write_value(game, extra_jumps_addr, *temp_jumps);
    }
}

repo_edit_hp :: (repo: *Repo, game: Process_Attach)
{
    read_value(game, repo.hp_addr, *repo.hp);
    ImGui.PushItemWidth(100);
    step: u32 = 10;
    if ImGui.InputScalar("Edit HP", ImGui.DataType.S32, *repo.hp, cast(*void)*step, cast(*void)*step)
    {
        write_value(game, repo.hp_addr, *repo.hp);
        write_value(game, repo.hp_prev_addr, *repo.hp);
    }
    ImGui.PopItemWidth();

    read_value(game, repo.max_hp_addr, *repo.max_hp);
    ImGui.PushItemWidth(100);
    if ImGui.InputScalar("Edit Max HP", ImGui.DataType.S32, *repo.max_hp, cast(*void)*step, cast(*void)*step)
    {
        write_value(game, repo.max_hp_addr, *repo.max_hp);
    }
    ImGui.PopItemWidth();
}

repo_edit_money :: (repo: *Repo, game: Process_Attach)
{
    read_value(game, repo.money_addr, *repo.money);
    ImGui.PushItemWidth(100);
    step: u32 = 5;
    if ImGui.InputScalar("Edit Money", ImGui.DataType.S32, *repo.money, cast(*void)*step, cast(*void)*step)
    {
        write_value(game, repo.money_addr, *repo.money);
    }
    ImGui.PopItemWidth();
}

repo_slider_cheats :: (using repo: *Repo, game: Process_Attach)
{
    read_value(game, repo.range_addr, *range);
    ImGui.PushItemWidth(200);
    if ImGui.SliderFloat("Edit Range", *range, 2.5, 100, "%.1f")
    {
        write_value(game, repo.range_addr, *range);
    }
    ImGui.PopItemWidth();

    read_value(game, repo.strength_addr, *strength);
    ImGui.PushItemWidth(200);
    if ImGui.SliderFloat("Edit Strength", *strength, 1, 10, "%.1f")
    {
        write_value(game, repo.strength_addr, *strength);
    }
    ImGui.PopItemWidth();

    read_value(game, repo.sprint_speed_addr, *sprint_speed);
    ImGui.PushItemWidth(200);
    if ImGui.SliderFloat("Edit Sprint Speed", *sprint_speed, 5, 100, "%.0f")
    {
        write_value(game, repo.sprint_speed_addr, *sprint_speed);
    }
    ImGui.PopItemWidth();

    read_value(game, repo.gravity_addr, *gravity);
    ImGui.PushItemWidth(200);
    if ImGui.SliderFloat("Edit Gravity", *gravity, -30, 30, "%.0f")
    {
        write_value(game, repo.gravity_addr, *gravity);
    }
    ImGui.PopItemWidth();
}

repo_cheat_ui :: (repo: *Repo, game: Process_Attach)
{
    //Keep recalculating dynamic address so you dont have to relaunch every time when you start a new game or loading another save
    init_repo_cheat(repo, game);

    ImGui.BeginChild("Repo", .{385, 365}, true, IMGUI_WINDOW_FLAGS.AlwaysVerticalScrollbar);

    repo_checkbox_cheats(repo, game);

    repo_edit_hp(repo, game);

    repo_edit_money(repo, game);

    repo_slider_cheats(repo, game);

    repo_tp_menu(repo, game);

    ImGui.EndChild();
}