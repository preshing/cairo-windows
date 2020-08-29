#! bash
set -e
trap 'previous_command=$this_command; this_command=$BASH_COMMAND' DEBUG
trap 'echo FAILED COMMAND: $previous_command' EXIT

# Versions used
USE_FREETYPE=1
CAIRO_VERSION=cairo-1.17.2
PIXMAN_VERSION=pixman-0.40.0
LIBPNG_VERSION=libpng-1.6.37
ZLIB_VERSION=zlib-1.2.11
FREETYPE_VERSION=freetype-2.10.2

# Set variables according to command line argument
if [ ${1:-x86} = x64 ]; then
    MSVC_PLATFORM_NAME=x64
    OUTPUT_PLATFORM_NAME=x64
else
    MSVC_PLATFORM_NAME=Win32
    OUTPUT_PLATFORM_NAME=x86
fi

# Make sure the MSVC linker appears first in the path
MSVC_LINK_PATH=`whereis link | sed "s| /usr/bin/link.exe||" | sed "s|.*\(/c.*\)link.exe.*|\1|"`
export PATH="$MSVC_LINK_PATH:$PATH"

# Download packages if not already
wget -nc https://www.cairographics.org/snapshots/$CAIRO_VERSION.tar.xz
wget -nc https://www.cairographics.org/releases/$PIXMAN_VERSION.tar.gz
wget -nc https://download.sourceforge.net/libpng/$LIBPNG_VERSION.tar.gz
wget -nc http://www.zlib.net/$ZLIB_VERSION.tar.gz
if [ $USE_FREETYPE -ne 0 ]; then
    wget -nc http://download.savannah.gnu.org/releases/freetype/$FREETYPE_VERSION.tar.gz
fi    

# Extract packages if not already
if [ ! -d cairo ]; then
    echo "Extracting $CAIRO_VERSION..."
    tar -xJf $CAIRO_VERSION.tar.xz
    mv $CAIRO_VERSION cairo
fi
if [ ! -d pixman ]; then
    echo "Extracting $PIXMAN_VERSION..."
    tar -xzf $PIXMAN_VERSION.tar.gz
    mv $PIXMAN_VERSION pixman
fi
if [ ! -d libpng ]; then
    echo "Extracting $LIBPNG_VERSION..."
    tar -xzf $LIBPNG_VERSION.tar.gz
    mv $LIBPNG_VERSION libpng
fi
if [ ! -d zlib ]; then
    echo "Extracting $ZLIB_VERSION..."
    tar -xzf $ZLIB_VERSION.tar.gz
    mv $ZLIB_VERSION zlib
fi
if [ $USE_FREETYPE -ne 0 ] && [ ! -d freetype ]; then
    echo "Extracting $FREETYPE_VERSION..."
    tar -xzf $FREETYPE_VERSION.tar.gz
    mv $FREETYPE_VERSION freetype
fi

# Build libpng and zlib
cd libpng
sed 's#4996</Disable#4996;5045</Disable#' projects/vstudio/zlib.props > zlib.props.fixed
mv zlib.props.fixed projects/vstudio/zlib.props
if [ ! -d "projects\vstudio\Backup" ]; then
    # Upgrade solution if not already
    devenv.com "projects\vstudio\vstudio.sln" -upgrade
fi
devenv.com "projects\vstudio\vstudio.sln" -build "Release Library|$MSVC_PLATFORM_NAME" -project libpng
cd ..
if [ $MSVC_PLATFORM_NAME = x64 ]; then
    cp "libpng/projects/vstudio/x64/Release Library/libpng16.lib" libpng/libpng.lib
    cp "libpng/projects/vstudio/x64/Release Library/zlib.lib" zlib/zlib.lib
else
    cp "libpng/projects/vstudio/Release Library/libpng16.lib" libpng/libpng.lib
    cp "libpng/projects/vstudio/Release Library/zlib.lib" zlib/zlib.lib
fi

# Build pixman
cd pixman
sed s/-MD/-MT/ Makefile.win32.common > Makefile.win32.common.fixed
mv Makefile.win32.common.fixed Makefile.win32.common
if [ $MSVC_PLATFORM_NAME = x64 ]; then
    # pass -B for switching between x86/x64
    make pixman -B -f Makefile.win32 "CFG=release" "MMX=off"
else
    make pixman -B -f Makefile.win32 "CFG=release"
fi
cd ..

if [ $USE_FREETYPE -ne 0 ]; then
    cd freetype
    # Build freetype
    if [ ! -d "builds/windows/vc2010/Backup" ]; then
        # Upgrade solution if not already
        devenv.com "builds/windows/vc2010/freetype.sln" -upgrade
    fi
    devenv.com "builds/windows/vc2010/freetype.sln" -build "Release Static|$MSVC_PLATFORM_NAME"
    cp "`ls -1d "objs/$MSVC_PLATFORM_NAME/Release Static/freetype.lib"`" .
    cd ..
fi

# Build cairo
cd cairo
sed 's/-MD/-MT/;s/zdll.lib/zlib.lib/' build/Makefile.win32.common > Makefile.win32.common.fixed
mv Makefile.win32.common.fixed build/Makefile.win32.common
if [ $USE_FREETYPE -ne 0 ]; then
    sed '/^CAIRO_LIBS =/s/$/ $(top_builddir)\/..\/freetype\/freetype.lib/;/^DEFAULT_CFLAGS =/s/$/ -I$(top_srcdir)\/..\/freetype\/include/' build/Makefile.win32.common > Makefile.win32.common.fixed
else
    sed '/^CAIRO_LIBS =/s/ $(top_builddir)\/..\/freetype\/freetype.lib//;/^DEFAULT_CFLAGS =/s/ -I$(top_srcdir)\/..\/freetype\/include//' build/Makefile.win32.common > Makefile.win32.common.fixed
fi
mv Makefile.win32.common.fixed build/Makefile.win32.common
sed "s/CAIRO_HAS_FT_FONT=./CAIRO_HAS_FT_FONT=$USE_FREETYPE/;s/CAIRO_HAS_TEE_SURFACE=./CAIRO_HAS_TEE_SURFACE=1/" build/Makefile.win32.features > Makefile.win32.features.fixed
mv Makefile.win32.features.fixed build/Makefile.win32.features
# pass -B for switching between x86/x64
make -B -f Makefile.win32 cairo "CFG=release"
cd ..

# Package headers with DLL
OUTPUT_FOLDER=output/${CAIRO_VERSION/cairo-/cairo-windows-}
mkdir -p $OUTPUT_FOLDER/include
for file in cairo/cairo-version.h \
            cairo/src/cairo-features.h \
            cairo/src/cairo.h \
            cairo/src/cairo-deprecated.h \
            cairo/src/cairo-win32.h \
            cairo/src/cairo-script.h \
            cairo/src/cairo-ps.h \
            cairo/src/cairo-pdf.h \
            cairo/src/cairo-svg.h \
            cairo/src/cairo-tee.h; do
    cp $file $OUTPUT_FOLDER/include
done
if [ $USE_FREETYPE -ne 0 ]; then
    cp cairo/src/cairo-ft.h $OUTPUT_FOLDER/include
fi
mkdir -p $OUTPUT_FOLDER/lib/$OUTPUT_PLATFORM_NAME
cp cairo/src/release/cairo.lib $OUTPUT_FOLDER/lib/$OUTPUT_PLATFORM_NAME
cp cairo/src/release/cairo.dll $OUTPUT_FOLDER/lib/$OUTPUT_PLATFORM_NAME
cp cairo/COPYING* $OUTPUT_FOLDER

trap - EXIT
echo 'Success!'
