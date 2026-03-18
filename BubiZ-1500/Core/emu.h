/*
	Skelton for retropc emulator

	Author : Takeda.Toshiya
	Date   : 2006.08.18 -

	[ emulation i/f ]
	[ macOS port ]
*/

#ifndef _EMU_H_
#define _EMU_H_

// for debug
//#define _DEBUG_LOG
#ifdef _DEBUG_LOG
//	#define _FDC_DEBUG_LOG
//	#define _SCSI_DEBUG_LOG
//	#define _DMA_DEBUG_LOG
//	#define _IO_DEBUG_LOG
#endif

#include <stdio.h>
#include <assert.h>
#include "common.h"
#include "config.h"
#include "vm/vm.h"

// macOS OSD
#ifdef OSD_MACOS
#include "../EmuZ-1500/macOS/osd.h"
#endif

#ifdef USE_FLOPPY_DISK
#define MAX_D88_BANKS 64
#endif
#ifdef USE_BUBBLE
#define MAX_B77_BANKS 16
#endif

class EMU;
class OSD;
class FIFO;
class FILEIO;

#ifdef USE_DEBUGGER
typedef struct {
	EMU *emu;
	OSD *osd;
	VM_TEMPLATE *vm;
	int cpu_index;
	bool running;
	bool request_terminate;
} debugger_thread_t;
#endif

class EMU
{
protected:
	VM_TEMPLATE* vm;
	OSD* osd;

private:
	// debugger
#ifdef USE_DEBUGGER
	void initialize_debugger();
	void release_debugger();
#endif

	// debug log
#ifdef _DEBUG_LOG
	void initialize_debug_log();
	void release_debug_log();
	FILE* debug_log;
#endif

	// misc
	int sound_frequency, sound_latency;
	int sound_rate, sound_samples;
#ifdef USE_CPU_TYPE
	int cpu_type;
#endif
#ifdef USE_OPTION_SWITCH
	uint32_t option_switch;
#endif
#ifdef USE_SOUND_TYPE
	int sound_type;
#endif
#ifdef USE_PRINTER_TYPE
	int printer_type;
#endif
#ifdef USE_SERIAL_TYPE
	int serial_type;
#endif
	bool now_suspended;

	// input
#ifdef USE_AUTO_KEY
	FIFO* auto_key_buffer;
	int auto_key_phase, auto_key_shift;
	bool shift_pressed;
	void initialize_auto_key();
	void release_auto_key();
	int get_auto_key_code(int code);
	void set_auto_key_code(int code);
	void update_auto_key();
#endif
#ifdef USE_JOYSTICK
	uint32_t joy_status[4];
	void update_joystick();
#endif

	// media
	typedef struct {
		_TCHAR path[_MAX_PATH];
		bool play;
		int bank;
		int wait_count;
	} media_status_t;

#ifdef USE_CART
	media_status_t cart_status[USE_CART];
#endif
#ifdef USE_FLOPPY_DISK
	media_status_t floppy_disk_status[USE_FLOPPY_DISK];
#endif
#ifdef USE_QUICK_DISK
	media_status_t quick_disk_status[USE_QUICK_DISK];
#endif
#ifdef USE_HARD_DISK
	media_status_t hard_disk_status[USE_HARD_DISK];
#endif
#ifdef USE_TAPE
	media_status_t tape_status[USE_TAPE];
#endif
#ifdef USE_COMPACT_DISC
	media_status_t compact_disc_status[USE_COMPACT_DISC];
#endif
#ifdef USE_LASER_DISC
	media_status_t laser_disc_status[USE_LASER_DISC];
#endif
#ifdef USE_BUBBLE
	media_status_t bubble_casette_status[USE_BUBBLE];
#endif

	void initialize_media();
	void update_media();
	void restore_media();

	void clear_media_status(media_status_t *status)
	{
		status->path[0] = _T('\0');
		status->wait_count = 0;
	}

	// state
#ifdef USE_STATE
	bool load_state_tmp(const _TCHAR* file_path);
#endif

public:
	EMU();
	~EMU();

	VM_TEMPLATE *get_vm()
	{
		return vm;
	}
	OSD *get_osd()
	{
		return osd;
	}

	// drive machine
	const _TCHAR *device_name();
	double get_frame_rate();
	int get_frame_interval();
	bool is_frame_skippable();
	int run();
	void reset();
#ifdef USE_SPECIAL_RESET
	void special_reset();
#endif
#ifdef USE_NOTIFY_POWER_OFF
	void notify_power_off();
#endif
	void power_off();
	void suspend();
	void lock_vm();
	void unlock_vm();
	void force_unlock_vm();
	bool is_vm_locked();

	// input
	void key_down(int code, bool extended, bool repeat);
	void key_up(int code, bool extended);
	void key_char(char code);
#ifdef USE_KEY_LOCKED
	bool get_caps_locked();
	bool get_kana_locked();
#endif
	void key_lost_focus();
#ifdef ONE_BOARD_MICRO_COMPUTER
	void press_button(int num);
#endif
#ifdef USE_MOUSE
	void enable_mouse();
	void disable_mouse();
	void toggle_mouse();
	bool is_mouse_enabled();
#endif
#ifdef USE_AUTO_KEY
	void set_auto_key_list(char *buf, int size);
	void set_auto_key_char(char code);
	void start_auto_key();
	void stop_auto_key();
	bool is_auto_key_running()
	{
		return (auto_key_phase != 0);
	}
	FIFO* get_auto_key_buffer()
	{
		return auto_key_buffer;
	}
#endif
	const uint8_t* get_key_buffer();
#ifdef USE_JOYSTICK
	const uint32_t* get_joy_buffer();
#endif
#ifdef USE_MOUSE
	const int32_t* get_mouse_buffer();
#endif

	// screen
	double get_window_mode_power(int mode);
	int get_window_mode_width(int mode);
	int get_window_mode_height(int mode);
	void set_host_window_size(int window_width, int window_height, bool window_mode);
	void set_vm_screen_size(int screen_width, int screen_height, int window_width, int window_height, int window_width_aspect, int window_height_aspect);
	void set_vm_screen_lines(int lines);
	int get_vm_window_width();
	int get_vm_window_height();
	int get_vm_window_width_aspect();
	int get_vm_window_height_aspect();
#if defined(USE_MINIMUM_RENDERING)
	bool is_screen_changed();
#endif
	int draw_screen();
	scrntype_t* get_screen_buffer(int y);
#ifdef USE_SCREEN_FILTER
	void screen_skip_line(bool skip_line);
#endif
	void capture_screen();
	bool start_record_video(int fps);
	void stop_record_video();
	bool is_video_recording();

	// sound
	int get_sound_rate()
	{
		return sound_rate;
	}
	void mute_sound();
	void start_record_sound();
	void stop_record_sound();
	bool is_sound_recording();

	// printer
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
	void write_bitmap_to_file(bitmap_t *bitmap, const _TCHAR *file_path);
#endif

	// midi
#ifdef USE_MIDI
	void send_to_midi(uint8_t data);
	bool recv_from_midi(uint8_t *data);
#endif

	// debugger
#ifdef USE_DEBUGGER
	void open_debugger(int cpu_index);
	void close_debugger();
	bool is_debugger_enabled(int cpu_index);
	bool now_debugging;
#ifdef USE_STATE
	int debugger_cpu_index, debugger_target_id;
	int request_save_state, request_load_state;
#endif
	debugger_thread_t debugger_thread_param;
	int debugger_thread_id;
	void start_waiting_in_debugger();
	void finish_waiting_in_debugger();
	void process_waiting_in_debugger();
#endif
	bool now_waiting_in_debugger;

	// debug log
	void out_debug_log(const _TCHAR* format, ...);
	void force_out_debug_log(const _TCHAR* format, ...);

	void out_message(const _TCHAR* format, ...);
	int message_count;
	_TCHAR message[1024];

	// misc
	void sleep(uint32_t ms);

	// user interface
#ifdef USE_CART
	void open_cart(int drv, const _TCHAR* file_path);
	void close_cart(int drv);
	bool is_cart_inserted(int drv);
#endif
#ifdef USE_FLOPPY_DISK
	struct {
		_TCHAR path[_MAX_PATH];
		_TCHAR disk_name[MAX_D88_BANKS][128];
		int bank_num;
		int cur_bank;
	} d88_file[USE_FLOPPY_DISK];
	bool create_blank_floppy_disk(const _TCHAR* file_path, uint8_t type);
	void open_floppy_disk(int drv, const _TCHAR* file_path, int bank);
	void close_floppy_disk(int drv);
	bool is_floppy_disk_connected(int drv);
	bool is_floppy_disk_inserted(int drv);
	void is_floppy_disk_protected(int drv, bool value);
	bool is_floppy_disk_protected(int drv);
	uint32_t is_floppy_disk_accessed();
	uint32_t floppy_disk_indicator_color();
#endif
#ifdef USE_QUICK_DISK
	void open_quick_disk(int drv, const _TCHAR* file_path);
	void close_quick_disk(int drv);
	bool is_quick_disk_connected(int drv);
	bool is_quick_disk_inserted(int drv);
	uint32_t is_quick_disk_accessed();
#endif
#ifdef USE_HARD_DISK
	bool create_blank_hard_disk(const _TCHAR* file_path, int sector_size, int sectors, int surfaces, int cylinders);
	void open_hard_disk(int drv, const _TCHAR* file_path);
	void close_hard_disk(int drv);
	bool is_hard_disk_connected(int drv);
	bool is_hard_disk_inserted(int drv);
	uint32_t is_hard_disk_accessed();
#endif
#ifdef USE_TAPE
	void play_tape(int drv, const _TCHAR* file_path);
	void rec_tape(int drv, const _TCHAR* file_path);
	void close_tape(int drv);
	bool is_tape_inserted(int drv);
	bool is_tape_playing(int drv);
	bool is_tape_recording(int drv);
	int get_tape_position(int drv);
	const _TCHAR* get_tape_message(int drv);
	void push_play(int drv);
	void push_stop(int drv);
	void push_fast_forward(int drv);
	void push_fast_rewind(int drv);
	void push_apss_forward(int drv);
	void push_apss_rewind(int drv);
#endif
#ifdef USE_COMPACT_DISC
	void open_compact_disc(int drv, const _TCHAR* file_path);
	void close_compact_disc(int drv);
	bool is_compact_disc_connected(int drv);
	bool is_compact_disc_inserted(int drv);
	uint32_t is_compact_disc_accessed();
#endif
#ifdef USE_LASER_DISC
	void open_laser_disc(int drv, const _TCHAR* file_path);
	void close_laser_disc(int drv);
	bool is_laser_disc_inserted(int drv);
	uint32_t is_laser_disc_accessed();
#endif
#ifdef USE_BINARY_FILE
	void load_binary(int drv, const _TCHAR* file_path);
	void save_binary(int drv, const _TCHAR* file_path);
#endif
#ifdef USE_BUBBLE
	struct {
		_TCHAR path[_MAX_PATH];
		_TCHAR bubble_name[MAX_B77_BANKS][128];
		int bank_num;
		int cur_bank;
	} b77_file[USE_BUBBLE];
	void open_bubble_casette(int drv, const _TCHAR* file_path, int bank);
	void close_bubble_casette(int drv);
	bool is_bubble_casette_inserted(int drv);
	void is_bubble_casette_protected(int drv, bool value);
	bool is_bubble_casette_protected(int drv);
#endif
#ifdef USE_LED_DEVICE
	uint32_t get_led_status();
#endif
#ifdef USE_SOUND_VOLUME
	void set_sound_device_volume(int ch, int decibel_l, int decibel_r);
#endif
	void update_config();

	// state
#ifdef USE_STATE
	void save_state(const _TCHAR* file_path);
	void load_state(const _TCHAR* file_path);
	const _TCHAR *state_file_path(int num);
#endif
};

#endif
