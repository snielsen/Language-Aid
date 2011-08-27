// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import <LAPlugin.h>

@interface IMDB : LAWebServicePlugin
{
	IBOutlet NSButton*		backButton;
	IBOutlet NSButton*		forwardButton;
}

- (bool) setup;
+ (void) updateSettings;

// IB Callbacks

- (void) hitBack:(id)sender;
- (void) hitForward:(id)sender;

@end