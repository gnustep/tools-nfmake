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

#import <unistd.h>

#import "MakeStyle.h"
#import "NSObject.h"
#import "NSFileManager_CompareFiles.h"


#define PROJECT_TYPE @"PROJECTTYPE"
@implementation MakeStyle


+(BOOL)buildsType:(NSString *)aType;
{
  return NO;
}


-(void)makeTarget:(NSString *)targetName;
{
  if ([targetName isEqualToString:@"clean"]) {
    [self removeBuildArea];
  } else {
    NSLog(@"Don't know how to make %@",targetName);
    exit (-5);
  }
}

-(void)setProject:(PBProject *)aDict;
{
  if (self) {
    [self release];
    self = nil;
  }
  self=[aDict retain];
}








/*
 Convience methods for subclasses
 */


-(void)buildSubprojects:(NSString *)target;
{
  id subProjectList=[self subProjects];
  id theMan = [NSFileManager defaultManager];

  [self installHeaders];
  if (subProjectList && [subProjectList count]) {
    id theEnum = [subProjectList objectEnumerator];
    id subProject;

    while ((subProject= [theEnum nextObject])) {
      [theMan changeCurrentDirectoryPath:[subProject baseDirectoryPath]];
      [subProject makeTarget:target];
    }
    [theMan changeCurrentDirectoryPath:[self baseDirectoryPath]];
  }
  [self installHeaders];
}

-(void)compileObjectiveC:(NSString *)classFile
{
  NSString *outputFile=[self compileTargetForSource:classFile];
  id theMan = [NSFileManager defaultManager];

  [theMan makeRecursiveDirectory:[outputFile stringByDeletingLastPathComponent]];

  if ([theMan newerFile:classFile :outputFile]==classFile) {
    NSTask *aTask = [[[NSTask alloc] init] autorelease];
    NSMutableArray *arguments= [NSMutableArray array];
    fprintf(stdout,"===Compiling  %s\n",[classFile cString]);
    fflush(stdout);
    [arguments addObjectsFromArray:[self cFlagArray]];
    [arguments addObject:@"-Wall"];
    [arguments addObject:@"-DNFOX_LINUX"];
    [arguments addObject:@"-D__LITTLE_ENDIAN__"];
    [arguments addObject:@"-DGNU_RUNTIME"];
    [arguments addObject:@"-g"];
    [arguments addObject:@"-c"];
    [arguments addObject:@"-objc"];
    [arguments addObject:@"-o"];
    [arguments addObject:outputFile];
    [arguments addObject:@"-Wno-import"];
    [arguments addObject:@"-Wall"];
    [arguments addObject:@"-I."];
    // these two are for this project
    [arguments addObject:[NSString stringWithFormat:@"-I%@",[self publicHeaderPath]]];
    [arguments addObject:[NSString stringWithFormat:@"-I%@",[self projectHeaderPath]]];
    // this is all the system paths
    [arguments addObjectsFromArray:[self headerDirectoryFlags]];
#define BAD_GCC
#ifdef BAD_GCC
// The gnu runtime requires that every linked Objective-C file have a unique path when compiled
// (I'm not kidding -K2 12/19/99)
// This is fixed in our patch to GCC 2.8.1
// (No it's still not -K2 2/14/99)
    [arguments addObject:[[theMan currentDirectoryPath] stringByAppendingPathComponent:classFile]];
#else
    [arguments addObject:classFile];
#endif
    //NSLog(@"%@",arguments);
    [aTask setLaunchPath:@"gcc"];
    [aTask setArguments:arguments];
    [aTask launch];
    sleep(30);
    [aTask waitUntilExit];
    if ([aTask terminationStatus]!=0) {
      fprintf(stderr,"Abort (%d)\n",[aTask terminationStatus]);
      exit([aTask terminationStatus]);
    } else {
    }
  } else {
    //fprintf(stdout,"Up to date %s\n",[classFile cString]);
    //fflush(stdout);
  }
}

-(void)buildClasses;
{
  id theEnum = [[self classes] objectEnumerator];
  id classFile;
  while ((classFile = [theEnum nextObject])) {
    [self compileObjectiveC:classFile];
  }
}



-(void)installHeaders;
{
  id theMan = [NSFileManager defaultManager];
  NSArray *publicArray = [[self filesTable] objectForKey:@"PUBLIC_HEADERS"];
  NSArray *projectArray = [[self filesTable] objectForKey:@"PROJECT_HEADERS"];
  if (publicArray && [publicArray count]) {
    [theMan makeRecursiveDirectory:[self publicHeaderPath]];
    [theMan updateFiles:publicArray toDirectory:[self publicHeaderPath]];
  }
  if (projectArray && [projectArray count]) {
    [theMan makeRecursiveDirectory:[self projectHeaderPath]];
    [theMan updateFiles:projectArray toDirectory:[self projectHeaderPath]];
  }
}


-(void)installResources;
{
  NSArray *theArray;
  id theMan = [NSFileManager defaultManager];

  [theMan makeRecursiveDirectory:[self resourcePath]];

  theArray = [[self filesTable] objectForKey:@"OTHER_RESOURCES"];
  if (theArray && [theArray count]) {
    [theMan updateFiles:theArray toDirectory:[self resourcePath]];
  }
  theArray = [[self filesTable] objectForKey:@"INTERFACES"];
  if (theArray && [theArray count]) {
    [theMan updateFiles:theArray toDirectory:[self resourcePath]];
  }

}

- (void)removeBuildArea;
{
  id theMan = [NSFileManager defaultManager];
[theMan  removeFileAtPath: [self outputDirectory]
		  handler: nil];
}

@end
