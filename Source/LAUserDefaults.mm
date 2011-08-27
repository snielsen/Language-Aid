// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import "LAUserDefaults.h"

@implementation LAUserDefaults

- (id) initWithDomain:(NSString*)aDomain
{
	self = [super init];
	
	if( self )
	{
		domain = [[NSString alloc] initWithString:aDomain];
	
		theDefaults = [[NSMutableDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] persistentDomainForName:domain]];
		changedKeys = [[NSMutableDictionary alloc] init];
		removedKeys = [[NSMutableDictionary alloc] init];
		
		dalock = [[NSRecursiveLock alloc] init];
	}
	
	return self;
}

- (void) dealloc
{
	[domain release];
	
	[theDefaults release];
	[changedKeys release];
	[removedKeys release];
	
	[dalock release];
	
	[super dealloc];
}

- (void) setObject:(id)anObject forKey:(id)aKey
{
	[dalock lock];
	
		[theDefaults setObject:anObject forKey:aKey];
		[changedKeys setObject:anObject forKey:aKey];
		[removedKeys removeObjectForKey:aKey];
	
	[dalock unlock];
}

- (void) removeObjectForKey:(id)aKey
{
	[dalock lock];
	
		[theDefaults removeObjectForKey:aKey];
		[removedKeys setObject:aKey forKey:aKey];
		[changedKeys removeObjectForKey:aKey];
	
	[dalock unlock];
}

- (id) objectForKey:(id)aKey
{
	[dalock lock];
	
		id thaobject = [theDefaults objectForKey:aKey];
	
	[dalock unlock];
	
	return thaobject;
}

- (BOOL) synchronize
{
	[dalock lock];
	
		NSUserDefaults* standard = [NSUserDefaults standardUserDefaults];
		BOOL result = [standard synchronize];
		
		if( result )
		{
			NSMutableDictionary* diskDefaults = [[NSMutableDictionary alloc] initWithDictionary:[standard persistentDomainForName:domain]];
			
			int numkeysChanged = [changedKeys count];
			int numkeysRemoved = [removedKeys count];
			
			// Add in changed keys
			if( numkeysChanged )
			{
				[diskDefaults addEntriesFromDictionary:changedKeys];
				[changedKeys removeAllObjects];
			}
			
			// Removed deleted keys
			if( numkeysRemoved )
			{
				NSEnumerator* remkey = [removedKeys objectEnumerator]; NSString* remvalue;
				while( remvalue = [remkey nextObject] ){ [diskDefaults removeObjectForKey:remvalue];}
				[removedKeys removeAllObjects];
			}
			
			[theDefaults release];
			theDefaults = diskDefaults;
			
			if( numkeysChanged || numkeysRemoved )
			{
				[standard setPersistentDomain:theDefaults forName:domain];
				result = [standard synchronize];
			}
		}
	
	[dalock unlock];
	
	return result;
}

@end