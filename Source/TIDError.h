// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import <Cocoa/Cocoa.h>

@interface TIDError : NSWindow
{
	@public
	IBOutlet NSButton*					back;
	IBOutlet NSButton*					enter;
	
	IBOutlet NSTextField*				theTID;
	
	NSString*							daActualTID;
}

- (void) backTID:(id)sender;
- (void) enterTID:(id)sender;

@end
