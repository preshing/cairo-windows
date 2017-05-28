This repository is meant to help create Cairo DLLs for Windows. Both 32-bit and 64-bit versions can be built. The resulting cairo.dll file is fully self-contained and does not depend on any other third-party DLLs. FreeType support is included.

# Build Steps

The `build-cairo-windows.sh` shell script will download, extract, and build all the necessary libraries to link a self-contained cairo.dll with FreeType support. It uses the existing build pipelines of each library as much as possible. It was adapted from https://www.cairographics.org/end_to_end_build_for_win32/

The Visual Studio 2017 compiler is used. Either MSYS, MSYS2 or Cygwin must be used to drive the build environment. So far it has only been tested with MSYS2. If using MSYS2, you'll need to install `tar` and `make` first:

    $ pacman -S tar make

## Building 32-bit

From the start menu, open "x86 Native Tools Command Prompt for VS 2017". Add the MSYS2 (for example) toolchain to the path. Start an MSYS2 shell (which inherits the `INCLUDE`, `LIB` and `PATH` variables from the first prompt), then run the script.

    (from an x86 Native Tools Command Prompt for VS 2017)
    > set PATH=C:\msys32\usr\bin;%PATH%
    > sh
    $ ./build-cairo-windows.sh

When it's done, you'll find a self-contained package in a subdirectory named output/cairo-windows-x.x.x.

## Building 64-bit

* First build 32-bit.
* Open libpng\projects\vstudio\vstudio.sln in Visual Studio, then add the "x64" platform to the solution as follows:
** Debug &rarr; Configuration Manager
** Active solution platform: &rarr; <New...>
** Select x64, click OK, close the Configuration Manager
** File &rarr; Save All
* Perform similar steps as for 32-bit, but open an "**x64** Native Tools Command Prompt for VS 2017" instead, and pass `x64` as an argument to the script:

    (from an x64 Native Tools Command Prompt for VS 2017)
    > set PATH=C:\msys32\usr\bin;%PATH%
    > sh
    $ ./build-cairo-windows.sh x64

Blah
