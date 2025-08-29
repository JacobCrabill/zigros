# Zenoh RMW

https://github.com/ros2/rmw_zenoh, branch 'jazzy'

## Prerequisites

Zenoh is written in Rust, so the easiest solution (besides doing work in Zig-land to download and
install a Rust toolchain and such) is to download the prebuilt library from Github:
<https://github.com/eclipse-zenoh/zenoh-c/releases>

There's still work to do to setup ZigROS to link this as a system library (and include the zenoh-c
and zenoh-cpp headers) reliably without hard-coded paths. For now, use the build options
`-Dzenohc_library_path` and `-Dzenohc_include_path` to specify the installation location for your
target.

You can also download a prebuilt zenohd executable from:
<https://zenoh.io/docs/getting-started/installation/>, but we build it here as well.

## Debugging Notes

You MUST set `AMENT_PREFIX_PATH` and have the Zenoh config JSON files installed to run any binaries
using Zenoh.

If you don't have the path set properly (or the config file is not found), ROS will throw a
`std::bad_alloc` exception (super unhelpful; it's not actually an allocation issue, it's from a
file-not-found error in `ament_index_cpp`).

## Building zenohc

I can't get this to work; just download the prebuilt library from the zenoh-c Github
[releases page](http://github.com/eclipse-zenoh/zenoh-c/releases) and install to
`/usr/lib/{x86_64,aarch64}-linux-musl` and `/usr/include/{x86_64,aarch64}-linux-musl/`.

```bash
rustup target add aarch64-unknown-linux-musl
cd <zenoh-c dir>
mkdir build-aarch64 && cmake build-aarch64
export CARGO_BUILD_TARGET=aarch64-unkonwn-linux-musl
export RUSTFLAGS="-Clinker=zig-cc -Car=zig-ar"
cmake .. -DZENOHC_CUSTOM_TARGET=aarch64-unknown-linux-musl -DCMAKE_C_COMPILER=zig-cc -DCMAKE_CXX_COMPILER=zig-cxx
make -j
```
