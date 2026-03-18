/*
	Skelton for retropc emulator

	Author : Takeda.Toshiya
	Date   : 2013.01.17-

	[ common routines ]
	[ macOS port ]
*/

#include <time.h>
#include <math.h>
#include <string>
#include <algorithm>
#include <cctype>
#include <mach-o/dyld.h>
#include <libgen.h>
#include "common.h"
#include "fileio.h"

// ----------------------------------------------------------------------------
// common initialize
// ----------------------------------------------------------------------------

void DLL_PREFIX common_initialize()
{
	get_initial_current_path();
}

// ----------------------------------------------------------------------------
// endian
// ----------------------------------------------------------------------------

#ifdef __LITTLE_ENDIAN__

uint32_t DLL_PREFIX EndianToLittle_DWORD(uint32_t x)
{
	return x;
}

uint16_t DLL_PREFIX EndianToLittle_WORD(uint16_t x)
{
	return x;
}

uint32_t DLL_PREFIX EndianFromLittle_DWORD(uint32_t x)
{
	return x;
}

uint16_t DLL_PREFIX EndianFromLittle_WORD(uint16_t x)
{
	return x;
}

uint32_t DLL_PREFIX EndianToBig_DWORD(uint32_t x)
{
	uint32_t y;
	y  = ((x & 0x000000ff) << 24);
	y |= ((x & 0x0000ff00) <<  8);
	y |= ((x & 0x00ff0000) >>  8);
	y |= ((x & 0xff000000) >> 24);
	return y;
}

uint16_t DLL_PREFIX EndianToBig_WORD(uint16_t x)
{
	uint16_t y;
	y  = ((x & 0x00ff) << 8);
	y |= ((x & 0xff00) >> 8);
	return y;
}

uint32_t DLL_PREFIX EndianFromBig_DWORD(uint32_t x)
{
	uint32_t y;
	y  = ((x & 0x000000ff) << 24);
	y |= ((x & 0x0000ff00) <<  8);
	y |= ((x & 0x00ff0000) >>  8);
	y |= ((x & 0xff000000) >> 24);
	return y;
}

uint16_t DLL_PREFIX EndianFromBig_WORD(uint16_t x)
{
	uint16_t y;
	y  = ((x & 0x00ff) << 8);
	y |= ((x & 0xff00) >> 8);
	return y;
}

#else // __BIG_ENDIAN__

uint32_t DLL_PREFIX EndianToLittle_DWORD(uint32_t x)
{
	uint32_t y;
	y  = ((x & 0x000000ff) << 24);
	y |= ((x & 0x0000ff00) <<  8);
	y |= ((x & 0x00ff0000) >>  8);
	y |= ((x & 0xff000000) >> 24);
	return y;
}

uint16_t DLL_PREFIX EndianToLittle_WORD(uint16_t x)
{
	uint16_t y;
	y  = ((x & 0x00ff) << 8);
	y |= ((x & 0xff00) >> 8);
	return y;
}

uint32_t DLL_PREFIX EndianFromLittle_DWORD(uint32_t x)
{
	uint32_t y;
	y  = ((x & 0x000000ff) << 24);
	y |= ((x & 0x0000ff00) <<  8);
	y |= ((x & 0x00ff0000) >>  8);
	y |= ((x & 0xff000000) >> 24);
	return y;
}

uint16_t DLL_PREFIX EndianFromLittle_WORD(uint16_t x)
{
	uint16_t y;
	y  = ((x & 0x00ff) << 8);
	y |= ((x & 0xff00) >> 8);
	return y;
}

uint32_t DLL_PREFIX EndianToBig_DWORD(uint32_t x)
{
	return x;
}

uint16_t DLL_PREFIX EndianToBig_WORD(uint16_t x)
{
	return x;
}

uint32_t DLL_PREFIX EndianFromBig_DWORD(uint32_t x)
{
	return x;
}

uint16_t DLL_PREFIX EndianFromBig_WORD(uint16_t x)
{
	return x;
}

#endif

uint64_t DLL_PREFIX ExchangeEndianU64(uint64_t x)
{
	uint64_t y;
	y  = ((x & (uint64_t)0x00000000000000ffULL) << 56);
	y |= ((x & (uint64_t)0x000000000000ff00ULL) << 40);
	y |= ((x & (uint64_t)0x0000000000ff0000ULL) << 24);
	y |= ((x & (uint64_t)0x00000000ff000000ULL) <<  8);
	y |= ((x & (uint64_t)0x000000ff00000000ULL) >>  8);
	y |= ((x & (uint64_t)0x0000ff0000000000ULL) >> 24);
	y |= ((x & (uint64_t)0x00ff000000000000ULL) >> 40);
	y |= ((x & (uint64_t)0xff00000000000000ULL) >> 56);
	return y;
}

int64_t DLL_PREFIX ExchangeEndianS64(uint64_t x)
{
	return (int64_t)ExchangeEndianU64(x);
}

uint32_t DLL_PREFIX ExchangeEndianU32(uint32_t x)
{
	uint32_t y;
	y  = ((x & 0x000000ff) << 24);
	y |= ((x & 0x0000ff00) <<  8);
	y |= ((x & 0x00ff0000) >>  8);
	y |= ((x & 0xff000000) >> 24);
	return y;
}

int32_t DLL_PREFIX ExchangeEndianS32(uint32_t x)
{
	return (int32_t)ExchangeEndianU32(x);
}

uint16_t DLL_PREFIX ExchangeEndianU16(uint16_t x)
{
	uint16_t y;
	y  = ((x & 0x00ff) << 8);
	y |= ((x & 0xff00) >> 8);
	return y;
}

int16_t DLL_PREFIX ExchangeEndianS16(uint16_t x)
{
	return (int16_t)ExchangeEndianU16(x);
}

// ----------------------------------------------------------------------------
// max / min
// ----------------------------------------------------------------------------

int DLL_PREFIX max(int a, int b)
{
	return (a > b) ? a : b;
}

unsigned int DLL_PREFIX max(int a, unsigned int b)
{
	if(a < 0) return b;
	return ((unsigned int)a > b) ? (unsigned int)a : b;
}

unsigned int DLL_PREFIX max(unsigned int a, int b)
{
	if(b < 0) return a;
	return (a > (unsigned int)b) ? a : (unsigned int)b;
}

unsigned int DLL_PREFIX max(unsigned int a, unsigned int b)
{
	return (a > b) ? a : b;
}

int DLL_PREFIX min(int a, int b)
{
	return (a < b) ? a : b;
}

int DLL_PREFIX min(unsigned int a, int b)
{
	if(b < 0) return b;
	return (a < (unsigned int)b) ? (int)a : b;
}

int DLL_PREFIX min(int a, unsigned int b)
{
	if(a < 0) return a;
	return ((unsigned int)a < b) ? a : (int)b;
}

unsigned int DLL_PREFIX min(unsigned int a, unsigned int b)
{
	return (a < b) ? a : b;
}

size_t DLL_PREFIX min(size_t a, size_t b)
{
	return (a < b) ? a : b;
}

size_t DLL_PREFIX min(size_t a, unsigned int b)
{
	return (a < (size_t)b) ? a : (size_t)b;
}

size_t DLL_PREFIX min(unsigned int a, size_t b)
{
	return ((size_t)a < b) ? (size_t)a : b;
}

// ----------------------------------------------------------------------------
// secure string functions (non-MSVC)
// ----------------------------------------------------------------------------

errno_t DLL_PREFIX my_tcscat_s(_TCHAR *strDestination, size_t numberOfElements, const _TCHAR *strSource)
{
	_tcscat(strDestination, strSource);
	return 0;
}

errno_t DLL_PREFIX my_strcpy_s(char *strDestination, size_t numberOfElements, const char *strSource)
{
	strcpy(strDestination, strSource);
	return 0;
}

errno_t DLL_PREFIX my_tcscpy_s(_TCHAR *strDestination, size_t numberOfElements, const _TCHAR *strSource)
{
	_tcscpy(strDestination, strSource);
	return 0;
}

errno_t DLL_PREFIX my_tcscpy_s(_TCHAR *strDestination, const _TCHAR *strSource)
{
	_tcscpy(strDestination, strSource);
	return 0;
}

errno_t DLL_PREFIX my_strncpy_s(char *strDestination, size_t numberOfElements, const char *strSource, size_t count)
{
	strncpy(strDestination, strSource, count);
	return 0;
}

errno_t DLL_PREFIX my_tcsncpy_s(_TCHAR *strDestination, size_t numberOfElements, const _TCHAR *strSource, size_t count)
{
	_tcsncpy(strDestination, strSource, count);
	return 0;
}

char *DLL_PREFIX my_strtok_s(char *strToken, const char *strDelimit, char **context)
{
	return strtok_r(strToken, strDelimit, context);
}

_TCHAR *DLL_PREFIX my_tcstok_s(_TCHAR *strToken, const char *strDelimit, _TCHAR **context)
{
	return strtok_r(strToken, strDelimit, context);
}

int DLL_PREFIX my_sprintf_s(char *buffer, size_t sizeOfBuffer, const char *format, ...)
{
	va_list ap;
	va_start(ap, format);
	int result = vsnprintf(buffer, sizeOfBuffer, format, ap);
	va_end(ap);
	return result;
}

int DLL_PREFIX my_swprintf_s(wchar_t *buffer, size_t sizeOfBuffer, const wchar_t *format, ...)
{
	va_list ap;
	va_start(ap, format);
	int result = vswprintf(buffer, sizeOfBuffer, format, ap);
	va_end(ap);
	return result;
}

int DLL_PREFIX my_stprintf_s(_TCHAR *buffer, size_t sizeOfBuffer, const _TCHAR *format, ...)
{
	va_list ap;
	va_start(ap, format);
	int result = vsnprintf(buffer, sizeOfBuffer, format, ap);
	va_end(ap);
	return result;
}

int DLL_PREFIX my_vsprintf_s(char *buffer, size_t numberOfElements, const char *format, va_list argptr)
{
	return vsnprintf(buffer, numberOfElements, format, argptr);
}

int DLL_PREFIX my_vstprintf_s(_TCHAR *buffer, size_t numberOfElements, const _TCHAR *format, va_list argptr)
{
	return vsnprintf(buffer, numberOfElements, format, argptr);
}

// ----------------------------------------------------------------------------
// memory
// ----------------------------------------------------------------------------

void *DLL_PREFIX my_memcpy(void *dst, void *src, size_t len)
{
	return memcpy(dst, src, len);
}

// ----------------------------------------------------------------------------
// Win32 API replacements - INI file handling
// ----------------------------------------------------------------------------

BOOL MyWritePrivateProfileString(LPCTSTR lpAppName, LPCTSTR lpKeyName, LPCTSTR lpString, LPCTSTR lpFileName)
{
	BOOL result = FALSE;
	FILEIO *fio_r = new FILEIO();
	if(fio_r->Fopen(lpFileName, FILEIO_READ_ASCII)) {
		char tmp_path[_MAX_PATH];
		my_stprintf_s(tmp_path, _MAX_PATH, _T("%s.$$$"), lpFileName);
		FILEIO *fio_w = new FILEIO();
		if(fio_w->Fopen(tmp_path, FILEIO_WRITE_ASCII)) {
			bool in_section = false;
			bool key_written = false;
			char line[1024], *p;
			while(fio_r->Fgets(line, sizeof(line)) != NULL) {
				if(line[0] == '[') {
					if(in_section && !key_written) {
						fio_w->Fprintf("%s=%s\n", lpKeyName, lpString);
						key_written = true;
					}
					char section[1024];
					p = &line[1];
					char *q = section;
					while(*p != ']' && *p != '\0') {
						*q++ = *p++;
					}
					*q = '\0';
					in_section = (_tcsicmp(section, lpAppName) == 0);
				} else if(in_section && !key_written) {
					char key[1024];
					p = line;
					char *q = key;
					while(*p != '=' && *p != '\0') {
						*q++ = *p++;
					}
					*q = '\0';
					// trim trailing spaces
					q--;
					while(q >= key && (*q == ' ' || *q == '\t')) {
						*q-- = '\0';
					}
					if(_tcsicmp(key, lpKeyName) == 0) {
						fio_w->Fprintf("%s=%s\n", lpKeyName, lpString);
						key_written = true;
						continue;
					}
				}
				fio_w->Fprintf("%s", line);
			}
			if(!key_written) {
				if(!in_section) {
					fio_w->Fprintf("[%s]\n", lpAppName);
				}
				fio_w->Fprintf("%s=%s\n", lpKeyName, lpString);
			}
			fio_w->Fclose();
			result = TRUE;
		}
		delete fio_w;
		fio_r->Fclose();
		if(result) {
			_tremove(lpFileName);
			_trename(tmp_path, lpFileName);
		}
	} else {
		FILEIO *fio_w = new FILEIO();
		if(fio_w->Fopen(lpFileName, FILEIO_WRITE_ASCII)) {
			fio_w->Fprintf("[%s]\n", lpAppName);
			fio_w->Fprintf("%s=%s\n", lpKeyName, lpString);
			fio_w->Fclose();
		}
		delete fio_w;
	}
	delete fio_r;
	return result;
}

DWORD MyGetPrivateProfileString(LPCTSTR lpAppName, LPCTSTR lpKeyName, LPCTSTR lpDefault, LPTSTR lpReturnedString, DWORD nSize, LPCTSTR lpFileName)
{
	_TCHAR *p = lpReturnedString;
	p[0] = _T('\0');
	FILEIO *fio = new FILEIO();
	if(fio->Fopen(lpFileName, FILEIO_READ_ASCII)) {
		bool in_section = false;
		char line[1024];
		while(fio->Fgets(line, sizeof(line)) != NULL) {
			// remove newline
			char *ptr = line;
			while(*ptr != '\0') {
				if(*ptr == '\r' || *ptr == '\n') {
					*ptr = '\0';
					break;
				}
				ptr++;
			}
			if(line[0] == '[') {
				char section[1024];
				char *sp = &line[1];
				char *sq = section;
				while(*sp != ']' && *sp != '\0') {
					*sq++ = *sp++;
				}
				*sq = '\0';
				in_section = (_tcsicmp(section, lpAppName) == 0);
			} else if(in_section) {
				char key[1024];
				char *kp = line;
				char *kq = key;
				while(*kp != '=' && *kp != '\0') {
					*kq++ = *kp++;
				}
				*kq = '\0';
				// trim trailing spaces from key
				kq--;
				while(kq >= key && (*kq == ' ' || *kq == '\t')) {
					*kq-- = '\0';
				}
				if(_tcsicmp(key, lpKeyName) == 0 && *kp == '=') {
					kp++; // skip '='
					// skip leading spaces
					while(*kp == ' ' || *kp == '\t') {
						kp++;
					}
					my_tcsncpy_s(lpReturnedString, nSize, kp, nSize - 1);
					lpReturnedString[nSize - 1] = _T('\0');
					fio->Fclose();
					delete fio;
					return (DWORD)_tcslen(lpReturnedString);
				}
			}
		}
		fio->Fclose();
	}
	delete fio;
	my_tcsncpy_s(lpReturnedString, nSize, lpDefault, nSize - 1);
	lpReturnedString[nSize - 1] = _T('\0');
	return (DWORD)_tcslen(lpReturnedString);
}

UINT MyGetPrivateProfileInt(LPCTSTR lpAppName, LPCTSTR lpKeyName, INT nDefault, LPCTSTR lpFileName)
{
	_TCHAR str[256];
	_TCHAR def[256];
	my_stprintf_s(def, 256, _T("%d"), nDefault);
	MyGetPrivateProfileString(lpAppName, lpKeyName, def, str, 256, lpFileName);
	return _tstoi(str);
}

// ----------------------------------------------------------------------------
// file path
// ----------------------------------------------------------------------------

const _TCHAR *DLL_PREFIX get_application_path()
{
	static _TCHAR app_path[_MAX_PATH];
	static bool initialized = false;
	if(!initialized) {
		// Use _NSGetExecutablePath for macOS, falling back to "./"
		char exec_path[_MAX_PATH];
		uint32_t size = sizeof(exec_path);
		if(_NSGetExecutablePath(exec_path, &size) == 0) {
			char *dir = dirname(exec_path);
			snprintf(app_path, _MAX_PATH, "%s/", dir);
		} else {
			strcpy(app_path, "./");
		}
		initialized = true;
	}
	return (const _TCHAR *)app_path;
}

const _TCHAR *DLL_PREFIX get_initial_current_path()
{
	static _TCHAR current_path[_MAX_PATH];
	static bool initialized = false;
	if(!initialized) {
		if(getcwd(current_path, _MAX_PATH) != NULL) {
			int len = (int)strlen(current_path);
			if(len > 0 && current_path[len - 1] != '/') {
				current_path[len] = '/';
				current_path[len + 1] = '\0';
			}
		} else {
			strcpy(current_path, "./");
		}
		initialized = true;
	}
	return (const _TCHAR *)current_path;
}

const _TCHAR *DLL_PREFIX create_local_path(const _TCHAR *format, ...)
{
	static _TCHAR file_path[8][_MAX_PATH];
	static unsigned int table_index = 0;
	unsigned int output_index = (table_index++) & 7;

	_TCHAR file_name[_MAX_PATH];
	va_list ap;
	va_start(ap, format);
	my_vstprintf_s(file_name, _MAX_PATH, format, ap);
	va_end(ap);
	my_stprintf_s(file_path[output_index], _MAX_PATH, _T("%s%s"), get_application_path(), file_name);
	return (const _TCHAR *)file_path[output_index];
}

void DLL_PREFIX create_local_path(_TCHAR *file_path, int length, const _TCHAR *format, ...)
{
	_TCHAR file_name[_MAX_PATH];
	va_list ap;
	va_start(ap, format);
	my_vstprintf_s(file_name, _MAX_PATH, format, ap);
	va_end(ap);
	my_stprintf_s(file_path, length, _T("%s%s"), get_application_path(), file_name);
}

const _TCHAR *DLL_PREFIX create_absolute_path(const _TCHAR *format, ...)
{
	static _TCHAR file_path[8][_MAX_PATH];
	static unsigned int table_index = 0;
	unsigned int output_index = (table_index++) & 7;

	_TCHAR file_name[_MAX_PATH];
	va_list ap;
	va_start(ap, format);
	my_vstprintf_s(file_name, _MAX_PATH, format, ap);
	va_end(ap);
	if(is_absolute_path(file_name)) {
		my_tcscpy_s(file_path[output_index], _MAX_PATH, file_name);
	} else {
		my_stprintf_s(file_path[output_index], _MAX_PATH, _T("%s%s"), get_application_path(), file_name);
	}
	return (const _TCHAR *)file_path[output_index];
}

void DLL_PREFIX create_absolute_path(_TCHAR *file_path, int length, const _TCHAR *format, ...)
{
	_TCHAR file_name[_MAX_PATH];
	va_list ap;
	va_start(ap, format);
	my_vstprintf_s(file_name, _MAX_PATH, format, ap);
	va_end(ap);
	if(is_absolute_path(file_name)) {
		my_tcscpy_s(file_path, length, file_name);
	} else {
		my_stprintf_s(file_path, length, _T("%s%s"), get_application_path(), file_name);
	}
}

bool DLL_PREFIX is_absolute_path(const _TCHAR *file_path)
{
	if(file_path[0] == _T('/')) {
		return true;
	}
	return false;
}

const _TCHAR *DLL_PREFIX create_date_file_path(const _TCHAR *extension)
{
	cur_time_t cur_time;
	get_host_time(&cur_time);
	return create_local_path(_T("%d-%0.2d-%0.2d_%0.2d-%0.2d-%0.2d.%s"), cur_time.year, cur_time.month, cur_time.day, cur_time.hour, cur_time.minute, cur_time.second, extension);
}

void DLL_PREFIX create_date_file_path(_TCHAR *file_path, int length, const _TCHAR *extension)
{
	cur_time_t cur_time;
	get_host_time(&cur_time);
	create_local_path(file_path, length, _T("%d-%0.2d-%0.2d_%0.2d-%0.2d-%0.2d.%s"), cur_time.year, cur_time.month, cur_time.day, cur_time.hour, cur_time.minute, cur_time.second, extension);
}

const _TCHAR *DLL_PREFIX create_date_file_name(const _TCHAR *extension)
{
	static _TCHAR file_name[_MAX_PATH];
	cur_time_t cur_time;
	get_host_time(&cur_time);
	my_stprintf_s(file_name, _MAX_PATH, _T("%d-%0.2d-%0.2d_%0.2d-%0.2d-%0.2d.%s"), cur_time.year, cur_time.month, cur_time.day, cur_time.hour, cur_time.minute, cur_time.second, extension);
	return (const _TCHAR *)file_name;
}

void DLL_PREFIX create_date_file_name(_TCHAR *file_path, int length, const _TCHAR *extension)
{
	cur_time_t cur_time;
	get_host_time(&cur_time);
	my_stprintf_s(file_path, length, _T("%d-%0.2d-%0.2d_%0.2d-%0.2d-%0.2d.%s"), cur_time.year, cur_time.month, cur_time.day, cur_time.hour, cur_time.minute, cur_time.second, extension);
}

bool DLL_PREFIX check_file_extension(const _TCHAR *file_path, const _TCHAR *ext)
{
	int nam_len = (int)_tcslen(file_path);
	int ext_len = (int)_tcslen(ext);

	return (nam_len >= ext_len && _tcsncicmp(&file_path[nam_len - ext_len], ext, ext_len) == 0);
}

const _TCHAR *DLL_PREFIX get_file_path_without_extensiton(const _TCHAR *file_path)
{
	static _TCHAR path[_MAX_PATH];
	my_tcscpy_s(path, _MAX_PATH, file_path);
	_TCHAR *p = _tcsrchr(path, _T('.'));
	if(p != NULL) {
		*p = _T('\0');
	}
	return (const _TCHAR *)path;
}

void DLL_PREFIX get_long_full_path_name(const _TCHAR* src, _TCHAR* dst, size_t dst_len)
{
	char real[_MAX_PATH];
	if(realpath(src, real) != NULL) {
		my_tcsncpy_s(dst, dst_len, real, dst_len - 1);
		dst[dst_len - 1] = _T('\0');
	} else {
		my_tcsncpy_s(dst, dst_len, src, dst_len - 1);
		dst[dst_len - 1] = _T('\0');
	}
}

const _TCHAR *DLL_PREFIX get_parent_dir(const _TCHAR* file)
{
	static _TCHAR path[_MAX_PATH];
	my_tcscpy_s(path, _MAX_PATH, file);
	// find last separator
	_TCHAR *p = _tcsrchr(path, _T('/'));
	if(p != NULL) {
		*(p + 1) = _T('\0');
	}
	return (const _TCHAR *)path;
}

// ----------------------------------------------------------------------------
// string conversion
// ----------------------------------------------------------------------------

const wchar_t *DLL_PREFIX char_to_wchar(const char *cs)
{
	static wchar_t ws[_MAX_PATH];
	mbstowcs(ws, cs, _MAX_PATH);
	return (const wchar_t *)ws;
}

const char *DLL_PREFIX wchar_to_char(const wchar_t *ws)
{
	static char cs[_MAX_PATH];
	wcstombs(cs, ws, _MAX_PATH);
	return (const char *)cs;
}

const _TCHAR *DLL_PREFIX char_to_tchar(const char *cs)
{
	// _TCHAR is char in non-Unicode build
	return (const _TCHAR *)cs;
}

const char *DLL_PREFIX tchar_to_char(const _TCHAR *ts)
{
	// _TCHAR is char in non-Unicode build
	return (const char *)ts;
}

const _TCHAR *DLL_PREFIX wchar_to_tchar(const wchar_t *ws)
{
	return char_to_tchar(wchar_to_char(ws));
}

const wchar_t *DLL_PREFIX tchar_to_wchar(const _TCHAR *ts)
{
	return char_to_wchar(tchar_to_char(ts));
}

// ----------------------------------------------------------------------------
// string format
// ----------------------------------------------------------------------------

const _TCHAR *DLL_PREFIX create_string(const _TCHAR* format, ...)
{
	static _TCHAR buffer[8][_MAX_PATH];
	static unsigned int table_index = 0;
	unsigned int output_index = (table_index++) & 7;

	va_list ap;
	va_start(ap, format);
	my_vstprintf_s(buffer[output_index], _MAX_PATH, format, ap);
	va_end(ap);
	return (const _TCHAR *)buffer[output_index];
}

// ----------------------------------------------------------------------------
// misc
// ----------------------------------------------------------------------------

int32_t DLL_PREFIX muldiv_s32(int32_t nNumber, int32_t nNumerator, int32_t nDenominator)
{
	return (int32_t)((int64_t)nNumber * (int64_t)nNumerator / (int64_t)nDenominator);
}

uint32_t DLL_PREFIX muldiv_u32(uint32_t nNumber, uint32_t nNumerator, uint32_t nDenominator)
{
	return (uint32_t)((uint64_t)nNumber * (uint64_t)nNumerator / (uint64_t)nDenominator);
}

uint32_t DLL_PREFIX get_crc32(uint8_t data[], int size)
{
	static bool initialized = false;
	static uint32_t table[256];

	if(!initialized) {
		for(int i = 0; i < 256; i++) {
			uint32_t c = i;
			for(int j = 0; j < 8; j++) {
				if(c & 1) {
					c = (c >> 1) ^ 0xEDB88320;
				} else {
					c >>= 1;
				}
			}
			table[i] = c;
		}
		initialized = true;
	}
	uint32_t c = ~0;
	for(int i = 0; i < size; i++) {
		c = table[(c ^ data[i]) & 0xff] ^ (c >> 8);
	}
	return ~c;
}

uint16_t DLL_PREFIX jis_to_sjis(uint16_t jis)
{
	pair16_t p;
	p.w = jis - 0x2121;
	if(p.b.h & 1) {
		p.b.l += 0x5e;
	}
	p.b.h >>= 1;
	if(p.b.l >= 0x3f) {
		p.b.l++;
	}
	p.b.l += 0x40;
	if(p.b.h >= 0x1f) {
		p.b.h += 0xc1;
	} else {
		p.b.h += 0x81;
	}
	return p.w;
}

int DLL_PREFIX decibel_to_volume(int decibel)
{
	// 0 decibel = 1024
	if(decibel <= -32) {
		return 0;
	}
	return (int)(1024.0 * pow(10.0, (double)decibel / 10.0));
}

int32_t DLL_PREFIX apply_volume(int32_t sample, int volume)
{
	return (int32_t)(((int64_t)sample * volume) >> 10);
}

// ----------------------------------------------------------------------------
// time
// ----------------------------------------------------------------------------

void DLL_PREFIX get_host_time(cur_time_t* cur_time)
{
	time_t timer = time(NULL);
	struct tm *local = localtime(&timer);
	cur_time->year = local->tm_year + 1900;
	cur_time->month = local->tm_mon + 1;
	cur_time->day = local->tm_mday;
	cur_time->day_of_week = local->tm_wday;
	cur_time->hour = local->tm_hour;
	cur_time->minute = local->tm_min;
	cur_time->second = local->tm_sec;
	cur_time->initialized = true;
}

// cur_time_t members

void cur_time_t::increment()
{
	if(second++ == 60) {
		second = 0;
		if(minute++ == 60) {
			minute = 0;
			if(hour++ == 24) {
				hour = 0;
				// update day
				update_day_of_week();
				if(day_of_week == 0) {
					day_of_week = 7;
				}
				update_year();
			}
		}
	}
}

void cur_time_t::update_year()
{
	static const int days_in_month[12] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
	if(++day > days_in_month[month - 1] + (month == 2 && LEAP_YEAR(year) ? 1 : 0)) {
		day = 1;
		if(++month > 12) {
			month = 1;
			year++;
		}
	}
}

void cur_time_t::update_day_of_week()
{
	static const int t[] = {0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4};
	int y = year;
	if(month < 3) {
		y -= 1;
	}
	day_of_week = (y + y / 4 - y / 100 + y / 400 + t[month - 1] + day) % 7;
}

bool cur_time_t::process_state(void *f, bool loading)
{
	FILEIO *state_fio = (FILEIO *)f;
	state_fio->StateValue(year);
	state_fio->StateValue(month);
	state_fio->StateValue(day);
	state_fio->StateValue(day_of_week);
	state_fio->StateValue(hour);
	state_fio->StateValue(minute);
	state_fio->StateValue(second);
	state_fio->StateValue(initialized);
	return true;
}

// ----------------------------------------------------------------------------
// symbol
// ----------------------------------------------------------------------------

const _TCHAR *DLL_PREFIX get_symbol(symbol_t *first_symbol, uint32_t addr)
{
	for(symbol_t *symbol = first_symbol; symbol != NULL; symbol = symbol->next_symbol) {
		if(symbol->addr == addr) {
			return symbol->name;
		}
	}
	return NULL;
}

const _TCHAR *DLL_PREFIX get_value_or_symbol(symbol_t *first_symbol, const _TCHAR *format, uint32_t addr)
{
	const _TCHAR *name = get_symbol(first_symbol, addr);
	if(name != NULL) {
		return name;
	}
	return create_string(format, addr);
}

const _TCHAR *DLL_PREFIX get_value_and_symbol(symbol_t *first_symbol, const _TCHAR *format, uint32_t addr)
{
	const _TCHAR *name = get_symbol(first_symbol, addr);
	if(name != NULL) {
		return create_string(_T("%s (%s)"), create_string(format, addr), name);
	}
	return create_string(format, addr);
}
