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

#import "BundleStyle.h"
#import <unistd.h>
#import "NSFileManager_CompareFiles.h"

@implementation BundleStyle
+(BOOL)buildsType:(NSString *)aType;
{
  if ([aType isEqualToString:@"Loadable Bundle"]) {
    return YES;
  }
  return NO;
}


-(void)linkFinalProduct;
{
  NSTask *aTask = [[[NSTask alloc] init] autorelease];
  NSMutableArray *arguments= [NSMutableArray array];

  if ([[NSFileManager defaultManager] file:[self executablePath] isOlderThanFiles:[self linkables]]==NO) {

//    fprintf(stdout,"up to date\n");
    return;
  }

  fprintf(stdout,"Linking %s\n",[[self executablePath] cString]); fflush(stdout);

  //[arguments addObject:@"-v"];
  [arguments addObjectsFromArray:[self cFlagArray]];
  [arguments addObject:@"-shared"];
  [arguments addObject:@"-o"];
  [arguments addObject:[self executablePath]];
  [arguments addObjectsFromArray:[self linkables]];
  [arguments addObject:@"-L/usr/GNUstep/Libraries/machine/"];
  [arguments addObject:[NSString stringWithFormat:@"-L%@",[self systemSharedLibraryDirectory]]];

//  [arguments addObjectsFromArray:[self frameworkLinkFlags]];
  

  [aTask setLaunchPath:@"gcc"];
  [aTask setArguments:arguments];
//NSLog(@"%@",arguments);
  [aTask launch];
  sleep(30);
  [aTask waitUntilExit];
  if ([aTask terminationStatus]!=0) {
    fprintf(stderr,"Abort\n");
    exit([aTask terminationStatus]);
  } else {
  }
}

-(void)installBundle;
{
  id theMan=[NSFileManager defaultManager];
  NSString *destRoot=[self systemComponentRoot];

  NSString *infoPath;

  destRoot = [destRoot stringByAppendingPathComponent:[self projectName]];
  destRoot=[destRoot stringByAppendingPathExtension:[self buildExtension]];
  [theMan removeFileAtPath:destRoot handler:nil];
  if ([theMan copyPath:[self componentPath] toPath:destRoot handler:nil]==NO) {
   fprintf(stderr," ERROR: could not install bundle %s\n",[destRoot cString]);
   exit (-1);
 } else {
   fprintf(stdout," installed %s\n",[destRoot cString]);
 }
  
  /* executablePath = [destRoot stringByAppendingPathComponent:[self projectName]];
  if ([theMan copyPath:[self executablePath] toPath:executablePath handler:nil]==NO) {
   fprintf(stderr," ERROR: could not install %s\n",[executablePath cString]);
   exit (-1);
 } else {
   fprintf(stdout," installed %s\n",[executablePath cString]);
 } 
  */
  infoPath = [destRoot stringByAppendingPathComponent:@"Info.plist"];
  {
   NSMutableDictionary *theDict=[NSMutableDictionary dictionary];
   [theDict setObject:[self projectName] forKey:@"NSExecutable"];
   [theDict writeToFile:infoPath atomically:YES];
  }
}


-(void)makeTarget:(NSString *)targetName;
{
  if ([targetName isEqualToString:@"default"]) {
    [self buildSubprojects:targetName];
    [self buildClasses];
    [self installHeaders];
    [self installResources];
    [self linkFinalProduct];
  } else  if ([targetName isEqualToString:@"install"]) {
    [self makeTarget:@"default"];
    [self installBundle];
  } else {
    [super makeTarget:targetName];
  }
}



@end
