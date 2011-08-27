// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import <LAPlugin.h>
#import <LAUserDefaults.h>

@interface GoogleTranslate : LAWebServicePlugin
{
	IBOutlet NSPopUpButton*		fromLanguage;
	IBOutlet NSPopUpButton*		toLanguage;
	
	NSDictionary*				fromLanguages;
	NSDictionary*				toLanguages;
}

- (bool) setup;
+ (void) updateSettings;

- (void) changeFromLanguage:(id)sender;
- (void) changeToLanguage:(id)sender;

@end