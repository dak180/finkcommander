/* 
File: SBString.h

 Category extending NSString class with following method(s):

 strip -- strip leading and trailing whitespace from a string


 Copyright (C) 2002  Steven J. Burr

 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

*/

#import <Foundation/Foundation.h>

@interface NSString ( SBString )

-(NSString *)strip;

@end
