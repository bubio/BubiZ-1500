/*
	Skelton for retropc emulator

	Author : Takeda.Toshiya
	Date   : 2006.08.18 -

	[ common header ]
	[ macOS port ]
*/

#ifndef _COMMON_H_
#define _COMMON_H_

// macOS platform
#ifndef OSD_MACOS
#define OSD_MACOS
#endif

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <typeinfo>
#include <assert.h>
#include <errno.h>
#include <stdarg.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <limits.h>
#include <cmath>
#include <string>
#include <algorithm>
#include <cctype>

#define SUPPORT_CPLUSPLUS_11

// macOS is not Windows
#define CSP_OS_GCC_GENERIC
#define CSP_OS_GENERIC
#define DLL_PREFIX
#define DLL_PREFIX_I

#ifndef _MAX_PATH
	#define _MAX_PATH 2048
#endif

// endian - macOS on Intel/Apple Silicon is little-endian
#ifndef __LITTLE_ENDIAN__
	#define __LITTLE_ENDIAN__
#endif

// type definitions
#ifndef _TCHAR
	typedef char _TCHAR;
#endif
#ifndef LPTSTR
	typedef _TCHAR* LPTSTR;
#endif
#ifndef LPCTSTR
	typedef const _TCHAR* LPCTSTR;
#endif
// BOOL: in Objective-C/Objective-C++, BOOL is already defined (signed char)
// In pure C++, define as int for Windows compatibility
#ifndef __OBJC__
	#ifndef BOOL
		typedef int BOOL;
	#endif
#else
	// Objective-C defines BOOL as signed char, but we need it available
	// It's already defined by objc/objc.h
	#include <objc/objc.h>
#endif
#ifndef TRUE
	#define TRUE 1
#endif
#ifndef FALSE
	#define FALSE 0
#endif
#ifndef BYTE
	typedef uint8_t BYTE;
#endif
#ifndef WORD
	typedef uint16_t WORD;
#endif
#ifndef DWORD
	typedef uint32_t DWORD;
#endif
#ifndef QWORD
	typedef uint64_t QWORD;
#endif
#ifndef INT8
	typedef int8_t INT8;
#endif
#ifndef INT16
	typedef int16_t INT16;
#endif
#ifndef INT32
	typedef int32_t INT32;
#endif
#ifndef INT64
	typedef int64_t INT64;
#endif
#ifndef UINT8
	typedef uint8_t UINT8;
#endif
#ifndef UINT16
	typedef uint16_t UINT16;
#endif
#ifndef UINT32
	typedef uint32_t UINT32;
#endif
#ifndef UINT64
	typedef uint64_t UINT64;
#endif
#ifndef INT
	typedef int INT;
#endif
#ifndef UINT
	typedef unsigned int UINT;
#endif
#ifndef LONG_PTR
	typedef intptr_t LONG_PTR;
#endif
#ifndef ULONG_PTR
	typedef uintptr_t ULONG_PTR;
#endif

typedef union pair16_u {
	struct {
		uint8_t l, h;
	} b;
	struct {
		int8_t l, h;
	} sb;
	uint16_t w;
	int16_t sw;

	inline void read_2bytes_le_from(uint8_t *t)
	{
		b.l = t[0]; b.h = t[1];
	}
	inline void write_2bytes_le_to(uint8_t *t)
	{
		t[0] = b.l; t[1] = b.h;
	}
	inline void read_2bytes_be_from(uint8_t *t)
	{
		b.h = t[0]; b.l = t[1];
	}
	inline void write_2bytes_be_to(uint8_t *t)
	{
		t[0] = b.h; t[1] = b.l;
	}
	inline void set_2bytes_be_from(uint16_t n)
	{
		union {
			uint16_t w;
			struct {
				uint8_t h, l;
			}b;
		} bigv;
		bigv.w = n;
		b.l = bigv.b.l; b.h = bigv.b.h;
	}
	inline void set_2bytes_le_from(uint16_t n)
	{
		union {
			uint16_t w;
			struct {
				uint8_t l, h;
			}b;
		} littlev;
		littlev.w = n;
		b.l = littlev.b.l; b.h = littlev.b.h;
	}
	inline uint16_t get_2bytes_be_to()
	{
		union {
			uint16_t w;
			struct {
				uint8_t h, l;
			}b;
		} bigv;
		bigv.b.l = b.l; bigv.b.h = b.h;
		return bigv.w;
	}
	inline uint16_t get_2bytes_le_to()
	{
		union {
			uint16_t w;
			struct {
				uint8_t l, h;
			}b;
		} littlev;
		littlev.b.l = b.l; littlev.b.h = b.h;
		return littlev.w;
	}
} pair16_t;

typedef union pair32_u {
	struct {
		uint8_t l, h, h2, h3;
	} b;
	struct {
		int8_t l, h, h2, h3;
	} sb;
	struct {
		uint16_t l, h;
	} w;
	struct {
		int16_t l, h;
	} sw;
	uint32_t d;
	int32_t sd;
	float f;

	inline void read_2bytes_le_from(uint8_t *t)
	{
		b.l = t[0]; b.h = t[1]; b.h2 = b.h3 = 0;
	}
	inline void write_2bytes_le_to(uint8_t *t)
	{
		t[0] = b.l; t[1] = b.h;
	}
	inline void read_2bytes_be_from(uint8_t *t)
	{
		b.h3 = b.h2 = 0; b.h = t[0]; b.l = t[1];
	}
	inline void write_2bytes_be_to(uint8_t *t)
	{
		t[0] = b.h; t[1] = b.l;
	}
	inline void read_4bytes_le_from(uint8_t *t)
	{
		b.l = t[0]; b.h = t[1]; b.h2 = t[2]; b.h3 = t[3];
	}
	inline void write_4bytes_le_to(uint8_t *t)
	{
		t[0] = b.l; t[1] = b.h; t[2] = b.h2; t[3] = b.h3;
	}
	inline void read_4bytes_be_from(uint8_t *t)
	{
		b.h3 = t[0]; b.h2 = t[1]; b.h = t[2]; b.l = t[3];
	}
	inline void write_4bytes_be_to(uint8_t *t)
	{
		t[0] = b.h3; t[1] = b.h2; t[2] = b.h; t[3] = b.l;
	}
	inline void set_2bytes_be_from(uint16_t n)
	{
		union {
			uint16_t w;
			struct {
				uint8_t h, l;
			}b;
		} bigv;
		bigv.w = n;
		b.l = bigv.b.l; b.h = bigv.b.h;
		b.h2 = 0; b.h3 = 0;
	}
	inline void set_2bytes_le_from(uint16_t n)
	{
		union {
			uint16_t w;
			struct {
				uint8_t l, h;
			}b;
		} littlev;
		littlev.w = n;
		b.l = littlev.b.l; b.h = littlev.b.h;
		b.h2 = 0; b.h3 = 0;
	}
	inline uint16_t get_2bytes_be_to()
	{
		union {
			uint16_t w;
			struct {
				uint8_t h, l;
			}b;
		} bigv;
		bigv.b.l = b.l; bigv.b.h = b.h;
		return bigv.w;
	}
	inline uint16_t get_2bytes_le_to()
	{
		union {
			uint16_t w;
			struct {
				uint8_t l, h;
			}b;
		} littlev;
		littlev.b.l = b.l; littlev.b.h = b.h;
		return littlev.w;
	}
	inline void set_4bytes_be_from(uint32_t n)
	{
		union {
			uint32_t dw;
			struct {
				uint8_t h3, h2, h, l;
			}b;
		} bigv;
		bigv.dw = n;
		b.l = bigv.b.l; b.h = bigv.b.h; b.h2 = bigv.b.h2; b.h3 = bigv.b.h3;
	}
	inline void set_4bytes_le_from(uint32_t n)
	{
		union {
			uint32_t dw;
			struct {
				uint8_t l, h, h2, h3;
			}b;
		} littlev;
		littlev.dw = n;
		b.l = littlev.b.l; b.h = littlev.b.h; b.h2 = littlev.b.h2; b.h3 = littlev.b.h3;
	}
	inline uint32_t get_4bytes_be_to()
	{
		union {
			uint32_t dw;
			struct {
				uint8_t h3, h2, h, l;
			}b;
		} bigv;
		bigv.b.l = b.l; bigv.b.h = b.h; bigv.b.h2 = b.h2; bigv.b.h3 = b.h3;
		return bigv.dw;
	}
	inline uint32_t get_4bytes_le_to()
	{
		union {
			uint32_t dw;
			struct {
				uint8_t l, h, h2, h3;
			}b;
		} littlev;
		littlev.b.l = b.l; littlev.b.h = b.h; littlev.b.h2 = b.h2; littlev.b.h3 = b.h3;
		return littlev.dw;
	}
} pair32_t;

typedef union pair64_u {
	struct {
		uint8_t l, h, h2, h3, h4, h5, h6, h7;
	} b;
	struct {
		int8_t l, h, h2, h3, h4, h5, h6, h7;
	} sb;
	struct {
		uint16_t l, h, h2, h3;
	} w;
	struct {
		int16_t l, h, h2, h3;
	} sw;
	struct {
		pair16_t l, h, h2, h3;
	} p16;
	struct {
		uint32_t l, h;
	} d;
	struct {
		int32_t l, h;
	} sd;
	struct {
		pair32_t l, h;
	} p32;
	uint64_t q;
	int64_t sq;
	double df;

	inline void read_2bytes_le_from(uint8_t *t)
	{
		b.l = t[0]; b.h = t[1]; b.h2 = b.h3 = 0;
		b.h4 = 0; b.h5 = 0; b.h6 = 0; b.h7 = 0;
	}
	inline void write_2bytes_le_to(uint8_t *t)
	{
		t[0] = b.l; t[1] = b.h;
	}
	inline void read_2bytes_be_from(uint8_t *t)
	{
		b.h3 = b.h2 = 0; b.h = t[0]; b.l = t[1];
		b.h4 = 0; b.h5 = 0; b.h6 = 0; b.h7 = 0;
	}
	inline void write_2bytes_be_to(uint8_t *t)
	{
		t[0] = b.h; t[1] = b.l;
	}
	inline void read_4bytes_le_from(uint8_t *t)
	{
		b.l = t[0]; b.h = t[1]; b.h2 = t[2]; b.h3 = t[3];
		b.h4 = 0; b.h5 = 0; b.h6 = 0; b.h7 = 0;
	}
	inline void write_4bytes_le_to(uint8_t *t)
	{
		t[0] = b.l; t[1] = b.h; t[2] = b.h2; t[3] = b.h3;
	}
	inline void read_4bytes_be_from(uint8_t *t)
	{
		b.h3 = t[0]; b.h2 = t[1]; b.h = t[2]; b.l = t[3];
		b.h4 = 0; b.h5 = 0; b.h6 = 0; b.h7 = 0;
	}
	inline void write_4bytes_be_to(uint8_t *t)
	{
		t[0] = b.h3; t[1] = b.h2; t[2] = b.h; t[3] = b.l;
	}
	inline void read_8bytes_le_from(uint8_t *t)
	{
		b.l = t[0];  b.h = t[1];  b.h2 = t[2]; b.h3 = t[3];
		b.h4 = t[4]; b.h5 = t[5]; b.h6 = t[6]; b.h7 = t[7];
	}
	inline void write_8bytes_le_to(uint8_t *t)
	{
		t[0] = b.l;  t[1] = b.h;  t[2] = b.h2; t[3] = b.h3;
		t[4] = b.h4; t[5] = b.h5; t[6] = b.h6; t[7] = b.h7;
	}
	inline void read_8bytes_be_from(uint8_t *t)
	{
		b.h7 = t[0]; b.h6 = t[1]; b.h5 = t[2]; b.h4 = t[3];
		b.h3 = t[4]; b.h2 = t[5]; b.h = t[6];  b.l = t[7];
	}
	inline void write_8bytes_be_to(uint8_t *t)
	{
		t[0] = b.h7; t[1] = b.h6; t[2] = b.h5; t[3] = b.h4;
		t[4] = b.h3; t[5] = b.h2; t[6] = b.h;  t[7] = b.l;
	}
	inline void set_2bytes_be_from(uint16_t n)
	{
		union {
			uint16_t w;
			struct {
				uint8_t h, l;
			}b;
		} bigv;
		bigv.w = n;
		b.l = bigv.b.l; b.h = bigv.b.h;
		b.h2 = 0; b.h3 = 0;
		b.h4 = 0; b.h5 = 0; b.h6 = 0; b.h7 = 0;
	}
	inline void set_2bytes_le_from(uint16_t n)
	{
		union {
			uint16_t w;
			struct {
				uint8_t l, h;
			}b;
		} littlev;
		littlev.w = n;
		b.l = littlev.b.l; b.h = littlev.b.h;
		b.h2 = 0; b.h3 = 0;
		b.h4 = 0; b.h5 = 0; b.h6 = 0; b.h7 = 0;
	}
	inline uint16_t get_2bytes_be_to()
	{
		union {
			uint16_t w;
			struct {
				uint8_t h, l;
			}b;
		} bigv;
		bigv.b.l = b.l; bigv.b.h = b.h;
		return bigv.w;
	}
	inline uint16_t get_2bytes_le_to()
	{
		union {
			uint16_t w;
			struct {
				uint8_t l, h;
			}b;
		} littlev;
		littlev.b.l = b.l; littlev.b.h = b.h;
		return littlev.w;
	}
	inline void set_4bytes_be_from(uint32_t n)
	{
		union {
			uint32_t dw;
			struct {
				uint8_t h3, h2, h, l;
			}b;
		} bigv;
		bigv.dw = n;
		b.l = bigv.b.l; b.h = bigv.b.h; b.h2 = bigv.b.h2; b.h3 = bigv.b.h3;
		b.h4 = 0;       b.h5 = 0;       b.h6 = 0;         b.h7 = 0;
	}
	inline void set_4bytes_le_from(uint32_t n)
	{
		union {
			uint32_t dw;
			struct {
				uint8_t l, h, h2, h3;
			}b;
		} littlev;
		littlev.dw = n;
		b.l = littlev.b.l; b.h = littlev.b.h; b.h2 = littlev.b.h2; b.h3 = littlev.b.h3;
		b.h4 = 0;          b.h5 = 0;          b.h6 = 0;            b.h7 = 0;
	}
	inline uint32_t get_4bytes_be_to()
	{
		union {
			uint32_t dw;
			struct {
				uint8_t h3, h2, h, l;
			}b;
		} bigv;
		bigv.b.l = b.l; bigv.b.h = b.h; bigv.b.h2 = b.h2; bigv.b.h3 = b.h3;
		return bigv.dw;
	}
	inline uint32_t get_4bytes_le_to()
	{
		union {
			uint32_t dw;
			struct {
				uint8_t l, h, h2, h3;
			}b;
		} littlev;
		littlev.b.l = b.l; littlev.b.h = b.h; littlev.b.h2 = b.h2; littlev.b.h3 = b.h3;
		return littlev.dw;
	}
	inline void set_8bytes_be_from(uint64_t n)
	{
		union {
			uint64_t qw;
			struct {
				uint8_t h7, h6, h5, h4, h3, h2, h, l;
			}b;
		} bigv;
		bigv.qw = n;
		b.l = bigv.b.l;   b.h = bigv.b.h;   b.h2 = bigv.b.h2; b.h3 = bigv.b.h3;
		b.h4 = bigv.b.h4; b.h5 = bigv.b.h5; b.h6 = bigv.b.h6; b.h7 = bigv.b.h7;
	}
	inline void set_8bytes_le_from(uint64_t n)
	{
		union {
			uint64_t qw;
			struct {
				uint8_t l, h, h2, h3, h4, h5, h6, h7;
			}b;
		} littlev;
		littlev.qw = n;
		b.l = littlev.b.l;   b.h = littlev.b.h;   b.h2 = littlev.b.h2; b.h3 = littlev.b.h3;
		b.h4 = littlev.b.h4; b.h5 = littlev.b.h5; b.h6 = littlev.b.h6; b.h7 = littlev.b.h7;
	}
	inline uint64_t get_8bytes_be_to()
	{
		union {
			uint64_t qw;
			struct {
				uint8_t h7, h6, h5, h4, h3, h2, h, l;
			}b;
		} bigv;
		bigv.b.l = b.l;   bigv.b.h = b.h;   bigv.b.h2 = b.h2; bigv.b.h3 = b.h3;
		bigv.b.h4 = b.h4; bigv.b.h5 = b.h5; bigv.b.h6 = b.h6; bigv.b.h7 = b.h7;
		return bigv.qw;
	}
	inline uint64_t get_8bytes_le_to()
	{
		union {
			uint64_t qw;
			struct {
				uint8_t l, h, h2, h3, h4, h5, h6, h7;
			}b;
		} littlev;
		littlev.b.l = b.l;   littlev.b.h = b.h;   littlev.b.h2 = b.h2; littlev.b.h3 = b.h3;
		littlev.b.h4 = b.h4; littlev.b.h5 = b.h5; littlev.b.h6 = b.h6; littlev.b.h7 = b.h7;
		return littlev.qw;
	}
} pair64_t;

uint32_t DLL_PREFIX EndianToLittle_DWORD(uint32_t x);
uint16_t DLL_PREFIX EndianToLittle_WORD(uint16_t x);
uint32_t DLL_PREFIX EndianFromLittle_DWORD(uint32_t x);
uint16_t DLL_PREFIX EndianFromLittle_WORD(uint16_t x);

uint32_t DLL_PREFIX EndianToBig_DWORD(uint32_t x);
uint16_t DLL_PREFIX EndianToBig_WORD(uint16_t x);
uint32_t DLL_PREFIX EndianFromBig_DWORD(uint32_t x);
uint16_t DLL_PREFIX EndianFromBig_WORD(uint16_t x);

uint64_t DLL_PREFIX ExchangeEndianU64(uint64_t x);
int64_t DLL_PREFIX ExchangeEndianS64(uint64_t x);
uint32_t DLL_PREFIX ExchangeEndianU32(uint32_t x);
int32_t DLL_PREFIX ExchangeEndianS32(uint32_t x);
uint16_t DLL_PREFIX ExchangeEndianU16(uint16_t x);
int16_t DLL_PREFIX ExchangeEndianS16(uint16_t x);

// max/min
#undef max
#undef min
int DLL_PREFIX max(int a, int b);
unsigned int DLL_PREFIX max(int a, unsigned int b);
unsigned int DLL_PREFIX max(unsigned int a, int b);
unsigned int DLL_PREFIX max(unsigned int a, unsigned int b);
int DLL_PREFIX min(int a, int b);
int DLL_PREFIX min(unsigned int a, int b);
int DLL_PREFIX min(int a, unsigned int b);
unsigned int DLL_PREFIX min(unsigned int a, unsigned int b);
size_t DLL_PREFIX min(size_t a, size_t b);
size_t DLL_PREFIX min(size_t a, unsigned int b);
size_t DLL_PREFIX min(unsigned int a, size_t b);

// string
#define stricmp(a,b) strcasecmp(a,b)
#define strnicmp(a,b,n) strncasecmp(a,b,n)

#ifndef _fgetts
	#define _fgetts fgets
#endif
#ifndef _ftprintf
	#define _ftprintf fprintf
#endif
#ifndef _tfopen
	#define _tfopen fopen
#endif
#ifndef _tcscmp
	#define _tcscmp strcmp
#endif
#ifndef _tcscpy
	#define _tcscpy strcpy
#endif
#ifndef _tcsicmp
	#define _tcsicmp stricmp
#endif
#ifndef _tcslen
	#define _tcslen strlen
#endif
#ifndef _tcscat
	#define _tcscat strcat
#endif
#ifndef _tcsncat
	#define _tcsncat strncat
#endif
#ifndef _tcsncpy
	#define _tcsncpy strncpy
#endif
#ifndef _tcsncicmp
	#define _tcsncicmp strnicmp
#endif
#ifndef _tcschr
	#define _tcschr strchr
#endif
#ifndef _tcsrchr
	#define _tcsrchr strrchr
#endif
#ifndef _tcsstr
	#define _tcsstr strstr
#endif
#ifndef _tcstok
	#define _tcstok strtok
#endif
#ifndef _tstoi
	#define _tstoi atoi
#endif
#ifndef _tcstol
	#define _tcstol strtol
#endif
#ifndef _tcstoul
	#define _tcstoul strtoul
#endif
#ifndef _stprintf
	#define _stprintf sprintf
#endif
#ifndef _vstprintf
	#define _vstprintf vsprintf
#endif
#ifndef _taccess
	#define _taccess access
#endif
#ifndef _tremove
	#define _tremove remove
#endif
#ifndef _trename
	#define _trename rename
#endif
#define __T(x) x
#define _T(x) __T(x)
#define _TEXT(x) __T(x)

// secure function replacements
#ifndef errno_t
	typedef int errno_t;
#endif
errno_t DLL_PREFIX my_tcscat_s(_TCHAR *strDestination, size_t numberOfElements, const _TCHAR *strSource);
errno_t DLL_PREFIX my_strcpy_s(char *strDestination, size_t numberOfElements, const char *strSource);
errno_t DLL_PREFIX my_tcscpy_s(_TCHAR *strDestination, size_t numberOfElements, const _TCHAR *strSource);
errno_t DLL_PREFIX my_tcscpy_s(_TCHAR *strDestination,  const _TCHAR *strSource);
errno_t DLL_PREFIX my_strncpy_s(char *strDestination, size_t numberOfElements, const char *strSource, size_t count);
errno_t DLL_PREFIX my_tcsncpy_s(_TCHAR *strDestination, size_t numberOfElements, const _TCHAR *strSource, size_t count);
char * DLL_PREFIX my_strtok_s(char *strToken, const char *strDelimit, char **context);
_TCHAR *DLL_PREFIX my_tcstok_s(_TCHAR *strToken, const char *strDelimit, _TCHAR **context);
#define my_fprintf_s fprintf
#define my_ftprintf_s _ftprintf
int DLL_PREFIX my_sprintf_s(char *buffer, size_t sizeOfBuffer, const char *format, ...);
int DLL_PREFIX my_swprintf_s(wchar_t *buffer, size_t sizeOfBuffer, const wchar_t *format, ...);
int DLL_PREFIX my_stprintf_s(_TCHAR *buffer, size_t sizeOfBuffer, const _TCHAR *format, ...);
int DLL_PREFIX my_vsprintf_s(char *buffer, size_t numberOfElements, const char *format, va_list argptr);
int DLL_PREFIX my_vstprintf_s(_TCHAR *buffer, size_t numberOfElements, const _TCHAR *format, va_list argptr);

// memory
void *DLL_PREFIX my_memcpy(void *dst, void *src, size_t len);

// hint for SIMD
#if defined(__clang__)
	#define __DECL_VECTORIZED_LOOP   _Pragma("clang loop vectorize(enable) interleave(enable)")
#elif defined(__GNUC__)
	#define __DECL_VECTORIZED_LOOP	_Pragma("GCC ivdep")
#else
	#define __DECL_VECTORIZED_LOOP
#endif

// C99 math functions
#define my_isfinite std::isfinite
#define my_log2 log2

// win32 api replacements
BOOL MyWritePrivateProfileString(LPCTSTR lpAppName, LPCTSTR lpKeyName, LPCTSTR lpString, LPCTSTR lpFileName);
DWORD MyGetPrivateProfileString(LPCTSTR lpAppName, LPCTSTR lpKeyName, LPCTSTR lpDefault, LPTSTR lpReturnedString, DWORD nSize, LPCTSTR lpFileName);
UINT MyGetPrivateProfileInt(LPCTSTR lpAppName, LPCTSTR lpKeyName, INT nDefault, LPCTSTR lpFileName);

// rgb color
#ifndef _RGB888
#define _RGB888
#endif
typedef uint32_t scrntype_t;
#define RGB_COLOR(r, g, b)	(((uint32_t)(r) << 16) | ((uint32_t)(g) << 8) | ((uint32_t)(b) << 0))
#define RGBA_COLOR(r, g, b, a)	(((uint32_t)(r) << 16) | ((uint32_t)(g) << 8) | ((uint32_t)(b) << 0) | ((uint32_t)(a) << 24))
#define R_OF_COLOR(c)		(((c) >> 16) & 0xff)
#define G_OF_COLOR(c)		(((c) >>  8) & 0xff)
#define B_OF_COLOR(c)		(((c)      ) & 0xff)
#define A_OF_COLOR(c)		(((c) >> 24) & 0xff)

// alignment
#define __DECL_ALIGNED(foo) __attribute__((aligned(foo)))

// wav file header
#pragma pack(1)
typedef struct {
	char id[4];
	uint32_t size;
} wav_chunk_t;
#pragma pack()

#pragma pack(1)
typedef struct {
	wav_chunk_t riff_chunk;
	char wave[4];
	wav_chunk_t fmt_chunk;
	uint16_t format_id;
	uint16_t channels;
	uint32_t sample_rate;
	uint32_t data_speed;
	uint16_t block_size;
	uint16_t sample_bits;
} wav_header_t;
#pragma pack()

// file path
const _TCHAR *DLL_PREFIX get_application_path();
const _TCHAR *DLL_PREFIX get_initial_current_path();
const _TCHAR *DLL_PREFIX create_local_path(const _TCHAR *format, ...);
void DLL_PREFIX create_local_path(_TCHAR *file_path, int length, const _TCHAR *format, ...);
const _TCHAR *DLL_PREFIX create_absolute_path(const _TCHAR *format, ...);
void DLL_PREFIX create_absolute_path(_TCHAR *file_path, int length, const _TCHAR *format, ...);
bool DLL_PREFIX is_absolute_path(const _TCHAR *file_path);
const _TCHAR *DLL_PREFIX create_date_file_path(const _TCHAR *extension);
void DLL_PREFIX create_date_file_path(_TCHAR *file_path, int length, const _TCHAR *extension);
const _TCHAR *DLL_PREFIX create_date_file_name(const _TCHAR *extension);
void DLL_PREFIX create_date_file_name(_TCHAR *file_path, int length, const _TCHAR *extension);
bool DLL_PREFIX check_file_extension(const _TCHAR *file_path, const _TCHAR *ext);
const _TCHAR *DLL_PREFIX get_file_path_without_extensiton(const _TCHAR *file_path);
void DLL_PREFIX get_long_full_path_name(const _TCHAR* src, _TCHAR* dst, size_t dst_len);
const _TCHAR *DLL_PREFIX get_parent_dir(const _TCHAR* file);

// string
const _TCHAR *DLL_PREFIX create_string(const _TCHAR* format, ...);
const wchar_t *DLL_PREFIX char_to_wchar(const char *cs);
const char *DLL_PREFIX wchar_to_char(const wchar_t *ws);
const _TCHAR *DLL_PREFIX char_to_tchar(const char *cs);
const char *DLL_PREFIX tchar_to_char(const _TCHAR *ts);
const _TCHAR *DLL_PREFIX wchar_to_tchar(const wchar_t *ws);
const wchar_t *DLL_PREFIX tchar_to_wchar(const _TCHAR *ts);

// misc
void DLL_PREFIX common_initialize();

int32_t DLL_PREFIX muldiv_s32(int32_t nNumber, int32_t nNumerator, int32_t nDenominator);
uint32_t DLL_PREFIX muldiv_u32(uint32_t nNumber, uint32_t nNumerator, uint32_t nDenominator);

uint32_t DLL_PREFIX get_crc32(uint8_t data[], int size);
uint16_t DLL_PREFIX jis_to_sjis(uint16_t jis);

int DLL_PREFIX decibel_to_volume(int decibel);
int32_t DLL_PREFIX apply_volume(int32_t sample, int volume);

#define array_length(array) (sizeof(array) / sizeof(array[0]))

#define FROM_BCD(v)	(((v) & 0x0f) + (((v) >> 4) & 0x0f) * 10)
#define TO_BCD(v)	((int)(((v) % 100) / 10) << 4) | ((v) % 10)
#define TO_BCD_LO(v)	((v) % 10)
#define TO_BCD_HI(v)	(int)(((v) % 100) / 10)

// time
#define LEAP_YEAR(y)	(((y) % 4) == 0 && (((y) % 100) != 0 || ((y) % 400) == 0))

#define dll_cur_time_t DLL_PREFIX_I struct cur_time_s

typedef DLL_PREFIX struct cur_time_s {
	int year, month, day, day_of_week, hour, minute, second;
	bool initialized;
	cur_time_s()
	{
		year = month = day = day_of_week = hour = minute = second = 0;
		initialized = false;
	}
	void increment();
	void update_year();
	void update_day_of_week();
	bool process_state(void *f, bool loading);
} cur_time_t;

void DLL_PREFIX get_host_time(cur_time_t* cur_time);

// symbol
typedef struct symbol_s {
	uint32_t addr;
	_TCHAR *name;
	struct symbol_s *next_symbol;
} symbol_t;

const _TCHAR *DLL_PREFIX get_symbol(symbol_t *first_symbol, uint32_t addr);
const _TCHAR *DLL_PREFIX get_value_or_symbol(symbol_t *first_symbol, const _TCHAR *format, uint32_t addr);
const _TCHAR *DLL_PREFIX get_value_and_symbol(symbol_t *first_symbol, const _TCHAR *format, uint32_t addr);

#endif
