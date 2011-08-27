// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import "WWWJDIC.h"

LAUserDefaults* defaults;

@implementation WWWJDIC

+ (void) initialize { defaults = [[LAUserDefaults alloc] initWithDomain:@"com.aoren.LanguageAid.WWWJDIC"]; }
+ (int) PluginCompatibility { return LAPLUGINCOMPATIBILITY; }
+ (NSString*) Title { return @"Japanese Lookups (WWWJDIC)"; }
+ (NSString*) Author { return @"Aoren Software"; }
+ (NSString*) windowTitle { return @"Jim Breen's WWWJDIC"; }

- (NSArray*) priorities { return [NSArray arrayWithObjects:SELECTEDVALUE, FULLVALUE, INDIVIDUALVALUE, 0L]; }

// In here we are simply grabbing the list of dictionaries and mirrors along with their corresponding default settings.  If they are not available then we call updateSettings which should get those values.
- (bool) setup
{
	dictionaries = [[defaults objectForKey:@"dictionaries"] retain];
	mirrors = [[defaults objectForKey:@"mirrors"] retain];
	
	// Perhaps this is the first time we have run it or we never had net access before
	if( !dictionaries || !mirrors )
	{
		[WWWJDIC updateSettings];
		
		dictionaries = [[defaults objectForKey:@"dictionaries"] retain];
		mirrors = [[defaults objectForKey:@"mirrors"] retain];
		
		if( !dictionaries || !mirrors ){ return false; } // Hmm looks like no net access, can't proceed without the dictionaries and mirror lists.
	}
	
	[dictionary removeAllItems];
	NSEnumerator* dicte = [dictionaries keyEnumerator]; id dictkey;
	while( dictkey = [dicte nextObject] ){ [dictionary addItemWithTitle:dictkey]; }
	
	[mirror removeAllItems];
	NSEnumerator* mirre = [mirrors keyEnumerator]; id mirrkey;
	while( mirrkey = [mirre nextObject] ){ [mirror addItemWithTitle:mirrkey]; }
	
	NSString* ddict = [defaults objectForKey:@"default dictionary"];
	
	if( ddict )
	{
		if( [dictionaries objectForKey:ddict] )
		{
			[dictionary selectItemWithTitle:ddict];
		}
		else
		{
			[dictionary selectItemWithTitle:@"Special Text-glossing"];
			[defaults setObject:@"Special Text-glossing" forKey:@"default dictionary"];
			[defaults synchronize];
		}
	}
	else
	{
		[dictionary selectItemWithTitle:@"Special Text-glossing"];
		[defaults setObject:@"Special Text-glossing" forKey:@"default dictionary"];
		[defaults synchronize];
	}
	
	NSString* dmirror = [defaults objectForKey:@"default mirror"];
	
	if( dmirror )
	{
		if( [mirrors objectForKey:dmirror] )
		{
			[mirror selectItemWithTitle:dmirror];
		}
		else
		{
			[mirror selectItemWithTitle:@"Monash University"];
			[defaults setObject:@"Monash University" forKey:@"default mirror"];
			[defaults synchronize];
		}
	}
	else
	{
		[mirror selectItemWithTitle:@"Monash University"];
		[defaults setObject:@"Monash University" forKey:@"default mirror"];
		[defaults synchronize];
	}
	
	return true;
}

#pragma mark IB Callbacks

// Interface Builder callback for the dictionary popup selector
- (void) changeDictionary:(id)sender
{
	[defaults setObject:[[sender selectedItem] title] forKey:@"default dictionary"]; [defaults synchronize];
	
	[pluginWindow displayLookup];
}

// Interface Builder callback for the mirror popup selector
- (void) changeMirror:(id)sender
{
	[defaults setObject:[[sender selectedItem] title] forKey:@"default mirror"]; [defaults synchronize];
}

#pragma mark Prefs and Config

// This function grabs the latest lists of mirrors and dictionaries
+ (void) updateSettings
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	// Get the mirrors from Aoren Software (because the URLs on the lookup pages are not always uniform and automatically parseable I have decided to manually maintain a mirrors list)
	NSDictionary* themirrors = [NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:@"http://www.aorensoftware.com/LanguageAid/Plugins/WWWJDIC/wwwjdicmirrors.plist"]];
	if( themirrors )
	{
		[defaults setObject:themirrors forKey:@"mirrors"];
	}
	else if( ![defaults objectForKey:@"mirrors"] )
	{
		// If we can't get the mirrors list and we have never before gotten them, just default to the main mirror 
		NSMutableDictionary* themirrorsDefault = [NSMutableDictionary dictionary];
		[themirrorsDefault setObject:@"http://www.csse.monash.edu.au/~jwb/cgi-bin/wwwjdic.cgi?9U" forKey:@"Monash University"];
		[defaults setObject:themirrorsDefault forKey:@"mirrors"];
	}
		
	// Get the dictionaries from Monash University
	NSError* err;

	NSXMLDocument* doc = [[NSXMLDocument alloc] initWithContentsOfURL:[NSURL URLWithString:@"http://www.csse.monash.edu.au/~jwb/cgi-bin/wwwjdic.cgi?9T"] options:NSXMLDocumentTidyHTML error:&err];
	
	if( doc )
	{
		NSArray* tags = [doc nodesForXPath:@"//select/option" error:&err];
		
		if( [tags count] )
		{
			NSMutableDictionary* thedictionaries = [NSMutableDictionary dictionary];
			
			int i;
			for( i = 0; i < [tags count]; i++ )
			{
				NSXMLNode* dict = [tags objectAtIndex:i];
				
				if( ![thedictionaries objectForKey:[dict stringValue]] )
				{
					[thedictionaries setObject:[[[dict nodesForXPath:@"@value" error:&err] objectAtIndex:0] stringValue] forKey:[dict stringValue]];
				}
			}
			
			[defaults setObject:thedictionaries forKey:@"dictionaries"];
		}
		
		[defaults synchronize];
	}
	
	[pool release];
}

#pragma mark LAWebService

- (NSURLRequest*) createQueryFull:(NSString*)fullValue selected:(NSString*)selectedValue individual:(NSString*)individualValue preferred:(NSString*)preferredValue
{
	// Try again to get the list of dictionaries and mirrors just in case we got net connectivity back
	if( !dictionaries || !mirrors )
	{
		[WWWJDIC updateSettings];
		
		dictionaries = [[defaults objectForKey:@"dictionaries"] retain];
		mirrors = [[defaults objectForKey:@"mirrors"] retain];
		
		if( !dictionaries || !mirrors ){ return false; }
	}

	// Build the POST query
	NSMutableString* POSTquery = [NSMutableString string];
	
	// Here we append which dictionary we are going to do the lookup into
	[POSTquery appendFormat:@"dicsel=%@&glleng=60", [dictionaries objectForKey:[[dictionary selectedItem] title]]];
	
	// Here we append what we are actually going to query.  
	[POSTquery appendFormat:@"&gloss_line=%@", preferredValue];
	
	// Convert the query data into Japanese EUC
	NSData* POSTdata = [POSTquery dataUsingEncoding:NSJapaneseEUCStringEncoding allowLossyConversion:YES];
	
	// Setup the URL request
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[mirrors objectForKey:[[mirror selectedItem] title]]]];
	[request setHTTPMethod: @"POST"];
	[request setHTTPBody:POSTdata];
	
	return request;
}

- (NSString*) filterResult:(NSData*)result
{
	// Filter out the HTML we don't want to display
	NSMutableString* filter = [[NSMutableString alloc] initWithBytes:[result bytes] length:[result length] encoding:[pluginWindow responseEncoding]];
	
	if( filter )
	{
		NSRange axe;
	
		// Here we punch out a section of HTML that we don't want based on unique keywords that we find
		NSRange ran = [filter rangeOfString:@"Key or paste"];
		NSRange ran2 = [filter rangeOfString:@"</BODY>"];
		if( (ran.location == NSNotFound) || (ran2.location == NSNotFound) ){ return filter; }
		
		if( ran2.location >= ran.location )
		{
			axe = NSMakeRange( ran.location, ran2.location - ran.location );
			[filter deleteCharactersInRange:axe];
		}
		
		// And here we punch out another section
		ran = [filter rangeOfString:@"<BODY"];
		ran2 = [filter rangeOfString:@"METHOD=\"POST\" >\n<br>"];
		if( (ran.location == NSNotFound) || (ran2.location == NSNotFound) ){ return filter; }
		
		if( ran2.location >= ran.location )
		{
			axe = NSMakeRange( ran.location, ran2.location - ran.location + ran2.length );
			[filter deleteCharactersInRange:axe];
		}
		
		return filter;
	}

	return 0L;
}

@end