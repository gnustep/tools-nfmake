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
enum {
  FC_NO_SRC=0,
  FC_NO_DEST,
  FC_SRC_NEWER,
  FC_DST_NEWER,
  FC_IDENTICAL
};

@interface NSFileManager(CompareFiles)
-(int)compareFile:(NSString *)sourceFile andFile:(NSString *)destFile;
-(void)makeRecursiveDirectory:(NSString *)thePath;
-(NSString *)newerFile:(NSString *)aFile :(NSString *)bFile;
-(BOOL)file:(NSString *)linkTarget isOlderThanFiles:(NSArray *)dependancies;




-(void)updateFiles:(NSArray *)fileList toDirectory:(NSString *)theDir;
-(void)updateFiles:(NSArray *)fileList toDirectory:(NSString *)theDir operationDelegate:opDelegate;

- (BOOL)shouldCopyFile:(NSString *)srcFile toDest:(NSString *)destFile;
- (void)copiedFile:(NSString *)srcFile toDest:(NSString *)destFile;

@end
