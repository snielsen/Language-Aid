// Copyright 2006-2011 Aoren LLC. All rights reserved.

// Description:
// Flexible, high accuracy, interpolation based timing system.
// To use it you simply call the class method with the parameter combination that you want to customize and everything else is taken care of.

// To do:

#import <Foundation/Foundation.h>

#import <sys/time.h>

// Indicates whether this timer is the dying kind or not.
#define DOESNTDIE		1
// Indicates whether the data will be set to the exact destination value upon death.
#define SETDESTINATION	1 << 1
#define CLAMP			1 << 2
#define KILLOTHERS		1 << 3
#define REPEAT			1 << 4

typedef float (*valcallback) (id, SEL, float);  // Callback that should take a float between 0.0 to 1.0 representing time and output the numeric progress as a decimal not necissarily between 0.0 and 1.0.

@interface Timer : NSObject
{
	@public
	// Passed in as parameters
	id					dataspace;							// (NOT optional) If data is part of a structure that can be deallocated this is the address of that structure.
	
	float*				data;								// (optional) The Data to be altered.  Must be a float.
	float				dest;								// (optional) The end value of *data.
	valcallback			vcb;								// (optional) Callback to the function that defines the numerical progress of data given time. (ie: linear, sinusodal, hyperbolic)
	float				start;								// (optional) The initial value *data.
	
	float				timeS;								// (optional) How long the timer is supposed to run.
	id					compobject;							// (optional) Callback object
	SEL					compcb;								// (optional) Callback to be invoked upon the death of this timer; can be used to define advanced timer behavior (ie: Repeatlinearly, Oscilatesinusodally)
	
	char				flags;								// (NOT optional) Various settings.
	
	// Calculated in the initializer
	SEL					vsel;
	struct timeval		startframe;							// Time values at this timer's birth.
    float				cumadded;							// The cumulative value that has been added to the data.
	
    struct Timer*		next;								// Next timer in the timer managements linked list structure.
}

// Public
+ (id) Object:(id)dsin Data:(float*)datain Destination:(float)destin Method:(SEL)vcbin Flags:(char)flagsin;
+ (id) Object:(id)dsin Data:(float*)datain Destination:(float)destin Method:(SEL)vcbin Start:(float)arstart Flags:(char)flagsin;
+ (id) Object:(id)dsin Time:(float)timein Flags:(char)flagsin;
+ (id) Object:(id)dsin Time:(float)timein CallbackObject:(id)cobj Callback:(SEL)ccbin Flags:(char)flagsin;
+ (id) Object:(id)dsin Data:(float*)datain Destination:(float)destin Method:(SEL)vcbin Time:(float)timein Flags:(char)flagsin;
+ (id) Object:(id)dsin Data:(float*)datain Destination:(float)destin Method:(SEL)vcbin Start:(float)arstart Time:(float)timein Flags:(char)flagsin;
+ (id) Object:(id)dsin Data:(float*)datain Destination:(float)destin Method:(SEL)vcbin Time:(float)timein CallbackObject:(id)cobj Callback:(SEL)ccbin Flags:(char)flagsin;
+ (id) Object:(id)dsin Data:(float*)datain Destination:(float)destin Method:(SEL)vcbin Start:(float)arstart Time:(float)timein CallbackObject:(id)cobj Callback:(SEL)ccbin Flags:(char)flagsin;

// Designated initializer.
- (id) Object:(id)dsin Data:(float*)datain Destination:(float)destin Method:(SEL)vcbin Start:(float)arstart Time:(float)timein CallbackObject:(id)cobj Callback:(SEL)ccbin Flags:(char)flagsin;

- (void) finishTimestamp:(struct timeval*)tv;

- (oneway void) Restart;									// Restarts a Timer
- (oneway void) Readjust:(in float)newdest;					// Restarts the Timer with a new destination.

// private

// Standard Types of data manipulation functions, eventually this will grow and I suppose it can be added to with categories.
- (float) linear:(float)x;
- (float) sinusodalcurveup:(float)x;
- (float) hyperbolic:(float)x;
- (float) sinusodalbump:(float)x;
- (float) triangular:(float)x;
- (float) accelaration:(float)x;

- (bool) Increment;											// Updates this timer's status.  Returns false if the timer has not yet expired, returns true if it has.

@end

void CleanTimers( id );										// When a data structure that has had data that has been attached to by a timer they should call this upon deletion to ensure that there are no outstanding timers attached to the soon to be unallocated memory.
void KillTimers( id TheObject, char* dname );				// Kills abruptly all timers that target on a certain data.
void KillTimers( float* dthing );							// Kills all Timers targeted on dthing.
//bool KillTimer( Timer* a );								// Kills a specific Timer.

extern timeval*			lastframe;							// Last frame's time stamp.
extern timeval*			thisframe;							// This frame's time stamp.

void TimerManagement( void );								// Manages all the timers.  This should be called every frame or every interval that the you want the timers to be maintained.

void initChrono( void );									// Initializes variables that have to do with the timer manager.
