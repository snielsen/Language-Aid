// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import "GoogleTranslate.h"

LAUserDefaults* defaults;

@implementation GoogleTranslate

+ (void) initialize { defaults = [[LAUserDefaults alloc] initWithDomain:@"com.aoren.LanguageAid.GoogleTranslate"]; }
+ (int) PluginCompatibility { return LAPLUGINCOMPATIBILITY; }
+ (NSString*) Title { return @"Translations (Google Translate)"; }
+ (NSString*) Author { return @"Aoren Software"; }
+ (NSString*) windowTitle { return @"Google Translate"; }

- (NSArray*) priorities { return [NSArray arrayWithObjects:SELECTEDVALUE, FULLVALUE, INDIVIDUALVALUE, 0L]; }

- (bool) setup
{
	fromLanguages = [[defaults objectForKey:@"fromLanguages"] retain];
	toLanguages   = [[defaults objectForKey:@"toLanguages"] retain];
	
	// Perhaps this is the first time we have run it or we never had net access before
	if( !fromLanguages || !toLanguages )
	{
		[GoogleTranslate updateSettings];
		
		fromLanguages = [[defaults objectForKey:@"fromLanguages"] retain];
		toLanguages   = [[defaults objectForKey:@"toLanguages"] retain];
		
		if( !fromLanguages || !toLanguages ){ return false; }
	}
	
	[fromLanguage removeAllItems];
	NSEnumerator* frome = [fromLanguages keyEnumerator]; id fromkey;
	while( fromkey = [frome nextObject] ){ [fromLanguage addItemWithTitle:fromkey]; }
	
	[toLanguage removeAllItems];
	NSEnumerator* toe = [toLanguages keyEnumerator]; id tokey;
	while( tokey = [toe nextObject] ){ [toLanguage addItemWithTitle:tokey]; }
	
	NSString* dfrom = [defaults objectForKey:@"default fromLanguage"];
	
	if( dfrom )
	{
		if( [fromLanguages objectForKey:dfrom] )
		{
			[fromLanguage selectItemWithTitle:dfrom];
		}
		else
		{
			[fromLanguage selectItemWithTitle:@"Detect language"];
			[defaults setObject:@"Detect language" forKey:@"default fromLanguage"];
			[defaults synchronize];
		}
	}
	else
	{
		[fromLanguage selectItemWithTitle:@"Detect language"];
		[defaults setObject:@"Detect language" forKey:@"default fromLanguage"];
		[defaults synchronize];
	}
	
	NSString* dto = [defaults objectForKey:@"default toLanguage"];
	
	if( dto )
	{
		if( [toLanguages objectForKey:dto] )
		{
			[toLanguage selectItemWithTitle:dto];
		}
		else
		{
			[toLanguage selectItemWithTitle:@"English"];
			[defaults setObject:@"English" forKey:@"default toLanguage"];
			[defaults synchronize];
		}
	}
	else
	{
		[toLanguage selectItemWithTitle:@"English"];
		[defaults setObject:@"English" forKey:@"default toLanguage"];
		[defaults synchronize];
	}
	
	return true;	
}

#pragma mark IB Callbacks

// Interface Builder callback for the source popup selector
- (void) changeFromLanguage:(id)sender
{
	[defaults setObject:[[sender selectedItem] title] forKey:@"default fromLanguage"]; [defaults synchronize];
	[pluginWindow displayLookup];
}

// Interface Builder callback for the translated popup selector
- (void) changeToLanguage:(id)sender
{
	[defaults setObject:[[sender selectedItem] title] forKey:@"default toLanguage"]; [defaults synchronize];
	[pluginWindow displayLookup];
}

#pragma mark Prefs and Config

+ (void) updateSettings
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	NSError* err;
	
	NSXMLDocument* doc = [[NSXMLDocument alloc] initWithContentsOfURL:[NSURL URLWithString:@"http://translate.google.com/translate_t"] options:NSXMLDocumentTidyHTML error:&err];
	
	if( doc )
	{
		NSArray* tags = [doc nodesForXPath:@"//select" error:&err];
		
		if( [tags count] )
		{
			NSMutableDictionary* theFromLanguages = [NSMutableDictionary dictionary];
			NSMutableDictionary* theToLanguages = [NSMutableDictionary dictionary];
			
			bool gotsl = false;
			bool gottl = false;
			
			int i;
			for( i = 0; i < [tags count]; i++ )
			{
				NSXMLNode* select = [tags objectAtIndex:i];
				NSArray* ids = [select nodesForXPath:@"@name" error:&err];
				
				if( [ids count] )
				{
					NSString* s = [[ids objectAtIndex:0] stringValue];
					
					if( [s isEqualToString:@"sl"] && !gotsl )
					{
						NSArray* langs = [select nodesForXPath:@"option" error:&err];
						
						int j;
						for( j = 0; j < [langs count]; j++ )
						{
							NSXMLNode* lang = [langs objectAtIndex:j];
							
							[theFromLanguages setObject:[[[lang nodesForXPath:@"@value" error:&err] objectAtIndex:0] stringValue] forKey:[lang stringValue]];
						}
						
						gotsl = true;
					}
					else if( [s isEqualToString:@"tl"] && !gottl )
					{
						NSArray* langs = [select nodesForXPath:@"option" error:&err];
						
						int j;
						for( j = 0; j < [langs count]; j++ )
						{
							NSXMLNode* lang = [langs objectAtIndex:j];
							
							[theToLanguages setObject:[[[lang nodesForXPath:@"@value" error:&err] objectAtIndex:0] stringValue] forKey:[lang stringValue]];
						}
						
						gottl = true;
					}
				}
			}
			
			[defaults setObject:theFromLanguages forKey:@"fromLanguages"];
			[defaults setObject:theToLanguages forKey:@"toLanguages"];
		}
		
		[defaults synchronize];
	}
	
	[pool release];
}

#pragma mark LAWebService

- (NSURLRequest*) createQueryFull:(NSString*)fullValue selected:(NSString*)selectedValue individual:(NSString*)individualValue preferred:(NSString*)preferredValue
{
	// Try again to get the list of dictionaries and mirrors just in case we got net connectivity back
	if( !fromLanguages || !toLanguages )
	{
		[GoogleTranslate updateSettings];
		
		fromLanguages = [[defaults objectForKey:@"fromLanguages"] retain];
		toLanguages = [[defaults objectForKey:@"toLanguages"] retain];
		
		if( !fromLanguages || !toLanguages ){ return false; }
	}
	
	NSMutableString* query = [NSMutableString string];
	
 	[query appendFormat:@"http://translate.google.com/translate_t?hl=en&ie=UTF8&langpair=%@|%@", [fromLanguages objectForKey:[[fromLanguage selectedItem] title]], [toLanguages objectForKey:[[toLanguage selectedItem] title]]];

	NSMutableString* POSTquery = [NSMutableString string];
	[POSTquery appendFormat:@"&text=%@", preferredValue];
	
	NSData* POSTdata = [POSTquery dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
	
	// Setup the URL request
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	[request setHTTPMethod: @"POST"];
	[request setHTTPBody:POSTdata];
	
	return request;
}

- (NSString*) filterResult:(NSData*)result
{
	NSMutableString* tobefiltered = [[NSMutableString alloc] initWithData:result encoding:[pluginWindow responseEncoding]];
	
	//return tobefiltered;
	
	if( tobefiltered )
	{
		NSError* err;
		
		NSXMLDocument* doc = [[NSXMLDocument alloc] initWithXMLString:tobefiltered options:NSXMLDocumentTidyHTML error:&err];
		
		if( doc )
		{
			NSString*	source = nil;
			NSString*	trans = nil;
			NSString*	orgMsg = nil;
			NSString*	transMsg = nil;
			
			NSArray* tags = [doc nodesForXPath:@"//textarea" error:&err];
			
			if( [tags count] )
			{
				int i;
				for( i = 0; i < [tags count]; i++ )
				{
					NSXMLNode* dict = [tags objectAtIndex:i];
					NSArray* ids = [dict nodesForXPath:@"@name" error:&err];
					
					if( [ids count] )
					{
						NSString* s = [[ids objectAtIndex:0] stringValue];
						
						if( [s isEqualToString:@"text"] )
						{
							source = [[dict stringValue] retain];
						}
					}
				}
			}
			
			tags = [doc nodesForXPath:@"//span" error:&err];
			
			if( [tags count] )
			{
				int i;
				for( i = 0; i < [tags count]; i++ )
				{
					NSXMLNode* dict = [tags objectAtIndex:i];
					NSArray* ids = [dict nodesForXPath:@"@id" error:&err];
					
					if( [ids count] )
					{
						NSString* s = [[ids objectAtIndex:0] stringValue];
						
						if( [s isEqualToString:@"result_box"] )
						{
							trans = [[dict stringValue] retain];
						}
					}
				}
			}
			
//			tags = [doc nodesForXPath:@"//td" error:&err];
//			
//			if( [tags count] )
//			{
//				int i;
//				for( i = 0; i < [tags count]; i++ )
//				{
//					NSXMLNode* dict = [tags objectAtIndex:i];
//					NSArray* ids = [dict nodesForXPath:@"@id" error:&err];
//					
//					if( [ids count] )
//					{
//						NSString* s = [[ids objectAtIndex:0] stringValue];
//						
//						if( [s isEqualToString:@"original_text"] )
//						{
//							orgMsg = [[dict stringValue] retain];
//						}
//						else if( [s isEqualToString:@"autotrans"] )
//						{
//							transMsg = [[dict stringValue] retain];
//						}
//					}
//				}
//			}
			
//			NSString* val = [[NSString alloc] initWithFormat:@"<table width=100%@><tr><td>%@</td><td>%@</td></tr><tr><td width=50%@>%@</td><td width=50%@>%@</td></tr></table>", @"%", orgMsg, transMsg, @"%", source, @"%", trans];
			NSString* val = [[NSString alloc] initWithFormat:@"<table width=100%@><tr><td width=50%@>%@</td><td width=50%@>%@</td></tr></table>", @"%", @"%", source, @"%", trans];
			
			[source release];
			[trans release];
			
			return val;
		}
	}
	
	return NULL;
}

@end