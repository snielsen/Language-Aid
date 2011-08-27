// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import <LAPlugin.h>
#import <LAUserDefaults.h>

@interface Wikipedia : LAWebServicePlugin
{
	IBOutlet NSPopUpButton*			language;
	IBOutlet NSTextField*			searchBox;
	IBOutlet NSButton*				goButton;
	
	IBOutlet NSButton*				backButton;
	IBOutlet NSButton*				forwardButton;
	
	NSDictionary*					languages;
}

- (bool) setup;
+ (void) updateSettings;

// IB Callbacks

- (void) goAction:(id)sender;
- (void) languageChange:(id)sender;

- (void) hitBack:(id)sender;
- (void) hitForward:(id)sender;

@end