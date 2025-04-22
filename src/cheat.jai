#load "abiotic_factor.jai";
#load "ale_and_tale.jai";
#load "supermarket_together.jai";
#load "repo.jai";

Game_Name :: enum u32
{
    Abiotic_Factor;
    Ale_and_Tale;
    Supermarket_Together;
    Repo;
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
    ale_and_tale: Ale_and_Tale;
    spt: Supermarket_Together;
    repo: Repo;
}

init_cheat :: (cheat: *Cheat)
{
    table_add(*cheat.exe_name_table, .Abiotic_Factor, ABIOTIC_FACTOR_EXE_NAME);
    table_add(*cheat.exe_name_table, .Ale_and_Tale, ALE_AND_TALE_EXE_NAME);
    table_add(*cheat.exe_name_table, .Supermarket_Together, SUPERMARKET_EXE_NAME);
    table_add(*cheat.exe_name_table, .Repo, REPO_EXE_NAME);
}

