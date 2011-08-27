// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import <Cocoa/Cocoa.h>

#import "LanguageInspector.h"
#import "LanguageAidService.h"
#import "LAUserDefaults.h"
#import "LAPlugin.h"

#import "Timing.h"
#import "Input.h"
#import "GetPID.h"

@class LanguageAidService;

@interface HotKeyRefWrapper: NSObject
{
	@public
	EventHotKeyRef					daRef;
}

@end

@interface MouseButtonWrapper: NSObject
{
	@public
	int								daButton;
}

@end

@interface TIDUpdate : NSWindow
{
	@public
	IBOutlet NSButton*				quit;
	IBOutlet NSButton*				update;
	
	IBOutlet NSTextField*			newTID;
	
	NSString*						gotoldTID;
	
	bool							EA;
}

- (void) quitTID:(id)sender;
- (void) updateTID:(id)sender;

@end

@interface TranslatorApp : NSApplication
{
	@public
	NSMutableDictionary*			windowSettings;
	
	NSMutableDictionary*			hotKeys;
	NSMutableDictionary*			hotButtons;
	
	NSMutableDictionary*			inspectorArrays;

	EventHandlerUPP					hotKeyDownFunction;
	EventHandlerUPP					hotKeyUpFunction;
	EventHandlerUPP					modsChangedFunction;
	
	AXUIElementRef					systemWideElement;
	AXUIElementRef					currentUIElementRef;
	
	IBOutlet LanguageInspector*		currentlyLoadingInspector;
	IBOutlet TIDUpdate*				updateWindow;
	
	LanguageAidService*				service;
}

- (int) runModalForWindow:(NSWindow*)theWindow;

- (LanguageInspector*) inspectorForType:(NSString*)moduleType;
- (void) LoadEarlyDefaults;
- (void) LoadDefaults;
- (void) getRegistration;

- (void) lookup:(NSString*)text module:(NSString*)module;
- (void) lookup:(NSPasteboard*)pboard userData:(NSString*)userData error:(NSString**)error;

@end

extern TranslatorApp*		TApp;
extern LAUserDefaults*		defaults;

extern "C"
{
	extern void TSMUnrestrictInputSourceAccess( void );
	extern unsigned int TSMGetInputSourceCount( unsigned int* );
	extern int TSMCreateInputSourceRefForIndex( int, unsigned int* );
	extern id TSMGetInputSourceProperty( unsigned int, NSString* Prop );
	extern unsigned int TSMEnableInputSource( unsigned int );
	extern unsigned int TSMSelectInputSource( unsigned int );
}
