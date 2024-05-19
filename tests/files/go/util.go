package main

import (
    "log"
)

func foo() int {
    return 2
}

func bar() int {
    for i := 0; i < 10; i++ {
       log.Printf("%d\n", i);
    }
    return 3
}

