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
    log.SetFlags(log.Ltime)

    flag.Usage = func() {
        fmt.Fprintf(os.Stderr, USAGE, filepath.Base(os.Args[0]))
        flag.PrintDefaults()
    }

    if len(os.Args) > 1 && os.Args[1] == "-h" {
        flag.Usage()
    } else {
        log.Printf("%+v\n", os.Args)
    }

}
