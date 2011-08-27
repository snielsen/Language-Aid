// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import "LanguageAidPref.h"

@class LanguageAidPref;

@interface NewModules : NSPanel 
{
	@public
	IBOutlet LanguageAidPref*			ownerPane;
	
	IBOutlet NSTableView*				newPlugins;
	IBOutlet NSButton*					installNew;
	
	IBOutlet NSProgressIndicator*		newPluginProgress;
}

- (void) installNewClick:(NSButton*)sender;
- (void) backClick:(NSButton*)sender;

@end
