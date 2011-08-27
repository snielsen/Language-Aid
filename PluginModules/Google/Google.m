// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import "Google.h"

@implementation Google

+ (int) PluginCompatibility { return LAPLUGINCOMPATIBILITY; }
+ (NSString*) Title { return @"Google Search"; }
+ (NSString*) Author { return @"Aoren Software"; }
+ (NSString*) windowTitle { return @"Google"; }

- (BOOL) filterLoad:(NSURL*)loadingURL { return NO; }

- (NSArray*) priorities { return [NSArray arrayWithObjects:SELECTEDVALUE, FULLVALUE, INDIVIDUALVALUE, 0L]; }

- (bool) setup
{	
	// This sets the default language to the current user's language
	usersLanguage = [[[[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"] objectAtIndex:0] substringWithRange:NSMakeRange(0,2)];

	if( !usersLanguage ){ usersLanguage = @"en"; }
	
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

#pragma mark LAWebService

- (NSURLRequest*) createQueryFull:(NSString*)fullValue selected:(NSString*)selectedValue individual:(NSString*)individualValue preferred:(NSString*)preferredValue
{
	NSMutableString* query = [NSMutableString string];
	
	[query appendFormat:@"http://www.google.com/search?client=pub-4111429741106355&rls=%@&ie=UTF-8&oe=UTF-8", usersLanguage];
	[query appendFormat:@"&q=%@", preferredValue];
	
	query = [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	// Setup the URL request
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:query]]; // Whatever your URL is, this is simply a test one
	//[request setHTTPBody:data];
	
	return request;
}

- (NSString*) filterResult:(NSData*)result
{
	NSMutableString* tobefiltered = [[NSMutableString alloc] initWithBytes:[result bytes] length:[result length] encoding:[pluginWindow responseEncoding]];
	
	if( tobefiltered )
	{
		return tobefiltered;
	}

	return NULL;
}

@end