// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import "LanguageAidCMI.h"

#import "GetPID.h"

#pragma mark -
#pragma mark Helper Functions

static LanguageAidCMIType* AllocLanguageAidCMIType( CFUUIDRef inFactoryID )
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
		// Allocate memory for the new instance.
		LanguageAidCMIType* theNewInstance = (LanguageAidCMIType*)malloc( sizeof(LanguageAidCMIType) );

		// Point to the function table
		theNewInstance->cmInterface = &LanguageAidCMIInterface;

		// Retain and keep an open instance refcount< for each factory.
		theNewInstance->factoryID = (CFUUIDRef)CFRetain( inFactoryID );
		CFPlugInAddInstanceForFactory( inFactoryID );

		// This function returns the IUnknown interface so set the refCount to one.
		theNewInstance->refCount = 1;
		theNewInstance->LACMI = [[LanguageAidCMI alloc] init];
	
	[pool release];
	
	return theNewInstance;
}

static void DeallocLanguageAidCMIType( void* thisInstance )
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
		CFUUIDRef theFactoryID = ((LanguageAidCMIType*)thisInstance)->factoryID;
		
		[((LanguageAidCMIType*)thisInstance)->LACMI release];
		
		free( thisInstance );
		
		if( theFactoryID )
		{
			CFPlugInRemoveInstanceForFactory( theFactoryID );
			CFRelease( theFactoryID );
		}
	
	[pool release];
}

static ULONG LanguageAidCMIAddRef( void *thisInstance )
{
	((LanguageAidCMIType*)thisInstance)->refCount += 1;
	
	return ((LanguageAidCMIType*)thisInstance)->refCount;
}

static ULONG LanguageAidCMIRelease( void* thisInstance )
{
	((LanguageAidCMIType*)thisInstance)->refCount -= 1;
	
	if( ((LanguageAidCMIType*)thisInstance)->refCount == 0 )
	{
		DeallocLanguageAidCMIType( thisInstance );
		return 0;
	}
	else
	{
		return ((LanguageAidCMIType*)thisInstance)->refCount;
	}
}

void* LanguageAidCMIFactory( CFAllocatorRef allocator, CFUUIDRef typeID )
{
	// If correct type is being requested, allocate an instance of TestType and return the IUnknown interface.
	if( CFEqual( typeID, kContextualMenuTypeID ) )
	{
		LanguageAidCMIType *result;
		result = AllocLanguageAidCMIType( kLanguageAidCMIFactoryID );
		return result;
	}
	else
	{
		// If the requested type is incorrect, return NULL.
		return NULL;
	}
}

static HRESULT LanguageAidCMIQueryInterface( void* thisInstance, REFIID iid, LPVOID* ppv )
{
	// Create a CoreFoundation UUIDRef for the requested interface.
	CFUUIDRef interfaceID = CFUUIDCreateFromUUIDBytes( NULL, iid );

	// Test the requested ID against the valid interfaces.
	if( CFEqual( interfaceID, kContextualMenuInterfaceID ) )
	{
		// If the LanguageAidCMIInterface was requested, bump the ref count, set the ppv parameter equal to the instance, and return good status.
		LanguageAidCMIAddRef( thisInstance );

		*ppv = thisInstance;
		CFRelease( interfaceID );
		return S_OK;
	}
	else if( CFEqual( interfaceID, IUnknownUUID ) )
	{
		// If the IUnknown interface was requested, same as above.
		LanguageAidCMIAddRef( thisInstance );

		*ppv = thisInstance;
		CFRelease( interfaceID );
		return S_OK;
	}
	else
	{
		// Requested interface unknown, bail with error.
		*ppv = NULL;
		CFRelease( interfaceID );
		return E_NOINTERFACE;
	}
}

#pragma mark -
#pragma mark The Main Functions

static OSStatus LanguageAidCMIExamineContext( void* thisInstance, const AEDesc* inContext, AEDescList* outCommandPairs )
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
		//NSAppleEventDescriptor* context = [[NSAppleEventDescriptor alloc] initWithAEDescNoCopy:inContext];
		//NSAppleEventDescriptor* commandPairs = [[NSAppleEventDescriptor alloc] initWithAEDescNoCopy:outCommandPairs];

		if( [((LanguageAidCMIType*)thisInstance)->LACMI hasSelectedText] )
		{
			NSAppleEventDescriptor* superCommand = [((LanguageAidCMIType*)thisInstance)->LACMI CreateMenus];

			AEPutDesc( outCommandPairs, 0, [superCommand aeDesc] );
		}

		//[context release];

	[pool release];

	return noErr;
}

static OSStatus LanguageAidCMIHandleSelection( void* thisInstance, AEDesc* inContext, SInt32 inCommandID )
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
		//NSAppleEventDescriptor* context = [[NSAppleEventDescriptor alloc] initWithAEDescNoCopy:inContext];

		//DescType thetype = [context descriptorType];

		//[((LanguageAidCMIType*)thisInstance)->LACMI hitMenu:inCommandID context:context];
		[((LanguageAidCMIType*)thisInstance)->LACMI hitMenu:inCommandID];
		
		//[context release];
	
	[pool release];

	return noErr;
}

static void LanguageAidCMIPostMenuCleanup( void* thisInstance )
{
	//NSLog(@"got here\n");
}

#pragma mark -
#pragma mark LanguageAidCMI

@implementation LanguageAidCMI

- (id) init
{
	self = [super init];
	
	if( self )
	{
		defaults = [[LAUserDefaults alloc] initWithDomain:@"com.aoren.LanguageAid"];
		
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultsChanged:) name:@"defaultsChanged" object:0L];
		
		Triggers = [[NSMutableDictionary alloc] initWithDictionary:[defaults objectForKey:@"Triggers"]];
	}
	
	return self;
}

- (void) dealloc
{
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:@"defaultsChanged" object:0L];
	
	[defaults release];
	
	[Triggers release];

	[super dealloc];
}

- (void) defaultsChanged:(NSNotification*)N
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		
		//NSLog(@"Detected defaults changed for LANGUAGE AID.\n");
		
		[defaults synchronize];

	[pool release];
}

- (NSAppleEventDescriptor*) CreateMenus
{
	// For some reason the notification doesn't get delivered always.  Re-register it real quick in case it got lost
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:@"defaultsChanged" object:0L];
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultsChanged:) name:@"defaultsChanged" object:0L];

	NSAppleEventDescriptor* superCommand = [NSAppleEventDescriptor recordDescriptor];
	NSAppleEventDescriptor* submenuCommands = [NSAppleEventDescriptor listDescriptor];

	if( Triggers ){ [Triggers release]; }
	Triggers = [[NSMutableDictionary alloc] initWithDictionary:[defaults objectForKey:@"Triggers"]];
	
	NSArray* mods = [Triggers allValues];
	NSArray* keys = [Triggers allKeys];
	
	for( int a = 0; a < [mods count]; a++ )
	{
		NSString* mKey = [keys objectAtIndex:a];
		NSDictionary* T = [mods objectAtIndex:a];
		
		NSNumber* isenabled = [T objectForKey:@"Enabled"];
		NSNumber* isloaded = [T objectForKey:@"Loaded"];
		NSString* title = [T objectForKey:@"title"];
		
		if( isenabled && [isenabled intValue] && isloaded && [isloaded intValue] )
		{
			NSAppleEventDescriptor* commandRecord = [NSAppleEventDescriptor recordDescriptor];
			if( title ){ [commandRecord setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:title] forKeyword:keyAEName]; }
			       else{ [commandRecord setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:mKey] forKeyword:keyAEName]; }
			[commandRecord setParamDescriptor:[NSAppleEventDescriptor descriptorWithInt32:a] forKeyword:keyContextualMenuCommandID];
			[submenuCommands insertDescriptor:commandRecord atIndex:0];
		}
	}
	
	[superCommand setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:@"Language Aid"] forKeyword:keyAEName];
	[superCommand setParamDescriptor:submenuCommands forKeyword:keyContextualMenuSubmenu];

	
	return superCommand;
}

- (bool) hasSelectedText
{
	/*NSString* contextString = [context stringValue];

	if( contextString )
	{
		return true;
	}
	else
	{*/
		NSApplication* app = [NSApplication sharedApplication];
		
		if( app )
		{
			NSWindow* keywin = [app keyWindow];
			
			if( keywin )
			{
				id firstResponder = [keywin firstResponder];
				
				if( firstResponder )
				{
					id validRequestor = 0L;
					
					if( validRequestor = [firstResponder validRequestorForSendType:NSStringPboardType returnType:nil] )
					{
						return true;
					}
					else if( validRequestor = [firstResponder validRequestorForSendType:NSTabularTextPboardType returnType:nil] )
					{
						return true;
					}
				}
			}
		}
	//}

	return false;
}

- (void) hitMenu:(int)menuid
{
	int laidProc = GetPIDForProcessName("Language Aid");

	if( laidProc == -1 )
	{
		if( [[NSWorkspace sharedWorkspace] openFile:@"/Library/Application Support/Language Aid/Language Aid.app"] )
		{
			sleep(3);
			laidProc = GetPIDForProcessName("Language Aid");
			
			if( laidProc == -1 ){ NSLog(@"For some reason the Language Aid cannot be enabled.\n"); return; }
		}
		else{ NSLog(@"For some reason the Language Aid cannot be launched.\n"); return; }
	}

	NSArray* keys = [Triggers allKeys];
	NSString* mKey = [keys objectAtIndex:menuid];
	
	//NSPasteboard* servicePasteboard = [[NSPasteboard pasteboardWithUniqueName] retain];
	//NSPasteboard* servicePasteboard = [NSPasteboard pasteboardWithUniqueName];
	NSPasteboard* servicePasteboard = [[NSPasteboard pasteboardWithName:@"Language Aid"] retain];
	
	//[[[[[NSApplication sharedApplication] keyWindow] firstResponder] validRequestorForSendType:NSStringPboardType returnType:nil] writeSelectionToPasteboard:[NSPasteboard generalPasteboard] type:NSStringPboardType];
	
	//NSString* contextString = [context stringValue];
	NSString* contextString = 0L;
	
	bool gotdata = false;
	
	/*if( contextString )
	{
		[servicePasteboard setString:contextString forType:NSStringPboardType];
		gotdata = true;
	}
	else
	{*/
		NSApplication* app = [NSApplication sharedApplication];
		
		if( app )
		{
			NSWindow* keywin = [app keyWindow];
			
			if( keywin )
			{
				id firstResponder = [keywin firstResponder];
				
				if( firstResponder )
				{
					id validRequestor = 0L;
						
					if( validRequestor = [firstResponder validRequestorForSendType:NSStringPboardType returnType:nil] )
					{
						[validRequestor writeSelectionToPasteboard:servicePasteboard types:[NSArray arrayWithObjects:NSStringPboardType, 0L]];
						//id blah = [servicePasteboard dataForType:NSStringPboardType];
						contextString = [servicePasteboard stringForType:NSStringPboardType];
						gotdata = true;
					}
					else if( validRequestor = [firstResponder validRequestorForSendType:NSTabularTextPboardType returnType:nil] )
					{
						[validRequestor writeSelectionToPasteboard:servicePasteboard types:[NSArray arrayWithObjects:NSTabularTextPboardType, 0L]];
						contextString = [servicePasteboard stringForType:NSTabularTextPboardType];
						gotdata = true;
					}
				}
			}
		}
	//}
	
	if( gotdata )
	{
		id LAIDServiceProxy = [NSConnection rootProxyForConnectionWithRegisteredName:[NSString stringWithFormat:@"Language Aid Lookup-%d", laidProc] host:nil];
		
		if( !LAIDServiceProxy )
		{
			sleep(3); // Give it a wee more time
			LAIDServiceProxy = [NSConnection rootProxyForConnectionWithRegisteredName:[NSString stringWithFormat:@"Language Aid Lookup-%d", laidProc] host:nil];
		}
		
		if( LAIDServiceProxy )
		{
			[LAIDServiceProxy lookup:contextString module:mKey];
		}
		else
		{
			NSLog(@"For some reason the Language Aid service for this user cannot be contacted.\n");
		}
	}
	else
	{
		NSLog(@"For some reason the contextual menu plugin could not get any text.\n");
	}
	
	[servicePasteboard release];
}

@end
