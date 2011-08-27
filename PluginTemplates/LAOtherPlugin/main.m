#import "ÇPROJECTNAMEÈ.h"

@implementation ÇPROJECTNAMEÈ

+ (int) PluginCompatibility { return LAPLUGINCOMPATIBILITY; }
+ (NSString*) Title { return @"<your plugin service>"; }
+ (NSString*) Author { return @"<your name>"; }
+ (NSString*) windowTitle { return @"ÇPROJECTNAMEÈ"; }

- (BOOL) filterLoad:(NSURL*)loadingURL
{
	// Implementation of this method in the subclass is optional.  By default it always returns YES.
	// When the user clicks on a link in the webView you have the option here of examining the destination URL and applying the plugin's results filter to that page after it completely loads.
	// This is useful if the links displayed lead to other pages of similar format.
	// You may however wish to not filter other pages that your user navigates to or selectivly filter depending on the URL.
	return YES;
}

- (bool) setup
{
	// Kind of like init.  Optional.  Do all your init-like setup here and return true or false if not successful. 
	// Called only upon load into the actual Language Aid process.
	// If false is returned then the load of the module is aborted.	
	// Plugins are run from both within Language Aid (com.aoren.LanguageAid) and within the pref pane (com.apple.systempreferences) and so when saving settings be sure that you know where you are saving them.
	// One thing you can do is explicitly share Language Aid's defaults domain by prepending your keys like this: [[NSUserDefaults standardUserDefaults] setObject:someobject forKey:@"ÇPROJECTNAMEÈ - somekey" inDomain:@"com.aoren.LanguageAid"] or you can pick your own.
	
	return true;
}

#pragma mark Prefs and Config

+ (void) updateSettings
{
	// Optional section called when the module is loaded into the PrefPane.  
	// This is an appropriate place to query lists of mirrors or other settings/prefs that should only be changed once in a while.
	// This method is called in it's own thread and so if you chose to implement it be sure to create and release an NSAutoreleasePool for it.
	// Plugins are run from both within Language Aid (com.aoren.LanguageAid) and within the pref pane (com.apple.systempreferences) and so when saving settings be sure that you know where you are saving them.
	// One thing you can do is explicitly share Language Aid's defaults domain by prepending your keys like this: [[NSUserDefaults standardUserDefaults] setObject:someobject forKey:@"ÇPROJECTNAMEÈ - somekey" inDomain:@"com.aoren.LanguageAid"] or you can pick your own.
}

#pragma mark LAOther

// Every time this module's lookup trigger is hit, Language Aid will call this method.  
// Language Aid passes you at least one and up to three forms of the text it grabbed in the variables:
//
//       fullValue - the biggest text chunk that the cursor is hovering over
//   selectedValue - the currently selected text (if possible, could be NULL, be sure to check)
// individualValue - if the text is short enough it gets put in here as well or sometimes it is the individual word that the cursor is hovering over (if possible, could be NULL, be sure to check)
//
// From this data you are to create an NSString containing HTML which will be subsequently displayed by the floating panel using any disk lookups or other procedures which you chose to use. 
// This is where you could do any or special formatting of the lookup results.
// You may return NULL if you wish and an appropriate error message will be displayed.

- (NSString*) resultOfQueryFull:(NSString*)fullValue selected:(NSString*)selectedValue individual:(NSString*)individualValue
{
	// Do whatever your query does based on the inputs here
	NSString* result = NULL;
	
	     if( individualValue ){ result = individualValue; }
	else if(   selectedValue ){ result = selectedValue;   }
	else if(       fullValue ){ result = fullValue;       }
	
	// And when you have a result, format it into HTML and return it
	
	return result;
}

// This is called because the floating panel's WebView needs to have some sort of URL with which to base its contents on.

- (NSURL*) baseURL
{
	// URL of your results so that the WebView has an idea of where your results came from (can be a local file or whatever, does not necessarily have to be accurate)
	return [NSURL fileURLWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"Results" ofType:@"html" inDirectory:0L]];
}

@end