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

#import <Foundation/Foundation.h>
#import "MakeStyle.h"
#import "PBProject.h"


int main (int argc, const char *argv[])
{
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
  id selfProcess = [NSProcessInfo processInfo];
  MakeStyle *theProject=[MakeStyle parse:@"PB.project"];
  //id theMan = [NSFileManager defaultManager];
  NSString *projectStyle=nil;

  if (!theProject) {
    fprintf(stderr,"Could not parse PB.project file\n");
    exit (-1);
  }

  if ([[selfProcess arguments] count]>1){
    projectStyle=[[selfProcess arguments] objectAtIndex:1];
  }

  if ([projectStyle characterAtIndex:0] == '-') {
	  NSString *query = [projectStyle stringWithoutPrefix:@"-"];
	  SEL theSelector = NSSelectorFromString(query);
	  id response=@"";
	  if (theSelector && [theProject respondsToSelector:theSelector]) {
	     response = [theProject performSelector:theSelector];
	  }
	  if ([response isKindOfClass:[NSArray class]]) {
		  int x;
		  for (x=0; x< [response count]; x++) {
			  fprintf(stdout,"%s\n",[[response objectAtIndex:x] lossyCString] );
		  }
	  } 
	  if ([response isKindOfClass:[NSString class]]) {
	  fprintf(stdout,"%s",[response lossyCString] );
	  } 
  } else {
    if (!projectStyle) {
      [theProject makeTarget:@"default"];
    } else {
      [theProject makeTarget:projectStyle];
    }
  }

  [pool release];
  exit(0);       // insure the process exit status is 0
  return 0;      // ...and make main fit the ANSI spec.
}
