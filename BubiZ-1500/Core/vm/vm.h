/*
	Skelton for retropc emulator

	[ virtual machine - MZ-1500 only ]
*/

#ifndef _VM_H_
#define _VM_H_

// MZ-1500 specific
#include "mz700/mz700.h"

// Default base drive/media numbers (fallback if not defined by VM)
#if defined(USE_CART) && !defined(BASE_CART_NUM)
	#define BASE_CART_NUM		1
#endif
#if defined(USE_FLOPPY_DISK) && !defined(BASE_FLOPPY_DISK_NUM)
	#define BASE_FLOPPY_DISK_NUM	1
#endif
#if defined(USE_QUICK_DISK) && !defined(BASE_QUICK_DISK_NUM)
	#define BASE_QUICK_DISK_NUM	1
#endif
#if defined(USE_HARD_DISK) && !defined(BASE_HARD_DISK_NUM)
	#define BASE_HARD_DISK_NUM	1
#endif
#if defined(USE_TAPE) && !defined(BASE_TAPE_NUM)
	#define BASE_TAPE_NUM		1
#endif
#if defined(USE_COMPACT_DISC) && !defined(BASE_COMPACT_DISC_NUM)
	#define BASE_COMPACT_DISC_NUM	1
#endif
#if defined(USE_LASER_DISC) && !defined(BASE_LASER_DISC_NUM)
	#define BASE_LASER_DISC_NUM	1
#endif
#if defined(USE_BINARY_FILE) && !defined(BASE_BINARY_FILE_NUM)
	#define BASE_BINARY_FILE_NUM	1
#endif
#if defined(USE_BUBBLE) && !defined(BASE_BUBBLE_NUM)
	#define BASE_BUBBLE_NUM		1
#endif

#ifndef KEY_KEEP_FRAMES
	#define KEY_KEEP_FRAMES 3
#endif

#endif
