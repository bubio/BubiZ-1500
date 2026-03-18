/*
	macOS to Windows Virtual Key Code mapping

	Maps macOS kVK_* key codes to Windows VK_* codes
	used by the emulator core.
*/

#ifndef _KEYCODE_MAP_H_
#define _KEYCODE_MAP_H_

#include <Carbon/Carbon.h>

// Windows Virtual Key codes used by the emulator
#define VK_BACK           0x08
#define VK_TAB            0x09
#define VK_RETURN         0x0D
#define VK_SHIFT          0x10
#define VK_CONTROL        0x11
#define VK_MENU           0x12  // Alt
#define VK_PAUSE          0x13
#define VK_CAPITAL        0x14  // Caps Lock
#define VK_KANA           0x15
#define VK_ESCAPE         0x1B
#define VK_CONVERT        0x1C
#define VK_NONCONVERT     0x1D
#define VK_SPACE          0x20
#define VK_PRIOR          0x21  // Page Up
#define VK_NEXT           0x22  // Page Down
#define VK_END            0x23
#define VK_HOME           0x24
#define VK_LEFT           0x25
#define VK_UP             0x26
#define VK_RIGHT          0x27
#define VK_DOWN           0x28
#define VK_SELECT         0x29
#define VK_PRINT          0x2A
#define VK_EXECUTE        0x2B
#define VK_SNAPSHOT       0x2C  // Print Screen
#define VK_INSERT         0x2D
#define VK_DELETE         0x2E
#define VK_HELP           0x2F

// 0-9 are the same as ASCII '0'-'9' (0x30-0x39)
// A-Z are the same as ASCII 'A'-'Z' (0x41-0x5A)

#define VK_LWIN           0x5B
#define VK_RWIN           0x5C
#define VK_APPS           0x5D
#define VK_NUMPAD0        0x60
#define VK_NUMPAD1        0x61
#define VK_NUMPAD2        0x62
#define VK_NUMPAD3        0x63
#define VK_NUMPAD4        0x64
#define VK_NUMPAD5        0x65
#define VK_NUMPAD6        0x66
#define VK_NUMPAD7        0x67
#define VK_NUMPAD8        0x68
#define VK_NUMPAD9        0x69
#define VK_MULTIPLY       0x6A
#define VK_ADD            0x6B
#define VK_SEPARATOR      0x6C
#define VK_SUBTRACT       0x6D
#define VK_DECIMAL        0x6E
#define VK_DIVIDE         0x6F
#define VK_F1             0x70
#define VK_F2             0x71
#define VK_F3             0x72
#define VK_F4             0x73
#define VK_F5             0x74
#define VK_F6             0x75
#define VK_F7             0x76
#define VK_F8             0x77
#define VK_F9             0x78
#define VK_F10            0x79
#define VK_F11            0x7A
#define VK_F12            0x7B
#define VK_F13            0x7C
#define VK_F14            0x7D
#define VK_F15            0x7E
#define VK_NUMLOCK        0x90
#define VK_SCROLL         0x91
#define VK_LSHIFT         0xA0
#define VK_RSHIFT         0xA1
#define VK_LCONTROL       0xA2
#define VK_RCONTROL       0xA3
#define VK_LMENU          0xA4
#define VK_RMENU          0xA5
#define VK_OEM_1          0xBA  // ;:
#define VK_OEM_PLUS       0xBB  // =+
#define VK_OEM_COMMA      0xBC  // ,<
#define VK_OEM_MINUS      0xBD  // -_
#define VK_OEM_PERIOD     0xBE  // .>
#define VK_OEM_2          0xBF  // /?
#define VK_OEM_3          0xC0  // `~
#define VK_OEM_4          0xDB  // [{
#define VK_OEM_5          0xDC  // backslash
#define VK_OEM_6          0xDD  // ]}
#define VK_OEM_7          0xDE  // '"
#define VK_OEM_102        0xE2  // extra key
#define VK_F16            0x7F
#define VK_F17            0x80
#define VK_F18            0x81
#define VK_F19            0x82

// macOS keyCode to Windows VK mapping table
// Index: macOS kVK_* code, Value: Windows VK_* code
// Returns 0 for unmapped keys
static const int kMacToVKMap[128] = {
	// 0x00
	0x41,          // kVK_ANSI_A -> 'A'
	0x53,          // kVK_ANSI_S -> 'S'
	0x44,          // kVK_ANSI_D -> 'D'
	0x46,          // kVK_ANSI_F -> 'F'
	0x48,          // kVK_ANSI_H -> 'H'
	0x47,          // kVK_ANSI_G -> 'G'
	0x5A,          // kVK_ANSI_Z -> 'Z'
	0x58,          // kVK_ANSI_X -> 'X'
	// 0x08
	0x43,          // kVK_ANSI_C -> 'C'
	0x56,          // kVK_ANSI_V -> 'V'
	VK_OEM_102,    // kVK_ISO_Section
	0x42,          // kVK_ANSI_B -> 'B'
	0x51,          // kVK_ANSI_Q -> 'Q'
	0x57,          // kVK_ANSI_W -> 'W'
	0x45,          // kVK_ANSI_E -> 'E'
	0x52,          // kVK_ANSI_R -> 'R'
	// 0x10
	0x59,          // kVK_ANSI_Y -> 'Y'
	0x54,          // kVK_ANSI_T -> 'T'
	0x31,          // kVK_ANSI_1 -> '1'
	0x32,          // kVK_ANSI_2 -> '2'
	0x33,          // kVK_ANSI_3 -> '3'
	0x34,          // kVK_ANSI_4 -> '4'
	0x36,          // kVK_ANSI_6 -> '6'
	0x35,          // kVK_ANSI_5 -> '5'
	// 0x18
	VK_OEM_PLUS,   // kVK_ANSI_Equal -> =+
	0x39,          // kVK_ANSI_9 -> '9'
	0x37,          // kVK_ANSI_7 -> '7'
	VK_OEM_MINUS,  // kVK_ANSI_Minus -> -_
	0x38,          // kVK_ANSI_8 -> '8'
	0x30,          // kVK_ANSI_0 -> '0'
	VK_OEM_6,      // kVK_ANSI_RightBracket -> ]}
	0x4F,          // kVK_ANSI_O -> 'O'
	// 0x20
	0x55,          // kVK_ANSI_U -> 'U'
	VK_OEM_4,      // kVK_ANSI_LeftBracket -> [{
	0x49,          // kVK_ANSI_I -> 'I'
	0x50,          // kVK_ANSI_P -> 'P'
	VK_RETURN,     // kVK_Return
	0x4C,          // kVK_ANSI_L -> 'L'
	0x4A,          // kVK_ANSI_J -> 'J'
	VK_OEM_7,      // kVK_ANSI_Quote -> '"
	// 0x28
	0x4B,          // kVK_ANSI_K -> 'K'
	VK_OEM_1,      // kVK_ANSI_Semicolon -> ;:
	VK_OEM_5,      // kVK_ANSI_Backslash
	VK_OEM_COMMA,  // kVK_ANSI_Comma -> ,<
	VK_OEM_2,      // kVK_ANSI_Slash -> /?
	0x4E,          // kVK_ANSI_N -> 'N'
	0x4D,          // kVK_ANSI_M -> 'M'
	VK_OEM_PERIOD, // kVK_ANSI_Period -> .>
	// 0x30
	VK_TAB,        // kVK_Tab
	VK_SPACE,      // kVK_Space
	VK_OEM_3,      // kVK_ANSI_Grave -> `~
	VK_BACK,       // kVK_Delete (Backspace)
	0,             // 0x34 unused
	VK_ESCAPE,     // kVK_Escape
	VK_RWIN,       // kVK_RightCommand
	VK_LWIN,       // kVK_Command
	// 0x38
	VK_LSHIFT,     // kVK_Shift
	VK_CAPITAL,    // kVK_CapsLock
	VK_LMENU,      // kVK_Option -> Alt
	VK_LCONTROL,   // kVK_Control
	VK_RSHIFT,     // kVK_RightShift
	VK_RMENU,      // kVK_RightOption -> Alt
	VK_RCONTROL,   // kVK_RightControl
	VK_APPS,       // kVK_Function
	// 0x40
	VK_F17,        // kVK_F17 (not standard VK, map to 0)
	VK_DECIMAL,    // kVK_ANSI_KeypadDecimal
	0,             // 0x42 unused
	VK_MULTIPLY,   // kVK_ANSI_KeypadMultiply
	0,             // 0x44 unused
	VK_ADD,        // kVK_ANSI_KeypadPlus
	0,             // 0x46 unused
	VK_NUMLOCK,    // kVK_ANSI_KeypadClear -> NumLock
	// 0x48
	0,             // kVK_VolumeUp (system key)
	0,             // kVK_VolumeDown (system key)
	0,             // kVK_Mute (system key)
	VK_DIVIDE,     // kVK_ANSI_KeypadDivide
	VK_RETURN,     // kVK_ANSI_KeypadEnter
	0,             // 0x4D unused
	VK_SUBTRACT,   // kVK_ANSI_KeypadMinus
	VK_F18,        // kVK_F18
	// 0x50
	VK_F19,        // kVK_F19
	VK_OEM_PLUS,   // kVK_ANSI_KeypadEquals -> = (numpad)
	VK_NUMPAD0,    // kVK_ANSI_Keypad0
	VK_NUMPAD1,    // kVK_ANSI_Keypad1
	VK_NUMPAD2,    // kVK_ANSI_Keypad2
	VK_NUMPAD3,    // kVK_ANSI_Keypad3
	VK_NUMPAD4,    // kVK_ANSI_Keypad4
	VK_NUMPAD5,    // kVK_ANSI_Keypad5
	// 0x58
	VK_NUMPAD6,    // kVK_ANSI_Keypad6
	VK_NUMPAD7,    // kVK_ANSI_Keypad7
	0,             // kVK_F20
	VK_NUMPAD8,    // kVK_ANSI_Keypad8
	VK_NUMPAD9,    // kVK_ANSI_Keypad9
	0x5C,          // kVK_JIS_Yen -> backslash
	0,             // kVK_JIS_Underscore
	VK_SEPARATOR,  // kVK_JIS_KeypadComma
	// 0x60
	VK_F5,         // kVK_F5
	VK_F6,         // kVK_F6
	VK_F7,         // kVK_F7
	VK_F3,         // kVK_F3
	VK_F8,         // kVK_F8
	VK_F9,         // kVK_F9
	VK_KANA,       // kVK_JIS_Eisu -> Kana
	VK_F11,        // kVK_F11
	// 0x68
	VK_KANA,       // kVK_JIS_Kana
	VK_F13,        // kVK_F13
	VK_F16,        // kVK_F16
	VK_F14,        // kVK_F14
	0,             // 0x6C unused
	VK_F10,        // kVK_F10
	0,             // 0x6E unused
	VK_F12,        // kVK_F12
	// 0x70
	0,             // 0x70 unused
	VK_F15,        // kVK_F15
	VK_HELP,       // kVK_Help
	VK_HOME,       // kVK_Home
	VK_PRIOR,      // kVK_PageUp
	VK_DELETE,     // kVK_ForwardDelete
	VK_F4,         // kVK_F4
	VK_END,        // kVK_End
	// 0x78
	VK_F2,         // kVK_F2
	VK_NEXT,       // kVK_PageDown
	VK_F1,         // kVK_F1
	VK_LEFT,       // kVK_LeftArrow
	VK_RIGHT,      // kVK_RightArrow
	VK_DOWN,       // kVK_DownArrow
	VK_UP,         // kVK_UpArrow
	0,             // 0x7F unused
};

static inline int macKeyCodeToVK(unsigned short keyCode)
{
	if(keyCode < 128) {
		return kMacToVKMap[keyCode];
	}
	return 0;
}

#endif
