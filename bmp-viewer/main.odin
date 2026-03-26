package main

import "core:io"
import "core:log"
import "core:os"
import sdl "vendor:sdl3"

WINDOW_WIDTH :: #config(WINDOW_WIDTH, 512)
WINDOW_HEIGHT :: #config(WINDOW_HEIGHT, 512)
FILE :: #config(FILE, "gradient.bmp")

BMP_File :: struct {
	header: BMP_Header,
	data:   []byte,
}

BMP_Header :: struct #packed {
	signature:   [2]byte,
	size:        u32,
	reserved:    u32,
	data_offset: u32,
}

bmp_read_path :: proc(bmp_file: ^BMP_File, path: string) -> os.Error {
	file := os.open(path) or_return

	return bmp_read(bmp_file, os.to_reader(file))
}

bmp_read :: proc(file: ^BMP_File, r: io.Reader, allocator := context.allocator) -> io.Error {
	header: [14]byte
	_ = io.read_full(r, header[:]) or_return
	file.header = transmute(BMP_Header)header

	file.data = make([]byte, file.header.size - file.header.data_offset)
	_ = io.read_at(r, file.data, i64(file.header.data_offset)) or_return

	return nil
}

main :: proc() {
	context.logger = log.create_console_logger()

	log.info("reading file...")
	file: BMP_File
	read_err := bmp_read_path(&file, FILE)
	if read_err != nil {
		log.fatalf("can not read file: %v", read_err)
	}
	log.infof("file read: %v", file.header)

	if ok := sdl.Init(sdl.INIT_VIDEO); !ok {
		log.fatalf("sdl: init failed: %v", sdl.GetError())
	}
	window := sdl.CreateWindow("BMP viewer", WINDOW_WIDTH, WINDOW_HEIGHT, sdl.WindowFlags{})
	if window == nil {
		log.fatalf("sdl: failed to create window: %v", sdl.GetError())
	}
	defer sdl.DestroyWindow(window)

	renderer := sdl.CreateRenderer(window, "")
	if renderer == nil {
		log.fatalf("sdl: failed to create renderer: %v", sdl.GetError())
	}
	defer sdl.DestroyRenderer(renderer)
	texture := sdl.CreateTexture(renderer, .BGR24, .STREAMING, WINDOW_WIDTH, WINDOW_HEIGHT)
	if texture == nil {
		log.fatalf("sdl: failed to create texture: %v", sdl.GetError())
	}
	defer sdl.DestroyTexture(texture)

	// TODO: read about this trick
	pitch := (WINDOW_WIDTH * (24 / 8) + 3) & ~i32(3)
	// pitch := ((WINDOW_WIDTH * 3 + 3) / 4) * 4
	sdl.UpdateTexture(texture, nil, raw_data(file.data), i32(pitch))
	sdl.RenderTexture(renderer, texture, nil, nil)
	sdl.RenderPresent(renderer)

	event: sdl.Event
	for sdl.WaitEvent(&event) {
		if event.type == .QUIT {
			break
		}
	}
}
