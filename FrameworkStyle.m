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
#import "FrameworkStyle.h"
#import "NSFileManager_CompareFiles.h"

@implementation FrameworkStyle

+(BOOL)buildsType: (NSString *)aType
{
  if ([aType isEqualToString: @"Framework"]) 
    {
      return YES;
    }
  return NO;
}

- (NSString *)projectHeaderPath
{
  return [[self buildHeaderDirectory] stringByAppendingPathComponent: [self projectName]];
}
- (NSString *)publicHeaderPath
{
  return [[self buildHeaderDirectory] stringByAppendingPathComponent: [self projectName]];
}

- (NSString *)sharedExecutablePath
{
  return [[self buildLibraryDirectory] stringByAppendingPathComponent: 
	    [NSString stringWithFormat: @"lib%@.so", [self projectName]]];
}

- (NSString *)staticExecutablePath
{
  return [[self buildLibraryDirectory] stringByAppendingPathComponent:
            [NSString stringWithFormat: @"lib%@.a", [self projectName]]];
}

- (void)install
{
  NSFileManager *theMan = [NSFileManager defaultManager];
  NSString *installDirectory = [self installDirectory];
  NSString *destRoot;
  NSDictionary *environDict = [[NSProcessInfo processInfo] environment];
   
  if (!installDirectory) 
    {
      NSLog(@"no INSTALLDIR set");
      exit(-5);
    }

  // Install the headers
  destRoot = [installDirectory stringByAppendingPathComponent: @"Headers"];

  //  NSLog(@"Installing Headers to %@\n", destRoot);
  [theMan installFromPath: [self publicHeaderPath] 
                    toDir: destRoot 
        operationDelegate: [self copyDelegate]];

  // Install the executable lib
  destRoot = [installDirectory stringByAppendingPathComponent: @"Libraries"];
  
  if (![self gnustepFlattened])
    {
      destRoot = [destRoot stringByAppendingPathComponent:
		    [environDict objectForKey: @"GNUSTEP_HOST_CPU"]];
      destRoot = [destRoot stringByAppendingPathComponent:
		    [environDict objectForKey: @"GNUSTEP_HOST_OS"]];
      destRoot = [destRoot stringByAppendingPathComponent:
		    [environDict objectForKey: @"LIBRARY_COMBO"]];
    }

  //NSLog(@"Installing shared library to %@\n", destRoot);
  [theMan installFromPath: [self sharedExecutablePath] 
                    toDir: destRoot
        operationDelegate: [self copyDelegate]];

  //NSLog(@"Installing static library to %@\n", destRoot);
  [theMan installFromPath: [self staticExecutablePath] 
                    toDir: destRoot
        operationDelegate: [self copyDelegate]];
}

- (void)makeComponentDirectory
{
 id theMan = [NSFileManager defaultManager];

 [theMan makeRecursiveDirectory: [self resourcePath]];
 // Languages
}

-(void)linkSharedExecutable
{
  NSMutableArray *arguments= [NSMutableArray array];

  if ([[NSFileManager defaultManager] file: [self sharedExecutablePath] 
			  isOlderThanFiles: [self linkables]]==NO) 
    {
      //    NSLog(@"up to date\n");
      return;
    }

  NSLog(@"===Linking    %@\n", [self sharedExecutablePath]);
  [arguments addObject: @"-shared"];
  [arguments addObject: @"-o"];
  [arguments addObject: [self sharedExecutablePath]];
  [arguments addObjectsFromArray: [self linkables]];
  [arguments addObjectsFromArray: [self libraryDirectoryFlags]];

  //[arguments addObject: @"-lobjc"];
//  [arguments addObjectsFromArray: [self frameworkLinkFlags]];

  [self compileWithArguments: arguments];
}

-(void)linkStaticExecutable
{
  NSTask *aTask = [[[NSTask alloc] init] autorelease];
  NSMutableArray *arguments= [NSMutableArray array];

  if ([[NSFileManager defaultManager] file: [self staticExecutablePath] 
			  isOlderThanFiles: [self linkables]]==NO) 
    {
      //    NSLog(@"up to date\n");
      return;
    }

  NSLog(@"===Linking    %@\n", [self staticExecutablePath]);
  [arguments addObject: @"r"];
  [arguments addObject: [self staticExecutablePath]];
  [arguments addObjectsFromArray: [self linkables]];
  //[arguments addObjectsFromArray: [self libraryDirectoryFlags]];

  //[arguments addObject: @"-lobjc"];
  //[arguments addObjectsFromArray: [self frameworkLinkFlags]];
  [aTask setLaunchPath: @"ar"];
  [aTask setArguments: arguments];
  [aTask setEnvironment: [self subTaskEnvironment]];
  [aTask launch];
  //sleep (30);
  [aTask waitUntilExit];
  if ([aTask terminationStatus]!=0) 
    {
      NSLog(@"Abort\n");
      exit([aTask terminationStatus]);
    } 
}

- (void)linkFinalProduct
{
  [self linkSharedExecutable];
  [self linkStaticExecutable];
}

-(void)makeTarget: (NSString *)targetName
{
  if ([targetName isEqualToString: @"InstallHeaders"]) 
    {
      [self installHeaders];
      [self buildSubprojects:targetName];
    } 
  else if ([targetName isEqualToString: @"default"]) 
    {
      [self makeTarget: @"InstallHeaders"];
      [self makeComponentDirectory];
      [self buildSubprojects: @"default"];
      [self buildClasses];
      [self linkFinalProduct];
      [self installHeaders];
      [self installResources];
    } 
  else if ([targetName isEqualToString: @"install"]) 
    {
      [self makeTarget: @"default"];
      [self install];
    } 
  else 
    {
      [super makeTarget: targetName];
    }
}

@end
