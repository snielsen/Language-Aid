// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import "PluginModulesTable.h"

@implementation pluginModulesTable

#pragma mark Plugin Module Dragging Callbacks

- (NSDragOperation) draggingEntered:(id <NSDraggingInfo>)sender
{
	NSPasteboard* paste = [sender draggingPasteboard];
    NSArray* pluginPaths = [paste propertyListForType:NSFilenamesPboardType];
	
	if( pluginPaths )
	{
		for( int i = 0; i < [pluginPaths count]; i++ )
		{
			if( [[pluginPaths objectAtIndex:i] hasSuffix:@".laplugin"] )
			{
				return NSDragOperationGeneric;
			}
		}
	}
	
	return NSDragOperationNone;
}

- (NSDragOperation) draggingUpdated:(id <NSDraggingInfo>)sender
{
	NSPasteboard* paste = [sender draggingPasteboard];
    NSArray* pluginPaths = [paste propertyListForType:NSFilenamesPboardType];
	
	if( pluginPaths )
	{
		for( int i = 0; i < [pluginPaths count]; i++ )
		{
			if( [[pluginPaths objectAtIndex:i] hasSuffix:@".laplugin"] )
			{
				return NSDragOperationGeneric;
			}
		}
	}
	
	return NSDragOperationNone;
}

/*- (void) draggingEnded:(id <NSDraggingInfo>)sender
{NSLog(@"draggingEnded\n");

}*/

/*- (void) draggingExited:(id <NSDraggingInfo>)sender
{

}*/

- (BOOL) prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	return YES;
}

- (BOOL) performDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard* paste = [sender draggingPasteboard];
    NSArray* pluginPaths = [paste propertyListForType:NSFilenamesPboardType];
	
	if( pluginPaths )
	{
		bool wroteatleastone = false;
		
		for( int i = 0; i < [pluginPaths count]; i++ )
		{
			NSString* pluginPath = [pluginPaths objectAtIndex:i];
			
			if( [pluginPath hasSuffix:@".laplugin"] )
			{
				NSFileManager*	fileManager = [NSFileManager defaultManager];
				BOOL			isDir;
				
				if( [fileManager fileExistsAtPath:pluginPath isDirectory:&isDir] && isDir )
				{
					if( [fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@/Contents", pluginPath] isDirectory:&isDir] && isDir )
					{
						if( [fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@/Contents/Info.plist", pluginPath]] )
						{
							char* myArgument = (char*)[[NSString stringWithFormat:@"/bin/rm -Rf \"/Library/Application Support/Language Aid/PluginModules/%@\"", [pluginPath lastPathComponent]] UTF8String];
							system( myArgument );

							char* myArgument2 = (char*)[[NSString stringWithFormat:@"/bin/cp -R \"%@\" \"/Library/Application Support/Language Aid/PluginModules/%@\"", pluginPath, [pluginPath lastPathComponent]] UTF8String];
							system( myArgument2 );


							/*OSStatus myStatus;
							AuthorizationRef myAuthorizationRef;
							AuthorizationFlags myFlags = kAuthorizationFlagDefaults;
						 
							myStatus = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, myFlags, &myAuthorizationRef);
							if( myStatus != errAuthorizationSuccess )
							{
								#ifdef DEBUG
								NSLog(@"No authorization");
								#endif
								
								return NO;
							}
						 
							AuthorizationItem myItems = {kAuthorizationRightExecute, 0, NULL, 0};
							AuthorizationRights myRights = {1, &myItems};

							myFlags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagPreAuthorize | kAuthorizationFlagExtendRights;
							myStatus = AuthorizationCopyRights (myAuthorizationRef, &myRights, NULL, myFlags, NULL );
						
							//FILE* myCommunicationsPipe = NULL;
							myFlags = kAuthorizationFlagDefaults;
							
							int s2;
							char* myArguments[] = { "-Rf", "", NULL };
							myArguments[1] = (char*)[[NSString stringWithFormat:@"/Library/Application Support/Language Aid/PluginModules/%@", [pluginPath lastPathComponent]] UTF8String];
							myStatus = AuthorizationExecuteWithPrivileges( myAuthorizationRef, "/bin/rm", myFlags, myArguments, NULL );
							wait(&s2);
							
							if( myStatus )
							{
								#ifdef DEBUG
								printf("Secure op Status: %ld\n", myStatus);
								#endif
							}
							else
							{
								char* myArguments2[] = { "-R", "", "", NULL };
								myArguments2[1] = (char*)[pluginPath UTF8String];
								myArguments2[2] = (char*)[[NSString stringWithFormat:@"/Library/Application Support/Language Aid/PluginModules/%@", [pluginPath lastPathComponent]] UTF8String];
								myStatus = AuthorizationExecuteWithPrivileges( myAuthorizationRef, "/bin/cp", myFlags, myArguments2, NULL );
								wait(&s2);
								
								if( myStatus )
								{
									#ifdef DEBUG
									printf("Secure op Status: %ld\n", myStatus);
									#endif
								}
								else
								{
									wroteatleastone = true;
									NSLog( @"Plugin: %@ added to plugin module repository\n", [pluginPaths objectAtIndex:i] );
								}
							}
							
							AuthorizationFree( myAuthorizationRef, kAuthorizationFlagDefaults );*/
						}
					}
				}
			}
		}
		
		if( wroteatleastone ){ return YES; }
	}
	
	return NO;
}

/*- (void) concludeDragOperation:(id <NSDraggingInfo>)sender
{

}*/

- (void) dealloc
{
    [self unregisterDraggedTypes];
    [super dealloc];
}

@end