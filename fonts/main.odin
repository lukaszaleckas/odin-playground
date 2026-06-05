/*
IN PROGRESS
*/
package main

import "core:fmt"

ARIAL :: #load("arial.ttf")

main :: proc() {
	font: Font
	if err := parse_bytes(&font, ARIAL); err != nil {
		fmt.panicf("parse error: %v", err)
	}

	fmt.println(font.table_head)
	fmt.println(font.table_maxp)
}
