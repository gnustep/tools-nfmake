/* 
   Copyright (C) 1999 Free Software Foundation, Inc.
   
   Written by:	Karl Kraft <karl@nfox.com>
   Date: 		Sep 99
   
   This file is part of nfmake - a utility for building GNUstep programs
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#import "WebObjectsSubproject.h"

@implementation WebObjectsSubproject
+(BOOL)buildsType:(NSString *)aType;
{
  if ([aType isEqualToString:@"WebObjectsSubproject"]) {
    return YES;
  }
  return NO;
}

-(NSString *)componentPath;   // where the component is assembled
{
  return [parentProject componentPath];
}

-(NSString *)serverResourcePath;
{
  return [parentProject serverResourcePath];
}

- (NSArray *)componentSpreadResources;
{
  return   [parentProject componentSpreadResources];
  // [parentProject filesTable] objectForKey:@"WEBSERVER_RESOURCES"];
}

-(void)makeTarget:(NSString *)targetName;
{
  fprintf(stdout,"Building %s\n",[[self projectName] cString]);
  fflush(stdout);
  if ([targetName isEqualToString:@"default"]) {
    [self installResources];
    [self buildSubprojects:targetName];
    [self buildClasses];
  } else {
    [super makeTarget:targetName];
  }

}

@end
