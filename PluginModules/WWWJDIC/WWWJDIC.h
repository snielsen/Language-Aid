// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import <LAPlugin.h>
#import <LAUserDefaults.h>

@interface WWWJDIC : LAWebServicePlugin
{
	IBOutlet NSPopUpButton*		dictionary;
	IBOutlet NSPopUpButton*		mirror;

	NSDictionary*				dictionaries;
	NSDictionary*				mirrors;
}

- (bool) setup;
+ (void) updateSettings;

// IB Callbacks

- (void) changeDictionary:(id)sender;
- (void) changeMirror:(id)sender;

@end