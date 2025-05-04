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
    attached: bool;
}

attach_process :: (name: string, module_name: string) -> Process_Attach
{
    result: Process_Attach;
    result.name = name;
    result.module_name = module_name;
    result.proc_id = get_process_id(name);

    if result.proc_id != 0
    {
        result.process = OpenProcess(PROCESS_ALL_ACCESS, 0, result.proc_id);
        if result.process
        {
            result.base_addr = get_module_base_addr(result);
            result.attached = true;
            print("FOUND: %, ID: %\n", name, result.proc_id);
            print("Process Attached.\n");
        }
    }

    return result;
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

get_module_base_addr :: (process: Process_Attach) -> *u64
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
                CloseHandle(h_snap);
                return module_base_addr;
            }
        }
    }
    else
    {
        print("Invalid handle value.\n");
    }

    CloseHandle(h_snap);

    return module_base_addr;
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

