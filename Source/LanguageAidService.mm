// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import "LanguageAidService.h"

#pragma mark

@implementation LanguageAidService

- (void) lookup:(NSString*)text module:(NSString*)module
{
	[TApp lookup:text module:module];
}

@end