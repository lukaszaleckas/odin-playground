package main

import "core:fmt"
import "core:time"
import sdl "vendor:sdl3"

WIDTH :: 640
HEIGHT :: 640

MOVE_SPEED_PER_FRAME :: 2

main :: proc() {
	if !sdl.Init(sdl.INIT_VIDEO) {
		fmt.panicf("sdl init failed: %v", sdl.GetError())
	}

	window: ^sdl.Window
	renderer: ^sdl.Renderer
	result := sdl.CreateWindowAndRenderer(
		"Messing with SDL",
		WIDTH,
		HEIGHT,
		sdl.WindowFlags{},
		&window,
		&renderer,
	)
	if !result {
		fmt.panicf("sdl window and renderer creation failed: %v", sdl.GetError())
	}

	pixel_buf := make([]u32, WIDTH * HEIGHT)

	texture := sdl.CreateTexture(renderer, .XRGB8888, .STREAMING, WIDTH, HEIGHT)
	if texture == nil {
		fmt.panicf("sdl texture creation failed: %v", sdl.GetError())
	}

	refresh_rate: f32 = 60
	if display_id := sdl.GetPrimaryDisplay(); display_id != 0 {
		if display_mode := sdl.GetCurrentDisplayMode(display_id); display_mode != nil {
			refresh_rate = display_mode.refresh_rate
		}
	}
	fps_time := time.Duration(f64(time.Second) / f64(refresh_rate))

	rect_x, rect_y: i32

	event: sdl.Event
	for {
		tick_start := time.tick_now()

		for sdl.PollEvent(&event) {
			if event.type == .QUIT {
				return
			}
		}

		clear(pixel_buf)
		draw_rect(pixel_buf, rect_x, rect_y, 30, 50)

		sdl.UpdateTexture(texture, nil, raw_data(pixel_buf), WIDTH * size_of(u32))
		sdl.RenderTexture(renderer, texture, nil, nil)
		sdl.RenderPresent(renderer)

		sleep_time := fps_time - time.tick_since(tick_start)
		time.accurate_sleep(sleep_time)

		fmt.printfln("refresh rate: %v; frame time: %v", refresh_rate, time.tick_since(tick_start))

		rect_x += MOVE_SPEED_PER_FRAME
		rect_y += MOVE_SPEED_PER_FRAME
	}
}

clear :: proc(pixel_buf: []u32) {
	for _, i in pixel_buf {
		pixel_buf[i] = 0
	}
}

draw_rect :: proc(pixel_buf: []u32, rect_x, rect_y, rect_width, rect_height: i32) {
	start_x := max(rect_x, 0)
	start_y := max(rect_y, 0)
	max_x := min(rect_x + rect_width, WIDTH)
	max_y := min(rect_y + rect_height, HEIGHT)

	for y in start_y ..< max_y {
		for x in start_x ..< max_x {
			pixel_buf[y * WIDTH + x] = 0xffffff
		}
	}
}
