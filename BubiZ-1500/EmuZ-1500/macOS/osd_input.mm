/*
	Skelton for retropc emulator
	macOS port

	[ macOS OSD - input ]
*/

#include "osd.h"

void OSD::initialize_input()
{
	memset(key_status, 0, sizeof(key_status));
	lost_focus = false;

#ifdef USE_JOYSTICK
	memset(joy_status, 0, sizeof(joy_status));
	memset(joy_to_key_status, 0, sizeof(joy_to_key_status));
	joy_num = 0;
#endif

#ifdef USE_MOUSE
	memset(mouse_status, 0, sizeof(mouse_status));
	mouse_enabled = false;
#endif

#ifdef USE_AUTO_KEY
	now_auto_key = false;
#endif
}

void OSD::release_input()
{
}

void OSD::update_input()
{
	if(lost_focus) {
		memset(key_status, 0, sizeof(key_status));
		lost_focus = false;
	}

#ifdef USE_JOYSTICK
	// TODO: poll GameController.framework
#endif

#ifdef USE_MOUSE
	// mouse delta is set from NSEvent handlers
#endif
}

void OSD::key_down(int code, bool extended, bool repeat)
{
	if(code >= 0 && code < 256) {
		if(!(code == 0xf0 || code == 0xf2 || code == 0xf3 || code == 0xf4)) {
			key_status[code] = 0x80;
		}
		if(!repeat) {
			vm->key_down(code, repeat);
		}
	}
}

void OSD::key_up(int code, bool extended)
{
	if(code >= 0 && code < 256) {
		key_status[code] &= 0x7f;
		vm->key_up(code);
	}
}

void OSD::key_down_native(int code, bool repeat)
{
	// native macOS keycode -> Windows VK conversion happens in the bridge layer
}

void OSD::key_up_native(int code)
{
	// native macOS keycode -> Windows VK conversion happens in the bridge layer
}

#ifdef USE_MOUSE
void OSD::enable_mouse()
{
	mouse_enabled = true;
}

void OSD::disable_mouse()
{
	mouse_enabled = false;
}

void OSD::toggle_mouse()
{
	mouse_enabled = !mouse_enabled;
}
#endif
