REPO_EXE_NAME :: "REPO.exe";
REPO_MODULE_NAME :: "UnityPlayer.dll";

Repo :: struct
{
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

    unlimited_stamina: bool;
    unlimited_hp: bool;
    unlimited_jumps: bool;

    money_addr: *u64;
    stamina_addr: *u64;
    max_stamina_addr: *u64;
    hp_addr: *u64;
    max_hp_addr: *u64;
    strength_addr: *u64;
    range_addr: *u64;
    sprint_speed_addr: *u64;
    extra_jumps_addr: *u64;

    position_addr: [3] *u64;

    tp_data: Teleport_Data;
}

//money_offset :: 0x2DB5C;
/* NOTES:
- extra jump offset from sprintspeed: 0x58
- strength offset from range: 0x10C
*/

init_repo_cheat :: (using cheat: *Repo, game: Process_Attach)
{
    money_addr = get_dynamic_memory_allocation_addr
    (
        game, 0x01C1DF80, 
        u32.[0xFC8, 0xAC8, 0x520, 0x68, 0x158, 0x48]
    );

    stamina_addr = get_dynamic_memory_allocation_addr
    (
        game, 0x01D20A78, 
        u32.[0x50, 0xD0, 0x8, 0x1B8, 0x4C4, 0x0, 0x194]
    );

    hp_addr = get_dynamic_memory_allocation_addr
    (
        game, 0x01C1FF00, 
        u32.[0x178, 0xA00, 0x60, 0xAC]
    );

    max_hp_addr = xx (cast(*u8)hp_addr + 0x8);

    position_addr[1] = get_dynamic_memory_allocation_addr
    (
        game, 0x01D1F4D8,
        u32.[0x1D0, 0xF80, 0xCD0, 0x960, 0x0, 0x154]
    );
    position_addr[0] = cast(*u64)(cast(*u8)position_addr[1]-4);
    position_addr[2] = cast(*u64)(cast(*u8)position_addr[1]+4);

    max_stamina_addr = cast(*u64)(cast(*u8)stamina_addr-4);

    sprint_speed_addr = get_dynamic_memory_allocation_addr
    (
        game, 0x01D014A8,
        u32.[0xD40, 0x3B0, 0x3E0, 0xD8, 0x38, 0x110]
    );

    extra_jumps_addr = cast(*u64)(cast(*u8)sprint_speed_addr+0x58);

    range_addr = get_dynamic_memory_allocation_addr
    (
        game, 0x01D056B8,
        u32.[0x0, 0x18, 0xA50, 0x6B8, 0x270, 0x110]
    );

    strength_addr = cast(*u64)(cast(*u8)range_addr+0x10C);
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

    position = Vector3.{xx pos_x, xx pos_y, xx pos_z};

    ImGui.Text("Teleport");
    ImGui.Text("(%, %, %)", cast(int)position.x, cast(int)position.y, cast(int)position.z);
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
        read_value(game, max_stamina_addr, *max_stamina);
        //print("MAX_STAMINA: %\n", max_stamina);
        write_value(game, stamina_addr, *max_stamina);
    }

    if ImGui.Checkbox("Unlimited HP", *unlimited_hp)
    {
        if unlimited_hp
        {
            read_value(game, hp_addr, *saved_hp);
            read_value(game, max_hp_addr, *saved_max_hp);
        }
        else
        {
            write_value(game, hp_addr, *saved_hp);
            write_value(game, max_hp_addr, *saved_max_hp);
        }
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

    if unlimited_hp
    {
        temp_hp: s32 = 9999;
        write_value(game, hp_addr, *temp_hp);
        write_value(game, max_hp_addr, *temp_hp);
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
    if ImGui.SliderFloat("Edit Sprint speed", *sprint_speed, 5, 100, "%.0f")
    {
        write_value(game, repo.sprint_speed_addr, *sprint_speed);
    }
    ImGui.PopItemWidth();
}

repo_cheat_ui :: (repo: *Repo, game: Process_Attach)
{
    //Keep recalculating dynamic address so you dont have to relaunch every time when you start a new game or loading another save
    init_repo_cheat(repo, game);

    repo_checkbox_cheats(repo, game);

    repo_edit_hp(repo, game);

    repo_edit_money(repo, game);

    repo_slider_cheats(repo, game);

    repo_tp_menu(repo, game);
}