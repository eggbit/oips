package main

import "core:fmt"
import "core:os"
import ips "ips"

main :: proc() {
    if !(len(os.args) == 5 && os.args[3] == "-o") {
        fmt.println("Usage: oips [patch] [rom] -o [output]")
        os.exit(1)
    }

    result := ips.apply(os.args[1], os.args[2], os.args[4])

    if result != ips.Status.PATCH_SUCCESS {
        fmt.printfln("Error: %s", result)
    }
}
