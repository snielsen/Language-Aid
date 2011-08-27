// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import "TIDError.h"

@implementation  TIDError

- (void) backTID:(id)sender
{
	daActualTID = 0L;

	[NSApp stopModal];
	[self close];
}

- (void) enterTID:(id)sender
{
	daActualTID = [[[[theTID stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString] retain];

	[NSApp stopModal];
	[self close];
}

@end
