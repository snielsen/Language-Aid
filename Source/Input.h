// Copyright 2006-2011 Aoren LLC. All rights reserved.

// Description:
// Various input device communication support is written in here by the maintainers of the server.  All configuration and use and interpretation of signals from devices occurs in Abstractions.
// When EventReceptor callbacks are triggered no matter what the callback selector is these values are pushed onto the stack for optional interpretation as passed paramters of these types and order:
// The Event Value(SInt32), The Abstraction(Abstraction*), The Receiving Construct(Construct*), The Event Receptor that was triggered(EventReceptor*)
// When a device gets unplugged or some other action causes an Hinterface to be dealloc'd objects can request a notification in the form of a LeavingDeviceNotification: message with the Hinterface object passed to them by simply instantiating a NotificationClient object with initNC.
// Only Abstraction programmers should ever have to deal directly with Hinterfaces (there might be a few exceptions) and most Application programmers should instead deal with Abstractions. 

// To do:
// Write in support for more devices and more options on the devices.

#import "HID_Utilities_External.h"

#import <Foundation/Foundation.h>

//#import "defs.h"

@interface Hinterface : NSObject
{
	@public
    pRecDevice          thaDev;				// HID device structure.
    //long                identity;			// HID device identifier.
	int					devType;			// Device type.
	
    struct Hinterface*  next;				// The next Hinterface in the linked list.
}

- (id) initHinterface:(pRecDevice)dev;
- (void) dealloc;


@end

@interface Mouse : Hinterface
{
	@public
    recElement* Xaxis;   void* XaxisC;
    recElement* Yaxis;   void* YaxisC;
    recElement* Button1; void* Button1C;
    recElement* Button2; void* Button2C;
    recElement* Button3; void* Button3C;
	recElement* Button4; void* Button4C;
	recElement* Button5; void* Button5C;
    recElement* Wheel;   void* WheelC;
}

- (id) initHinterface:(pRecDevice)mouseDev;

@end

#pragma mark-

void initControl( void );
//void changeMouseInput( int button );
void addMouseInput( int button );
void clearMouseInput( int button );

extern Hinterface*		firstHinterface;							// Head of the linked list of Hinterfaces.


typedef void (*clickCallback) (int, int);

extern clickCallback	clickCB;