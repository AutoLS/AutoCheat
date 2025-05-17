SLORMANCER_EXE_NAME :: "The Slormancer.exe";

Slormancer_Cheat :: struct 
{
    gold: float64;
    slorm: float64;

    gold_addr: *u64;
    slorm_addr: *u64;
}

init_slormancer_cheat :: (using cheat: *Slormancer_Cheat, game: Process_Attach)
{
    gold_addr = get_dynamic_memory_allocation_addr(
        game, 0x01E35718, u32.[0x48, 0x10, 0x400, 0xD0]
    );

    slorm_addr = get_dynamic_memory_allocation_addr(
        game, 0x01E3B988, u32.[0x48, 0x18, 0xF90, 0x0]
    );
}

slormancer_cheat_ui :: (using cheat: *Slormancer_Cheat, game: Process_Attach)
{
    cheat_input_scalar(game, "Edit Gold", gold_addr, *gold, 1000.0, ImGui.DataType.Double);
    cheat_input_scalar(game, "Edit Slorm", slorm_addr, *slorm, 1000.0, ImGui.DataType.Double);
}  