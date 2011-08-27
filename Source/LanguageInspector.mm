// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import "TranslatorApp.h"
#import "LanguageInspector.h"
#import "LAPlugin.h"
#import "GetPID.h"
#import "main.h"

	extern "C"
	{
		typedef int CGSConnection;
		typedef int CGSWindow;
		
		struct CPSProcessSerNum
		{
			UInt32				lo;
			UInt32				hi;
		};

		typedef UInt32	CPSAppFlavour;
		typedef UInt32	CPSProcAttributes;

		struct CPSProcessInfoRec
		{
			CPSProcessSerNum	Parent;
			UInt64				LaunchDate;
			CPSAppFlavour		Flavour;
			CPSProcAttributes	Attributes;
			UInt32				ExecFileType;
			UInt32				ExecFileCreator;
			UInt32				UnixPID;
		};

		typedef enum _CGSWindowOrderingMode {
			kCGSOrderAbove                =  1, // Window is ordered above target.
			kCGSOrderBelow                = -1, // Window is ordered below target.
			kCGSOrderOut                  =  0  // Window is removed from the on-screen window list.
		} CGSWindowOrderingMode;

		extern CGSConnection CGSMainConnectionID();
		extern int CGSFindWindowAndOwner( CGSConnection conID, int a, int b, int c, CGPoint* thapoint, CPSProcessSerNum* p1, CPSProcessSerNum* p2, CPSProcessSerNum* p3 );
		extern OSErr CPSGetWindowOwner( CGSWindow windowNumber, CPSProcessSerNum* psn );
		extern OSErr CPSGetProcessInfo( CPSProcessSerNum* psn, CPSProcessInfoRec* info, char* path, int maxPathLen, int* len, char* name, int maxNameLen);
		
		extern OSStatus CGSGetWindowLevel( const CGSConnection cid, CGSWindow wid, int* level );
		//extern OSStatus CGSSetWindowAlpha( const CGSConnection cid, const CGSWindow wid, float alpha );
		
		extern OSStatus CGSOrderWindow( const CGSConnection cid, const CGSWindow wid, CGSWindowOrderingMode place, CGSWindow relativeToWindowID ); 
		
		//extern OSStatus CGSGetScreenRectForWindow( const CGSConnection cid, const CGSWindow wid, CGRect* rect );
		
		//extern OSStatus __CGSSetWindowRegion( const CGSConnection cid, CGSWindow wid, CGRect region );
		extern CGSWindow GetNativeWindowFromWindowRef( WindowRef );
		
		extern CFMessagePortRef CFMessagePortCreatePerProcessRemote(CFAllocatorRef allocator, CFStringRef name, UInt32 UnixPID) __attribute__((weak_import));
	}


bool alreadyLoading = false;

static pascal void checkAXAPIStatus( EventLoopTimerRef inTimer, void* userData )
{
	if( AXAPIEnabled() )
    {
		[((LanguageInspector*)userData)->errorbutton setHidden:YES];
		[((LanguageInspector*)userData)->myModule->UI setHidden:NO];
		RemoveEventLoopTimer( inTimer );
	}
}

#pragma mark

bool whitespaceCharacter( unichar dachar )
{
	bool gotit = false;
	
	switch( dachar )
	{
		case    ' ': { gotit = true; } break;
		case 0x00A0: { gotit = true; } break;
		case   '\t': { gotit = true; } break;
		case   '\n': { gotit = true; } break;
		case   '\r': { gotit = true; } break;
		case 0x2028: { gotit = true; } break;
		case 0x2029: { gotit = true; } break;
	}
	
	return gotit;
}

#pragma mark

static pascal void fade( EventLoopTimerRef inTimer, void* userData )
{
	LanguageInspector* tWindow = (LanguageInspector*)userData;
	
	if( !tWindow->tima ){ [tWindow fadeOut]; }
	
	tWindow->fadetima = 0L;
}

static pascal void fadeLoop( EventLoopTimerRef inTimer, void* userData )
{
	LanguageInspector* tWindow = (LanguageInspector*)userData;
	
	TimerManagement();
	
	if( (tWindow->windowAlpha != 0.0) || (tWindow->windowAlpha != 1.0) )
	{
		[tWindow setAlphaValue:tWindow->windowAlpha];
	}
}

static pascal void highlightLoop( EventLoopTimerRef inTimer, void* userData )
{
	LanguageInspector* tWindow = (LanguageInspector*)userData;
	
	TimerManagement();
	
	//[tWindow->getWindow setFrame:tWindow->highlightRect display:YES];
	
	[tWindow->getWindow setAlphaValue:tWindow->highlightWindowAlpha];
}

static pascal void highlightMoveLoop( EventLoopTimerRef inTimer, void* userData )
{
	LanguageInspector* tWindow = (LanguageInspector*)userData;
	
	Point pointAsCarbonPoint;

	GetMouse( &pointAsCarbonPoint );	

	//AXUIElementRef 		newElement = NULL;

	tWindow->valuePoint.x = pointAsCarbonPoint.h;
	tWindow->valuePoint.y = pointAsCarbonPoint.v;
	
	//if( AXUIElementCopyElementAtPosition( TApp->systemWideElement, pointAsCGPoint.x, pointAsCGPoint.y, &newElement ) == kAXErrorSuccess && newElement )
	{
		//if( !CFEqual( TApp->currentUIElementRef, newElement ) )
		{
			[tWindow highlightPressed];
		}
	}
}

#pragma mark

@implementation LanguageInspector

#pragma mark UICallbacks

- (void) errClick:(id)sender
{
	[[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/UniversalAccessPref.prefPane"];
}

- (void) fontSizeChange:(id)sender
{
	[webView setTextSizeMultiplier:([sender floatValue]/100.0) * 3.0];
	
	// Change the local copy to have the new value.  We don't need to write it to disk until we quit.
	NSString* theName = NSStringFromClass( [myModule class] );
	NSMutableDictionary* modT = [NSMutableDictionary dictionaryWithDictionary:[TApp->windowSettings objectForKey:theName]];
	[modT setObject:[sender stringValue] forKey:@"textSize"];
	[TApp->windowSettings setObject:modT forKey:theName];
}

#pragma mark Overridden

- (void) awakeFromNib
{
	//[self setBackgroundColor:[NSColor lightGrayColor]];
	
	tima = 0L;
	fadetima = 0L;
	
	highlighttima = 0L;
	highlightmovetima = 0L;
	holdtima = 0L;
	highLightFade = 0;
	
	holdVal = 0L;
	
	//[self reportMachineInfo];
	//[self setFrameUsingName:@"winstuff"];
	[self setHidesOnDeactivate:NO];
	
	windowAlpha = 0.0;
	[self setAlphaValue:windowAlpha];
	requestError = 0L;
	requestResponse = 0L;
	responseEncoding = 0;
	fullValue = 0L;
	selectedValue = 0L;
	individualValue = 0L;
	
	connectionLock = [[NSRecursiveLock alloc] init];
	connection = 0L;
	connectionData = 0L;

	baseURL = 0L;
	
	highlightRect = NSRectFromString(@"{{0, 0}, {200, 200}}");
	//getHighlight = [[HighlightView alloc] initWithFrame:NSRectFromString(@"{{0, 0}, {200, 200}}")];
	getHighlight->LI = self;
	//getWindow = [[NSPanel alloc] initWithContentRect:highlightRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
	getWindow = [[NSWindow alloc] initWithContentRect:highlightRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
	//[getWindow setBackgroundColor:[NSColor clearColor]];
	[getWindow setBackgroundColor:[NSColor blackColor]];
	[getWindow setOpaque:NO];
	[getWindow setIgnoresMouseEvents:YES];
	//[getWindow setFloatingPanel:YES];
	
	[getWindow setAlphaValue:0.0];
	//[getWindow setLevel:3];
	[getWindow makeKeyAndOrderFront:self];
	[getWindow setViewsNeedDisplay:YES];
	
	//getHighlight->textView = [[NSTextField alloc] initWithFrame:NSMakeRect(0.0, 0.0, 200.0, 200.0)];
	//getHighlight->textView = [[NSTextView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 200.0, 200.0)];
	//getHighlight->textView = [[NSText alloc] initWithFrame:NSMakeRect(0.0, 0.0, 200.0, 200.0)];
	
	//[getHighlight->textView setAutoresizingMask:NSViewMaxYMargin];

	//getHighlight->textView = [[NSTextField alloc] initWithFrame:NSMakeRect(0.0, 0.0, 200.0, 200.0)];
	//[getHighlight->textView setBordered:NO];
	//[getHighlight->textView setAutoresizingMask:NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin | NSViewWidthSizable | NSViewHeightSizable];
	
	//[getHighlight->textView setFont:[NSFont fontWithName:HIGHLIGHTFONT size:HIGHLIGHTSIZE]];
	[getHighlight->textView setFont:[NSFont systemFontOfSize:HIGHLIGHTSIZE]];
	
	
	//[getHighlight->textView setString:@"あ"]; // For some reason priming the textview with a unicode?/asian? character affects the spacing of roman characters
	
	//[getHighlight->textView setBounds:NSMakeRect(0.0, 0.0, 200.0, 200.0)];
	//[getHighlight setFrameOrigin:NSMakePoint(0.0, 0.0)];
	
	//[getHighlight addSubview:getHighlight->textView];
	
	//[getHighlight->textView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
	
	
	holdValid = false;
	expanding = false;
	
	highlightWindowAlpha = 0.0;
	
	//[getWindow setContentView:gHigh];
	[getWindow setContentView:getHighlight];
	//[getWindow setContentView:getHighlight->textView];
	
	
	/*rootLayer = [[CALayer alloc] init];
	[rootLayer setLayoutManager:[CAConstraintLayoutManager layoutManager]];
	[rootLayer setBackgroundColor:CGColorCreateGenericRGB( 0.0, 0.0, 0.0, 1.0 )];*/
	
	/*textStyle = [[NSDictionary dictionaryWithObjectsAndKeys:
	[NSNumber numberWithInteger:12], @"cornerRadius",
	[NSValue valueWithSize:NSMakeSize(5, 0)], @"margin",
	@"BankGothic-Light", @"font",
	[NSNumber numberWithInteger:12], @"fontSize",
	//kCAAlignmentCenter, @"alignmentMode",
	nil] retain];*/


	/*headerTextLayer = [[CATextLayer alloc] init];
	[headerTextLayer setName:@"header"];
	[headerTextLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX]];
	[headerTextLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX relativeTo:@"superlayer" attribute:kCAConstraintMaxX]];
	[headerTextLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY]];
	[headerTextLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY]];
	//[headerTextLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY relativeTo:@"superlayer" attribute:kCAConstraintMaxY offset:-10]];
	//[headerTextLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"header" attribute:kCAConstraintMaxY offset:-64]];
	//[headerTextLayer setAlignmentMode:kCAAlignmentCenter];
	//[headerTextLayer setString:@"Loading Images..."];
	//[headerTextLayer setStyle:textStyle];
	//[headerTextLayer setFontSize:12];
	[headerTextLayer setWrapped:YES];
	//[rootLayer addSublayer:headerTextLayer];*/
	
	//[getHighlight setLayer:rootLayer];
	//[getHighlight setWantsLayer:YES];

	//textStyle = [[NSDictionary dictionaryWithObjectsAndKeys:(NSFont*)[headerTextLayer font], NSFontAttributeName, nil] retain];
	pStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] retain];
	[pStyle setLineSpacing:-3.0];
	
	textStyle = [[NSDictionary dictionaryWithObjectsAndKeys:
    //[NSFont fontWithName:HIGHLIGHTFONT size:HIGHLIGHTSIZE], NSFontAttributeName,
	[NSFont systemFontOfSize:HIGHLIGHTSIZE], NSFontAttributeName,
	pStyle, NSParagraphStyleAttributeName,
	[NSNumber numberWithFloat:0.0], NSBaselineOffsetAttributeName, 
    //shadow, NSShadowAttributeName,
    //[NSColor whiteColor], NSForegroundColorAttributeName, 
    nil] retain];
	
	NSTextStorage *storage = [getHighlight->textView textStorage];
	NSRange range = NSMakeRange(0,[storage length]);
	[storage addAttributes:textStyle range:range];
	
	//[getHighlight->textView setDefaultParagraphStyle:pStyle];
	
	//[[getHighlight->textView layoutManager] setTypesetterBehavior:];
	
	firstPriority = 0;
	secondPriority = 0;
	thirdPriority = 0;

	//[progressBack setHidden:YES];
	
	//NSStringEncoding enc;
	//NSString* filePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/Contents/Resources/Intro.html"];
	NSString* filePath = [[NSBundle mainBundle] pathForResource:@"Intro" ofType:@"html" inDirectory:0L];
	
	alreadyLoading = true;
	
	[[webView mainFrame] loadHTMLString:[NSString stringWithContentsOfFile:filePath] baseURL:[NSURL fileURLWithPath:filePath]];
	
	[webView display];
	
	[webView setFrameLoadDelegate:self];
	
	//[webView setFrameLoadDelegate:self];
}

- (void) dealloc
{
	[connectionLock lock];
	
		if( connection ){ [connection cancel]; }
		if( connectionData ){ [connectionData release]; }
		
	[connectionLock unlock];
	
	[connectionLock release];
	
	[getWindow release];
	
	if( baseURL ){ [baseURL release]; }
	
	[super dealloc];
}

- (void) close
{
	[self fadeOut];
    //[super close];
    //[NSApp terminate:NULL];
}

#pragma mark Methods

- (NSStringEncoding) responseEncoding
{
	return responseEncoding;
}

- (NSString*) fullValue
{
	return (NSString*)fullValue;
}

- (NSString*) selectedValue
{
	return (NSString*)selectedValue;
}

- (NSString*) individualValue
{
	return (NSString*)individualValue;
}

- (void) setInput:(NSString*)input
{
	if(       fullValue ){       [(id)fullValue release];       fullValue = 0L; }
	if(   selectedValue ){   [(id)selectedValue release];   selectedValue = 0L; }
	if( individualValue ){ [(id)individualValue release]; individualValue = 0L; }
	
	if( input )
	{
		fullValue = [input retain];
		selectedValue = [input retain];
		individualValue = [input retain];
	}
}

- (void) setFullValue:(NSString*)input
{
	if( fullValue ){ [(id)fullValue release]; fullValue = 0L; }
	
	if( input ){ fullValue = [input retain]; }
}

- (void) setSelectedValue:(NSString*)input
{
	if( selectedValue ){ [(id)selectedValue release]; selectedValue = 0L; }

	if( input ){ selectedValue = [input retain]; }
}

- (void) setIndividualValue:(NSString*)input
{
	if( individualValue ){ [(id)individualValue release]; individualValue = 0L; }
	
	if( input ){ individualValue = [input retain]; }
}

- (void) startFadeTimer
{
	//NSLog(@"Fade starting...\n");
	if( fadetima ){ RemoveEventLoopTimer( fadetima ); }
	InstallEventLoopTimer( GetCurrentEventLoop(), kEventDurationSecond * fadesecs, 0, NewEventLoopTimerUPP( fade ), self, &fadetima );
}

#pragma mark

- (void) AXlookup
{
	if( fadetima ){ RemoveEventLoopTimer( fadetima ); }
	
	if( AXAPIEnabled() )
	{
		if( holdValid == false )
		{
			if( [self updateCurrentUIElement] )
			{
				[self displayLookup];
			}
		}
		else
		{
			[self setInput:holdVal];
			[self displayLookup];
		}
	}
	// If the AX API is not on then check every three seconds until it is.
	else
	{
		[errorbutton setHidden:NO];
		[myModule->UI setHidden:YES];
		InstallEventLoopTimer( GetCurrentEventLoop(), 0, kEventDurationSecond * 3, NewEventLoopTimerUPP( checkAXAPIStatus ), self, 0L );
		
		if( windowAlpha != 1.0 ){ [self fadeIn]; }
	}
}

- (bool) updateCurrentUIElement
{	
	//currentVswitch = random() % 2;
	
	//bool vres = verifyRegistrationB();
	//if( !currentVswitch ){ vres = !vres; }
	
	{
		[errorbutton setHidden:YES];
		[myModule->UI setHidden:NO];
		
		Point pointAsCarbonPoint;

		GetMouse( &pointAsCarbonPoint );		

		AXUIElementRef 		newElement = NULL;

		valuePoint.x = pointAsCarbonPoint.h;
		valuePoint.y = pointAsCarbonPoint.v;

		CGSConnection mainConID = CGSMainConnectionID();
			
		CPSProcessSerNum thaProc;
		CPSProcessSerNum thaProc2; thaProc2.lo = 0; thaProc2.hi = 0;
		CPSProcessSerNum thaProc3;
		
		OSErr err0 = CGSFindWindowAndOwner( mainConID, NULL, 1, NULL, &valuePoint, &thaProc, &thaProc2, &thaProc3 );

		if( AXUIElementCopyElementAtPosition( TApp->systemWideElement, valuePoint.x, valuePoint.y, &newElement ) == kAXErrorSuccess && newElement )		
		{
			if( TApp->currentUIElementRef ){ [(id)TApp->currentUIElementRef release]; }
			
			TApp->currentUIElementRef = newElement;
		
			CFTypeRef	roleType = 0L;
			
			AXUIElementCopyAttributeValue( TApp->currentUIElementRef, kAXRoleAttribute, &roleType );			
			
			/*CFTypeRef	thesizeRef;
			CFTypeRef	thepositionRef;

			CGSize		thasize;
			CGPoint		thapoint;
			
			AXUIElementCopyAttributeValue( TApp->currentUIElementRef, kAXSizeAttribute, &thesizeRef );
			AXUIElementCopyAttributeValue( TApp->currentUIElementRef, kAXPositionAttribute, &thepositionRef );			
			
			AXValueGetValue( (const __AXValue*)thesizeRef, kAXValueCGSizeType, &thasize );
			AXValueGetValue( (const __AXValue*)thepositionRef, kAXValueCGPointType, &thapoint );

			NSRect daRect = [[[NSScreen screens] objectAtIndex:0] frame];
			
			highlightRectORG = NSMakeRect( thapoint.x, daRect.size.height - thapoint.y - thasize.height, thasize.width, thasize.height );
			highlightRect = NSMakeRect( thapoint.x + thasize.width/2, daRect.size.height - thapoint.y - thasize.height + thasize.height/2, 1, 1 );
			
			[getWindow setFrame:highlightRect display:YES];
			[getWindow orderBack:self];

			OSStatus err = CGSOrderWindow( mainConID, GetNativeWindowFromWindowRef( (OpaqueWindowPtr*)[getWindow windowRef] ), kCGSOrderAbove, thaProc2.lo );
			
			InstallEventLoopTimer( GetCurrentEventLoop(), 0, kEventDurationSecond/60, NewEventLoopTimerUPP( highlightLoop ), self, &highlighttima );
			[Timer Object:self Data:&highlightRect.size.height Destination:thasize.height + 40 Method:@selector(linear:) Time:HIGHLIGHTTIME Flags:KILLOTHERS | SETDESTINATION];
			[Timer Object:self Data:&highlightRect.size.width Destination:thasize.width + 40 Method:@selector(linear:) Time:HIGHLIGHTTIME Flags:KILLOTHERS | SETDESTINATION];
			[Timer Object:self Data:&highlightRect.origin.x Destination:thapoint.x - 20 Method:@selector(linear:) Time:HIGHLIGHTTIME Flags:KILLOTHERS | SETDESTINATION];
			[Timer Object:self Data:&highlightRect.origin.y Destination:daRect.size.height - thapoint.y - thasize.height - 20 Method:@selector(linear:) Time:HIGHLIGHTTIME CallbackObject:self Callback:@selector(expandedHighlight) Flags:KILLOTHERS | SETDESTINATION];
			
			highlightWindowAlpha  = 1.0;
			[getWindow setAlphaValue:highlightWindowAlpha];*/
			
			
			
			
			//NSLog(@"%@\n", roleType);
			
			if(       fullValue ){       [(NSString*)fullValue release];       fullValue = 0L; }
			if(   selectedValue ){   [(NSString*)selectedValue release];   selectedValue = 0L; }
			if( individualValue ){ [(NSString*)individualValue release]; individualValue = 0L; }
			
			// Get the text to translate
			
			// kAXStaticTextRole
			// kAXPopUpButtonRole
			if( CFEqual( roleType, kAXStaticTextRole ) ||
				CFEqual( roleType, kAXPopUpButtonRole ) )				
			{
				AXUIElementCopyAttributeValue( TApp->currentUIElementRef, kAXValueAttribute, &fullValue );				
				
				if( !err0 )
				{
					CPSProcessSerNum	myProcSerial;
					CPSProcessInfoRec	pInfo;

					OSErr err1 = CPSGetWindowOwner( thaProc2.lo, &myProcSerial);
					
					if( !err1 )
					{
						OSErr err2 = CPSGetProcessInfo( &myProcSerial, &pInfo, NULL, NULL, NULL, NULL, NULL );
						
						if( !err2 )
						{
							// Ask that process for the text :) WARNING, WILL NOT WORK IF BEING DEBUGGED (maybe?)
							CFMessagePortRef dictPort = CFMessagePortCreateRemote( NULL, (__CFString*)[NSString stringWithFormat:@"com.apple.DictionaryServiceComponent-%d", pInfo.UnixPID]);
							
							if( dictPort )
							{
								CFDataRef requestParameters = CFPropertyListCreateXMLData( NULL, [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:100], @"length", 0L] );
								CFDataRef returnData = 0L;
								
								// 200 the individual word?
								// 201 the word boundaries?
								// 202 the attributed string?
								
								SInt32 res = CFMessagePortSendRequest( dictPort, 200, requestParameters, 5, 5, kCFRunLoopDefaultMode, &returnData);
								
								if( res == kCFMessagePortSuccess )
								{
									CFPropertyListRef thaRetDict = CFPropertyListCreateFromXMLData( NULL, returnData, NULL, NULL );
									
									if( thaRetDict )
									{
										#ifdef DEBUG
										//NSArray* aK = [thaRetDict allKeys];
										//for(int i = 0; i < [aK count]; i++)
										//{
										//	NSLog(@"%@ - %@", [aK objectAtIndex:i], [thaRetDict objectForKey:[aK objectAtIndex:i]]);
										//}
										#endif
									
										NSString* thaText = [(NSDictionary*)thaRetDict objectForKey:@"text"];
										
										if( thaText )
										{
											int jstart = 0;
											while( jstart < [thaText length] )
											{
												if( whitespaceCharacter( [(NSString*)thaText characterAtIndex:jstart] ) ){ jstart++; }else{ break; }
											}
											
											int j = 0;
											while( j < [thaText length] )
											{
												if( whitespaceCharacter( [(NSString*)thaText characterAtIndex:j] ) ){ break; }else{ j++; }
											}
											
											if( j == [thaText length] ){ j = [thaText length] - 1; }
											NSRange R2 = NSMakeRange( jstart, j );
											
											individualValue = [[thaText substringWithRange:R2] retain];
										}
										else
										{
											#ifdef DEBUG
											NSLog(@"DictLookup thaText is 0L.\n");
											#endif
										}
									
										CFRelease( thaRetDict );
									}
									else
									{
										#ifdef DEBUG
										NSLog(@"DictLookup thaRetDict is 0L.\n");
										#endif
									}
									
									CFRelease( returnData );
								}
								else
								{
									#ifdef DEBUG
									NSLog(@"DictLookup CFMessagePortSendRequest: %d\n", res);
									#endif
								}
								
								CFRelease( requestParameters );
								CFRelease( dictPort );
							}
						}
							
						//NSLog(@"indiv: %@", (NSString*)individualValue);
					}
				}
			}
			// kAXTextFieldRole
			// kAXTextAreaRole
			// kAXComboBoxRole
			// AXDateTimeArea
			else if( CFEqual( roleType, kAXTextFieldRole ) ||
					 CFEqual( roleType, kAXTextAreaRole ) ||
					 CFEqual( roleType, kAXComboBoxRole ) ||
					 CFEqual( roleType, CFSTR("AXDateTimeArea") ) )					
			{
				AXUIElementCopyAttributeValue( TApp->currentUIElementRef, kAXValueAttribute, &fullValue );
				AXUIElementCopyAttributeValue( TApp->currentUIElementRef, kAXSelectedTextAttribute, &selectedValue );
				
				if( (fullValue != nil) && [fullValue length] )
				{
					CFTypeRef parameter = AXValueCreate(kAXValueCGPointType, &valuePoint);
					CFTypeRef value = 0L;
					AXError err = AXUIElementCopyParameterizedAttributeValue( TApp->currentUIElementRef, kAXRangeForPositionParameterizedAttribute, parameter, &value);
					
					CFRange decodedValue;
					if( AXValueGetValue((__AXValue*)value, kAXValueCFRangeType, &decodedValue) ) 
					{
						NSRange R = NSMakeRange(decodedValue.location, decodedValue.length);
						
						if( R.length )
						{
							while( (R.location < [fullValue length] - 1) && whitespaceCharacter( [(NSString*)fullValue characterAtIndex:R.location] ) ){ R.location++; }
							
							int i = R.location;
							while( i >= 0 )
							{
								if( whitespaceCharacter( [(NSString*)fullValue characterAtIndex:i] ) ){ i++; break; }else{ i--; }
							}
							
							int j = R.location;
							while( j < [(NSString*)fullValue length] )
							{
								if( whitespaceCharacter( [(NSString*)fullValue characterAtIndex:j] ) ){ break; }else{ j++; }
							}
							
							if( i == -1 ){ i = 0; }
							if( j == [(NSString*)fullValue length] ){ j = [(NSString*)fullValue length]; }
							
							NSRange R2 = NSMakeRange( i, j - i );
							CFTypeRef parameter2 = AXValueCreate(kAXValueCFRangeType, &R2);
							
							err = AXUIElementCopyParameterizedAttributeValue( TApp->currentUIElementRef, kAXStringForRangeParameterizedAttribute, parameter2, &individualValue);
							
							/*CFTypeRef	theBoundsRef;
							CGRect		theBounds;
							
							err = AXUIElementCopyParameterizedAttributeValue( TApp->currentUIElementRef, kAXBoundsForRangeParameterizedAttribute, parameter2, &theBoundsRef);
							
							AXValueGetValue( (const __AXValue*)theBoundsRef, kAXValueCGRectType, &theBounds );
							
							
							NSRange R3 = NSMakeRange( 0, [(NSString*)fullValue length] );
							CFTypeRef parameter3 = AXValueCreate(kAXValueCFRangeType, &R3);
							err = AXUIElementCopyParameterizedAttributeValue( TApp->currentUIElementRef, kAXBoundsForRangeParameterizedAttribute, parameter3, &theBoundsRef);
							AXValueGetValue( (const __AXValue*)theBoundsRef, kAXValueCGRectType, &theBounds );
							
							int poi = 0;*/
							
							if( parameter2 ){ [(id)parameter2 release]; }
						}
					}
					
					if( parameter ){ [(id)parameter release]; }
					if( value ){ [(id)value release]; }
				}
				
				//NSLog(@"indiv: %@", (NSString*)individualValue);
			}
			// kAXMenuButtonRole
			// kAXWindowRole
			// kAXRadioButtonRole
			// kAXMenuItemRole
			// kAXMenuBarItemRole
			// kAXButtonRole
			// kAXCheckBoxRole
			// kAXSortButtonSubrole
			// kAXImageRole
			// AXFinderItem
			// kAXDockItemRole
			else if( CFEqual( roleType, kAXMenuButtonRole ) ||
					 CFEqual( roleType, kAXWindowRole ) ||
					 CFEqual( roleType, kAXRadioButtonRole ) ||
					 CFEqual( roleType, kAXMenuItemRole ) ||
					 CFEqual( roleType, kAXMenuBarItemRole ) ||
					 CFEqual( roleType, kAXButtonRole ) ||
					 CFEqual( roleType, kAXCheckBoxRole ) ||
					 CFEqual( roleType, kAXSortButtonSubrole ) ||
					 CFEqual( roleType, kAXImageRole ) ||
					 CFEqual( roleType, CFSTR("AXFinderItem") ) ||
					 CFEqual( roleType, kAXDockItemRole ) )			
			{
				AXUIElementCopyAttributeValue( TApp->currentUIElementRef, kAXTitleAttribute, &fullValue );				
				
				if( fullValue ){ individualValue = [[NSString alloc] initWithString:(NSString*)fullValue]; }
			}
			// If it didn't get any of the standard Roles
			else
			{
				#ifdef DEBUG
				//NSLog(@"Unknown kAXRoleAttribute\n");
				#endif
			
				AXError err = AXUIElementCopyAttributeValue( TApp->currentUIElementRef, kAXTitleAttribute, &individualValue );
				
				if( err != kAXErrorSuccess )
				{
					//err = AXUIElementCopyAttributeValue( TApp->currentUIElementRef, kAXValueAttribute, &individualValue );					
				}
			}
			
			if( [(NSString*)individualValue isEqualToString:@""] || [(NSString*)individualValue isEqualToString:@" "] ){ [(NSString*)individualValue release]; individualValue = 0L; }
			if(   [(NSString*)selectedValue isEqualToString:@""] ||   [(NSString*)selectedValue isEqualToString:@" "] ){   [(NSString*)selectedValue release];   selectedValue = 0L; }
			if(       [(NSString*)fullValue isEqualToString:@""] ||       [(NSString*)fullValue isEqualToString:@" "] ){       [(NSString*)fullValue release];       fullValue = 0L; }
			
			[(id)roleType release];
			
			//[self displayLookup];
			return true;
		}
				
		//NSLog(@"indiv: %@\n", (NSString*)individualValue);
		//NSLog(@"selected: %@\n", (NSString*)selectedValue);
		//NSLog(@"full: %@\n", (NSString*)fullValue);
	}
	
	return false;
}

- (void) displayLookup
{
	if( fullValue || selectedValue || individualValue )
	{
		[self orderFrontRegardless];
		[self makeKeyWindow];
		
		if( baseURL ){ [baseURL release]; baseURL = 0L; }
		
		switch( pluginType )
		{
			case LAWEBSERVICEMODULE:
			{
				// Get Request from module
				/*NSURLRequest* theirrequest = [(LAWebServicePlugin*)myModule createQueryFull:(NSString*)fullValue selected:(NSString*)selectedValue individual:(NSString*)individualValue];
				NSMutableURLRequest* request = [theirrequest mutableCopy];
				NSLog([webView customUserAgent]);*/
				
				NSURLRequest* request = 0L;
				
				if( [(LAWebServicePlugin*)myModule respondsToSelector:@selector(createQueryFull:selected:individual:preferred:)] )
				{
					request = [(LAWebServicePlugin*)myModule createQueryFull:(NSString*)fullValue selected:(NSString*)selectedValue individual:(NSString*)individualValue preferred:(NSString*)[self getPriorityValue]];
				}
				else if( [(LAWebServicePlugin*)myModule respondsToSelector:@selector(createQueryFull:selected:individual:)] )
				{
					request = [(LAWebServicePlugin*)myModule createQueryFull:(NSString*)fullValue selected:(NSString*)selectedValue individual:(NSString*)individualValue];
				}
				else
				{
					NSLog(@"This inspector doesn't seem to respond to either createQueryFull:selected:individual:preferred: or createQueryFull:selected:individual:\n" );
				}
				
				//[request setValue:[webView customUserAgent] forHTTPHeaderField:@"User-Agent"];
				
				if( request && [request isKindOfClass:[NSURLRequest class]] )
				{
					baseURL = [[request URL] retain];

					[ballSpin startAnimation:self];
					
					//NSData* responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&requestResponse error:&requestError];
					
					[connectionLock lock];
					
						if( connection ){ [connection cancel]; }
						
						if( connectionData ){ [connectionData release]; }
						connectionData = [[NSMutableData alloc] initWithCapacity:4096];
						
						connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
					
					[connectionLock unlock];
				}
				else
				{
					NSString* filePath = [[NSBundle mainBundle] pathForResource:@"RequestError" ofType:@"html" inDirectory:0L];
	
					[[webView mainFrame] loadHTMLString:[NSString stringWithContentsOfFile:filePath] baseURL:[NSURL fileURLWithPath:filePath]];
					[webView display];
				}
			} break;
			
			case LAOTHERMODULE:
			{
				[ballSpin startAnimation:self];
				
				[NSThread detachNewThreadSelector:@selector(otherThread:) toTarget:self withObject:self];
			} break;
		}
		
		if( windowAlpha != 1.0 ){ [self fadeIn]; }
	}
	else
	{
		if( windowAlpha != 1.0 ){ if( fades ){ [self startFadeTimer]; } [self fadeIn]; }
		else{ [self fadeOut]; }
	}
}

#pragma mark

- (void) otherThread:(id)thing
{
	////[ballSpin stopAnimation:self];
	
	//// Try to cut the caches down?
	/*[[WebHistory optionalSharedHistory] removeAllItems];
	
	WebBackForwardList *backForwardList = [webView backForwardList]; 
	unsigned cacheSize = [backForwardList pageCacheSize];
	[backForwardList setPageCacheSize:0];
	[backForwardList setPageCacheSize:cacheSize];*/
	////
		
	// Get filtered results from module
	NSString* filter = 0L;
	
	if( [(LAOtherPlugin*)myModule respondsToSelector:@selector(resultOfQueryFull:selected:individual:preferred:)] )
	{
		filter = [(LAOtherPlugin*)myModule resultOfQueryFull:(NSString*)fullValue selected:(NSString*)selectedValue individual:(NSString*)individualValue preferred:(NSString*)[self getPriorityValue]];
	}
	else if( [(LAOtherPlugin*)myModule respondsToSelector:@selector(resultOfQueryFull:selected:individual:)] )
	{
		filter = [(LAOtherPlugin*)myModule resultOfQueryFull:(NSString*)fullValue selected:(NSString*)selectedValue individual:(NSString*)individualValue];
	}
	else
	{
		NSLog(@"This inspector doesn't seem to respond to either createQueryFull:selected:individual:preferred: or createQueryFull:selected:individual:\n" );
	}
		
	alreadyLoading = true;
	
	if( filter && [filter isKindOfClass:[NSString class]] )
	{
		// Actually display the content now
		[[webView mainFrame] loadHTMLString:filter baseURL:[(LAOtherPlugin*)myModule baseURL]]; [filter release];
		[webView display];
	}
	else
	{
		NSString* filePath = [[NSBundle mainBundle] pathForResource:@"FilterError" ofType:@"html" inDirectory:0L];
	
		[[webView mainFrame] loadHTMLString:[NSString stringWithContentsOfFile:filePath] baseURL:[NSURL fileURLWithPath:filePath]];
		[webView display];
	}
	
	if( fades ){ [self startFadeTimer]; }
	
	// Can't rely on image count
	//if( numImages == 0 ){ numImages = _dyld_image_count(); }
	
	// I forget, do I even need anything here? Shouldn't I move all "connection" like stuff into the web service only class?
	[connectionLock lock];
	
		if( connectionData ){ [connectionData release]; } connectionData = 0L;
		connection = 0L;
	
	[connectionLock unlock];
}

- (int) getDomintantPriority
{
	int domintantPriority = 0L;
					
	bool gotit = false;
	
	switch( firstPriority )
	{
		case 1: { if(       fullValue ){ domintantPriority = 1; gotit = true; } } break;
		case 2: { if(   selectedValue ){ domintantPriority = 2; gotit = true; } } break;
		case 3: { if( individualValue ){ domintantPriority = 3; gotit = true; } } break;
	}
	
	if( !gotit )
	{
		switch( secondPriority )
		{
			case 1: { if(       fullValue ){ domintantPriority = 1; gotit = true; } } break;
			case 2: { if(   selectedValue ){ domintantPriority = 2; gotit = true; } } break;
			case 3: { if( individualValue ){ domintantPriority = 3; gotit = true; } } break;
		}
	}
	
	if( !gotit )
	{
		switch( thirdPriority )
		{
			case 1: { if(       fullValue ){ domintantPriority = 1; } } break;
			case 2: { if(   selectedValue ){ domintantPriority = 2; } } break;
			case 3: { if( individualValue ){ domintantPriority = 3; } } break;
		}
	}
	
	return domintantPriority;
}

- (const void*) getPriorityValue
{
	const void* preferredValue = 0L;
					
	bool gotit = false;
	
	switch( firstPriority )
	{
		case 1: { if(       fullValue ){ preferredValue =       fullValue; gotit = true; } } break;
		case 2: { if(   selectedValue ){ preferredValue =   selectedValue; gotit = true; } } break;
		case 3: { if( individualValue ){ preferredValue = individualValue; gotit = true; } } break;
	}
	
	if( !gotit )
	{
		switch( secondPriority )
		{
			case 1: { if(       fullValue ){ preferredValue =       fullValue; gotit = true; } } break;
			case 2: { if(   selectedValue ){ preferredValue =   selectedValue; gotit = true; } } break;
			case 3: { if( individualValue ){ preferredValue = individualValue; gotit = true; } } break;
		}
	}
	
	if( !gotit )
	{
		switch( thirdPriority )
		{
			case 1: { if(       fullValue ){ preferredValue =       fullValue; } } break;
			case 2: { if(   selectedValue ){ preferredValue =   selectedValue; } } break;
			case 3: { if( individualValue ){ preferredValue = individualValue; } } break;
		}
	}
	
	return preferredValue;
}

- (void) setPriority:(NSArray*)priorities
{
	int j = 0;
	for( int i = 0; i < [priorities count]; i++ )
	{
		NSString* p = [priorities objectAtIndex:i];
		
		if( [p isKindOfClass:[NSString class]] )
		{
			if( [p isEqualToString:FULLVALUE] )
			{
				     if( j == 0 ){  firstPriority = 1; j++; }
				else if( j == 1 ){ secondPriority = 1; j++; }
				else if( j == 2 ){  thirdPriority = 1; break; }
			}
			else if( [p isEqualToString:SELECTEDVALUE] )
			{
					 if( j == 0 ){  firstPriority = 2; j++; }
				else if( j == 1 ){ secondPriority = 2; j++; }
				else if( j == 2 ){  thirdPriority = 2; break; }
			}
			else if( [p isEqualToString:INDIVIDUALVALUE] )
			{
					 if( j == 0 ){  firstPriority = 3; j++; }
				else if( j == 1 ){ secondPriority = 3; j++; }
				else if( j == 2 ){  thirdPriority = 3; break; }
			}
		}
	}
}

#pragma mark NSURL callbacks

- (void) connection:(NSURLConnection*)daCon didReceiveData:(NSData*)data
{
	[connectionLock lock];
	
		if( connectionData ){ [connectionData appendData:data];}
		
	[connectionLock unlock];
}

- (void) connection:(NSURLConnection*)daCon didFailWithError:(NSError*)error
{
	NSLog([error localizedDescription]);

	////[ballSpin stopAnimation:self];

	//// Try to cut the caches down?
	/*[[WebHistory optionalSharedHistory] removeAllItems];
	
	WebBackForwardList *backForwardList = [webView backForwardList]; 
	unsigned cacheSize = [backForwardList pageCacheSize];
	[backForwardList setPageCacheSize:0];
	[backForwardList setPageCacheSize:cacheSize];*/
	////
	
	//NSString* filePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/Contents/Resources/ConnectError.html"];
	NSString* filePath = [[NSBundle mainBundle] pathForResource:@"ConnectError" ofType:@"html" inDirectory:0L];
	
	[[webView mainFrame] loadHTMLString:[NSString stringWithContentsOfFile:filePath] baseURL:[NSURL fileURLWithPath:filePath]];
	[webView display];
	
	[connectionLock lock];
	
		if( connectionData ){ [connectionData release]; } connectionData = 0L;
		connection = 0L;
		[requestResponse release]; requestResponse = 0L;
		responseEncoding = 0;
	
	[connectionLock unlock];
	
	//[daCon release];
}

- (void) connectionDidFinishLoading:(NSURLConnection*)daCon
{
	////[ballSpin stopAnimation:self];
	
	//// Try to cut the caches down?
	/*[[WebHistory optionalSharedHistory] removeAllItems];
	
	WebBackForwardList *backForwardList = [webView backForwardList]; 
	unsigned cacheSize = [backForwardList pageCacheSize];
	[backForwardList setPageCacheSize:0];
	[backForwardList setPageCacheSize:cacheSize];*/
	////
	
	[connectionLock lock];
	
	if( connectionData )
	{
		// Get filtered results from module
		NSString* filter = [(LAWebServicePlugin*)myModule filterResult:connectionData];
				
		alreadyLoading = true;
		
		if( filter && [filter isKindOfClass:[NSString class]] )
		{
			// Actually display the content now
			[[webView mainFrame] loadHTMLString:filter baseURL:baseURL]; [filter release];
			[[webView backForwardList] addItem:[[WebHistoryItem alloc] initWithURLString:[baseURL absoluteString] title:@"" lastVisitedTimeInterval:0.0]];
			[webView display];
		}
		else
		{
			NSString* filePath = [[NSBundle mainBundle] pathForResource:@"FilterError" ofType:@"html" inDirectory:0L];
		
			[[webView mainFrame] loadHTMLString:[NSString stringWithContentsOfFile:filePath] baseURL:[NSURL fileURLWithPath:filePath]];
			[webView display];
		}
		
		if( fades ){ [self startFadeTimer]; }
		
		//if( numImages == 0 ){ numImages = _dyld_image_count(); }
		
		[connectionData release]; connectionData = 0L;
	}
	
	connection = 0L;
	
	[connectionLock unlock];
	
	//[daCon release];
}

- (NSURLRequest*) connection:(NSURLConnection*)daCon willSendRequest:(NSURLRequest*)request redirectResponse:(NSURLResponse*)redirectResponse
{
	/*if( baseURL ){ [baseURL release]; }*/ baseURL = [request URL];
	
	/*NSMutableURLRequest* newReq = [request mutableCopy];
    [newReq setValue:[webView customUserAgent] forHTTPHeaderField:@"User-Agent"];
    return [newReq autorelease];*/
	
	return request;
}

- (void) connection:(NSURLConnection*)daCon didReceiveResponse:(NSURLResponse*)response
{
	if( requestResponse ){ [requestResponse release]; requestResponse = 0L; }
	requestResponse = [response retain];
	NSString* encodingName = [requestResponse textEncodingName];
	
	responseEncoding = NSISOLatin1StringEncoding; // NSUTF8StringEncoding?
   
	if( encodingName )
	{
		CFStringEncoding CoreFoundationEncoding = CFStringConvertIANACharSetNameToEncoding( (CFStringRef)encodingName );
	   
		if( CoreFoundationEncoding != kCFStringEncodingInvalidId )
		{
			responseEncoding = CFStringConvertEncodingToNSStringEncoding( CoreFoundationEncoding );
		}
	}
}

#pragma mark WebView callbacks

- (void) webView:(WebView*)WV didStartProvisionalLoadForFrame:(WebFrame*)WF
{
	[ballSpin startAnimation:self];
}

//- (void) webView:(WebView*)WV didStartProvisionalLoadForFrame:(WebFrame*)WF
- (void) webView:(WebView*)WV didFinishLoadForFrame:(WebFrame*)WF
//- (void) webView:(WebView*)WV didChangeLocationWithinPageForFrame:(WebFrame*)WF
//- (void) webView:(WebView*)WV didCommitLoadForFrame:(WebFrame*)WF
//- (void) webView:(WebView*)WV didReceiveTitle:(NSString*) forFrame:(WebFrame*)WF
//- (void) webView:(WebView*)WV didFirstLayoutInFrame:(WebFrame*)WF
//- (void) webView:(WebView*)WV didHandleOnloadEventsForFrame:(WebFrame*)WF
{
	if( [WV mainFrame] == WF )
	{
		[ballSpin stopAnimation:self];
	
		if( alreadyLoading ){ alreadyLoading = false; }
		else
		{
			alreadyLoading = true;
			
			NSString* thing = [WV mainFrameURL];
			NSURL* thaURL = [NSURL URLWithString:thing];
			
			if( [myModule filterLoad:thaURL] == YES )
			{
				//NSLog(@"Got here!\n");
				
				//DOMDocument* DD = [WF DOMDocument];
				//DOMHTMLElement* DE = [DD documentElement];
				//NSData* result = [[DE outerHTML] dataUsingEncoding:NSISOLatin1StringEncoding];
				
				WebDataSource* DS = [[WV mainFrame] dataSource];
				NSData* result = [DS data];
				
				[WV stopLoading:self];
				
				// Get filtered results from module
				NSString* filter = [(LAWebServicePlugin*)myModule filterResult:result];
				
				if( filter && [filter isKindOfClass:[NSString class]] )
				{
					// Actually display the content now
					[[webView mainFrame] loadHTMLString:filter baseURL:thaURL]; [filter release];
					//[[webView backForwardList] addItem:[[WebHistoryItem alloc] initWithURLString:[baseURL absoluteString] title:@"" lastVisitedTimeInterval:0.0]];
					[webView display];
				}
			}
		}
	}
}

#pragma mark Fader routines

- (void) stopTime
{
	if( tima ){ RemoveEventLoopTimer( tima ); tima = 0L; }
	if( timaUPP ){ DisposeEventLoopTimerUPP(timaUPP); timaUPP = 0; }
}

/*- (void) fadeOut
{
	[self stopTime];
	timaUPP = NewEventLoopTimerUPP( fadeLoop );
	InstallEventLoopTimer( GetCurrentEventLoop(), 0, kEventDurationSecond/60, timaUPP, self, &tima );
	[Timer Object:self Data:&windowAlpha Destination:0.0 Method:@selector(linear:) Time:0.25 CallbackObject:self Callback:@selector(stopTime) Flags:KILLOTHERS | SETDESTINATION];
}

- (void) fadeIn
{
	[self orderFrontRegardless];
	[self makeKeyWindow];
	[self stopTime];
	timaUPP = NewEventLoopTimerUPP( fadeLoop );
	InstallEventLoopTimer( GetCurrentEventLoop(), 0, kEventDurationSecond/60, timaUPP, self, &tima );
	[Timer Object:self Data:&windowAlpha Destination:1.0 Method:@selector(linear:) Time:0.25 CallbackObject:self Callback:@selector(stopTime) Flags:KILLOTHERS | SETDESTINATION];
}*/

- (void) fadeOut
{
	windowAlpha = 0.0;
	[self setAlphaValue:windowAlpha];
}

- (void) fadeIn
{
	[self orderFrontRegardless];
	[self makeKeyWindow];
	windowAlpha = 1.0;
	[self setAlphaValue:windowAlpha];
}

- (void) highlightFadedIn
{
	highLightFade = 0;
	if( highlighttima ){ RemoveEventLoopTimer( highlighttima ); highlighttima = 0L; }
	if( highlighttimaUPP ){ DisposeEventLoopTimerUPP(highlighttimaUPP); highlighttimaUPP = 0; }
}

- (void) highlightFadeIn
{
	highlighttimaUPP = NewEventLoopTimerUPP( highlightLoop );
	[Timer Object:self Data:&highlightWindowAlpha Destination:1.0 Method:@selector(linear:) Time:HIGHLIGHTTIME CallbackObject:self Callback:@selector(highlightFadedIn) Flags:KILLOTHERS | SETDESTINATION];
	InstallEventLoopTimer( GetCurrentEventLoop(), 0, kEventDurationSecond/60, highlighttimaUPP, self, &highlighttima );
	highLightFade = 0;
}

- (void) highlightFadeOut
{
	if( highLightFade != -1 )
	{
		highLightFade = -1;
		if( highlighttima ){ RemoveEventLoopTimer( highlighttima ); highlighttima = 0L; }
		if( highlighttimaUPP ){ DisposeEventLoopTimerUPP(highlighttimaUPP); highlighttimaUPP = 0; }
		highlighttimaUPP = NewEventLoopTimerUPP( highlightLoop );
		[Timer Object:self Data:&highlightWindowAlpha Destination:0.0 Method:@selector(linear:) Time:HIGHLIGHTTIME CallbackObject:self Callback:@selector(highlightFadedIn) Flags:KILLOTHERS | SETDESTINATION];
		InstallEventLoopTimer( GetCurrentEventLoop(), 0, kEventDurationSecond/60, highlighttimaUPP, self, &highlighttima );
	}
}

#pragma mark Highlight routines

- (void) expandedHighlight
{
	[Timer Object:self Data:&highlightRect.size.height Destination:highlightRectORG.size.height Method:@selector(linear:) Time:HIGHLIGHTTIME Flags:KILLOTHERS | SETDESTINATION];
	[Timer Object:self Data:&highlightRect.size.width Destination:highlightRectORG.size.width Method:@selector(linear:) Time:HIGHLIGHTTIME Flags:KILLOTHERS | SETDESTINATION];
	[Timer Object:self Data:&highlightRect.origin.x Destination:highlightRectORG.origin.x Method:@selector(linear:) Time:HIGHLIGHTTIME Flags:KILLOTHERS | SETDESTINATION];
	[Timer Object:self Data:&highlightRect.origin.y Destination:highlightRectORG.origin.y Method:@selector(linear:) Time:HIGHLIGHTTIME Flags:KILLOTHERS | SETDESTINATION];
	
	[Timer Object:self Data:&highlightWindowAlpha Destination:0.0 Method:@selector(linear:) Time:HIGHLIGHTTIME CallbackObject:self Callback:@selector(contractHighlight) Flags:KILLOTHERS | SETDESTINATION];
	
	//InstallEventLoopTimer( GetCurrentEventLoop(), 0, kEventDurationSecond/60, NewEventLoopTimerUPP( fadeLoop ), self, &tima );
	//[Timer Object:self Data:&windowAlpha Destination:1.0 Method:@selector(linear:) Time:0.25 CallbackObject:self Callback:@selector(stopTime) Flags:KILLOTHERS | SETDESTINATION];
}

- (void) contractHighlight
{
	RemoveEventLoopTimer( highlighttima );
	[getWindow orderOut:self];
}

- (bool) highlightPressed
{
	bool shouldhighlightexpand = false;

	if( holdValid )
	{
		if( !highlightmovetima )
		{
			InstallEventLoopTimer( GetCurrentEventLoop(), 0, kEventDurationSecond/10, NewEventLoopTimerUPP( highlightMoveLoop ), self, &highlightmovetima );
		}
	
		if( [self updateCurrentUIElement] )
		{
			shouldhighlightexpand = true;
		
			if( individualValue || selectedValue || fullValue )
			{
				NSString* priorityVal = (NSString*)[self getPriorityValue];
				
				if( ![[getHighlight->textView string] isEqualToString:priorityVal] )
				{
					if( holdVal ){ [holdVal release]; } holdVal = [priorityVal copy];
					highlightWindowAlpha = 0.0;
					[getWindow setAlphaValue:highlightWindowAlpha];
					
					//[getHighlight->textView setString:@"あ"]; // For some reason priming the textview with a unicode?/asian? character affects the spacing of roman characters
					[getHighlight->textView setNeedsDisplay:YES];
					[getHighlight->textView setString:priorityVal];
					[getHighlight->textView setFont:[NSFont systemFontOfSize:HIGHLIGHTSIZE]];
					NSFont* f = [getHighlight->textView font];
					/*NSAffineTransform* at = [f textTransform];
					NSAffineTransformStruct ats = [at transformStruct];
					NSLayoutManager* lm = [getHighlight->textView layoutManager];
					NSLog( @"%@ %f %f %f %f %f %f %f\n", [f fontName], [f ascender], [f descender], [f leading], [f xHeight], ats.tX, ats.tY, [lm defaultBaselineOffsetForFont:f] );*/
					
					[pStyle setLineSpacing:LINESPACING - [f leading]/2];
					if( textStyle ){ [textStyle release]; }
					textStyle = [[NSDictionary dictionaryWithObjectsAndKeys:
					f, NSFontAttributeName,
					//[NSFont systemFontOfSize:HIGHLIGHTSIZE], NSFontAttributeName,
					pStyle, NSParagraphStyleAttributeName,
					[NSNumber numberWithFloat:BASELINEOFFSET - [f leading]/2], NSBaselineOffsetAttributeName, 
					//shadow, NSShadowAttributeName,
					//[NSColor whiteColor], NSForegroundColorAttributeName, 
					nil] retain];
					
					NSTextStorage *storage = [getHighlight->textView textStorage];
					NSRange range = NSMakeRange(0,[storage length]);
					[storage setAttributes:textStyle range:range];



					NSRect daRect, daMainRect;
					daMainRect = [[NSScreen mainScreen] frame];
					NSArray* ar = [NSScreen screens];
					int i;
					for( i = 0; i < [ar count]; i++ )
					{
						daRect = [[ar objectAtIndex:i] frame];
						if( (valuePoint.x >= daRect.origin.x) && (valuePoint.x < daRect.size.width + daRect.origin.x) && (valuePoint.y >= daRect.origin.y) && (valuePoint.y < daRect.size.height + daRect.origin.y) ){ break;	}
					}
					
					NSSize sSize; sSize.width = daRect.size.width; sSize.height = daRect.size.height;
					
					NSAttributedString* pVal = [[NSAttributedString alloc] initWithString:priorityVal attributes:textStyle];
					NSRect bounds = [pVal boundingRectWithSize:sSize options:(NSStringDrawingOptions)nil];
					bounds.size.width += 12.0;
					bounds.size.height += [[NSParagraphStyle defaultParagraphStyle] lineSpacing];
					[pVal release];
					
					float a = sqrt( (bounds.size.width * bounds.size.height)/(daRect.size.height/daRect.size.width) );
					//float b = (bounds.size.width * bounds.size.height)/a;
					
					if( bounds.size.width < daRect.size.width/3 ){ a = bounds.size.width; }
					else if( a < daRect.size.width/3 ){ a = daRect.size.width/3; }
					else if( a > daRect.size.width/2 ){ a = daRect.size.width/2; }
					
					NSRect currentHighlightRectORG = NSMakeRect( valuePoint.x, daMainRect.size.height - valuePoint.y, ceilf(a), 15 );

					if( currentHighlightRectORG.size.width && currentHighlightRectORG.size.height )
					{
						/*CGSConnection mainConID = CGSMainConnectionID();

						CPSProcessSerNum thaProc;
						CPSProcessSerNum thaProc2; thaProc2.lo = 0; thaProc2.hi = 0;
						CPSProcessSerNum thaProc3;

						OSErr err0 = CGSFindWindowAndOwner( mainConID, NULL, 1, NULL, &valuePoint, &thaProc, &thaProc2, &thaProc3 );

						OSStatus err = CGSOrderWindow( mainConID, GetNativeWindowFromWindowRef( (OpaqueWindowPtr*)[getWindow windowRef] ), kCGSOrderAbove, thaProc2.lo );
						//OSStatus err = CGSOrderWindow( mainConID, GetNativeWindowFromWindowRef( (OpaqueWindowPtr*)[getWindow windowRef] ), kCGSOrderAbove, 0 );*/
						[getWindow setLevel:NSScreenSaverWindowLevel - 1];
						
						//if( !err0 && !err )
						//if( !err0 )
						{
							[getWindow setFrame:currentHighlightRectORG display:YES];
							NSRect dafr = [getHighlight->textView frame];
							currentHighlightRectORG.size.height = dafr.size.height + 10.0;

							/*while( (bounds.size.width < daRect.size.width/3) && (dafr.size.height > 40) ) // this number needs to be gererated by something..
							{
								currentHighlightRectORG.size.width += 2;
								currentHighlightRectORG.size.height = 1;
								[getWindow setFrame:currentHighlightRectORG display:YES];
								dafr = [getHighlight->textView frame];
							}
							currentHighlightRectORG.size.height = dafr.size.height;
							
							if( currentHighlightRectORG.size.height == 1 )
							{
								int blah = 1;
							}*/
							
							// Center the highlight
							currentHighlightRectORG.origin.x -= currentHighlightRectORG.size.width/2;
							
							// Make sure it doesn't go offscreen
							if( currentHighlightRectORG.origin.x < daRect.origin.x + HIGHLIGHTEDGETHRESH ){ currentHighlightRectORG.origin.x = daRect.origin.x + HIGHLIGHTEDGETHRESH; }
							if( currentHighlightRectORG.origin.x + currentHighlightRectORG.size.width > daRect.origin.x + daRect.size.width - HIGHLIGHTEDGETHRESH ){ currentHighlightRectORG.origin.x = daRect.origin.x + daRect.size.width - (currentHighlightRectORG.size.width + HIGHLIGHTEDGETHRESH); }
							if( currentHighlightRectORG.origin.y < daRect.origin.y + HIGHLIGHTEDGETHRESH ){ currentHighlightRectORG.origin.y = daRect.origin.y + HIGHLIGHTEDGETHRESH; }
							if( currentHighlightRectORG.origin.y + currentHighlightRectORG.size.height > daRect.origin.y + daRect.size.height - HIGHLIGHTEDGETHRESH ){ currentHighlightRectORG.origin.y = daRect.origin.y + daRect.size.height - (currentHighlightRectORG.size.height + HIGHLIGHTEDGETHRESH); }
							
							// Cut it off if it is too big
							//if( currentHighlightRectORG.origin.y + currentHighlightRectORG.size.height > daRect.size.height - HIGHLIGHTEDGETHRESH )
							//{
							//	currentHighlightRectORG.size.height = daRect.size.height - HIGHLIGHTEDGETHRESH - currentHighlightRectORG.origin.y;
							//}
							if( currentHighlightRectORG.origin.y < daRect.origin.y + HIGHLIGHTEDGETHRESH )
							{
								currentHighlightRectORG.size.height = daRect.size.height - HIGHLIGHTEDGETHRESH * 2;
								currentHighlightRectORG.origin.y = daRect.origin.y + HIGHLIGHTEDGETHRESH;
							}
							
							[getWindow setFrame:currentHighlightRectORG display:YES];
							
							//[getWindow setAlphaValue:1.0];
							if( highlighttima ){ RemoveEventLoopTimer( highlighttima ); highlighttima = 0L; }
							if( highLightFade == 0 )
							{
								KillTimers( &highlightWindowAlpha );
								highlightWindowAlpha = 1.0; [getWindow setAlphaValue:highlightWindowAlpha];
							}
							else if( highLightFade == 1 )
							{
								[self highlightFadeIn];
							}
							
							expanding = true;
						}
					}
				}
			}
		}
	}
	else
	{
		if( highlightmovetima ){ RemoveEventLoopTimer( highlightmovetima ); highlightmovetima = 0L; }
		
		[self highlightFadeOut];
	}
	
	return shouldhighlightexpand;
}


/*- (bool) highlightPressed
{
	bool shouldhighlightexpand = false;

	if( holdValid )
	{
		if( !highlightmovetima )
		{
			InstallEventLoopTimer( GetCurrentEventLoop(), 0, kEventDurationSecond/10, NewEventLoopTimerUPP( highlightMoveLoop ), self, &highlightmovetima );
		}

		if( [self updateCurrentUIElement] )
		{
			shouldhighlightexpand = true;
		
			if( individualValue || selectedValue || fullValue )
			{
				//
				NSRect daRect = [[[NSScreen screens] objectAtIndex:0] frame]; // Fix this for multimonitor support eventually

				NSAttributedString* pVal = [[NSAttributedString alloc] initWithString:(NSString*)[self getPriorityValue] attributes:textStyle];
				//NSAttributedString* pVal = [[NSAttributedString alloc] initWithString:(NSString*)[self getPriorityValue]];
				//NSString* pVal = (NSString*)[self getPriorityValue];
				[headerTextLayer setString:pVal];
				[getHighlight->textView setString:(NSString*)[self getPriorityValue]];
				//[getHighlight->textView setTitleWithMnemonic:(NSString*)[self getPriorityValue]];
				//[getHighlight->textView ];
				
				//[getHighlight->textView sizeToFit];
				NSRect dafr = [getHighlight->textView frame];
				NSLog(@"%f %f %f %f\n", dafr.origin.x, dafr.origin.y, dafr.size.width, dafr.size.height);
				//NSRect currentHighlightRectORG = NSMakeRect( valuePoint.x, daRect.size.height - valuePoint.y, dafr.size.width + dafr.origin.x, dafr.size.height + dafr.origin.y );
				//NSRect currentHighlightRectORG = NSMakeRect( valuePoint.x, daRect.size.height - valuePoint.y, 300.0, 300.0 );
				//NSRect currentHighlightRectORG = NSMakeRect( valuePoint.x, daRect.size.height - valuePoint.y, dafr.size.width, dafr.size.height );
				//NSTextContainer* tc = [getHighlight->textView textContainer];
				//NSSize tcs = [tc containerSize];
				//NSRect currentHighlightRectORG = NSMakeRect( valuePoint.x, daRect.size.height - valuePoint.y, tcs.width, tcs.height );
				//[getHighlight->textView setFrame:NSMakeRect(0.0, 0.0, dafr.size.width, dafr.size.height - dafr.origin.y)];
				//NSRect currentHighlightRectORG = NSMakeRect( valuePoint.x, daRect.size.height - valuePoint.y, dafr.size.width + dafr.origin.x, dafr.size.height + dafr.origin.y );

				//[getHighlight->textView setString:pVal];
				//[headerTextLayer setString:(NSString*)[self getPriorityValue]];
				//NSSize bounds = [pVal sizeWithAttributes:textStyle];
				NSRect bounds = [pVal boundingRectWithSize:NSSizeFromString(@"{1920,1200}") options:nil];
				bounds.size.height += [[NSParagraphStyle defaultParagraphStyle] lineSpacing];
				//NSLog(@"%f\n", [[NSParagraphStyle defaultParagraphStyle] lineSpacing]);
				
				float a = sqrt( (bounds.size.width * bounds.size.height)/(daRect.size.height/daRect.size.width) );
				float b = (bounds.size.width * bounds.size.height)/a;
				NSRect currentHighlightRectORG = NSMakeRect( valuePoint.x, daRect.size.height - valuePoint.y, ceilf(a), b );
				//NSRect currentHighlightRectORG = NSMakeRect( valuePoint.x, daRect.size.height - valuePoint.y, a * 1.1, b * 1.1 );
				//NSRect currentHighlightRectORG = NSMakeRect( valuePoint.x, daRect.size.height - valuePoint.y, bounds.width * 1.1, bounds.height );
				//NSRect currentHighlightRectORG = NSMakeRect( valuePoint.x, daRect.size.height - valuePoint.y, bounds.width, bounds.height );
				
				//CGRect bounds = [headerTextLayer frame];
				//NSRect currentHighlightRectORG = NSMakeRect( valuePoint.x, daRect.size.height - valuePoint.y, bounds.size.width, bounds.size.height );
				//

				//NSRect currentHighlightRectORG = NSMakeRect( valuePoint.x, daRect.size.height - valuePoint.y, bounds.size.width, bounds.size.height );

				if( currentHighlightRectORG.origin.x && currentHighlightRectORG.origin.y && currentHighlightRectORG.size.width && currentHighlightRectORG.size.height )
				{
					NSRect currentHighlightRect = NSMakeRect( currentHighlightRectORG.origin.x + currentHighlightRectORG.size.width/2, currentHighlightRectORG.origin.y + currentHighlightRectORG.size.height/2, 1, 1 );
					
					if( !NSEqualRects( highlightRectORG, currentHighlightRectORG ) )
					{
						highlightRectORG = currentHighlightRectORG;
						highlightRect = currentHighlightRect;
						
						
						[getWindow orderBack:self];
						
						CGSConnection mainConID = CGSMainConnectionID();

						CPSProcessSerNum thaProc;
						CPSProcessSerNum thaProc2; thaProc2.lo = 0; thaProc2.hi = 0;
						CPSProcessSerNum thaProc3;

						OSErr err0 = CGSFindWindowAndOwner( mainConID, NULL, 1, NULL, &valuePoint, &thaProc, &thaProc2, &thaProc3 );

						OSStatus err = CGSOrderWindow( mainConID, GetNativeWindowFromWindowRef( (OpaqueWindowPtr*)[getWindow windowRef] ), kCGSOrderAbove, thaProc2.lo );
						
						[[getWindow animator] setAlphaValue:1.0];
						[getWindow setFrame:highlightRectORG display:YES];
						dafr = [getHighlight->textView frame];
						NSLog(@"2 - %f %f %f %f\n", dafr.origin.x, dafr.origin.y, dafr.size.width, dafr.size.height);
						currentHighlightRectORG.size.height = dafr.size.height;
						[getWindow setFrame:currentHighlightRectORG display:YES];
						NSLog(@"3 - %f %f %f %f\n", currentHighlightRectORG.origin.x, currentHighlightRectORG.origin.y, currentHighlightRectORG.size.width, currentHighlightRectORG.size.height);
						
						highlightRectORG = currentHighlightRectORG;
						highlightRect = currentHighlightRect;
						
						
						expanding = true;
					}
					else
					{
						shouldhighlightexpand = false;
					}
				}
			}
		}
	}
	
	return shouldhighlightexpand;
}*/

/*- (bool) highlightPressed
{
	bool shouldhighlightexpand = false;
	
	if( holdValid )
	{
		getHighlight->initialOffset = 0;
		getHighlight->extraSpace = 0;
		getHighlight->fontHeight = 0;

		if( !highlightmovetima )
		{
			InstallEventLoopTimer( GetCurrentEventLoop(), 0, kEventDurationSecond/10, NewEventLoopTimerUPP( highlightMoveLoop ), self, &highlightmovetima );
		}
		
		Point pointAsCarbonPoint;

		GetMouse( &pointAsCarbonPoint );

		CGPoint				pointAsCGPoint;
		AXUIElementRef 		newElement = NULL;

		pointAsCGPoint.x = pointAsCarbonPoint.h;
		pointAsCGPoint.y = pointAsCarbonPoint.v;

		CGSConnection mainConID = CGSMainConnectionID();
			
		CPSProcessSerNum thaProc;
		CPSProcessSerNum thaProc2; thaProc2.lo = 0; thaProc2.hi = 0;
		CPSProcessSerNum thaProc3;
		
		OSErr err0 = CGSFindWindowAndOwner( mainConID, NULL, 1, NULL, &pointAsCGPoint, &thaProc, &thaProc2, &thaProc3 );

		if( AXUIElementCopyElementAtPosition( TApp->systemWideElement, pointAsCGPoint.x, pointAsCGPoint.y, &newElement ) == kAXErrorSuccess && newElement )		
		{
			if( TApp->currentUIElementRef ){ [(id)TApp->currentUIElementRef release]; }
			
			TApp->currentUIElementRef = newElement;
		
			CFTypeRef	roleType = 0L;
			
			AXUIElementCopyAttributeValue( TApp->currentUIElementRef, kAXRoleAttribute, &roleType );			
			
			
			NSRect currentHighlightRectORG = NSMakeRect(0,0,0,0);
			
			CFTypeRef	thesizeRef = 0L;
			CFTypeRef	thepositionRef = 0L;
			
			CGSize		thasize;
			CGPoint		thapoint;
			
			AXUIElementCopyAttributeValue( TApp->currentUIElementRef, kAXSizeAttribute, &thesizeRef );
			AXUIElementCopyAttributeValue( TApp->currentUIElementRef, kAXPositionAttribute, &thepositionRef );			
			
			NSRect daRect = [[[NSScreen screens] objectAtIndex:0] frame];
			
			if( AXValueGetValue( (const __AXValue*)thesizeRef, kAXValueCGSizeType, &thasize ) )
			{
				if( AXValueGetValue( (const __AXValue*)thepositionRef, kAXValueCGPointType, &thapoint ) )
				{
					currentHighlightRectORG = NSMakeRect( thapoint.x, daRect.size.height - thapoint.y - thasize.height, thasize.width, thasize.height );
					//NSRect currentHighlightRect = NSMakeRect( thapoint.x + thasize.width/2, daRect.size.height - thapoint.y - thasize.height + thasize.height/2, 1, 1 );
				}
			}
			if(     thesizeRef ){     CFRelease(thesizeRef); }
			if( thepositionRef ){ CFRelease(thepositionRef); }
			
			//NSLog(@"%@\n", roleType);
			
			if(       fullValue ){       [(NSString*)fullValue release];       fullValue = 0L; }
			if(   selectedValue ){   [(NSString*)selectedValue release];   selectedValue = 0L; }
			if( individualValue ){ [(NSString*)individualValue release]; individualValue = 0L; }
			
			shouldhighlightexpand = true;
			
			// Get the text to translate
			
			// kAXStaticTextRole
			// kAXPopUpButtonRole
			if( CFEqual( roleType, kAXStaticTextRole ) ||
				CFEqual( roleType, kAXPopUpButtonRole ) )				
			{
				AXUIElementCopyAttributeValue( TApp->currentUIElementRef, kAXValueAttribute, &fullValue );
				
				// Did we aquire the window and its owner?
				if( !err0 )
				{
					CPSProcessSerNum	myProcSerial;
					CPSProcessInfoRec	pInfo;

					OSErr err1 = CPSGetWindowOwner( thaProc2.lo, &myProcSerial);
					
					if( !err1 )
					{
						OSErr err2 = CPSGetProcessInfo( &myProcSerial, &pInfo, NULL, NULL, NULL, NULL, NULL );
						
						if( !err2 )
						{
							// Ask that process for the text :) WARNING, WILL NOT WORK IF BEING DEBUGGED (maybe?)
							CFMessagePortRef dictPort = nil;
							NSDictionary* requestPacket = nil;
							int messageId = 0;
							
							// 10.5
							if( CFMessagePortCreatePerProcessRemote )
							{
								dictPort = CFMessagePortCreatePerProcessRemote( NULL, (__CFString*)@"com.apple.DictionaryServiceComponent", pInfo.UnixPID );
								requestPacket = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:50], @"length", [NSNumber numberWithInt:processRemoteID++], @"transactionID", 0L];
								messageId = 100;
							}
							// 10.4
							else
							{
								dictPort = CFMessagePortCreateRemote( NULL, (__CFString*)[NSString stringWithFormat:@"com.apple.DictionaryServiceComponent-%d", pInfo.UnixPID]);
								requestPacket = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:100], @"length", 0L];
								messageId = 200;
							}

							if( dictPort )
							{
								CFDataRef requestParameters = CFPropertyListCreateXMLData( NULL, requestPacket );
								CFDataRef returnData = 0L;

								// 100/200 the individual word
								SInt32 res = CFMessagePortSendRequest( dictPort, messageId, requestParameters, 5, 5, kCFRunLoopDefaultMode, &returnData);
								
								while( CFDataGetLength( returnData ) == 0  )
								{
									printf("%d\n", processRemoteID);
									requestPacket = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:50], @"length", [NSNumber numberWithInt:processRemoteID++], @"transactionID", 0L];
									res = CFMessagePortSendRequest( dictPort, messageId, CFPropertyListCreateXMLData( NULL, requestPacket ), 5, 5, kCFRunLoopDefaultMode, &returnData);
								}
								
								if( res == kCFMessagePortSuccess )
								{
									CFPropertyListRef thaRetDict = CFPropertyListCreateFromXMLData( NULL, returnData, NULL, NULL );
									
									if( thaRetDict )
									{
										#ifdef DEBUG
										//NSLog([thaRetDict description]);
										//
										//NSArray* aK = [thaRetDict allKeys];
										//for(int i = 0; i < [aK count]; i++)
										//{
										//	NSLog(@"%@ - %@", [aK objectAtIndex:i], [thaRetDict objectForKey:[aK objectAtIndex:i]]);
										//}
										#endif
									
										NSString* thaText = [(NSDictionary*)thaRetDict objectForKey:@"text"];
										
										if( thaText )
										{
											int jstart = 0;
											while( jstart < [thaText length] )
											{
												if( whitespaceCharacter( [(NSString*)thaText characterAtIndex:jstart] ) ){ jstart++; }else{ break; }
											}
										
											int j = 0;
											while( j < [thaText length] )
											{
												if( whitespaceCharacter( [(NSString*)thaText characterAtIndex:j] ) ){ break; }else{ j++; }
											}
											
											if( j == [thaText length] ){ j = [thaText length] - 1; }
											NSRange R2 = NSMakeRange( jstart, j );
											
											individualValue = [[thaText substringWithRange:R2] retain];
											
											//
											
											
											CFDataRef requestParameters2 = CFPropertyListCreateXMLData( NULL, [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1751216737], @"textref", [NSNumber numberWithInt:0], @"offset", [NSNumber numberWithInt:[individualValue length]], @"length", 0L] );
											CFDataRef returnData2 = 0L;
											
											// 202 the attributes
											SInt32 res = CFMessagePortSendRequest( dictPort, 202, requestParameters2, 5, 5, kCFRunLoopDefaultMode, &returnData2 );
								
											if( res == kCFMessagePortSuccess )
											{
												CFPropertyListRef thaRetDict2 = CFPropertyListCreateFromXMLData( NULL, returnData2, NULL, NULL );
												
												if( thaRetDict2 )
												{
													NSTextStorage* nas = [[NSTextStorage alloc] initWithRTF:[thaRetDict2 objectForKey:@"attribute data"] documentAttributes:0L];
													NSFont* dafont = [nas font];
													
													//NSLog([nas description]);
													
													NSRect bounds = [individualValue boundingRectWithSize:[individualValue sizeWithAttributes:[nas attributesAtIndex:0 effectiveRange:0L]] options:NSStringDrawingUsesDeviceMetrics attributes:[nas attributesAtIndex:0 effectiveRange:0L]];
													
													if( [self getDomintantPriority] == 3 )
													{
														CFDataRef requestParameters3 = CFPropertyListCreateXMLData( NULL, [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1751216737], @"textref", [NSNumber numberWithInt:0], @"offset", [NSNumber numberWithInt:[individualValue length]], @"length", 0L] );
														CFDataRef returnData3 = 0L;
									
														// 201 the word origin
														SInt32 res = CFMessagePortSendRequest( dictPort, 201, requestParameters3, 5, 5, kCFRunLoopDefaultMode, &returnData3);
											
														if( res == kCFMessagePortSuccess )
														{
															CFPropertyListRef thaRetDict3 = CFPropertyListCreateFromXMLData( NULL, returnData3, NULL, NULL );
															
															if( thaRetDict3 )
															{
																//NSLog([(id)thaRetDict3 description]);
																
																NSPoint dapos = NSPointFromString( [thaRetDict3 objectForKey:@"origin"] );
																
																currentHighlightRectORG = NSMakeRect( dapos.x, daRect.size.height - dapos.y, bounds.size.width, bounds.size.height );
																
																CFRelease( thaRetDict3 );
															}
															
															CFRelease( returnData3 );
														}
													}
													
													if( [self getDomintantPriority] == 1 )
													{
														// If that process is Safari then get the bounds of its parent if the text wraps
														if( GetPIDForProcessName("Safari") == pInfo.UnixPID )
														{
															// Get the rect of the string
															NSRect fullbounds = [fullValue boundingRectWithSize:[fullValue sizeWithAttributes:[nas attributesAtIndex:0 effectiveRange:0L]] options:NSStringDrawingUsesDeviceMetrics attributes:[nas attributesAtIndex:0 effectiveRange:0L]];
															
															if( fullbounds.size.width > currentHighlightRectORG.size.width )
															{
																AXUIElementRef	theparentRef = 0L;
																CFTypeRef		parentRoleType = 0L;
																
																AXUIElementCopyAttributeValue( TApp->currentUIElementRef, kAXParentAttribute, (const void**)&theparentRef );																
																
																if( theparentRef )
																{
																	AXUIElementCopyAttributeValue( theparentRef, kAXRoleAttribute, &parentRoleType );
																	
																	if( parentRoleType )
																	{
																		if( CFEqual( parentRoleType, kAXGroupRole ) )
																		{
																			CFTypeRef	theParentsizeRef = 0L;
																			CFTypeRef	theParentpositionRef = 0L;
																			
																			CGSize		thaParentsize;
																			CGPoint		thaParentpoint;
																			
																			AXUIElementCopyAttributeValue( theparentRef, kAXSizeAttribute, &theParentsizeRef );
																			AXUIElementCopyAttributeValue( theparentRef, kAXPositionAttribute, &theParentpositionRef );
																			
																			if( AXValueGetValue( (const __AXValue*)theParentsizeRef, kAXValueCGSizeType, &thaParentsize ) )
																			{
																				if( AXValueGetValue( (const __AXValue*)theParentpositionRef, kAXValueCGPointType, &thaParentpoint ) )
																				{
																					getHighlight->initialOffset = thapoint.x - thaParentpoint.x;
																					getHighlight->extraSpace = (getHighlight->initialOffset + (int)thasize.width) % (int)thaParentsize.width;
																					getHighlight->fontHeight = thasize.height;
																					
																					currentHighlightRectORG = NSMakeRect( thaParentpoint.x, daRect.size.height - thaParentpoint.y - thaParentsize.height, thaParentsize.width, thaParentsize.height );
																					//NSRect currentHighlightRect = NSMakeRect( thapoint.x + thasize.width/2, daRect.size.height - thapoint.y - thasize.height + thasize.height/2, 1, 1 );
																				}
																			}
																			
																			if(     theParentsizeRef ){     CFRelease(theParentsizeRef); }
																			if( theParentpositionRef ){ CFRelease(theParentpositionRef); }
																		}
																	
																		CFRelease(parentRoleType);
																	}
																	
																	CFRelease(theparentRef);
																}
															}
														}
													}
													
													CFRelease( thaRetDict2 );
												}
												
												CFRelease( returnData2 );
											}
											
										}
										else
										{
											#ifdef DEBUG
											NSLog(@"DictLookup thaText is 0L.\n");
											#endif
										}
									
										CFRelease( thaRetDict );
									}
									else
									{
										#ifdef DEBUG
										NSLog(@"DictLookup thaRetDict is 0L.\n");
										#endif
									}
									
									CFRelease( returnData );
								}
								else
								{
									#ifdef DEBUG
									NSLog(@"DictLookup CFMessagePortSendRequest: %d\n", res);
									#endif
								}
								
								CFRelease( requestParameters );
								CFRelease( dictPort );
							}
						}
						
						//NSLog(@"indiv: %@", (NSString*)individualValue);
					}
				}
			}
			// kAXTextFieldRole
			// kAXTextAreaRole
			// kAXComboBoxRole
			// AXDateTimeArea
			else if( CFEqual( roleType, kAXTextFieldRole ) ||
					 CFEqual( roleType, kAXTextAreaRole ) ||
					 CFEqual( roleType, kAXComboBoxRole ) ||
					 CFEqual( roleType, CFSTR("AXDateTimeArea") ) )					
			{
				NSRange fullRange;
				NSRange selectedRange;
				NSRange individualRange;
				
				// fullValue
				AXUIElementCopyAttributeValue( TApp->currentUIElementRef, kAXValueAttribute, &fullValue );				
				fullRange = NSMakeRange( 0, [(NSString*)fullValue length] );
				
				// selectedValue
				CFTypeRef selRangeRef = 0L;
				AXUIElementCopyAttributeValue( TApp->currentUIElementRef, kAXSelectedTextAttribute, &selectedValue );
				AXError err = AXUIElementCopyAttributeValue( TApp->currentUIElementRef, kAXSelectedTextRangeAttribute, &selRangeRef);
				AXValueGetValue((__AXValue*)selRangeRef, kAXValueCFRangeType, &selectedRange);
				if( [(NSString*)selectedValue isEqualToString:@""] ){ [(NSString*)selectedValue release]; selectedValue = 0L; }
				
				// individualValue
				CFTypeRef parameter = AXValueCreate(kAXValueCGPointType, &pointAsCGPoint);
				CFTypeRef value = 0L;
				err = AXUIElementCopyParameterizedAttributeValue( TApp->currentUIElementRef, kAXRangeForPositionParameterizedAttribute, parameter, &value);
				
				CFRange decodedValue;
				if( AXValueGetValue((__AXValue*)value, kAXValueCFRangeType, &decodedValue) ) 
				{
					NSRange R = NSMakeRange(decodedValue.location, decodedValue.length);
					
					if( R.length )
					{
						while( (R.location < [fullValue length] - 1) && whitespaceCharacter( [(NSString*)fullValue characterAtIndex:R.location] ) ){ R.location++; }
					
						int i = R.location;
						while( i >= 0 )
						{
							if( whitespaceCharacter( [(NSString*)fullValue characterAtIndex:i] ) ){ i++; break; }else{ i--; }
						}
						
						int j = R.location;
						while( j < [(NSString*)fullValue length] )
						{
							if( whitespaceCharacter( [(NSString*)fullValue characterAtIndex:j] ) ){ break; }else{ j++; }
						}
						
						if( i == -1 ){ i = 0; }
						if( j == [(NSString*)fullValue length] ){ j = [(NSString*)fullValue length]; }
						
						NSRange R2 = NSMakeRange( i, j - i );
						CFTypeRef parameter2 = AXValueCreate(kAXValueCFRangeType, &R2);
						
						err = AXUIElementCopyParameterizedAttributeValue( TApp->currentUIElementRef, kAXStringForRangeParameterizedAttribute, parameter2, &individualValue);
						
						individualRange = R2;
					}
				}
				//else
				//{
				//	int gothere = 1;
				//}
				
				// Now alter the rect according to the priority
				CFTypeRef	parameter3;
				CFTypeRef	theBoundsRef;
				
				int dominantPriority = [self getDomintantPriority];
				//NSLog(@"indiv: %@", (NSString*)individualValue);
				//NSLog(@"selected: %@", (NSString*)selectedValue);
				if( dominantPriority )
				{
					switch( dominantPriority )
					{
						case 1: { parameter3 = AXValueCreate(kAXValueCFRangeType, &fullRange);	     } break;
						case 2: { parameter3 = AXValueCreate(kAXValueCFRangeType, &selectedRange);	 } break;
						case 3: { parameter3 = AXValueCreate(kAXValueCFRangeType, &individualRange); } break;
					}
					
					err = AXUIElementCopyParameterizedAttributeValue( TApp->currentUIElementRef, kAXBoundsForRangeParameterizedAttribute, parameter3, &theBoundsRef );
					AXValueGetValue( (const __AXValue*)theBoundsRef, kAXValueCGRectType, &currentHighlightRectORG );
					currentHighlightRectORG.origin.y = daRect.size.height - currentHighlightRectORG.origin.y - currentHighlightRectORG.size.height;
				}
				//NSLog(@"indiv: %@", (NSString*)individualValue);
			}
			// kAXMenuButtonRole
			// kAXRadioButtonRole
			// kAXMenuItemRole
			// kAXMenuBarItemRole
			// kAXButtonRole
			// kAXCheckBoxRole
			// kAXSortButtonSubrole
			// kAXImageRole
			// AXFinderItem
			// kAXDockItemRole
			else if( CFEqual( roleType, kAXMenuButtonRole ) ||
					 CFEqual( roleType, kAXWindowRole ) ||
					 CFEqual( roleType, kAXRadioButtonRole ) ||
					 CFEqual( roleType, kAXMenuItemRole ) ||
					 CFEqual( roleType, kAXMenuBarItemRole ) ||
					 CFEqual( roleType, kAXButtonRole ) ||
					 CFEqual( roleType, kAXCheckBoxRole ) ||
					 CFEqual( roleType, kAXSortButtonSubrole ) ||
					 CFEqual( roleType, kAXImageRole ) ||
					 CFEqual( roleType, CFSTR("AXFinderItem") ) ||
					 CFEqual( roleType, kAXDockItemRole ) )
			{
				AXUIElementCopyAttributeValueTRIP( TApp->currentUIElementRef, kAXTitleAttribute, &fullValue );
				
				if( fullValue )
				{
					individualValue = [[NSString alloc] initWithString:(NSString*)fullValue];
				}
			}
			// Can grab text from but not highlightable
			// kAXWindowRole
			else if( CFEqual( roleType, kAXWindowRole ) )
			{
				shouldhighlightexpand = false;
			}
			// If it didn't get any of the standard Roles
			else
			{
				#ifdef DEBUG
				//NSLog(@"Unknown kAXRoleAttribute\n");
				#endif
			
				AXError err = AXUIElementCopyAttributeValue( TApp->currentUIElementRef, kAXTitleAttribute, &individualValue );
				
				if( err != kAXErrorSuccess )
				{
					err = AXUIElementCopyAttributeValue( TApp->currentUIElementRef, kAXValueAttribute, &individualValue );
				}
				
				shouldhighlightexpand = false;
			}
			
			if( [(NSString*)individualValue isEqualToString:@""] || [(NSString*)individualValue isEqualToString:@" "] ){ [(NSString*)individualValue release]; individualValue = 0L; }
			if(   [(NSString*)selectedValue isEqualToString:@""] ||   [(NSString*)selectedValue isEqualToString:@" "] ){   [(NSString*)selectedValue release];   selectedValue = 0L; }
			if(       [(NSString*)fullValue isEqualToString:@""] ||       [(NSString*)fullValue isEqualToString:@" "] ){       [(NSString*)fullValue release];       fullValue = 0L; }
			
			if( shouldhighlightexpand )
			{
				if( individualValue || selectedValue || fullValue )
				{
					if( currentHighlightRectORG.origin.x && currentHighlightRectORG.origin.y && currentHighlightRectORG.size.width && currentHighlightRectORG.size.height )
					{
						NSRect currentHighlightRect = NSMakeRect( currentHighlightRectORG.origin.x + currentHighlightRectORG.size.width/2, currentHighlightRectORG.origin.y + currentHighlightRectORG.size.height/2, 1, 1 );
						
						if( !NSEqualRects( highlightRectORG, currentHighlightRectORG ) )
						{
							highlightRectORG = currentHighlightRectORG;
							highlightRect = currentHighlightRect;
							
							[getWindow setFrame:highlightRect display:YES];
							[getWindow orderBack:self];

							OSStatus err = CGSOrderWindow( mainConID, GetNativeWindowFromWindowRef( (OpaqueWindowPtr*)[getWindow windowRef] ), kCGSOrderAbove, thaProc2.lo );
							
							InstallEventLoopTimer( GetCurrentEventLoop(), 0, kEventDurationSecond/60, NewEventLoopTimerUPP( highlightLoop ), self, &highlighttima );
							[Timer Object:self Data:&highlightRect.size.height Destination:currentHighlightRectORG.size.height + 40 Method:@selector(linear:) Time:HIGHLIGHTTIME Flags:KILLOTHERS | SETDESTINATION];
							[Timer Object:self Data:&highlightRect.size.width Destination:currentHighlightRectORG.size.width + 40 Method:@selector(linear:) Time:HIGHLIGHTTIME Flags:KILLOTHERS | SETDESTINATION];
							[Timer Object:self Data:&highlightRect.origin.x Destination:currentHighlightRectORG.origin.x - 20 Method:@selector(linear:) Time:HIGHLIGHTTIME Flags:KILLOTHERS | SETDESTINATION];
							//[Timer Object:self Data:&highlightRect.origin.y Destination:currentHighlightRectORG.origin.y - 20 Method:@selector(linear:) Time:HIGHLIGHTTIME CallbackObject:self Callback:@selector(expandedHighlight) Flags:KILLOTHERS | SETDESTINATION];
							[Timer Object:self Data:&highlightRect.origin.y Destination:currentHighlightRectORG.origin.y - 20 Method:@selector(linear:) Time:HIGHLIGHTTIME Flags:KILLOTHERS | SETDESTINATION];
							
							highlightWindowAlpha = 1.0;
							[getWindow setAlphaValue:highlightWindowAlpha];
							
							expanding = true;
						}
						else
						{
							shouldhighlightexpand = false;
						}
					}
				}
			}
			else
			{
				
			}
			
			[(id)roleType release];
		}
	}
	else
	{
		//[self setAcceptsMouseMovedEvents:NO];
		if( highlightmovetima ){ RemoveEventLoopTimer( highlightmovetima ); highlightmovetima = 0L; }
	}
	
	return shouldhighlightexpand;
}*/

@end
