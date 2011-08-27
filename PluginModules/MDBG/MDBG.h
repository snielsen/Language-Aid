// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import <LAPlugin.h>
#import <LAUserDefaults.h>

@interface MDBG : LAWebServicePlugin
{
	IBOutlet NSPopUpButton*			mirror;
	
	IBOutlet NSPopUpButton*			charactersystem;
	IBOutlet NSPopUpButton*			resultstyle;
	IBOutlet NSMatrix*				pinyinstlye;
	
	IBOutlet NSButton*				backButton;
	IBOutlet NSButton*				forwardButton;
	
	NSDictionary*					mirrors;
	
	NSString*						lastrequest;
	int								requestdepth;
}

- (bool) setup;
+ (void) updateSettings;

// IB Callbacks

- (void) hitBack:(id)sender;
- (void) hitForward:(id)sender;

- (void) changeMirror:(id)sender;
- (void) changeCharacterSystem:(id)sender;
- (void) changeResultStyle:(id)sender;
- (void) changePinyinStyle:(id)sender;

- (void) goToMDBG:(id)sender;

@end