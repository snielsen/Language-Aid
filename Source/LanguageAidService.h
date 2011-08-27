// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import <Cocoa/Cocoa.h>

#import "TranslatorApp.h"

@interface LanguageAidService : NSObject
{

}

- (void) lookup:(NSString*)text module:(NSString*)module;

@end
