// Copyright 2006-2011 Aoren LLC. All rights reserved.

// Description:

// To do:
// Eventually write in an exception catcher to handle event send errors.
// For some reason the HID libraries leak like no other, especially when you smash around multiple keys at once.  Eventually find a clean solution/replacement.
// I think you can actually have messages that use less than the regular number of callback things.  Check that.

#import "Input.h"
#import "TranslatorApp.h"

#import <Carbon/Carbon.h>

#import <objc/objc-runtime.h>

Hinterface*			firstHinterface = 0L;

clickCallback		clickCB = 0L;

#pragma mark -
#pragma mark Utility Functions

// Returns the interface that has the specified product ID
Hinterface* HIconnected( pRecDevice h )
{
    Hinterface* a = firstHinterface;
	
	while( a )
	{
		if( a->thaDev == h )
		{
			return a;
		}
		
		a = a->next; 
	}
	
	return 0L;
}

#pragma mark -
#pragma mark Signal Callbacks

void InputCallback( void* target, IOReturn result, void* refcon, void* sender )
{
	Mouse* a = (Mouse*)HIconnected( (pRecDevice)target );
	
	IOHIDEventStruct* DevEvent = new IOHIDEventStruct();
	
	while( HIDGetEvent( (recDevice*)target, DevEvent ) )
	{
		int whichbutton = -1;
	
			 if( DevEvent->elementCookie == a->Button1C ){ whichbutton = 1; }
		else if( DevEvent->elementCookie == a->Button2C ){ whichbutton = 2; }
		else if( DevEvent->elementCookie == a->Button3C ){ whichbutton = 3; }
		else if( DevEvent->elementCookie == a->Button4C ){ whichbutton = 4; }
		else if( DevEvent->elementCookie == a->Button5C ){ whichbutton = 5; }
		
		if( clickCB ){ clickCB( whichbutton, DevEvent->value ); }
		
		if( DevEvent->longValue ){ delete (char*)DevEvent->longValue; }
	}
	
	delete DevEvent;
}

#pragma mark -
#pragma mark Hinterface

@implementation Hinterface

- (id) initHinterface:(pRecDevice)dev
{
	self = [super init];
	
	if( self )
	{
		thaDev = dev;
		//identity = (long int)dev->interface;
	
		next = 0L;
		
		// Enter itself in the Hinterface list
		if( firstHinterface == 0L )
		{
			firstHinterface = self;
		}
		else
		{
			Hinterface* a = firstHinterface;
			
			while( a->next != 0L )
			{
				a = a->next;
			}
			
			a->next = self;
		}
	}
	
	return self;
}

- (void) dealloc
{
	// Remove itself from the Hinterface list.
    if( self == firstHinterface )
    {
		firstHinterface = next;
    }
    else
    {
        Hinterface* a = firstHinterface;
        
        while( a->next != self )
		{
			a = a->next;
		}
        
        a->next = next;
    }
	
	[super dealloc];
}

@end

#pragma mark -
#pragma mark Device Structures

@implementation Mouse

- (void) pokeTree:(recElement*)b
{
	char c[256];
	
	HIDGetUsageName( b->usagePage, b->usage, c );
	
		 if( strcmp( c, "X-Axis" )    == 0 ){ Xaxis = b;   XaxisC = b->cookie;    }
	else if( strcmp( c, "Y-Axis" )    == 0 ){ Yaxis = b;   YaxisC = b->cookie;    }
	else if( strcmp( c, "Button #1" ) == 0 ){ Button1 = b; Button1C = b->cookie;  }
	else if( strcmp( c, "Button #2" ) == 0 ){ Button2 = b; Button2C = b->cookie;  }
	else if( strcmp( c, "Button #3" ) == 0 ){ Button3 = b; Button3C = b->cookie;  }
	else if( strcmp( c, "Button #4" ) == 0 ){ Button4 = b; Button4C = b->cookie;  }
	else if( strcmp( c, "Button #5" ) == 0 ){ Button5 = b; Button5C = b->cookie;  }
	else if( strcmp( c, "Wheel" )     == 0 ){ Wheel = b;   WheelC = b->cookie;    }
	
	if( b->pSibling ){ [self pokeTree:b->pSibling]; }
	if( b->pChild   ){ [self pokeTree:b->pChild];   }
}

- (id) initHinterface:(pRecDevice)dev
{
	devType = 1;
		
	Xaxis   = 0L; XaxisC   = 0;
	Yaxis   = 0L; YaxisC   = 0;
	Button1 = 0L; Button1C = 0;
	Button2 = 0L; Button2C = 0;
	Button3 = 0L; Button3C = 0;
	Button4 = 0L; Button4C = 0;
	Button5 = 0L; Button5C = 0;
	Wheel   = 0L; Wheel    = 0;
	
	[self pokeTree:dev->pListElements];
	
	self = [super initHinterface:dev];
	
	if( self )
	{
		//if( mouseinput )
		{
			//HIDQueueElement( thaDev, Button1 );
			//HIDQueueElement( thaDev, Button2 );
			//HIDQueueElement( thaDev, Button3 );
			//HIDQueueDevice( thaDev );
			/*	 if( mouseinput == 1 ){ HIDQueueElement( thaDev, Button1 ); HIDSetQueueCallback( thaDev, InputCallback ); }
			else if( mouseinput == 2 ){ HIDQueueElement( thaDev, Button2 ); HIDSetQueueCallback( thaDev, InputCallback ); }
			else if( mouseinput == 3 ){ HIDQueueElement( thaDev, Button3 ); HIDSetQueueCallback( thaDev, InputCallback ); }
			else if( mouseinput == 4 ){ HIDQueueElement( thaDev, Button4 ); HIDSetQueueCallback( thaDev, InputCallback ); }
			else if( mouseinput == 5 ){ HIDQueueElement( thaDev, Button5 ); HIDSetQueueCallback( thaDev, InputCallback ); }*/
			
			// Initial queue setup
			HIDQueueElement( thaDev, Button1 );
			HIDSetQueueCallback( thaDev, InputCallback );
			HIDDequeueElement( thaDev, Button1 );
			
			NSEnumerator* menumerator = [TApp->hotButtons objectEnumerator]; MouseButtonWrapper* mvalue;
			while( mvalue = [menumerator nextObject] )
			{
					 if( mvalue->daButton == 1 ){ HIDQueueElement( thaDev, Button1 ); }
				else if( mvalue->daButton == 2 ){ HIDQueueElement( thaDev, Button2 ); }
				else if( mvalue->daButton == 3 ){ HIDQueueElement( thaDev, Button3 ); }
				else if( mvalue->daButton == 4 ){ HIDQueueElement( thaDev, Button4 ); }
				else if( mvalue->daButton == 5 ){ HIDQueueElement( thaDev, Button5 ); }
			}
		}
	}
	
	return self;
}

@end

#pragma mark -
#pragma mark Main Functions

void deviceAdded( pRecDevice addedDevice )
{
	char iname[255];
            
	HIDGetUsageName( addedDevice->usagePage, addedDevice->usage, iname );
	
	// Error
	if( strlen(iname) > 255 ){ NSLog(@"ERROR Interfaces: iname is > 255.\n" ); return;	}
	
	if( strcmp(iname, "Mouse") == 0 )
	{
		[[Mouse alloc] initHinterface:addedDevice];
	}
}

void deviceRemoved( pRecDevice removedDevice )
{
	[HIconnected( removedDevice ) release];
}

/*void changeMouseInput( int button )
{
	if( button != mouseinput )
	{
		Mouse* a = firstHinterface;
		
		while( a )
		{
				 if( mouseinput == 1 ){ HIDDequeueElement( a->thaDev, a->Button1 ); }
			else if( mouseinput == 2 ){ HIDDequeueElement( a->thaDev, a->Button2 ); }
			else if( mouseinput == 3 ){ HIDDequeueElement( a->thaDev, a->Button3 ); }
			else if( mouseinput == 4 ){ HIDDequeueElement( a->thaDev, a->Button4 ); }
			else if( mouseinput == 5 ){ HIDDequeueElement( a->thaDev, a->Button5 ); }
			
			a = a->next; 
		}
		
		mouseinput = button;
		
		if( mouseinput )
		{
			a = firstHinterface;
			
			while( a )
			{
					 if( mouseinput == 1 ){ HIDQueueElement( a->thaDev, a->Button1 ); }
				else if( mouseinput == 2 ){ HIDQueueElement( a->thaDev, a->Button2 ); }
				else if( mouseinput == 3 ){ HIDQueueElement( a->thaDev, a->Button3 ); }
				else if( mouseinput == 4 ){ HIDQueueElement( a->thaDev, a->Button4 ); }
				else if( mouseinput == 5 ){ HIDQueueElement( a->thaDev, a->Button5 ); }
				HIDSetQueueCallback( a->thaDev, InputCallback );
				
				a = a->next; 
			}
			
		}
	}
}*/

void addMouseInput( int button )
{
	Mouse* a = (Mouse*)firstHinterface;
	
	while( a )
	{
			 if( button == 1 ){ HIDQueueElement( a->thaDev, a->Button1 ); }
		else if( button == 2 ){ HIDQueueElement( a->thaDev, a->Button2 ); }
		else if( button == 3 ){ HIDQueueElement( a->thaDev, a->Button3 ); }
		else if( button == 4 ){ HIDQueueElement( a->thaDev, a->Button4 ); }
		else if( button == 5 ){ HIDQueueElement( a->thaDev, a->Button5 ); }
		HIDSetQueueCallback( a->thaDev, InputCallback );
		
		a = (Mouse*)a->next; 
	}
}

void clearMouseInput( int button )
{
	Mouse* a = (Mouse*)firstHinterface;
	
	while( a )
	{
			 if( button == 1 ){ HIDDequeueElement( a->thaDev, a->Button1 ); }
		else if( button == 2 ){ HIDDequeueElement( a->thaDev, a->Button2 ); }
		else if( button == 3 ){ HIDDequeueElement( a->thaDev, a->Button3 ); }
		else if( button == 4 ){ HIDDequeueElement( a->thaDev, a->Button4 ); }
		else if( button == 5 ){ HIDDequeueElement( a->thaDev, a->Button5 ); }
		
		a = (Mouse*)a->next; 
	}
}

#pragma mark Init

// Simple initialization function.
void initControl( void )
{
	HIDDeviceStateCallbacks( deviceAdded, deviceRemoved );
	HIDBuildDeviceList( 0L, 0L );
}