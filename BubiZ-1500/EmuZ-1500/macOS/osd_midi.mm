/*
	Skelton for retropc emulator
	macOS port

	[ macOS OSD - MIDI ]
*/

#include "osd.h"
#include "../../Core/fifo.h"

#ifdef USE_MIDI

void OSD::initialize_midi()
{
	midi_thread_params.send_buffer = new FIFO(1024);
	midi_thread_params.recv_buffer = new FIFO(1024);
	midi_thread_params.terminate = false;
	// TODO: initialize CoreMIDI
}

void OSD::release_midi()
{
	midi_thread_params.terminate = true;
	if(midi_thread_params.send_buffer) {
		midi_thread_params.send_buffer->release();
		delete midi_thread_params.send_buffer;
		midi_thread_params.send_buffer = NULL;
	}
	if(midi_thread_params.recv_buffer) {
		midi_thread_params.recv_buffer->release();
		delete midi_thread_params.recv_buffer;
		midi_thread_params.recv_buffer = NULL;
	}
}

void OSD::send_to_midi(uint8_t data)
{
	if(midi_thread_params.send_buffer) {
		midi_thread_params.send_buffer->write(data);
	}
}

bool OSD::recv_from_midi(uint8_t *data)
{
	if(midi_thread_params.recv_buffer && !midi_thread_params.recv_buffer->empty()) {
		*data = (uint8_t)midi_thread_params.recv_buffer->read();
		return true;
	}
	return false;
}

#endif
