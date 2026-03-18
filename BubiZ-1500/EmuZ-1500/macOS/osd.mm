/*
	Skelton for retropc emulator
	macOS port

	[ macOS OSD - core ]
*/

#include "osd.h"
#include "../../Core/fileio.h"
#include <unistd.h>

void OSD::initialize(int rate, int samples)
{
	// initialize screen
	initialize_screen();

	// initialize sound
	initialize_sound(rate, samples);

	// initialize input
	initialize_input();

	// initialize console
	initialize_console();

#ifdef USE_MIDI
	initialize_midi();
#endif
}

void OSD::release()
{
#ifdef USE_MIDI
	release_midi();
#endif
	release_console();
	release_input();
	release_sound();
	release_screen();
}

void OSD::power_off()
{
}

void OSD::suspend()
{
	mute_sound();
}

void OSD::restore()
{
}

void OSD::lock_vm()
{
	vm_mutex.lock();
	lock_count++;
}

void OSD::unlock_vm()
{
	if(lock_count > 0) {
		lock_count--;
		vm_mutex.unlock();
	}
}

void OSD::force_unlock_vm()
{
	while(lock_count > 0) {
		lock_count--;
		vm_mutex.unlock();
	}
}

void OSD::sleep(uint32_t ms)
{
	usleep(ms * 1000);
}

#ifdef USE_DEBUGGER
void OSD::start_waiting_in_debugger()
{
}

void OSD::finish_waiting_in_debugger()
{
}

void OSD::process_waiting_in_debugger()
{
}
#endif
