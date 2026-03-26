/*
Simple BMP file viewer using SDL3. Supports only 32 and 24 bit BMP files.
*/
package main

import "core:io"
import "core:log"
import "core:os"
import sdl "vendor:sdl3"

FILE :: #config(FILE, "gradient.bmp")

BMP_File :: struct {
	header:      BMP_Header,
	info_header: BMP_Info_Header,
	data:        []byte,
}

BMP_Header :: struct #packed {
	signature:   [2]byte,
	size:        u32,
	reserved:    u32,
	data_offset: u32,
}

BMP_Info_Header :: struct #packed {
	size:               u32,
	width:              i32,
	height:             i32,
	planes:             u16,
	bit_count:          u16,
	compression:        u32,
	image_size:         u32,
	x_pixels_per_meter: u32,
	y_pixels_per_meter: u32,
	colors_used:        u32,
	colors_important:   u32,
}

bmp_read_path :: proc(bmp_file: ^BMP_File, path: string) -> os.Error {
	file := os.open(path) or_return

	return bmp_read(bmp_file, os.to_reader(file))
}

bmp_read :: proc(file: ^BMP_File, r: io.Reader, allocator := context.allocator) -> io.Error {
	header: [14]byte
	_ = io.read_full(r, header[:]) or_return
	file.header = transmute(BMP_Header)header

	info_header: [40]byte
	_ = io.read_full(r, info_header[:]) or_return
	file.info_header = transmute(BMP_Info_Header)info_header

	file.data = make([]byte, file.info_header.image_size)
	_ = io.read_at(r, file.data, i64(file.header.data_offset)) or_return

	return nil
}

bmp_pitch :: proc(file: BMP_File) -> i32 {
	if file.info_header.bit_count == 32 {
		return file.info_header.width * 4
	}

	byte_count := i32(file.info_header.bit_count) / 8

	return (file.info_header.width * byte_count + 3) & ~i32(3)
}

// `bmp_top_down_data` flips the image vertically if needed
bmp_top_down_data :: proc(file: BMP_File, allocator := context.allocator) -> []byte {
	if file.info_header.height < 0 {
		return file.data
	}

	log.info("flipping image vertically")

	pitch := int(bmp_pitch(file))
	temp := make([]byte, pitch, allocator)
	defer delete(temp)
	num_rows := len(file.data) / pitch
	for row in 0 ..< num_rows / 2 {
		bottom_start := row * pitch
		bottom := file.data[bottom_start:bottom_start + pitch]
		top_start := (num_rows - row - 1) * pitch
		top := file.data[top_start:top_start + pitch]

		copy(temp, top)
		copy(top, bottom)
		copy(bottom, temp)
	}

	return file.data
}

main :: proc() {
	context.logger = log.create_console_logger()

	file: BMP_File
	read_err := bmp_read_path(&file, FILE)
	if read_err != nil {
		log.fatalf("can not read file: %v", read_err)
	}
	log.infof("header: %v", file.header)
	log.infof("info header: %v", file.info_header)

	if ok := sdl.Init(sdl.INIT_VIDEO); !ok {
		log.fatalf("sdl: init failed: %v", sdl.GetError())
	}
	window_height := file.info_header.height
	if window_height < 0 {
		window_height *= -1
	}
	window := sdl.CreateWindow(
		"BMP viewer",
		i32(file.info_header.width),
		window_height,
		sdl.WindowFlags{},
	)
	if window == nil {
		log.fatalf("sdl: failed to create window: %v", sdl.GetError())
	}
	defer sdl.DestroyWindow(window)

	renderer := sdl.CreateRenderer(window, "")
	if renderer == nil {
		log.fatalf("sdl: failed to create renderer: %v", sdl.GetError())
	}
	defer sdl.DestroyRenderer(renderer)
	pixel_format: sdl.PixelFormat = file.info_header.bit_count == 24 ? .BGR24 : .BGRX32
	texture := sdl.CreateTexture(
		renderer,
		pixel_format,
		.STREAMING,
		file.info_header.width,
		window_height,
	)
	if texture == nil {
		log.fatalf("sdl: failed to create texture: %v", sdl.GetError())
	}
	defer sdl.DestroyTexture(texture)

	sdl.UpdateTexture(texture, nil, raw_data(bmp_top_down_data(file)), bmp_pitch(file))
	sdl.RenderTexture(renderer, texture, nil, nil)
	sdl.RenderPresent(renderer)

	event: sdl.Event
	for sdl.WaitEvent(&event) {
		if event.type == .QUIT {
			break
		}
	}
}
