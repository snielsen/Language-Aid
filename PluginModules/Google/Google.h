// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import <LAPlugin.h>

@interface Google : LAWebServicePlugin
{
	IBOutlet NSButton*		backButton;
	IBOutlet NSButton*		forwardButton;
			
	NSString*				usersLanguage;
}

- (bool) setup;

// IB Callbacks

- (void) hitBack:(id)sender;
- (void) hitForward:(id)sender;

@end