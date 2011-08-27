// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import "encoding.h"

char* encode_hex( unsigned char* in, int length )
{
	char* buffer = (char*)malloc( length * 2 + 1 ); buffer[0] = 0;
	char dstr[3]; dstr[2] = 0;
	
	int i;
	for( i = 0; i < length; i++ )
	{
		sprintf( dstr, "%X", *( in + i ) ); if( dstr[1] == 0 ){ dstr[1] = dstr[0]; dstr[0] = '0'; }; dstr[2] = 0;
		strcat( buffer, dstr );
	}
	
	return buffer;
}

unsigned char* decode_hex( char* in )
{
	unsigned char* buffer = (unsigned char*)malloc( strlen(in)/2 );
	char dstr[3]; dstr[2] = 0;
	
	int i;
	for( i = 0; i < strlen(in)/2; i++ )
	{
		memcpy( dstr, in + i * sizeof(char) * 2, sizeof(char) * 2 );
		
		unsigned char byte = 0;
		
			 if( dstr[0] == '0' ){ byte +=  0 * 16; }
		else if( dstr[0] == '1' ){ byte +=  1 * 16; }
		else if( dstr[0] == '2' ){ byte +=  2 * 16; }
		else if( dstr[0] == '3' ){ byte +=  3 * 16; }
		else if( dstr[0] == '4' ){ byte +=  4 * 16; }
		else if( dstr[0] == '5' ){ byte +=  5 * 16; }
		else if( dstr[0] == '6' ){ byte +=  6 * 16; }
		else if( dstr[0] == '7' ){ byte +=  7 * 16; }
		else if( dstr[0] == '8' ){ byte +=  8 * 16; }
		else if( dstr[0] == '9' ){ byte +=  9 * 16; }
		else if( dstr[0] == 'A' || dstr[0] == 'a' ){ byte += 10 * 16; }
		else if( dstr[0] == 'B' || dstr[0] == 'b' ){ byte += 11 * 16; }
		else if( dstr[0] == 'C' || dstr[0] == 'c' ){ byte += 12 * 16; }
		else if( dstr[0] == 'D' || dstr[0] == 'd' ){ byte += 13 * 16; }
		else if( dstr[0] == 'E' || dstr[0] == 'e' ){ byte += 14 * 16; }
		else if( dstr[0] == 'F' || dstr[0] == 'f' ){ byte += 15 * 16; }
		else{ printf("decode_hex: invalid hex character %c\n", dstr[0]); }
		
			 if( dstr[1] == '0' ){ byte +=  0; }
		else if( dstr[1] == '1' ){ byte +=  1; }
		else if( dstr[1] == '2' ){ byte +=  2; }
		else if( dstr[1] == '3' ){ byte +=  3; }
		else if( dstr[1] == '4' ){ byte +=  4; }
		else if( dstr[1] == '5' ){ byte +=  5; }
		else if( dstr[1] == '6' ){ byte +=  6; }
		else if( dstr[1] == '7' ){ byte +=  7; }
		else if( dstr[1] == '8' ){ byte +=  8; }
		else if( dstr[1] == '9' ){ byte +=  9; }
		else if( dstr[1] == 'A' || dstr[1] == 'a' ){ byte += 10; }
		else if( dstr[1] == 'B' || dstr[1] == 'b' ){ byte += 11; }
		else if( dstr[1] == 'C' || dstr[1] == 'c' ){ byte += 12; }
		else if( dstr[1] == 'D' || dstr[1] == 'd' ){ byte += 13; }
		else if( dstr[1] == 'E' || dstr[1] == 'e' ){ byte += 14; }
		else if( dstr[1] == 'F' || dstr[1] == 'f' ){ byte += 15; }
		else{ printf("decode_hex: invalid hex character %c\n", dstr[1]); }
		
		memcpy( buffer + i, &byte, sizeof(char) );
	}
	
	return buffer;
}
