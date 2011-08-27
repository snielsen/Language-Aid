// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import <PreferencePanes/PreferencePanes.h>
#import <Carbon/Carbon.h>
#import <CoreFoundation/CFPreferences.h> 
#import <WebKit/Webkit.h>
#import <Security/Authorization.h>
#import <Security/AuthorizationTags.h>

#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <sys/un.h>

#import "LAPlugin.h"
#import "LAUserDefaults.h"

#import "RegistrationWindow.h"
#import "NewModules.h"
#import "PluginModulesTable.h"
#import "TIDError.h"
#import "JustNumFormatter.h"

#define PIPEPORT			""

#define REGISTRATIONTRIES	15
#define REGTRYSLEEPTIME		4

#define DEFAULTKEYTRIGGER	@"F7"

@class LanguageAidPref;
@class RegistrationWindow;
@class NewModules;

extern unsigned int			PPHeight;

extern NSMutableArray*		newModulesArray;

extern NSString*			registrationKey;

extern NSBundle*			myBundle;

@interface LanguageAidPref : NSPreferencePane 
{
	@public	
	IBOutlet pluginModulesTable*		pluginModules;
	IBOutlet NSButton*					unsignedPlugins;
	
	IBOutlet NSButton*					copyrightNotice;
	
	IBOutlet RegistrationWindow*		regWindow;
	
	// Status
	IBOutlet NSButton*					onoff;
	IBOutlet NSTextField*				status;
	IBOutlet NSButton*					enableAtLogin;
	
	// Registration
	IBOutlet NSButton*					serial;
	IBOutlet NSTextField*				registrationstatus;
	
	IBOutlet NSButton*					supportButton;
	
	IBOutlet NSButton*					uninstallButton;
	IBOutlet NSButton*					upgradeButton;
	
	IBOutlet NSProgressIndicator*		webpayProgress;
	
	// Upgrading
	IBOutlet NSButton*					addnewModulesButton;
	IBOutlet NSButton*					upgradeModulesButton;
	IBOutlet NSTextField*				upgradeStatus;
	IBOutlet NSProgressIndicator*		upgradeProgress;
	
	IBOutlet NewModules*				newModWindow;
	
	IBOutlet TIDError*					TIDErrorWindow;
	
	// Lookup Trigger
	IBOutlet NSButton*					command;
	IBOutlet NSButton*					shift;
	IBOutlet NSButton*					option;
	IBOutlet NSButton*					control;
	
	IBOutlet NSPopUpButton*				key;
	IBOutlet NSPopUpButton*				mouse;
	IBOutlet NSMatrix*					actiontype;
	
	IBOutlet NSButtonCell*				keytype;
	IBOutlet NSButtonCell*				mousetype;
	
	IBOutlet NSButton*					fadeAwayButton;
	IBOutlet NSTextField*				fadeAwaySeconds;
	
		
	LAPluginReference*					currentPlugin;
	NSMutableDictionary*				currentPluginDictionary;
	
	NSString*							tehData;
	
	NSUserDefaults*						standardDefaults;
	LAUserDefaults*						defaults;
	
	EventLoopTimerRef					checkTimer;
	
	bool								currentlyRunning;
	
	int									keySocket;
	
	bool								serialBack;
	
	bool								expanded;

	//NSMutableString*					transaction;
	float								oldwidth;
	
	int									regThreadSocket;
	
	int									supportTimes;
	
	bool								shuttingDown;
	bool								registering;
	
	int									unsignedWarned;
	
	NSImage*							aorenlogo;
	NSImage*							unsignedImage;
	
	IBOutlet NSTextField*				versionField;
}

- (NSString*) mouseToMouseLocalized:(NSString*)m;
- (void) queryRunning;
- (void) pushDefaults;

- (void) setBootingUp;
- (void) setShuttingDown;
- (void) setRunning;
- (void) setNotRunning;

- (void) setcommand:(NSButton*)sender;
- (void) setshift:(NSButton*)sender;
- (void) setoption:(NSButton*)sender;
- (void) setcontrol:(NSButton*)sender;
- (void) setfunctionkey:(NSPopUpButton*)sender;
- (void) setmouseclick:(NSPopUpButton*)sender;
- (void) setType:(NSMatrix*)sender;
- (void) setfade:(NSButton*)sender;
- (void) setfadesecs:(NSTextField*)sender;
- (void) toggleStatus:(NSButton*)sender;
- (void) getSerial:(NSButton*)sender;
- (void) changeLogin:(NSButton*)sender;
- (void) supportClick:(NSButton*)sender;
- (void) uninstallClick:(NSButton*)sender;
- (void) upgradeClick:(NSButton*)sender;
- (void) copyrightClick:(NSButton*)sender;
- (void) unsignedClick:(NSButton*)sender;
- (void) pluginClick:(NSTableView*)sender;
- (void) upgradeModulesClick:(NSButton*)sender;
- (void) addnewModulesClick:(NSButton*)sender;

@end