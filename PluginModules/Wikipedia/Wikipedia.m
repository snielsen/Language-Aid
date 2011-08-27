// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import "Wikipedia.h"

LAUserDefaults* defaults;

@implementation Wikipedia

+ (void) initialize { defaults = [[LAUserDefaults alloc] initWithDomain:@"com.aoren.LanguageAid.Wikipedia"]; }
+ (int) PluginCompatibility { return LAPLUGINCOMPATIBILITY; }
+ (NSString*) Title { return @"Wikipedia"; }
+ (NSString*) Author { return @"Aoren Software"; }
+ (NSString*) windowTitle { return @"Wikipedia"; }

- (NSArray*) priorities { return [NSArray arrayWithObjects:SELECTEDVALUE, INDIVIDUALVALUE, FULLVALUE, 0L]; }

// In here we are simply grabbing the list of supported languages and the default language settings.  If they are not available then we call updateSettings which should get those values.
- (bool) setup
{
	languages = [[defaults objectForKey:@"languages"] retain];
	
	// Perhaps this is the first time we have run it or we never had net access before
	if( !languages )
	{
		[Wikipedia updateSettings];
		
		languages = [[defaults objectForKey:@"languages"] retain];
		
		if( !languages ){ return false; } // Hmm looks like no net access, can't proceed without the language list.
	}
	
	[language removeAllItems];
	NSEnumerator* lange = [languages keyEnumerator]; id langkey;
	while( langkey = [lange nextObject] ){ [language addItemWithTitle:langkey]; }
	
	NSString* dlang = [defaults objectForKey:@"default language"];
	
	if( dlang && [languages objectForKey:dlang] )
	{
		[language selectItemWithTitle:dlang];
	}
	else
	{
		// This sets the default language to the current user's language
		NSString* usersLanguageAbrv = [[[[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"] objectAtIndex:0] substringWithRange:NSMakeRange(0,2)];
		NSString* usersLanguage = [[languages allKeysForObject:usersLanguageAbrv] objectAtIndex:0];
	
		if( !usersLanguage ){ usersLanguage = @"English"; }
	
		[language selectItemWithTitle:usersLanguage];
		[defaults setObject:usersLanguage forKey:@"default language"];
		[defaults synchronize];
	}
	
	// Adjust the width of the our UI's NSView
	/*NSRect WF = [pluginWindow frame];
	NSRect UIF = [UI frame];
	
	UIF.size.width = WF.size.width;
	
	[UI setFrame:UIF];*/
	
	return true;
}

#pragma mark Prefs and Config

// This grabs the latest list of languages searchable
+ (void) updateSettings
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

	// Get the languages from the homepage
	NSError* err;

	NSXMLDocument* doc = [[NSXMLDocument alloc] initWithContentsOfURL:[NSURL URLWithString:@"http://www.wikipedia.org/"] options:NSXMLDocumentTidyHTML error:&err];
	
	if( doc )
	{
		NSArray* tags = [doc nodesForXPath:@"//select/option" error:&err];
		
		if( [tags count] )
		{
			NSMutableDictionary* thelanguages = [NSMutableDictionary dictionary];
			
			int i;
			for( i = 0; i < [tags count]; i++ )
			{
				NSXMLNode* dict = [tags objectAtIndex:i];
				
				if( ![thelanguages objectForKey:[dict stringValue]] )
				{
					[thelanguages setObject:[[[dict nodesForXPath:@"@value" error:&err] objectAtIndex:0] stringValue] forKey:[dict stringValue]];
				}
			}
			
			[defaults setObject:thelanguages forKey:@"languages"];
		}
		
		[defaults synchronize];
	}
	
	[pool release];
}

#pragma mark IB Callbacks

// Interface Builder callback for the "Lookup" button
- (void) goAction:(id)sender
{
	if( ![[pluginWindow individualValue] isEqualToString:[searchBox stringValue]] )
	{
		[pluginWindow setInput:[searchBox stringValue]];
		
		[pluginWindow displayLookup];
	}
}

// Interface Builder callback for the language popup selector
- (void) languageChange:(id)sender
{
	[defaults setObject:[[sender selectedItem] title] forKey:@"default language"]; [defaults synchronize];
	
	[pluginWindow displayLookup];
}

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
	
	// Build the URL
	[query appendFormat:@"http://www.wikipedia.org/search-redirect.php?language=%@&go=Go", [languages objectForKey:[[language selectedItem] title]]];
	
	// We construct the query using our preferred value.
	[query appendFormat:@"&search=%@", preferredValue ];

	// Setup the URL request
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	
	return request;
}

- (NSString*) filterResult:(NSData*)result
{
	// Filter out the HTML we don't want to display
	NSMutableString* filter = [[NSMutableString alloc] initWithData:result encoding:[pluginWindow responseEncoding]];
	
	if( filter )
	{
		/*NSRange axe;
	
		// Here we punch out a section of HTML that we don't want based on unique keywords that we find
		NSRange ran = [filter rangeOfString:@"<!-- end content -->"];
		NSRange ran2 = [filter rangeOfString:@"</body>"];
		if( (ran.location == NSNotFound) || (ran2.location == NSNotFound) ){ return filter; }
		
		if( ran2.location >= ran.location )
		{
			axe = NSMakeRange( ran.location, ran2.location - ran.location );
			[filter deleteCharactersInRange:axe];
		}
		
		// And here we punch out another section
		ran = [filter rangeOfString:@"<div id=\"content\">"];
		ran2 = [filter rangeOfString:@"<!-- start content -->"];
		if( (ran.location == NSNotFound) || (ran2.location == NSNotFound) ){ return filter; }
		
		if( ran2.location >= ran.location )
		{
			axe = NSMakeRange( ran.location, ran2.location - ran.location + ran2.length );
			[filter deleteCharactersInRange:axe];
		}

		// And here we insert a bit of formatting to make things look a little nicer
		[filter insertString:@"<div style=\"margin: 2em;\">" atIndex:ran.location];*/

		return filter;
	}

	return 0L;
}

@end