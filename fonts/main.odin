/*
IN PROGRESS
*/
package main

import "core:fmt"

ARIAL :: #load("arial.ttf")

main :: proc() {
	font: Ttf_Font

	fmt.println(
		ODIN_ENDIAN,
		font,
		ttf_parse_bytes(&font, ARIAL),
	)
}
