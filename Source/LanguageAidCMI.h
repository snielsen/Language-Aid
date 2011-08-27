// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import <CoreFoundation/CoreFoundation.h>
#import <CoreFoundation/CFPlugInCOM.h>
#import <ApplicationServices/ApplicationServices.h>
#import <Carbon/Carbon.h>
#import <CoreServices/CoreServices.h>

#import <unistd.h>

#import "LAUserDefaults.h"

#define kLanguageAidCMIFactoryID ( CFUUIDGetConstantUUIDWithBytes( NULL,0x4a,0xb0,0x62,0x88,0x56,0xa4,0x11,0xdc,0x83,0x14,0x08,0x00,0x20,0x0c,0x9a,0x66 ) )
//4ab06288-56a4-11dc-8314-0800200c9a66

@class LanguageAidCMI;

// The layout for an instance of LanguageAidCMIType.
typedef struct LanguageAidCMIType
{
	ContextualMenuInterfaceStruct	*cmInterface;
	CFUUIDRef						factoryID;
	UInt32							refCount;
	LanguageAidCMI*					LACMI;
	
} LanguageAidCMIType;

static HRESULT LanguageAidCMIQueryInterface( void* thisInstance, REFIID iid, LPVOID* ppv );
static ULONG LanguageAidCMIAddRef( void* thisInstance );
static ULONG LanguageAidCMIRelease( void* thisInstance );

static OSStatus LanguageAidCMIExamineContext( void* thisInstance,const AEDesc* inContext, AEDescList* outCommandPairs );
static OSStatus LanguageAidCMIHandleSelection( void* thisInstance, AEDesc* inContext, SInt32 inCommandID );
static void LanguageAidCMIPostMenuCleanup( void* thisInstance );

extern "C" { extern void* LanguageAidCMIFactory( CFAllocatorRef allocator, CFUUIDRef typeID ) __attribute__ ((visibility ("default"))); }

static ContextualMenuInterfaceStruct LanguageAidCMIInterface =
{
	// Required padding for COM
	NULL,

	// These three are the required COM functions
	LanguageAidCMIQueryInterface,
	LanguageAidCMIAddRef,
	LanguageAidCMIRelease,

	// Interface implementation
	LanguageAidCMIExamineContext,
	LanguageAidCMIHandleSelection,
	LanguageAidCMIPostMenuCleanup
};

@interface LanguageAidCMI : NSObject
{
	LAUserDefaults*					defaults;
	NSMutableDictionary*			Triggers;
}

NSPasteboard* servicePasteboard;

- (bool) hasSelectedText;
- (NSAppleEventDescriptor*) CreateMenus;
- (void) hitMenu:(int)menuid;

@end