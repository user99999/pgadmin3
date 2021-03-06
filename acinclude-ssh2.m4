dnl CURL_CHECK_NONBLOCKING_SOCKET
dnl -------------------------------------------------
dnl Check for how to set a socket to non-blocking state. There seems to exist
dnl four known different ways, with the one used almost everywhere being POSIX
dnl and XPG3, while the other different ways for different systems (old BSD,
dnl Windows and Amiga).
dnl
dnl There are two known platforms (AIX 3.x and SunOS 4.1.x) where the
dnl O_NONBLOCK define is found but does not work. This condition is attempted
dnl to get caught in this script by using an excessive number of #ifdefs...
dnl
AC_DEFUN([CURL_CHECK_NONBLOCKING_SOCKET],
[
	AC_MSG_CHECKING([non-blocking sockets style])
	AC_TRY_COMPILE([
		/* headers for O_NONBLOCK test */
		#include <sys/types.h>
		#include <unistd.h>
		#include <fcntl.h>
	],[
		/* try to compile O_NONBLOCK */

		#if defined(sun) || defined(__sun__) || defined(__SUNPRO_C) || defined(__SUNPRO_CC)
			# if defined(__SVR4) || defined(__srv4__)
				#  define PLATFORM_SOLARIS
			# else
				#  define PLATFORM_SUNOS4
			# endif
		#endif
		#if (defined(_AIX) || defined(__xlC__)) && !defined(_AIX41)
			# define PLATFORM_AIX_V3
		#endif

		#if defined(PLATFORM_SUNOS4) || defined(PLATFORM_AIX_V3) || defined(__BEOS__)
			#error "O_NONBLOCK does not work on this platform"
		#endif
		int socket;
		int flags = fcntl(socket, F_SETFL, flags | O_NONBLOCK);
	],[
		dnl the O_NONBLOCK test was fine
		nonblock="O_NONBLOCK"
		AC_DEFINE(HAVE_O_NONBLOCK, 1, [use O_NONBLOCK for non-blocking sockets])
	],[
		dnl the code was bad, try a different program now, test 2

		AC_TRY_COMPILE([
			/* headers for FIONBIO test */
			#include <unistd.h>
			#include <stropts.h>
		],[
			/* FIONBIO source test (old-style unix) */
			int socket;
			int flags = ioctl(socket, FIONBIO, &flags);
		],[
			dnl FIONBIO test was good
			nonblock="FIONBIO"
			AC_DEFINE(HAVE_FIONBIO, 1, [use FIONBIO for non-blocking sockets])
		],[
			dnl FIONBIO test was also bad
			dnl the code was bad, try a different program now, test 3

			AC_TRY_COMPILE([
				/* headers for ioctlsocket test (Windows) */
				#undef inline
				#ifdef HAVE_WINDOWS_H
					#ifndef WIN32_LEAN_AND_MEAN
						#define WIN32_LEAN_AND_MEAN
					#endif
					#include <windows.h>
					#ifdef HAVE_WINSOCK2_H
						#include <winsock2.h>
					#else
						#ifdef HAVE_WINSOCK_H
							#include <winsock.h>
						#endif
					#endif
				#endif
			],[
				/* ioctlsocket source code */
				SOCKET sd;
				unsigned long flags = 0;
				sd = socket(0, 0, 0);
				ioctlsocket(sd, FIONBIO, &flags);
			],[
				dnl ioctlsocket test was good
				nonblock="ioctlsocket"
				AC_DEFINE(HAVE_IOCTLSOCKET, 1, [use ioctlsocket() for non-blocking sockets])
			],[
				dnl ioctlsocket didnt compile!, go to test 4
				AC_TRY_LINK([
					/* headers for IoctlSocket test (Amiga?) */
					#include <sys/ioctl.h>
				],[
					/* IoctlSocket source code */
					int socket;
					int flags = IoctlSocket(socket, FIONBIO, (long)1);
				],[
					dnl ioctlsocket test was good
					nonblock="IoctlSocket"
					AC_DEFINE(HAVE_IOCTLSOCKET_CASE, 1, [use Ioctlsocket() for non-blocking sockets])
				],[
					dnl Ioctlsocket didnt compile, do test 5!
					AC_TRY_COMPILE([
						/* headers for SO_NONBLOCK test (BeOS) */
						#include <socket.h>
					],[
						/* SO_NONBLOCK source code */
						long b = 1;
						int socket;
						int flags = setsockopt(socket, SOL_SOCKET, SO_NONBLOCK, &b, sizeof(b));
					],[
						dnl the SO_NONBLOCK test was good
						nonblock="SO_NONBLOCK"
						AC_DEFINE(HAVE_SO_NONBLOCK, 1, [use SO_NONBLOCK for non-blocking sockets])
					],[
						dnl test 5 didnt compile!
						nonblock="nada"
						AC_DEFINE(HAVE_DISABLED_NONBLOCKING, 1, [disabled non-blocking sockets])
					])
					dnl end of fifth test
				])
				dnl end of forth test
			])
			dnl end of third test
		])
		dnl end of second test
	])
	dnl end of non-blocking try-compile test
	AC_MSG_RESULT($nonblock)

	if test "$nonblock" = "nada"; then
		AC_MSG_WARN([non-block sockets disabled])
	fi
])
