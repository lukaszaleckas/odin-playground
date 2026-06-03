package main

import "core:bytes"
import "core:io"

Ttf_Font :: struct {
	header: Ttf_Header,
}

Ttf_Header :: struct #packed {
	sfnt_version: u32be,
	num_tables: u16be,
	search_range: u16be,
	entry_selector: u16be,
	range_shift: u16be,
}

ttf_parse_bytes :: proc(font: ^Ttf_Font, data: []byte) -> io.Error {
	bytes_reader: bytes.Reader
	stream := bytes.reader_init(&bytes_reader, data)
	reader, _ := io.to_reader(stream)

	return ttf_parse(font, reader)
}

ttf_parse :: proc(font: ^Ttf_Font, reader: io.Reader) -> io.Error {
	header: [size_of(Ttf_Header)]byte
	_ = io.read_full(reader, header[:]) or_return

	// remove the "be" from the types
	// font.header.sfnt_version = _read_u32be(header[:4])
	// fonbet.header.num_tables = _read_u16be(header[4:6])
	// font.header.search_range = _read_u16be(header[6:8])
	// font.header.entry_selector = _read_u16be(header[8:10])
	// font.header.range_shift = _read_u16be(header[10:12])

	font.header = transmute(Ttf_Header)header

	return nil
}

// _read_u32be reads the big endian byte slice and constructs them as u32
_read_u32be :: proc(data: []byte) -> u32 {
	return u32(data[0]) << 24 |
		u32(data[1]) << 16 |
		u32(data[2]) << 8 |
		u32(data[3])
}

// _read_u16be reads the big endian byte slice and constructs them as u16
_read_u16be :: proc(data: []byte) -> u16 {
	return u16(data[0]) << 8 |
		u16(data[1])
}
