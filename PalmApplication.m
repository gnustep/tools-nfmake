/* 
   Copyright (C) 1999 Free Software Foundation, Inc.
   
   Written by:	Karl Kraft <karl@nfox.com>
   Date: 		Dec 00
   
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

/*
 *  A style for building palm applications.
 *
 *  Takes the classes and other_linked and creates a .o for each
 *  
 *  Links the .o's together to make a .grc
 *  
 *  Runs pilrc on each of the resource files to make .bin
 *  
 *  Runs build prc to put the bins and the grc together.
 *  
 *  
 *  In order to maintain the clean division of source and build products
 *  (that is build products don't get created in the source tree), this
 *  make style is bit different than the others, due to the tools involved.
 *  
 *  Build-prc does not allow absolutes nor relative paths to files, all
 *  files input to build-prc must be in the same directory, so it's all
 *  built into the same place, and we jump there to get the build to work.
 *  
 *  For convience we also make clean on the entire project on every build
 *  cycle, so that nothing is in that directory that we don't want.
 */
 
#import <unistd.h>

#import "PalmApplication.h"
#import "NSFileManager_CompareFiles.h"

@implementation PalmApplication

+(BOOL)buildsType:(NSString *)aType;
{
  if ([aType isEqualToString:@"PalmApplication"]) {
    return YES;
  }
  return NO;
}

- (NSString *)prcInputDir;
{
  NSString *aString = [[self outputDirectory] stringByAppendingPathComponent:@"prcinput"];
  return aString;
}

- (NSString *)compilerOutput;
{
  NSString *aString = [[self outputDirectory] stringByAppendingPathComponent:@"o"];
  return aString;
}




- (NSArray *)pilrcFlags;
{
  NSArray *baseArray= [[self filesTable] objectForKey:@"RESOURCE_DIRS"];
  NSMutableArray *newArray = [NSMutableArray array];

  int x;
  for (x=0; x< [baseArray count]; x++) {
    [newArray addObject:@"-I"];
    [newArray addObject:[baseArray objectAtIndex:x]];
  }
  return newArray;
}

- (void)makeResourceFile:(NSString *)resourceFile;
{
  id theMan = [NSFileManager defaultManager];

  [theMan makeRecursiveDirectory:[self prcInputDir]];

  {
    NSTask *aTask = [[[NSTask alloc] init] autorelease];
    NSMutableArray *arguments= [NSMutableArray array];
    fprintf(stdout,"===Resourcing  %s\n",[resourceFile cString]);
    fflush(stdout);
    [arguments addObject:@"-q"];
    [arguments addObjectsFromArray:[self pilrcFlags]];
    [arguments addObject:resourceFile];
    [arguments addObject:[self prcInputDir]];

    [aTask setLaunchPath:@"pilrc"];
    [aTask setArguments:arguments];
    [aTask launch];
    //sleep(1);
    [aTask waitUntilExit];
    if ([aTask terminationStatus]!=0) {
      fprintf(stderr,"Abort (%d)\n",[aTask terminationStatus]);
      exit([aTask terminationStatus]);
    } else {
    }
  }
  
}

- (NSString *)makeCodeFile:(NSString *)resourceFile;
{
  id theMan = [NSFileManager defaultManager];
NSString *outputName = [[resourceFile stringByDeletingPathExtension] stringByAppendingPathExtension:@"o"];

  {
	  NSString *targetDir;
	  targetDir = [[self compilerOutput] stringByAppendingPathComponent:outputName];
	  targetDir = [targetDir stringByDeletingLastPathComponent];
    NSLog(@"Making %@",targetDir);
    [theMan makeRecursiveDirectory:targetDir];
  }

  {
    NSTask *aTask = [[[NSTask alloc] init] autorelease];
    NSMutableArray *arguments= [NSMutableArray array];
    fprintf(stdout,"===Compiling  %s\n",[resourceFile cString]);
    fflush(stdout);
    [arguments addObject:@"-g"];
    [arguments addObject:@"-mdebug-labels"];
    [arguments addObject:@"-O1"];
    [arguments addObject:@"-c"];
    [arguments addObject:@"-Wall"];
    [arguments addObject:resourceFile];
    [arguments addObject:@"-o"];
    [arguments addObject:[[self compilerOutput] stringByAppendingPathComponent:outputName]];

    [aTask setLaunchPath:@"m68k-palmos-gcc"];
    [aTask setArguments:arguments];
    [aTask launch];
    //sleep(1);
    [aTask waitUntilExit];
    if ([aTask terminationStatus]!=0) {
      fprintf(stderr,"Abort (%d)\n",[aTask terminationStatus]);
      exit([aTask terminationStatus]);
    } else {
    }
  }
  return [[self compilerOutput] stringByAppendingPathComponent:outputName];
}


- (void)makeCode;
{
  NSArray *baseArray= [[self filesTable] objectForKey:@"OTHER_LINKED"];
  NSMutableArray *allOArray= [NSMutableArray array];
  int x=[baseArray count];
  while (x--) {
    NSString *outputFile = [self makeCodeFile:[baseArray objectAtIndex:x]];
    [allOArray addObject:outputFile];
  }
  
  {
    NSTask *aTask = [[[NSTask alloc] init] autorelease];
    NSMutableArray *arguments= [NSMutableArray array];
    fprintf(stdout,"===Linking  PROJECTSYM\n");
    fflush(stdout);
    [arguments addObject:@"-g"];
    [arguments addObject:@"-O1"];
    [arguments addObject:@"-o"];
    [arguments addObject:[[self prcInputDir] stringByAppendingPathComponent:@"PROJECTSYM"]];
    [arguments addObjectsFromArray:allOArray];

    [aTask setLaunchPath:@"m68k-palmos-gcc"];
    [aTask setArguments:arguments];
    [aTask launch];
    //sleep(1);
    [aTask waitUntilExit];
    if ([aTask terminationStatus]!=0) {
      fprintf(stderr,"Abort (%d)\n",[aTask terminationStatus]);
      exit([aTask terminationStatus]);
    } else {
    }
  }
}


- (NSString *)executablePath;
{
  NSString *theString = [self outputDirectory];
  theString = [theString stringByAppendingPathComponent:[self projectName]];
  theString = [theString stringByAppendingPathExtension:@"prc"];
  
  return theString;
}

- (void)buildPrc;
{
	NSFileManager *theMan = [NSFileManager defaultManager];
	NSString *sourceDirectory = [theMan currentDirectoryPath];
	

  NSTask *aTask = [[[NSTask alloc] init] autorelease];
  NSMutableArray *arguments= [NSMutableArray array];

  NSString *targetFile = [self executablePath];
  NSString *defFile = [initialDictionary objectForKey:@"PROJECTDEF"];

  [theMan changeCurrentDirectoryPath:[self prcInputDir]];

  fprintf(stdout,"===Building  %s\n",[targetFile cString]);
  fflush(stdout);

// convert some to absolute path
  defFile  = [sourceDirectory stringByAppendingPathComponent:defFile];
  
  [arguments addObject:@"-o"];
  [arguments addObject:targetFile];
  [arguments addObject:defFile];
  [arguments addObjectsFromArray:[theMan directoryContentsAtPath:@"."]];
//  NSLog(@"%@",arguments);
  [aTask setLaunchPath:@"build-prc"];
  [aTask setArguments:arguments];
  [aTask launch];

  //sleep(1);
  [aTask waitUntilExit];
  if ([aTask terminationStatus]!=0) {
    fprintf(stderr,"Abort (%d)\n",[aTask terminationStatus]);
    exit([aTask terminationStatus]);
  } else {
  }
[theMan changeCurrentDirectoryPath:sourceDirectory];

}

- (void)installFinalProduct;
{
}

- (void)makeResourceFiles;
{
  NSArray *baseArray= [[self filesTable] objectForKey:@"RESOURCE_FILES"];
  int x=[baseArray count];
  while (x--) {
    [self makeResourceFile:[baseArray objectAtIndex:x]];
  }
}

- (void)makeTarget:(NSString *)targetName;
{
  if ([targetName isEqualToString:@"default"]) {
    [super makeTarget:@"clean"];  // the tools prevent any other solid way from preventing old code from creeping in
    [self makeResourceFiles];
    [self makeCode];
    [self buildPrc];
  } else if ([targetName isEqualToString:@"install"]) {
    [self makeTarget:@"default"];
    [self installFinalProduct];
  } else {
    [super makeTarget:targetName];
  }
}


@end
