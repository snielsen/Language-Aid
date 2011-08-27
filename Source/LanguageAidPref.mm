// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import "LanguageAidPref.h"

#import "LAPlugin.h"

//#import "registration.h"
#import "Encoding.h"
#import "GetPID.h"

#import <netdb.h>
#import <unistd.h>

bool firsteverload = false;
bool initdonce = false;

NSString*				justEnabled = 0L;

NSMutableArray*			newModulesArray = [[NSMutableArray alloc] init];
NSBundle*				myBundle = [NSBundle bundleForClass:[LanguageAidPref class]];
NSString*				registrationKey = 0L;
unsigned int			PPHeight = 400;

static pascal void checkProcessStatus( EventLoopTimerRef inTimer, void* userData ){ [(LanguageAidPref*)userData queryRunning]; }

/*extern "C"
{
	typedef struct OpaqueLSSharedFileListRef*  LSSharedFileListRef;
	typedef struct OpaqueLSSharedFileListItemRef*  LSSharedFileListItemRef;

	extern CFStringRef kLSSharedFileListSessionLoginItems __attribute__((weak_import));
	extern LSSharedFileListItemRef kLSSharedFileListItemLast __attribute__((weak_import));
	extern CFArrayRef LSSharedFileListCopySnapshot( LSSharedFileListRef, UInt32* ) __attribute__((weak_import));
	extern OSStatus LSSharedFileListItemResolve( LSSharedFileListItemRef, UInt32, CFURLRef*, FSRef* ) __attribute__((weak_import));
	extern OSStatus LSSharedFileListItemRemove( LSSharedFileListRef, LSSharedFileListItemRef) __attribute__((weak_import));
	
	extern LSSharedFileListRef LSSharedFileListCreate( CFAllocatorRef, CFStringRef, CFTypeRef ) __attribute__((weak_import));
	extern LSSharedFileListItemRef LSSharedFileListInsertItemURL( LSSharedFileListRef, LSSharedFileListItemRef, CFStringRef, IconRef, CFURLRef, CFDictionaryRef, CFArrayRef ) __attribute__((weak_import));
}*/

@implementation LanguageAidPref

#pragma mark Other

- (void) resizeTrigger
{
	NSTableColumn* tableColumn = [pluginModules tableColumnWithIdentifier:@"Trigger"];
	NSTableColumn* nameColumn = [pluginModules tableColumnWithIdentifier:@"Name"];
	//NSTableColumn* authorColumn = [pluginModules tableColumnWithIdentifier:@"Author"];
	
	float width = [[tableColumn headerCell] cellSize].width;

	NSCell* daCell = [tableColumn dataCell];
	
	[LAPluginsLock lock];
	
		for( int i = 0; i < [loadedLAPlugins count]; i++ )
		{
			LAPluginReference* PMR = ((LAPluginReference*)[loadedLAPlugins objectAtIndex:i]);

			NSMutableString* tString = [NSMutableString string];
			
			NSDictionary* thisModulesTriggers = [Triggers objectForKey:PMR->name];
			
			if( thisModulesTriggers )
			{
				NSString* type = [thisModulesTriggers objectForKey:@"actiontype"];
				
				id val = 0L;
	
				val = [thisModulesTriggers objectForKey:@"command"]; if( val && [val intValue] ){ [tString appendString:[NSString stringWithCString:"⌘" encoding:NSUTF8StringEncoding]]; }
				val = [thisModulesTriggers objectForKey:@"shift"];   if( val && [val intValue] ){ [tString appendString:[NSString stringWithCString:"⇧" encoding:NSUTF8StringEncoding]]; }
				val = [thisModulesTriggers objectForKey:@"option"];  if( val && [val intValue] ){ [tString appendString:[NSString stringWithCString:"⌥" encoding:NSUTF8StringEncoding]]; }
				val = [thisModulesTriggers objectForKey:@"control"]; if( val && [val intValue] ){ [tString appendString:[NSString stringWithCString:"⌃" encoding:NSUTF8StringEncoding]]; }
						
					 if( [type isEqualToString:@"Mouse Click"]  ){ [tString appendString:[self mouseToMouseLocalized:[thisModulesTriggers objectForKey:@"mouseclick"]]];  }
				else if( [type isEqualToString:@"Function Key"] ){ [tString appendString:[thisModulesTriggers objectForKey:@"functionkey"]]; }
			}
			else
			{
				//[tString appendString:DEFAULTKEYTRIGGER];
				[tString appendString:NSLocalizedStringFromTableInBundle(@"NOTSET", 0L, myBundle, 0L)];
			}
			
			[daCell setStringValue:tString];
			float tmp = [daCell cellSize].width;
			width = (tmp > width)? tmp : width;
		}
		
	[LAPluginsLock unlock];

	width += 5.0;

	//[tableColumn setMinWidth:width];
	[tableColumn setWidth:width];

	
	float tWidth = 539;
	float cWidth = 0;
	
	NSArray* cols = [pluginModules tableColumns];

	for( int j = 0; j < [cols count]; j++ )
	{
		NSTableColumn* TC = [cols objectAtIndex:j];
		cWidth += [TC width];
	}
	
	//printf("%f %f\n", tWidth, cWidth );
	
	if( cWidth > tWidth )
	{
		[nameColumn setWidth:[nameColumn width] - (cWidth - tWidth)];
	}
	else
	{
		[nameColumn setWidth:[nameColumn width] + (tWidth - cWidth)];
	}

	/*NSTableColumn* tableColumn = [pluginModules tableColumnWithIdentifier:@"Trigger"];
	
	float width = [[tableColumn headerCell] cellSize].width;
	
	[LAPluginsLock lock];
		int nrows = [loadedLAPlugins count];
		int i = 0;
		
		while( i < nrows )
		{
			NSCell* daCell = [tableColumn dataCellForRow:i];
			float tmp = [daCell cellSize].width;
			width = (tmp > width)? tmp : width;
			i++;
		}
	[LAPluginsLock unlock];
	
	width += 5.0;

	// Set the table column width
	[tableColumn setMinWidth:width];
	[tableColumn setWidth:width];*/
}

- (NSString*) mouseToMouseLocalized:(NSString*)m
{
	NSMutableString* m2 = [NSMutableString stringWithString:NSLocalizedStringFromTableInBundle(@"MOUSE", 0L, myBundle, 0L)];
		 if( [m isEqualToString:@"Mouse Button 1"] ){ [m2 appendString:@" 1"]; }
	else if( [m isEqualToString:@"Mouse Button 2"] ){ [m2 appendString:@" 2"]; }
	else if( [m isEqualToString:@"Mouse Button 3"] ){ [m2 appendString:@" 3"]; }
	else if( [m isEqualToString:@"Mouse Button 4"] ){ [m2 appendString:@" 4"]; }
	else if( [m isEqualToString:@"Mouse Button 5"] ){ [m2 appendString:@" 5"]; }
	
	return m2;
}

- (NSString*) popUpTagMouse:(id)sender
{
	NSString* whichbutton = 0L;
		 if( [sender indexOfItemWithTag:1] == [sender indexOfSelectedItem] ){ whichbutton = @"Mouse Button 1"; }
	else if( [sender indexOfItemWithTag:2] == [sender indexOfSelectedItem] ){ whichbutton = @"Mouse Button 2"; }
	else if( [sender indexOfItemWithTag:3] == [sender indexOfSelectedItem] ){ whichbutton = @"Mouse Button 3"; }
	else if( [sender indexOfItemWithTag:4] == [sender indexOfSelectedItem] ){ whichbutton = @"Mouse Button 4"; }
	else if( [sender indexOfItemWithTag:5] == [sender indexOfSelectedItem] ){ whichbutton = @"Mouse Button 5"; }
	
	//NSLog(@"whichbutton: %@\n", whichbutton);
	
	return whichbutton;
}

- (NSString*) tagToMouse:(int)tag
{
	NSString* whichbutton = 0L;
		 if( tag == 1 ){ whichbutton = @"Mouse Button 1"; }
	else if( tag == 2 ){ whichbutton = @"Mouse Button 2"; }
	else if( tag == 3 ){ whichbutton = @"Mouse Button 3"; }
	else if( tag == 4 ){ whichbutton = @"Mouse Button 4"; }
	else if( tag == 5 ){ whichbutton = @"Mouse Button 5"; }
	
	return whichbutton;
}

- (int) mouseToTag:(NSString*)m
{
	int mousebutton = 0;
					
		 if( [m isEqualToString:@"Mouse Button 1"] ){ mousebutton = 1; }
	else if( [m isEqualToString:@"Mouse Button 2"] ){ mousebutton = 2; }
	else if( [m isEqualToString:@"Mouse Button 3"] ){ mousebutton = 3; }
	else if( [m isEqualToString:@"Mouse Button 4"] ){ mousebutton = 4; }
	else if( [m isEqualToString:@"Mouse Button 5"] ){ mousebutton = 5; }
	
	return mousebutton;
}

- (void) actionChange:(NSNumber*)num
{
	[actiontype selectCellWithTag:[num intValue]];
}

- (bool) settingsAreDuped:(NSDictionary*)justChanged
{
	int i = 0;
	// Run through all the Trigger sets
	NSEnumerator* denumerator = [Triggers objectEnumerator]; NSDictionary* dvalue;
	while( dvalue = [denumerator nextObject] )
	{
		//NSLog(@"%X VS %X\n", justChanged, dvalue );
		
		// Make sure that is it not the exact trigger that we are comparing against
		if( dvalue != justChanged )
		{
			// Then make sure that the module is there
			NSString* daKey = [[Triggers allKeysForObject:dvalue] objectAtIndex:0];
			
			if( isPluginThere( daKey ) )
			{
				// Now check all the trigger options
				if( [[dvalue objectForKey:@"actiontype"] isEqualToString:[justChanged objectForKey:@"actiontype"]] )
				{
					if( [[dvalue objectForKey:@"command"] isEqualToNumber:[justChanged objectForKey:@"command"]] )
					{
						if( [[dvalue objectForKey:@"shift"] isEqualToNumber:[justChanged objectForKey:@"shift"]] )
						{
							if( [[dvalue objectForKey:@"option"] isEqualToNumber:[justChanged objectForKey:@"option"]] )
							{
								if( [[dvalue objectForKey:@"control"] isEqualToNumber:[justChanged objectForKey:@"control"]] )
								{
									if( [[dvalue objectForKey:@"actiontype"] isEqualToString:@"Function Key"] )
									{
										if( [[dvalue objectForKey:@"functionkey"] isEqualToString:[justChanged objectForKey:@"functionkey"]] )
										{
											//NSLog(@"%X - %@\nVS\n%X - %@\n", justChanged, [justChanged description], dvalue, [dvalue description] );
											
											return true;
										}
									}
									else if( [[dvalue objectForKey:@"actiontype"] isEqualToString:@"Mouse Click"] )
									{
										if( [[dvalue objectForKey:@"mouseclick"] isEqualToString:[justChanged objectForKey:@"mouseclick"]] )
										{
											//NSLog(@"%X - %@\nVS\n%X - %@\n", justChanged, [justChanged description], dvalue, [dvalue description] );
											
											return true;
										}
									}
								}
							}
						}
					}
				}
			}
		}
		
		i++;
	}
	
	return false;
}

- (void) enableTrigger
{
	[command setEnabled:YES];
	[shift setEnabled:YES];
	[option setEnabled:YES];
	[control setEnabled:YES];
	
	[key setEnabled:YES];
	[mouse setEnabled:YES];
	[actiontype setEnabled:YES];
	
	[fadeAwayButton setEnabled:YES];
	[fadeAwaySeconds setEnabled:YES];
}

- (void) disableTrigger
{
	[command setEnabled:NO];
	[shift setEnabled:NO];
	[option setEnabled:NO];
	[control setEnabled:NO];
	
	[key setEnabled:NO];
	[mouse setEnabled:NO];
	[actiontype setEnabled:NO];
	
	[fadeAwayButton setEnabled:NO];
	[fadeAwaySeconds setEnabled:NO];
	
	[key selectItemWithTitle:DEFAULTKEYTRIGGER];
	[mouse selectItemWithTag:3];
	[command setState:NSOffState];
	[shift setState:NSOffState];
	[option setState:NSOffState];
	[control setState:NSOffState];
	[fadeAwayButton setState:NSOffState];
	[fadeAwaySeconds setIntValue:60];
	[actiontype selectCellWithTag:0];
}

- (void) queryRunning
{
	int result = GetPIDForProcessName("Language Aid");
	//printf("result: %d\n", result);
	if( result == -1 )
	{
		[self setNotRunning];
	}
	else
	{
		if( shuttingDown == true )
		{
			char killcommand[64]; sprintf( killcommand, "kill %d", result );
			system(killcommand);
		}
		else
		{
			[self setRunning];
		}
	}
	
	shuttingDown = false;
}

- (void) pushDefaults
{	
	if( currentPlugin )
	{
		[Triggers setObject:currentPluginDictionary forKey:currentPlugin->name];
		[defaults setObject:Triggers forKey:@"Triggers"];
	}
	
	[defaults synchronize];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"defaultsChanged" object:0L userInfo:0L deliverImmediately:YES];
}

- (bool) getLogin
{
	// The way to do it in 10.5
	/*if( LSSharedFileListCreate )
	{
		LSSharedFileListRef loginItems = LSSharedFileListCreate( NULL, kLSSharedFileListSessionLoginItems, NULL );
		CFURLRef thePath = (CFURLRef)[NSURL fileURLWithPath:@"/Library/Application Support/Language Aid/Language Aid.app"];
		UInt32 seedValue;
				
		NSArray* loginItemsArray = (NSArray*)LSSharedFileListCopySnapshot( loginItems, &seedValue );
		
		bool gotit = false;
		id item = nil;
		for( int i = 0; i < [loginItemsArray count]; i++ )
		{
			item = [loginItemsArray objectAtIndex:i];
			
			LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)item;
			
			CFURLRef itemPath = nil;

			if( LSSharedFileListItemResolve( itemRef, 0, (CFURLRef*)&itemPath, NULL ) == noErr )
			{
				NSLog(@"GOTPATH: %@\n", [(NSURL*)itemPath path]);
				if( [[(NSURL*)itemPath path] hasPrefix:@"/Library/Application Support/Language Aid/Language Aid.app"] )
				{
					LSSharedFileListItemRemove( loginItems, itemRef ); gotit = true;
				}
			}
		}
		
		[loginItemsArray release];
		CFRelease(loginItems);

		return gotit;
	}*/
	
	NSDictionary* errorDict;
	NSAppleEventDescriptor* returnDescriptor = NULL;

	NSAppleScript* scriptObject = [[NSAppleScript alloc] initWithSource:@"tell application \"System Events\"\nrepeat with the_item in login items \nif path of the_item contains \"/Library/Application Support/Language Aid/Language Aid.app\" then\nreturn true\nend if\nend repeat\nreturn false\nend tell"];

	returnDescriptor = [scriptObject executeAndReturnError:&errorDict];
	[scriptObject release];

	if( returnDescriptor != NULL )
	{
		if( [returnDescriptor booleanValue] ){ return true; }else{ return false; }
	}
	
	// Try it the old way
	NSString* path = [[NSString stringWithString:@"~/Library/Preferences/loginwindow.plist"] stringByExpandingTildeInPath];
	NSMutableDictionary* NSMD = [NSMutableDictionary dictionaryWithContentsOfFile:path];
	NSMutableArray* ALAD = [NSMD objectForKey:@"AutoLaunchedApplicationDictionary"];
	
	int i;
	for( i = 0; i < [ALAD count]; i++ )
	{
		if( [[[ALAD objectAtIndex:i] objectForKey:@"Path"] isEqualToString:@"/Library/Application Support/Language Aid/Language Aid.app"] )
		{
			//NSLog([[ALAD objectAtIndex:i] objectForKey:@"Path"]);
			return true;
		}
	}
	
	return false;
}

- (void) getRegistration
{
	// First look in the user prefs for a registration key
	registrationKey = [defaults objectForKey:@"registration"]; if( registrationKey ){ [registrationKey retain]; }
	
	// Then look in system wide prefs
	if( !registrationKey )
	{
		NSString* path = [NSString stringWithString:@"/Library/Preferences/com.aoren.LanguageAid.plist"];
		NSMutableDictionary* NSMD = [NSMutableDictionary dictionaryWithContentsOfFile:path];
		
		registrationKey = [NSMD objectForKey:@"registration"]; if( registrationKey ){ [registrationKey retain]; }
		
		// If there is then move a copy up to the user prefs
		if( registrationKey )
		{
			[defaults setObject:registrationKey forKey:@"registration"];
			#ifdef SITELICENSED
			[defaults setObject:[NSMD objectForKey:@"RegisteredTo"] forKey:@"RegisteredTo"];
			#endif
			[self pushDefaults];
		}
		// If still not then check if there is a transaction id
		else
		{
			NSString* TID = [defaults objectForKey:@"TID"];
			
			// If there is a transaction ID but no registration key then it should mean that registration failed
			if( TID )
			{
				NSMutableString* Failure = [NSMutableString stringWithString:NSLocalizedStringFromTableInBundle(@"LASTREGISTRATIONFAILED", 0L, myBundle, 0L)];
				[Failure appendString:TID];
				[registrationstatus setTitleWithMnemonic:Failure];
			}
			else
			{
				NSString* oldTID = [defaults objectForKey:@"oldTID"];
			
				// If there is an old transaction ID but no registration key then it should tell the person that they can upgrade their license
				if( oldTID )
				{
					NSMutableString* nUpgrade = [NSMutableString stringWithString:NSLocalizedStringFromTableInBundle(@"NEEDSLICENSEUPGRADE", 0L, myBundle, 0L)];
					[registrationstatus setTitleWithMnemonic:nUpgrade];
					[serial setTitle:NSLocalizedStringFromTableInBundle(@"UPGRADELICENSE", 0L, myBundle, 0L)];
				}
			}
		}
		
		#ifdef SITELICENSED
		if( ![defaults objectForKey:@"RegisteredTo"] )
		{
			[defaults setObject:[NSMD objectForKey:@"RegisteredTo"] forKey:@"RegisteredTo"];
		}
		#endif
	}
	// If we do have a registration key in the user prefs then check to see if there is one in the global prefs
	else
	{
		NSString* path = [NSString stringWithString:@"/Library/Preferences/com.aoren.LanguageAid.plist"];
		NSMutableDictionary* NSMD = [NSMutableDictionary dictionaryWithContentsOfFile:path];
		
		NSString* registrationKeyG = [NSMD objectForKey:@"registration"];
		
		// If there is then check and see if it matches the user prefs one
		if( registrationKeyG )
		{
			// If they are not equal then overite the local one with the global one
			if( ![registrationKeyG isEqualToString:registrationKey] )
			{
				[defaults setObject:registrationKeyG forKey:@"registration"];
				#ifdef SITELICENSED
				[defaults setObject:[NSMD objectForKey:@"RegisteredTo"] forKey:@"RegisteredTo"];
				#endif
				[self pushDefaults];
			}
		}
		
		#ifdef SITELICENSED
		if( ![defaults objectForKey:@"RegisteredTo"] )
		{
			[defaults setObject:[NSMD objectForKey:@"RegisteredTo"] forKey:@"RegisteredTo"];
		}
		#endif
	}
	
	if( registrationKey )
	{
		//NSMutableString* Success = [NSMutableString stringWithString:@"Language Aid is registered. Registration Number: "];
		//[Success appendString:registrationKey];
		#ifdef SITELICENSED
		NSMutableString* Success = [NSMutableString stringWithFormat:@"%@ to %@", NSLocalizedStringFromTableInBundle(@"REGISTERED", 0L, myBundle, 0L), [defaults objectForKey:@"RegisteredTo"]];
		#else
		NSMutableString* Success = [NSMutableString stringWithString:NSLocalizedStringFromTableInBundle(@"REGISTERED", 0L, myBundle, 0L)];
		#endif
		[registrationstatus setTitleWithMnemonic:Success];

		[serial setHidden:YES];
		[supportButton setHidden:NO];
	}
	else
	{
		[serial setHidden:YES];
		
		[supportButton setHidden:YES];
	}
}

- (bool) makeKeyServerRequest:(NSString*)tehRealData txnid:(const char*)tx
{
	for( int numtries = 0; numtries < REGISTRATIONTRIES; numtries++ )
	{
		// Setup the pipe socket
		keySocket = socket( AF_INET, SOCK_STREAM, 0 );
		
		if( keySocket != -1)
		{
			//NSLog( @"key socket: %d created\n", keySocket );
		
			//if( fcntl( pipeSocket, F_SETFL, O_NONBLOCK ) != -1 )
			{
				struct sockaddr_in			pipeAddress;				// Connection to other computer address.
				//struct in_addr				pipeIp;						// Other computer's IP.
		
				//inet_aton( "127.0.0.1", &pipeIp );
				struct hostent* host = gethostbyname( "www.aorensoftware.com" );
				
				if( host )
				{
					struct in_addr **addr_ptr = (struct in_addr **)(host->h_addr_list);
					
					pipeAddress.sin_addr.s_addr = addr_ptr[0]->s_addr;
					//pipeAddress.sin_addr.s_addr = pipeIp.s_addr;
					pipeAddress.sin_port = htons(atoi(PIPEPORT));
					pipeAddress.sin_family = AF_INET;
					memset(&(pipeAddress.sin_zero), '\0', 8);
					
					if( connect( keySocket, (struct sockaddr *)&pipeAddress, sizeof(struct sockaddr) ) != -1 )
					{
						#ifdef DEBUG
						NSLog(@"connected\n");
						#endif
						
						int len = 0;
						
						int identitylength = strlen(tx); identitylength *= -1; // THIS IS TO INDICATE TO THE KEYSERVER THAT THIS IDENTIFIER WAS CREATED BY LAID 1.1 >= (newerScheme)
						// identitylength needs to be correctly endianized.
						identitylength = htonl(identitylength);
						
						len = send( keySocket, &identitylength, sizeof(int), 0 );
						len = send( keySocket, tx, strlen(tx), 0 );
						
						#ifdef DEBUG
						NSLog( @"sent identity: %s\n", tx );
						#endif
						
						
						// Now because we are the new scheme we have to send to TID again if we are normal, and the old one if we are upgrading
						id oldTID = [defaults objectForKey:@"oldTID"];
						if( !oldTID )
						{
							identitylength = strlen(tx);
							// identitylength needs to be correctly endianized.
							identitylength = htonl(identitylength);
							
							len = send( keySocket, &identitylength, sizeof(int), 0 );
							len = send( keySocket, tx, strlen(tx), 0 );
							
							#ifdef DEBUG
							NSLog( @"sent identity2: %s\n", tx );
							#endif
						}
						else
						{
							const char* tx2 = [oldTID cStringUsingEncoding:NSASCIIStringEncoding];
							identitylength = strlen(tx2);
							// identitylength needs to be correctly endianized.
							identitylength = htonl(identitylength);
							
							len = send( keySocket, &identitylength, sizeof(int), 0 );
							len = send( keySocket, tx2, strlen(tx2), 0 );
							
							#ifdef DEBUG
							NSLog( @"sent identity2: %s\n", tx2 );
							#endif
						}
						
						
						unsigned char* identifier = decode_hex( (char*)[tehRealData cStringUsingEncoding:NSASCIIStringEncoding] );
						
						// I can't remember why I am using [tehRealData length]/2 here...but for some reason even though [tehRealData length]/2 == 16 it still sends the complete 32 byte identifier!? It works, I can't remember why..
						// Oh wait, nevermind...the identifier is converted into hex so one byte equals two letters.
						
						//int identifierlength = *((unsigned int*)identifier) + sizeof(unsigned int);
						unsigned int identifierlength = htonl( [tehRealData length]/2 );
						
						// The first 4 bytes(unsigned int) needs to be correctly endianized.
						//unsigned int identlength = htonl(*((unsigned int*)identifier));
						//printf("%d vs %d\n", *((unsigned int*)identifier), identlength );
						//*((unsigned int*)identifier) = identlength;
						
						len = send( keySocket, &identifierlength, sizeof(unsigned int), 0 );
						len = send( keySocket, identifier, [tehRealData length]/2, 0 );
						
						#ifdef DEBUG
						NSLog( @"sent identifier of length %d\n", [tehRealData length]/2 );
						#endif
						
						unsigned int siglength = 0;
						len = recv( keySocket, &siglength, sizeof(unsigned int), MSG_WAITALL );
						siglength = ntohl(siglength);
						switch( siglength )
						{
							// The registration server does not yet have an entry for it
							case( 0 ) :
							{
								//printf("Got siglenth: 0\n");
							} break;
							
							// The server already a different signed identifier for this transaction so fail (Possible attack)
							case( 0xFFFFFFFF ) :
							{
								close(keySocket);
								return false;
							} break;
							
							// We got our identifier signed, yay!
							default :
							{
								unsigned char* sig = (unsigned char*)malloc( siglength );
								len = recv( keySocket, sig, siglength, MSG_WAITALL );
								
								#ifdef DEBUG
								NSLog(@"identifier: %x identifier length: %d got sig of length: %d\n", identifier, identifierlength, len);
								#endif
								
								////int res2 = RSA_verify( NID_md5, identifier + sizeof(unsigned int), identifierlength - sizeof(unsigned int), sig, len, keypair);
								////printf( "key verification: %d\n", res2 );
								
								char* encodedForm = encode_hex( sig, siglength );
								if( registrationKey ){ [registrationKey release]; }
								registrationKey = [[NSString alloc] initWithCString:encodedForm encoding:NSASCIIStringEncoding];
								free( encodedForm );
								
								// If we were upgrading then we must remove the old TID
								if( oldTID )
								{
									[defaults removeObjectForKey:@"oldTID"];
								}
								
								[defaults setObject:registrationKey forKey:@"registration"];
								[self pushDefaults];
								
								[self getRegistration];
								close(keySocket);
								
								
								// Also put a copy of the registration in the system root so other users can use it
								NSString* path = [NSString stringWithString:@"/Library/Preferences/com.aoren.LanguageAid.plist"];
								NSMutableDictionary* NSMD = [NSMutableDictionary dictionaryWithContentsOfFile:path];
								if( !NSMD ){ NSMD = [NSMutableDictionary dictionary]; }
								[NSMD setObject:registrationKey forKey:@"registration"];
								[NSMD writeToFile:path atomically:YES];
								
								return true;
							} break;
						}
						
						free( identifier );
					}
				}
			}
		}
		
		close(keySocket);
		#ifdef DEBUG
		NSLog( @"try number %d\n", numtries );
		#endif
		sleep(REGTRYSLEEPTIME);
	}
	
	return false;
}

#pragma mark Visual Status Setters

- (void) setBootingUp    { [status setTitleWithMnemonic:NSLocalizedStringFromTableInBundle(@"BEINGENABLED", 0L, myBundle, 0L)];  [status setTextColor:[NSColor colorWithCalibratedRed:0.6 green:0.6 blue:0.6 alpha:1.0]]; [onoff setTitle:NSLocalizedStringFromTableInBundle(@"DISABLE", 0L, myBundle, 0L)]; [onoff setEnabled:NO];	 currentlyRunning = false; }
- (void) setShuttingDown { [status setTitleWithMnemonic:NSLocalizedStringFromTableInBundle(@"BEINGDISABLED", 0L, myBundle, 0L)]; [status setTextColor:[NSColor colorWithCalibratedRed:0.6 green:0.6 blue:0.6 alpha:1.0]]; [onoff setTitle:NSLocalizedStringFromTableInBundle(@"ENABLE", 0L, myBundle, 0L)];	 [onoff setEnabled:NO];	 currentlyRunning = true;  }
- (void) setRunning      { [status setTitleWithMnemonic:NSLocalizedStringFromTableInBundle(@"ENABLED", 0L, myBundle, 0L)];		 [status setTextColor:[NSColor colorWithCalibratedRed:0.0 green:0.6 blue:0.0 alpha:1.0]]; [onoff setTitle:NSLocalizedStringFromTableInBundle(@"DISABLE", 0L, myBundle, 0L)]; [onoff setEnabled:YES]; currentlyRunning = true;  }
- (void) setNotRunning   { [status setTitleWithMnemonic:NSLocalizedStringFromTableInBundle(@"DISABLED", 0L, myBundle, 0L)];	     [status setTextColor:[NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:1.0]]; [onoff setTitle:NSLocalizedStringFromTableInBundle(@"ENABLE", 0L, myBundle, 0L)];  [onoff setEnabled:YES]; currentlyRunning = false; }

#pragma mark Threads

- (void) regthread:(NSString*)txnid
{
	NSAutoreleasePool* NSARP = [[NSAutoreleasePool alloc] init];
	
	[defaults setObject:txnid forKey:@"TID"];
	[self pushDefaults];
	
	registering = true;
	[webpayProgress setHidden:NO]; [webpayProgress startAnimation:self];
	[regWindow->webpayProgress setHidden:NO]; [regWindow->webpayProgress startAnimation:self];
	[registrationstatus setTitleWithMnemonic:NSLocalizedStringFromTableInBundle(@"REGISTERING", 0L, myBundle, 0L)];
	
	if( ![self makeKeyServerRequest:tehData txnid:[txnid cStringUsingEncoding:NSASCIIStringEncoding]] )
	{
		NSMutableString* Failure = [NSMutableString stringWithString:NSLocalizedStringFromTableInBundle(@"REGISTRATIONFAILED", 0L, myBundle, 0L)];
		[Failure appendString:txnid];
		[registrationstatus setTitleWithMnemonic:Failure];
		[serial setHidden:NO];
	}
	
	[txnid release];
	
	[webpayProgress setHidden:YES]; [webpayProgress stopAnimation:self];
	[regWindow->webpayProgress setHidden:YES]; [regWindow->webpayProgress stopAnimation:self];
	registering = false;
	
	// After the registration attempt is done send the user to the return URL
	
	NSURL* returnURL = [NSURL URLWithString:@"https://www.aorensoftware.com/LanguageAid/register.html"];
	
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:returnURL];
	[request setHTTPMethod: @"GET"];

	// Send the request
	NSURLResponse*					requestResponse;
	NSError*						requestError;
	[webpayProgress setHidden:NO]; [webpayProgress startAnimation:self];
	[regWindow->webpayProgress setHidden:NO]; [regWindow->webpayProgress startAnimation:self];
	NSData* responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&requestResponse error:&requestError];
	
	//// Try to cut the caches down?
	/*[[WebHistory optionalSharedHistory] removeAllItems];
	
	WebBackForwardList *backForwardList = [paymentView backForwardList]; 
	unsigned cacheSize = [backForwardList pageCacheSize];
	[backForwardList setPageCacheSize:0];
	[backForwardList setPageCacheSize:cacheSize];*/
	////
	
	[webpayProgress setHidden:YES]; [webpayProgress stopAnimation:self];
	[regWindow->webpayProgress setHidden:YES]; [regWindow->webpayProgress stopAnimation:self];
	
	if( [responseData length] )
	{
		[[regWindow->paymentView mainFrame] loadData:responseData MIMEType:@"text/html" textEncodingName:[requestResponse textEncodingName] baseURL:returnURL];
	}
	else
	{
		//
	}
	
	[NSARP release];
}

- (void) checkupgrade:(id)nuthin
{
	NSAutoreleasePool* NSARP = [[NSAutoreleasePool alloc] init];
	
	#ifdef DEBUG
	NSDictionary* upgrade = [NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:@"http://localhost/~snielsen/www.aorensoftware.com/LanguageAid/upgrade.plist"]];
	#else
	NSDictionary* upgrade = [NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:@"http://www.aorensoftware.com/LanguageAid/upgrade.plist"]];
	#endif

	if( upgrade )
	{
		// Check the version of the app for a later version
		NSString* currentVersion = [upgrade objectForKey:@"ReleaseIterator"];
		NSString* thisVersion = [[myBundle infoDictionary] objectForKey:@"ReleaseIterator"];
		
		if( currentVersion && thisVersion )
		{
			if( [thisVersion floatValue] < [currentVersion floatValue] )
			{
				[upgradeButton setHidden:NO];
			}
		}
		
		// Now check all the published plugins for the latest versions
		//NSArray* uptodatePlugins = [upgrade objectForKey:@"plugins"];
		NSArray* uptodatePlugins = [upgrade objectForKey:@"plugins1.1.1"]; // This should be set to whatever the latest compatability version should be
		
		bool anyupgradable = false;
		bool anynotinstalled = false;
		
		[LAPluginsLock lock];
			
			for( int i = 0; i < [uptodatePlugins count]; i++ )
			{
				NSMutableDictionary* newplugin = [NSMutableDictionary dictionaryWithDictionary:[uptodatePlugins objectAtIndex:i]];
				NSString* newplugname = [newplugin objectForKey:@"plugin"];
				bool needupgrade = false;
				bool alreadyinstalled = false;
				
				#ifdef DEBUG
				NSLog(@"%@ remote managed plugin found\n", newplugname);
				#endif
				
				LAPluginReference* PMR = 0L;
				
				for( int m = 0; m < [loadedLAPlugins count]; m++ )
				{
					PMR = [loadedLAPlugins objectAtIndex:m];
					
					if( [PMR->name isEqualToString:newplugname] )
					{
						alreadyinstalled = true;
						
						#ifdef DEBUG
						NSLog(@"%@ vs %@\n", [newplugin objectForKey:@"version"], [PMR->infoDictionary objectForKey:@"CFBundleShortVersionString"]);
						#endif
							
						if( [[newplugin objectForKey:@"version"] compare:[PMR->infoDictionary objectForKey:@"CFBundleShortVersionString"] options:NSNumericSearch] == NSOrderedDescending )
						{
							#ifdef DEBUG
							NSLog(@"%@ wins NEEDS UPGRADE\n", [newplugin objectForKey:@"version"]);
							#endif

							needupgrade = true;
							anyupgradable = true;
						}
						else
						{
							#ifdef DEBUG
							NSLog(@"%@ wins IS FINE\n", [PMR->infoDictionary objectForKey:@"CFBundleShortVersionString"]);
							#endif
						}
						
						break;
					}
				}
				
				if( !alreadyinstalled )
				{
					[newModulesArray addObject:newplugin];
					anynotinstalled = true;
				}
				else if( needupgrade )
				{
					PMR->newversion = [[newplugin objectForKey:@"version"] retain];
					PMR->newversionURL = [[newplugin objectForKey:@"URL"] retain];
				}
			}
		
		[LAPluginsLock unlock];
		
		if( anyupgradable ){ [upgradeModulesButton setHidden:NO]; }else{ [upgradeModulesButton setHidden:YES]; }
		if( anynotinstalled ){ [addnewModulesButton setHidden:NO]; [newModWindow->newPlugins reloadData]; }else{ [addnewModulesButton setHidden:YES]; }
	}
	else
	{
		#ifdef DEBUG
		NSLog(@"couldn't get upgrade.plist\n");
		#endif
	}
	
	[NSARP release];
}

#pragma mark Notification Callbacks

- (void) aidRunning:(NSNotification*)N
{
	[self setRunning];
	if( serialBack )
	{
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"needtehData" object:0L userInfo:0L deliverImmediately:YES]; serialBack = false;
	}
}

- (void) aidDying:(NSNotification*)N { [self setNotRunning]; }

/*- (void) changedPayView:(NSNotification*)N
{
	printf("changed\n");
	WebView* WV = [N object];
	WebFrame* WF = [WV mainFrame];
	
	if( [[WF name] isEqualTo:@"Payment Received"] )
	{
		//[[NSNotificationCenter defaultCenter] removeObserver:self name:@"WebViewDidChangeNotification" object:WV];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:@"WebViewDidChangeNotification" object:0L];
		
		[self makeKeyServerRequest:tehData];
	}
}*/

/*- (void) webView:(WebView*)sender didReceiveTitle:(NSString*)title forFrame:(WebFrame*)frame
{
	NSLog( title );
	
	if( [title isEqualToString:@"PayPal - You Have Completed Your Purchase"] )
	{
		WebDataSource* WDS = [frame dataSource];
		
		//while( [WDS isLoading] == YES ){}
		
		NSData* theData = [WDS data];
		char* theBytes = (char*)[theData bytes];
		
		printf("THE RESULTS: %s\n", theBytes);

		char* asf = strstr(theBytes, "aorensoftware");
		
		if( asf ){ printf("GOT AOREN\n"); };
	}
}*/

- (void) tehData:(NSNotification*)N
{
	tehData = [[N object] retain];
	//NSLog(tehData);
	
	NSString* TID = [defaults objectForKey:@"TID"];
	
	// This is a retry, don't need to bring up PayPal again because they already paid.
	// Failed to register, try again.
	if( TID )
	{
		[TID retain];
		[NSThread detachNewThreadSelector:@selector(regthread:) toTarget:self withObject:TID];
	}
	// Fresh transaction, bring up PayPal and start da bidness...
	else
	{
		[regWindow->paymentView setFrameLoadDelegate:self];
		
		// Build the POST query
		
		// 1.0/1.0.1 (item 42)
		/*#ifdef RELEASE
		NSMutableString* POSTquery = [NSMutableString stringWithString:@"cmd=_s-xclick&submit.x=47&submit.y=15&encrypted=-----BEGIN PKCS7-----MIIICQYJKoZIhvcNAQcEoIIH+jCCB/YCAQExggEwMIIBLAIBADCBlDCBjjELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAkNBMRYwFAYDVQQHEw1Nb3VudGFpbiBWaWV3MRQwEgYDVQQKEwtQYXlQYWwgSW5jLjETMBEGA1UECxQKbGl2ZV9jZXJ0czERMA8GA1UEAxQIbGl2ZV9hcGkxHDAaBgkqhkiG9w0BCQEWDXJlQHBheXBhbC5jb20CAQAwDQYJKoZIhvcNAQEBBQAEgYCKvlweklIAKJbTfVaZgs6iwZLArxe0fwJwQMaEt90ahXcidFawdeVl0akdLbPZ5me+sz8oGpybDMQchGoEsO7HZF9A4l+obhGgs/0wxtxDYlbhvcBWhWP53d9hiKWLo/Fjxn+l5+VXe1s0xkRnDE1dQusoVl+0Ui4FdRgw1K0iwzELMAkGBSsOAwIaBQAwggGFBgkqhkiG9w0BBwEwFAYIKoZIhvcNAwcECFvWqLrrw6tegIIBYKRibhvBV5KQlt2Gvh1u1DGIsvCwi70LWnyiDP4Y5IAps5lUvlK6YW5pPMBLpq5SVk+tX+obTkUzT4q4taqGTx9jrZU2CmQ022waSCmXPPD32nK4KcimDLGuMekm1ofNPHzjUb80Pbso5+k0SojbKCn+NGJcgPKgyFkp1RRt6tctOJWYtoTMbukTw027I8bufs3F0ek3yYWmxWQgXy3Wsz7MMX7vx+grhzIqQJmWuTPaAcNi570/EwJdxyDdXx5vbLn8gF29fW55WLz1QdbmMF9u2XJzha+gLs+QkYS84UlWOeFxh7ub9oYc27QYmDG9X5xqtGVHCFAuAeKrdLyInWojHbECjSqlNIkNcHeWZsuvkSF7I8cO7tjLqqjaJ4nXOiNf+JMP+d/FtI0RGWtxFfpEdVOzg3DEnczciIrw0h3WDFw0HjpW3RhFdV3CxdJwLCZLbm3IpIRcsxnPSkDpFh2gggOHMIIDgzCCAuygAwIBAgIBADANBgkqhkiG9w0BAQUFADCBjjELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAkNBMRYwFAYDVQQHEw1Nb3VudGFpbiBWaWV3MRQwEgYDVQQKEwtQYXlQYWwgSW5jLjETMBEGA1UECxQKbGl2ZV9jZXJ0czERMA8GA1UEAxQIbGl2ZV9hcGkxHDAaBgkqhkiG9w0BCQEWDXJlQHBheXBhbC5jb20wHhcNMDQwMjEzMTAxMzE1WhcNMzUwMjEzMTAxMzE1WjCBjjELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAkNBMRYwFAYDVQQHEw1Nb3VudGFpbiBWaWV3MRQwEgYDVQQKEwtQYXlQYWwgSW5jLjETMBEGA1UECxQKbGl2ZV9jZXJ0czERMA8GA1UEAxQIbGl2ZV9hcGkxHDAaBgkqhkiG9w0BCQEWDXJlQHBheXBhbC5jb20wgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBAMFHTt38RMxLXJyO2SmS+Ndl72T7oKJ4u4uw+6awntALWh03PewmIJuzbALScsTS4sZoS1fKciBGoh11gIfHzylvkdNe/hJl66/RGqrj5rFb08sAABNTzDTiqqNpJeBsYs/c2aiGozptX2RlnBktH+SUNpAajW724Nv2Wvhif6sFAgMBAAGjge4wgeswHQYDVR0OBBYEFJaffLvGbxe9WT9S1wob7BDWZJRrMIG7BgNVHSMEgbMwgbCAFJaffLvGbxe9WT9S1wob7BDWZJRroYGUpIGRMIGOMQswCQYDVQQGEwJVUzELMAkGA1UECBMCQ0ExFjAUBgNVBAcTDU1vdW50YWluIFZpZXcxFDASBgNVBAoTC1BheVBhbCBJbmMuMRMwEQYDVQQLFApsaXZlX2NlcnRzMREwDwYDVQQDFAhsaXZlX2FwaTEcMBoGCSqGSIb3DQEJARYNcmVAcGF5cGFsLmNvbYIBADAMBgNVHRMEBTADAQH/MA0GCSqGSIb3DQEBBQUAA4GBAIFfOlaagFrl71+jq6OKidbWFSE+Q4FqROvdgIONth+8kSK//Y/4ihuE4Ymvzn5ceE3S/iBSQQMjyvb+s2TWbQYDwcp129OPIbD9epdr4tJOUNiSojw7BHwYRiPh58S1xGlFgHFXwrEBb3dgNbMUa+u4qectsMAXpVHnD9wIyfmHMYIBmjCCAZYCAQEwgZQwgY4xCzAJBgNVBAYTAlVTMQswCQYDVQQIEwJDQTEWMBQGA1UEBxMNTW91bnRhaW4gVmlldzEUMBIGA1UEChMLUGF5UGFsIEluYy4xEzARBgNVBAsUCmxpdmVfY2VydHMxETAPBgNVBAMUCGxpdmVfYXBpMRwwGgYJKoZIhvcNAQkBFg1yZUBwYXlwYWwuY29tAgEAMAkGBSsOAwIaBQCgXTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0wNjA1MjYwNDQ2NTdaMCMGCSqGSIb3DQEJBDEWBBTPbyDZQzNwoeDlJZVngvyjEP8zyTANBgkqhkiG9w0BAQEFAASBgG7hfU5vX3lkwMBxkkAxD8Yz8RBMy9xvoW0aWD3b7rbNhV8PNmj2LmZVx/+EfHUNJjd3fs1r3uJVzWoaX2duxoCRZAPmKMVUN+0JvBL8wWM+9chaWY/hkrh5AhJaaP3p/1E1S5pGUsJn0c0GOeRzIERLJMJcDsAUbSz7+kbuzE+T-----END PKCS7-----"];
		// MUST BE DONE IN THIS ORDER!
		[POSTquery replaceOccurrencesOfString:@"+" withString:@"%2B" options:NSLiteralSearch range:NSMakeRange(0, [POSTquery length])];
		[POSTquery replaceOccurrencesOfString:@"/" withString:@"%2F" options:NSLiteralSearch range:NSMakeRange(0, [POSTquery length])];
		[POSTquery replaceOccurrencesOfString:@" " withString:@"+" options:NSLiteralSearch range:NSMakeRange(0, [POSTquery length])];
		
		//NSString* POSTquery = [NSString stringWithContentsOfFile:@"/poo2" encoding:NSUTF8StringEncoding error:NULL];
		#else
		NSString* POSTquery = [NSString stringWithString:@"cmd=_s-xclick&submit.x=47&submit.y=15&encrypted=-----BEGIN+PKCS7-----MIIHkQYJKoZIhvcNAQcEoIIHgjCCB34CAQExggE6MIIBNgIBADCBnjCBmDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCkNhbGlmb3JuaWExETAPBgNVBAcTCFNhbiBKb3NlMRUwEwYDVQQKEwxQYXlQYWwsIEluYy4xFjAUBgNVBAsUDXNhbmRib3hfY2VydHMxFDASBgNVBAMUC3NhbmRib3hfYXBpMRwwGgYJKoZIhvcNAQkBFg1yZUBwYXlwYWwuY29tAgEAMA0GCSqGSIb3DQEBAQUABIGAYZKXBX3Tnxg%2FPzL2lCNw2Eu%2BeBYjnTecnIVuuPkoeAttt7Okrj2PgKAgV4gFLjfYMydRhLHU80RQIWH4Q9b3JakErGb%2BK6QDJr0OuFVJ9zCWYh3%2F5C%2Fg0cSnT1lr%2F7QvFvSAZGiA%2FJFZ8qMxpUgk%2FgEGdPm5t7ZukvWNNk6Z2G4xCzAJBgUrDgMCGgUAMIHcBgkqhkiG9w0BBwEwFAYIKoZIhvcNAwcECLCx909%2BmgVCgIG4SwQ3%2F8fUEblU67cd8YHSdV9x2YP9N4v7Xx4m9TrkhU%2Bsg13LyVhpO9W2Y286NIbk%2BaXMSC7rDvNxKGSRomKKlx7RFxGfQ2rgucs9VS9Z12hinnmaXmzlAA7kQGnSq4eY9XcW0dhtxSI0pEQZqKX6BlHFJU704He87mfrLZflNvxZZ1udpoG9EAcr0vTQFSQFqnldtTBoBC5j7GC1XOz4BYM53%2BBQ7Qg4NcGw4eYbniaM3RvnygNyNqCCA6UwggOhMIIDCqADAgECAgEAMA0GCSqGSIb3DQEBBQUAMIGYMQswCQYDVQQGEwJVUzETMBEGA1UECBMKQ2FsaWZvcm5pYTERMA8GA1UEBxMIU2FuIEpvc2UxFTATBgNVBAoTDFBheVBhbCwgSW5jLjEWMBQGA1UECxQNc2FuZGJveF9jZXJ0czEUMBIGA1UEAxQLc2FuZGJveF9hcGkxHDAaBgkqhkiG9w0BCQEWDXJlQHBheXBhbC5jb20wHhcNMDQwNDE5MDcwMjU0WhcNMzUwNDE5MDcwMjU0WjCBmDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCkNhbGlmb3JuaWExETAPBgNVBAcTCFNhbiBKb3NlMRUwEwYDVQQKEwxQYXlQYWwsIEluYy4xFjAUBgNVBAsUDXNhbmRib3hfY2VydHMxFDASBgNVBAMUC3NhbmRib3hfYXBpMRwwGgYJKoZIhvcNAQkBFg1yZUBwYXlwYWwuY29tMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC3luO%2F%2FQ3So3dOIEv7X4v8SOk7WN6o9okLV8OL5wLq3q1NtDnk53imhPzGNLM0flLjyId1mHQLsSp8TUw8JzZygmoJKkOrGY6s771BeyMdYCfHqxvp%2Bgcemw%2BbtaBDJSYOw3BNZPc4ZHf3wRGYHPNygvmjB%2FfMFKlE%2FQ2VNaic8wIDAQABo4H4MIH1MB0GA1UdDgQWBBSDLiLZqyqILWunkyzzUPHyd9Wp0jCBxQYDVR0jBIG9MIG6gBSDLiLZqyqILWunkyzzUPHyd9Wp0qGBnqSBmzCBmDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCkNhbGlmb3JuaWExETAPBgNVBAcTCFNhbiBKb3NlMRUwEwYDVQQKEwxQYXlQYWwsIEluYy4xFjAUBgNVBAsUDXNhbmRib3hfY2VydHMxFDASBgNVBAMUC3NhbmRib3hfYXBpMRwwGgYJKoZIhvcNAQkBFg1yZUBwYXlwYWwuY29tggEAMAwGA1UdEwQFMAMBAf8wDQYJKoZIhvcNAQEFBQADgYEAVzbzwNgZf4Zfb5Y%2F93B1fB%2BJx%2F6uUb7RX0YE8llgpklDTr1b9lGRS5YVD46l3bKE%2Bmd4Z7ObDdpTbbYIat0qE6sElFFymg7cWMceZdaSqBtCoNZ0btL7%2BXyfVB8M%2Bn6OlQs6tycYRRjjUiaNklPKVslDVvk8EGMaI%2FQ%2Bkrjxx0UxggGkMIIBoAIBATCBnjCBmDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCkNhbGlmb3JuaWExETAPBgNVBAcTCFNhbiBKb3NlMRUwEwYDVQQKEwxQYXlQYWwsIEluYy4xFjAUBgNVBAsUDXNhbmRib3hfY2VydHMxFDASBgNVBAMUC3NhbmRib3hfYXBpMRwwGgYJKoZIhvcNAQkBFg1yZUBwYXlwYWwuY29tAgEAMAkGBSsOAwIaBQCgXTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0wNjAzMjUxNzMxMDBaMCMGCSqGSIb3DQEJBDEWBBTzLHNe2hZ3gKEbvex2Aqn6ltReXTANBgkqhkiG9w0BAQEFAASBgIy%2BFmaxEBM2pVj8SB0vbCF%2FgbCULJxjwfJwY%2FCv7H5171udR3MRDTMLV9pE4qELl0zzTubdNf2%2BoY1IcSXl%2B4qjN3CSihLp%2FrRcHbloOk9o2UEHATSgZ2imTE7zkp9XXBjzZvrbtRsuJJYz4T7sjZoZxQPt%2BcshqcypDE2bUXv4-----END+PKCS7-----"];
		#endif*/
		
		#ifdef DEBUG
		NSDictionary* purchaseURLs = [NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:@"http://localhost/~snielsen/www.aorensoftware.com/LanguageAid/purchaseURL.plist"]];
		#else
		NSDictionary* purchaseURLs = [NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:@"http://www.aorensoftware.com/LanguageAid/purchaseURL.plist"]];
		#endif
		
		if( purchaseURLs )
		{
			NSString* POSTquery = 0L;
			
			// Eventually grab these from the web site.
			id oldTID = [defaults objectForKey:@"oldTID"];
			if( !oldTID )
			{
				// 1.1 new (item 43)
				#ifdef DEBUG
				POSTquery = [purchaseURLs objectForKey:@"newPurchaseURLSANDBOX"];
				#else
				POSTquery = [purchaseURLs objectForKey:@"newPurchaseURL"];
				#endif
			}
			else
			{
				// 1.1 upgrade (item 44)
				#ifdef DEBUG
				POSTquery = [purchaseURLs objectForKey:@"upgradePurchaseURLSANDBOX"];
				#else
				POSTquery = [purchaseURLs objectForKey:@"upgradePurchaseURL"];
				#endif
			}
			
			// Setup the URL request
			#ifdef RELEASE
			NSURL* paypalURL = [NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr"];
			#else
			NSURL* paypalURL = [NSURL URLWithString:@"https://www.sandbox.paypal.com/cgi-bin/webscr"];
			#endif
			NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:paypalURL];
			[request setHTTPMethod: @"POST"];
			[request setHTTPBody:[POSTquery dataUsingEncoding:NSUTF8StringEncoding]];
			/*[request addValue:@"Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/417.9 (KHTML, like Gecko) Safari/417.8" forHTTPHeaderField:@"User-Agent"];
			[request addValue:@"http://localhost/" forHTTPHeaderField:@"Referer"];
			[request addValue:@"en" forHTTPHeaderField:@"Accept-Language"];
			[request addValue:@"keep-alive" forHTTPHeaderField:@"Connection"];*/
			//[request addValue:@"2744" forHTTPHeaderField:@"Content-Length"];
			
			//[request setHTTPShouldHandleCookies:NO];
			
			// Send the request
			NSURLResponse*					requestResponse;
			NSError*						requestError;
			[webpayProgress setHidden:NO]; [webpayProgress startAnimation:self];
			NSData* responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&requestResponse error:&requestError];
			
			//// Try to cut the caches down?
			/*[[WebHistory optionalSharedHistory] removeAllItems];
			
			WebBackForwardList *backForwardList = [paymentView backForwardList]; 
			unsigned cacheSize = [backForwardList pageCacheSize];
			[backForwardList setPageCacheSize:0];
			[backForwardList setPageCacheSize:cacheSize];*/
			////
			
			if( [responseData length] )
			{
				[[regWindow->paymentView mainFrame] loadData:responseData MIMEType:@"text/html" textEncodingName:[requestResponse textEncodingName] baseURL:paypalURL];
			}
			else
			{
				//NSString* filePath = [[myBundle bundlePath] stringByAppendingString:@"/Contents/Resources/PrefConnectError.html"];
				NSString* filePath = [myBundle pathForResource:@"PrefConnectError" ofType:@"html" inDirectory:0L];
				[[regWindow->paymentView mainFrame] loadHTMLString:[NSString stringWithContentsOfFile:filePath] baseURL:[NSURL fileURLWithPath:filePath]];
				[regWindow->paymentView display];
			}
		}
		else
		{
			NSString* filePath = [myBundle pathForResource:@"AorenConnectError" ofType:@"html" inDirectory:0L];
			[[regWindow->paymentView mainFrame] loadHTMLString:[NSString stringWithContentsOfFile:filePath] baseURL:[NSURL fileURLWithPath:filePath]];
			[regWindow->paymentView display];
		}
	}
}

- (void) repChanged:(NSNotification*)N
{
	#ifdef DEBUG
	NSLog(@"DID repChanged\n");
	#endif

	NSArray* newMods = [thePM reload];
	[self resizeTrigger]; [pluginModules reloadData];
	[newMods release];
}

- (void) webView:(WebView*)sender didFinishLoadForFrame:(WebFrame*)frame
{
	[regWindow->webpayProgress setHidden:YES]; [regWindow->webpayProgress stopAnimation:self];
	
	//NSLog( [frame name] );
	
	//// Try to cut the caches down?
	/*[[WebHistory optionalSharedHistory] removeAllItems];
	
	WebBackForwardList *backForwardList = [paymentView backForwardList]; 
	unsigned cacheSize = [backForwardList pageCacheSize];
	[backForwardList setPageCacheSize:0];
	[backForwardList setPageCacheSize:cacheSize];*/
	////
	
	if( !expanded )
	{
		//[regWindow setHidden:FALSE];
		[regWindow center];
		[regWindow makeKeyAndOrderFront:self];
	
		// Actually display the content now
		[regWindow->paymentView display];
		[regWindow->paymentView setHidden:FALSE];
		
		/*NSRect screenRect = [[NSScreen mainScreen] frame];
		NSView* v = [self mainView];
		[v setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
		NSWindow* w = [v window];
		NSRect f = [w frame];
		//f.origin.y -= PPHeight;
		f.origin.y = 20;
		f.origin.x = screenRect.size.width/2 - 832/2;
		f.size.height += PPHeight; oldwidth = f.size.width;
		f.size.width = 832;
		[w setFrame:f display:YES animate:YES];*/
		
		[webpayProgress setHidden:YES]; [webpayProgress stopAnimation:self];
		
		//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changedPayView:) name:@"WebViewDidChangeNotification" object:0L];
		
		expanded = true;
	}
	else
	{
		//WebDataSource* WDS = [frame dataSource];
		
		//NSLog( [WDS pageTitle] );
	
		//if( [[WDS pageTitle] isEqualToString:@"PayPal - You Have Completed Your Purchase"] )
		{
			WebDataSource* WDS = [frame dataSource];
			
			while( [WDS isLoading] == YES ){}
			
			NSData* theData = [WDS data]; //[theData writeToFile:@"/junk.html" atomically:YES];
			
			if( theData )
			{
				char* theBytes = (char*)[theData bytes];

				if( theBytes)
				{
					//printf("THE RESULTS: %s\n", theBytes);
					
					char* asf = strstr(theBytes, "http://www.aorensoftware.com/LanguageAid/register.html");
					
					if( asf )
					{
						asf += strlen("http://www.aorensoftware.com/LanguageAid/register.html");
						
						char  txstr[64];
						char* tx = strstr( asf, "tx" );
						
						if( tx )
						{
							tx = strstr( tx, "=" );
							
							if( tx )
							{
								tx += strlen("=");
								
								int txlen = strstr( tx, "&amp" ) - tx;
								
								if( (txlen < 64) && (txlen > 0) )
								{
									strncpy( txstr, tx, txlen );
									txstr[strstr( tx, "&amp" ) - tx] = 0;
								}
								else
								{
									#ifdef DEBUG
									NSLog(@"txlen invalid: %d\n", txlen);
									#endif
								}
							}
							else
							{
								#ifdef DEBUG
								NSLog(@"DID NOT GET = for tx\n");
								#endif
							}
						}
						else
						{
							#ifdef DEBUG
							NSLog(@"DID NOT GET tx\n");
							#endif
						}
						
						char txstrQ[64];
						char* txQ = strstr( asf, "tx" );
						
						if( txQ )
						{
							txQ = strstr( txQ, "=\"" );
							
							if( txQ )
							{
								txQ += strlen("=\"");
								
								int txlenQ = strstr( txQ, "\"" ) - txQ;
								
								if( (txlenQ < 64) && (txlenQ > 0) )
								{
									strncpy( txstrQ, txQ, txlenQ );
									txstrQ[strstr( txQ, "\"" ) - txQ] = 0;
								}
								else
								{
									#ifdef DEBUG
									NSLog(@"txlenQ invalid: %d\n", txlenQ);
									#endif
								}
							}
							else
							{
								#ifdef DEBUG
								NSLog(@"DID NOT GET = for txQ\n");
								#endif
							}
						}
						else
						{
							#ifdef DEBUG
							NSLog(@"DID NOT GET txQ\n");
							#endif
						}
						
						if( strlen(txstr) == 17 )
						{
							[NSThread detachNewThreadSelector:@selector(regthread:) toTarget:self withObject:[[NSString alloc] initWithCString:txstr encoding:NSASCIIStringEncoding]];
						}
						else if( strlen(txstrQ) == 17 )
						{
							[NSThread detachNewThreadSelector:@selector(regthread:) toTarget:self withObject:[[NSString alloc] initWithCString:txstrQ encoding:NSASCIIStringEncoding]];
						}
						else
						{
							[theData writeToFile:@"/Library/Application Support/Language Aid/failedregistration.html" atomically:YES];
							NSLog(@"Unable to parse transation ID.  Please email the file /Library/Application Support/Language Aid/failedregistration.html to support@aorensoftware.com\n");
								
							// We couldn't parse it so ask the user for it
							/*[NSApp runModalForWindow:TIDErrorWindow];
							
							// Pressed "Enter TID"
							if( TIDErrorWindow->daActualTID )
							{
								[NSThread detachNewThreadSelector:@selector(regthread:) toTarget:self withObject:TIDErrorWindow->daActualTID];
							}
							// Pressed "Back"
							else
							{
								
							}*/
						}
					}
				}
			}
		}
	}
}

- (void) webView:(WebView*)WV didStartProvisionalLoadForFrame:(WebFrame*)WF
{
	[regWindow->webpayProgress setHidden:NO]; [regWindow->webpayProgress startAnimation:self];
}

#pragma mark Plugin Module Table Callbacks

- (id) tableView:(NSTableView*)aTableView objectValueForTableColumn:(NSTableColumn*)aTableColumn row:(int)rowIndex
{
	[LAPluginsLock lock];
	
	LAPluginReference* PMR = ((LAPluginReference*)[loadedLAPlugins objectAtIndex:rowIndex]);
	
	if( PMR )
	{
		if( [[aTableColumn identifier] isEqualToString:@"Enabled"] )
		{
			NSNumber* isenabled = 0L;
			
			NSDictionary* daTrig = [Triggers objectForKey:PMR->name];
			NSMutableDictionary* thisModulesTriggers = [NSMutableDictionary dictionaryWithDictionary:daTrig];
			
			if( daTrig )
			{
				isenabled = [thisModulesTriggers objectForKey:@"Enabled"];
				
				if( !isenabled )
				{
					isenabled = [NSNumber numberWithInt:0];
					[thisModulesTriggers setObject:isenabled forKey:@"Enabled"];
					[Triggers setObject:thisModulesTriggers forKey:PMR->name];
				}
			}
			else
			{
				isenabled = [NSNumber numberWithInt:0];
			}
			
			if( !unsignedOK && !PMR->aorensigned )
			{
				NSButtonCell* theBC = [aTableColumn dataCellForRow:rowIndex];
				[theBC setEnabled:NO];
				//[theBC setToolTip:NSLocalizedStringFromTableInBundle(@"GREYEDOUTCHECKBOX", 0L, myBundle, 0L)];
			}
			else
			{
				NSButtonCell* theBC = [aTableColumn dataCellForRow:rowIndex];
				[theBC setEnabled:YES];
				//[theBC setToolTip:0L];
			}
			
			[LAPluginsLock unlock];
			return isenabled;
		}
		else if( [[aTableColumn identifier] isEqualToString:@"Name"] )
		{
			NSMutableString* tString = [NSMutableString string];
			
			if( !PMR->pluginClass )
			{
				if( PMR->name )
				{
					[tString appendFormat:@"%@ %@", PMR->name, NSLocalizedStringFromTableInBundle(@"NOTLOADED", 0L, myBundle, 0L)];
				}
				else
				{
					[tString appendFormat:@"%@", NSLocalizedStringFromTableInBundle(@"NOTLOADED", 0L, myBundle, 0L)];
				}
			}
			else
			{
				if( [PMR->pluginClass respondsToSelector:@selector(Title)] )
				{
					NSString* t = [PMR->pluginClass Title];
					
					if( ![t isEqualToString:@""] )
					{
						[tString appendFormat:@"%@", t];
					}
					else if( PMR->name )
					{
						[tString appendFormat:@"%@", PMR->name];
					}
				}
				else if( PMR->name )
				{
					[tString appendFormat:@"%@", PMR->name];
				}
				else
				{
					[tString appendFormat:@"%@", @"POOPEY"];
				}
			}
			
			[LAPluginsLock unlock];
			return tString;
		}
		else if( [[aTableColumn identifier] isEqualToString:@"Author"] )
		{
			NSString* daauthor = NSLocalizedStringFromTableInBundle(@"NOTLOADED", 0L, myBundle, 0L);
			
			if( PMR->pluginClass )
			{
				daauthor = [PMR->pluginClass Author];
				
				if( ![daauthor isKindOfClass:[NSString class]] ){ daauthor = 0L; }
			}
			else
			{
				#ifdef DEBUG
				//NSLog(@"%@'s pluginClass is null for some reason (rowIndex: %d).", PMR->modulePath, rowIndex);
				#endif
			}
			
			[LAPluginsLock unlock];
			return daauthor;
		}
		else if( [[aTableColumn identifier] isEqualToString:@"Trigger"] )
		{
			NSMutableString* tString = [NSMutableString string];
			
			NSDictionary* thisModulesTriggers = [Triggers objectForKey:PMR->name];
			
			if( thisModulesTriggers )
			{
				NSString* type = [thisModulesTriggers objectForKey:@"actiontype"];
				
				id val = 0L;
	
				val = [thisModulesTriggers objectForKey:@"command"]; if( val && [val intValue] ){ [tString appendString:[NSString stringWithCString:"⌘" encoding:NSUTF8StringEncoding]]; }
				val = [thisModulesTriggers objectForKey:@"shift"];   if( val && [val intValue] ){ [tString appendString:[NSString stringWithCString:"⇧" encoding:NSUTF8StringEncoding]]; }
				val = [thisModulesTriggers objectForKey:@"option"];  if( val && [val intValue] ){ [tString appendString:[NSString stringWithCString:"⌥" encoding:NSUTF8StringEncoding]]; }
				val = [thisModulesTriggers objectForKey:@"control"]; if( val && [val intValue] ){ [tString appendString:[NSString stringWithCString:"⌃" encoding:NSUTF8StringEncoding]]; }
						
					 if( [type isEqualToString:@"Mouse Click"]  ){ [tString appendString:[self mouseToMouseLocalized:[thisModulesTriggers objectForKey:@"mouseclick"]]];  }
				else if( [type isEqualToString:@"Function Key"] ){ [tString appendString:[thisModulesTriggers objectForKey:@"functionkey"]]; }
			}
			else
			{
				//[tString appendString:DEFAULTKEYTRIGGER];
				[tString appendString:NSLocalizedStringFromTableInBundle(@"NOTSET", 0L, myBundle, 0L)];
			}
			
			//NSLog( tString );
			
			[LAPluginsLock unlock];
			return tString;
		}
		else if( [[aTableColumn identifier] isEqualToString:@"Version"] )
		{			
			NSString* vers = 0L;
			
			if( PMR->upgradedVersion ){ vers = PMR->upgradedVersion; }
			else{ vers = [PMR->infoDictionary objectForKey:@"CFBundleShortVersionString"]; }
			//NSLog(@"%@ VERS: %@", PMR->name, [PMR->infoDictionary objectForKey:@"CFBundleShortVersionString"]);
			
			if( PMR->newversion ){ vers = [vers stringByAppendingString:[NSString stringWithCString:" ⇪" encoding:NSUTF8StringEncoding]];	}
			
			NSButtonCell* BC = [aTableColumn dataCellForRow:rowIndex];
			[BC setTitle:vers];
			
			[LAPluginsLock unlock];
			return vers;
		}
		else if( [[aTableColumn identifier] isEqualToString:@"Signed"] )
		{
			NSImage* sign = unsignedImage;
			
			if( PMR->aorensigned )
			{
				sign = aorenlogo;
			}
			
			[LAPluginsLock unlock];
			return sign;
		}
	}
	else
	{
		#ifdef DEBUG
		NSLog(@"PMR lookup failed in table for rowIndex: %d\n", rowIndex);
		#endif
	}
	
	[LAPluginsLock unlock];
	return @"";
}

- (void) tableView:(NSTableView*)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn*)aTableColumn row:(int)rowIndex
{
	if( [[aTableColumn identifier] isEqualToString:@"Enabled"] )
	{
		[LAPluginsLock lock];
		
		LAPluginReference* PMR = ((LAPluginReference*)[loadedLAPlugins objectAtIndex:rowIndex]);
		NSMutableDictionary* thisModulesTriggers = [Triggers objectForKey:PMR->name];
		
		int newstate = [anObject intValue];
		
		//printf( "newstate: %d rowIndex: %d\n", newstate, rowIndex );
		
		if( thisModulesTriggers )
		{
			NSString* t = [PMR->pluginClass Title];
			if( t && ![t isEqualToString:@""] ){	[thisModulesTriggers setObject:t forKey:@"title"]; }
			
			[thisModulesTriggers setObject:anObject forKey:@"Enabled"];
			[Triggers setObject:thisModulesTriggers forKey:PMR->name];
			[defaults setObject:Triggers forKey:@"Triggers"];
			[defaults synchronize];
			[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"defaultsChanged" object:0L userInfo:0L deliverImmediately:YES];
		
			justEnabled = 0L;
		}
		else
		{
			justEnabled = PMR->name;
		}
		
		if( (unsignedOK || PMR->aorensigned) && !PMR->isLoaded && newstate ){ [PMR nowLoad]; }

		[LAPluginsLock unlock];
		
		[pluginModules reloadData];
	}
	else if( [[aTableColumn identifier] isEqualToString:@"Version"] )
	{
		[LAPluginsLock lock];
	
		LAPluginReference* PMR = ((LAPluginReference*)[loadedLAPlugins objectAtIndex:rowIndex]);

		if( PMR->newversion )
		{
			int ret = NSRunAlertPanel( [NSString stringWithFormat:@"%@ - %@ %@", PMR->name, NSLocalizedStringFromTableInBundle(@"UPGRADE", 0L, myBundle, 0L), PMR->newversion], NSLocalizedStringFromTableInBundle(@"UPGRADEDIALOG", 0L, myBundle, 0L), NSLocalizedStringFromTableInBundle(@"YES", 0L, myBundle, 0L), NSLocalizedStringFromTableInBundle(@"NO", 0L, myBundle, 0L), 0L );
			switch (ret)
			{
				case NSAlertDefaultReturn:   
				{
					[upgradeModulesButton setHidden:YES];
					[upgradeStatus setHidden:NO];
					[upgradeProgress setMaxValue:3.0];
					[upgradeProgress setDoubleValue:0.0];
					[upgradeProgress setHidden:NO];

					[upgradeProgress incrementBy:1.0];

					OSStatus myStatus;
					AuthorizationFlags myFlags = kAuthorizationFlagDefaults;
					AuthorizationRef myAuthorizationRef;
				 
					myStatus = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, myFlags, &myAuthorizationRef);
					if( myStatus != errAuthorizationSuccess ){ return; }
				 
					AuthorizationItem myItems = {kAuthorizationRightExecute, 0, NULL, 0};
					AuthorizationRights myRights = {1, &myItems};

					myFlags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagPreAuthorize | kAuthorizationFlagExtendRights;
					myStatus = AuthorizationCopyRights (myAuthorizationRef, &myRights, NULL, myFlags, NULL );

					[upgradeProgress incrementBy:1.0];

					if( myStatus == errAuthorizationSuccess)
					{
						int ures = [PMR upgrade:myAuthorizationRef];
						if( ures == DOWNLOADPROBLEM )
						{
							NSRunAlertPanel( [NSString stringWithFormat:@"%@ - %@", PMR->name, NSLocalizedStringFromTableInBundle(@"BADDOWNLOAD", 0L, myBundle, 0L)], NSLocalizedStringFromTableInBundle(@"DOWNLOADFAILED", 0L, myBundle, 0L), NSLocalizedStringFromTableInBundle(@"OK", 0L, myBundle, 0L), 0L, 0L );
						}
						else
						{
							if( currentlyRunning )
							{
								[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"LAshutdown" object:0L userInfo:0L deliverImmediately:YES];
								
								sleep(2);
								
								[self setBootingUp];
								[[NSWorkspace sharedWorkspace] openFile:@"/Library/Application Support/Language Aid/Language Aid.app"];
							}
							else
							{
								[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"LAshutdown" object:0L userInfo:0L deliverImmediately:YES];
							}
						}
						
						[self resizeTrigger]; [pluginModules reloadData];
					}
					
					AuthorizationFree( myAuthorizationRef, kAuthorizationFlagDefaults );
					
					[upgradeProgress incrementBy:1.0];
					
					[upgradeStatus setHidden:YES];
					[upgradeProgress setHidden:YES];
					
					// Check if there are any others that can upgraded
					bool anyupgradable = false;
					for( int m = 0; m < [loadedLAPlugins count]; m++ )
					{
						PMR = [loadedLAPlugins objectAtIndex:m];
						
						if( PMR->newversion )
						{
							anyupgradable = true;
						}
					}
					
					if( anyupgradable ){ [upgradeModulesButton setHidden:NO]; }else{ [upgradeModulesButton setHidden:YES]; }
				} break;
				
				case NSAlertAlternateReturn:
				{
					return;
				} break;
				
				case NSAlertOtherReturn: { } break;
				default: { } break;
			}
		}
		
		safeToJump = true;
		pthread_cond_signal( &repcond );
		[LAPluginsLock unlock];
	}
}

- (int) numberOfRowsInTableView:(NSTableView*)TV
{
	[LAPluginsLock lock];
		int nrows = [loadedLAPlugins count];
	[LAPluginsLock unlock];
	
	return nrows;
}

- (void) tableViewSelectionDidChange:(NSNotification*)aNotification
{
	int pluginIndex = [pluginModules selectedRow];
	
	if( pluginIndex == -1 )
	{
		currentPlugin = 0L;
		currentPluginDictionary = 0L;
		
		[self disableTrigger];
	}
	else
	{
		[LAPluginsLock lock];
		
			currentPlugin = (LAPluginReference*)[loadedLAPlugins objectAtIndex:pluginIndex];
			
			NSMutableDictionary* tr = [Triggers objectForKey:currentPlugin->name];
			
			// This is the first time this module has ever been looked at in the pref pane, create it and give it the default settings
			if( !tr )
			{
				tr = [[NSMutableDictionary alloc] init];
				
				[tr setObject:DEFAULTKEYTRIGGER forKey:@"functionkey"];
				[tr setObject:@"Mouse Button 3" forKey:@"mouseclick"];
				[tr setObject:[NSNumber numberWithInt:0] forKey:@"command"];
				[tr setObject:[NSNumber numberWithInt:0] forKey:@"shift"];
				[tr setObject:[NSNumber numberWithInt:0] forKey:@"option"];
				[tr setObject:[NSNumber numberWithInt:0] forKey:@"control"];
				[tr setObject:[NSNumber numberWithInt:0] forKey:@"fade"];
				[tr setObject:[NSNumber numberWithInt:60] forKey:@"fadesecs"];
				[tr setObject:@"Function Key" forKey:@"actiontype"];
				
				if( [justEnabled isEqualToString:currentPlugin->name] )
					{ [tr setObject:[NSNumber numberWithInt:1] forKey:@"Enabled"]; justEnabled = 0L; }
				else{ [tr setObject:[NSNumber numberWithInt:0] forKey:@"Enabled"]; }
				
				currentPluginDictionary = tr;
				
				[self pushDefaults];
				
				bool dupeRes = [self settingsAreDuped:currentPluginDictionary];
				
				// If there was a conflict then pick a random setting until we find a unique setting
				if( (dupeRes) && ([Triggers count] < 256) )
				{
					while( dupeRes )
					{
						[tr setObject:[NSNumber numberWithInt:random() % 2] forKey:@"command"];
						[tr setObject:[NSNumber numberWithInt:random() % 2] forKey:@"shift"];
						[tr setObject:[NSNumber numberWithInt:random() % 2] forKey:@"option"];
						[tr setObject:[NSNumber numberWithInt:random() % 2] forKey:@"control"];
						int fkey = random() % 16;
						
						NSString* whichkey = 0L;
							 if( fkey ==  0 ){ whichkey =  @"F1"; }
						else if( fkey ==  1 ){ whichkey =  @"F2"; }
						else if( fkey ==  2 ){ whichkey =  @"F3"; }
						else if( fkey ==  3 ){ whichkey =  @"F4"; }
						else if( fkey ==  4 ){ whichkey =  @"F5"; }
						else if( fkey ==  5 ){ whichkey =  @"F6"; }
						else if( fkey ==  6 ){ whichkey =  @"F7"; }
						else if( fkey ==  7 ){ whichkey =  @"F8"; }
						else if( fkey ==  8 ){ whichkey =  @"F9"; }
						else if( fkey ==  9 ){ whichkey = @"F10"; }
						else if( fkey == 10 ){ whichkey = @"F11"; }
						else if( fkey == 11 ){ whichkey = @"F12"; }
						else if( fkey == 12 ){ whichkey = @"F13"; }
						else if( fkey == 13 ){ whichkey = @"F14"; }
						else if( fkey == 14 ){ whichkey = @"F15"; }
						else if( fkey == 15 ){ whichkey = @"F16"; }
						
						[tr setObject:whichkey forKey:@"functionkey"];
						
						dupeRes = [self settingsAreDuped:currentPluginDictionary];
					}
					
					[self pushDefaults];
				}
				// >= 256 module triggers already in the system.  That is too much, we aren't going to try that many times.
				else if( dupeRes )
				{
					NSLog(@"Language Aid can only handle 256 (2^4 modifiers * 16 function keys) different function key combos at once. I don't want to check that the triggers are all function key ones but at >= 256 modules it is surely a lot.  Thus there will be an allowed conflict on this new module's settings.\n");
				}
				
				// Reload the data in the table because the new module just changed the listing.
				[pluginModules reloadData];
			}
			else
			{
				//tr = [[NSMutableDictionary alloc] initWithDictionary:tr];
				
				currentPluginDictionary = tr;
			}
			
			id val = 0L;
			
			val = [tr objectForKey:@"functionkey"];	if( val ){ [key selectItemWithTitle:val];     }else{ [key selectItemWithTitle:DEFAULTKEYTRIGGER];               }
			val = [tr objectForKey:@"mouseclick"];	if( val ){ [mouse selectItemWithTag:[self mouseToTag:val]];   }else{ [mouse selectItemWithTag:3];					}
			val = [tr objectForKey:@"command"];	    if( val ){ [command setState:[val intValue]]; }else{ [command setState:NSOffState];                 }
			val = [tr objectForKey:@"shift"];	    if( val ){ [shift setState:[val intValue]];   }else{ [shift setState:NSOffState];                   }
			val = [tr objectForKey:@"option"];	    if( val ){ [option setState:[val intValue]];  }else{ [option setState:NSOffState];                  }
			val = [tr objectForKey:@"control"];	    if( val ){ [control setState:[val intValue]]; }else{ [control setState:NSOffState];                 }
			val = [tr objectForKey:@"fade"];	    if( val ){ [fadeAwayButton setState:[val intValue]];   }else{ [fadeAwayButton setState:NSOffState]; }
			val = [tr objectForKey:@"fadesecs"];	if( val ){ [fadeAwaySeconds setIntValue:[val intValue]]; }else{ [fadeAwaySeconds setIntValue:60]; }
			val = [tr objectForKey:@"actiontype"];
			if( val ){ if( [val isEqualToString:@"Mouse Click"] ){ [actiontype selectCellWithTag:1]; }else if( [val isEqualToString:@"Function Key"] ){ [actiontype selectCellWithTag:0]; } }else{ [actiontype selectCellWithTag:0]; }
			
		[LAPluginsLock unlock];
		
		[self enableTrigger];
	}
}

- (NSString*) tableView:(NSTableView*)tv toolTipForCell:(NSCell*)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn*)tc row:(int)row mouseLocation:(NSPoint)mouseLocation
{
    if( [cell isKindOfClass:[NSButtonCell class]] )
	{
		if( [[tc identifier] isEqualToString:@"Enabled"] )
		{
			[LAPluginsLock lock];
			LAPluginReference* PMR = ((LAPluginReference*)[loadedLAPlugins objectAtIndex:row]);

			if( PMR )
			{
				NSNumber* isenabled = 0L;
				
				NSMutableDictionary* thisModulesTriggers = [NSMutableDictionary dictionaryWithDictionary:[Triggers objectForKey:PMR->name]];
				
				if( thisModulesTriggers )
				{
					isenabled = [thisModulesTriggers objectForKey:@"Enabled"];
					
					if( !isenabled )
					{
						isenabled = [NSNumber numberWithInt:0];
					}
				}
				else
				{
					isenabled = [NSNumber numberWithInt:0];
				}
				
				if( !unsignedOK && !PMR->aorensigned )
				{
					[LAPluginsLock unlock];
					return NSLocalizedStringFromTableInBundle(@"GREYEDOUTCHECKBOX", 0L, myBundle, 0L);
				}
				else
				{
					[LAPluginsLock unlock];
					return 0L;
				}
			}
			
			[LAPluginsLock unlock];
		}
    }
	
    return 0L;
}

#pragma mark IB Callbacks

- (void) setcommand:(NSButton*)sender
{
	NSNumber* oldCommand = [[currentPluginDictionary objectForKey:@"command"] retain];
	[currentPluginDictionary setObject:[NSNumber numberWithInt:[sender state]] forKey:@"command"];
	
	if( [self settingsAreDuped:currentPluginDictionary] ){ NSBeep(); [sender setState:[oldCommand intValue]]; [currentPluginDictionary setObject:oldCommand forKey:@"command"]; }
	
	[oldCommand release]; [self resizeTrigger]; [pluginModules reloadData]; [self pushDefaults];
}

- (void) setshift:(NSButton*)sender
{
	NSNumber* oldShift = [[currentPluginDictionary objectForKey:@"shift"] retain];
	[currentPluginDictionary setObject:[NSNumber numberWithInt:[sender state]] forKey:@"shift"];

	if( [self settingsAreDuped:currentPluginDictionary] ){ NSBeep(); [sender setState:[oldShift intValue]]; [currentPluginDictionary setObject:oldShift forKey:@"shift"]; }

	[oldShift release]; [self resizeTrigger]; [pluginModules reloadData]; [self pushDefaults];
}

- (void) setoption:(NSButton*)sender
{
	NSNumber* oldOption  = [[currentPluginDictionary objectForKey:@"option"] retain];
	[currentPluginDictionary setObject:[NSNumber numberWithInt:[sender state]] forKey:@"option"];
	
	if( [self settingsAreDuped:currentPluginDictionary] ){ NSBeep(); [sender setState:[oldOption intValue]]; [currentPluginDictionary setObject:oldOption forKey:@"option"]; }
	
	[oldOption release]; [self resizeTrigger]; [pluginModules reloadData]; [self pushDefaults];
}

- (void) setcontrol:(NSButton*)sender
{
	NSNumber* oldControl = [[currentPluginDictionary objectForKey:@"control"] retain];
	[currentPluginDictionary setObject:[NSNumber numberWithInt:[sender state]] forKey:@"control"];
	
	if( [self settingsAreDuped:currentPluginDictionary] ){ NSBeep(); [sender setState:[oldControl intValue]]; [currentPluginDictionary setObject:oldControl forKey:@"control"]; }
	
	[oldControl release]; [self resizeTrigger]; [pluginModules reloadData]; [self pushDefaults];
}

- (void) setfunctionkey:(NSPopUpButton*)sender
{
	NSString* oldFuncKey = [[currentPluginDictionary objectForKey:@"functionkey"] retain];
	[currentPluginDictionary setObject:[[sender selectedItem] title] forKey:@"functionkey"];
	
	if( [self settingsAreDuped:currentPluginDictionary] ){ NSBeep(); [sender selectItemWithTitle:oldFuncKey]; [currentPluginDictionary setObject:oldFuncKey forKey:@"functionkey"]; }
	
	[oldFuncKey release]; [self resizeTrigger]; [pluginModules reloadData]; [self pushDefaults];
}

- (void) setmouseclick:(NSPopUpButton*)sender
{
	NSString* oldMouse = [[currentPluginDictionary objectForKey:@"mouseclick"] retain];
	[currentPluginDictionary setObject:[self popUpTagMouse:sender] forKey:@"mouseclick"];
	
	if( [self settingsAreDuped:currentPluginDictionary] ){ NSBeep(); [sender selectItemWithTag:[self mouseToTag:oldMouse]]; [currentPluginDictionary setObject:oldMouse forKey:@"mouseclick"]; }
	
	[oldMouse release];	[self resizeTrigger]; [pluginModules reloadData];	[self pushDefaults];
}

- (void) setType:(NSMatrix*)sender
{
	NSString* oldType = [[currentPluginDictionary objectForKey:@"actiontype"] retain];
	
	if( [sender cellWithTag:0] == [sender selectedCell] )
	    { [currentPluginDictionary setObject:@"Function Key" forKey:@"actiontype"]; }
	else{ [currentPluginDictionary setObject:@"Mouse Click" forKey:@"actiontype"]; }
	
	if( [self settingsAreDuped:currentPluginDictionary] )
	{
		NSBeep();
		
		if( [oldType isEqualToString:@"Function Key"] )
		    { [self performSelector:@selector(actionChange:) withObject:[NSNumber numberWithInt:0] afterDelay:0.0]; }
		else{ [self performSelector:@selector(actionChange:) withObject:[NSNumber numberWithInt:1] afterDelay:0.0]; }
		
		[currentPluginDictionary setObject:oldType forKey:@"actiontype"];
	}
	
	[oldType release]; [self resizeTrigger]; [pluginModules reloadData]; [self pushDefaults];
}

- (void) setfade:(NSButton*)sender
{
	[currentPluginDictionary setObject:[NSNumber numberWithInt:[sender state]] forKey:@"fade"];
	[currentPluginDictionary setObject:[NSNumber numberWithInt:[fadeAwaySeconds intValue]] forKey:@"fadesecs"];
	[self pushDefaults];
}
- (void) setfadesecs:(NSTextField*)sender
{
	[currentPluginDictionary setObject:[NSNumber numberWithInt:[fadeAwayButton state]] forKey:@"fade"];
	[currentPluginDictionary setObject:[NSNumber numberWithInt:[sender intValue]] forKey:@"fadesecs"];
	[self pushDefaults];
}

- (void) toggleStatus:(NSButton*)sender
{
	//printf("toggling\n");
	if( currentlyRunning )
	{
		[self setShuttingDown];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"LAshutdown" object:0L userInfo:0L deliverImmediately:YES];
	}
	else
	{
		[self setBootingUp];
		[[NSWorkspace sharedWorkspace] openFile:@"/Library/Application Support/Language Aid/Language Aid.app"];
	}
}

- (void) getSerial:(NSButton*)sender
{
	#ifndef SITELICENSED
	if( !registrationKey )
	{
		if( !currentlyRunning )
		{
			if( [[NSWorkspace sharedWorkspace] openFile:@"/Library/Application Support/Language Aid/Language Aid.app"] ){ serialBack = true; }else{ return; }
		}
		else
		{
			[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"needtehData" object:0L userInfo:0L deliverImmediately:YES];
		}
	}
	#endif
	
	[sender setHidden:YES];
}

- (void) changeLogin:(NSButton*)sender
{
	/*// The way to do it in 10.5
	if( LSSharedFileListCreate )
	{
		LSSharedFileListRef loginItems = LSSharedFileListCreate( NULL, kLSSharedFileListSessionLoginItems, NULL );
		CFURLRef thePath = (CFURLRef)[NSURL fileURLWithPath:@"/Library/Application Support/Language Aid/Language Aid.app"];
		UInt32 seedValue;
				
		NSArray* loginItemsArray = (NSArray*)LSSharedFileListCopySnapshot( loginItems, &seedValue );
		
		bool gotit = false;
		id item = nil;
		for( int i = 0; i < [loginItemsArray count]; i++ )
		{
			item = [loginItemsArray objectAtIndex:i];
			
			LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)item;
			
			CFURLRef itemPath = nil;

			if( LSSharedFileListItemResolve( itemRef, 0, (CFURLRef*)&itemPath, NULL ) == noErr )
			{
				if( [[(NSURL*)itemPath path] hasPrefix:@"/Library/Application Support/Language Aid/Language Aid.app"] )
				{
					LSSharedFileListItemRemove( loginItems, itemRef ); gotit = true;
				}
			}
		}
		
		[loginItemsArray release];
		
		if( !gotit )
		{
			LSSharedFileListItemRef item = LSSharedFileListInsertItemURL( loginItems, kLSSharedFileListItemLast, NULL, NULL, (CFURLRef)thePath, NULL, NULL );
			if( item ){ CFRelease( item ); }
		}

		CFRelease(loginItems);
	}*/
	
	// First try AppleScript
	
	
	
	NSDictionary* errorDict;
	NSAppleEventDescriptor* returnDescriptor = NULL;

	NSAppleScript* scriptObject = [[NSAppleScript alloc] initWithSource:@"tell application \"System Events\"\nrepeat with the_item in login items \nif path of the_item contains \"/Library/Application Support/Language Aid/Language Aid.app\" then\nreturn true\nend if\nend repeat\nreturn false\nend tell"];

	returnDescriptor = [scriptObject executeAndReturnError:&errorDict];
	[scriptObject release];

	if( returnDescriptor != NULL )
	{
		// It is there, turn it off
		if( [returnDescriptor booleanValue] )
		{
			scriptObject = [[NSAppleScript alloc] initWithSource:
				@"tell application \"System Events\"\nset the_index to 1\nrepeat with the_item in login items\nif path of the_item contains \"/Library/Application Support/Language Aid/Language Aid.app\" then\ndelete login item the_index\nset the_index to the_index - 1\nend if\nset the_index to the_index + 1\nend repeat\nend tell"];
		
			returnDescriptor = [scriptObject executeAndReturnError:&errorDict];
			[scriptObject release];
		}
		// It isn't there turn it on
		else
		{
			scriptObject = [[NSAppleScript alloc] initWithSource:
				@"tell application \"System Events\"\nif \"AddLoginItem\" is not in (name of every login item) then\nmake login item at end with properties {hidden:false, path:\"/Library/Application Support/Language Aid/Language Aid.app\"}\nend if\nend tell"];
		
			returnDescriptor = [scriptObject executeAndReturnError:&errorDict];
			[scriptObject release];
		}
	}

	if( returnDescriptor != NULL )
	{
		// successful execution
		if( kAENullEvent != [returnDescriptor descriptorType] ){ return; }
	}

	// Applescript failed, try the old fashioned way
	NSString* path = [[NSString stringWithString:@"~/Library/Preferences/loginwindow.plist"] stringByExpandingTildeInPath];
	//NSMutableArray* ALAD = [defaults objectForKey:@"AutoLaunchedApplicationDictionary" inDomain:@"loginwindow"];
	NSMutableDictionary* NSMD = [NSMutableDictionary dictionaryWithContentsOfFile:path];
	NSMutableArray* ALAD = [NSMD objectForKey:@"AutoLaunchedApplicationDictionary"];
	if( !ALAD ){ ALAD = [NSMutableArray array]; [NSMD setObject:ALAD forKey:@"AutoLaunchedApplicationDictionary"]; }
	
	#ifdef DEBUG
	//NSLog("NSMD: %x\n", NSMD);
	//NSLog("ALAD: %x\n", ALAD);
	#endif
	
	int foundindex = -1;
	
	int i;
	for( i = 0; i < [ALAD count]; i++ )
	{
		if( [[[ALAD objectAtIndex:i] objectForKey:@"Path"] isEqualToString:@"/Library/Application Support/Language Aid/Language Aid.app"] )
		{
			//NSLog([[ALAD objectAtIndex:i] objectForKey:@"Path"]);
			foundindex = i; break;
		}
	}
	
	if( [sender state] == NSOnState )
	{
		if( foundindex == -1 )
		{
			#ifdef DEBUG
			NSLog(@"trying to write\n");
			#endif
			NSMutableDictionary* MD = [[NSMutableDictionary alloc] init];
			//[MD setObject:[[NSNumber numberWithBool:NO] boolValue] forKey:@"Hide"];
			//[MD setBool:NO forKey:@"Hide"];
			//[MD setObject:@"No" forKey:@"Hide"];
			[MD setObject:[NSNumber numberWithBool:NO] forKey:@"Hide"];
			[MD setObject:@"/Library/Application Support/Language Aid/Language Aid.app" forKey:@"Path"];
			[ALAD addObject:MD];
			//[defaults setObject:ALAD forKey:@"AutoLaunchedApplicationDictionary" inDomain:@"loginwindow"];
			[NSMD writeToFile:path atomically:YES];
			[MD release];
		}
	}
	else if( [sender state] == NSOffState )
	{
		if( foundindex != -1 )
		{
			#ifdef DEBUG
			NSLog(@"trying to delete\n");
			#endif
			[ALAD removeObjectAtIndex:foundindex];
			//[defaults setObject:ALAD forKey:@"AutoLaunchedApplicationDictionary" inDomain:@"loginwindow"];
			[NSMD writeToFile:path atomically:YES];
		}
	}
}

- (void) supportClick:(NSButton*)sender
{
	if( registrationKey )
	{
		/*#ifdef DEBUG
		NSMutableString* daPage = [NSMutableString stringWithString:@"http://localhost/~snielsen/www.aorensoftware.com/LanguageAid/support.php?reg="];
		#else
		NSMutableString* daPage = [NSMutableString stringWithString:@"http://www.aorensoftware.com/LanguageAid/support.php?reg="];
		#endif
		//NSMutableString* daPage = [NSMutableString stringWithString:@"http://localhost/~snielsen/Aoren2/LanguageAid/support.php?reg="];
		[daPage appendString:registrationKey];
		[daPage appendFormat:@"&time=%d", supportTimes++];
		NSURL* supportPage = [NSURL URLWithString:daPage];
		[[NSWorkspace sharedWorkspace] openURL:supportPage];*/
		
		// Decided to forego the web interface for just plain emailing.
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[[NSString stringWithFormat:@"mailto:support@aorensoftware.com?subject=Language Aid Support TID: %@", [defaults objectForKey:@"TID"]] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]]]; 
	}
	else
	{
		#ifdef DEBUG
		NSLog(@"Shouldn't be here, no registrationKey\n");
		#endif
	}
}

- (void) uninstallClick:(NSButton*)sender
{
	int ret = NSRunAlertPanel( NSLocalizedStringFromTableInBundle(@"UNINSTALL", 0L, myBundle, 0L), NSLocalizedStringFromTableInBundle(@"UNINSTALLWARNING", 0L, myBundle, 0L), NSLocalizedStringFromTableInBundle(@"NO", 0L, myBundle, 0L), NSLocalizedStringFromTableInBundle(@"YES", 0L, myBundle, 0L), 0L );
			
	switch (ret)
	{
		case NSAlertDefaultReturn:   
		{
			
		} break;
		
		case NSAlertAlternateReturn:
		{
			// Shut Language Aid down
			if( currentlyRunning )
			{
				[self setShuttingDown];
				[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"LAshutdown" object:0L userInfo:0L deliverImmediately:YES];
			}


			// Remove the login item
			/*// The way to do it in 10.5
			if( LSSharedFileListCreate )
			{
				LSSharedFileListRef loginItems = LSSharedFileListCreate( NULL, kLSSharedFileListSessionLoginItems, NULL );
				UInt32 seedValue;
						
				NSArray* loginItemsArray = (NSArray*)LSSharedFileListCopySnapshot( loginItems, &seedValue );
				
				id item = nil;
				for( int i = 0; i < [loginItemsArray count]; i++ )
				{
					item = [loginItemsArray objectAtIndex:i];
					
					LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)item;
					
					CFURLRef itemPath = nil;

					if( LSSharedFileListItemResolve( itemRef, 0, (CFURLRef*)&itemPath, NULL ) == noErr )
					{
						if( [[(NSURL*)itemPath path] hasPrefix:@"/Library/Application Support/Language Aid/Language Aid.app"] )
						{
							LSSharedFileListItemRemove( loginItems, itemRef );
						}
					}
				}
				
				[loginItemsArray release];
				CFRelease(loginItems);
			}*/

			NSDictionary* errorDict;
			NSAppleEventDescriptor* returnDescriptor = NULL;

			NSAppleScript* scriptObject = [[NSAppleScript alloc] initWithSource:@"tell application \"System Events\"\nset the_index to 1\nrepeat with the_item in login items\nif path of the_item contains \"/Library/Application Support/Language Aid/Language Aid.app\" then\ndelete login item the_index\nset the_index to the_index - 1\nend if\nset the_index to the_index + 1\nend repeat\nend tell"];
		
			returnDescriptor = [scriptObject executeAndReturnError:&errorDict];
			[scriptObject release];

			if( returnDescriptor == NULL )
			{
				// Do it the old way
				NSString* path = [[NSString stringWithString:@"~/Library/Preferences/loginwindow.plist"] stringByExpandingTildeInPath];
				NSMutableDictionary* NSMD = [NSMutableDictionary dictionaryWithContentsOfFile:path];
				NSMutableArray* ALAD = [NSMD objectForKey:@"AutoLaunchedApplicationDictionary"];
				if( !ALAD ){ ALAD = [NSMutableArray array]; [NSMD setObject:ALAD forKey:@"AutoLaunchedApplicationDictionary"]; }
				
				#ifdef DEBUG
				//NSLog("NSMD: %x\n", NSMD);
				//NSLog("ALAD: %x\n", ALAD);
				#endif
				
				int foundindex = -1;
				
				int i;
				for( i = 0; i < [ALAD count]; i++ )
				{
					if( [[[ALAD objectAtIndex:i] objectForKey:@"Path"] isEqualToString:@"/Library/Application Support/Language Aid/Language Aid.app"] )
					{
						//NSLog([[ALAD objectAtIndex:i] objectForKey:@"Path"]);
						foundindex = i; break;
					}
				}
				
				if( foundindex != -1 )
				{
					#ifdef DEBUG
					NSLog(@"trying to delete\n");
					#endif
					[ALAD removeObjectAtIndex:foundindex];
					//[defaults setObject:ALAD forKey:@"AutoLaunchedApplicationDictionary" inDomain:@"loginwindow"];
					[NSMD writeToFile:path atomically:YES];
				}
			}


			// Authorized deletion
			OSStatus myStatus;
			AuthorizationFlags myFlags = kAuthorizationFlagDefaults;
			AuthorizationRef myAuthorizationRef;
		 
			myStatus = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, myFlags, &myAuthorizationRef);
			if( myStatus != errAuthorizationSuccess ){ return; }
		 
			AuthorizationItem myItems = {kAuthorizationRightExecute, 0, NULL, 0};
			AuthorizationRights myRights = {1, &myItems};
 
			myFlags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagPreAuthorize | kAuthorizationFlagExtendRights;
			myStatus = AuthorizationCopyRights( myAuthorizationRef, &myRights, NULL, myFlags, NULL );
 
			if( myStatus == errAuthorizationSuccess)
			{
				char myToolPath[] = "/Library/Application Support/Language Aid/uninstall";
				char *myArguments[] = { "", NULL };
				//FILE *myCommunicationsPipe = NULL;
				//char myReadBuffer[128];
	 
				myFlags = kAuthorizationFlagDefaults;
				//myStatus = AuthorizationExecuteWithPrivileges(myAuthorizationRef, myToolPath, myFlags, myArguments,	&myCommunicationsPipe);
				myStatus = AuthorizationExecuteWithPrivileges( myAuthorizationRef, myToolPath, myFlags, myArguments, NULL );
				
				/*if( myStatus == errAuthorizationSuccess )
				{
					for(;;)
					{
						int bytesRead = read (fileno (myCommunicationsPipe), myReadBuffer, sizeof (myReadBuffer));
						if( bytesRead < 1 ){ break; }
						write(fileno (stdout), myReadBuffer, bytesRead);
					}
				}*/
			}
		 
			AuthorizationFree( myAuthorizationRef, kAuthorizationFlagDefaults );
		 
			if( myStatus )
			{
				#ifdef DEBUG
				printf("Status: %ld\n", myStatus);
				#endif
			}
	
			[NSApp terminate:self];
		} break;
		
		case NSAlertOtherReturn:
		{
		
		} break;
		
		default: { } break;
	}
}

- (void) upgradeClick:(NSButton*)sender
{
	#ifndef SITELICENSED
		#ifdef DEBUG
		//[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://localhost/~snielsen/www.aorensoftware.com/Downloads/Files/LanguageAid.dmg"]];
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://localhost/~snielsen/www.aorensoftware.com/LanguageAid/"]];
		#else
		//[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.aorensoftware.com/Downloads/Files/LanguageAid.dmg"]];
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.aorensoftware.com/LanguageAid/"]];
		#endif
	#endif
}

- (void) copyrightClick:(NSButton*)sender
{
	#ifdef DEBUG
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://localhost/~snielsen/www.aorensoftware.com/LanguageAid/"]];
	#else
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.aorensoftware.com/LanguageAid/"]];
	#endif
}

- (void) unsignedClick:(NSButton*)sender
{	
	unsignedOK = [sender state];
	[defaults setObject:[NSNumber numberWithInt:[sender state]] forKey:@"unsignedOK"];
	
	if( unsignedOK )
	{
		// Ungrey the unsigned module's checkboxes
		/*[LAPluginsLock lock];
			for( int numplugins = [loadedLAPlugins count]; numplugins != 0; numplugins-- )
			{
				LAPluginReference* PMR = (LAPluginReference*)[loadedLAPlugins objectAtIndex:numplugins - 1];
				
				if( !PMR->aorensigned )
				{
					NSTableColumn* TC = [pluginModules tableColumnWithIdentifier:@"Enabled"];
					NSButtonCell* BC = [TC dataCellForRow:numplugins];
					
					[BC setEnabled:YES];
				}
			}
		[LAPluginsLock unlock];*/
		
		NSArray* newMods = [thePM reload];
		[newMods release];
		
		if( unsignedWarned == 0 )
		{
			unsignedWarned = 1;
			[defaults setObject:[NSNumber numberWithInt:unsignedWarned] forKey:@"unsignedWarned"];
			
			NSRunAlertPanel( NSLocalizedStringFromTableInBundle(@"UNSIGNEDTOGGLE", 0L, myBundle, 0L), NSLocalizedStringFromTableInBundle(@"UNSIGNEDWARNING", 0L, myBundle, 0L), NSLocalizedStringFromTableInBundle(@"OK", 0L, myBundle, 0L), 0L, 0L );
		}
	}
	else
	{
		// Disable the unsigned module's checkboxes
		[LAPluginsLock lock];
			for( int numplugins = [loadedLAPlugins count]; numplugins != 0; numplugins-- )
			{
				LAPluginReference* PMR = (LAPluginReference*)[loadedLAPlugins objectAtIndex:numplugins - 1];
				
				if( !PMR->aorensigned )
				{
					NSMutableDictionary* thisModulesTriggers = [Triggers objectForKey:PMR->name];
					if( thisModulesTriggers )
					{
						[thisModulesTriggers setObject:[NSNumber numberWithInt:0] forKey:@"Enabled"];
						[Triggers setObject:thisModulesTriggers forKey:PMR->name];
						[defaults setObject:Triggers forKey:@"Triggers"];
					}
				}
			}
		[LAPluginsLock unlock];
	}
	
	[pluginModules reloadData];
	
	[defaults synchronize];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"defaultsChanged" object:0L userInfo:0L deliverImmediately:YES];
}

- (void) pluginClick:(NSTableView*)sender
{

}

- (void) enabledClick:(NSTableView*)sender
{

}

- (void) upgradeModulesClick:(NSButton*)sender
{
	[LAPluginsLock lock];
	
	int ret = NSRunAlertPanel( NSLocalizedStringFromTableInBundle(@"UPGRADEALL", 0L, myBundle, 0L), NSLocalizedStringFromTableInBundle(@"UPGRADEALLDIALOG", 0L, myBundle, 0L), NSLocalizedStringFromTableInBundle(@"YES", 0L, myBundle, 0L), NSLocalizedStringFromTableInBundle(@"NO", 0L, myBundle, 0L), 0L );
	switch (ret)
	{
		case NSAlertDefaultReturn:   
		{
			[upgradeModulesButton setHidden:YES];
			[upgradeStatus setHidden:NO];
			[upgradeProgress setMaxValue:[loadedLAPlugins count]];
			[upgradeProgress setDoubleValue:0.0];
			[upgradeProgress setHidden:NO];
				
			LAPluginReference* PMR = 0L;

			OSStatus myStatus;
			AuthorizationFlags myFlags = kAuthorizationFlagDefaults;
			AuthorizationRef myAuthorizationRef;
		 
			myStatus = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, myFlags, &myAuthorizationRef);
			if( myStatus != errAuthorizationSuccess ){ return; }
		 
			AuthorizationItem myItems = {kAuthorizationRightExecute, 0, NULL, 0};
			AuthorizationRights myRights = {1, &myItems};

			myFlags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagPreAuthorize | kAuthorizationFlagExtendRights;
			myStatus = AuthorizationCopyRights( myAuthorizationRef, &myRights, NULL, myFlags, NULL );
			
			if( myStatus == errAuthorizationSuccess)
			{
				for( int m = 0; m < [loadedLAPlugins count]; m++ )
				{
					PMR = [loadedLAPlugins objectAtIndex:m];
					
					if( PMR->newversion )
					{
						int ures = [PMR upgrade:myAuthorizationRef];
						if( ures == DOWNLOADPROBLEM )
						{
							NSRunAlertPanel( [NSString stringWithFormat:@"%@ - %@", PMR->name, NSLocalizedStringFromTableInBundle(@"BADDOWNLOAD", 0L, myBundle, 0L)], NSLocalizedStringFromTableInBundle(@"DOWNLOADFAILED", 0L, myBundle, 0L), NSLocalizedStringFromTableInBundle(@"OK", 0L, myBundle, 0L), 0L, 0L );
						}
					}
					
					[upgradeProgress incrementBy:1.0];
				}
			}
			
			if( currentlyRunning )
			{
				[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"LAshutdown" object:0L userInfo:0L deliverImmediately:YES];
				
				sleep(2);
				
				[self setBootingUp];
				[[NSWorkspace sharedWorkspace] openFile:@"/Library/Application Support/Language Aid/Language Aid.app"];
			}
			else
			{
				[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"LAshutdown" object:0L userInfo:0L deliverImmediately:YES];
			}
			
			AuthorizationFree( myAuthorizationRef, kAuthorizationFlagDefaults );
			
			[self resizeTrigger]; [pluginModules reloadData];
			
			[upgradeStatus setHidden:YES];
			[upgradeProgress setHidden:YES];
				
			// Check if there are any others that can upgraded
			bool anyupgradable = false;
			for( int m = 0; m < [loadedLAPlugins count]; m++ )
			{
				PMR = [loadedLAPlugins objectAtIndex:m];
				
				if( PMR->newversion )
				{
					anyupgradable = true;
				}
			}
			
			if( anyupgradable ){ [upgradeModulesButton setHidden:NO]; }else{ [upgradeModulesButton setHidden:YES]; }
			
			[LAPluginsLock unlock];
		} break;
		
		case NSAlertAlternateReturn:
		{
			return;
		} break;
		
		case NSAlertOtherReturn: { } break;
		default: { } break;
	}
	
	safeToJump = true;
	pthread_cond_signal( &repcond );
	[LAPluginsLock unlock];
}

- (void) addnewModulesClick:(NSButton*)sender
{
	[NSApp runModalForWindow:newModWindow];
}

#pragma mark Overridden

- (void) mainViewDidLoad
{
	aorenlogo = [[NSImage alloc] initWithContentsOfFile:[myBundle pathForResource:@"aorenlogo" ofType:@"jpg"]];
	unsignedImage = [[NSImage alloc] initWithContentsOfFile:[myBundle pathForResource:@"unsignedImage" ofType:@"bmp"]];
	
	NSRect screenRect = [[NSScreen mainScreen] frame];
	
	//PPHeight = screenRect.size.height - 400;
	PPHeight = screenRect.size.height - 455;
	
	if( PPHeight > 740 ){ PPHeight = 740; }
	
	//printf("height: %f\n", screenRect.size.height);
	//PPHeight = 600;

	//WebFrame* WF = [paymentView mainFrame];
	//WebFrameView* WFV = [WF frameView];
	//NSRect F = [WFV frame];
	//F.size.height = PPHeight - 300;
	//[WFV setFrame:F];
	
	/*NSRect F = [paymentView frame];
	F.size.height = PPHeight;
	[paymentView setFrame:F];*/
	
	//NSWindow* HW = [paymentView hostWindow];
	//NSRect daRec = [HW frame];
	//daRec.size.height = PPHeight;
	//[HW setFrame:daRec display:YES];

	/*system("rm /tmp/JAidthing");
	//int yes = 1;
	//setsockopt( s, SOL_SOCKET, SO_NOSIGPIPE, &yes, sizeof(int) );
	//setsockopt( s, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(int) );
	
	int s = socket(AF_UNIX, SOCK_STREAM, 0);
	
	struct sockaddr_un addr; 

	strcpy(addr.sun_path, "/tmp/JAidthing"); 
	addr.sun_family = AF_UNIX; 
	int res = bind(s, (struct sockaddr *) &addr, strlen(addr.sun_path) + sizeof(addr.sun_len) + sizeof(addr.sun_family));
	res = listen( s, 5 );
	res = fcntl( s, F_SETFL, 0 );
	
	pthread_t dathread = 0L;
	pthread_create( &dathread, 0L, regthread, self );

	struct sockaddr_un from; 
	socklen_t fromlen = sizeof (from); 
	regThreadSocket = accept(s, (struct sockaddr *)&from, &fromlen);*/
	
	////

	//transaction = [[NSMutableString alloc] init];
	
	[key setToolTip:NSLocalizedStringFromTableInBundle(@"TRIGGERCONFLICT", 0L, myBundle, 0L)];
	[mouse setToolTip:NSLocalizedStringFromTableInBundle(@"TRIGGERCONFLICT", 0L, myBundle, 0L)];

	[unsignedPlugins setToolTip:NSLocalizedStringFromTableInBundle(@"UNSIGNEDTOOLTIP", 0L, myBundle, 0L)];

	standardDefaults = [NSUserDefaults standardUserDefaults];
	defaults = [[LAUserDefaults alloc] initWithDomain:@"com.aoren.LanguageAid"];
	
	id val = [defaults objectForKey:@"unsignedWarned"]; if( val ){ unsignedWarned = [val intValue]; }else{ unsignedWarned = 0; }
	val = [defaults objectForKey:@"unsignedOK"];	if( val ){ [unsignedPlugins setState:[val intValue]]; unsignedOK = [val intValue]; }else{ [unsignedPlugins setState:NSOffState]; unsignedOK = 0; }
	
	[[NSURLCache sharedURLCache] setDiskCapacity:0];
	
	//initRegistration();
	
	currentlyRunning = false;
	serialBack = false;
	expanded = false;
	
	shuttingDown = false;
	registering = false;
	
	supportTimes = 0;
	
	currentPlugin = 0L;
	currentPluginDictionary = 0L;
	
	Triggers = 0L;

	[[fadeAwaySeconds cell] setFormatter:[[JustNumFormatter alloc] init]];

	//printf( "mainViewDidLoad unsignedOK: %d\n", unsignedOK );
	
	//LoadLAPlugins(); // moved to below
	
	#ifndef SITELICENSED
	[NSThread detachNewThreadSelector:@selector(checkupgrade:) toTarget:self withObject:0L];
	#endif
	
	[pluginModules setDataSource:self];
	[pluginModules setDelegate:self];
	
	[pluginModules registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
	
	[self disableTrigger];
}

- (void) willSelect
{
	if( !initdonce )
	{
		initdonce = true;
		
		// Set the displayable version in the pref pane
		[versionField setTitleWithMnemonic:[NSString stringWithFormat:@"v%@", [[myBundle infoDictionary] objectForKey:@"CFBundleShortVersionString"]]];
		
		/*id val = 0L;
			
			val = [defaults objectForKey:@"functionkey"		];	if( val ){ [key selectItemWithTitle:val];     }else{ [key selectItemWithTitle:DEFAULTKEYTRIGGER];               }
			val = [defaults objectForKey:@"mouseclick"		];	if( val ){ [mouse selectItemWithTitle:val];   }else{ [mouse selectItemWithTitle:@"Mouse Button 3"]; }
			val = [defaults objectForKey:@"command"			];	if( val ){ [command setState:[val intValue]]; }else{ [command setState:NSOffState];                 }
			val = [defaults objectForKey:@"shift"			];	if( val ){ [shift setState:[val intValue]];   }else{ [shift setState:NSOffState];                   }
			val = [defaults objectForKey:@"option"			];	if( val ){ [option setState:[val intValue]];  }else{ [option setState:NSOffState];                  }
			val = [defaults objectForKey:@"control"			];	if( val ){ [control setState:[val intValue]]; }else{ [control setState:NSOffState];                 }
			val = [defaults objectForKey:@"fade"			];	if( val ){ [fadeAwayButton setState:[val intValue]];   }else{ [fadeAwayButton setState:NSOffState]; }
			val = [defaults objectForKey:@"fadesecs"		];	if( val ){ [fadeAwaySeconds setIntValue:[val intValue]]; }else{ [fadeAwaySeconds setIntValue:60]; }
			val = [defaults objectForKey:@"actiontype"		];
			if( val ){ if( [val isEqualToString:@"Mouse Click"] ){ [actiontype selectCellWithTag:1]; } else if( [val isEqualToString:@"Function Key"] ){ [actiontype selectCellWithTag:0]; } }else{ [actiontype selectCellWithTag:0]; }*/

		NSDictionary* daTr = [defaults objectForKey:@"Triggers"];

		Triggers = [[NSMutableDictionary alloc] initWithDictionary:daTr];

		// Make all the sub dicts mutable
		NSArray* aKeys = [Triggers allKeys];
		for( int i = 0; i < [aKeys count]; i++ )
		{
			NSString* daKey = [aKeys objectAtIndex:i];
			NSMutableDictionary* mut = [NSMutableDictionary dictionaryWithDictionary:[Triggers objectForKey:daKey]];
			[Triggers setObject:mut forKey:daKey];
		}

		// If there were no saved Triggers then this is probably the first time the pref pane has ever been launched.  If we are upgrading, do the nice thing and set up WWWJDIC for them
		if( !daTr )
		{
			firsteverload = true;
			
			NSMutableDictionary* wwwjdicTrigger = [NSMutableDictionary dictionary];
			id val = 0L;
			bool gotany = false;
			
			val = [defaults objectForKey:@"functionkey"	];	if( val ){ gotany = true; [wwwjdicTrigger setObject:val forKey:@"functionkey"]; }else{ [wwwjdicTrigger setObject:DEFAULTKEYTRIGGER forKey:@"functionkey"];        }
			val = [defaults objectForKey:@"mouseclick"	];	if( val ){ gotany = true; [wwwjdicTrigger setObject:val forKey:@"mouseclick"];  }else{ [wwwjdicTrigger setObject:@"Mouse Button 3" forKey:@"mouseclick"];         }
			val = [defaults objectForKey:@"command"		];	if( val ){ gotany = true; [wwwjdicTrigger setObject:val forKey:@"command"];     }else{ [wwwjdicTrigger setObject:[NSNumber numberWithInt:0] forKey:@"command"];   }
			val = [defaults objectForKey:@"shift"		];	if( val ){ gotany = true; [wwwjdicTrigger setObject:val forKey:@"shift"];       }else{ [wwwjdicTrigger setObject:[NSNumber numberWithInt:0] forKey:@"shift"];     }
			val = [defaults objectForKey:@"option"		];	if( val ){ gotany = true; [wwwjdicTrigger setObject:val forKey:@"option"];      }else{ [wwwjdicTrigger setObject:[NSNumber numberWithInt:0] forKey:@"option"];    }
			val = [defaults objectForKey:@"control"		];	if( val ){ gotany = true; [wwwjdicTrigger setObject:val forKey:@"control"];     }else{ [wwwjdicTrigger setObject:[NSNumber numberWithInt:0] forKey:@"control"];   }
			val = [defaults objectForKey:@"fade"		];	if( val ){ gotany = true; [wwwjdicTrigger setObject:val forKey:@"fade"];        }else{ [wwwjdicTrigger setObject:[NSNumber numberWithInt:0] forKey:@"fade"];      }
			val = [defaults objectForKey:@"fadesecs"	];	if( val ){ gotany = true; [wwwjdicTrigger setObject:val forKey:@"fadesecs"];    }else{ [wwwjdicTrigger setObject:[NSNumber numberWithInt:60] forKey:@"fadesecs"]; }
			val = [defaults objectForKey:@"actiontype"	];  if( val ){ gotany = true; [wwwjdicTrigger setObject:val forKey:@"actiontype"];  }else{ [wwwjdicTrigger setObject:@"Function Key" forKey:@"actiontype"];           }
			
			if( gotany )
			{
				[wwwjdicTrigger setObject:[NSNumber numberWithBool:YES] forKey:@"Enabled"];
				
				[Triggers setObject:wwwjdicTrigger forKey:@"WWWJDIC"];
				[defaults setObject:Triggers forKey:@"Triggers"];
				[defaults synchronize];
				[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"defaultsChanged" object:0L userInfo:0L deliverImmediately:YES];
			}
		}

		LoadLAPlugins();
		
		// Here check if unsigned plugins are OK, if not then we need to change the state of the unsigned module's "Enabled" status
		if( !unsignedOK )
		{
			// Grey the unsigned module's checkboxes and uncheck those that are enabled
			[LAPluginsLock lock];
				for( int numplugins = [loadedLAPlugins count]; numplugins != 0; numplugins-- )
				{
					LAPluginReference* PMR = (LAPluginReference*)[loadedLAPlugins objectAtIndex:numplugins - 1];
					
					if( !PMR->aorensigned )
					{
						NSMutableDictionary* thisModulesTriggers = [Triggers objectForKey:PMR->name];
						if( thisModulesTriggers )
						{
							NSString* t = [PMR->pluginClass Title];
							if( t && ![t isEqualToString:@""] ){	[thisModulesTriggers setObject:t forKey:@"title"]; }
							[thisModulesTriggers setObject:[NSNumber numberWithInt:0] forKey:@"Enabled"];
							
							[Triggers setObject:thisModulesTriggers forKey:PMR->name];
							[defaults setObject:Triggers forKey:@"Triggers"];
							[defaults synchronize];
							[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"defaultsChanged" object:0L userInfo:0L deliverImmediately:YES];
						}
					}
				}
			[LAPluginsLock unlock];
		}
		
		
		
		
		// Go through all the loaded plugins and write in their title to their trigger prefs (for the CMI to pick up on) // Maybe don't need anymore because it is being written now everytime Enabled is pushed?
		[LAPluginsLock lock];
			for( int numplugins = [loadedLAPlugins count]; numplugins != 0; numplugins-- )
			{
				LAPluginReference* PMR = (LAPluginReference*)[loadedLAPlugins objectAtIndex:numplugins - 1];
				
				if( PMR->isLoaded && PMR->pluginClass )
				{
					if( [PMR->pluginClass respondsToSelector:@selector(Title)] )
					{
						NSString* t = [PMR->pluginClass Title];
						
						if( t && ![t isEqualToString:@""] )
						{
							NSMutableDictionary* thisModulesTriggers = [Triggers objectForKey:PMR->name];
							if( thisModulesTriggers )
							{
								[thisModulesTriggers setObject:t forKey:@"title"];
								[Triggers setObject:thisModulesTriggers forKey:PMR->name];
								[defaults setObject:Triggers forKey:@"Triggers"];
							}
						}
					}
				}
			}
			
			[defaults synchronize];
			[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"defaultsChanged" object:0L userInfo:0L deliverImmediately:YES];
		[LAPluginsLock unlock];
		
		
				

		
		//printf( "willSelect unsignedOK: %d\n", unsignedOK );
	
		[self getRegistration];
	}
	
	InstallEventLoopTimer( GetCurrentEventLoop(), 0, kEventDurationSecond * 3, NewEventLoopTimerUPP( checkProcessStatus ), self, &checkTimer );
	
	if( [self getLogin] ){ [enableAtLogin setState:NSOnState]; }else{ [enableAtLogin setState:NSOffState]; }
	
	[self queryRunning];
	
	[self resizeTrigger];
}

- (void) didSelect
{
	if( expanded )
	{
		NSView* v = [self mainView];
		[v setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
		NSWindow* w = [v window];
		NSRect f = [w frame];
		f.size.width = 832;
		[w setFrame:f display:YES animate:YES];
	}
	
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(aidRunning:) name:@"aidRunning" object:0L];
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(aidDying:) name:@"aidDying" object:0L];
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(tehData:) name:@"tehData" object:0L];
	
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(repChanged:) name:REPCHANGEDNOTIFY object:0L]; // Only need the notification in this process-space, but done distributed so it is answered in the main thread.
	//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(regthread:) name:@"regthread" object:0L];
	
	[self tableViewSelectionDidChange:0L];
	
	if( firsteverload )
	{
		[self setBootingUp];
		[[NSWorkspace sharedWorkspace] openFile:@"/Library/Application Support/Language Aid/Language Aid.app"];
	}
}

- (void) willUnselect
{
	//[paymentView setFrameLoadDelegate:0L];
	//if( checkTimer ){ RemoveEventLoopTimer( checkTimer ); checkTimer = 0L; }
}

- (void) didUnselect
{
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:@"aidRunning" object:0L];
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:@"aidDying" object:0L];
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:@"tehData" object:0L];
	//[[NSNotificationCenter defaultCenter] removeObserver:self name:@"regthread" object:0L];

	if( checkTimer ){ RemoveEventLoopTimer( checkTimer ); checkTimer = 0L; }
}

@end