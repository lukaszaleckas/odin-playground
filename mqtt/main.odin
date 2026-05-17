package main

import "core:strconv"
import "core:os"
import "base:runtime"
import "core:fmt"
import "core:c";

main :: proc() {
	//region:args-parse
	host := "localhost"
	port: i32 = 1883

	if len(os.args) > 1 {
		host = os.args[1]
	}
	if len(os.args) > 2 {
		if parsed_port, ok := strconv.parse_int(os.args[2]); ok {
			port = i32(parsed_port)
		}
	}
	fmt.printfln("used host: %q", host)
	fmt.printfln("used port: %d\n", port)

	//region:mosquitto-setup
	if err_number := mosquitto_lib_init(); err_number != 0 {
		mosquitto_panic("init failed", err_number)
	}
	defer mosquitto_lib_cleanup()

	client := mosquitto_new(nil, true, nil)
	if client == nil {
		fmt.panicf("failed to create mosquitto client")
	}
	defer mosquitto_destroy(client)

	conn_err_number := mosquitto_connect(
		client,
		cstring(raw_data(host)),
		port,
		keepalive=10,
	)
	if conn_err_number != 0 {
		mosquitto_panic("connection failed", conn_err_number)
	}
	defer mosquitto_disconnect(client)

	mosquitto_message_callback_set(client, on_message)

	sub_err_number := mosquitto_subscribe(client, nil, "#", 0)
	if sub_err_number != 0 {
		mosquitto_panic("subscribe failed", sub_err_number)
	}

	//region:main-loop
	mosquitto_loop_forever(client, -1, 1)
}

mosquitto_panic :: #force_inline proc(msg: string, err_number: c.int) {
	fmt.panicf("mosquitto: %s: %s", msg, mosquitto_strerror(err_number))
}

on_message :: proc "c" (
	mosq: ^Mosquitto,
	user_data: rawptr,
	message: ^Mosquitto_Message,
) {
	context = runtime.default_context()

	fmt.printfln(
		"mid: %d; topic: %q; payload: %q; qos: %d; retain: %v\n",
		message.mid,
		message.topic,
		cstring(message.payload),
		message.qos,
		message.retain,
	)
}
