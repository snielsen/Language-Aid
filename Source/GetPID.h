// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import <stdlib.h>
#import <stdio.h>
	 
enum
{
	kSuccess = 0,
	kCouldNotFindRequestedProcess = -1, 
	kInvalidArgumentsError = -2,
	kErrorGettingSizeOfBufferRequired = -3,
	kUnableToAllocateMemoryForBuffer = -4,
	kPIDBufferOverrunError = -5
};

// These routines were cannibalized from Apple sample code and were altered so that they only returned processes of ProcessName, that are not zombied and run by the same user as this calling program (ie not fast switched users).
int GetAllPIDsForProcessName( const char* ProcessName, pid_t ArrayOfReturnedPIDs[], const unsigned int NumberOfPossiblePIDsInArray, unsigned int* NumberOfMatchesFound, int* SysctlError);
int GetPIDForProcessName(const char* ProcessName);
