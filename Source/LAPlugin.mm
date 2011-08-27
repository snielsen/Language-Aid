// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import "LAPlugin.h"

#import <sys/types.h>
#import <sys/event.h>
#import <sys/time.h>
#import <sys/dir.h>

#import <openssl/ssl.h>
#import <openssl/err.h>
#import <openssl/rsa.h>
#import <openssl/engine.h>
#import <openssl/md5.h>

#import <dirent.h>
#import <unistd.h>

PluginManager*				thePM = [[PluginManager alloc] init];

NSRecursiveLock*			LAPluginsLock = [[NSRecursiveLock alloc] init];
NSMutableArray*				loadedLAPlugins = [[NSMutableArray alloc] init];

Class						pmClass = objc_getClass("LAPlugin");
Class						wsClass = objc_getClass("LAWebServicePlugin");
Class						otClass = objc_getClass("LAOtherPlugin");

bool						kqrunning = false;
int							kq;
int							fd;
struct kevent				ev;
struct timespec				nullts = { 0, 0 };

bool						threadkill = false;

RSA*						modulekeypair = 0L;

int							unsignedOK = 0;

bool						safeToJump = false;

pthread_cond_t				repcond  = PTHREAD_COND_INITIALIZER;
pthread_mutex_t				repmutex = PTHREAD_MUTEX_INITIALIZER;

NSMutableDictionary*		Triggers = 0L;

bool isPluginThere( NSString* pname )
{
	[LAPluginsLock lock];
	
		for( int i = 0; i < [loadedLAPlugins count]; i++ )
		{
			LAPluginReference* PMR = [loadedLAPlugins objectAtIndex:i];
			
			if( [pname isEqualToString:PMR->name] ){ [LAPluginsLock unlock]; return true; }
		}
	
	[LAPluginsLock unlock];
	
	return false;
}

@implementation LAWebServicePlugin

//- (NSURLRequest*) createQueryFull:(NSString*)fullValue selected:(NSString*)selectedValue individual:(NSString*)individualValue preferred:(NSString*)preferredValue { return 0L; }
- (NSURLRequest*) createQueryFull:(NSString*)fullValue selected:(NSString*)selectedValue individual:(NSString*)individualValue { return 0L; }
- (NSString*) filterResult:(NSData*)result { return @""; }

@end

@implementation LAOtherPlugin

//- (NSString*) resultOfQueryFull:(NSString*)fullValue selected:(NSString*)selectedValue individual:(NSString*)individualValue preferred:(NSString*)preferredValue { return @""; }
- (NSString*) resultOfQueryFull:(NSString*)fullValue selected:(NSString*)selectedValue individual:(NSString*)individualValue { return @""; }
- (NSURL*) baseURL { return 0L; }

@end

@implementation LAPlugin

+ (int) PluginCompatibility { return 010100; } // For plugins before plugin compatibility was introduced. Needs to stay at 010100 (1.1.0)
+ (NSString*) Title { return @""; }
+ (NSString*) Author { return @""; }
+ (NSString*) windowTitle { return @""; }
- (BOOL) filterLoad:(NSURL*)loadingURL { return YES; }

@end

#pragma mark

@implementation LAPluginReference

- (id) initWithPath:(NSString*)path Bundle:(NSBundle*)inbun Signed:(bool)isSigned isLoaded:(bool)isloaded
{
	self = [super init];
	
	if( self )
	{
		modulePath = [[NSString alloc] initWithString:path];
	
		name = [[[modulePath lastPathComponent] stringByDeletingPathExtension] retain];
	
		thaBundle = inbun;
		infoDictionary = [[NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/Contents/Info.plist", path]] retain];
		
		handle = 0L;
		
		mh = 0L;
		mhindex = -1;

		// Get the class information
		classdata = 0L;
		classnum = 0;
		
		pluginClass = 0L;
		
		aorensigned = isSigned;
		isLoaded = isloaded;
		//[[Triggers objectForKey:name] setObject:[NSNumber numberWithBool:isLoaded] forKey:@"isLoaded"];
		
		newversion = 0L;
		newversionURL = 0L;
		
		upgradedVersion = 0L;
		
		
		if( isLoaded )
		{
			Class c = [thaBundle principalClass];
			
			if( c )
			{
				if( [c respondsToSelector:@selector(PluginCompatibility)] )
				{
					if( [c PluginCompatibility] <= LAPLUGINCOMPATIBILITY )
					{
						if( (c->super_class == pmClass) || (c->super_class == wsClass) || (c->super_class == otClass) )
						{
							if( c->super_class == wsClass )
							{
								//if( [c conformsToProtocol:@protocol(LAWebService)] ){ pluginClass = c; }
								//else{ NSLog( @"Class %@ does not conform to @protocol(LAWebService)\n", NSStringFromClass(c) ); }
								pluginClass = c;
							}
							else if( c->super_class == otClass )
							{
								//if( [c conformsToProtocol:@protocol(LAOther)] ){ pluginClass = c; }
								//else{ NSLog( @"Class %@ does not conform to @protocol(LAOther)\n", NSStringFromClass(c) ); }
								pluginClass = c;
							}
							else if( c->super_class == pmClass )
							{
								// Eventually put some protocol check here? Should be a loophole?
								pluginClass = c;
							}
						}
					}
					else
					{
						NSLog( @"Class %@ has a later plugin capability (%d) than this copy of Language Aid (%d)\n", NSStringFromClass(c), [c PluginCompatibility], LAPLUGINCOMPATIBILITY );
					}
				}
				else
				{
					NSLog( @"Class %@ is not responding to PluginCompatibility\n", NSStringFromClass(c) );
				}
			}
			else
			{
				NSLog( @"No principal class found in %@. Explicitly specify using NSPrincipalClass in the plugin bundle's Info.plist\n", modulePath );
			}
			
			if( !pluginClass )
			{
				[self autorelease];
				return 0L;
			}
		
			// If we are the pref pane then run updateSettings if defined
			#ifdef LAPREFPANE
			if( [pluginClass respondsToSelector:@selector(updateSettings)] )
			{
				//[pluginClass updateSettings];
				[NSThread detachNewThreadSelector:@selector(updateSettings) toTarget:pluginClass withObject:0L];
			}
			#endif
		
			NSLog( @"Class %@ loaded\n", NSStringFromClass(c) );
		}
	}
	
	return self;
}

- (void) nowLoad
{
	if( !isLoaded )
	{
		if( unsignedOK || aorensigned )
		{
			if( [thaBundle load] )
			{
				Class c = [thaBundle principalClass];
					
				if( c )
				{
					if( [c respondsToSelector:@selector(PluginCompatibility)] )
					{
						if( [c PluginCompatibility] <= LAPLUGINCOMPATIBILITY )
						{
							if( (c->super_class == pmClass) || (c->super_class == wsClass) || (c->super_class == otClass) )
							{
								// Eventually put protocol checks here like above? does it even matter?
							
								pluginClass = c;
								
								// If we are the pref pane then run updateSettings if defined
								#ifdef LAPREFPANE
								if( [pluginClass respondsToSelector:@selector(updateSettings)] )
								{
									//[pluginClass updateSettings];
									[NSThread detachNewThreadSelector:@selector(updateSettings) toTarget:pluginClass withObject:0L];
								}
								#endif
								
								NSLog( @"Class %@ loaded\n", NSStringFromClass(c) );
							}
						}
						else
						{
							NSLog( @"Class %@ has a later plugin capability (%d) than this copy of Language Aid (%d)\n", NSStringFromClass(c), [c PluginCompatibility], LAPLUGINCOMPATIBILITY );
						}
					}
					else
					{
						NSLog( @"Class %@ is not responding to PluginCompatibility\n", NSStringFromClass(c) );
					}
				}

				isLoaded = true;
				//[[Triggers objectForKey:name] setObject:[NSNumber numberWithBool:isLoaded] forKey:@"isLoaded"];
			}
		}
	}
}

- (int) upgrade:(AuthorizationRef)myAuthorizationRef
{
	NSString* scratch = [NSString stringWithFormat:@"/tmp/LAModuleUpgradeScratch%@.tar.gz", name];
	NSString* scratchtar = [NSString stringWithFormat:@"/tmp/LAModuleUpgradeScratch%@.tar", name];
	NSURL* scratchURL = [NSURL URLWithString:newversionURL];
	NSData* scratchData = [NSData dataWithContentsOfURL:scratchURL];
	
	#ifdef DEBUG
	NSLog(@"%x sucess on URL of %@ writing to %@\n", scratchData, newversionURL, scratch );
	#endif
	
	if( scratchData )
	{
		if( [scratchData writeToFile:scratch atomically:YES] == YES )
		{
			OSStatus myStatus;
			AuthorizationFlags myFlags = kAuthorizationFlagDefaults;
			//FILE* myCommunicationsPipe = NULL;
			
			int s2;
			char* myArguments[] = { "", NULL };
			myArguments[0] = (char*)[scratch UTF8String];
			//myStatus = AuthorizationExecuteWithPrivileges(myAuthorizationRef, "/usr/bin/gunzip", myFlags, myArguments, &myCommunicationsPipe);
			myStatus = AuthorizationExecuteWithPrivileges(myAuthorizationRef, "/usr/bin/gunzip", myFlags, myArguments, NULL);
			wait(&s2);
			
			if( myStatus )
			{
				#ifdef DEBUG
				printf("Secure op Status: %ld\n", myStatus);
				#endif
			}
			else
			{
				char* myArguments2[] = { "-C", "/Library/Application Support/Language Aid/PluginModules/", "-xf", "", NULL };
				myArguments2[3] = (char*)[scratchtar UTF8String];
				//myStatus = AuthorizationExecuteWithPrivileges(myAuthorizationRef, "/usr/bin/tar", myFlags, myArguments2, &myCommunicationsPipe);
				myStatus = AuthorizationExecuteWithPrivileges(myAuthorizationRef, "/usr/bin/tar", myFlags, myArguments2, NULL);
				wait(&s2);
				
				if( myStatus )
				{
					#ifdef DEBUG
					printf("Secure op Status: %ld\n", myStatus);
					#endif
				}
				else
				{
					upgradedVersion = newversion;
				
					newversion = 0L;
					[newversionURL release]; newversionURL = 0L;
					
					if( infoDictionary ){ [infoDictionary release]; }
					infoDictionary = [[NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/Contents/Info.plist", modulePath]] retain];
					
					aorensigned = [LAPluginReference signStatus:thaBundle];
					
					// At this point I suppose that if this app was running under Leopard or later we could reload the code.  It is still broken under Tiger
				}
			}
		}
		else
		{
			#ifdef DEBUG
			NSLog(@"Can't write %@\n", scratch );
			#endif
		}
	}
	// For some reason there was a problem with the download
	else
	{
		return DOWNLOADPROBLEM;
	}
	
	return NOERROR;
}

- (void) dealloc
{
	#ifdef DEBUG
	NSLog(@"DEALLOC!\n");
	#endif

	[modulePath release];
	[name release];
	[infoDictionary release];
	
	[super dealloc];
}

+ (bool) signStatus:(NSBundle*)dabun
{
	// Check sig
	bool signedornot = false;
	
	NSString* bundlename = [[[dabun bundlePath] lastPathComponent] stringByDeletingPathExtension];
	
	#ifdef DEBUG
	NSLog(@"Testing sig on %@ bundle path: %@\n", bundlename, [dabun bundlePath]);
	#endif
	
	FILE* sigfile = fopen( [[NSString stringWithFormat:@"%@/Contents/Resources/%@.sig", [dabun bundlePath], bundlename] UTF8String], "r" );
	if( sigfile )
	{
		unsigned char* sig = (unsigned char*)malloc( RSA_size(modulekeypair) );
		fread( sig, 1, RSA_size(modulekeypair), sigfile );
		fclose( sigfile );
		
		FILE* exefile = fopen( [[NSString stringWithFormat:@"%@/Contents/MacOS/%@", [dabun bundlePath], bundlename] UTF8String], "r" );
		int res = fseek( exefile, 0, SEEK_END );
		long exelen = ftell(exefile);
		unsigned char* exe = (unsigned char*)malloc( exelen );
		res = fseek( exefile, 0, SEEK_SET );
		fread( exe, 1, exelen, exefile );
		fclose( exefile );
		
		unsigned char md5[MD5_DIGEST_LENGTH];
		MD5( exe, exelen, md5 );
		
		signedornot = RSA_verify( NID_md5, md5, MD5_DIGEST_LENGTH, sig, RSA_size(modulekeypair), modulekeypair);
		
		#ifdef DEBUG
		NSLog(@"Signature verification result: %d.\n", signedornot);
		#endif
		free(sig);
		free(exe);
	}
	else
	{
		#ifdef DEBUG
		NSLog(@"No .sig file or couldn't open it.\n");
		#endif
	}

	return signedornot;
}

@end

#pragma mark

int laplugin_select( struct direct* entry )
{
	if( (strcmp(entry->d_name, ".") == 0) || (strcmp(entry->d_name, "..") == 0) )
	{
		return 0;
	}
	else if( strstr(entry->d_name, ".laplugin") )
	{
		return 1;
	}
	
	return 0;
}

@implementation PluginManager

- (NSArray*) reload
{
	[LAPluginsLock lock];
	
	NSMutableArray* newMods = [[NSMutableArray alloc] init];
	
	//NSArray* bundles = [NSBundle pathsForResourcesOfType:@"laplugin" inDirectory:@"/Library/Application Support/Language Aid/PluginModules/"];
	NSMutableArray* bundles = [[NSMutableArray alloc] init];
	
	struct direct** files;
	int count = scandir( "/Library/Application Support/Language Aid/PluginModules/", &files, laplugin_select, alphasort );
	
	for( int i = 0; i < count; i++)
	{
		if( files[i]->d_type & DT_DIR )
		{
			[bundles addObject:[NSString stringWithFormat:@"/Library/Application Support/Language Aid/PluginModules/%s", files[i]->d_name]];
		}
	}
	
	for( int i = 0; i < count; i++){ free( files[i] ); } free( files );
	
	for( int numplugins = [bundles count]; numplugins != 0; numplugins-- )
	{
		bool gotitalready = false;
		
		NSString* pluginpath = [bundles objectAtIndex:numplugins - 1];
		
		LAPluginReference* oldPMR = 0L;
		
		for( int numExistingplugins = [loadedLAPlugins count]; numExistingplugins != 0; numExistingplugins-- )
		{
			oldPMR = [loadedLAPlugins objectAtIndex:numExistingplugins - 1];
			
			if( [pluginpath isEqualToString:oldPMR->modulePath] )
			{
				gotitalready = true; break;
			}
		}
		
		// Check if it is enabled
		bool enabledornot = false;
		NSString* daname = [[[pluginpath lastPathComponent] stringByDeletingPathExtension] retain];
		NSDictionary* thisModulesTriggers = [Triggers objectForKey:daname];
		if( thisModulesTriggers )
		{
			NSNumber* isenabled = [thisModulesTriggers objectForKey:@"Enabled"];
			if( isenabled && [isenabled intValue] ){ enabledornot = true; }
		}

		if( !gotitalready )
		{
			#ifdef DEBUG
			NSLog(@"Bundle: %@\n", pluginpath);
			#endif
			
			NSBundle* dabun = [[NSBundle alloc] initWithPath:pluginpath];
			//NSArray* blah = [dabun pathsForResourcesOfType:0L inDirectory:0L];
			//NSArray* bundles = [NSBundle pathsForResourcesOfType:@"nib" inDirectory:@"/Library/Application Support/Language Aid/PluginModules/WWWJDIC.laplugin/Contents/Resources/English.lproj"];
			if( !dabun )
			{
				#ifdef DEBUG
				NSLog(@"no bundle! : %@\n", pluginpath );
				#endif
			}
			
			// Check sig
			bool signedornot = [LAPluginReference signStatus:dabun];
			
			if( (unsignedOK || signedornot) && enabledornot )
			{
				if( [dabun load] )
				{
					LAPluginReference* PMR = [[LAPluginReference alloc] initWithPath:pluginpath Bundle:dabun Signed:signedornot isLoaded:true];
					if( PMR )
					{
						[loadedLAPlugins addObject:PMR];
						[newMods addObject:PMR];
					}
				}
			}
			else
			{
				LAPluginReference* PMR = [[LAPluginReference alloc] initWithPath:pluginpath Bundle:dabun Signed:signedornot isLoaded:false];
				if( PMR )
				{
					[loadedLAPlugins addObject:PMR];
					[newMods addObject:PMR];
				}
			}
		}
		else
		{
			if( (unsignedOK || oldPMR->aorensigned) && !oldPMR->isLoaded && enabledornot )
			{
				[oldPMR nowLoad];
			}
		}
	}
	
	[LAPluginsLock unlock];
	[bundles release];
	return newMods;
}

@end


#pragma mark

void* repthread( void* args )
{
	while( 1 )
	{
		int n = kevent( kq, NULL, 0, &ev, 1, NULL );

		if( n > 0 )
		{
			//sleep(1); // Sleep long enough to let the copy/whatever transaction finish
			
			if( !safeToJump )
			{
				//sleep(5);
				struct timespec	ts;
				struct timeval	tp;
				
				int rc = gettimeofday( &tp, NULL );

				ts.tv_sec  = tp.tv_sec;
				ts.tv_nsec = tp.tv_usec * 1000;
				ts.tv_sec += 5;
				
				rc = pthread_cond_timedwait( &repcond, &repmutex, &ts );
			}
			else
			{
				safeToJump = false;
			}
			
			[LAPluginsLock lock];
			
			[[NSDistributedNotificationCenter defaultCenter] postNotificationName:REPCHANGEDNOTIFY object:0L userInfo:0L deliverImmediately:YES];
			
			[LAPluginsLock unlock];
		}

		// Because above could potentially block forever this might never get reached. Meh...
		if( threadkill )
		{
			close( fd );
			return 0L;
		}
	}
}

void initialLAPlugins( void )
{	
	//printf( "initialLAPlugins unsignedOK: %d\n", unsignedOK );

	// nu skool
	//NSArray* bundles = [NSBundle pathsForResourcesOfType:@"bundle" inDirectory:@"/Library/Application Support/Language Aid/PluginModules/"];
	//NSArray* bundles = [NSBundle pathsForResourcesOfType:@"laplugin" inDirectory:@"/Library/Application Support/Language Aid/PluginModules/"];
	NSMutableArray* bundles = [[NSMutableArray alloc] init];
	
	struct direct** files;
	int count = scandir( "/Library/Application Support/Language Aid/PluginModules/", &files, laplugin_select, alphasort );
	
	for( int i = 0; i < count; i++)
	{
		if( files[i]->d_type & DT_DIR )
		{
			[bundles addObject:[NSString stringWithFormat:@"/Library/Application Support/Language Aid/PluginModules/%s", files[i]->d_name]];
		}
	}
	
	for( int i = 0; i < count; i++){ free( files[i] ); } free( files );
	
	for( int numplugins = [bundles count]; numplugins != 0; numplugins-- )
	{
		NSString* pluginpath = [bundles objectAtIndex:numplugins - 1];
		
		#ifdef DEBUG
		NSLog(@"Bundle: %@\n", pluginpath);
		#endif
		
		NSBundle* dabun = [[NSBundle alloc] initWithPath:pluginpath];
		//NSArray* blah = [dabun pathsForResourcesOfType:0L inDirectory:0L];
		// Check sig
		bool signedornot = [LAPluginReference signStatus:dabun];
		
		// Check if it is enabled
		bool enabledornot = false;
		NSString* daname = [[[pluginpath lastPathComponent] stringByDeletingPathExtension] retain];
		NSDictionary* thisModulesTriggers = [Triggers objectForKey:daname];
		if( thisModulesTriggers )
		{
			NSNumber* isenabled = [thisModulesTriggers objectForKey:@"Enabled"];
			if( isenabled && [isenabled intValue] ){ enabledornot = true; }
		}
		
		[LAPluginsLock lock];
		
			if( (unsignedOK || signedornot) && enabledornot )
			{
				if( [dabun load] )
				{
					LAPluginReference* PMR = [[LAPluginReference alloc] initWithPath:pluginpath Bundle:dabun Signed:signedornot isLoaded:true];
					if( PMR ){ [loadedLAPlugins addObject:PMR]; }
				}
			}
			else
			{
				LAPluginReference* PMR = [[LAPluginReference alloc] initWithPath:pluginpath Bundle:dabun Signed:signedornot isLoaded:false];
				if( PMR ){ [loadedLAPlugins addObject:PMR]; }
			}
		
		[LAPluginsLock unlock];
	}
	
	[bundles release];
}

bool setupKQueue( void )
{
	if( !kqrunning )
	{
		kq = kqueue();
		
		fd = open( "/Library/Application Support/Language Aid/PluginModules/", O_RDONLY );
		
		if( fd )
		{
			EV_SET( &ev, fd, EVFILT_VNODE, EV_ADD | EV_ENABLE | EV_CLEAR, NOTE_RENAME | NOTE_WRITE | NOTE_DELETE | NOTE_ATTRIB, 0, 0 );
			kevent( kq, &ev, 1, NULL, 0, &nullts );
			
			//printf( "LoadLAPlugins unsignedOK: %d\n", unsignedOK );
			
			pthread_t		repthreadhandle = 0L;
			pthread_create( &repthreadhandle, 0L, repthread, 0L );
			
			kqrunning = true;
		}
	}
	
	return kqrunning;
}

void LoadLAPlugins( void )
{
	int rsares = 0;
	modulekeypair = RSA_new();
	modulekeypair->n = BN_new(); rsares = BN_hex2bn( &modulekeypair->n, "00cf20148de06e442bf976d31c772818af8119093f2f3b828ab8c1ff83f720689b89498ef10423ef6cb2717df0286d842ae1c0a942bce64d98c07496d317a36a94fc43fe250500d66b773a4e9755537f407f57ca9c6c343d2cf3d3e094dffba08b694de514197ed4dbfab2f1376f4fb0928ee981f4b0249f087f858e962ef2878bd0e29617269cd4ca4ebbfdf9fc3de38bc015b676c8c336dd25482b10bcf8e4190c2b23d9d8bfd39ddcd9b87ee9b9a86c0b25778351bd75c78f285fc13439310daca4716ea9968d7fe0ee886db24e055ae612b3758b31b34df668fcf620cd197c3fb97ee9f0a1fa72fd1f6e14ae66d7fa318e39058f638b8e9d7fcee6c248b2b9" );
	modulekeypair->e = BN_new(); rsares = BN_hex2bn( &modulekeypair->e, "010001" );
	modulekeypair->d = 0L;
	modulekeypair->p = 0L;
	modulekeypair->q = 0L;
	modulekeypair->dmp1 = 0L;
	modulekeypair->dmq1 = 0L;
	modulekeypair->iqmp = 0L;

	if( setupKQueue() )
	{
		initialLAPlugins();
	}
}