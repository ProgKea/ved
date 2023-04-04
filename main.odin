package main

import "core:fmt"
import "core:strings"
import "core:os"
import "core:bufio"
import "core:io"

Ved :: struct {
    highlight_start: uint,
    cursor: uint,
    input: string,
    words: [dynamic]string
}

ALPHABET :: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

count_seq :: proc(s: string, a: rune) -> (count: uint) {
    count = 0
    for b, i in s {
	if a != b {
	    count = uint(i)
	    break
	}
    }
    return
}

is_any :: proc(char: u8, chars: string) -> bool {
    for it in chars {
	if char == u8(it) {
	    return true
	}
    }
    return false
}

len_up_to :: proc(s: [dynamic]string, index: uint) -> (result: uint) {
    return len(strings.join(s[:index], ""))
}

get_current_word :: proc(words: [dynamic]string, cursor: uint) -> uint {
    for _, i in words {
	i := uint(i)
	if cursor < len_up_to(words, i) {
	    return i-1
	}
    }
    return len(words)-1
}

/*
If current character differs from previous character (By differ I mean alphabetic character vs special character)
then we should push all the characters up to the difference to the words list and repeat that until we split all the words.
*/
split_words :: proc(of: string) -> (words: [dynamic]string) /* <-- Does this need to be dynamic? */ {
    word_start := 0
    for i in 0..<len(of)-1 {
	if is_any(of[i], ALPHABET) != is_any(of[i+1], ALPHABET) && of[i+1] != ' ' {
	    append(&words, of[word_start:i+1])
	    word_start = i+1
	}
    }
    append(&words, of[word_start:])

    return words
}

ved_init :: proc(input: string) -> (v: Ved) {
    return {
	input = input,
	words = split_words(input),
	cursor = 0,
	highlight_start = 0,
    }
}

ved_deinit :: proc(v: ^Ved) {
    delete(v.words)
}

ved_get_highlight :: proc(v: Ved) -> string {
    input_len := uint(len(v.input))
    return (
	v.input[v.highlight_start:min(input_len, v.cursor+1)] if v.highlight_start < v.cursor
	else v.input[v.cursor:min(input_len, v.highlight_start+1)]
    )
}

ved_exec :: proc(v: ^Ved cmd: string) {
    skip := false
    for c, i in cmd {
	// TODO: find a better way to do this
	if skip {
	    skip = false
	    continue
	}

	switch c {
	case 'v':
	    v.highlight_start = uint(v.cursor)
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
	case '0':
	    v.cursor = 0
	case '_':
	    v.cursor = count_seq(v.input, ' ')
	case 'w':
	    v.cursor = len_up_to(v.words, get_current_word(v.words, v.cursor)+1)
	case 'e':
	    fmt.eprintf("Command %s is unimplemented", rune(cmd[i]))
	    os.exit(1)
	case 'b':
	    fmt.eprintf("Command %s is unimplemented", rune(cmd[i]))
	    os.exit(1)
	case 'f':
	    v.cursor += cast(uint)max(strings.index_rune(v.input[v.cursor:], rune(cmd[i+1])), 0)
	    skip = true
	case 't':
	    v.cursor += cast(uint)max(strings.index_rune(v.input[v.cursor:], rune(cmd[i+1]))-1, 0)
	    skip = true
	case 'F':
	    v.cursor -= cast(uint)max(strings.index_rune(strings.reverse(v.input[:v.cursor+1]), rune(cmd[i+1])), 0)
	    skip = true
	case 'T':
	    v.cursor -= cast(uint)max(strings.index_rune(strings.reverse(v.input[:v.cursor+1]), rune(cmd[i+1]))-1, 0)
	    skip = true
	case:
	    fmt.eprintln("ERROR: Unkown symbol: ", c)
	}
    }
}

execute_ved :: proc(input: string, cmd: string) -> string {
    v := ved_init(input)
    defer ved_deinit(&v)

    ved_exec(&v, cmd)
    return ved_get_highlight(v)
}

print_help :: proc(program_name: string) {
    fmt.printf("%s <command> <optional filepath>\n", program_name)
}

main :: proc() {
    args := os.args

    switch {
    case len(args) < 2:
	fmt.eprintln("ERROR: not enough arguments were provided.")
	print_help(args[0])
    case len(args) == 2:
	stdin := os.stream_from_handle(os.stdin)

	reader: bufio.Reader
	bufio.reader_init(&reader, io.Reader{stdin})
	defer bufio.reader_destroy(&reader)

	cmd := args[1]
	input: string
	for err: io.Error; err == nil; input, err = bufio.reader_read_string(&reader, '\n') {
	    input := strings.trim(input, "\n")
	    fmt.println(execute_ved(input, cmd))
	}
    case len(args) == 3:
	cmd := args[1]
	file_name := args[2]
	data, ok := os.read_entire_file(file_name)
	if !ok {
	    fmt.eprintf("ERROR: failed to read file: %s", file_name)
	    os.exit(1)
	}

	using strings
	for line in split_lines(string(data)) {
	    fmt.println(execute_ved(line, cmd))
	}
    case:
	fmt.eprintln("ERROR: To many arguments were provided.")
	print_help(args[0])
    }
}
