This repository is meant to help create Cairo DLLs for Windows. Both 32-bit and 64-bit versions can be built. The resulting `cairo.dll` file is fully self-contained and does not depend on any other third-party DLLs. FreeType support is included. See [this blog post](http://preshing.com/20170529/heres-a-standalone-cairo-dll-for-windows) for more information.

Binary releases are available [here](https://github.com/preshing/cairo-windows/releases).

# Build Steps

The `build-cairo-windows.sh` shell script will download, extract, and build all the necessary libraries to link a self-contained `cairo.dll` with FreeType support. It uses the existing build pipelines of each library as much as possible. It was adapted from https://www.cairographics.org/end_to_end_build_for_win32/

The Visual Studio 2017 compiler is used. Either MSYS, MSYS2 or Cygwin must be used to drive the build environment. So far it has only been tested with MSYS2. If using MSYS2, you'll need to install `tar` and `make` first:

    $ pacman -S tar make

## Building 32-bit

You'll need to create an MSYS2 (for example) shell that has all the correct environment variables set for Visual Studio 2017, including `INCLUDE`, `LIB` and `PATH`.

As of this writing, this can be achieved by opening "x86 Native Tools Command Prompt for VS 2017" from the start menu, and entering commands similar to the following. The final command runs the `build-cairo-windows.sh` script.

```
(from an x86 Native Tools Command Prompt for VS 2017)
> set PATH=C:\msys64;%PATH%
> msys2_shell.cmd -use-full-path
$ unset TMP
$ unset TEMP
$ ./build-cairo-windows.sh
```

Some notes:

* `msys2_shell.cmd -use-full-path` opens an MSYS2 terminal while [inheriting the PATH](https://sourceforge.net/p/msys2/discussion/general/thread/dbe17030/#3f85) from the x86 Native Tools Command Prompt.
* `unset TMP` and `unset TEMP` are currently needed to avoid `error MSB6001: Invalid command line switch for "CL.exe". Item has already been added. Key in dictionary: 'TMP' Key being added: 'tmp'`, which is caused by the MSYS2 environment block [having multiple `TMP` entries due to case sensitivty](https://cmake.org/Bug/print_bug_page.php?bug_id=13131).

When it's done, you'll find a self-contained package in a subdirectory named `output/cairo-windows-x.x.x`.

## Building 64-bit

1. First build 32-bit.
2. Open `libpng\projects\vstudio\vstudio.sln` in Visual Studio, then add the "x64" platform to the solution as follows:
   * Build &rarr; Configuration Manager
   * Active solution platform: &rarr; <New...>
   * Select x64, click OK, close the Configuration Manager
   * File &rarr; Save All
3. Perform similar steps as for 32-bit, but open an "**x64** Native Tools Command Prompt for VS 2017" instead, and pass `x64` as an argument to the script:

```
(from an x64 Native Tools Command Prompt for VS 2017)
> set PATH=C:\msys64;%PATH%
> msys2_shell.cmd -use-full-path
$ unset TMP
$ unset TEMP
$ ./build-cairo-windows.sh x64
```
