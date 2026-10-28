#ifndef URBACKUP_TIGER_PORTABLE_PATHS_H
#define URBACKUP_TIGER_PORTABLE_PATHS_H

#include <stdlib.h>
#include <string>

// The original mac build stores absolute configure-time paths in the binary.
// The application bundle supplies these variables so that the same executable
// can be installed by any user without referring to the build user's home.
inline std::string tigerVarDir(const char* fallback)
{
#ifdef __APPLE__
	const char* value = getenv("URBACKUP_TIGER_VARDIR");
	if (value != NULL && value[0] != '\0')
	{
		return std::string(value);
	}
#endif
	return std::string(fallback);
}

inline std::string tigerDataDir(const char* fallback)
{
#ifdef __APPLE__
	const char* value = getenv("URBACKUP_TIGER_DATADIR");
	if (value != NULL && value[0] != '\0')
	{
		return std::string(value);
	}
#endif
	return std::string(fallback);
}

#endif
