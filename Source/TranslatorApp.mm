// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import "TranslatorApp.h"

#import <unistd.h>

TranslatorApp*					TApp = 0L;
LAUserDefaults*					defaults = 0L;

static pascal void highlightPressed( EventLoopTimerRef inTimer, void* userData )
{
	LanguageInspector* LI = (LanguageInspector*)userData;
	
	// THIS HERE ENABLES THE HIGHLIGHT DRAWING
	LI->holdValid = true;
	LI->highLightFade = 1;
	[LI highlightPressed];
}

pascal OSStatus modsChangedCallback( EventHandlerCallRef nextHandler, EventRef event, void* userData )
{//NSLog(@"got here\n");
	EventHotKeyID key;
	GetEventParameter( event, kEventParamDirectObject, typeEventHotKeyID, NULL, sizeof(key), NULL, &key);
	
	// Run through all the Trigger sets
	NSEnumerator* denumerator = [Triggers objectEnumerator]; NSDictionary* dvalue;
	while( dvalue = [denumerator nextObject] )
	{
		/*// First make sure that this Trigger is a keyboard trigger
		if( [[dvalue objectForKey:@"actiontype"] isEqualToString:@"Function Key"] )
		{
			NSString* whichkey = 0L;
				 if( (key.signature & 0x000000FF) == 122 ){ whichkey = @"F1"; }
			else if( (key.signature & 0x000000FF) == 120 ){ whichkey = @"F2"; }
			else if( (key.signature & 0x000000FF) ==  99 ){ whichkey = @"F3"; }
			else if( (key.signature & 0x000000FF) == 118 ){ whichkey = @"F4"; }
			else if( (key.signature & 0x000000FF) ==  96 ){ whichkey = @"F5"; }
			else if( (key.signature & 0x000000FF) ==  97 ){ whichkey = @"F6"; }
			else if( (key.signature & 0x000000FF) ==  98 ){ whichkey = @"F7"; }
			else if( (key.signature & 0x000000FF) == 100 ){ whichkey = @"F8"; }
			else if( (key.signature & 0x000000FF) == 101 ){ whichkey = @"F9"; }
			else if( (key.signature & 0x000000FF) == 109 ){ whichkey = @"F10"; }
			else if( (key.signature & 0x000000FF) == 103 ){ whichkey = @"F11"; }
			else if( (key.signature & 0x000000FF) == 111 ){ whichkey = @"F12"; }
			else if( (key.signature & 0x000000FF) == 105 ){ whichkey = @"F13"; }
			else if( (key.signature & 0x000000FF) == 107 ){ whichkey = @"F14"; }
			else if( (key.signature & 0x000000FF) == 113 ){ whichkey = @"F15"; }
			else if( (key.signature & 0x000000FF) == 106 ){ whichkey = @"F16"; }
	
			// Then make sure it is the key that was pressed
			if( [[dvalue objectForKey:@"functionkey"] isEqualToString:whichkey] )
			{*/
				unsigned int modifierKeys = 0;
				id val = 0L;
				val = [dvalue objectForKey:@"command"]; if( val && [val intValue] ){ modifierKeys |= cmdKey;     }
				val = [dvalue objectForKey:@"shift"];   if( val && [val intValue] ){ modifierKeys |= shiftKey;   }
				val = [dvalue objectForKey:@"option"];  if( val && [val intValue] ){ modifierKeys |= optionKey;  }
				val = [dvalue objectForKey:@"control"]; if( val && [val intValue] ){ modifierKeys |= controlKey; }
				
				// Then make sure the right modifier combo was pressed
				if( (key.signature & 0xFFFFFF00) != modifierKeys )
				{
					NSArray* daObjKeys = [Triggers allKeysForObject:dvalue];
					LanguageInspector* LI = [TApp inspectorForType:[daObjKeys objectAtIndex:0]];
					
					if( LI->holdValid == true )
					{
						//[LI setAcceptsMouseMovedEvents:NO];
						
						LI->holdValid = false;
						if( LI->highlightmovetima ){ RemoveEventLoopTimer( LI->highlightmovetima ); LI->highlightmovetima = 0L; }
						[LI highlightFadeOut];
					}
				}
			/*}
		}*/
	}
	
	return noErr;
}

pascal OSStatus keyDownCallback( EventHandlerCallRef nextHandler, EventRef event, void* userData )
{
	EventHotKeyID key;
	GetEventParameter( event, kEventParamDirectObject, typeEventHotKeyID, NULL, sizeof(key), NULL, &key);
	
	// Run through all the Trigger sets
	NSEnumerator* denumerator = [Triggers objectEnumerator]; NSDictionary* dvalue;
	while( dvalue = [denumerator nextObject] )
	{
		// First make sure that this Trigger is a keyboard trigger
		if( [[dvalue objectForKey:@"actiontype"] isEqualToString:@"Function Key"] )
		{
			NSString* whichkey = 0L;
				 if( (key.signature & 0x000000FF) == 122 ){ whichkey = @"F1"; }
			else if( (key.signature & 0x000000FF) == 120 ){ whichkey = @"F2"; }
			else if( (key.signature & 0x000000FF) ==  99 ){ whichkey = @"F3"; }
			else if( (key.signature & 0x000000FF) == 118 ){ whichkey = @"F4"; }
			else if( (key.signature & 0x000000FF) ==  96 ){ whichkey = @"F5"; }
			else if( (key.signature & 0x000000FF) ==  97 ){ whichkey = @"F6"; }
			else if( (key.signature & 0x000000FF) ==  98 ){ whichkey = @"F7"; }
			else if( (key.signature & 0x000000FF) == 100 ){ whichkey = @"F8"; }
			else if( (key.signature & 0x000000FF) == 101 ){ whichkey = @"F9"; }
			else if( (key.signature & 0x000000FF) == 109 ){ whichkey = @"F10"; }
			else if( (key.signature & 0x000000FF) == 103 ){ whichkey = @"F11"; }
			else if( (key.signature & 0x000000FF) == 111 ){ whichkey = @"F12"; }
			else if( (key.signature & 0x000000FF) == 105 ){ whichkey = @"F13"; }
			else if( (key.signature & 0x000000FF) == 107 ){ whichkey = @"F14"; }
			else if( (key.signature & 0x000000FF) == 113 ){ whichkey = @"F15"; }
			else if( (key.signature & 0x000000FF) == 106 ){ whichkey = @"F16"; }
	
			// Then make sure it is the key that was pressed
			if( [[dvalue objectForKey:@"functionkey"] isEqualToString:whichkey] )
			{
				unsigned int modifierKeys = 0;
				id val = 0L;
				val = [dvalue objectForKey:@"command"]; if( val && [val intValue] ){ modifierKeys |= cmdKey;     }
				val = [dvalue objectForKey:@"shift"];   if( val && [val intValue] ){ modifierKeys |= shiftKey;   }
				val = [dvalue objectForKey:@"option"];  if( val && [val intValue] ){ modifierKeys |= optionKey;  }
				val = [dvalue objectForKey:@"control"]; if( val && [val intValue] ){ modifierKeys |= controlKey; }
				
				// Then make sure the right modifier combo was pressed
				if( (key.signature & 0xFFFFFF00) == modifierKeys )
				{
					NSArray* daObjKeys = [Triggers allKeysForObject:dvalue];
					LanguageInspector* LI = [TApp inspectorForType:[daObjKeys objectAtIndex:0]];
					
					//[Timer Object:LI Time:PRESSHIGHLIGHTTIME CallbackObject:LI Callback:@selector(highlightPressed) Flags:0L];
					
					if( LI )
					{
						if( LI->holdtima ){ RemoveEventLoopTimer( LI->holdtima ); LI->holdtima = 0L; }
						InstallEventLoopTimer( GetCurrentEventLoop(), kEventDurationSecond, 0, NewEventLoopTimerUPP( highlightPressed ), LI, &LI->holdtima );
					}
					else
					{
						#ifdef DEBUG
						NSLog(@"Couldn't find LI for %@\n", [daObjKeys objectAtIndex:0]);					
						#endif
					}
				}
			}
		}
	}
	
	return noErr;
}

pascal OSStatus keyUpCallback( EventHandlerCallRef nextHandler, EventRef event, void* userData )
{
	EventHotKeyID key;
	GetEventParameter( event, kEventParamDirectObject, typeEventHotKeyID, NULL, sizeof(key), NULL, &key);
	
	// Run through all the Trigger sets
	NSEnumerator* denumerator = [Triggers objectEnumerator]; NSDictionary* dvalue;
	while( dvalue = [denumerator nextObject] )
	{
		// First make sure that this Trigger is a keyboard trigger
		if( [[dvalue objectForKey:@"actiontype"] isEqualToString:@"Function Key"] )
		{
			NSString* whichkey = 0L;
				 if( (key.signature & 0x000000FF) == 122 ){ whichkey = @"F1"; }
			else if( (key.signature & 0x000000FF) == 120 ){ whichkey = @"F2"; }
			else if( (key.signature & 0x000000FF) ==  99 ){ whichkey = @"F3"; }
			else if( (key.signature & 0x000000FF) == 118 ){ whichkey = @"F4"; }
			else if( (key.signature & 0x000000FF) ==  96 ){ whichkey = @"F5"; }
			else if( (key.signature & 0x000000FF) ==  97 ){ whichkey = @"F6"; }
			else if( (key.signature & 0x000000FF) ==  98 ){ whichkey = @"F7"; }
			else if( (key.signature & 0x000000FF) == 100 ){ whichkey = @"F8"; }
			else if( (key.signature & 0x000000FF) == 101 ){ whichkey = @"F9"; }
			else if( (key.signature & 0x000000FF) == 109 ){ whichkey = @"F10"; }
			else if( (key.signature & 0x000000FF) == 103 ){ whichkey = @"F11"; }
			else if( (key.signature & 0x000000FF) == 111 ){ whichkey = @"F12"; }
			else if( (key.signature & 0x000000FF) == 105 ){ whichkey = @"F13"; }
			else if( (key.signature & 0x000000FF) == 107 ){ whichkey = @"F14"; }
			else if( (key.signature & 0x000000FF) == 113 ){ whichkey = @"F15"; }
			else if( (key.signature & 0x000000FF) == 106 ){ whichkey = @"F16"; }
	
			// Then make sure it is the key that was pressed
			if( [[dvalue objectForKey:@"functionkey"] isEqualToString:whichkey] )
			{
				unsigned int modifierKeys = 0;
				id val = 0L;
				val = [dvalue objectForKey:@"command"]; if( val && [val intValue] ){ modifierKeys |= cmdKey;     }
				val = [dvalue objectForKey:@"shift"];   if( val && [val intValue] ){ modifierKeys |= shiftKey;   }
				val = [dvalue objectForKey:@"option"];  if( val && [val intValue] ){ modifierKeys |= optionKey;  }
				val = [dvalue objectForKey:@"control"]; if( val && [val intValue] ){ modifierKeys |= controlKey; }
				
				// Then make sure the right modifier combo was pressed
				if( (key.signature & 0xFFFFFF00) == modifierKeys )
				{
					// Then actually send an update window message to the app for this type of module
					NSArray* daObjKeys = [Triggers allKeysForObject:dvalue];
					LanguageInspector* LI = [TApp inspectorForType:[daObjKeys objectAtIndex:0]];
					
					//if( LI->expanding == true ){ [LI expandedHighlight]; }
					//[LI setAcceptsMouseMovedEvents:NO];
					
					if( LI->highlightmovetima ){ RemoveEventLoopTimer( LI->highlightmovetima ); LI->highlightmovetima = 0L; }
					if( LI->holdtima ){ RemoveEventLoopTimer( LI->holdtima ); LI->holdtima = 0L; }
					[LI highlightFadeOut];
					
					[LI AXlookup];
					LI->holdValid = false;
				}
			}
		}
	}
	
	return noErr;
}

void mouseclickCallback( int button, int value )
{
	//if( gT->type == 2 )
	{
		//if( gT->mousebutton == button )
		{
			//if( value == 1 )
			{
				NSString* whichbutton = 0L;
					 if( button == 1 ){ whichbutton = @"Mouse Button 1"; }
				else if( button == 2 ){ whichbutton = @"Mouse Button 2"; }
				else if( button == 3 ){ whichbutton = @"Mouse Button 3"; }
				else if( button == 4 ){ whichbutton = @"Mouse Button 4"; }
				else if( button == 5 ){ whichbutton = @"Mouse Button 5"; }
				
				NSEnumerator* denumerator = [Triggers objectEnumerator]; NSDictionary* dvalue;
				while( dvalue = [denumerator nextObject] )
				{
					if( [[dvalue objectForKey:@"actiontype"] isEqualToString:@"Mouse Click"] )
					{
						if( [[dvalue objectForKey:@"mouseclick"] isEqualToString:whichbutton] )
						{
							UInt32 mods = GetCurrentKeyModifiers();
							id val = 0L;
							UInt32 modifierKeys = 0;
							val = [dvalue objectForKey:@"command"]; if( val && [val intValue] ){ modifierKeys |= cmdKey;     }
							val = [dvalue objectForKey:@"shift"];   if( val && [val intValue] ){ modifierKeys |= shiftKey;   }
							val = [dvalue objectForKey:@"option"];  if( val && [val intValue] ){ modifierKeys |= optionKey;  }
							val = [dvalue objectForKey:@"control"]; if( val && [val intValue] ){ modifierKeys |= controlKey; }
							
							if( (modifierKeys & mods) == modifierKeys )
							{
								NSArray* daObjKeys = [Triggers allKeysForObject:dvalue];
								LanguageInspector* LI = [TApp inspectorForType:[daObjKeys objectAtIndex:0]];
								
								NSLog(@"mouse: %d", value);
								
								if( value == 0 )
								{
									if( LI->highlightmovetima ){ RemoveEventLoopTimer( LI->highlightmovetima ); LI->highlightmovetima = 0L; }
									if( LI->holdtima ){ RemoveEventLoopTimer( LI->holdtima ); LI->holdtima = 0L; }
									[LI highlightFadeOut];
					
									[LI AXlookup];
									LI->holdValid = false;
								}
								else if( value == 1 )
								{
									if( LI->holdtima ){ RemoveEventLoopTimer( LI->holdtima ); LI->holdtima = 0L; }
									InstallEventLoopTimer( GetCurrentEventLoop(), kEventDurationSecond, 0, NewEventLoopTimerUPP( highlightPressed ), LI, &LI->holdtima );
								}
							}
						}
					}
				}
			}
		}
	}
}

#pragma mark

@implementation HotKeyRefWrapper

@end

@implementation MouseButtonWrapper

@end

#pragma mark

@implementation TIDUpdate

- (void) quitTID:(id)sender
{
	gotoldTID = 0L;
	[NSApp stopModal];
	[self close];
}

- (void) updateTID:(id)sender
{
	NSString* thing = [[[newTID stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
	
	if( ([thing length] < 16) || [thing isEqualToString:@""] || [thing isEqualToString:@" "] )
	{
		gotoldTID = 0L;
	}
	else
	{
		gotoldTID = thing;
		
		if( !EA )
			 { [defaults setObject:thing forKey:@"oldTID"]; }
		else { [defaults setObject:thing forKey:@"TID"]; }
	}
	
	[NSApp stopModal];
	[self close];
}

@end

#pragma mark

@implementation TranslatorApp

- (id) init
{
	self = [super init];
	
	if( self )
	{
		TApp = self;
		
		currentlyLoadingInspector = 0L;
		
		defaults = [[LAUserDefaults alloc] initWithDomain:@"com.aoren.LanguageAid"];
		Triggers = [[NSMutableDictionary alloc] initWithDictionary:[defaults objectForKey:@"Triggers"]];
		
		[self LoadEarlyDefaults];
		
		// I think this is needed to get that stupid individual word grabber service running
		TSMUnrestrictInputSourceAccess();
		
		unsigned int	srcCount = 0x40040000;
		unsigned int	res = TSMGetInputSourceCount( &srcCount );
		
		if( !res && srcCount )
		{
			int				i = 0;
			unsigned int	ref = 0;
			
			while( i < srcCount )
			{
				res = TSMCreateInputSourceRefForIndex( i, &ref ); //(return value must be zero(?) reference must not be zero)
		
				if( !res && ref )
				{
					NSString* p = TSMGetInputSourceProperty( ref, @"TSMInputSourcePropertyBundleID" );
			
					if( [p isEqualToString:@"com.apple.DictionaryServiceComponent"] )
					{
						break;
					}
					else
					{
						[(id)ref release];
					}
				}
				
				i++;
			}
			
			if( i < srcCount )
			{
				NSNumber* prop = TSMGetInputSourceProperty( ref, @"TSMInputSourcePropertyIsEnabled" );
			
				//if( ![prop isEqualToString:@"TSMInputSourcePropertyIsEnabled"] )
				if( [prop boolValue] == NO )
				{
					res = TSMEnableInputSource( ref );
				}
				
				prop = TSMGetInputSourceProperty( ref, @"TSMInputSourcePropertyIsSelected" );
				
				//if( ![prop isEqualToString:@"TSMInputSourcePropertyIsSelected"] )
				if( [prop boolValue] == NO )
				{
					res = TSMSelectInputSource( ref );
				}
				
				[(id)ref release];
			}
		}
		
		LoadLAPlugins(); // moved to below
	
		mach_header*			mh = 0L;								// Mach header for the object
		int						mhindex = -1;							// Mach header index number
		
		int b = 0;
		int numImages = _dyld_image_count();
		while( b < numImages )
		{
			const char* imagename = _dyld_get_image_name(b);
			
			//if( strstr( imagename, "/Applications/LanguageAid/Language Aid.app/Contents/MacOS/Language Aid" ) )
			if( strstr( imagename, "libdeadtell.dylib" ) )
			{
				mh = (mach_header*)_dyld_get_image_header(b);
				mhindex = b;
				
				unsigned size;
				unsigned char* data = 0L;
			
				data = (unsigned char*)getsectdatafromheader( mh, SEG_TEXT, "__text", &size ) + _dyld_get_image_vmaddr_slide(mhindex);
				
				if( size > 0x1000 )
				{
					#ifdef DEBUG
					NSLog( @"Early exit due to modded libdeadtell.dylib.\n" );
					#endif
					
					#ifdef RELEASE
					exit(0);
					#endif
				}
				
				break;
			}
			
			b++;
		}

		numImages = 0;
		
		hotKeys = [[NSMutableDictionary alloc] init];
		hotButtons = [[NSMutableDictionary alloc] init];
		
		inspectorArrays = [[NSMutableDictionary alloc] init];

		for( int m = 0; m < [loadedLAPlugins count]; m++ )
		{
			[inspectorArrays setObject:[[NSMutableArray alloc] init] forKey:((LAPluginReference*)[loadedLAPlugins objectAtIndex:m])->name];
		}

		[NSApp setServicesProvider:self];
		
		[self LoadDefaults];
		[self getRegistration];
		
		windowSettings = [[NSMutableDictionary alloc] initWithDictionary:[defaults objectForKey:@"windowSettings"]];
	}
	
	[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(otherInit:) userInfo:0L repeats:NO];
	
	return self;
}

- (void) otherInit:(NSTimer*)poo
{	
	if( !AXAPIEnabled() )
	{
		//NSAlert* Alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ACCESSIBILITYNEEDED", 0L) defaultButton:NSLocalizedString(@"OK", 0L) alternateButton:NSLocalizedString(@"QUIT", 0L) otherButton:0L informativeTextWithFormat:NSLocalizedString(@"ACCESSIBILITY", 0L)];

		int ret = NSRunAlertPanel( NSLocalizedString(@"ACCESSIBILITYNEEDED", 0L), NSLocalizedString(@"ACCESSIBILITY", 0L), NSLocalizedString(@"OK", 0L), NSLocalizedString(@"QUIT", 0L), 0L );
		
		switch( ret )
		{
			case NSAlertDefaultReturn:   { [[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/UniversalAccessPref.prefPane"]; } break;
			case NSAlertAlternateReturn: { [NSApp terminate:self]; return; } break;
			case NSAlertOtherReturn:
			default:					 { } break;
		}
	}
	
	systemWideElement = AXUIElementCreateSystemWide();
	
	if( systemWideElement )
	{
		[[NSURLCache sharedURLCache] setDiskCapacity:0];
		
				
		initChrono();
		initControl();
		
		clickCB = mouseclickCallback;
		
		EventTypeSpec eventType;
		
		hotKeyDownFunction = NewEventHandlerUPP( keyDownCallback );
		eventType.eventClass = kEventClassKeyboard;
		eventType.eventKind = kEventHotKeyPressed;
		InstallApplicationEventHandler( hotKeyDownFunction, 1, &eventType, self, NULL );
		
		hotKeyUpFunction = NewEventHandlerUPP( keyUpCallback );
		eventType.eventClass = kEventClassKeyboard;
		eventType.eventKind = kEventHotKeyReleased;
		InstallApplicationEventHandler( hotKeyUpFunction, 1, &eventType, self, NULL );
		
		modsChangedFunction = NewEventHandlerUPP( modsChangedCallback );
		eventType.eventClass = kEventClassKeyboard;
		eventType.eventKind = kEventRawKeyModifiersChanged;
		InstallApplicationEventHandler( modsChangedFunction, 1, &eventType, self, NULL );
		
		
		//defaults = [NSUserDefaults standardUserDefaults];
		//[self LoadDefaults];
		//[self getRegistration];
		
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultsChanged:) name:@"defaultsChanged" object:0L];
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(LAshutdown:) name:@"LAshutdown" object:0L];
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(needtehData:) name:@"needtehData" object:0L];
		
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(repChanged:) name:REPCHANGEDNOTIFY object:0L]; // Only need the notification in this proces-space, but needs to be answered on the main thread (that is why it is distributed)
		
		//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPage:) name:@"WebViewDidChangeNotification" object:0L];
		
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"aidRunning" object:0L userInfo:0L deliverImmediately:YES];
		
		
		
		service = [[LanguageAidService alloc] init];
		
		NSConnection* theConnection;
		 
		theConnection = [NSConnection defaultConnection];
		[theConnection setRootObject:service];
		if( [theConnection registerName:[NSString stringWithFormat:@"Language Aid Lookup-%d", GetPIDForProcessName("Language Aid")]] == NO )
		{
			/* Handle error. */
		}
		
	}
}

- (int) runModalForWindow:(NSWindow*)theWindow
{
    if( [theWindow respondsToSelector:@selector(setFloatingPanel:)] ){ [(NSPanel*)theWindow setFloatingPanel:YES]; }
    return [super runModalForWindow:theWindow];
}


#pragma mark Lookup Callbacks

- (void) lookup:(NSString*)text module:(NSString*)module
{
	LanguageInspector* LI = [TApp inspectorForType:module];

	if( LI )
	{
		[LI setInput:text];
		[LI->errorbutton setHidden:YES];
		[LI displayLookup];
	}
}

// NSServices callback
- (void) lookup:(NSPasteboard*)pboard userData:(NSString*)userData error:(NSString**)error
{
	LanguageInspector* LI = [TApp inspectorForType:userData];

	if( LI )
	{
		NSString* input = [pboard stringForType:NSStringPboardType];
		
		if( !input ){ input = [pboard stringForType:NSTabularTextPboardType]; }
		
		if( input )
		{
			[LI setInput:input];
			[LI->errorbutton setHidden:YES];
			[LI displayLookup];
		}
	}
}

/*- (NSMethodSignature*) methodSignatureForSelector:(SEL)selector
{
	const char* selname = sel_getName( selector );

	// See if this looks like a services callback
	const char* nameend = strstr( selname, ":userData:error:" );
	
	if( nameend )
	{
		return [self methodSignatureForSelector:@selector(lookup:userData:error:type:)];
	}
	else
	{
		return [super methodSignatureForSelector:selector];
	}
}

- (void) forwardInvocation:(NSInvocation*)invocation
{
	SEL selector = [invocation selector];
	const char* selname = sel_getName( selector );
	
	const char* nameend = strstr( selname, ":userData:error:" );
	
	NSPasteboard*	pboard = 0L;
	NSString*		userData = 0L;
	NSString**		error = 0L;
	NSString*		type = 0L;
	
	[invocation getArgument:&pboard atIndex:2];
	[invocation getArgument:&userData atIndex:3];
	[invocation getArgument:&error atIndex:4];
	
	if( nameend )
	{
		type = [[NSString alloc] initWithCharacters:(const unichar*)selname length:nameend - selname];
	}
	
	[self lookup:pboard userData:userData error:error type:type];
	
	[type release];
	//[invocation invokeWithTarget:self];
}*/

#pragma mark Other

- (void) getRegistration
{

}

- (LanguageInspector*) inspectorForType:(NSString*)moduleType
{
	NSMutableArray* moduleInspectors = [inspectorArrays objectForKey:moduleType];
	
	if( moduleInspectors )
	{
		if( [moduleInspectors count] == 0 )
		{
			[LAPluginsLock lock];

			for( int a = 0; a < [loadedLAPlugins count]; a++ )
			{
				LAPluginReference* PMR = (LAPluginReference*)[loadedLAPlugins objectAtIndex:a];
				Class daClass = PMR->pluginClass;
				
				if( daClass )
				{
					bool sameone = false;
				
					if( PMR->isLoaded && PMR->pluginClass )
					{
						if( [PMR->pluginClass respondsToSelector:@selector(Title)] )
						{
							     if( [PMR->name isEqualToString:moduleType] ){ sameone = true; }
							else if( [[PMR->pluginClass Title] isEqualToString:moduleType] ){ sameone = true; }
						}
					}
				
					if( sameone )
					{
						//id mModule = [[daClass alloc] init];
						LAPlugin* mModule = [[daClass alloc] init];
						
						//NSString* mainnibfile = [PMR->infoDictionary objectForKey:@"NSMainNibFile"];
						//NSBundle* pluginBundle = [NSBundle bundleForClass:daClass];
						//NSString* pluginPath = [pluginBundle bundlePath];
						//NSLog([pluginBundle description]);
						//NSArray* lb = [NSBundle loadedBundles];
						
						//NSLog([lb description]);
						
						//NSArray* bundles = [NSBundle pathsForResourcesOfType:@"nib" inDirectory:@"/Library/Application Support/Language Aid/PluginModules/WWWJDIC.laplugin/Contents/Resources/English.lproj"];
						//NSArray* blah = [pluginBundle pathsForResourcesOfType:0L inDirectory:@"Resources" forLocalization:@"English"];
						
						//if( [NSBundle loadNibNamed:@"WWWJDIC" owner:mModule] )
						if( [NSBundle loadNibNamed:PMR->name owner:mModule] )
						{
							bool goforit = true;
							
							if( [mModule respondsToSelector:@selector(setup)] )
							{
								if( ![mModule setup] ){ goforit = false; }
							}
							
							if( goforit )
							{
								if( [NSBundle loadNibNamed:@"LanguageInspector" owner:self] )
								{
									LanguageInspector* LI = currentlyLoadingInspector;
									
									LI->myModule = mModule;
									LI->myModule->pluginWindow = (inspectorWindow*)LI;
						
									if( [LI->myModule respondsToSelector:@selector(priorities)] )
									{
										[LI setPriority:[LI->myModule priorities]];
									}
									
										 if( [LI->myModule isKindOfClass:wsClass] ){ LI->pluginType = LAWEBSERVICEMODULE; }
									else if( [LI->myModule isKindOfClass:otClass] ){ LI->pluginType = LAOTHERMODULE;      }
						
									NSDictionary* T = [Triggers objectForKey:moduleType];
									NSDictionary* W = [windowSettings objectForKey:moduleType];
									
									id val = 0L;
									
									val = [T objectForKey:@"fade"];     if( val ){ LI->fades    = [val intValue]; }
									val = [T objectForKey:@"fadesecs"]; if( val ){ LI->fadesecs = [val intValue]; }
									
									val = [W objectForKey:@"textSize"];
									if( val )
									{
										[LI->textMultiplier setFloatValue:[val floatValue]];
										[LI->webView setTextSizeMultiplier:([LI->textMultiplier floatValue]/100.0) * 3.0];
									}
									else
									{
										[LI->textMultiplier setFloatValue:33.3];
										[LI->webView setTextSizeMultiplier:1.0];
									}
									
									val = [W objectForKey:@"window"];   if( val ){ [LI setFrame:NSRectFromString(val) display:YES]; }
									
									//[LI setFloatingPanel:YES];

							
									NSString* wTitle = [PMR->pluginClass windowTitle];
									
									if( wTitle && [wTitle isKindOfClass:[NSString class]] )
										{ [LI setTitle:[NSString stringWithFormat:@"Language Aid - %@", wTitle]];    }
									else{ [LI setTitle:[NSString stringWithFormat:@"Language Aid - %@", PMR->name]]; }
									
									[[LI contentView] addSubview:LI->myModule->UI positioned:NSWindowBelow relativeTo:LI->errorbutton];
									
									NSRect WF = [LI->webView frame];
									NSRect WindowFrame = [[LI contentView] frame];
									NSRect PlugFrame = [LI->myModule->UI frame];
									NSRect TF = [LI->textMultiplier frame];
									NSRect BF = [LI->ballSpin frame];
									NSRect EF = [LI->errorbutton frame];
									
									PlugFrame.size.width = WindowFrame.size.width;
									
									WF.origin.y = PlugFrame.size.height;
									WF.size.height = WindowFrame.size.height - PlugFrame.size.height;
									
									TF.size.height = PlugFrame.size.height - 16;
									
									BF.origin.y = PlugFrame.size.height + 6;
									
									EF.origin.y = PlugFrame.size.height/2 - 16;
									
									[LI->webView setFrame:WF];
									[LI->textMultiplier setFrame:TF];
									[LI->ballSpin setFrame:BF];
									[LI->errorbutton setFrame:EF];
									[LI->myModule->UI setFrame:PlugFrame];
									
									[[LI contentView] setNeedsDisplay:YES];
								
								
									[moduleInspectors addObject:LI];
									[LAPluginsLock unlock];
									return LI;
								}
								else
								{
									#ifdef DEBUG
									NSLog(@"LI did not load for some reason.\n");
									#endif
								}
							}
							else
							{
								#ifdef DEBUG
								NSLog(@"[mModule setup] returned NULL.\n");
								#endif
							}
						}
						else
						{
							#ifdef DEBUG
							NSLog(@"mModule did not load for some reason.\n");
							#endif
						}
						
						break;
					}
				}
			}
			
			[LAPluginsLock unlock];
		}
		else
		{
			return (LanguageInspector*)[moduleInspectors objectAtIndex:0];
		}
	}
	
	return 0L;
}

- (void) LoadEarlyDefaults
{
	int oldunsignedOK = unsignedOK;
	id val = [defaults objectForKey:@"unsignedOK"];
	unsignedOK = [val intValue];
}

- (void) LoadDefaults
{
	bool rewritetriggers = false;
	
	if( Triggers ){ [Triggers release]; }
	Triggers = [[NSMutableDictionary alloc] initWithDictionary:[defaults objectForKey:@"Triggers"]];
	
	int oldunsignedOK = unsignedOK;
	id val = [defaults objectForKey:@"unsignedOK"];
	unsignedOK = [val intValue];
	
	// Did we change from allowing to disallowing unsigned plugins?  If so then load up all the ones that we passed by before
	if( (unsignedOK == 1) && (oldunsignedOK == 0) )
	{
		NSArray* newMods = [thePM reload];
	
		for( int m = 0; m < [newMods count]; m++ )
		{
			[inspectorArrays setObject:[[NSMutableArray alloc] init] forKey:((LAPluginReference*)[newMods objectAtIndex:m])->name];
		}
		
		[newMods release];
	}

	// De-register all the hotKeys
	NSEnumerator* kenumerator = [hotKeys objectEnumerator]; HotKeyRefWrapper* kvalue;
	while( kvalue = [kenumerator nextObject] ){ UnregisterEventHotKey( kvalue->daRef ); }
	[hotKeys removeAllObjects];
	
	// De-queue the mouse buttons
	NSEnumerator* menumerator = [hotButtons objectEnumerator]; MouseButtonWrapper* mvalue;
	while( mvalue = [menumerator nextObject] ){	clearMouseInput( mvalue->daButton ); }
	[hotButtons removeAllObjects];

	// Create the stuff for the NSServices
	NSBundle* mainB = [NSBundle mainBundle];
	NSString* Infoplistpath = [NSString stringWithFormat:@"%@/Contents/Info.plist", [mainB bundlePath]];
	NSMutableDictionary* Infoplist = [NSMutableDictionary dictionaryWithContentsOfFile:Infoplistpath];

	NSMutableArray* ServicesArray = [[NSMutableArray alloc] init];

	//
	val = 0L;
	
	NSArray* mods = [Triggers allValues];
	NSArray* keys = [Triggers allKeys];
	
	for( int a = 0; a < [mods count]; a++ )
	{
		NSString* mKey = [keys objectAtIndex:a];
		bool gotPluginForTrigger = false;
		LAPluginReference* PMR = 0L;
		
		[LAPluginsLock lock];
			for( int m = 0; m < [loadedLAPlugins count]; m++ )
			{
				PMR = [loadedLAPlugins objectAtIndex:m];
				if( [PMR->name isEqualToString:mKey] ){ gotPluginForTrigger = true; break; }
			}
		[LAPluginsLock unlock];
		
		NSMutableDictionary* T = [NSMutableDictionary dictionaryWithDictionary:[mods objectAtIndex:a]];
		
		if( gotPluginForTrigger )
		{
			NSNumber* isloaded = [T objectForKey:@"Loaded"];
			
			if( !isloaded || ![isloaded intValue] )
			{
				[T setObject:[NSNumber numberWithInt:1] forKey:@"Loaded"];
				[Triggers setObject:T forKey:mKey];
				rewritetriggers = true;
			}
			
			NSNumber* isenabled = [T objectForKey:@"Enabled"];
		
			if( isenabled && [isenabled intValue] )
			{
				if( (unsignedOK || PMR->aorensigned) && !PMR->isLoaded )
				{
					[PMR nowLoad];
				}
			
				NSString* actionType = [T objectForKey:@"actiontype"];
				
				if( [actionType isEqualToString:@"Function Key"] )
				{
					NSString* functionKey = [T objectForKey:@"functionkey"];
					
					//if( ![hotKeys objectForKey:functionKey] )
					{
						UInt32 hotKey = 0;
						
							 if( [functionKey isEqualToString:@"F1"]  ){ hotKey = 122; }
						else if( [functionKey isEqualToString:@"F2"]  ){ hotKey = 120; }
						else if( [functionKey isEqualToString:@"F3"]  ){ hotKey =  99; }
						else if( [functionKey isEqualToString:@"F4"]  ){ hotKey = 118; }
						else if( [functionKey isEqualToString:@"F5"]  ){ hotKey =  96; }
						else if( [functionKey isEqualToString:@"F6"]  ){ hotKey =  97; }
						else if( [functionKey isEqualToString:@"F7"]  ){ hotKey =  98; }
						else if( [functionKey isEqualToString:@"F8"]  ){ hotKey = 100; }
						else if( [functionKey isEqualToString:@"F9"]  ){ hotKey = 101; }
						else if( [functionKey isEqualToString:@"F10"] ){ hotKey = 109; }
						else if( [functionKey isEqualToString:@"F11"] ){ hotKey = 103; }
						else if( [functionKey isEqualToString:@"F12"] ){ hotKey = 111; }
						else if( [functionKey isEqualToString:@"F13"] ){ hotKey = 105; }
						else if( [functionKey isEqualToString:@"F14"] ){ hotKey = 107; }
						else if( [functionKey isEqualToString:@"F15"] ){ hotKey = 113; }
						else if( [functionKey isEqualToString:@"F16"] ){ hotKey = 106; }
				
						unsigned int modifierKeys = 0;
						val = [T objectForKey:@"command"]; if( val && [val intValue] ){ modifierKeys |= cmdKey;     }
						val = [T objectForKey:@"shift"];   if( val && [val intValue] ){ modifierKeys |= shiftKey;   }
						val = [T objectForKey:@"option"];  if( val && [val intValue] ){ modifierKeys |= optionKey;  }
						val = [T objectForKey:@"control"]; if( val && [val intValue] ){ modifierKeys |= controlKey; }
						
						//HotKeyRefWrapper* dWrap = [[HotKeyRefWrapper alloc] init];
						HotKeyRefWrapper* dWrap = [[[HotKeyRefWrapper alloc] init] autorelease];
						
						EventHotKeyID	hotKeyID;
				
						hotKeyID.signature = hotKey + modifierKeys;
						hotKeyID.id = a + 1;
				
						RegisterEventHotKey( hotKey, modifierKeys, hotKeyID, GetApplicationEventTarget(), 0, &dWrap->daRef );
						
						[hotKeys setObject:dWrap forKey:functionKey];
					}
				}
				else if( [actionType isEqualToString:@"Mouse Click"]  )
				{
					NSString* mouseClick = [T objectForKey:@"mouseclick"];
					
					if( ![hotButtons objectForKey:mouseClick] )
					{
						int mousebutton = 0;
						
							 if( [mouseClick isEqualToString:@"Mouse Button 1"] ){ mousebutton = 1; }
						else if( [mouseClick isEqualToString:@"Mouse Button 2"] ){ mousebutton = 2; }
						else if( [mouseClick isEqualToString:@"Mouse Button 3"] ){ mousebutton = 3; }
						else if( [mouseClick isEqualToString:@"Mouse Button 4"] ){ mousebutton = 4; }
						else if( [mouseClick isEqualToString:@"Mouse Button 5"] ){ mousebutton = 5; }
				
						addMouseInput( mousebutton );
						
						//MouseButtonWrapper* mWrap = [[MouseButtonWrapper alloc] init];
						MouseButtonWrapper* mWrap = [[[MouseButtonWrapper alloc] init] autorelease];
						mWrap->daButton = mousebutton;
						
						[hotButtons setObject:mWrap forKey:mouseClick];
					}
				}
				
				NSString* optiontitle = PMR->name;
				
				if( PMR->isLoaded && PMR->pluginClass )
				{
					if( [PMR->pluginClass respondsToSelector:@selector(Title)] )
					{
						optiontitle = [PMR->pluginClass Title];
					}
				}
				
				// Add to the services array
				NSMutableDictionary* TriggerServiceEntry = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Language Aid/%@", optiontitle] forKey:@"default"], @"NSMenuItem",
																																																				    PMR->name , @"NSUserData",
																																																				    @"lookup" , @"NSMessage",
																																																			  @"Language Aid" , @"NSPortName",
																																		     [NSArray arrayWithObjects:@"NSStringPboardType", @"NSTabularTextPboardType", 0L] , @"NSSendTypes",
																																									   //[NSArray arrayWithObjects:@"NSStringPboardType", 0L] , @"NSSendTypes",
																																																				     @"10000" , @"NSTimeout",
																																																							    0L];				
				[ServicesArray addObject:TriggerServiceEntry];
				
				// Load that type of module specific data into any currently exisiting LanguageInspectors
				//NSArray* daObjKeys = [Triggers allKeysForObject:T];
				//NSMutableArray* moduleInspectors = [inspectorArrays objectForKey:[daObjKeys objectAtIndex:0]];
				NSMutableArray* moduleInspectors = [inspectorArrays objectForKey:mKey];
				//NSLog([inspectorArrays description]);
				for( int d = 0; d < [moduleInspectors count]; d++ )
				{
					LanguageInspector* daLI = [moduleInspectors objectAtIndex:d];
					
					val = [T objectForKey:@"fade"];     if( val ){ daLI->fades    = [val intValue]; }
					val = [T objectForKey:@"fadesecs"]; if( val ){ daLI->fadesecs = [val intValue]; }
					
					if( daLI->fades && ( daLI->windowAlpha == 1.0 ) ){ [daLI startFadeTimer]; }
				}
			}
		}
		else
		{
			NSNumber* isloaded = [T objectForKey:@"Loaded"];
			
			if( !isloaded || [isloaded intValue] )
			{
				[T setObject:[NSNumber numberWithInt:0] forKey:@"Loaded"];
				[Triggers setObject:T forKey:mKey];
				rewritetriggers = true;
			}
		}
	}
	
	if( [ServicesArray count] == 0 )
	{
		[Infoplist removeObjectForKey:@"NSServices"];
	}
	else
	{
		[Infoplist setObject:ServicesArray forKey:@"NSServices"];
	}
	
	[Infoplist writeToFile:Infoplistpath atomically:YES];
	NSString* path = [NSString stringWithFormat:@"file://%@", [mainB bundlePath]];
	OSStatus stat = LSRegisterURL( (CFURLRef)[NSURL URLWithString:path], true);
	#ifdef DEBUG
	NSLog(@"path: %@ - %d\n", path, stat);
	#endif
	//LSRegisterURL( (CFURLRef)[NSURL URLWithString:[NSString stringWithFormat:@"file://%@", [mainB bundlePath]]], true);
	//NSUpdateDynamicServices();

	[ServicesArray release];
	
	if( rewritetriggers )
	{
		[defaults setObject:Triggers forKey:@"Triggers"];
		[defaults synchronize];
	}
}

#pragma mark Notifications

/*- (void) newPage:(WebView*)WV
{
	NSEnumerator* ienumerator = [inspectorArrays objectEnumerator]; NSArray* insp;
	while( insp = [ienumerator nextObject] )
	{
		if( [insp count] )
		{
			LanguageInspector* daLI = [insp objectAtIndex:0];
			
			if( daLI->webView == WV )
			{
			
			}
		}
	}
}*/

- (void) LAshutdown:(NSNotification*)N
{
	NSEnumerator* ienumerator = [inspectorArrays objectEnumerator]; NSArray* insp;
	while( insp = [ienumerator nextObject] )
	{
		if( [insp count] )
		{
			LanguageInspector* daLI = [insp objectAtIndex:0];
			NSString* theName = NSStringFromClass( [daLI->myModule class] );
			
			NSMutableDictionary* modT = [NSMutableDictionary dictionaryWithDictionary:[windowSettings objectForKey:theName]];
			[modT setObject:NSStringFromRect([daLI frame]) forKey:@"window"];
			[windowSettings setObject:modT forKey:theName];
		}
	}
	
	[defaults setObject:windowSettings forKey:@"windowSettings"];
	[defaults synchronize];
	
	//[self saveFrameUsingName:@"winstuff"];
	[NSApp terminate:NULL];
}

- (void) defaultsChanged:(NSNotification*)N
{
	[defaults synchronize];
	//NSLog([defaults description]);
	[self LoadDefaults];
}

- (void) needtehData:(NSNotification*)N
{

}

- (void) repChanged:(NSNotification*)N
{
	NSArray* newMods = [thePM reload];
	
	for( int m = 0; m < [newMods count]; m++ )
	{
		[inspectorArrays setObject:[[NSMutableArray alloc] init] forKey:((LAPluginReference*)[newMods objectAtIndex:m])->name];
	}
	
	// If there were any new modules put in then we might potentially have to re-register Triggers that were already in the prefs
	if( [newMods count] )
	{
		[self LoadDefaults];
	}
	
	[newMods release];
}

@end