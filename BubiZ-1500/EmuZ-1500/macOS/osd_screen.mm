/*
	Skelton for retropc emulator
	macOS port

	[ macOS OSD - screen ]
*/

#include "osd.h"
#include "../../Core/fileio.h"

#ifndef WINDOW_WIDTH
#define WINDOW_WIDTH SCREEN_WIDTH
#endif
#ifndef WINDOW_HEIGHT
#define WINDOW_HEIGHT SCREEN_HEIGHT
#endif

void OSD::initialize_screen()
{
	host_window_width = WINDOW_WIDTH;
	host_window_height = WINDOW_HEIGHT;
	host_window_mode = true;

	vm_screen_width = SCREEN_WIDTH;
	vm_screen_height = SCREEN_HEIGHT;
	vm_window_width = SCREEN_WIDTH;
	vm_window_height = SCREEN_HEIGHT;
	vm_window_width_aspect = SCREEN_WIDTH;
	vm_window_height_aspect = WINDOW_HEIGHT_ASPECT;

	memset(&vm_screen_buffer, 0, sizeof(bitmap_t));
	initialize_screen_buffer(&vm_screen_buffer, SCREEN_WIDTH, SCREEN_HEIGHT, 0);

#ifdef USE_SCREEN_FILTER
	memset(&filtered_screen_buffer, 0, sizeof(bitmap_t));
	memset(&tmp_filtered_screen_buffer, 0, sizeof(bitmap_t));
	screen_skip_line = false;
#endif

	memset(&stretched_screen_buffer, 0, sizeof(bitmap_t));

	draw_screen_buffer = &vm_screen_buffer;
	draw_screen_width = SCREEN_WIDTH;
	draw_screen_height = SCREEN_HEIGHT;

	first_draw_screen = false;
	first_invalidate = true;
	self_invalidate = false;
	now_record_video = false;
}

void OSD::release_screen()
{
	release_screen_buffer(&vm_screen_buffer);
#ifdef USE_SCREEN_FILTER
	release_screen_buffer(&filtered_screen_buffer);
	release_screen_buffer(&tmp_filtered_screen_buffer);
#endif
	release_screen_buffer(&stretched_screen_buffer);
}

void OSD::initialize_screen_buffer(bitmap_t *buffer, int width, int height, int mode)
{
	release_screen_buffer(buffer);
	buffer->width = width;
	buffer->height = height;
	buffer->lpBmp = (scrntype_t *)calloc(width * height, sizeof(scrntype_t));
}

void OSD::release_screen_buffer(bitmap_t *buffer)
{
	if(buffer->lpBmp != NULL) {
		free(buffer->lpBmp);
		buffer->lpBmp = NULL;
	}
	buffer->width = 0;
	buffer->height = 0;
}

double OSD::get_window_mode_power(int mode)
{
	if(mode == 0) return 1.0;
	if(mode == 1) return 1.5;
	if(mode == 2) return 2.0;
	if(mode == 3) return 2.5;
	if(mode == 4) return 3.0;
	return 1.0;
}

int OSD::get_window_mode_width(int mode)
{
	return (int)(vm_window_width_aspect * get_window_mode_power(mode));
}

int OSD::get_window_mode_height(int mode)
{
	return (int)(vm_window_height_aspect * get_window_mode_power(mode));
}

void OSD::set_host_window_size(int window_width, int window_height, bool window_mode)
{
	host_window_width = window_width;
	host_window_height = window_height;
	host_window_mode = window_mode;
	
	// Update aspect ratio based on config
	vm_window_height_aspect = (config.window_aspect_mode == 0) ? 400 : 480;
}

void OSD::set_vm_screen_size(int screen_width, int screen_height, int window_width, int window_height, int window_width_aspect, int window_height_aspect)
{
	if(vm_screen_width != screen_width || vm_screen_height != screen_height) {
		release_screen_buffer(&vm_screen_buffer);
		initialize_screen_buffer(&vm_screen_buffer, screen_width, screen_height, 0);
	}
	vm_screen_width = screen_width;
	vm_screen_height = screen_height;
	vm_window_width = window_width;
	vm_window_height = window_height;
	vm_window_width_aspect = window_width_aspect;
	vm_window_height_aspect = window_height_aspect;
}

void OSD::set_vm_screen_lines(int lines)
{
	// stub
}

scrntype_t* OSD::get_vm_screen_buffer(int y)
{
	return vm_screen_buffer.get_buffer(y);
}

int OSD::draw_screen()
{
	// VM draws into vm_screen_buffer via get_vm_screen_buffer()
	// draw_screen_buffer points to the final buffer for display
	draw_screen_buffer = &vm_screen_buffer;

#ifdef USE_SCREEN_FILTER
	if(config.filter_type == SCREEN_FILTER_RGB) {
		int dest_pow_x = (int)ceil((double)host_window_width / (double)vm_window_width_aspect);
		int dest_pow_y = (int)ceil((double)host_window_height / (double)vm_window_height_aspect);
		if(dest_pow_x < 1) dest_pow_x = 1;
		if(dest_pow_y < 1) dest_pow_y = 1;

		int filter_width = vm_screen_width * dest_pow_x;
		int filter_height = vm_screen_height * dest_pow_y;
		if(filtered_screen_buffer.width != filter_width || filtered_screen_buffer.height != filter_height) {
			initialize_screen_buffer(&filtered_screen_buffer, filter_width, filter_height, 0);
		}
		apply_rgb_filter_to_screen_buffer(draw_screen_buffer, &filtered_screen_buffer);
		draw_screen_buffer = &filtered_screen_buffer;
	}
#endif

	draw_screen_width = draw_screen_buffer->width;
	draw_screen_height = draw_screen_buffer->height;
	first_draw_screen = true;
	return 1;
}

void OSD::capture_screen()
{
	// TODO: implement PNG capture
}

bool OSD::start_record_video(int fps)
{
	return false;
}

void OSD::stop_record_video()
{
	now_record_video = false;
}

void OSD::restart_record_video()
{
}

void OSD::add_extra_frames(int extra_frames)
{
}

#ifdef USE_PRINTER
void OSD::create_bitmap(bitmap_t *bitmap, int width, int height)
{
	bitmap->width = width;
	bitmap->height = height;
	bitmap->lpBmp = (scrntype_t *)calloc(width * height, sizeof(scrntype_t));
}

void OSD::release_bitmap(bitmap_t *bitmap)
{
	if(bitmap->lpBmp != NULL) {
		free(bitmap->lpBmp);
		bitmap->lpBmp = NULL;
	}
}

void OSD::create_font(font_t *font, const _TCHAR *family, int width, int height, int rotate, bool bold, bool italic)
{
	my_tcscpy_s(font->family, 64, family);
	font->width = width;
	font->height = height;
	font->rotate = rotate;
	font->bold = bold;
	font->italic = italic;
	font->valid = true;
}

void OSD::release_font(font_t *font)
{
	font->valid = false;
}

void OSD::create_pen(pen_t *pen, int width, uint8_t r, uint8_t g, uint8_t b)
{
	pen->width = width;
	pen->r = r;
	pen->g = g;
	pen->b = b;
	pen->valid = true;
}

void OSD::release_pen(pen_t *pen)
{
	pen->valid = false;
}

void OSD::clear_bitmap(bitmap_t *bitmap, uint8_t r, uint8_t g, uint8_t b)
{
	if(bitmap->lpBmp != NULL) {
		scrntype_t color = RGB_COLOR(r, g, b);
		for(int i = 0; i < bitmap->width * bitmap->height; i++) {
			bitmap->lpBmp[i] = color;
		}
	}
}

int OSD::get_text_width(bitmap_t *bitmap, font_t *font, const char *text)
{
	return (int)strlen(text) * font->width;
}

void OSD::draw_text_to_bitmap(bitmap_t *bitmap, font_t *font, int x, int y, const char *text, uint8_t r, uint8_t g, uint8_t b)
{
	// TODO: implement text rendering
}

void OSD::draw_line_to_bitmap(bitmap_t *bitmap, pen_t *pen, int sx, int sy, int ex, int ey)
{
	// TODO: implement line drawing
}

void OSD::draw_rectangle_to_bitmap(bitmap_t *bitmap, int x, int y, int width, int height, uint8_t r, uint8_t g, uint8_t b)
{
	if(bitmap->lpBmp != NULL) {
		scrntype_t color = RGB_COLOR(r, g, b);
		for(int yy = y; yy < y + height && yy < bitmap->height; yy++) {
			for(int xx = x; xx < x + width && xx < bitmap->width; xx++) {
				if(yy >= 0 && xx >= 0) {
					bitmap->lpBmp[yy * bitmap->width + xx] = color;
				}
			}
		}
	}
}

void OSD::draw_point_to_bitmap(bitmap_t *bitmap, int x, int y, uint8_t r, uint8_t g, uint8_t b)
{
	if(bitmap->lpBmp != NULL && x >= 0 && x < bitmap->width && y >= 0 && y < bitmap->height) {
		bitmap->lpBmp[y * bitmap->width + x] = RGB_COLOR(r, g, b);
	}
}

void OSD::stretch_bitmap(bitmap_t *dest, int dest_x, int dest_y, int dest_width, int dest_height, bitmap_t *source, int source_x, int source_y, int source_width, int source_height)
{
	// simple nearest-neighbor scaling
	if(dest->lpBmp == NULL || source->lpBmp == NULL) return;
	for(int y = 0; y < dest_height; y++) {
		int dy = dest_y + y;
		if(dy < 0 || dy >= dest->height) continue;
		int sy = source_y + y * source_height / dest_height;
		if(sy < 0 || sy >= source->height) continue;
		for(int x = 0; x < dest_width; x++) {
			int dx = dest_x + x;
			if(dx < 0 || dx >= dest->width) continue;
			int sx = source_x + x * source_width / dest_width;
			if(sx < 0 || sx >= source->width) continue;
			dest->lpBmp[dy * dest->width + dx] = source->lpBmp[sy * source->width + sx];
		}
	}
}
#endif

void OSD::stretch_screen_buffer(bitmap_t *source, bitmap_t *dest)
{
	if((dest->width % source->width) == 0 && (dest->height % source->height) == 0) {
		int pow_x = dest->width / source->width;
		int pow_y = dest->height / source->height;

		for(int y = 0, yy = 0; y < source->height; y++, yy += pow_y) {
			scrntype_t* source_buffer = source->get_buffer(y);
			scrntype_t* dest_buffer = dest->get_buffer(yy);

			if(pow_x != 1) {
				scrntype_t* tmp_buffer = dest_buffer;
				for(int x = 0; x < source->width; x++) {
					scrntype_t c = source_buffer[x];
					for(int px = 0; px < pow_x; px++) {
						tmp_buffer[px] = c;
					}
					tmp_buffer += pow_x;
				}
			} else {
				for(int x = 0; x < source->width; x++) {
					dest_buffer[x] = source_buffer[x];
				}
			}
			if(pow_y != 1) {
				for(int py = 1; py < pow_y; py++) {
					scrntype_t* tmp_buffer = dest->get_buffer(yy + py);
					for(int x = 0; x < dest->width; x++) {
						tmp_buffer[x] = dest_buffer[x];
					}
				}
			}
		}
	} else {
		// non-integer scaling: nearest neighbor
		for(int y = 0; y < dest->height; y++) {
			scrntype_t* dest_buffer = dest->get_buffer(y);
			int sy = y * source->height / dest->height;
			if(sy >= source->height) sy = source->height - 1;
			scrntype_t* source_buffer = source->get_buffer(sy);

			for(int x = 0; x < dest->width; x++) {
				int sx = x * source->width / dest->width;
				if(sx >= source->width) sx = source->width - 1;
				dest_buffer[x] = source_buffer[sx];
			}
		}
	}
}

#ifdef USE_SCREEN_FILTER
#define _3_8(v) (((((v) * 3) >> 3) * 180) >> 8)
#define _5_8(v) (((((v) * 3) >> 3) * 180) >> 8)
#define _8_8(v) (((v) * 180) >> 8)

static uint8_t r0[2048], g0[2048], b0[2048], t0[2048];
static uint8_t r1[2048], g1[2048], b1[2048];

void OSD::apply_rgb_filter_to_screen_buffer(bitmap_t *source, bitmap_t *dest)
{
	if(source->width * 6 == dest->width && source->height * 6 == dest->height) {
		if(tmp_filtered_screen_buffer.width != source->width * 2 || tmp_filtered_screen_buffer.height != source->height * 2) {
			initialize_screen_buffer(&tmp_filtered_screen_buffer, source->width * 2, source->height * 2, 0);
		}
		stretch_screen_buffer(source, &tmp_filtered_screen_buffer);
		screen_skip_line = true;
		apply_rgb_filter_x3_y3(&tmp_filtered_screen_buffer, dest);
	} else if(source->width * 3 == dest->width && source->height * 6 == dest->height) {
		if(tmp_filtered_screen_buffer.width != source->width || tmp_filtered_screen_buffer.height != source->height * 2) {
			initialize_screen_buffer(&tmp_filtered_screen_buffer, source->width, source->height * 2, 0);
		}
		stretch_screen_buffer(source, &tmp_filtered_screen_buffer);
		screen_skip_line = true;
		apply_rgb_filter_x3_y3(&tmp_filtered_screen_buffer, dest);
	} else if(source->width * 4 == dest->width && source->height * 4 == dest->height) {
		if(tmp_filtered_screen_buffer.width != source->width * 2 || tmp_filtered_screen_buffer.height != source->height * 2) {
			initialize_screen_buffer(&tmp_filtered_screen_buffer, source->width * 2, source->height * 2, 0);
		}
		stretch_screen_buffer(source, &tmp_filtered_screen_buffer);
		screen_skip_line = true;
		apply_rgb_filter_x2_y2(&tmp_filtered_screen_buffer, dest);
	} else if(source->width * 2 == dest->width && source->height * 4 == dest->height) {
		if(tmp_filtered_screen_buffer.width != source->width || tmp_filtered_screen_buffer.height != source->height * 2) {
			initialize_screen_buffer(&tmp_filtered_screen_buffer, source->width, source->height * 2, 0);
		}
		stretch_screen_buffer(source, &tmp_filtered_screen_buffer);
		screen_skip_line = true;
		apply_rgb_filter_x2_y2(&tmp_filtered_screen_buffer, dest);
	} else if(source->width * 3 == dest->width && source->height * 3 == dest->height) {
		apply_rgb_filter_x3_y3(source, dest);
	} else if(source->width * 3 == dest->width && source->height * 2 == dest->height) {
		apply_rgb_filter_x3_y2(source, dest);
	} else if(source->width * 2 == dest->width && source->height * 3 == dest->height) {
		apply_rgb_filter_x2_y3(source, dest);
	} else if(source->width * 2 == dest->width && source->height * 2 == dest->height) {
		apply_rgb_filter_x2_y2(source, dest);
	} else if(source->width != dest->width || source->height != dest->height) {
		if(tmp_filtered_screen_buffer.width != source->width || tmp_filtered_screen_buffer.height != source->height) {
			initialize_screen_buffer(&tmp_filtered_screen_buffer, source->width, source->height, 0);
		}
		apply_rgb_filter_x1_y1(source, &tmp_filtered_screen_buffer);
		stretch_screen_buffer(&tmp_filtered_screen_buffer, dest);
	} else {
		apply_rgb_filter_x1_y1(source, dest);
	}
}

void OSD::apply_rgb_filter_x3_y3(bitmap_t *source, bitmap_t *dest)
{
	if(!screen_skip_line) {
		for(int y = 0, yy = 0; y < source->height; y++, yy += 3) {
			scrntype_t* src = source->get_buffer(y);
			scrntype_t* out1 = dest->get_buffer(yy + 0);
			scrntype_t* out2 = dest->get_buffer(yy + 1);
			scrntype_t* out3 = dest->get_buffer(yy + 2);

			for(int x = 1; x <= source->width; x++) {
				scrntype_t c = src[x - 1];
				t0[x] = A_OF_COLOR(c);
				r0[x] = R_OF_COLOR(c);
				g0[x] = G_OF_COLOR(c);
				b0[x] = B_OF_COLOR(c);
				r1[x] = r0[x] >> 3;
				g1[x] = g0[x] >> 3;
				b1[x] = b0[x] >> 3;
			}
			for(int x = 1, xx = 0; x <= source->width; x++, xx += 3) {
				uint32_t r = r1[x - 1] + r0[x] + r1[x + 1];
				uint32_t g = g1[x - 1] + g0[x] + g1[x + 1];
				uint32_t b = b1[x - 1] + b0[x] + b1[x + 1];
				out1[xx    ] = out2[xx    ] = (32 + _8_8(r)) << 16;
				out1[xx + 1] = out2[xx + 1] = (32 + _8_8(g)) << 8;
				out1[xx + 2] = out2[xx + 2] = (32 + _8_8(b));
				if(t0[x]) {
					out3[xx    ] = (32 + _8_8(r)) << 16;
					out3[xx + 1] = (32 + _8_8(g)) << 8;
					out3[xx + 2] = (32 + _8_8(b));
				} else {
					out3[xx    ] = (32 + _5_8(r)) << 16;
					out3[xx + 1] = (32 + _5_8(g)) << 8;
					out3[xx + 2] = (32 + _5_8(b));
				}
			}
		}
	} else {
		for(int y = 0, yy = 0; y < source->height; y += 2, yy += 6) {
			scrntype_t* src = source->get_buffer(y);
			scrntype_t* out1 = dest->get_buffer(yy + 0);
			scrntype_t* out2 = dest->get_buffer(yy + 1);
			scrntype_t* out3 = dest->get_buffer(yy + 2);
			scrntype_t* out4 = dest->get_buffer(yy + 3);
			scrntype_t* out5 = dest->get_buffer(yy + 4);
			scrntype_t* out6 = dest->get_buffer(yy + 5);

			for(int x = 1; x <= source->width; x++) {
				scrntype_t c = src[x - 1];
				t0[x] = A_OF_COLOR(c);
				r0[x] = R_OF_COLOR(c);
				g0[x] = G_OF_COLOR(c);
				b0[x] = B_OF_COLOR(c);
				r1[x] = r0[x] >> 3;
				g1[x] = g0[x] >> 3;
				b1[x] = b0[x] >> 3;
			}
			for(int x = 1, xx = 0; x <= source->width; x++, xx += 3) {
				uint32_t r = r1[x - 1] + r0[x] + r1[x + 1];
				uint32_t g = g1[x - 1] + g0[x] + g1[x + 1];
				uint32_t b = b1[x - 1] + b0[x] + b1[x + 1];
				out1[xx    ] = out2[xx    ] = out3[xx    ] = out4[xx    ] = (32 + _8_8(r)) << 16;
				out1[xx + 1] = out2[xx + 1] = out3[xx + 1] = out4[xx + 1] = (32 + _8_8(g)) << 8;
				out1[xx + 2] = out2[xx + 2] = out3[xx + 2] = out4[xx + 2] = (32 + _8_8(b));
				if(t0[x]) {
					out5[xx    ] = out6[xx    ] = (32 + _8_8(r)) << 16;
					out5[xx + 1] = out6[xx + 1] = (32 + _8_8(g)) << 8;
					out5[xx + 2] = out6[xx + 2] = (32 + _8_8(b));
				} else {
					out5[xx    ] = out6[xx    ] = (32 + _5_8(r)) << 16;
					out5[xx + 1] = out6[xx + 1] = (32 + _5_8(g)) << 8;
					out5[xx + 2] = out6[xx + 2] = (32 + _5_8(b));
				}
			}
		}
	}
}

void OSD::apply_rgb_filter_x3_y2(bitmap_t *source, bitmap_t *dest)
{
	if(!screen_skip_line) {
		for(int y = 0, yy = 0; y < source->height; y++, yy += 2) {
			scrntype_t* src = source->get_buffer(y);
			scrntype_t* out1 = dest->get_buffer(yy + 0);
			scrntype_t* out2 = dest->get_buffer(yy + 1);

			for(int x = 1; x <= source->width; x++) {
				scrntype_t c = src[x - 1];
				t0[x] = A_OF_COLOR(c);
				r0[x] = R_OF_COLOR(c);
				g0[x] = G_OF_COLOR(c);
				b0[x] = B_OF_COLOR(c);
				r1[x] = r0[x] >> 3;
				g1[x] = g0[x] >> 3;
				b1[x] = b0[x] >> 3;
			}
			for(int x = 1, xx = 0; x <= source->width; x++, xx += 3) {
				uint32_t r = r1[x - 1] + r0[x] + r1[x + 1];
				uint32_t g = g1[x - 1] + g0[x] + g1[x + 1];
				uint32_t b = b1[x - 1] + b0[x] + b1[x + 1];
				out1[xx    ] = (32 + _8_8(r)) << 16;
				out1[xx + 1] = (32 + _8_8(g)) << 8;
				out1[xx + 2] = (32 + _8_8(b));
				if(t0[x]) {
					out2[xx    ] = (32 + _8_8(r)) << 16;
					out2[xx + 1] = (32 + _8_8(g)) << 8;
					out2[xx + 2] = (32 + _8_8(b));
				} else {
					out2[xx    ] = (32 + _5_8(r)) << 16;
					out2[xx + 1] = (32 + _5_8(g)) << 8;
					out2[xx + 2] = (32 + _5_8(b));
				}
			}
		}
	} else {
		for(int y = 0, yy = 0; y < source->height; y += 2, yy += 4) {
			scrntype_t* src = source->get_buffer(y);
			scrntype_t* out1 = dest->get_buffer(yy + 0);
			scrntype_t* out2 = dest->get_buffer(yy + 1);
			scrntype_t* out3 = dest->get_buffer(yy + 2);
			scrntype_t* out4 = dest->get_buffer(yy + 3);

			for(int x = 1; x <= source->width; x++) {
				scrntype_t c = src[x - 1];
				t0[x] = A_OF_COLOR(c);
				r0[x] = R_OF_COLOR(c);
				g0[x] = G_OF_COLOR(c);
				b0[x] = B_OF_COLOR(c);
				r1[x] = r0[x] >> 3;
				g1[x] = g0[x] >> 3;
				b1[x] = b0[x] >> 3;
			}
			for(int x = 1, xx = 0; x <= source->width; x++, xx += 3) {
				uint32_t r = r1[x - 1] + r0[x] + r1[x + 1];
				uint32_t g = g1[x - 1] + g0[x] + g1[x + 1];
				uint32_t b = b1[x - 1] + b0[x] + b1[x + 1];
				out1[xx    ] = out2[xx    ] = out3[xx    ] = (32 + _8_8(r)) << 16;
				out1[xx + 1] = out2[xx + 1] = out3[xx + 1] = (32 + _8_8(g)) << 8;
				out1[xx + 2] = out2[xx + 2] = out3[xx + 2] = (32 + _8_8(b));
				if(t0[x]) {
					out4[xx    ] = (32 + _8_8(r)) << 16;
					out4[xx + 1] = (32 + _8_8(g)) << 8;
					out4[xx + 2] = (32 + _8_8(b));
				} else {
					out4[xx    ] = (32 + _5_8(r)) << 16;
					out4[xx + 1] = (32 + _5_8(g)) << 8;
					out4[xx + 2] = (32 + _5_8(b));
				}
			}
		}
	}
}

void OSD::apply_rgb_filter_x2_y3(bitmap_t *source, bitmap_t *dest)
{
	if(!screen_skip_line) {
		for(int y = 0, yy = 0; y < source->height; y++, yy += 3) {
			scrntype_t* src = source->get_buffer(y);
			scrntype_t* out1 = dest->get_buffer(yy + 0);
			scrntype_t* out2 = dest->get_buffer(yy + 1);
			scrntype_t* out3 = dest->get_buffer(yy + 2);

			for(int x = 1; x <= source->width; x++) {
				scrntype_t c = src[x - 1];
				t0[x] = A_OF_COLOR(c);
				r0[x] = R_OF_COLOR(c);
				g0[x] = G_OF_COLOR(c);
				b0[x] = B_OF_COLOR(c);
				r1[x] = r0[x] >> 3;
				g1[x] = g0[x] >> 3;
				b1[x] = b0[x] >> 3;
			}
			for(int x = 1, xx = 0; x <= source->width; x++, xx += 2) {
				uint32_t r = r1[x - 1] + r0[x] + r1[x + 1];
				uint32_t g = g1[x - 1] + g0[x] + g1[x + 1];
				uint32_t b = b1[x - 1] + b0[x] + b1[x + 1];
				out1[xx    ] = out2[xx    ] = RGB_COLOR(32 + _8_8(r), 32 + _8_8(g), 32 + _8_8(b));
				out1[xx + 1] = out2[xx + 1] = RGB_COLOR(16 + _5_8(r), 16 + _5_8(g), 16 + _5_8(b));
				if(t0[x]) {
					out3[xx    ] = RGB_COLOR(32 + _8_8(r), 32 + _8_8(g), 32 + _8_8(b));
					out3[xx + 1] = RGB_COLOR(16 + _5_8(r), 16 + _5_8(g), 16 + _5_8(b));
				} else {
					out3[xx    ] = RGB_COLOR(32 + _3_8(r), 32 + _3_8(g), 32 + _3_8(b));
					out3[xx + 1] = RGB_COLOR(16 + _3_8(r), 16 + _3_8(g), 16 + _3_8(b));
				}
			}
		}
	} else {
		for(int y = 0, yy = 0; y < source->height; y += 2, yy += 6) {
			scrntype_t* src = source->get_buffer(y);
			scrntype_t* out1 = dest->get_buffer(yy + 0);
			scrntype_t* out2 = dest->get_buffer(yy + 1);
			scrntype_t* out3 = dest->get_buffer(yy + 2);
			scrntype_t* out4 = dest->get_buffer(yy + 3);
			scrntype_t* out5 = dest->get_buffer(yy + 4);
			scrntype_t* out6 = dest->get_buffer(yy + 5);

			for(int x = 1; x <= source->width; x++) {
				scrntype_t c = src[x - 1];
				t0[x] = A_OF_COLOR(c);
				r0[x] = R_OF_COLOR(c);
				g0[x] = G_OF_COLOR(c);
				b0[x] = B_OF_COLOR(c);
				r1[x] = r0[x] >> 3;
				g1[x] = g0[x] >> 3;
				b1[x] = b0[x] >> 3;
			}
			for(int x = 1, xx = 0; x <= source->width; x++, xx += 2) {
				uint32_t r = r1[x - 1] + r0[x] + r1[x + 1];
				uint32_t g = g1[x - 1] + g0[x] + g1[x + 1];
				uint32_t b = b1[x - 1] + b0[x] + b1[x + 1];
				out1[xx    ] = out2[xx    ] = out3[xx    ] = out4[xx    ] = RGB_COLOR(32 + _8_8(r), 32 + _8_8(g), 32 + _8_8(b));
				out1[xx + 1] = out2[xx + 1] = out3[xx + 1] = out4[xx + 1] = RGB_COLOR(16 + _5_8(r), 16 + _5_8(g), 16 + _5_8(b));
				if(t0[x]) {
					out5[xx    ] = out6[xx    ] = RGB_COLOR(32 + _8_8(r), 32 + _8_8(g), 32 + _8_8(b));
					out5[xx + 1] = out6[xx + 1] = RGB_COLOR(16 + _5_8(r), 16 + _5_8(g), 16 + _5_8(b));
				} else {
					out5[xx    ] = out6[xx    ] = RGB_COLOR(32 + _3_8(r), 32 + _3_8(g), 32 + _3_8(b));
					out5[xx + 1] = out6[xx + 1] = RGB_COLOR(16 + _3_8(r), 16 + _3_8(g), 16 + _3_8(b));
				}
			}
		}
	}
}

void OSD::apply_rgb_filter_x2_y2(bitmap_t *source, bitmap_t *dest)
{
	if(!screen_skip_line) {
		for(int y = 0, yy = 0; y < source->height; y++, yy += 2) {
			scrntype_t* src = source->get_buffer(y);
			scrntype_t* out1 = dest->get_buffer(yy + 0);
			scrntype_t* out2 = dest->get_buffer(yy + 1);

			for(int x = 1; x <= source->width; x++) {
				scrntype_t c = src[x - 1];
				t0[x] = A_OF_COLOR(c);
				r0[x] = R_OF_COLOR(c);
				g0[x] = G_OF_COLOR(c);
				b0[x] = B_OF_COLOR(c);
				r1[x] = r0[x] >> 3;
				g1[x] = g0[x] >> 3;
				b1[x] = b0[x] >> 3;
			}
			for(int x = 1, xx = 0; x <= source->width; x++, xx += 2) {
				uint32_t r = r1[x - 1] + r0[x] + r1[x + 1];
				uint32_t g = g1[x - 1] + g0[x] + g1[x + 1];
				uint32_t b = b1[x - 1] + b0[x] + b1[x + 1];
				out1[xx    ] = RGB_COLOR(32 + _8_8(r), 32 + _8_8(g), 32 + _8_8(b));
				out1[xx + 1] = RGB_COLOR(16 + _5_8(r), 16 + _5_8(g), 16 + _5_8(b));
				if(t0[x]) {
					out2[xx    ] = RGB_COLOR(32 + _8_8(r), 32 + _8_8(g), 32 + _8_8(b));
					out2[xx + 1] = RGB_COLOR(16 + _5_8(r), 16 + _5_8(g), 16 + _5_8(b));
				} else {
					out2[xx    ] = RGB_COLOR(32 + _3_8(r), 32 + _3_8(g), 32 + _3_8(b));
					out2[xx + 1] = RGB_COLOR(16 + _3_8(r), 16 + _3_8(g), 16 + _3_8(b));
				}
			}
		}
	} else {
		for(int y = 0, yy = 0; y < source->height; y += 2, yy += 4) {
			scrntype_t* src = source->get_buffer(y);
			scrntype_t* out1 = dest->get_buffer(yy + 0);
			scrntype_t* out2 = dest->get_buffer(yy + 1);
			scrntype_t* out3 = dest->get_buffer(yy + 2);
			scrntype_t* out4 = dest->get_buffer(yy + 3);

			for(int x = 1; x <= source->width; x++) {
				scrntype_t c = src[x - 1];
				t0[x] = A_OF_COLOR(c);
				r0[x] = R_OF_COLOR(c);
				g0[x] = G_OF_COLOR(c);
				b0[x] = B_OF_COLOR(c);
				r1[x] = r0[x] >> 3;
				g1[x] = g0[x] >> 3;
				b1[x] = b0[x] >> 3;
			}
			for(int x = 1, xx = 0; x <= source->width; x++, xx += 2) {
				uint32_t r = r1[x - 1] + r0[x] + r1[x + 1];
				uint32_t g = g1[x - 1] + g0[x] + g1[x + 1];
				uint32_t b = b1[x - 1] + b0[x] + b1[x + 1];
				out1[xx    ] = out2[xx    ] = out3[xx    ] = RGB_COLOR(32 + _8_8(r), 32 + _8_8(g), 32 + _8_8(b));
				out1[xx + 1] = out2[xx + 1] = out3[xx + 1] = RGB_COLOR(16 + _5_8(r), 16 + _5_8(g), 16 + _5_8(b));
				if(t0[x]) {
					out4[xx    ] = RGB_COLOR(32 + _8_8(r), 32 + _8_8(g), 32 + _8_8(b));
					out4[xx + 1] = RGB_COLOR(16 + _5_8(r), 16 + _5_8(g), 16 + _5_8(b));
				} else {
					out4[xx    ] = RGB_COLOR(32 + _3_8(r), 32 + _3_8(g), 32 + _3_8(b));
					out4[xx + 1] = RGB_COLOR(16 + _3_8(r), 16 + _3_8(g), 16 + _3_8(b));
				}
			}
		}
	}
}

void OSD::apply_rgb_filter_x1_y1(bitmap_t *source, bitmap_t *dest)
{
	if(!screen_skip_line) {
		for(int y = 0; y < source->height; y++) {
			scrntype_t* src = source->get_buffer(y);
			scrntype_t* out1 = dest->get_buffer(y);

			for(int x = 1; x <= source->width; x++) {
				scrntype_t c = src[x - 1];
				r0[x] = R_OF_COLOR(c);
				g0[x] = G_OF_COLOR(c);
				b0[x] = B_OF_COLOR(c);
				r1[x] = r0[x] >> 3;
				g1[x] = g0[x] >> 3;
				b1[x] = b0[x] >> 3;
			}
			for(int x = 1; x <= source->width; x++) {
				uint32_t r = r1[x - 1] + r0[x] + r1[x + 1];
				uint32_t g = g1[x - 1] + g0[x] + g1[x + 1];
				uint32_t b = b1[x - 1] + b0[x] + b1[x + 1];
				out1[x - 1] = RGB_COLOR(32 + _8_8(r), 32 + _8_8(g), 32 + _8_8(b));
			}
		}
	} else {
		for(int y = 0; y < source->height; y += 2) {
			scrntype_t* src = source->get_buffer(y);
			scrntype_t* out1 = dest->get_buffer(y + 0);
			scrntype_t* out2 = dest->get_buffer(y + 1);

			for(int x = 1; x <= source->width; x++) {
				scrntype_t c = src[x - 1];
				t0[x] = A_OF_COLOR(c);
				r0[x] = R_OF_COLOR(c);
				g0[x] = G_OF_COLOR(c);
				b0[x] = B_OF_COLOR(c);
				r1[x] = r0[x] >> 3;
				g1[x] = g0[x] >> 3;
				b1[x] = b0[x] >> 3;
			}
			for(int x = 1; x <= source->width; x++) {
				uint32_t r = r1[x - 1] + r0[x] + r1[x + 1];
				uint32_t g = g1[x - 1] + g0[x] + g1[x + 1];
				uint32_t b = b1[x - 1] + b0[x] + b1[x + 1];
				out1[x - 1] = RGB_COLOR(32 + _8_8(r), 32 + _8_8(g), 32 + _8_8(b));
				if(t0[x]) {
					out2[x - 1] = RGB_COLOR(32 + _8_8(r), 32 + _8_8(g), 32 + _8_8(b));
				} else {
					out2[x - 1] = RGB_COLOR(32 + _3_8(r), 32 + _3_8(g), 32 + _3_8(b));
				}
			}
		}
	}
}
#endif

void OSD::write_bitmap_to_file(bitmap_t *bitmap, const _TCHAR *file_path)
{
	// TODO: implement PNG writing
}
