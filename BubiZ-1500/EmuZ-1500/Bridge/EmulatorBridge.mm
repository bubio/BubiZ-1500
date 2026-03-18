//
//  EmulatorBridge.mm
//  EmuZ-1500
//
//  Objective-C++ bridge between Swift UI and C++ emulator core
//

#import "EmulatorBridge.h"
#include "../../Core/emu.h"
#include "../../Core/config.h"

@implementation EmulatorBridge {
	EMU *_emu;
	NSString *_tapeFilePath;
}

- (instancetype)init
{
	self = [super init];
	if (self) {
		_emu = nullptr;
		_isRunning = NO;
	}
	return self;
}

- (void)dealloc
{
	[self shutdown];
}

- (void)startup
{
	if (_emu != nullptr) {
		return;
	}

	// Initialize config
	initialize_config();

	// Load config if exists
	NSString *configPath = [self configFilePath];
	load_config([configPath UTF8String]);

	// Create EMU instance
	_emu = new EMU();
	_isRunning = YES;
}

- (void)shutdown
{
	if (_emu != nullptr) {
		// Save config
		NSString *configPath = [self configFilePath];
		save_config([configPath UTF8String]);

		delete _emu;
		_emu = nullptr;
	}
	_isRunning = NO;
}

- (void)reset
{
	if (_emu != nullptr) {
		_emu->reset();
	}
}

// MARK: - Emulation loop

- (int)runFrame
{
	if (_emu == nullptr) return 0;
	return _emu->run();
}

- (void)drawScreen
{
	if (_emu == nullptr) return;
	_emu->draw_screen();
}

// MARK: - Screen

- (nullable const uint32_t *)screenBuffer
{
	if (_emu == nullptr) return nullptr;
	return _emu->get_osd()->get_screen_buffer();
}

- (int)screenWidth
{
	if (_emu == nullptr) return 0;
	return _emu->get_osd()->get_screen_width();
}

- (int)screenHeight
{
	if (_emu == nullptr) return 0;
	return _emu->get_osd()->get_screen_height();
}

- (int)vmWindowWidth
{
	if (_emu == nullptr) return 0;
	return _emu->get_vm_window_width();
}

- (int)vmWindowHeight
{
	if (_emu == nullptr) return 0;
	return _emu->get_vm_window_height();
}

- (int)vmWindowWidthAspect
{
	if (_emu == nullptr) return 0;
	return _emu->get_vm_window_width_aspect();
}

- (int)vmWindowHeightAspect
{
	if (_emu == nullptr) return 0;
	return _emu->get_vm_window_height_aspect();
}

- (double)frameRate
{
	if (_emu == nullptr) return 60.0;
	return _emu->get_frame_rate();
}

- (nullable NSString *)deviceName
{
	if (_emu == nullptr) return nil;
	const char *name = _emu->device_name();
	return name ? [NSString stringWithUTF8String:name] : nil;
}

// MARK: - Input

- (void)keyDown:(int)vkCode extended:(BOOL)extended repeat:(BOOL)repeat
{
	if (_emu != nullptr) {
		_emu->key_down(vkCode, extended, repeat);
	}
}

- (void)keyUp:(int)vkCode extended:(BOOL)extended
{
	if (_emu != nullptr) {
		_emu->key_up(vkCode, extended);
	}
}

- (void)keyLostFocus
{
	if (_emu != nullptr) {
		_emu->key_lost_focus();
	}
}

// MARK: - Media

- (void)playTape:(int)drv path:(NSString *)path
{
	if (_emu != nullptr) {
		_tapeFilePath = [path copy];
		_emu->play_tape(drv, [path UTF8String]);
	}
}

- (void)recTape:(int)drv path:(NSString *)path
{
	if (_emu != nullptr) {
		_emu->rec_tape(drv, [path UTF8String]);
	}
}

- (void)closeTape:(int)drv
{
	if (_emu != nullptr) {
		_emu->close_tape(drv);
		_tapeFilePath = nil;
	}
}

- (BOOL)isTapeInserted:(int)drv
{
	if (_emu == nullptr) return NO;
	return _emu->is_tape_inserted(drv) ? YES : NO;
}

- (BOOL)hasTapeFilePath
{
	return _tapeFilePath != nil;
}

- (void)openFloppyDisk:(int)drv path:(NSString *)path bank:(int)bank
{
	if (_emu != nullptr) {
		_emu->open_floppy_disk(drv, [path UTF8String], bank);
	}
}

- (void)closeFloppyDisk:(int)drv
{
	if (_emu != nullptr) {
		_emu->close_floppy_disk(drv);
	}
}

- (BOOL)isFloppyDiskInserted:(int)drv
{
	if (_emu == nullptr) return NO;
	return _emu->is_floppy_disk_inserted(drv) ? YES : NO;
}

- (void)openQuickDisk:(int)drv path:(NSString *)path
{
	if (_emu != nullptr) {
		_emu->open_quick_disk(drv, [path UTF8String]);
	}
}

- (void)closeQuickDisk:(int)drv
{
	if (_emu != nullptr) {
		_emu->close_quick_disk(drv);
	}
}

- (BOOL)isQuickDiskInserted:(int)drv
{
	if (_emu == nullptr) return NO;
	return _emu->is_quick_disk_inserted(drv) ? YES : NO;
}

// MARK: - Disk Name

- (nullable NSString *)floppyDiskName:(int)drv
{
	if (_emu == nullptr) return nil;
	if (!_emu->is_floppy_disk_inserted(drv)) return nil;
	int bank = _emu->d88_file[drv].cur_bank;
	const char *name = (const char *)_emu->d88_file[drv].disk_name[bank];
	if (name == nullptr || name[0] == '\0') return nil;
	// D88ヘッダーのタイトルはShift_JISエンコーディング
	NSData *data = [NSData dataWithBytes:name length:strnlen(name, 127)];
	NSString *str = [[NSString alloc] initWithData:data encoding:NSShiftJISStringEncoding];
	if (str == nil) {
		str = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	}
	return str;
}

// MARK: - Tape Transport Control

- (void)pushPlay:(int)drv
{
	if (_emu != nullptr) {
		if (_tapeFilePath != nil) {
			if (_emu->is_tape_inserted(drv)) {
				_emu->close_tape(drv);
			}
			_emu->play_tape(drv, [_tapeFilePath UTF8String]);
		}
		_emu->push_play(drv);
	}
}

- (void)pushStop:(int)drv
{
	if (_emu != nullptr) {
		_emu->push_stop(drv);
	}
}

- (void)pushFastForward:(int)drv
{
	if (_emu != nullptr) {
		_emu->push_fast_forward(drv);
	}
}

- (void)pushFastRewind:(int)drv
{
	if (_emu != nullptr) {
		_emu->push_fast_rewind(drv);
	}
}

// MARK: - Tape Config

- (BOOL)isWaveShaperEnabled:(int)drv
{
	return config.wave_shaper[drv] ? YES : NO;
}

- (void)setWaveShaper:(int)drv enabled:(BOOL)enabled
{
	config.wave_shaper[drv] = enabled;
}

// MARK: - Floppy Disk Config

- (BOOL)isFloppyDiskProtected:(int)drv
{
	if (_emu == nullptr) return NO;
	return _emu->is_floppy_disk_protected(drv) ? YES : NO;
}

- (void)setFloppyDiskProtected:(int)drv enabled:(BOOL)enabled
{
	if (_emu != nullptr) {
		_emu->is_floppy_disk_protected(drv, enabled);
	}
}

- (BOOL)isCorrectDiskTimingEnabled:(int)drv
{
	return config.correct_disk_timing[drv] ? YES : NO;
}

- (void)setCorrectDiskTiming:(int)drv enabled:(BOOL)enabled
{
	config.correct_disk_timing[drv] = enabled;
}

- (BOOL)isIgnoreDiskCRCEnabled:(int)drv
{
	return config.ignore_disk_crc[drv] ? YES : NO;
}

- (void)setIgnoreDiskCRC:(int)drv enabled:(BOOL)enabled
{
	config.ignore_disk_crc[drv] = enabled;
}

- (BOOL)createBlankFloppyDisk:(NSString *)path type:(int)type
{
	if (_emu == nullptr) return NO;
	return _emu->create_blank_floppy_disk([path UTF8String], (uint8_t)type) ? YES : NO;
}

// MARK: - CPU Speed

- (int)cpuPower
{
	return config.cpu_power;
}

- (void)setCpuPower:(int)power
{
	config.cpu_power = power;
}

- (BOOL)isFullSpeed
{
	return config.full_speed ? YES : NO;
}

- (void)setFullSpeed:(BOOL)enabled
{
	config.full_speed = enabled;
}

- (BOOL)isTapeFastLoadable
{
	if (_emu == nullptr) return NO;
	return (_emu->is_tape_playing(0) && !config.sound_tape_signal) ? YES : NO;
}

- (BOOL)isDriveVMInOpecodeEnabled
{
	return config.drive_vm_in_opecode ? YES : NO;
}

- (void)setDriveVMInOpecode:(BOOL)enabled
{
	config.drive_vm_in_opecode = enabled;
}

// MARK: - Option Switch

- (int)optionSwitch
{
	return config.option_switch;
}

- (void)setOptionSwitch:(int)value
{
	config.option_switch = value;
}

// MARK: - Device Config

- (int)joystickType
{
	return config.joystick_type;
}

- (void)setJoystickType:(int)type
{
	config.joystick_type = type;
}

- (int)printerType
{
	return config.printer_type;
}

- (void)setPrinterType:(int)type
{
	config.printer_type = type;
}

- (BOOL)isScanlineEnabled
{
	return config.scan_line ? YES : NO;
}

- (void)setScanline:(BOOL)enabled
{
	config.scan_line = enabled;
}

- (int)filterType
{
	return config.filter_type;
}

- (void)setFilterType:(int)type
{
	config.filter_type = type;
}

// MARK: - Sound Config

- (BOOL)isSoundNoiseFDDEnabled
{
	return config.sound_noise_fdd ? YES : NO;
}

- (void)setSoundNoiseFDD:(BOOL)enabled
{
	config.sound_noise_fdd = enabled;
}

- (BOOL)isSoundNoiseCMTEnabled
{
	return config.sound_noise_cmt ? YES : NO;
}

- (void)setSoundNoiseCMT:(BOOL)enabled
{
	config.sound_noise_cmt = enabled;
}

- (BOOL)isSoundTapeSignalEnabled
{
	return config.sound_tape_signal ? YES : NO;
}

- (void)setSoundTapeSignal:(BOOL)enabled
{
	config.sound_tape_signal = enabled;
}

- (BOOL)isSoundTapeVoiceEnabled
{
	return config.sound_tape_voice ? YES : NO;
}

- (void)setSoundTapeVoice:(BOOL)enabled
{
	config.sound_tape_voice = enabled;
}

- (BOOL)isSpeakerSimulationEnabled
{
	return config.sound_speaker_simulation ? YES : NO;
}

- (void)setSpeakerSimulation:(BOOL)enabled
{
	config.sound_speaker_simulation = enabled;
	if(_emu != nullptr) {
		_emu->get_osd()->set_speaker_simulation(enabled);
	}
}

- (BOOL)isReverbEnabled
{
	return config.sound_reverb ? YES : NO;
}

- (void)setReverb:(BOOL)enabled
{
	config.sound_reverb = enabled;
	if(_emu != nullptr) {
		_emu->get_osd()->set_reverb(enabled);
	}
}

- (BOOL)isChorusEnabled
{
	return config.sound_chorus ? YES : NO;
}

- (void)setChorus:(BOOL)enabled
{
	config.sound_chorus = enabled;
	if(_emu != nullptr) {
		_emu->get_osd()->set_chorus(enabled);
	}
}

// MARK: - Auto Key

- (BOOL)isRomajiToKanaEnabled
{
	return config.romaji_to_kana ? YES : NO;
}

- (void)setRomajiToKana:(BOOL)enabled
{
	config.romaji_to_kana = enabled;
}

// MARK: - Host Window Size

- (void)setHostWindowSize:(int)width height:(int)height
{
	if (_emu != nullptr) {
		_emu->set_host_window_size(width, height, true);
	}
}

// MARK: - Config Notification

- (void)updateConfig
{
	if (_emu != nullptr) {
		_emu->update_config();
	}
}

// MARK: - Access Lamp

- (uint32_t)floppyDiskAccessed
{
	if (_emu == nullptr) return 0;
	return _emu->is_floppy_disk_accessed();
}

- (uint32_t)quickDiskAccessed
{
	if (_emu == nullptr) return 0;
	return _emu->is_quick_disk_accessed();
}

- (BOOL)isTapePlaying:(int)drv
{
	if (_emu == nullptr) return NO;
	return _emu->is_tape_playing(drv) ? YES : NO;
}

- (BOOL)isTapeRecording:(int)drv
{
	if (_emu == nullptr) return NO;
	return _emu->is_tape_recording(drv) ? YES : NO;
}

- (int)tapePosition:(int)drv
{
	if (_emu == nullptr) return 0;
	return _emu->get_tape_position(drv);
}

- (nullable NSString *)tapeMessage:(int)drv
{
	if (_emu == nullptr) return nil;
	const _TCHAR *msg = _emu->get_tape_message(drv);
	return msg ? [NSString stringWithUTF8String:msg] : nil;
}

// MARK: - Sound

- (void)muteSound
{
	if (_emu != nullptr) {
		_emu->mute_sound();
	}
}

// MARK: - State

- (void)saveState:(NSString *)path
{
#ifdef USE_STATE
	if (_emu != nullptr) {
		_emu->save_state([path UTF8String]);
	}
#endif
}

- (void)loadState:(NSString *)path
{
#ifdef USE_STATE
	if (_emu != nullptr) {
		_emu->load_state([path UTF8String]);
	}
#endif
}

// MARK: - VM lock

- (void)lockVM
{
	if (_emu != nullptr) {
		_emu->lock_vm();
	}
}

- (void)unlockVM
{
	if (_emu != nullptr) {
		_emu->unlock_vm();
	}
}

// MARK: - Private

- (NSString *)configFilePath
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(
		NSApplicationSupportDirectory,
		NSUserDomainMask,
		YES
	);
	NSString *appSupportDir = paths.firstObject;
	NSString *appDir = [appSupportDir stringByAppendingPathComponent:@"BubiZ-1500"];

	NSFileManager *fm = [NSFileManager defaultManager];
	if (![fm fileExistsAtPath:appDir]) {
		[fm createDirectoryAtPath:appDir withIntermediateDirectories:YES attributes:nil error:nil];
	}

	return [appDir stringByAppendingPathComponent:@"mz1500.ini"];
}

// MARK: - ROM Management

- (NSString *)romDirectoryPath
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(
		NSApplicationSupportDirectory,
		NSUserDomainMask,
		YES
	);
	NSString *appSupportDir = paths.firstObject;
	NSString *appDir = [appSupportDir stringByAppendingPathComponent:@"BubiZ-1500"];
	NSString *romDir = [appDir stringByAppendingPathComponent:@"ROM"];

	return romDir;
}

- (BOOL)checkRequiredROMs:(NSArray<NSString *> *_Nullable *_Nullable)missingFiles
{
	// Required ROM files for MZ-1500
	NSArray<NSString *> *requiredROMs = @[
		@"IPL.ROM",
		@"EXT.ROM",
		@"FONT.ROM"
	];

	NSString *romDir = [self romDirectoryPath];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSMutableArray<NSString *> *missing = [NSMutableArray array];

	// Check each required ROM file
	for (NSString *romFile in requiredROMs) {
		NSString *romPath = [romDir stringByAppendingPathComponent:romFile];
		if (![fm fileExistsAtPath:romPath]) {
			[missing addObject:romFile];
		}
	}

	// Return result
	if (missing.count > 0) {
		if (missingFiles != NULL) {
			*missingFiles = [missing copy];
		}
		return NO;
	}

	return YES;
}

// MARK: - Window Aspect Ratio

- (int)windowAspectMode
{
	return config.window_aspect_mode;
}

- (void)setWindowAspectMode:(int)mode
{
	config.window_aspect_mode = mode;
}

// MARK: - Recent Files

- (NSArray<NSString *> *)recentTapePaths:(int)drv
{
#ifdef USE_TAPE
	if (drv >= USE_TAPE) return @[];
	NSMutableArray *paths = [NSMutableArray array];
	for (int i = 0; i < MAX_HISTORY; i++) {
		if (config.recent_tape_path[drv][i][0] != '\0') {
			[paths addObject:[NSString stringWithUTF8String:config.recent_tape_path[drv][i]]];
		}
	}
	return paths;
#else
	return @[];
#endif
}

- (NSArray<NSString *> *)recentFloppyDiskPaths:(int)drv
{
#ifdef USE_FLOPPY_DISK
	if (drv >= USE_FLOPPY_DISK) return @[];
	NSMutableArray *paths = [NSMutableArray array];
	for (int i = 0; i < MAX_HISTORY; i++) {
		if (config.recent_floppy_disk_path[drv][i][0] != '\0') {
			[paths addObject:[NSString stringWithUTF8String:config.recent_floppy_disk_path[drv][i]]];
		}
	}
	return paths;
#else
	return @[];
#endif
}

- (NSArray<NSString *> *)recentQuickDiskPaths:(int)drv
{
#ifdef USE_QUICK_DISK
	if (drv >= USE_QUICK_DISK) return @[];
	NSMutableArray *paths = [NSMutableArray array];
	for (int i = 0; i < MAX_HISTORY; i++) {
		if (config.recent_quick_disk_path[drv][i][0] != '\0') {
			[paths addObject:[NSString stringWithUTF8String:config.recent_quick_disk_path[drv][i]]];
		}
	}
	return paths;
#else
	return @[];
#endif
}

- (void)addRecentTapePath:(int)drv path:(NSString *)path
{
#ifdef USE_TAPE
	if (drv >= USE_TAPE) return;
	const char *cpath = [path UTF8String];

	int existing = -1;
	for (int i = 0; i < MAX_HISTORY; i++) {
		if (strcmp(config.recent_tape_path[drv][i], cpath) == 0) {
			existing = i;
			break;
		}
	}

	int start = (existing >= 0) ? existing : MAX_HISTORY - 1;
	for (int i = start; i > 0; i--) {
		strlcpy(config.recent_tape_path[drv][i], config.recent_tape_path[drv][i - 1], _MAX_PATH);
	}

	strncpy(config.recent_tape_path[drv][0], cpath, _MAX_PATH - 1);
	config.recent_tape_path[drv][0][_MAX_PATH - 1] = '\0';
#endif
}

- (void)addRecentFloppyDiskPath:(int)drv path:(NSString *)path
{
#ifdef USE_FLOPPY_DISK
	if (drv >= USE_FLOPPY_DISK) return;
	const char *cpath = [path UTF8String];

	int existing = -1;
	for (int i = 0; i < MAX_HISTORY; i++) {
		if (strcmp(config.recent_floppy_disk_path[drv][i], cpath) == 0) {
			existing = i;
			break;
		}
	}

	int start = (existing >= 0) ? existing : MAX_HISTORY - 1;
	for (int i = start; i > 0; i--) {
		strlcpy(config.recent_floppy_disk_path[drv][i], config.recent_floppy_disk_path[drv][i - 1], _MAX_PATH);
	}

	strncpy(config.recent_floppy_disk_path[drv][0], cpath, _MAX_PATH - 1);
	config.recent_floppy_disk_path[drv][0][_MAX_PATH - 1] = '\0';
#endif
}

- (void)addRecentQuickDiskPath:(int)drv path:(NSString *)path
{
#ifdef USE_QUICK_DISK
	if (drv >= USE_QUICK_DISK) return;
	const char *cpath = [path UTF8String];

	int existing = -1;
	for (int i = 0; i < MAX_HISTORY; i++) {
		if (strcmp(config.recent_quick_disk_path[drv][i], cpath) == 0) {
			existing = i;
			break;
		}
	}

	int start = (existing >= 0) ? existing : MAX_HISTORY - 1;
	for (int i = start; i > 0; i--) {
		strlcpy(config.recent_quick_disk_path[drv][i], config.recent_quick_disk_path[drv][i - 1], _MAX_PATH);
	}

	strncpy(config.recent_quick_disk_path[drv][0], cpath, _MAX_PATH - 1);
	config.recent_quick_disk_path[drv][0][_MAX_PATH - 1] = '\0';
#endif
}

@end
