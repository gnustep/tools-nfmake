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

// For creating a new PBProject subclass instance
+ (PBProject *)parse:(NSString *)aPath;

// when we spawn sub tasks, we need to set up their environment
-(NSDictionary *)subTaskEnvironment;

// general build configurations
- (NSString *)rootBuildDirectory;  // a temp place to use for builds usually ~/spool
- (NSString *)buildHeaderDirectory; // where framework headers go on default built
- (NSString *)buildLibraryDirectory; // where framework .so files go on built
- (NSString *)buildFrameworkDirectory; // where frameworkse go on default built
- (NSString *)buildComponentDirectory; // where resuable components go when built
- (NSString *)buildWebObjectsDirectory; // where WebObjects Applications go when built

// Subprojects
- (NSArray *)subProjects;      // List of PBProject instances for each direct subproject
- (NSArray *)subProjectNames;  // list of directory names for each direct subproject

// General Project information
- (NSString *)projectName;
- (NSString *)buildExtension;
- (NSDictionary *)filesTable;
- (NSString *)projectType;
- (NSString *)baseDirectoryPath;  // The initial directory that they PB.project was in

// Building
- (NSString *)outputDirectory;  // root of build output for this project
- (NSString *)compileTargetForSource:(NSString *)sourceFile;  // the .o for a given .m
- (NSArray *)classes;
- (NSArray *)linkables;
- (NSString *)cFlags;  // flags to pass to the compiler
- (NSString *)publicHeaderPath;    // where to copy this projects "public  headers"
- (NSString *)projectHeaderPath;   // where to copy this projects "project headers"
- (NSString *)componentPath;   // where the component is assembled
- (NSString *)resourcePath;
- (NSArray *)cFlagArray;
- (NSArray *)headerDirectoryFlags;  // -I flags

// Linking
- (NSArray *)executableLinkFlags; // this is all frameworks and libraries for a FINAL executable
- (NSString *)executablePath;  // where the executable code is placed
- (NSArray *)frameworkLinkFlags;   // -l flags
- (NSArray *)libraryDirectoryFlags;  // -L flags


// Installing
- (NSString *)installRoot; /// the root of where to install finished products if none is speced
- (NSString *)installDirectory;


@end
