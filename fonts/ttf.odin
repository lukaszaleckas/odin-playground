package main

import "base:builtin"
import "base:intrinsics"
import "core:fmt"
import "core:log"
import "core:bytes"
import "core:io"

Error :: union #shared_nil {
	io.Error,
	Table_Error,
}

Table_Error :: enum {
	None = 0,
	Record_Not_Found,
}

//REGION: structs

Font :: struct {
	header: Header,
	table_records: []Table_Record,

	table_head: Table_Head,
	table_maxp: Table_Maxp,
}

Header :: struct #packed {
	sfnt_version: u32be,
	num_tables: u16be,
	search_range: u16be,
	entry_selector: u16be,
	range_shift: u16be,
}

Table_Record :: struct #packed {
	table_tag: [4]byte,
	checksum: u32be,
	offset: u32be,
	length: u32be,
}

Table_Head :: struct #packed {
	major_ver: u16be,
	minor_ver: u16be,
	font_revision: f32be,
	checksum_adjustment: u32be,
	magic_number: u32be,
	flags: u16,
	units_per_em: u16,
	created_at: i64be,
	modified_at: i64be,
	x_min: i16be,
	y_min: i16be,
	x_max: i16be,
	y_max: i16be,
	mac_style: u16be,
	lowest_rec_ppem: u16be,
	font_dir_hint: i16be,
	idx_to_loc_format: i16be,
	glyph_data_format: i16be,
}

Table_Maxp :: struct #packed {
	version: u32be,
	num_glyphs: u16be,
}

//REGION: font file parsing

parse_bytes :: proc(font: ^Font, data: []byte) -> Error {
	bytes_reader: bytes.Reader
	stream := bytes.reader_init(&bytes_reader, data)
	reader, _ := io.to_reader(stream)

	return parse(font, reader)
}

parse :: proc(
	font: ^Font,
	reader: io.Reader,
	allocator := context.allocator,
) -> Error {
	header: [size_of(Header)]byte
	_ = io.read_full(reader, header[:]) or_return

	// use this or transmute below
	// remove the "be" from the types if using this
	//
	// font.header.sfnt_version = _read_u32be(header[:4])
	// fonbet.header.num_tables = _read_u16be(header[4:6])
	// font.header.search_range = _read_u16be(header[6:8])
	// font.header.entry_selector = _read_u16be(header[8:10])
	// font.header.range_shift = _read_u16be(header[10:12])

	font.header = transmute(Header)header
	font.table_records = make([]Table_Record, font.header.num_tables, allocator)

	for i in 0 ..< font.header.num_tables {
		table_record: [size_of(Table_Record)]byte
		_ = io.read_full(reader, table_record[:]) or_return

		font.table_records[i] = transmute(Table_Record)table_record
	}

	font.table_head = _read_table(font.table_records, reader, "head", Table_Head) or_return
	font.table_maxp = _read_table(font.table_records, reader, "maxp", Table_Maxp) or_return

	return nil
}

_read_table :: proc(
	records: []Table_Record,
	reader: io.Reader,
	name: string,
	$T: typeid,
) -> (result: T, err: Error) {
	table_record: Table_Record
	table_record_found: bool
	for &record in records {
		if string(record.table_tag[:]) == name {
			table_record = table_record
			table_record_found = true
		}
	}
	if !table_record_found {
		return result, .Record_Not_Found
	}

	_ = io.seek(reader, i64(table_record.offset), .Start) or_return

	table: [size_of(T)]byte
	_ = io.read_full(reader, table[:]) or_return

	return transmute(T)table, nil
}

//REGION: utilities
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
