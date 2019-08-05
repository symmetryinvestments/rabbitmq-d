module symmetry.api.rabbitmq.platform_utils;
import std.conv:to;
// import kaleidic.api.rabbitmq;

/+
	#include <stdint.h>
	#include <sys/time.h>
	#include <time.h>
	#include <unistd.h>
+/

version(Posix)
{
	import core.sys.posix.sys.time: timeval,timespec;

	extern(C) int nanosleep(in timespec*, timespec*);
	extern(C) int gettimeofday(timeval*, void*);
	ulong now_microseconds()
	{
	  timeval tv;
	  gettimeofday(&tv, null);
	  return tv.tv_sec.to!ulong * 1000000 + tv.tv_usec.to!ulong;
	}

	void microsleep(int usec)
	{
	  timespec req;
	  req.tv_sec = 0;
	  req.tv_nsec = 1000 * usec;
	  nanosleep(&req, null);
	}
}

else version(Windows)
{
	import core.sys.windows.winbase : FILETIME, GetSystemTimeAsFileTime, Sleep;
	// import core.sys.windows.winnt;
	// import core.sys.windows.syserror;

	/+
		#include <stdint.h>
		#include <windows.h>
	+/

	ulong now_microseconds()
	{
		FILETIME ft;
		GetSystemTimeAsFileTime(&ft);
		return ((ft.dwHighDateTime.to!ulong << 32) | ft.dwLowDateTime.to!ulong) / 10;
	}

	void microsleep(int usec) { Sleep(usec / 1000); }
}
else pragma(msg, "only posix and windows platforms supported");

