#   GNUmakefile: makefile for GNUstep nfmake
#
#   Copyright (C) 2004 Free Software Foundation, Inc.
#
#   Author: Fred Kiefer <fredkiefer@gmx.de>
#   Date: 2004
#   
#   This file is part of GNUstep.
#   
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#   
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#   
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

include $(GNUSTEP_MAKEFILES)/common.make

OBJCFLAGS += -Wall

TOOL_NAME = nfmake

nfmake_OBJC_FILES = \
            FrameworkStyle.m \
            MakeStyle.m \
            NSObject_ClassTree.m \
            ToolStyle.m \
            PalmApplication.m \
            WebObjects.m \
            WebObjectsSubproject.m \
            NSFileManager_CompareFiles.m \
            PBProject.m \
            ProjectCopyDelegate.m \
            ComponentStyle.m \
            BundleStyle.m \
            ApplicationStyle.m \
            DocumentApplication.m \
            NFOXComponentStyle.m \
	    nfmake_main.m

nfmake_HEADER_FILES = \
	    FrameworkStyle.h \
            MakeStyle.h \
            NSObject.h \
            ToolStyle.h \
            PalmApplication.h \
            NSFileManager_CompareFiles.h \
            PBProject.h \
            ComponentStyle.h \
            BundleStyle.h \
            ApplicationStyle.h \
            DocumentApplication.h \
            NFOXComponentStyle.h

-include GNUmakefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/tool.make

-include GNUmakefile.postamble

