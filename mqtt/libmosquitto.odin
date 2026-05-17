package main

import "core:c"

when ODIN_OS == .Windows {
	#panic("windows is not currently supported")
} else {
	foreign import lib "system:mosquitto"
}

Mosquitto :: struct{}
Mosquitto_Message :: struct{
	mid: c.int,
	topic: cstring,
	payload: rawptr,
	payload_length: c.int,
	qos: c.int,
	retain: bool,
}

Connect_Callback :: #type proc "c" (mosq: ^Mosquitto, user_data: rawptr, return_code: c.int)
Message_Callback :: #type proc "c" (mosq: ^Mosquitto, user_data: rawptr, message: ^Mosquitto_Message)

@(default_calling_convention = "c")
foreign lib {
	mosquitto_lib_init :: proc() -> c.int ---
	mosquitto_lib_cleanup :: proc() -> c.int ---
	mosquitto_strerror :: proc(err_number: c.int) -> cstring ---

	mosquitto_new :: proc(id: cstring, clean_session: bool, user_data: rawptr) -> ^Mosquitto ---
	mosquitto_destroy :: proc(mosq: ^Mosquitto) ---

	mosquitto_connect :: proc(mosq: ^Mosquitto, host: cstring, port: c.int, keepalive: c.int) -> c.int ---
	mosquitto_disconnect :: proc(mosq: ^Mosquitto) -> c.int ---
	mosquitto_loop_forever :: proc(mosq: ^Mosquitto, timeout: c.int, max_packets: c.int) -> c.int ---

	mosquitto_subscribe :: proc(mosq: ^Mosquitto, mid: ^c.int, sub: cstring, qos: c.int) -> c.int ---

	mosquitto_message_callback_set :: proc(mosq: ^Mosquitto, callback: Message_Callback) ---
}
