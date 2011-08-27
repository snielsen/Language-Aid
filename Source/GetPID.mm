// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import "GetPID.h"

#import <errno.h>
#import <string.h>
#import <sys/sysctl.h>
#import <sys/types.h>
#import <unistd.h>

int GetAllPIDsForProcessName( const char* ProcessName, pid_t ArrayOfReturnedPIDs[], const unsigned int NumberOfPossiblePIDsInArray, unsigned int* NumberOfMatchesFound, int* SysctlError )
{
    // Defining local variables for this function and initializing all to zero
    int					mib[6] = {0,0,0,0,0,0}; // used for sysctl call.
    int					SuccessfullyGotProcessInformation;
    size_t				sizeOfBufferRequired = 0; // set to zero to start with.
    int					error = 0;
    long				NumberOfRunningProcesses = 0;
    unsigned int		Counter = 0;
    struct kinfo_proc*	BSDProcessInformationStructure = NULL;
    pid_t				CurrentExaminedProcessPID = 0;
    char*				CurrentExaminedProcessName = NULL;

    // Checking input arguments for validity
    if( (ProcessName == NULL)          ||
		(ArrayOfReturnedPIDs == NULL)  ||
		(NumberOfMatchesFound == NULL) ||
		(NumberOfPossiblePIDsInArray <= 0) ){ return( kInvalidArgumentsError); }

    // initalizing PID array so all values are zero
    memset( ArrayOfReturnedPIDs, 0, NumberOfPossiblePIDsInArray * sizeof(pid_t) );
        
    *NumberOfMatchesFound = 0; //no matches found yet

    if( SysctlError != NULL ){ *SysctlError = 0; } // only set sysctlError if it is present

    // Getting list of process information for all processes
	
    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_ALL;

    SuccessfullyGotProcessInformation = FALSE;
    
    while( SuccessfullyGotProcessInformation == FALSE )
    {
		error = sysctl( mib, 3, NULL, &sizeOfBufferRequired, NULL, NULL );

        if( error != 0 ) 
        {
            if( SysctlError != NULL ){ *SysctlError = errno; } // we only set this variable if the pre-allocated variable is given

            return kErrorGettingSizeOfBufferRequired;
        }
    
        // Now we successful obtained the size of the buffer required for the sysctl call.  This is stored in the SizeOfBufferRequired variable.  We will malloc a buffer of that size to hold the sysctl result.
        BSDProcessInformationStructure = (struct kinfo_proc*)malloc( sizeOfBufferRequired );

        if( BSDProcessInformationStructure == NULL )
        {
            if( SysctlError != NULL ){ *SysctlError = ENOMEM; } // we only set this variable if the pre-allocated variable is given

            return kUnableToAllocateMemoryForBuffer; // unrecoverable error (no memory available) so give up
        }
    
        error = sysctl( mib, 3, BSDProcessInformationStructure, &sizeOfBufferRequired, NULL, NULL );
    
        // Here we successfully got the process information.  Thus set the variable to end this sysctl calling loop
        if( error == 0 ){ SuccessfullyGotProcessInformation = TRUE; }else{ if( BSDProcessInformationStructure ){ free( BSDProcessInformationStructure ); BSDProcessInformationStructure = NULL; } }
    }

    // Going through process list looking for processes with matching names

    NumberOfRunningProcesses = sizeOfBufferRequired / sizeof( struct kinfo_proc );  
    
    for( Counter = 0; Counter < NumberOfRunningProcesses; Counter++ )
    {
        // Getting PID of process we are examining
        CurrentExaminedProcessPID = BSDProcessInformationStructure[Counter].kp_proc.p_pid; 
    
        // Getting name of process we are examining
        CurrentExaminedProcessName = BSDProcessInformationStructure[Counter].kp_proc.p_comm; 
        
		//printf("%s\n", CurrentExaminedProcessName);
		
		// Valid PID and name matches
        if( (CurrentExaminedProcessPID > 0) && ((strncmp( CurrentExaminedProcessName, ProcessName, MAXCOMLEN ) == 0)) )
        {
			// It has to be run by the same user as this program (don't want to look for switched user's processes)
			if( getuid() == BSDProcessInformationStructure[Counter].kp_eproc.e_ucred.cr_uid )
			{
				// no zombies allowed
				if( !(BSDProcessInformationStructure[Counter].kp_proc.p_stat & SZOMB) )
				{
					//printf( "%d\n", BSDProcessInformationStructure[Counter].kp_eproc.e_pcred.p_svuid );
					// Got a match add it to the array if possible
					if( (*NumberOfMatchesFound + 1) > NumberOfPossiblePIDsInArray )
					{
						// if we overran the array buffer passed we release the allocated buffer give an error.
						if( BSDProcessInformationStructure ){ free( BSDProcessInformationStructure ); BSDProcessInformationStructure = NULL; }
						return(kPIDBufferOverrunError);
					}
				
					// adding the value to the array.
					ArrayOfReturnedPIDs[*NumberOfMatchesFound] = CurrentExaminedProcessPID;
					
					// incrementing our number of matches found.
					*NumberOfMatchesFound = *NumberOfMatchesFound + 1;
				}
			}
        }
    }

    if( BSDProcessInformationStructure ){ free( BSDProcessInformationStructure ); BSDProcessInformationStructure = NULL; }
	
    if( *NumberOfMatchesFound == 0 ){ return(kCouldNotFindRequestedProcess); }else{ return(kSuccess); }
}

int GetPIDForProcessName(const char* ProcessName)
{
    pid_t PIDArray[1] = {0};
    int Error = 0;
    unsigned int NumberOfMatches = 0;  

    Error = GetAllPIDsForProcessName( ProcessName, PIDArray, 1, &NumberOfMatches, NULL );
    
	//printf( "%d %d\n", Error, NumberOfMatches  );
	
    if( (Error == 0) && (NumberOfMatches == 1) )
		{ return((int) PIDArray[0]); } // return the one PID we found.
    else{ return -1; }
}
