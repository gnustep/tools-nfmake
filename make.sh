#!/bin/csh


#
#  This is a tool that will build a NFOX project under linux.  The goal is to be able to edit and work on YellowBox/Windows
#  and be able to compile on Linux by just running nfmake instead of make. 
#
#  Zero work for the developer.

#
#  How to build without nfmake or make?
#
#  Also, this is the tool used to build the frameworks, so how to build without them?
#
#  Strategy is to build with nfmake if it is available, otherwise manually host


# Don't use the one in the current directory :-)
#if ( -x /usr/local/bin/nfmake) then
#/usr/local/bin/nfmake
#endif

if (! -d obj) then
mkdir obj
endif

foreach i (*.m)
 echo -n $i
 set bn=`basename $i .m`
 set target=obj/$bn.o
 if (! -f $target) goto build
 newer $target $i
 if ($?) goto build
 echo ""
 goto done
build:
 echo "  compile"
 cc -g -DGNU_RUNTIME -c -o $target -Wno-import -I. -I/usr/GNUstep/Headers/gnustep/ -I/usr/GNUstep/Headers/ix86/linux-gnu/ $i 
done:
end

cc -g -o nfmake_boot obj/*.o -L/usr/GNUstep/Libraries/machine/ -lgnustep-base -lobjc -lpthread

