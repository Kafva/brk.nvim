package main

import (
    "flag"
    "fmt"
    "log"
    "os"
    "path/filepath"
)

const USAGE = `usage: %s [flags] ` + "\n"

func main() {
    value := 1
    log.SetFlags(log.Ltime)

    flag.Usage = func() {
        fmt.Fprintf(os.Stderr, USAGE, filepath.Base(os.Args[0]))
        flag.PrintDefaults()
    }

    if len(os.Args) > 1 && os.Args[1] == "-h" {
        flag.Usage()
    } else {
        value2 := foo()
        log.Printf("%d: %+v\n", value, os.Args)
        log.Printf("%d: %+v\n", value2, os.Args)
    }

}
