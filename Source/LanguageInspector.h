// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import <ApplicationServices/ApplicationServices.h>
#import <WebKit/Webkit.h>

#import <QuartzCore/QuartzCore.h>

#import "Timing.h"
#import "Input.h"
#import "LAPlugin.h"
#import "HighlightView.h"

@class HighlightView;

@interface LanguageInspector : NSPanel
{
	@public
	IBOutlet WebView*				webView;
	IBOutlet NSProgressIndicator*	ballSpin;
	IBOutlet NSSlider*				textMultiplier;
	IBOutlet NSButton*				errorbutton;
	IBOutlet NSBox*					moduleFieldBox;
	
	int								fades;
	int								fadesecs;
	float							fadeholder;
	
	NSError*						requestError;
	NSURLResponse*					requestResponse;
	NSStringEncoding				responseEncoding;
	
	CFTypeRef						fullValue;				// Where the junk to query actually get dumped into
	CFTypeRef						selectedValue;
	CFTypeRef						individualValue;
	
	float							windowAlpha;
	
	int								type;
	
	EventLoopTimerRef				tima;
	EventLoopTimerRef				fadetima;
	
	EventLoopTimerRef				highlighttima;
	EventLoopTimerRef				highlightmovetima;
	
	LAPlugin*						myModule;
	int								pluginType;
	
	NSRecursiveLock*				connectionLock;
	NSURLConnection*				connection;
	NSMutableData*					connectionData;
	
	NSURL*							baseURL;
	
	NSWindow*						getWindow;
	IBOutlet HighlightView*			getHighlight;
	NSRect							highlightRect;
	NSRect							highlightRectORG;
	
	float							highlightWindowAlpha;
	
	bool							holdValid;
	bool							expanding;
	
	int								firstPriority;
	int								secondPriority;
	int								thirdPriority;
	
	CGPoint							valuePoint;
	
	//CALayer*						rootLayer;
	//CATextLayer*					headerTextLayer;
	NSDictionary*					textStyle;
	NSMutableParagraphStyle*		pStyle;
	
	EventLoopTimerRef				holdtima;
	
	int								highLightFade;
	
	NSString*						holdVal;
	
	EventLoopTimerUPP				timaUPP;
	EventLoopTimerUPP				highlighttimaUPP;
}

- (void) setInput:(NSString*)input;

- (NSStringEncoding) responseEncoding;

- (NSString*) fullValue;
- (NSString*) selectedValue;
- (NSString*) individualValue;

- (void) setFullValue:(NSString*)input;
- (void) setSelectedValue:(NSString*)input;
- (void) setIndividualValue:(NSString*)input;

- (void) errClick:(id)sender;

- (bool) updateCurrentUIElement;
- (void) displayLookup;

- (void) fontSizeChange:(id)sender;

- (void) fadeOut;
- (void) fadeIn;

- (void) highlightFadedIn;
- (void) highlightFadeIn;
- (void) highlightFadeOut;

- (int) getDomintantPriority;
- (const void*) getPriorityValue;
- (void) setPriority:(NSArray*)priorities;

- (void) expandedHighlight;
- (void) contractHighlight;
- (bool) highlightPressed;

- (void) AXlookup;

- (void) startFadeTimer;

@end