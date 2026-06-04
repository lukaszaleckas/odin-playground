/*
IN PROGRESS
*/
package main

import "core:fmt"

ARIAL :: #load("arial.ttf")

main :: proc() {
	font: Font

	fmt.println(
		ODIN_ENDIAN,
		font,
		parse_bytes(&font, ARIAL),
	)
}
