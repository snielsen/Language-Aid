// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import <stdlib.h>
#import <stdio.h>
#import <string.h>

char* encode_hex( unsigned char* in, int length );	// Takes a length of bytes(in) and returns a string of the bytes in hex format
unsigned char* decode_hex( char* in );				// Takes a string of hex characters and returns the bytes represented by them