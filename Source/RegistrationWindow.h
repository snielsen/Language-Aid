// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import "LanguageAidPref.h"

@class LanguageAidPref;

@interface RegistrationWindow : NSWindow
{
	@public

	IBOutlet LanguageAidPref*			prefPane;
	
	IBOutlet WebView*					paymentView;
		
	IBOutlet NSProgressIndicator*		webpayProgress;
}

@end