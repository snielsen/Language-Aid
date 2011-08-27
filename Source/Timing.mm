// Copyright 2006-2011 Aoren LLC. All rights reserved.

// Description:
// Uses NAN as a special no value instead of 0.

// To do:
// Consider updating thisframe after every Timer is Incremented to allow for finer timing.  However, this might not be doable because Timers used in things like Oscillation that are made the same length and at the same time(virtually, by that i mean the same frame) as each other will start to drift off and unsynchronize.
// Currently if either the number of seconds entered in or the difference between the start time and current time are more than 2^32/1000000 seconds then the values will overflow and screw things up, fix this eventually.

#import "Timing.h"

#import <objc/objc-class.h>

unsigned int		floatNaN = 0x7fc00000;

Timer*				firstTimer = 0L;			// The first entry in the timer management's linked list structure.

timeval*			lastframe = 0L;				// Last frame's time stamp.
timeval*			thisframe = 0L;				// This frame's time stamp.

Timer*				currTimer = 0L;				// The current Timer that has it's memory space being used.
bool				pendingDelete = false;		// Pending deletion flag if we were supposed to delete the currTimer while it was being used.

@implementation Timer

#pragma mark public

//Timer initializers.  Automatically enters the structures into the timer management system. Dirty, study default arguments sometime so there will only be one function or something.

+ (id) Object:(id)dsin Data:(float*)datain Destination:(float)destin Method:(SEL)vcbin Flags:(char)flagsin
{
	return [[self alloc] Object:dsin Data:datain Destination:destin Method:vcbin Start:NAN Time:0 CallbackObject:nil Callback:nil Flags:flagsin];
}

+ (id) Object:(id)dsin Data:(float*)datain Destination:(float)destin Method:(SEL)vcbin Start:(float)arstart Flags:(char)flagsin
{
	return [[self alloc] Object:dsin Data:datain Destination:destin Method:vcbin Start:arstart Time:0 CallbackObject:nil Callback:nil Flags:flagsin];
}

+ (id) Object:(id)dsin Time:(float)timein Flags:(char)flagsin
{
	return [[self alloc] Object:dsin Data:0L Destination:0L Method:nil Start:NAN Time:timein CallbackObject:nil Callback:nil Flags:flagsin];
}

+ (id) Object:(id)dsin Time:(float)timein CallbackObject:(id)cobj Callback:(SEL)ccbin Flags:(char)flagsin
{
	return [[self alloc] Object:dsin Data:0L Destination:0L Method:nil Start:NAN Time:timein CallbackObject:cobj Callback:ccbin Flags:flagsin];
}

+ (id) Object:(id)dsin Data:(float*)datain Destination:(float)destin Method:(SEL)vcbin Time:(float)timein Flags:(char)flagsin
{
	return [[self alloc] Object:dsin Data:datain Destination:destin Method:vcbin Start:NAN Time:timein CallbackObject:nil Callback:nil Flags:flagsin];
}

+ (id) Object:(id)dsin Data:(float*)datain Destination:(float)destin Method:(SEL)vcbin Start:(float)arstart Time:(float)timein Flags:(char)flagsin
{
	return [[self alloc] Object:dsin Data:datain Destination:destin Method:vcbin Start:arstart Time:timein CallbackObject:nil Callback:nil Flags:flagsin];
}

+ (id) Object:(id)dsin Data:(float*)datain Destination:(float)destin Method:(SEL)vcbin Time:(float)timein CallbackObject:(id)cobj Callback:(SEL)ccbin Flags:(char)flagsin
{
	return [[self alloc] Object:dsin Data:datain Destination:destin Method:vcbin Start:NAN Time:timein CallbackObject:cobj Callback:ccbin Flags:flagsin];
}

+ (id) Object:(id)dsin Data:(float*)datain Destination:(float)destin Method:(SEL)vcbin Start:(float)arstart Time:(float)timein CallbackObject:(id)cobj Callback:(SEL)ccbin Flags:(char)flagsin
{
	return [[self alloc] Object:dsin Data:datain Destination:destin Method:vcbin Start:arstart Time:timein CallbackObject:cobj Callback:ccbin Flags:flagsin];
}

#pragma mark

- (id) Object:(id)dsin Data:(float*)datain Destination:(float)destin Method:(SEL)vcbin Start:(float)arstart Time:(float)timein CallbackObject:(id)cobj Callback:(SEL)ccbin Flags:(char)flagsin
{
	self = [super init];
	
	if( self )
	{
		// Eventually add Construct* checker and/or change id to Construct*?
		if( dsin   ){ dataspace = dsin;   }else{ NSLog(@"Can't make a timer without an object for a dataspace."); return 0L; }
		if( datain ){ data      = datain; }else{ }
		dest = destin; 
		if( vcbin ){ vsel = vcbin; vcb = (valcallback)[self methodForSelector:vcbin]; } else{ vsel = 0L; vcb = 0L; }
		
		if( data ){ if( memcmp( &arstart, &floatNaN, sizeof(float) ) ){ start = arstart; }else{ start = *data; } }else{ start = 0; }
		
		timeS = timein; 
		
		compobject = cobj;
		compcb = ccbin;
		
		flags = flagsin;
		
		gettimeofday( &startframe, 0L );
		cumadded = 0;
		
		if( (flags & KILLOTHERS) && data ){ KillTimers( data ); }
		
		next = 0L;
		if( firstTimer == 0L )
		{
			firstTimer = self;
		}
		else
		{ 
			Timer* a = firstTimer; 
			while( a->next != 0L ){	a = a->next; }
			a->next = self;
		}
	}
	
	return self;
}

- (void) dealloc
{
	if( self == currTimer )
	{
		pendingDelete = true;
		//[self retain];
		//printf( "count: %d\n", [self retainCount] );
	}
	else
	{
		if( self == firstTimer )
		{
			firstTimer = next;
		}
		else
		{
			Timer*	b = firstTimer;
			
			while( (b) && (b->next != self) )
			{
				b = b->next;
			}
			
			if( b )
			{
				b->next = next;
			}
			else
			{
				// Double free, technically should be allowable in these VERY narrow situations.  Curious that i havn't yet seen this place hit yet.
				// Actually go ahead and allow it.  There are situations like when you may want to kill Timers before or after they are done but you don't know if they are or not.
				//NSLog( @"The Timer we are trying to delete isn't in the main list.\n" );
				//killres = false;
			}
		}
		
		[super dealloc];
	}
}

#pragma mark

- (void) finishTimestamp:(timeval*)tv
{
	memcpy( tv, &startframe, sizeof(timeval) );
	
	float integer = 0.0;
	float decimal = modff( timeS, &integer );
	
	tv->tv_sec += (int)integer;
	tv->tv_usec += (int)(decimal * 1000000);
	
	if( tv->tv_usec >= 1000000 )
	{
		tv->tv_sec++;
		tv->tv_usec %= 1000000;
	}
}

#pragma mark

// Restarts a timer
- (oneway void) Restart
{
	gettimeofday( &startframe, 0L );
}

- (oneway void) Readjust:(float)newdest
{
	[self Restart];
	dest = newdest;
	
	//start = *data;
	start += cumadded;
	cumadded = 0;
}

#pragma mark private

// Standard Types of data manipulation functions
- (float) linear:(float)x
{
	return x;
}

- (float) sinusodalcurveup:(float)x
{
	return ((cos(x * M_PI) * -1) + 1)/2; 
}

- (float) hyperbolic:(float)x
{
	return x*x;
}

- (float) sinusodalbump:(float)x
{
	return sin(x * M_PI); 
}

- (float) triangular:(float)x
{
	if( x <= 0.5 )
	{
		return x/0.5;
	}
	else
	{
		return (1.0 - x)/0.5;
	}
}

- (float) accelaration:(float)x
{
	return 4 * (x - (x*x));
}

#pragma mark

// Updates this timer's status.  Returns false if the timer has not yet expired, returns true if it has.
- (bool) Increment
{
	bool res = false;
	
	// This here causes us to not start letting the increments happen until the next frame because of Timers that are created because of other Timer callbacks.
	if( (thisframe->tv_sec > startframe.tv_sec) || ((thisframe->tv_sec == startframe.tv_sec) && (thisframe->tv_usec >= startframe.tv_usec)) )
	{
		unsigned long msecs = (thisframe->tv_sec - startframe.tv_sec) * 1000000; 
		msecs += (thisframe->tv_usec - startframe.tv_usec);
		
		float progress = (float)msecs/(timeS * 1000000);
		
		unsigned long msecs2;
		
		if( (lastframe->tv_sec < startframe.tv_sec) || ((lastframe->tv_sec == startframe.tv_sec) && (lastframe->tv_usec < startframe.tv_usec)) )
		{ 
			msecs2 = 0; 
		}
		else
		{ 
			msecs2 = (lastframe->tv_sec - startframe.tv_sec) * 1000000; 
			msecs2 += (lastframe->tv_usec - startframe.tv_usec); 
		}	
		
		float progress2 = (float)msecs2/(timeS * 1000000);
		
		if( flags & CLAMP )
		{
			if( data )
			{
				if( flags & SETDESTINATION )
				{
					*data = dest;
				}
				else
				{
					cumadded += ( 1.0 * (dest - start));
					*data += ( 1.0 * (dest - start));
					start = dest;
				}
			}
			
			res = false;
		}
		else
		{
			if( flags & DOESNTDIE )
			{
				res = false;
				
				if( progress > 1.0 )
				{
					while( progress > 1.0 )
					{
						if( data )
						{
							if( flags & SETDESTINATION )
							{
								cumadded = 0;
								*data = start + dest;
								start += dest;
							}
							else
							{
								if( progress >= 2.0 )
								{
									cumadded += dest;
									*data += dest;
								}
								else
								{
									cumadded += (vcb(self, vsel, progress) - vcb(self, vsel, progress2)) * dest;
									*data += (vcb(self, vsel, progress) - vcb(self, vsel, progress2)) * dest;
								}
							}
						}
					
						if( compcb )
						{
							#ifdef VISIONDAEMON
							SwapProcessForObject( compobject );
							#endif
								[compobject performSelector:compcb withObject:self];
							#ifdef VISIONDAEMON
							SwapBack();
							#endif
						}
						
						progress -= 1.0;
					}
					
					// Resets the Timer to the correct amount for the next round
					unsigned long jumpmsecs = (unsigned long)(timeS * (float)1000000); 
					
					startframe.tv_sec  += jumpmsecs / 1000000;
					startframe.tv_usec += jumpmsecs % 1000000;
					
					startframe.tv_sec  += startframe.tv_usec/1000000;
					startframe.tv_usec %= 1000000;
					
					if( flags & REPEAT )
					{
						float poo = 0;
						*data = start + (modff(vcb(self, vsel, progress), &poo)) * dest;
					}
				}
				else
				{
					if( data )
					{
						cumadded += (vcb(self, vsel, progress) - vcb(self, vsel, progress2)) * dest;
						*data += (vcb(self, vsel, progress) - vcb(self, vsel, progress2)) * dest;
					}
				}
			}
			else
			{
				if( progress > 1 )
				{
					res = true;
					
					if( data )
					{
						if( flags & SETDESTINATION )
						{
							cumadded = dest - start;
							*data = dest;
						}
						else
						{
							cumadded += ( (1.0 - vcb(self, vsel, progress2)) * (dest - start));
							*data += ( (1.0 - vcb(self, vsel, progress2)) * (dest - start));
						}
					}
					
					if( compcb )
					{
						#ifdef VISIONDAEMON
						SwapProcessForObject( compobject );
						#endif
							[compobject performSelector:compcb withObject:self];
						#ifdef VISIONDAEMON
						SwapBack();
						#endif
					}
				}
				else
				{
					if( data )
					{
						cumadded += (vcb(self, vsel, progress) - vcb(self, vsel, progress2)) * (dest - start);
						*data += (vcb(self, vsel, progress) - vcb(self, vsel, progress2)) * (dest - start);
					}
					
					res = false;
				}
			}
		}
	}
	
	return res;
}

@end

#pragma mark-

// When a data structure that has had data that has been attached to by a timer they should call this upon deletion to ensure that there are no outstanding timers attached to the soon to be unallocated memory.
void CleanTimers( id dspace )
{
	Timer*	b = firstTimer;
	Timer*	c = 0L;

	while( b )
	{
		c = b;
		b = b->next;
			
		if( (c->dataspace == dspace) || (c->compobject == dspace) )
		{
			[c release];
		}
	}
}

#ifdef VISIONDAEMON
void CleanClientTimers( ClientProcess* dying )
{
	Timer*	b = firstTimer;
	Timer*	c = 0L;

	while( b )
	{
		c = b;
		b = b->next;
			
		if( ProcessFromZone( malloc_zone_from_ptr( c ) ) == dying )
		{
			[c release];
		}
	}
}
#endif

// Kills abruptly all timers that target on a certain data.
void KillTimers( float* dthing )
{	
	Timer*	b = firstTimer;
	Timer*	c = 0L;

	while( b )
	{
		c = b;
		b = b->next;
			
		if( c->data == dthing )
		{
			[c release];
		}
	}
}

// Kills abruptly all timers that target on a certain data.
void KillTimers( id TheObject, char* dname )
{
	float* dthing = 0L;
	Ivar blah = object_getInstanceVariable(TheObject, dname, (void**)&dthing);
	dthing = (float*)((char*)TheObject + blah->ivar_offset);
	
	Timer*	b = firstTimer;
	Timer*	c = 0L;

	while( b )
	{
		c = b;
		b = b->next;
			
		if( c->data == dthing )
		{
			[c release];
		}
	}
}

#pragma mark

// Manages all the timers.  This should be called every frame or every interval that the you want the timers to be maintained.
void TimerManagement( void )
{
    lastframe->tv_sec  = thisframe->tv_sec;
    lastframe->tv_usec = thisframe->tv_usec;
    
    gettimeofday( thisframe, 0L );
    
	Timer*	b = firstTimer;
	Timer*	c = 0L;

	currTimer = b;
	pendingDelete = false;
		
	while( b )
	{
		bool incrementresult = [b Increment];
		
		c = b;
		b = b->next; 
		
		currTimer = b;
		
		     if(   pendingDelete ){ [c release]; }
		else if( incrementresult ){ [c release]; }
		
		//if(   pendingDelete ){ [c release]; }
		//if( incrementresult ){ [c release]; }
		
		pendingDelete = false;
	}
}

#pragma mark

// Initializes variables that have to do with the timer manager.
void initChrono( void )
{
    lastframe = new timeval;
    thisframe = new timeval;
    
    gettimeofday( lastframe, 0L );
    gettimeofday( thisframe, 0L );
    
    firstTimer = 0L;
}