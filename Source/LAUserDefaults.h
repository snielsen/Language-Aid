// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import <Cocoa/Cocoa.h>

@interface LAUserDefaults : NSObject
{

#ifdef LAINTERNAL
	NSString*					domain;
	
	NSMutableDictionary*		theDefaults;
	NSMutableDictionary*		changedKeys;
	NSMutableDictionary*		removedKeys;

	NSRecursiveLock*			dalock;
#endif

}

- (id) initWithDomain:(NSString*)domain;
- (void) dealloc;

- (void) setObject:(id)anObject forKey:(id)aKey;
- (void) removeObjectForKey:(id)aKey;
- (id) objectForKey:(id)aKey;
- (BOOL) synchronize;

@end