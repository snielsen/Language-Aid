// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import "RegistrationWindow.h"

@implementation RegistrationWindow


- (void) close
{
	//if( expanded )
	{
		if( !registrationKey && !prefPane->registering ){ [prefPane->serial setHidden:NO]; }
		
		/*NSView* v = [self mainView];
		[v setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
		NSWindow* w = [v window];
		NSRect f = [w frame];
		f.origin.y += PPHeight;
		f.size.height -= PPHeight;
		f.size.width = oldwidth;
		[w setFrame:f display:YES animate:YES];
		
		[paymentView setHidden:TRUE];*/
		
		//[self setHidden:TRUE];
		
		prefPane->expanded = false;
		
		[webpayProgress setHidden:YES];
	}
	
	[super close];
}

@end