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

@interface PBProject : NSObject
{
  NSDictionary *initialDictionary;
  id parentProject;
  id childList;
  id baseDirectoryPath;
  id userSettings;
}

+(PBProject *)parse:(NSString *)aPath;

// "system" configurations

-(NSString *)installRoot; /// the root of where to install finished products

-(NSString *)systemComponentRoot; // where resuable components go when installed
-(NSString *)systemFrameworkRoot; // where frameworkse go when installed
-(NSString *)systemHeaderDirectory; // where framework headers go on install
-(NSString *)systemSharedLibraryDirectory; // where shared libs go on install


-(NSString *)rootBuildDirectory;  // a temp place to use for builds

-(NSString *)cFlags;  // flags to pass to the compiler


// per project values
-(NSString *)projectName;
-(NSString *)outputDirectory;  // root of build output for this project
-(NSString *)compileTargetForSource:(NSString *)sourceFile;  // the .o for a .m
-(NSString *)projectType;
-(NSString *)componentPath;   // where the component is assembled
-(NSString *)executablePath;  // where the executable code is placed
-(NSString *)publicHeaderPath;
-(NSString *)projectHeaderPath;
-(NSString *)resourcePath;
-(NSString *)baseDirectoryPath;
- (NSString *)buildExtension;

// project cotents
-(NSDictionary *)filesTable;
-(NSArray *)classes;
-(NSArray *)subProjects;
-(NSArray *)subProjectNames;
-(NSArray *)linkables;


// this is all frameworks and libraries for a FINAL executable
- (NSArray *)executableLinkFlags;

// This is frameworks for non final links
- (NSArray *)frameworkLinkFlags;

-(NSArray *)cFlagArray;
-(NSDictionary *)subTaskEnvironment;
- (NSString *)systemExecutableDirectory;

@end
