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

#import "NSObject.h"


#if defined(NeXT_RUNTIME)
#import <objc/hashtable2.h>
#import <objc/objc-class.h>
#import <objc/objc-runtime.h>
#elif defined(GNU_RUNTIME)
#import <objc/objc.h>
#else
#error You must define which runtime you are using
#endif

@implementation NSObject(ClassTree)

+ (NSMutableArray *)loadedSubclassArray
{
#if defined(GNU_RUNTIME)
  void *es = NULL;
#elif defined (NeXT_RUNTIME)
  NXHashTable *classes = objc_getClasses();
  NXHashState state = NXInitHashState(classes);
#else
#error You must define what runtime you are using
#endif


  NSMutableArray *myArray=[[[NSMutableArray alloc] init] autorelease];
  Class testClass=nil;

#if defined(GNU_RUNTIME)
  while ((testClass = objc_next_class(&es))) {
#elif define (NeXT_RUNTIME)
  while ( NXNextHashState(classes, &state, (void **)&testClass) ){
#else
#error What runtime is this?
#endif
    struct objc_class *upClass;	// walks classes
    upClass= testClass;
    while ((upClass = upClass->super_class)) { // keep walking the tree until supercalss is nill
      if (upClass == upClass->super_class) break;  // break on circular links
      if (upClass==self) {		// note that self is class object here
        [myArray addObject:testClass];
        break;
      }
    }
  }
  return myArray;
}


  
@end
