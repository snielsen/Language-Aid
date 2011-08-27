// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import <Cocoa/Cocoa.h>
#import <WebKit/Webkit.h>

#ifdef LAINTERNAL

#import <dlfcn.h>
#import <pthread.h>

#import <mach-o/dyld.h>
#import <mach-o/getsect.h>

#import <objc/objc-class.h>
#import <objc/objc-runtime.h>

#import <Security/Authorization.h>
#import <Security/AuthorizationTags.h>

#define LAWEBSERVICEMODULE 0
#define LAOTHERMODULE 1

#ifdef LAAPP
#define REPCHANGEDNOTIFY	@"repositoryChanged"
#elif LAPREFPANE
#define REPCHANGEDNOTIFY	@"repositoryChangedPref"
#endif

extern NSMutableDictionary*			Triggers;

/*@interface NSUserDefaults ( unexportedNSUserDefaults )
- (id) objectForKey:(NSString*)defaultName inDomain:(NSString*)domain;
- (void) setObject:(id)value forKey:(NSString*)defaultName inDomain:(NSString*)domain;
- (void) removeObjectForKey:(NSString*)defaultName inDomain:(NSString*)domain;
@end*/

@interface WebView (unexportedWebView)
- (NSString*) mainFrameURL;
@end

#endif

// This is the latest compatabilty version for plugins (1.1.1)
#define LAPLUGINCOMPATIBILITY	010101

#define FULLVALUE				@"fullValue"
#define SELECTEDVALUE			@"selectedValue"
#define INDIVIDUALVALUE			@"individualValue"

// The window that pops up and displays results when triggered
@interface inspectorWindow : NSPanel
{
	@public
	WebView*				webView;
}

- (NSStringEncoding) responseEncoding;			// Attempts to return the text encoding of the request response.

- (NSString*) fullValue;						// Returns a string holding the fullValue.
- (NSString*) selectedValue;					// Returns a string holding the selectedValue.
- (NSString*) individualValue;					// Returns a string holding the individualValue.

- (void) setFullValue:(NSString*)input;			// You can manually set the value of fullValue with this
- (void) setSelectedValue:(NSString*)input;		// You can manually set the value of selectedValue with this
- (void) setIndividualValue:(NSString*)input;	// You can manually set the value of individualValue with this

- (void) setInput:(NSString*)input;				// You can manually set the value of all three values (fullValue, selectedValue, individualValue) with this

- (void) displayLookup;							// This will cause another query to be triggered on the currently grabbed set of text

- (void) fadeOut;								// Fades out the window
- (void) fadeIn;								// Fades in the window

- (void) setPriority:(NSArray*)priorities;		// You can set the order of priority of input strings by passing an array of FULLVALUE, SELECTEDVALUE and INDIVIDUALVALUE in whatever order you would like the results.

@end

// The base plugin class
@interface LAPlugin : NSObject
{
#ifdef LAINTERNAL
	@public
#endif

	IBOutlet NSView*		UI;					// Your user interface's NSView define in the NIB file
	
	inspectorWindow*		pluginWindow;		// This is the window that actually displays your NSView and the reults.  There are a few public messages that can be sent to it noted above.
}

+ (int) PluginCompatibility;
+ (NSString*) Author;
+ (NSString*) windowTitle;
- (BOOL) filterLoad:(NSURL*)loadingURL;

@end

// Base web service plugin class
@interface LAWebServicePlugin : LAPlugin
{
	
}

- (NSURLRequest*) createQueryFull:(NSString*)fullValue selected:(NSString*)selectedValue individual:(NSString*)individualValue;
- (NSString*) filterResult:(NSData*)result;

@end

// Base plugin of any other type
@interface LAOtherPlugin : LAPlugin
{
	
}

- (NSString*) resultOfQueryFull:(NSString*)fullValue selected:(NSString*)selectedValue individual:(NSString*)individualValue;
- (NSURL*) baseURL;

@end

#ifdef LAINTERNAL

#define NOERROR			0
#define DOWNLOADPROBLEM	1

extern bool isPluginThere( NSString* pname );

@interface LAPluginReference : NSObject
{
	@public
	NSString*				modulePath;
	
	void*					handle;									// dlopen handle
	
	mach_header*			mh;										// Mach header for the object
	int						mhindex;								// Mach header index number
	char*					classdata;								// Pointer to the Objective-C class data resident in this object
	int						classnum;								// Number of Objective-C classes resident in this object
	
	Class					pluginClass;
	
	NSBundle*				thaBundle;
	NSDictionary*			infoDictionary;							// This is here because sometimes NSBundle screws up and doesn't respond to anything
	
	bool					aorensigned;
	
	bool					isLoaded;
	
	NSString*				name;
	
	NSString*				newversion;
	NSString*				newversionURL;
	
	NSString*				upgradedVersion;
}

- (id) initWithPath:(NSString*)path Bundle:(NSBundle*)inbun Signed:(bool)isSigned isLoaded:(bool)isloaded;

- (void) nowLoad;
- (int) upgrade:(AuthorizationRef)myAuthorizationRef;
+ (bool) signStatus:(NSBundle*)dabun;

@end

@interface PluginManager : NSObject
{
	@public
}

- (NSArray*) reload;

@end

extern NSMutableArray*		loadedLAPlugins;

bool setupKQueue( void );
void LoadLAPlugins( void );

extern PluginManager*		thePM;

extern Class				pmClass;
extern Class				wsClass;
extern Class				otClass;

extern int					unsignedOK;

extern NSRecursiveLock*		LAPluginsLock;

extern bool					safeToJump;

extern pthread_cond_t		repcond;
extern pthread_mutex_t		repmutex;

#endif