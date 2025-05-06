TH32CS_SNAPPROCESS :: 0x00000002;
TH32CS_SNAPMODULE :: 0x00000008;
TH32CS_SNAPMODULE32 :: 0x00000010;

PROCESS_ALL_ACCESS :: 0x000F0000 | 0x00100000 | 0xFFFF;

Process_Attach :: struct
{
    proc_id: DWORD;
    process: HANDLE;
    base_addr: *u64;

    name: string;
    module_name: string;
    module_size: u64;
    attached: bool;

    cheat_dll: *void = null;
    dll_thread: HANDLE;
}

attach_process :: (game: *Process_Attach, name: string, module_name: string, dll_path: string = "")
{
    if game.process
    {
        CloseHandle(game.process);
    }

    if game.cheat_dll != null && game.proc_id != 0
    {
        VirtualFreeEx(game.process, game.cheat_dll, 0, MEM_RELEASE);
        CloseHandle(game.dll_thread);
    }

    game.name = name;
    game.module_name = module_name;
    game.proc_id = get_process_id(name);

    if game.proc_id != 0
    {
        game.process = OpenProcess(PROCESS_ALL_ACCESS, 0, game.proc_id);
        if game.process
        {
            get_module_base_addr(game);
            game.attached = true;
            print("FOUND: %, ID: %\n", name, game.proc_id);
            print("Process Attached.\n");

            if dll_path != ""
            {
                game.cheat_dll = VirtualAllocEx(game.process, null, xx (dll_path.count+1), MEM_COMMIT, PAGE_READWRITE);

                if game.cheat_dll != null
                {
                    WriteProcessMemory(game.process, game.cheat_dll, temp_c_string(dll_path), xx (dll_path.count+1), null);

                    kernel32base := GetModuleHandleA(temp_c_string("kernel32.dll"));
                    game.dll_thread = CreateRemoteThread(game.process, null, 0, GetProcAddress(kernel32base, "LoadLibraryA"), game.cheat_dll, 0, null);

                    exit_code: u32;
                    WaitForSingleObject(game.dll_thread, INFINITE);
                    GetExitCodeProcess(game.dll_thread, *exit_code);

                    if game.dll_thread
                        print("Injected dll.\n");
                }
            }
        }
    }
}

get_process_id :: (name: string) -> u32
{
    proc_id: u32 = 0;
    h_snap := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);

    if h_snap != INVALID_HANDLE_VALUE
    {
        proc_entry := PROCESSENTRY32.{};
        proc_entry.dwSize = size_of(PROCESSENTRY32);

        while Process32Next(h_snap, *proc_entry)
        {
            next_proc_name := to_string(proc_entry.szExeFile.data);
            //print("process name: %\n", next_proc_name);
            if compare(next_proc_name, name) == 0
            {
                //print("FOUND: %\n", next_proc_name);
                proc_id = proc_entry.th32ProcessID;
                CloseHandle(h_snap);
                return proc_id;
            }
        }
    }
    else
    {
        print("Invalid handle value.\n");
    }

    CloseHandle(h_snap);

    return proc_id;
}

get_module_base_addr :: (pid: DWORD, name: string) -> *u64, u64
{
    module_base_addr: *u64;
    h_snap := CreateToolhelp32Snapshot(TH32CS_SNAPMODULE | TH32CS_SNAPMODULE32, pid);

    if h_snap != INVALID_HANDLE_VALUE
    {
        module_entry := MODULEENTRY32.{};
        module_entry.dwSize = size_of(MODULEENTRY32);

        while Module32Next(h_snap, *module_entry)
        {
            module_name := to_string(module_entry.szModule.data);
            if compare(module_name,name) == 0
            {
                print("Module name: %, size: %\n", module_name, module_entry.modBaseSize);
                module_base_addr = cast(*u64)module_entry.modBaseAddr;
                print("Module address: %\n", module_base_addr);
                CloseHandle(h_snap);
                return module_base_addr, module_entry.modBaseSize;
            }
        }
    }
    else
    {
        print("Invalid handle value.\n");
    }

    CloseHandle(h_snap);

    return module_base_addr, 0;
}

get_module_base_addr :: (process: *Process_Attach)
{
    module_base_addr: *u64;
    h_snap := CreateToolhelp32Snapshot(TH32CS_SNAPMODULE | TH32CS_SNAPMODULE32, process.proc_id);

    if h_snap != INVALID_HANDLE_VALUE
    {
        module_entry := MODULEENTRY32.{};
        module_entry.dwSize = size_of(MODULEENTRY32);

        while Module32Next(h_snap, *module_entry)
        {
            module_name := to_string(module_entry.szModule.data);
            if compare(module_name, process.module_name) == 0
            {
                print("Module name: %, size: %\n", module_name, module_entry.modBaseSize);
                module_base_addr = cast(*u64)module_entry.modBaseAddr;
                print("Module address: %\n", module_base_addr);
                CloseHandle(h_snap);
                process.base_addr = module_base_addr;
                process.module_size = module_entry.modBaseSize;
            }
        }
    }
    else
    {
        print("Invalid handle value.\n");
    }

    CloseHandle(h_snap);
}

get_address_with_offset :: (address: *u64, offset: int) -> *u64
{
    return cast(*u64)(cast(*u8)address + offset);
}

find_dynamic_memory_allocation_addr :: (attachment: Process_Attach, base_addr: *u64, offset: [] u32) -> *u64
{
    result := cast(*u8)base_addr;
    for offset
    {
        ReadProcessMemory(attachment.process, cast(*void)result, *result, size_of(*u64), null);
        result += it;
    }

    return cast(*u64)result;
}

get_dynamic_memory_allocation_addr :: (attachment: Process_Attach, mem_addr_offset: u64, offset: [] u32) -> *u64
{
    dynamic_ptr_base_addr: *u8 = cast(*u8)attachment.base_addr + mem_addr_offset;
    result := find_dynamic_memory_allocation_addr(attachment, cast(*u64)dynamic_ptr_base_addr, offset);

    return result;
}

pattern_scan :: (data: *u8, count: u64, pattern: [] u8) -> *u8
{
    for i : 0..(xx count - pattern.count)-1 
    {
        matched := true;
        for j : 0..pattern.count-1
        {
            if data[i+j] != pattern[j] 
            {
                matched = false;
                break;
            }
        }
        if matched return data + i;
    }

    return null;
}

aob_scan_module :: (handle: HANDLE, base_addr: *u64, size: u64, pattern: [] u8) -> *u8
{
    buffer: *u8 = temporary_alloc(xx size);
    read_bytes: u64 = 0;

    final_address: *u8 = null;

    if ReadProcessMemory(handle, cast(*void)base_addr, buffer, size, *read_bytes) == 0
    {
        print("Failed to read process memory.\n");
        return final_address;
    }

    match_address := pattern_scan(buffer, size, pattern);
    if match_address != null
    {
        final_address = match_address;
        print("Pattern found at %\n", final_address);
    }
    else
    {
        print("Pattern not found.\n");
    }

    return final_address;
}

read_value :: (attachment: Process_Attach, mem_addr: *u64, value: *$T)
{
    ReadProcessMemory(attachment.process, cast(*void)mem_addr, value, size_of(T), null);
}

write_value :: (attachment: Process_Attach, mem_addr: *u64, value: *$T)
{
    data: T;
    //* NOTE: Check if memory is valid before writing
    if ReadProcessMemory(attachment.process, cast(*void)mem_addr, *data, size_of(T), null)
    {
        WriteProcessMemory(attachment.process, cast(*void)mem_addr, value, size_of(T), null);
    }
}

