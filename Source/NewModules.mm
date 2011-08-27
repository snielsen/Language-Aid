// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import "NewModules.h"

@implementation NewModules

- (void) installNewClick:(NSButton*)sender
{
	int j = 0; int k = 0;
	while( j < (int)[newModulesArray count] )
	{
		NSNumber* dacheck = [[newModulesArray objectAtIndex:j] objectForKey:@"check"];
		if( dacheck && ([dacheck intValue] == 1) ){ k++; } j++;
	}
	
	if( k )
	{
		[LAPluginsLock lock];
		
		[newPluginProgress setMaxValue:k];
		[newPluginProgress setDoubleValue:0.0];
		[newPluginProgress setHidden:NO];
				
		int i = 0;
		
		while( i < (int)[newModulesArray count] )
		{
			NSDictionary* newplugin = [newModulesArray objectAtIndex:i];
			i++;
			
			NSNumber* dacheck = [newplugin objectForKey:@"check"];
			
			if( dacheck && ([dacheck intValue] == 1) )
			{
				[newPluginProgress incrementBy:1.0];
			
				NSString* scratch = [NSString stringWithFormat:@"/tmp/LAModuleUpgradeScratch%@.tar.gz", [newplugin objectForKey:@"plugin"]];
				NSString* scratchtar = [NSString stringWithFormat:@"/tmp/LAModuleUpgradeScratch%@.tar", [newplugin objectForKey:@"plugin"]];
				NSURL* scratchURL = [NSURL URLWithString:[newplugin objectForKey:@"URL"]];
				NSData* scratchData = [NSData dataWithContentsOfURL:scratchURL];
				
				#ifdef DEBUG
				NSLog(@"%x sucess on URL of %@ writing to %@\n", scratchData, [newplugin objectForKey:@"URL"], scratch );
				#endif
				
				if( scratchData )
				{
					if( [scratchData writeToFile:scratch atomically:YES] == YES )
					{
						OSStatus myStatus;
						AuthorizationRef myAuthorizationRef;
						AuthorizationFlags myFlags = kAuthorizationFlagDefaults;
					 
						myStatus = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, myFlags, &myAuthorizationRef);
						if( myStatus != errAuthorizationSuccess )
						{
							#ifdef DEBUG
							NSLog(@"No authorization");
							#endif
						}
					 
						AuthorizationItem myItems = {kAuthorizationRightExecute, 0, NULL, 0};
						AuthorizationRights myRights = {1, &myItems};

						myFlags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagPreAuthorize | kAuthorizationFlagExtendRights;
						myStatus = AuthorizationCopyRights (myAuthorizationRef, &myRights, NULL, myFlags, NULL );
					
						//FILE* myCommunicationsPipe = NULL;
						myFlags = kAuthorizationFlagDefaults;
						
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
							//char* myArguments3[] = { "-p", "-m", "0775", "/Library/Application Support/Language Aid/PluginModules/", NULL };
							//myStatus = AuthorizationExecuteWithPrivileges(myAuthorizationRef, "/bin/mkdir", myFlags, myArguments3, &myCommunicationsPipe);
							//
							//if( myStatus ){ printf("Secure op Status: %ld\n", myStatus); }
							//else
							//{
							//	setupKQueue(); // If the KQueue wasn't set up yet then do it now.
								
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
									[newModulesArray removeObject:newplugin];
									i = 0;
								}
							//}
						}
						
						AuthorizationFree( myAuthorizationRef, kAuthorizationFlagDefaults );
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
					NSRunAlertPanel( [NSString stringWithFormat:@"%@ - %@", [newplugin objectForKey:@"plugin"], NSLocalizedStringFromTableInBundle(@"BADDOWNLOAD", 0L, myBundle, 0L)], NSLocalizedStringFromTableInBundle(@"DOWNLOADFAILED", 0L, myBundle, 0L), NSLocalizedStringFromTableInBundle(@"OK", 0L, myBundle, 0L), 0L, 0L );
				}
			}
		}

		if( [newModulesArray count] == 0 ){ [ownerPane->addnewModulesButton setHidden:YES]; }else{ [ownerPane->addnewModulesButton setHidden:NO]; }

		[NSApp stopModal];
		[self close];

		[newPluginProgress setHidden:YES];
		safeToJump = true;
		pthread_cond_signal( &repcond );
		[LAPluginsLock unlock];
	}
}

- (void) backClick:(NSButton*)sender
{
	[NSApp stopModal];
	[self close];
}

#pragma mark Plugin Module Table Callbacks

- (id) tableView:(NSTableView*)aTableView objectValueForTableColumn:(NSTableColumn*)aTableColumn row:(int)rowIndex
{
	NSDictionary* newMod = [newModulesArray objectAtIndex:rowIndex];
	
	if( [[aTableColumn identifier] isEqualToString:@"Name"] )
	{
		return [newMod objectForKey:@"plugin"];
	}
	else if( [[aTableColumn identifier] isEqualToString:@"Author"] )
	{
		return [newMod objectForKey:@"author"];
	}
	else if( [[aTableColumn identifier] isEqualToString:@"Version"] )
	{
		return [newMod objectForKey:@"version"];
	}
	else if( [[aTableColumn identifier] isEqualToString:@"Check"] )
	{
		return [newMod objectForKey:@"check"];
	}
	
	return 0L;
}

- (void) tableView:(NSTableView*)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn*)aTableColumn row:(int)rowIndex
{
	NSMutableDictionary* newMod = [newModulesArray objectAtIndex:rowIndex];
	
	[newMod setObject:anObject forKey:@"check"];
	
	[newPlugins reloadData];
}

- (int) numberOfRowsInTableView:(NSTableView*)TV
{
	//NSLog(@"%d new mods\n",[newModulesArray count]);
	return [newModulesArray count];
}

- (void) tableViewSelectionDidChange:(NSNotification*)aNotification
{

}

#pragma mark Overridden

- (void) awakeFromNib
{
	srandom(time(NULL));
	
	[newPlugins setDataSource:self];
	[newPlugins setDelegate:self];
}

@end
