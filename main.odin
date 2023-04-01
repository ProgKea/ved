package main

import "core:fmt"

Ved :: struct {
    highlight_start: uint,
    cursor: uint,
    input: string,
}

ved_init :: proc(input: string) -> Ved {
    return Ved {
	input = input,
	cursor = 0,
    }
}

ved_get_highlight :: proc(v: Ved) -> string {
    input_len := uint(len(v.input))
    return (
	v.input[v.highlight_start:min(input_len, v.cursor+1)] if v.highlight_start < v.cursor
	else v.input[v.cursor:min(input_len, v.highlight_start+1)]
    )
}

ved_exec :: proc(v: ^Ved cmd: string) -> (result: string, ok: bool) {
    for c, i in cmd {
	switch c {
	case 'v':
	    v.highlight_start = uint(i)
	case 'h':
	    if v.cursor > 0 {
		v.cursor -= 1
	    }
	case 'l':
	    if v.cursor < len(v.input) {
		v.cursor += 1
	    }
	case '$':
	    v.cursor = len(v.input)-1
	case:
	    fmt.eprintln("ERROR: Unkown symbol: ", c)
	}
    }

    return "", true
}

main :: proc() {
    v := ved_init("Hello, ved")

    ved_exec(&v, "vlllllllllllllllllllllll")
    fmt.println(ved_get_highlight(v))
}
