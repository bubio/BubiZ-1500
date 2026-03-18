//
//  EmulatorBridge.h
//  EmuZ-1500
//
//  Objective-C bridge between Swift UI and C++ emulator core
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EmulatorBridge : NSObject

@property (nonatomic, readonly) BOOL isRunning;
@property (nonatomic, readonly) int screenWidth;
@property (nonatomic, readonly) int screenHeight;
@property (nonatomic, readonly) double frameRate;
@property (nonatomic, readonly, nullable) NSString *deviceName;

// Lifecycle
- (instancetype)init;
- (void)startup;
- (void)shutdown;
- (void)reset;

// Emulation loop
- (int)runFrame;
- (void)drawScreen;

// Screen
- (nullable const uint32_t *)screenBuffer;
- (int)vmWindowWidth;
- (int)vmWindowHeight;
- (int)vmWindowWidthAspect;
- (int)vmWindowHeightAspect;

// Input
- (void)keyDown:(int)vkCode extended:(BOOL)extended repeat:(BOOL)repeat;
- (void)keyUp:(int)vkCode extended:(BOOL)extended;
- (void)keyLostFocus;

// Media
- (void)playTape:(int)drv path:(NSString *)path;
- (void)recTape:(int)drv path:(NSString *)path;
- (void)closeTape:(int)drv;
- (BOOL)isTapeInserted:(int)drv;
- (BOOL)hasTapeFilePath;

- (void)openFloppyDisk:(int)drv path:(NSString *)path bank:(int)bank;
- (void)closeFloppyDisk:(int)drv;
- (BOOL)isFloppyDiskInserted:(int)drv;

- (void)openQuickDisk:(int)drv path:(NSString *)path;
- (void)closeQuickDisk:(int)drv;
- (BOOL)isQuickDiskInserted:(int)drv;

// Tape transport control
- (void)pushPlay:(int)drv;
- (void)pushStop:(int)drv;
- (void)pushFastForward:(int)drv;
- (void)pushFastRewind:(int)drv;

// Tape config
- (BOOL)isWaveShaperEnabled:(int)drv;
- (void)setWaveShaper:(int)drv enabled:(BOOL)enabled;

// Floppy disk config
- (BOOL)isFloppyDiskProtected:(int)drv;
- (void)setFloppyDiskProtected:(int)drv enabled:(BOOL)enabled;
- (BOOL)isCorrectDiskTimingEnabled:(int)drv;
- (void)setCorrectDiskTiming:(int)drv enabled:(BOOL)enabled;
- (BOOL)isIgnoreDiskCRCEnabled:(int)drv;
- (void)setIgnoreDiskCRC:(int)drv enabled:(BOOL)enabled;
- (BOOL)createBlankFloppyDisk:(NSString *)path type:(int)type;

// CPU speed
- (int)cpuPower;
- (void)setCpuPower:(int)power;
- (BOOL)isFullSpeed;
- (void)setFullSpeed:(BOOL)enabled;
- (BOOL)isTapeFastLoadable;
- (BOOL)isDriveVMInOpecodeEnabled;
- (void)setDriveVMInOpecode:(BOOL)enabled;

// Option switch
- (int)optionSwitch;
- (void)setOptionSwitch:(int)value;

// Device config
- (int)joystickType;
- (void)setJoystickType:(int)type;
- (int)printerType;
- (void)setPrinterType:(int)type;
- (BOOL)isScanlineEnabled;
- (void)setScanline:(BOOL)enabled;
- (int)filterType;
- (void)setFilterType:(int)type;

// Sound config
- (BOOL)isSoundNoiseFDDEnabled;
- (void)setSoundNoiseFDD:(BOOL)enabled;
- (BOOL)isSoundNoiseCMTEnabled;
- (void)setSoundNoiseCMT:(BOOL)enabled;
- (BOOL)isSoundTapeSignalEnabled;
- (void)setSoundTapeSignal:(BOOL)enabled;
- (BOOL)isSoundTapeVoiceEnabled;
- (void)setSoundTapeVoice:(BOOL)enabled;
- (BOOL)isSpeakerSimulationEnabled;
- (void)setSpeakerSimulation:(BOOL)enabled;
- (BOOL)isReverbEnabled;
- (void)setReverb:(BOOL)enabled;
- (BOOL)isChorusEnabled;
- (void)setChorus:(BOOL)enabled;

// Auto key
- (BOOL)isRomajiToKanaEnabled;
- (void)setRomajiToKana:(BOOL)enabled;

// Host window size
- (void)setHostWindowSize:(int)width height:(int)height;

// Config notification
- (void)updateConfig;

// Access lamp
- (uint32_t)floppyDiskAccessed;
- (uint32_t)quickDiskAccessed;
- (BOOL)isTapePlaying:(int)drv;
- (BOOL)isTapeRecording:(int)drv;

// Disk name (from D88 header)
- (nullable NSString *)floppyDiskName:(int)drv;

// Tape status
- (int)tapePosition:(int)drv;
- (nullable NSString *)tapeMessage:(int)drv;

// Sound
- (void)muteSound;

// State
- (void)saveState:(NSString *)path;
- (void)loadState:(NSString *)path;

// VM lock
- (void)lockVM;
- (void)unlockVM;

// ROM management
- (BOOL)checkRequiredROMs:(NSArray<NSString *> *_Nullable *_Nullable)missingFiles;
- (NSString *)romDirectoryPath;

// Window aspect ratio
- (int)windowAspectMode;
- (void)setWindowAspectMode:(int)mode;

// Recent files
- (NSArray<NSString *> *)recentTapePaths:(int)drv;
- (NSArray<NSString *> *)recentFloppyDiskPaths:(int)drv;
- (NSArray<NSString *> *)recentQuickDiskPaths:(int)drv;
- (void)addRecentTapePath:(int)drv path:(NSString *)path;
- (void)addRecentFloppyDiskPath:(int)drv path:(NSString *)path;
- (void)addRecentQuickDiskPath:(int)drv path:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
