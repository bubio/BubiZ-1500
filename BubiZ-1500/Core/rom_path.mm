//
//  rom_path.mm
//  BubiZ-1500
//
//  ROM file path utilities using Cocoa APIs
//

#include "rom_path.h"
#import <Foundation/Foundation.h>
#include <cstdarg>

// Static buffer for ROM directory path (using TCHAR for compatibility)
static _TCHAR rom_directory_path[_MAX_PATH] = {0};
static bool rom_path_initialized = false;

// Static buffers for file paths (8 rotating buffers like create_local_path)
static _TCHAR rom_file_path[8][_MAX_PATH];
static unsigned int rom_path_table_index = 0;

/**
 * Initialize and get the ROM directory path
 * Creates ~/Library/Application Support/EmuZ-1500/ROM/ if it doesn't exist
 */
const _TCHAR *get_rom_directory_path(void)
{
	if (!rom_path_initialized) {
		@autoreleasepool {
			// Get Application Support directory
			NSArray *paths = NSSearchPathForDirectoriesInDomains(
				NSApplicationSupportDirectory,
				NSUserDomainMask,
				YES
			);
			NSString *appSupportDir = paths.firstObject;
			NSLog(@"Application Support: %@", appSupportDir);

			// Create BubiZ-1500/ROM subdirectory
			NSString *appDir = [appSupportDir stringByAppendingPathComponent:@"BubiZ-1500"];
			NSString *romDir = [appDir stringByAppendingPathComponent:@"ROM"];
			NSLog(@"ROM Directory: %@", romDir);

			// Create directory if it doesn't exist
			NSFileManager *fm = [NSFileManager defaultManager];
			if (![fm fileExistsAtPath:romDir]) {
				NSError *error = nil;
				BOOL success = [fm createDirectoryAtPath:romDir
							  withIntermediateDirectories:YES
											   attributes:nil
													error:&error];
				if (!success) {
					NSLog(@"Failed to create ROM directory at %@: %@", romDir, error);
				}
			}

			// Convert NSString to _TCHAR (assuming UTF-8/char for macOS)
#ifdef UNICODE
			// If UNICODE is defined, convert to wchar_t
			const char *utf8Path = [romDir UTF8String];
			mbstowcs(rom_directory_path, utf8Path, _MAX_PATH - 1);
#else
			// Otherwise, use char* directly
			const char *utf8Path = [romDir UTF8String];
			my_stprintf_s(rom_directory_path, _MAX_PATH, _T("%s/"), utf8Path);
#endif

			rom_path_initialized = true;
		}
	}

	return rom_directory_path;
}

/**
 * Create a full path to a ROM file
 * Uses rotating buffer system like create_local_path()
 */
const _TCHAR *create_rom_path(const _TCHAR *format, ...)
{
	// Get ROM directory path (initializes if needed)
	const _TCHAR *base_path = get_rom_directory_path();

	// Use rotating buffer
	unsigned int output_index = (rom_path_table_index++) & 7;

	// Build filename from format arguments
	_TCHAR file_name[_MAX_PATH];
	va_list ap;
	va_start(ap, format);
	my_vstprintf_s(file_name, _MAX_PATH, format, ap);
	va_end(ap);

	// Combine base path with filename
	my_stprintf_s(rom_file_path[output_index], _MAX_PATH, _T("%s%s"), base_path, file_name);

	return rom_file_path[output_index];
}
