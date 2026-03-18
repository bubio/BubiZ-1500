/*
	Skelton for retropc emulator
	macOS port

	[ macOS OSD - console ]
*/

#include "osd.h"

void OSD::initialize_console()
{
}

void OSD::release_console()
{
}

void OSD::open_console(int width, int height, const _TCHAR* title)
{
}

void OSD::close_console()
{
}

unsigned int OSD::get_console_code_page()
{
	return 65001; // UTF-8
}

void OSD::set_console_code_page(unsigned int cp)
{
}

void OSD::get_console_cursor_position(int *x, int *y)
{
	if(x) *x = 0;
	if(y) *y = 0;
}

void OSD::set_console_cursor_position(int x, int y)
{
}

void OSD::set_console_text_attribute(unsigned short attr)
{
}

void OSD::write_console(const _TCHAR* buffer, unsigned int length)
{
	if(buffer && length > 0) {
		fwrite(buffer, 1, length, stdout);
	}
}

void OSD::write_console_char(const char* buffer, unsigned int length)
{
	if(buffer && length > 0) {
		fwrite(buffer, 1, length, stdout);
	}
}

void OSD::write_console_wchar(const wchar_t* buffer, unsigned int length)
{
	if(buffer && length > 0) {
		for(unsigned int i = 0; i < length; i++) {
			putwchar(buffer[i]);
		}
	}
}

int OSD::read_console_input(_TCHAR* buffer, unsigned int length)
{
	return 0;
}

bool OSD::is_console_key_pressed(int vk)
{
	return false;
}

bool OSD::is_console_closed()
{
	return false;
}

void OSD::close_debugger_console()
{
}
