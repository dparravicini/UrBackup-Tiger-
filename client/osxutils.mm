#import <Cocoa/Cocoa.h>
#include <Carbon/Carbon.h>

#if MAC_OS_X_VERSION_MAX_ALLOWED >= 1050
#include <CoreServices/CoreServices.h>
#include <Security/Security.h>
#endif

extern "C" void bring_to_foreground()
{
	ProcessSerialNumber psn = { 0, kCurrentProcess };
	SetFrontProcess(&psn);
}

#if MAC_OS_X_VERSION_MAX_ALLOWED >= 1050

extern "C" void register_login_item()
{
	AuthorizationItem right[1] = {{"system.global-login-items.", 0, NULL, 0}};
	AuthorizationRights rights = {1, right};
	AuthorizationRef auth = NULL; 
	AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &auth);
	
	if(auth==NULL)
	{
		return;
	}

	AuthorizationCopyRights(auth, &rights, kAuthorizationEmptyEnvironment,
                              (kAuthorizationFlagDefaults
                               | kAuthorizationFlagInteractionAllowed
                               | kAuthorizationFlagExtendRights), NULL);

	LSSharedFileListRef login_items = LSSharedFileListCreate(NULL, kLSSharedFileListGlobalLoginItems, NULL);
	if(login_items==NULL)
	{
		return;
	}

	NSString* app_path = [[[NSBundle mainBundle] bundleURL] absoluteString];

	LSSharedFileListSetAuthorization(login_items, auth);

	UInt32 seed;
	CFArrayRef login_items_array = LSSharedFileListCopySnapshot(login_items, &seed);
	for (id item in (NSArray *)login_items_array)
	{       
	    LSSharedFileListItemRef item_ref = (LSSharedFileListItemRef)item;
	    CFURLRef item_path;
	    if (LSSharedFileListItemResolve(item_ref, 0, (CFURLRef*) &item_path, NULL) == noErr)
	    {
	        if ([[(NSURL *)item_path path] hasPrefix:app_path])
	        {
	            return;
	        }
	    }       
	}

	NSURL* app_url = [[NSBundle mainBundle] bundleURL];
	LSSharedFileListInsertItemURL(login_items, kLSSharedFileListItemLast,
                                  NULL, NULL, (CFURLRef)(app_url), NULL, NULL);
}

extern "C" void remove_login_item()
{
	AuthorizationItem right[1] = {{"system.global-login-items.", 0, NULL, 0}};
	AuthorizationRights rights = {1, right};
	AuthorizationRef auth = NULL; 
	AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &auth);
	
	if(auth==NULL)
	{
		return;
	}

	AuthorizationCopyRights(auth, &rights, kAuthorizationEmptyEnvironment,
                              (kAuthorizationFlagDefaults
                               | kAuthorizationFlagInteractionAllowed
                               | kAuthorizationFlagExtendRights), NULL);

	LSSharedFileListRef login_items = LSSharedFileListCreate(NULL, kLSSharedFileListGlobalLoginItems, NULL);
	if(login_items==NULL)
	{
		return;
	}

	LSSharedFileListSetAuthorization(login_items, auth);

	NSString* app_path = [[[NSBundle mainBundle] bundleURL] absoluteString];

	UInt32 seed;
	CFArrayRef login_items_array = LSSharedFileListCopySnapshot(login_items, &seed);
	for (id item in (NSArray *)login_items_array)
	{       
	    LSSharedFileListItemRef item_ref = (LSSharedFileListItemRef)item;
	    CFURLRef item_path;
	    if (LSSharedFileListItemResolve(item_ref, 0, (CFURLRef*) &item_path, NULL) == noErr)
	    {
	        if ([[(NSURL *)item_path path] hasPrefix:app_path])
	        {
	            LSSharedFileListItemRemove(login_items, item_ref);
	        }
	    }       
	}
}

#else

static void run_login_item_script(NSString* command)
{
	NSString* path = [[NSBundle mainBundle] bundlePath];
	if ([path rangeOfString:@"\""].location != NSNotFound)
	{
		return;
	}

	NSString* source = [NSString stringWithFormat:command, path];
	NSAppleScript* script = [[NSAppleScript alloc] initWithSource:source];
	[script executeAndReturnError:NULL];
	[script release];
}

extern "C" void register_login_item()
{
	run_login_item_script(@"tell application \"System Events\" to make login item at end with properties {path:\"%@\", hidden:false}");
}

extern "C" void remove_login_item()
{
	run_login_item_script(@"tell application \"System Events\" to delete (every login item whose path is \"%@\")");
}

#endif

/* ------------------------------------------------------------------
 * Tiger menu bar status item.
 *
 * wxWidgets 3.0 Carbon implements wxTaskBarIcon on top of the
 * application dock tile only (wxTBI_DOCK), so the original UrBackup
 * tray had no place to appear on Mac OS X 10.4. NSStatusItem exists
 * since 10.1, so the same original icons are shown in the menu bar
 * through it and the click is forwarded to the existing wx menu.
 * ------------------------------------------------------------------ */

#ifdef __WXOSX_CARBON__

#include <wx/icon.h>
#include <wx/image.h>
#include <wx/bitmap.h>
#include <wx/string.h>
#include "TrayIcon.h"
#include "osxtray.h"

@interface TigerTrayTarget : NSObject
{
@public
	TigerTrayClickFn _fn;
	void* _ctx;
	NSStatusItem* _item;
}
- (void)clicked:(id)sender;
@end

@implementation TigerTrayTarget
- (void)clicked:(id)sender
{
	if(_fn!=NULL)
	{
		_fn(_ctx);
	}
}
@end

static NSImage* tigerImageFromIcon(const wxIcon& icon)
{
	wxBitmap bmp(icon);
	if(!bmp.IsOk())
	{
		return nil;
	}
	wxImage img=bmp.ConvertToImage();
	if(!img.IsOk())
	{
		return nil;
	}
	const int w=img.GetWidth();
	const int h=img.GetHeight();
	const bool sourceAlpha=img.HasAlpha()!=0;
	const int spp=4;
	NSBitmapImageRep* rep=[[NSBitmapImageRep alloc]
		initWithBitmapDataPlanes:NULL pixelsWide:w pixelsHigh:h bitsPerSample:8
		samplesPerPixel:spp hasAlpha:YES isPlanar:NO
		colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:0 bitsPerPixel:0];
	if(rep==nil)
	{
		return nil;
	}
	unsigned char* dst=[rep bitmapData];
	const int stride=[rep bytesPerRow];
	const unsigned char* rgb=img.GetData();
	const unsigned char* alp=sourceAlpha?img.GetAlpha():NULL;
	for(int y=0;y<h;y++)
	{
		unsigned char* row=dst+y*stride;
		for(int x=0;x<w;x++)
		{
			const int sb=(y*w+x)*3;
			const int db=x*spp;
			row[db+0]=rgb[sb+0];
			row[db+1]=rgb[sb+1];
			row[db+2]=rgb[sb+2];
			row[db+3]=sourceAlpha?alp[y*w+x]:255;
		}
	}
	NSImage* result=[[NSImage alloc] initWithSize:NSMakeSize(w,h)];
	[result addRepresentation:rep];
	[rep release];
	return result;
}

static NSImage* tigerImageFromFile(const char* path)
{
	if(path==NULL)
	{
		return nil;
	}

	wxImage img;
	if(!img.LoadFile(wxString::FromUTF8(path), wxBITMAP_TYPE_ICO) || !img.IsOk())
	{
		return nil;
	}

	const int sw=img.GetWidth();
	const int sh=img.GetHeight();
	const int w=32;
	const int h=32;
	const bool sourceAlpha=img.HasAlpha()!=0;
	const bool sourceMask=img.HasMask()!=0;
	unsigned char maskRed=0, maskGreen=0, maskBlue=0;
	if(sourceMask)
	{
		maskRed=img.GetMaskRed();
		maskGreen=img.GetMaskGreen();
		maskBlue=img.GetMaskBlue();
	}

	const int spp=4;
	NSBitmapImageRep* rep=[[NSBitmapImageRep alloc]
		initWithBitmapDataPlanes:NULL pixelsWide:w pixelsHigh:h bitsPerSample:8
		samplesPerPixel:spp hasAlpha:YES isPlanar:NO
		colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:0 bitsPerPixel:0];
	if(rep==nil)
	{
		return nil;
	}

	unsigned char* dst=[rep bitmapData];
	const int stride=[rep bytesPerRow];
	const unsigned char* rgb=img.GetData();
	const unsigned char* alp=sourceAlpha?img.GetAlpha():NULL;
	for(int y=0;y<h;y++)
	{
		unsigned char* row=dst+y*stride;
		const int sy=y*sh/h;
		for(int x=0;x<w;x++)
		{
			const int sx=x*sw/w;
			const int sb=(sy*sw+sx)*3;
			const int db=x*spp;
			const unsigned char r=rgb[sb+0];
			const unsigned char g=rgb[sb+1];
			const unsigned char b=rgb[sb+2];
			unsigned char a=255;
			if(sourceAlpha)
			{
				a=alp[sy*sw+sx];
			}
			else if(sourceMask)
			{
				a=(r==maskRed && g==maskGreen && b==maskBlue)?0:255;
			}
			else
			{
				a=r>g ? (r>b?r:b) : (g>b?g:b);
				row[db+0]=0;
				row[db+1]=0;
				row[db+2]=0;
				row[db+3]=a;
				continue;
			}
			row[db+0]=r;
			row[db+1]=g;
			row[db+2]=b;
			row[db+3]=a;
		}
	}

	NSImage* result=[[NSImage alloc] initWithSize:NSMakeSize(w,h)];
	[result addRepresentation:rep];
	[rep release];
	return result;
}

void* tiger_tray_create(TigerTrayClickFn fn, void* ctx)
{
	TigerTrayTarget* target=[[TigerTrayTarget alloc] init];
	target->_fn=fn;
	target->_ctx=ctx;
	NSStatusItem* item=[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
	if(item==nil)
	{
		[target release];
		return NULL;
	}
	[item retain];
	target->_item=item;
	[item setTarget:target];
	[item setAction:@selector(clicked:)];
	[item setHighlightMode:YES];
	[item setLength:24.0];
	return target;
}

void tiger_tray_set_icon(void* handle, const wxIcon& icon, const wxString& tooltip)
{
	TigerTrayTarget* target=(TigerTrayTarget*)handle;
	if(target==NULL)
	{
		return;
	}
	NSImage* img=tigerImageFromIcon(icon);
	if(img!=nil)
	{
		[img setScalesWhenResized:YES];
		[img setSize:NSMakeSize(18,18)];
		[target->_item setImage:img];
		[img release];
	}
	if(!tooltip.empty())
	{
		wxCharBuffer utf8=tooltip.utf8_str();
		NSString* text=[NSString stringWithUTF8String:utf8.data()];
		if([target->_item respondsToSelector:@selector(setToolTip:)])
		{
			[target->_item performSelector:@selector(setToolTip:) withObject:text];
		}
	}
}

void tiger_tray_set_icon_file(void* handle, const char* path, const wxString& tooltip)
{
	TigerTrayTarget* target=(TigerTrayTarget*)handle;
	if(target==NULL)
	{
		return;
	}
	NSImage* img=tigerImageFromFile(path);
	if(img!=nil)
	{
		[img setScalesWhenResized:YES];
		[img setSize:NSMakeSize(18,18)];
		[target->_item setImage:img];
		[img release];
	}
	if(!tooltip.empty())
	{
		wxCharBuffer utf8=tooltip.utf8_str();
		NSString* text=[NSString stringWithUTF8String:utf8.data()];
		if([target->_item respondsToSelector:@selector(setToolTip:)])
		{
			[target->_item performSelector:@selector(setToolTip:) withObject:text];
		}
	}
}

void tiger_tray_remove(void* handle)
{
	TigerTrayTarget* target=(TigerTrayTarget*)handle;
	if(target==NULL)
	{
		return;
	}
	[target->_item setImage:nil];
}

void tiger_tray_destroy(void* handle)
{
	TigerTrayTarget* target=(TigerTrayTarget*)handle;
	if(target==NULL)
	{
		return;
	}
	[[NSStatusBar systemStatusBar] removeStatusItem:target->_item];
	[target->_item release];
	target->_item=nil;
	[target release];
}

#endif
