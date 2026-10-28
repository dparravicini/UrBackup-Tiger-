#ifndef OSXTRAY_H
#define OSXTRAY_H

#ifdef __WXOSX_CARBON__

class wxIcon;
class wxString;

typedef void (*TigerTrayClickFn)(void* ctx);

void* tiger_tray_create(TigerTrayClickFn fn, void* ctx);
void tiger_tray_set_icon(void* handle, const wxIcon& icon, const wxString& tooltip);
void tiger_tray_set_icon_file(void* handle, const char* path, const wxString& tooltip);
void tiger_tray_remove(void* handle);
void tiger_tray_destroy(void* handle);

#endif

#endif
