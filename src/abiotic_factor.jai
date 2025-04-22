ABIOTIC_FACTOR_EXE_NAME :: "AbioticFactor-Win64-Shipping.exe";

Abiotic_Factor :: struct
{
    item_count: u32;
    unlimited_stamina: bool;

    slot1_battery: u32;
    unlimited_battery: bool;
    mem_addr: Table(string, *u64);

    tp_data: Teleport_Data;
}

//Z axis offset: 0x1B9B9A0

init_abf_cheat :: (using abf: *Abiotic_Factor, game: Process_Attach)
{
    hotbar_slot1_addr := get_dynamic_memory_allocation_addr(game, 0x0847F600, u32.[0x1E8, 0x30, 0xEF8, 0x280, 0x90, 0x370, 0x30]);

    stamina_addr := get_dynamic_memory_allocation_addr(game, 0x074AEF68, u32.[0, 0x20, 0x278, 0x1C8, 0xB0, 0x90, 0x8A4]);

    zaxis_addr := get_dynamic_memory_allocation_addr(game, 0x0849F0B8, u32.[0x50, 0x2D8, 0xF60, 0x1F0, 0x450, 0xB8, 0x200]);

    table_add(*mem_addr, "hotbar_slot1", hotbar_slot1_addr);
    table_add(*mem_addr, "stamina", stamina_addr);
    table_add(*mem_addr, "zpos", zaxis_addr);
}

abf_cheat_ui :: (abf: *Abiotic_Factor, game: Process_Attach)
{
    hotbar_slot1_input(abf, game);
    ImGui.NewLine();
    ImGui.Separator();
    teleport_menu(abf, game);
/*
    checkbox_cheat(abf, game);
    ImGui.NewLine();
    ImGui.Separator();
*/
}

hotbar_slot1_input :: (using abf: *Abiotic_Factor, game: Process_Attach)
{
    addr, found := table_find(*abf.mem_addr, "hotbar_slot1");
    if found
    {
        hotbar_slot_item_count: u32;
        read_value(game, addr, *hotbar_slot_item_count);
        //ImGui.Text("Item Count: %", hotbar_slot_item_count);
        new_hotbar_slot1_count: u32 = hotbar_slot_item_count;
        step: u32 = 1;
        ImGui.Text("Hotbar Slot 1 Settings");
        ImGui.PushItemWidth(100);
        if ImGui.InputScalar("Item Count", ImGui.DataType.U32, *new_hotbar_slot1_count, cast(*void)*step, cast(*void)*step)
        {
            write_value(game, addr, *new_hotbar_slot1_count);
        }
        ImGui.PopItemWidth();
        //TODO: Probably better to store these magic numbers lol
        if ImGui.Button("Max Durability/Decay")
        {
            durability_decay_addr := cast(*u8)addr - 0x10;
            max_dura_decay_addr := cast(*u8)addr - 0x8;
            max_value: float64; 
            read_value(game, xx max_dura_decay_addr, *max_value);
            write_value(game, xx durability_decay_addr, *max_value);
        }
        if ImGui.Checkbox("Unlimited battery", *unlimited_battery)
        {
            battery_addr := cast(*u8)addr + 0x8;
            read_value(game, xx battery_addr, *slot1_battery);
            if slot1_battery == 0 then slot1_battery = 5;
        }
        if unlimited_battery
        {
            battery_addr := cast(*u8)addr + 0x8;
            write_value(game, xx battery_addr, *slot1_battery);
        }

    }
}
checkbox_cheat :: (using abf: *Abiotic_Factor, game: Process_Attach)
{
    max_stamina: float64 = 412325249024;
    addr, found := table_find(*mem_addr, "stamina");
    if found 
    {
        ImGui.Text("Player");
        ImGui.Checkbox("Unlimited Stamina", *unlimited_stamina);
        if unlimited_stamina
        {
            write_value(game, addr, *max_stamina);
        }
    }
}

get_player_position :: (abf: *Abiotic_Factor, game: Process_Attach) -> Vector3
{
    position: Vector3;
    addr, found := table_find(*abf.mem_addr, "zpos");
    if found
    {
        pos_z: float64;
        pos_x: float64;
        pos_y: float64;

        x_addr := cast(*u8)addr-16;
        y_addr := cast(*u8)addr-8;

        read_value(game, cast(*u64)addr, *pos_z);
        read_value(game, cast(*u64)x_addr, *pos_x);
        read_value(game, cast(*u64)y_addr, *pos_y);

        position = Vector3.{xx pos_x, xx pos_y, xx pos_z};
    }

    return position;
}

teleport_menu :: (abf: *Abiotic_Factor, game: Process_Attach)
{
    using abf.tp_data;
    player_position := get_player_position(abf, game);
    ImGui.Text("Teleport");
    ImGui.Text("(%, %, %)", cast(int)player_position.x, cast(int)player_position.y, cast(int)player_position.z);
    ImGui.SetNextItemWidth(200);
    ImGui.InputText("Name", location_name_text.data, location_name_text.count);
    if ImGui.Button("Add")
    {
        name := copy_string(cast(string)location_name_text);
        array_add(*saved_location_names, name);
        
        table_add(*saved_location, name, player_position);

        for location_name_text
        {
            location_name_text[it_index] = xx "";
        }
    }

    ImGui.SetNextItemWidth(150);
    ImGui.InputFloat3("Custom Coordinate", *custom_coordinate_tp);
    if ImGui.Button("Teleport##0")
    {
        addr, addr_found := table_find(*abf.mem_addr, "zpos");
        if addr_found
        {
            print("Teleporting to position: %\n", custom_coordinate_tp);
            pos_x: float64 = xx custom_coordinate_tp[0];
            pos_y: float64 = xx custom_coordinate_tp[1]; 
            pos_z: float64 = xx custom_coordinate_tp[2];

            x_addr := cast(*u8)addr-16;
            y_addr := cast(*u8)addr-8;

            write_value(game, addr, *pos_z);
            write_value(game, cast(*u64)x_addr, *pos_x);
            write_value(game, cast(*u64)y_addr, *pos_y);
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
                addr, addr_found := table_find(*abf.mem_addr, "zpos");
                if addr_found
                {
                    print("Teleporting to position: %\n", pos);
                    pos_z: float64 = xx (pos.z + 1.0);
                    pos_x: float64 = xx pos.x;
                    pos_y: float64 = xx pos.y; 

                    x_addr := cast(*u8)addr-16;
                    y_addr := cast(*u8)addr-8;

                    write_value(game, addr, *pos_z);
                    write_value(game, cast(*u64)x_addr, *pos_x);
                    write_value(game, cast(*u64)y_addr, *pos_y);
                }
            }
        }
    }
}