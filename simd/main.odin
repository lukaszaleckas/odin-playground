package main

import "core:fmt"
import "core:simd"

main :: proc() {
	a := []int{1, 2, 3, 4, 5, 6, 7, 8}
	b := []int{10, 20, 30, 40, 50, 60, 70, 80}

	av := simd.from_slice(#simd[8]int, a)
	bv := simd.from_slice(#simd[8]int, b)
	simd_result := simd.add(av, bv)

	fmt.printfln("Result: %v", simd_result)
}
