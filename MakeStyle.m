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
#import "ProjectCopyDelegate.h"


#define PROJECT_TYPE @"PROJECTTYPE"
@implementation MakeStyle

-(void)makeTarget: (NSString *)targetName
{
  if ([targetName isEqualToString: @"clean"]) 
    {
      [self removeBuildArea];
    } 
  else 
    {
      NSLog(@"Don't know how to make %@", targetName);
      exit (-5);
    }
}

/*
 Convience methods for subclasses
 */

-(void)buildSubprojects: (NSString *)target
{
  id subProjectList=[self subProjects];
  id theMan = [NSFileManager defaultManager];

  if (subProjectList && [subProjectList count]) 
    {
      id theEnum = [subProjectList objectEnumerator];
      id subProject;
      
      while ((subProject= [theEnum nextObject])) 
        {
	  if ( [theMan changeCurrentDirectoryPath: [subProject baseDirectoryPath]]) 
	    {
	      [subProject makeTarget:target];
	    } 
	  else 
	    {
	      NSLog(@"Can't build subproject %@, directory missing",[subProject baseDirectoryPath]);
	    }
	}
      [theMan changeCurrentDirectoryPath:[self baseDirectoryPath]];
    }
  [self installHeaders];
}

-(void)compileWithArguments: (NSArray *)arguments
{
  NSTask *aTask = [[[NSTask alloc] init] autorelease];
  int status;

  //NSLog(@"%@",arguments);
  [aTask setLaunchPath: @"gcc"];
  [aTask setArguments: arguments];
  [aTask setEnvironment: [self subTaskEnvironment]];
  [aTask launch];
  [aTask waitUntilExit];
  status = [aTask terminationStatus];
  if (status != 0) 
    {
      NSLog(@"Abort (%d)\n", status);
      exit(status);
    } 
}

-(void)compileObjectiveC: (NSString *)classFile
{
  NSString *outputFile = [self compileTargetForSource: classFile];
  id theMan = [NSFileManager defaultManager];

  [theMan makeRecursiveDirectory: [outputFile stringByDeletingLastPathComponent]];

  if ([theMan newerFile: classFile : outputFile] == classFile) 
    {
      NSMutableArray *arguments= [NSMutableArray array];

      NSLog(@"===Compiling  %@\n", classFile);
      [arguments addObject: classFile];
      [arguments addObjectsFromArray: [self cFlagArray]];
      [arguments addObject: @"-c"];
      [arguments addObject: @"-DNFOX_LINUX"];
#ifdef __BIG_ENDIAN__
      [arguments addObject: @"-D__BIG_ENDIAN__"];
#else
      [arguments addObject: @"-D__LITTLE_ENDIAN__"];
#endif
      [arguments addObject: @"-DGNUSTEP_BASE_LIBRARY=1"];
      [arguments addObject: @"-DGNU_GUI_LIBRARY=1"];
      [arguments addObject: @"-DGNU_RUNTIME=1"];
//    [arguments addObject:@"-g"];
      [arguments addObject: @"-Wno-import"];
      [arguments addObject: @"-Wall"];
      [arguments addObject: @"-fgnu-runtime"];
      [arguments addObject: @"-fconstant-string-class=NSConstantString"];

      [arguments addObject: @"-I."];
      // these two are for this project
      [arguments addObject: [NSString stringWithFormat:@"-I%@", [self publicHeaderPath]]];
      [arguments addObject: [NSString stringWithFormat:@"-I%@", [self projectHeaderPath]]];
      // this is all the system paths
      [arguments addObjectsFromArray: [self headerDirectoryFlags]];

      [arguments addObject: @"-o"];
      [arguments addObject: outputFile];

      [self compileWithArguments: arguments];
    } 
  else 
    {
      //NSLog(@"Up to date %@\n", classFile);
    }
}

-(void)buildClasses
{
  id theEnum = [[self classes] objectEnumerator];
  id classFile;

  while ((classFile = [theEnum nextObject])) 
    {
      [self compileObjectiveC: classFile];
    }
}

-(void)installHeaders
{
  id theMan = [NSFileManager defaultManager];
  NSArray *publicArray = [[self filesTable] objectForKey: @"PUBLIC_HEADERS"];
  NSArray *projectArray = [[self filesTable] objectForKey: @"PROJECT_HEADERS"];

  if (publicArray && [publicArray count]) 
    {
      [theMan makeRecursiveDirectory: [self publicHeaderPath]];
      [theMan updateFiles: publicArray toDirectory: [self publicHeaderPath]];
    }
  if (projectArray && [projectArray count]) 
    {
      [theMan makeRecursiveDirectory: [self projectHeaderPath]];
      [theMan updateFiles: projectArray toDirectory: [self projectHeaderPath]];
    }
}

-(void)installResources
{
  NSArray *theArray;
  id theMan = [NSFileManager defaultManager];

  [theMan makeRecursiveDirectory: [self resourcePath]];

  theArray = [[self filesTable] objectForKey: @"OTHER_RESOURCES"];
  if (theArray && [theArray count]) 
    {
      [theMan updateFiles: theArray toDirectory: [self resourcePath]];
    }
  theArray = [[self filesTable] objectForKey: @"INTERFACES"];
  if (theArray && [theArray count]) 
    {
      [theMan updateFiles:theArray toDirectory: [self resourcePath]];
    } 
}

- (void)removeBuildArea
{
  id theMan = [NSFileManager defaultManager];

  [theMan  removeFileAtPath: [self outputDirectory]
	            handler: nil];
}

- copyDelegate
{
  return [[[ProjectCopyDelegate alloc] init] autorelease];
}

@end
