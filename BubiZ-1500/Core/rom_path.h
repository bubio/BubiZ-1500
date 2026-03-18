//
//  rom_path.h
//  BubiZ-1500
//
//  ROM file path utilities for Application Support directory
//

#ifndef rom_path_h
#define rom_path_h

#include "common.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Get the ROM directory path in Application Support
 * Returns: ~/Library/Application Support/EmuZ-1500/ROM/
 * Creates the directory if it doesn't exist
 */
const _TCHAR *get_rom_directory_path(void);

/**
 * Create a full path to a ROM file in Application Support
 * Same signature as create_local_path() but points to ROM directory
 *
 * Example: create_rom_path(_T("IPL.ROM"))
 * Returns: ~/Library/Application Support/EmuZ-1500/ROM/IPL.ROM
 */
const _TCHAR *create_rom_path(const _TCHAR *format, ...);

#ifdef __cplusplus
}
#endif

#endif /* rom_path_h */
