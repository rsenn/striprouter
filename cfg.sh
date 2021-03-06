cfg() {
  if type gcc 2>/dev/null >/dev/null && type g++ 2>/dev/null >/dev/null; then
    : ${CC:=gcc} ${CXX:=g++}
  elif type clang 2>/dev/null >/dev/null && type clang++ 2>/dev/null >/dev/null; then
    : ${CC:=clang} ${CXX:=clang++}
  fi

  : ${build:=`$CC -dumpmachine | sed 's|-pc-|-|g'`}

  if [ -z "$host" -a -z "$builddir" ]; then
    host=$build
    case "$host" in
      x86_64-w64-mingw32) host="$host" builddir=build/$host prefix=/mingw64 ;;
      i686-w64-mingw32) host="$host" builddir=build/$host prefix=/mingw32 ;;
      x86_64-pc-*) host="$host" builddir=build/${host} prefix=/usr ;;
      i686-pc-*) host="$host" builddir=build/${host} prefix=/usr ;;
    esac
  fi
  : ${prefix:=/usr/local}
  : ${libdir:=$prefix/lib}
  [ -d "$libdir/$host" ] && libdir=$libdir/$host

  if [ -e "$TOOLCHAIN" ]; then
    cmakebuild=$(basename "$TOOLCHAIN" .cmake)
    cmakebuild=${cmakebuild%.toolchain}
    cmakebuild=${cmakebuild#toolchain-}
    : ${builddir=build/$cmakebuild}
  else
   : ${builddir=build/$host}
  fi
  test -n "$builddir" && builddir=`echo $builddir | sed 's|-pc-|-|g'`

  case $(uname -o) in
   # MSys|MSYS|Msys) SYSTEM="MSYS" ;;
    *) SYSTEM="Unix" ;;
  esac

  case "$STATIC:$TYPE" in
    YES:*|yes:*|y:*|1:*|ON:*|on:* | *:*[Ss]tatic*) set -- "$@" \
      -DBUILD_SHARED_LIBS=OFF \
      -DENABLE_PIC=OFF ;;
  esac

  : ${generator:="Unix Makefiles"}

 (mkdir -p $builddir
  : ${relsrcdir=`realpath --relative-to "$builddir" .`}
  set -x
  cd "${builddir:-.}"
  ${CMAKE:-cmake} -Wno-dev \
    -G "$generator" \
    ${VERBOSE:+-DCMAKE_VERBOSE_MAKEFILE=TRUE} \
    -DCMAKE_BUILD_TYPE="${TYPE:-Debug}" \
    -DBUILD_SHARED_LIBS=ON \
    ${CC:+-DCMAKE_C_COMPILER="$CC"} \
    ${CXX:+-DCMAKE_CXX_COMPILER="$CXX"} \
    ${PKG_CONFIG:+-DPKG_CONFIG_EXECUTABLE="$PKG_CONFIG"} \
    ${TOOLCHAIN:+-DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN"} \
    ${CC:+-DCMAKE_C_COMPILER="$CC"} \
    ${CXX:+-DCMAKE_CXX_COMPILER="$CXX"} \
    ${MAKE:+-DCMAKE_MAKE_PROGRAM="$MAKE"} \
    "$@" \
    $relsrcdir 2>&1 ) |tee "${builddir##*/}.log"
}

cfg-android ()
{
  (: ${builddir=build/android}
    cfg \
  -DCMAKE_INSTALL_PREFIX=/opt/arm-linux-androideabi/sysroot/usr \
  -DCMAKE_VERBOSE_MAKEFILE=TRUE \
  -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN:-/opt/android-cmake/android.cmake} \
  -DANDROID_NATIVE_API_LEVEL=21 \
  -DPKG_CONFIG_EXECUTABLE=arm-linux-androideabi-pkg-config \
  -DCMAKE_PREFIX_PATH=/opt/arm-linux-androideabi/sysroot/usr \
  -DCMAKE_MAKE_PROGRAM=/usr/bin/make \
   -DCMAKE_MODULE_PATH="/opt/OpenCV-3.4.1-android-sdk/sdk/native/jni/abi-armeabi-v7a" \
   -DOpenCV_DIR="/opt/OpenCV-3.4.1-android-sdk/sdk/native/jni/abi-armeabi-v7a" \
   "$@"
    )
}

cfg-diet() {
 (: ${build=$(${CC:-gcc} -dumpmachine | sed 's|-pc-|-|g')}
  : ${host=${build/-gnu/-diet}}
  : ${prefix=/opt/diet}
  : ${libdir=/opt/diet/lib-${host%%-*}}
  : ${bindir=/opt/diet/bin-${host%%-*}}

  : ${CC="diet-gcc"}
  export CC

  if type pkgconf >/dev/null; then
    export PKG_CONFIG=pkgconf
  fi

  : ${PKG_CONFIG_PATH="$libdir/pkgconfig"}; export PKG_CONFIG_PATH
  
  builddir=build/${host%-*}-diet \
  cfg \
    -DCMAKE_INSTALL_PREFIX="$prefix" \
    -DENABLE_SHARED=OFF \
    -DENABLE_STATIC=ON \
    -DSHARED_LIBS=OFF \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DCMAKE_FIND_ROOT_PATH="$prefix" \
    -DCMAKE_SYSTEM_LIBRARY_PATH="$prefix/lib-${host%%-*}" \
    -D{CMAKE_INSTALL_LIBDIR=,INSTALL_LIB_DIR=$prefix/}"lib-${host%%-*}" \
      ${launcher:+-DCMAKE_C_COMPILER_LAUNCHER="$launcher"} \
    "$@")
}

cfg-diet64() {
 (build=$(gcc -dumpmachine | sed 's|-pc-|-|g')
  host=${build%%-*}-linux-diet
  host=x86_64-${host#*-}

  export prefix=/opt/diet

  builddir=build/$host \
  CC="diet-gcc" \
  cfg-diet \
  "$@")
}

cfg-diet32() {
 (build=$(gcc -dumpmachine | sed 's|-pc-|-|g')
  host=${build%%-*}-linux-diet
  host=i686-${host#*-}
  
  if type diet32-clang 2>/dev/null >/dev/null; then
    CC="diet32-clang"
    export CC
  elif type diet32-gcc 2>/dev/null >/dev/null; then
    CC="diet32-gcc"
    export CC
  else
    CC="gcc"
    launcher="/opt/diet/bin-i386/diet"
    CFLAGS="-m32"
    export CC launcher CFLAGS
  fi

  builddir=build/$host \
  cfg-diet  "$@")
}

cfg-mingw() {
 (build=$(gcc -dumpmachine | sed 's|-pc-|-|g')
  : ${host=${build%%-*}-w64-mingw32}
  : ${prefix=/usr/$host/sys-root/mingw}

  test -s /usr/x86_64-w64-mingw32/sys-root/toolchain-mingw64.cmake &&
  TOOLCHAIN=/usr/x86_64-w64-mingw32/sys-root/toolchain-mingw64.cmake

  builddir=build/$host \
  bindir=$prefix/bin \
  libdir=$prefix/lib \
  cfg \
    "$@")
}
cfg-emscripten() {
 (build=$(${CC:-emcc} -dumpmachine | sed 's|-pc-|-|g')
  host=${build/-gnu/-emscriptenlibc}
  builddir=build/${host%-*}-emscripten
  
  prefix=`which emcc | sed 's|/emcc$|/system|'` 
  libdir=$prefix/lib
  bindir=$prefix/bin

  CC="emcc" \
  PKG_CONFIG="PKG_CONFIG_PATH=$libdir/pkgconfig pkg-config" \
  cfg \
    -DCMAKE_INSTALL_PREFIX="$prefix" \
    -DENABLE_SHARED=OFF \
    -DENABLE_STATIC=ON \
    -DSHARED_LIBS=OFF \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    "$@")
}

cfg-tcc() {
 (build=$(cc -dumpmachine | sed 's|-pc-|-|g')
  host=${build/-gnu/-tcc}
  builddir=build/$host
  prefix=/usr
  includedir=/usr/lib/$build/tcc/include
  libdir=/usr/lib/$build/tcc/
  bindir=/usr/bin

  CC=${TCC:-tcc} \
  cfg \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    "$@")
}

cfg-musl() {
 (: ${build=$(${CC:-gcc} -dumpmachine | sed 's|-pc-|-|g')}
  : ${host=${build%-*}-musl}

 : ${prefix=/usr}
 : ${includedir=/usr/include/$host}
 : ${libdir=/usr/lib/$host}
 : ${bindir=/usr/bin/$host}

  builddir=build/$host \
  CC=musl-gcc \
  PKG_CONFIG=musl-pkg-config \
  cfg \
    -DENABLE_SHARED=OFF \
    -DENABLE_STATIC=ON \
    -DSHARED_LIBS=OFF \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    "$@")
}


cfg-musl64() {
 (build=$(gcc -dumpmachine | sed 's|-pc-|-|g')
  host=${build%%-*}-linux-musl
  host=x86_64-${host#*-}

  builddir=build/$host \
  CFLAGS="-m64" \
  cfg-musl \
  -DCMAKE_C_COMPILER="musl-gcc" \
  "$@")
}

cfg-musl32() {
 (build=$(gcc -dumpmachine | sed 's|-pc-|-|g')
  host=$(echo "$build" | sed "s|x86_64|i686| ; s|-gnu|-musl|")

  builddir=build/$host \
  CFLAGS="-m32" \
  cfg-musl \
  -DCMAKE_C_COMPILER="musl-gcc" \
  "$@")
}

cfg-msys() {
 (build=$(gcc -dumpmachine | sed 's|-pc-|-|g')
  : ${host=${build%%-*}-pc-msys}
  : ${prefix=/usr/$host/sys-root/msys}

  builddir=build/$host \
  bindir=$prefix/bin \
  libdir=$prefix/lib \
  CC="$host-gcc" \
  cfg \
    -DCMAKE_CROSSCOMPILING=TRUE \
    "$@")
}

cfg-msys32() {
 (build=$(gcc -dumpmachine | sed 's|-pc-|-|g')
  host=${build%%-*}-pc-msys
  host=i686-${host#*-}
  cfg-msys "$@")
}

cfg-rpi4()
{
  (builddir=build/rpi4
  : ${host=aarch64-linux-gnu}
  : ${build=aarch64-linux-gnu}
  : ${CC=aarch64-linux-gnu-gcc}
  : ${CXX=aarch64-linux-gnu-g++}
  
  prefix=/usr/aarch64-linux-gnu/sysroot/usr
    cfg \
  -DCMAKE_INSTALL_PREFIX=$prefix \
  -DCMAKE_VERBOSE_MAKEFILE=TRUE \
  -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN:-/opt/cmake-toolchains/aarch64-linux-gnu.toolchain.cmake} \
  -DANDROID_NATIVE_API_LEVEL=21 \
  -DPKG_CONFIG_EXECUTABLE=/usr/bin/aarch64-linux-gnu-pkg-config \
  -DCMAKE_PREFIX_PATH=$prefix \
  -DCMAKE_SYSROOT=${prefix%/usr} \
  -DCMAKE_MAKE_PROGRAM=/usr/bin/make \
   -DCMAKE_MODULE_PATH="$prefix/lib/cmake" \
   "$@"
    )
}
cfg-termux()
{
  (builddir=build/rpi4
    cfg \
  -DCMAKE_INSTALL_PREFIX=/data/data/com.termux/files/usr \
  -DCMAKE_VERBOSE_MAKEFILE=TRUE \
  -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN:-/opt/android-cmake/android.cmake} \
  -DANDROID_NATIVE_API_LEVEL=21 \
  -DPKG_CONFIG_EXECUTABLE=arm-linux-androideabi-pkg-config \
  -DCMAKE_PREFIX_PATH=/data/data/com.termux/files/usr \
  -DCMAKE_MAKE_PROGRAM=/usr/bin/make \
   -DCMAKE_MODULE_PATH="/data/data/com.termux/files/usr/lib/cmake" \
   "$@"
    )
}
cfg-wasm() {
  export VERBOSE
 (EMCC=$(which emcc)
  EMSCRIPTEN=$(dirname "$EMCC");
  EMSCRIPTEN=${EMSCRIPTEN%%/bin*};
  test -f /opt/cmake-toolchains/generic/Emscripten-wasm.cmake && TOOLCHAIN=/opt/cmake-toolchains/generic/Emscripten-wasm.cmake
  test '!' -f "$TOOLCHAIN" && TOOLCHAIN=$(find "$EMSCRIPTEN" -iname emscripten.cmake);
  test -f "$TOOLCHAIN" || unset TOOLCHAIN;
  : ${prefix:="$EMSCRIPTEN"}
  builddir=build/emscripten-wasm \
  CC="$EMCC" \
  cfg \
    -DEMSCRIPTEN_PREFIX="$EMSCRIPTEN" \
    ${TOOLCHAIN:+-DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN"} \
    -DCMAKE_EXE_LINKER_FLAGS="-s WASM=1" \
    -DCMAKE_EXECUTABLE_SUFFIX=".html" \
    -DCMAKE_EXECUTABLE_SUFFIX_INIT=".html" \
    -DUSE_{ZLIB,BZIP,LZMA,SSL}=OFF \
  "$@")
}

cfg-msys32() {
 (build=$(gcc -dumpmachine | sed 's|-pc-|-|g')
  host=${build%%-*}-pc-msys
  host=i686-${host#*-}
  cfg-msys "$@")
}

cfg-msys() {
 (build=$(gcc -dumpmachine | sed 's|-pc-|-|g')
  : ${host=${build%%-*}-pc-msys}
  : ${prefix=/usr/$host/sys-root/msys}

  builddir=build/$host \
  bindir=$prefix/bin \
  libdir=$prefix/lib \
  
  CC="$host-gcc" \
  cfg \
    -DCMAKE_CROSSCOMPILING=TRUE \
    "$@")
}

cfg-tcc() {
 (build=$(cc -dumpmachine | sed 's|-pc-|-|g')
  host=${build/-gnu/-tcc}
  builddir=build/$host
  prefix=/usr
  includedir=/usr/lib/$build/tcc/include
  libdir=/usr/lib/$build/tcc/
  bindir=/usr/bin

  CC=${TCC:-tcc} \
  cfg \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    "$@")
}
  
