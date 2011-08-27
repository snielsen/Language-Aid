// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import "main.h"

int main(int argc, char *argv[])
{
	srandom(time(NULL));
	
	{
		return NSApplicationMain( argc, (const char**)argv );
	}
	
	return 0;
}
