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
+(BOOL)buildsType:(NSString *)aType;
{
  if ([aType isEqualToString:@"Framework"]) {
    return YES;
  }
  return NO;
}


- (NSString *)sharedExecutablePath;
{
  return [[self outputDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"lib%@.so",[self projectName]]];
}

- (NSString *)finalExecutablePath;
{
  return [[self systemSharedLibraryDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"lib%@.so",[self projectName]]];
}

- (void)installLibrary;
{
  id theMan=[NSFileManager defaultManager];
  NSString *destRoot=[self finalExecutablePath];
  [theMan makeRecursiveDirectory:[self systemSharedLibraryDirectory]];
  [theMan removeFileAtPath:destRoot handler:nil];
  if ([theMan copyPath:[self sharedExecutablePath] toPath:destRoot handler:nil]==NO) {
    fprintf(stderr," ERROR: could not install %s\n",[destRoot cString]);
    exit(-1);
  } else {
    fprintf(stdout," installed %s\n",[destRoot cString]);
  }
}

-(void)installBundle;
{
  id theMan=[NSFileManager defaultManager];

NSString *destRoot=[self systemFrameworkRoot];
 destRoot = [destRoot stringByAppendingPathComponent:[self projectName]];
 destRoot=[destRoot stringByAppendingPathExtension:@"framework"];
 [theMan removeFileAtPath:destRoot handler:nil];
 if ([theMan copyPath:[self componentPath] toPath:destRoot handler:nil]==NO) {
   fprintf(stderr," ERROR: could not install %s\n",[destRoot cString]);
    exit(-1);
 } else {
   fprintf(stdout," installed %s\n",[destRoot cString]);
 }

 destRoot=[self systemHeaderDirectory];
 destRoot = [destRoot stringByAppendingPathComponent:[self projectName]];
  [theMan removeFileAtPath:destRoot handler:nil];
  if ([theMan copyPath:[self publicHeaderPath] toPath:destRoot handler:nil]==NO) {
    fprintf(stderr," ERROR: could not install %s\n",[destRoot cString]);
    exit(-1);
  } else {
    fprintf(stdout," installed %s\n",[destRoot cString]);
  }

}


-(void)makeComponentDirectory;
{
 id theMan = [NSFileManager defaultManager];
[theMan makeRecursiveDirectory:[self resourcePath]];
  // Languages
}

-(void)linkFinalProduct;
{
  NSTask *aTask = [[[NSTask alloc] init] autorelease];
  NSMutableArray *arguments= [NSMutableArray array];
  if ([[NSFileManager defaultManager] file:[self sharedExecutablePath] isOlderThanFiles:[self linkables]]==NO) {

//    fprintf(stdout,"up to date\n");
    return;
  }
  fprintf(stdout,"Creating shared library for framework\n");
  [arguments addObject:@"-shared"];
  [arguments addObject:@"-o"];
  [arguments addObject:[self sharedExecutablePath]];
  [arguments addObjectsFromArray:[self linkables]];
  [arguments addObjectsFromArray:[self libraryDirectoryFlags]];
  [arguments addObject:[NSString stringWithFormat:@"-L%@",[self systemSharedLibraryDirectory]]];

  //[arguments addObject:@"-lobjc"];
//  [arguments addObjectsFromArray:[self frameworkLinkFlags]];
  [aTask setLaunchPath:@"gcc"];
  [aTask setArguments:arguments];
  [aTask setEnvironment:[self subTaskEnvironment]];
  [aTask launch];
  sleep (30);
  [aTask waitUntilExit];
  if ([aTask terminationStatus]!=0) {
    fprintf(stderr,"Abort\n");
    exit([aTask terminationStatus]);
  } else {
  }

}


-(void)makeTarget:(NSString *)targetName;
{
  if ([targetName isEqualToString:@"InstallHeaders"]) {
    [self installHeaders];
    [self buildSubprojects:targetName];
  } else if ([targetName isEqualToString:@"default"]) {
    [self makeTarget:@"InstallHeaders"];
    [self makeComponentDirectory];
    [self buildSubprojects:@"default"];
    [self buildClasses];
    [self linkFinalProduct];
    [self installHeaders];
    [self installResources];
  } else if ([targetName isEqualToString:@"install"]) {
    [self makeTarget:@"default"];
    [self installBundle];
    [self installLibrary];
  } else {
    [super makeTarget:targetName];
  }
}

@end
