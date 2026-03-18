/*
	Skelton for retropc emulator

	Author : Takeda.Toshiya (original Win32)
	macOS port

	[ macOS dependent ]
*/

#ifndef _MACOS_OSD_H_
#define _MACOS_OSD_H_

#include <mutex>
#include <cstdint>
#include <atomic>
#include "../../Core/vm/vm.h"
#include "../../Core/common.h"
#include "../../Core/config.h"

class FIFO;
class FILEIO;

#define OSD_CONSOLE_BLUE	1
#define OSD_CONSOLE_GREEN	2
#define OSD_CONSOLE_RED		4
#define OSD_CONSOLE_INTENSITY	8

#define SCREEN_FILTER_NONE	0
#define SCREEN_FILTER_RGB	1
#define SCREEN_FILTER_CRT	2
#define SCREEN_FILTER_NTSC	3

// macOS bitmap_t - top-down pixel buffer (unlike Win32 bottom-up DIB)
typedef struct bitmap_s {
	inline bool initialized()
	{
		return (lpBmp != NULL);
	}
	inline scrntype_t* get_buffer(int y)
	{
		return lpBmp + width * y;  // top-down (not bottom-up like Win32)
	}
	int width, height;
	scrntype_t* lpBmp;
} bitmap_t;

typedef struct font_s {
	inline bool initialized()
	{
		return (valid);
	}
	_TCHAR family[64];
	int width, height, rotate;
	bool bold, italic;
	bool valid;
} font_t;

typedef struct pen_s {
	inline bool initialized()
	{
		return (valid);
	}
	int width;
	uint8_t r, g, b;
	bool valid;
} pen_t;

#ifdef USE_MIDI
typedef struct midi_thread_params_s {
	FIFO *send_buffer;
	FIFO *recv_buffer;
	bool terminate;
} midi_thread_params_t;
#endif

class OSD
{
private:
	int lock_count;
	std::mutex vm_mutex;

	// console
	void initialize_console();
	void release_console();

	// input
	void initialize_input();
	void release_input();

	uint8_t key_status[256];
	bool lost_focus;

#ifdef USE_JOYSTICK
	uint32_t joy_status[4];
	int joy_num;
	bool joy_to_key_status[256];
#endif

#ifdef USE_MOUSE
	int32_t mouse_status[3];
	bool mouse_enabled;
#endif

	// screen
	void initialize_screen();
	void release_screen();
	void initialize_screen_buffer(bitmap_t *buffer, int width, int height, int mode);
	void release_screen_buffer(bitmap_t *buffer);
#ifdef USE_SCREEN_FILTER
	void apply_rgb_filter_to_screen_buffer(bitmap_t *source, bitmap_t *dest);
	void apply_rgb_filter_x3_y3(bitmap_t *source, bitmap_t *dest);
	void apply_rgb_filter_x3_y2(bitmap_t *source, bitmap_t *dest);
	void apply_rgb_filter_x2_y3(bitmap_t *source, bitmap_t *dest);
	void apply_rgb_filter_x2_y2(bitmap_t *source, bitmap_t *dest);
	void apply_rgb_filter_x1_y1(bitmap_t *source, bitmap_t *dest);
#endif
	void stretch_screen_buffer(bitmap_t *source, bitmap_t *dest);

	bitmap_t vm_screen_buffer;
#ifdef USE_SCREEN_FILTER
	bitmap_t filtered_screen_buffer;
	bitmap_t tmp_filtered_screen_buffer;
#endif
	bitmap_t stretched_screen_buffer;

	bitmap_t* draw_screen_buffer;

	int host_window_width, host_window_height;
	bool host_window_mode;
	int vm_screen_width, vm_screen_height;
	int vm_window_width, vm_window_height;
	int vm_window_width_aspect, vm_window_height_aspect;
	int draw_screen_width, draw_screen_height;

	bool first_draw_screen;
	bool first_invalidate;
	bool self_invalidate;

	// sound
	void initialize_sound(int rate, int samples);
	void release_sound();

	int sound_rate, sound_samples;
	bool sound_available, sound_started, sound_muted;
	bool sound_first_half;

	// AVAudioEngine (macOS sound output)
	// Stored as void* to avoid ARC issues (OSD is constructed from C++ context)
	// Bridged to AVAudioEngine*/AVAudioSourceNode* in osd_sound.mm
	void *audioEngine;
	void *sourceNode;
	void *speakerEQNode;
	void *reverbNode;
	void *chorusNode;
	void *chorusWetGainNode;
	void *chorusMixerNode;
	int16_t *sound_ring_buffer;
	int ring_buffer_size;        // total samples (L+R interleaved)
	std::atomic<int> ring_buffer_read_pos;
	std::atomic<int> ring_buffer_write_pos;

	_TCHAR sound_file_path[_MAX_PATH];
	FILEIO* rec_sound_fio;
	int rec_sound_bytes;
	int rec_sound_buffer_ptr;

	// midi
#ifdef USE_MIDI
	void initialize_midi();
	void release_midi();
	midi_thread_params_t midi_thread_params;
#endif

public:
	OSD()
	{
		lock_count = 0;
		audioEngine = NULL;
		sourceNode = NULL;
		speakerEQNode = NULL;
		reverbNode = NULL;
		chorusNode = NULL;
		chorusWetGainNode = NULL;
		chorusMixerNode = NULL;
		sound_ring_buffer = NULL;
	}
	~OSD() {}

	// common
	VM_TEMPLATE* vm;

	void initialize(int rate, int samples);
	void release();
	void power_off();
	void suspend();
	void restore();
	void lock_vm();
	void unlock_vm();
	bool is_vm_locked()
	{
		return (lock_count != 0);
	}
	void force_unlock_vm();
	void sleep(uint32_t ms);

	// common debugger
#ifdef USE_DEBUGGER
	void start_waiting_in_debugger();
	void finish_waiting_in_debugger();
	void process_waiting_in_debugger();
#endif

	// common console
	void open_console(int width, int height, const _TCHAR* title);
	void close_console();
	unsigned int get_console_code_page();
	void set_console_code_page(unsigned int cp);
	void get_console_cursor_position(int *x, int *y);
	void set_console_cursor_position(int x, int y);
	void set_console_text_attribute(unsigned short attr);
	void write_console(const _TCHAR* buffer, unsigned int length);
	void write_console_char(const char* buffer, unsigned int length);
	void write_console_wchar(const wchar_t* buffer, unsigned int length);
	int read_console_input(_TCHAR* buffer, unsigned int length);
	bool is_console_key_pressed(int vk);
	bool is_console_closed();
	void close_debugger_console();

	// common input
	void update_input();
	void key_down(int code, bool extended, bool repeat);
	void key_up(int code, bool extended);
	void key_down_native(int code, bool repeat);
	void key_up_native(int code);
	void key_lost_focus()
	{
		lost_focus = true;
	}
#ifdef USE_MOUSE
	void enable_mouse();
	void disable_mouse();
	void toggle_mouse();
	bool is_mouse_enabled()
	{
		return mouse_enabled;
	}
#endif
	uint8_t* get_key_buffer()
	{
		return key_status;
	}
#ifdef USE_JOYSTICK
	uint32_t* get_joy_buffer()
	{
		return joy_status;
	}
#endif
#ifdef USE_MOUSE
	int32_t* get_mouse_buffer()
	{
		return mouse_status;
	}
#endif
#ifdef USE_AUTO_KEY
	bool now_auto_key;
#endif

	// common screen
	double get_window_mode_power(int mode);
	int get_window_mode_width(int mode);
	int get_window_mode_height(int mode);
	void set_host_window_size(int window_width, int window_height, bool window_mode);
	void set_vm_screen_size(int screen_width, int screen_height, int window_width, int window_height, int window_width_aspect, int window_height_aspect);
	void set_vm_screen_lines(int lines);
	int get_vm_window_width()
	{
		return vm_window_width;
	}
	int get_vm_window_height()
	{
		return vm_window_height;
	}
	int get_vm_window_width_aspect()
	{
		return vm_window_width_aspect;
	}
	int get_vm_window_height_aspect()
	{
		return vm_window_height_aspect;
	}
	scrntype_t* get_vm_screen_buffer(int y);
	int draw_screen();
	void capture_screen();
	bool start_record_video(int fps);
	void stop_record_video();
	void restart_record_video();
	void add_extra_frames(int extra_frames);
	bool now_record_video;
#ifdef USE_SCREEN_FILTER
	bool screen_skip_line;
#endif

	// common sound
	void update_sound(int* extra_frames);
	void mute_sound();
	void stop_sound();
	void set_speaker_simulation(bool enabled);
	void set_reverb(bool enabled);
	void set_chorus(bool enabled);
	void start_record_sound();
	void stop_record_sound();
	void restart_record_sound();
	bool now_record_sound;

	// common printer
#ifdef USE_PRINTER
	void create_bitmap(bitmap_t *bitmap, int width, int height);
	void release_bitmap(bitmap_t *bitmap);
	void create_font(font_t *font, const _TCHAR *family, int width, int height, int rotate, bool bold, bool italic);
	void release_font(font_t *font);
	void create_pen(pen_t *pen, int width, uint8_t r, uint8_t g, uint8_t b);
	void release_pen(pen_t *pen);
	void clear_bitmap(bitmap_t *bitmap, uint8_t r, uint8_t g, uint8_t b);
	int get_text_width(bitmap_t *bitmap, font_t *font, const char *text);
	void draw_text_to_bitmap(bitmap_t *bitmap, font_t *font, int x, int y, const char *text, uint8_t r, uint8_t g, uint8_t b);
	void draw_line_to_bitmap(bitmap_t *bitmap, pen_t *pen, int sx, int sy, int ex, int ey);
	void draw_rectangle_to_bitmap(bitmap_t *bitmap, int x, int y, int width, int height, uint8_t r, uint8_t g, uint8_t b);
	void draw_point_to_bitmap(bitmap_t *bitmap, int x, int y, uint8_t r, uint8_t g, uint8_t b);
	void stretch_bitmap(bitmap_t *dest, int dest_x, int dest_y, int dest_width, int dest_height, bitmap_t *source, int source_x, int source_y, int source_width, int source_height);
#endif
	void write_bitmap_to_file(bitmap_t *bitmap, const _TCHAR *file_path);

	// common midi
#ifdef USE_MIDI
	void send_to_midi(uint8_t data);
	bool recv_from_midi(uint8_t *data);
#endif

	// macOS specific
	scrntype_t* get_screen_buffer() { return draw_screen_buffer ? draw_screen_buffer->lpBmp : NULL; }
	int get_screen_width() { return draw_screen_width; }
	int get_screen_height() { return draw_screen_height; }
};

#endif
