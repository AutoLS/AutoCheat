#load "abiotic_factor.jai";
#load "ale_and_tale.jai";
#load "supermarket_together.jai";
#load "repo.jai";
#load "slormancer.jai";

Game_Name :: enum u32
{
    Abiotic_Factor;
    Supermarket_Together;
    Repo;
    Slormancer;
}

Teleport_Data :: struct
{
    location_name_text: [128] u8;
    saved_location_names: [..] string;
    saved_location: Table(string, Vector3);
    selected_location_index: s32;
    custom_coordinate_tp: [3] float; 
}

Cheat :: struct
{
    game: Process_Attach;
    current_game: Game_Name = .Repo;
    exe_name_table: Table(Game_Name, string);

    abf: Abiotic_Factor;
    spt: Supermarket_Together;
    repo: Repo;
    slormancer: Slormancer_Cheat;
}

init_cheat :: (cheat: *Cheat)
{
    table_add(*cheat.exe_name_table, .Abiotic_Factor, ABIOTIC_FACTOR_EXE_NAME);
    table_add(*cheat.exe_name_table, .Supermarket_Together, SUPERMARKET_EXE_NAME);
    table_add(*cheat.exe_name_table, .Repo, REPO_EXE_NAME);
    table_add(*cheat.exe_name_table, .Slormancer, SLORMANCER_EXE_NAME);
}

cheat_input_scalar :: (game: Process_Attach, text: string, address: *u64, value: *$T, step: T, type: ImGui.DataType)
{
    read_value(game, address, value);
    ImGui.PushItemWidth(150);
    if ImGui.InputScalar(temp_c_string(text), type, value, cast(*void)*step, cast(*void)*step, "%.0f")
    {
        write_value(game, address, value);
    }
    ImGui.PopItemWidth();
}

