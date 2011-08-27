// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import "IMDB.h"

@implementation IMDB

+ (int) PluginCompatibility { return LAPLUGINCOMPATIBILITY; }
+ (NSString*) Title { return @"IMDB"; }
+ (NSString*) Author { return @"Aoren Software"; }
+ (NSString*) windowTitle { return @"IMDB"; }

- (bool) setup
{
	// Kind of like init.  Optional.  Do all your init-like setup here and return true or false if not successful. 
	// Called only upon load into the actual Language Aid process.
	// If false is returned then the load of the module is aborted.	
	// Plugins are run from both within Language Aid (com.aoren.LanguageAid) and within the pref pane (com.apple.systempreferences) and so when saving settings be sure that you know where you are saving them.
	// One thing you can do is explicitly share Language Aid's defaults domain by prepending your keys like this: [[NSUserDefaults standardUserDefaults] setObject:someobject forKey:@"IMDB - somekey" inDomain:@"com.aoren.LanguageAid"] or you can pick your own.
	
	return true;
}

#pragma mark IB Callbacks

- (void) hitBack:(id)sender
{
	[pluginWindow->webView goBack];
}

- (void) hitForward:(id)sender
{
	[pluginWindow->webView goForward];
}

#pragma mark Prefs and Config

+ (void) updateSettings
{
	// Optional section called when the module is loaded into the PrefPane.  
	// This is an appropriate place to query lists of mirrors or other settings/prefs that should only be changed once in a while.
	// This method is called in it's own thread and so if you chose to implement it be sure to create and release an NSAutoreleasePool for it.
	// Plugins are run from both within Language Aid (com.aoren.LanguageAid) and within the pref pane (com.apple.systempreferences) and so when saving settings be sure that you know where you are saving them.
	// One thing you can do is explicitly share Language Aid's defaults domain by prepending your keys like this: [[NSUserDefaults standardUserDefaults] setObject:someobject forKey:@"IMDB - somekey" inDomain:@"com.aoren.LanguageAid"] or you can pick your own.
}

#pragma mark LAWebService

// Every time this module's lookup trigger is hit, Language Aid will call this method.  
// Language Aid passes you at least one and up to three forms of the text it grabbed in the variables:
//
//       fullValue - the biggest text chunk that the cursor is hovering over
//   selectedValue - the currently selected text (if possible, could be NULL, be sure to check)
// individualValue - if the text is short enough it gets put in here as well or sometimes it is the individual word that the cursor is hovering over (if possible, could be NULL, be sure to check)
//
// Using those passed values you are to create a valid NSURLRequest which you then return to Language Aid.  
// Language Aid will then perform your request and call your class's filterResult: method below when it is done.
// You may return NULL if you wish and an appropriate error message will be displayed.

- (NSURLRequest*) createQueryFull:(NSString*)fullValue selected:(NSString*)selectedValue individual:(NSString*)individualValue
{
	NSMutableString* query = [NSMutableString string];
	
	// Build the query here using one of the passed variables
	
		 if( individualValue ){ [query appendFormat:@"http://www.imdb.com/find?s=all&q=%@", individualValue]; }
	else if(   selectedValue ){ [query appendFormat:@"http://www.imdb.com/find?s=all&q=%@",   selectedValue]; }
	else if(       fullValue ){ [query appendFormat:@"http://www.imdb.com/find?s=all&q=%@",       fullValue]; }
	
	query = [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	// Setup the URL request
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:query]]; // Whatever your URL is, this is simply a test one
	//[request setHTTPBody:data];
	
	return request;
}

// Once an NSURLRequest has been performed this method is called and passed the results in the variable "result".
// From that data you are to create an NSString containing HTML which will be subsequently displayed by the floating panel. 
// This is where you could do any filtering of results or special formatting.
// You may return NULL if you wish and an appropriate error message will be displayed.

- (NSString*) filterResult:(NSData*)result
{
	// Filter out the HTML we don't want to display
	NSMutableString* tobefiltered = [[NSMutableString alloc] initWithBytes:[result bytes] length:[result length] encoding:NSUTF8StringEncoding];
	
	if( tobefiltered )
	{
		NSRange ran;
		NSRange ran2;
		NSRange axe;
		
		while( 1 )
		{
			ran = [tobefiltered rangeOfString:@"<iframe"];
			ran2 = [tobefiltered rangeOfString:@"</iframe>"]; ran2.location += [@"</iframe>" length];
			if( (ran.location == NSNotFound) || (ran2.location == NSNotFound) ){ break; }
			
			if( ran2.location >= ran.location )
			{
				axe = NSMakeRange( ran.location, ran2.location - ran.location );
				[tobefiltered deleteCharactersInRange:axe];
			}
		}
		
		
		ran = [tobefiltered rangeOfString:@"<!-- sid"];
		ran2 = [tobefiltered rangeOfString:@"<table border=\"0\""];
		if( (ran.location == NSNotFound) || (ran2.location == NSNotFound) ){ return tobefiltered; }
		
		if( ran2.location >= ran.location )
		{
			axe = NSMakeRange( ran.location, ran2.location - ran.location );
			[tobefiltered deleteCharactersInRange:axe];
		}
		
		
		ran = [tobefiltered rangeOfString:@"<div id=\"footer\""];
		ran2 = [tobefiltered rangeOfString:@"</p>\n</div>"];
		if( (ran.location == NSNotFound) || (ran2.location == NSNotFound) ){ return tobefiltered; }
		
		if( ran2.location >= ran.location )
		{
			axe = NSMakeRange( ran.location, ran2.location - ran.location + ran2.length );
			[tobefiltered deleteCharactersInRange:axe];
		}
		
		return tobefiltered;
	}

	return NULL;
}

@end