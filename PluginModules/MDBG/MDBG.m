// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import "MDBG.h"

LAUserDefaults* defaults;

@implementation MDBG

+ (void) initialize { defaults = [[LAUserDefaults alloc] initWithDomain:@"com.aoren.LanguageAid.MDBG"]; }
+ (int) PluginCompatibility { return LAPLUGINCOMPATIBILITY; }
+ (NSString*) Title { return @"Chinese Lookups (MDBG)"; }
+ (NSString*) Author { return @"Aoren Software"; }
+ (NSString*) windowTitle { return @"MDBG"; }

- (NSArray*) priorities { return [NSArray arrayWithObjects:SELECTEDVALUE, FULLVALUE, INDIVIDUALVALUE, 0L]; }

- (bool) setup
{
	lastrequest = 0L;
	requestdepth = 0;
	
	[charactersystem selectItemWithTag:[[defaults objectForKey:@"MDBG - default character system"] intValue]];
	[resultstyle selectItemWithTag:[[defaults objectForKey:@"MDBG - default result style"] intValue]];
	[pinyinstlye selectCellWithTag:[[defaults objectForKey:@"MDBG - default pinyin style"] intValue]];
	
	mirrors = [[defaults objectForKey:@"MDBG - mirrors"] retain];
	
	// Perhaps this is the first time we have run it or we never had net access before
	if( !mirrors )
	{
		[MDBG updateSettings];
		
		mirrors = [[defaults objectForKey:@"MDBG - mirrors"] retain];
		
		if( !mirrors ){ return false; } // Hmm looks like no net access, can't proceed without the dictionaries and mirror lists.
	}
	
	[mirror removeAllItems];
	NSEnumerator* mirre = [mirrors keyEnumerator]; id mirrkey;
	while( mirrkey = [mirre nextObject] ){ [mirror addItemWithTitle:mirrkey]; }
	
	NSString* dmirror = [defaults objectForKey:@"MDBG - default mirror"];
	
	if( dmirror )
	{
		if( [mirrors objectForKey:dmirror] )
		{
			[mirror selectItemWithTitle:dmirror];
		}
		else
		{
			[mirror selectItemWithTitle:@"Germany"];
			[defaults setObject:@"Germany" forKey:@"MDBG - default mirror"];
			[defaults synchronize];
		}
	}
	else
	{
		[mirror selectItemWithTitle:@"Germany"];
		[defaults setObject:@"Germany" forKey:@"MDBG - default mirror"];
		[defaults synchronize];
	}
	
	return true;
}

#pragma mark Prefs and Config

+ (void) updateSettings
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	// Get the mirrors from Aoren Software (because the URLs on the lookup pages are not always uniform and automatically parseable I have decided to manually maintain a mirrors list)
	NSDictionary* themirrors = [NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:@"http://www.aorensoftware.com/LanguageAid/Plugins/MDBG/mdbgmirrors.plist"]];
	if( themirrors )
	{
		[defaults setObject:themirrors forKey:@"MDBG - mirrors"];
	}
	else if( ![defaults objectForKey:@"MDBG - mirrors"] )
	{
		// If we can't get the mirrors list and we have never before gotten them, just default to the main mirror 
		NSMutableDictionary* themirrorsDefault = [NSMutableDictionary dictionary];
		[themirrorsDefault setObject:@"http://www.mdbg.net/chindict/chindict.php" forKey:@"Germany"];
		[defaults setObject:themirrorsDefault forKey:@"MDBG - mirrors"];
	}
	
	[defaults synchronize];
	
	[pool release];
}

#pragma mark LAWebService

- (NSURLRequest*) createQueryFull:(NSString*)fullValue selected:(NSString*)selectedValue individual:(NSString*)individualValue preferred:(NSString*)preferredValue
{
	// Build the POST query
	NSMutableString* POSTquery = [NSMutableString string];
	
	// Here we append which dictionary we are going to do the lookup into
	[POSTquery appendFormat:@"client=aoren-la&ext=1&dss=1&wdrst=%d&wdqchsv=%d&wddmtm=%d", [[charactersystem selectedItem] tag], [[resultstyle selectedItem] tag], [[pinyinstlye selectedCell] tag]];
	
	// Here we append what we are actually going to query.  Because of the nature of the MDBG we want to submit as much as we can.

	if( lastrequest ){ [lastrequest release]; lastrequest = 0L; requestdepth = 0; }
	
	[POSTquery appendFormat:@"&ewdqchs=%@", preferredValue]; lastrequest = [preferredValue retain];
	
	NSData* POSTdata = [POSTquery dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
	
	// Setup the URL request
	//NSString* req = [[NSString stringWithFormat:@"%@?%@", [mirrors objectForKey:[[mirror selectedItem] title]], POSTquery] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	//NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:req]]; // Whatever your URL is, this is simply a test one
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[mirrors objectForKey:[[mirror selectedItem] title]]]]; 
	[request setHTTPMethod: @"POST"]; // Or GET or whatever
	[request setHTTPBody:POSTdata];
	[request setHTTPShouldHandleCookies:YES];
	
	/*NSString* dastring = [NSString stringWithFormat:@"%@?%@", [mirrors objectForKey:[[mirror selectedItem] title]], POSTquery];
	
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[dastring stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]]; 
	//[request setHTTPMethod: @"GET"]; // Or GET or whatever
	//[request setHTTPBody:POSTdata];*/
	
	return request;
}

- (NSString*) filterResult:(NSData*)result
{
	// Filter out the HTML we don't want to display
	NSMutableString* tobefiltered = [[NSMutableString alloc] initWithBytes:[result bytes] length:[result length] encoding:[pluginWindow responseEncoding]];
	//NSMutableString* tobefiltered = [[NSMutableString alloc] initWithBytes:[result bytes] length:[result length] encoding:NSUTF8StringEncoding];
	
	requestdepth++;
	
	if( tobefiltered )
	{
		return tobefiltered;
	}

	return NULL;
}

#pragma mark IB Callbacks

- (void) hitBack:(id)sender
{
	NSLog(@"requestdepth: %d\n", requestdepth);
	
	if( requestdepth == 2 )
	{
		[pluginWindow setInput:lastrequest];
		[pluginWindow displayLookup];
	}
	else if( requestdepth >= 2 )
	{
		requestdepth -= 2;
		[pluginWindow->webView goBack];
	}
}

- (void) hitForward:(id)sender
{
	[pluginWindow->webView goForward];
}

- (void) changeMirror:(id)sender
{
	[defaults setObject:[[sender selectedItem] title] forKey:@"MDBG - default mirror"]; [defaults synchronize];
	//[pluginWindow displayLookup];
}

- (void) changeCharacterSystem:(id)sender
{
	[defaults setObject:[NSNumber numberWithInt:[[sender selectedItem] tag]] forKey:@"MDBG - default character system"]; [defaults synchronize];
	[pluginWindow displayLookup];
}

- (void) changeResultStyle:(id)sender
{
	[defaults setObject:[NSNumber numberWithInt:[[sender selectedItem] tag]] forKey:@"MDBG - default result style"]; [defaults synchronize];
	[pluginWindow displayLookup];
}

- (void) changePinyinStyle:(id)sender
{
	[defaults setObject:[NSNumber numberWithInt:[[sender selectedCell] tag]] forKey:@"MDBG - default pinyin style"]; [defaults synchronize];
	[pluginWindow displayLookup];
}

- (void) goToMDBG:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.mdbg.net"]];
}

@end