REPO_EXE_NAME :: "REPO.exe";
REPO_MODULE_NAME :: "UnityPlayer.dll";

Repo :: struct
{
    money: s32;
    hp: s32;
    saved_hp: s32;
    stamina: float32;
    max_stamina: float32;

    unlimited_stamina: bool;
    unlimited_hp: bool;

    money_addr: *u64;
    stamina_addr: *u64;
    max_stamina_addr: *u64;
    hp_addr: *u64;
}

//money_offset :: 0x2DB5C;

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

    max_stamina_addr = cast(*u64)(cast(*u8)stamina_addr-4);

}

repo_cheat_ui :: (repo: *Repo, game: Process_Attach)
{
    ImGui.Checkbox("Unlimited Stamina", *repo.unlimited_stamina);
    if repo.unlimited_stamina
    {
        read_value(game, repo.max_stamina_addr, *repo.max_stamina);
        print("MAX_STAMINA: %\n", repo.max_stamina);
        write_value(game, repo.stamina_addr, *repo.max_stamina);
    }

    if ImGui.Checkbox("Unlimited HP", *repo.unlimited_hp)
    {
        if repo.unlimited_hp
        {
            read_value(game, repo.hp_addr, *repo.saved_hp);
        }
        else
        {
            write_value(game, repo.hp_addr, *repo.saved_hp);
        }
    }

    if repo.unlimited_hp
    {
        temp_hp: s32 = 9999;
        write_value(game, repo.hp_addr, *temp_hp);
    }

    read_value(game, repo.hp_addr, *repo.hp);
    ImGui.PushItemWidth(100);
    step: u32 = 10;
    if ImGui.InputScalar("Edit HP", ImGui.DataType.S32, *repo.hp, cast(*void)*step, cast(*void)*step)
    {
        write_value(game, repo.hp_addr, *repo.hp);
    }
    ImGui.PopItemWidth();

    /*
    */
    read_value(game, repo.money_addr, *repo.money);
    ImGui.PushItemWidth(100);
    step = 5;
    if ImGui.InputScalar("Edit Money", ImGui.DataType.S32, *repo.money, cast(*void)*step, cast(*void)*step)
    {
        write_value(game, repo.money_addr, *repo.money);
    }
    ImGui.PopItemWidth();
}