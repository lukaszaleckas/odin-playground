package main

import "core:c"
import "core:log"
import "core:math"
import "core:mem"
import "core:os"
import sdl "vendor:sdl3"

phase: f32
gain: f32 = 0.5
sample_rate: i32 = 48000
freq: f32 = 440
phase_shift_per_sample: f32 = (freq / f32(sample_rate)) * 2 * math.PI
buf: [2048]f32
min_samples: i32 = len(buf) / 2

audio_callback :: proc "c" (
	userdata: rawptr,
	stream: ^sdl.AudioStream,
	need_bytes, total_bytes: c.int,
) {
	need_samples := need_bytes / size_of(f32)
	if need_samples < min_samples {
		return
	}

	for _, i in buf {
		phase += phase_shift_per_sample
		if phase >= 2 * math.PI {
			phase -= 2 * math.PI
		}
		buf[i] = math.sin_f32(phase) * gain
	}

	sdl.PutAudioStreamData(stream, raw_data(buf[:]), size_of(buf))
}

main :: proc() {
	context.logger = log.create_console_logger()
	when ODIN_DEBUG {
		alloc: mem.Tracking_Allocator
		mem.tracking_allocator_init(&alloc, context.allocator)
		context.allocator = mem.tracking_allocator(&alloc)
		defer {
			for _, entry in alloc.allocation_map {
				log.errorf("%v leaked %m", entry.location, entry.size)
			}
			mem.tracking_allocator_destroy(&alloc)
		}
	}

	if ok := sdl.Init(sdl.INIT_AUDIO); !ok {
		log.fatalf("sdl: init failed: %v", sdl.GetError())
	}
	defer sdl.Quit()
	stream := sdl.OpenAudioDeviceStream(
		sdl.AUDIO_DEVICE_DEFAULT_PLAYBACK,
		&sdl.AudioSpec{format = .F32, channels = 1, freq = sample_rate},
		audio_callback,
		nil,
	)
	if stream == nil {
		log.fatalf("sdl: open audio device stream failed: %v", sdl.GetError())
	}
	defer sdl.DestroyAudioStream(stream)
	if ok := sdl.ResumeAudioStreamDevice(stream); !ok {
		log.fatalf("sdl: resume audio stream device failed: %v", sdl.GetError())
	}

	log.info("playing sine wave... press ENTER to stop")

	buf: [1]byte
	os.read(os.stdin, buf[:])
}
