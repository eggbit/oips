package ips

import "core:os"
import "core:slice"

Status :: enum {
    OK,
    IPS_INVALID,
    ROM_OPEN_FAILED,
    PATCH_OPEN_FAILED,
    PATCH_CREATION_FAILED,
    PATCH_SUCCESS
}

@private ips_load :: proc(path: string) -> ([]byte, Status) {
    ips, ok := os.read_entire_file_from_filename(path)

    if !ok {
        return {}, Status.PATCH_OPEN_FAILED
    }
    
    if string(read(&ips, 5)) != "PATCH" {
        return nil, Status.IPS_INVALID
    }

    return ips, Status.OK
}

@private rom_load :: proc(rom_path: string) -> ([dynamic]byte, Status) {
    rom, ok := os.read_entire_file_from_filename(rom_path)

    if !ok {
        return nil, Status.ROM_OPEN_FAILED
    }

    return slice.clone_to_dynamic(rom), Status.OK
}

@private as_u32 :: proc(b: []byte) -> u32 {
    result: u32 = 0
    
    for i in b {
        result = result << 8 | u32(i)
    }
    
    return result
}

@private read :: proc(buffer: ^[]byte, num: u32, inc: bool = true) -> []u8 {
    @static pos : u32

    result := buffer[pos : pos + num]
    if inc do pos += num
    
    return result
}

apply :: proc(patch_path, rom_path, out_path: string) -> Status {
    ips := ips_load(patch_path) or_return
    rom := rom_load(rom_path) or_return
    defer delete(rom)

    for string(read(&ips, 3, false)) != "EOF" {
        record_offset := as_u32(read(&ips, 3))
        record_size := as_u32(read(&ips, 2))

        // RLE
        if record_size == 0 {
            rle_size := as_u32(read(&ips, 2))
            rle_val := read(&ips, 1)[0]

            for i in 0..<rle_size {
                rom[record_offset + i] = rle_val
            }
        } 
        else {
            assign_at(&rom, int(record_offset), ..read(&ips, record_size))
        }
    }

    // Output
    success := os.write_entire_file(out_path, rom[:]);

    if !success {
        return Status.PATCH_CREATION_FAILED
    }

    return Status.PATCH_SUCCESS
}
