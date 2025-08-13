# Zenoh RMW

https://github.com/ros2/rmw_zenoh, branch 'jazzy'

## Prerequisites

Zenoh is written in Rust, so the easiest solution (besides doing work in Zig-land to download and
install a Rust toolchain and such) is to download the prebuilt library from Github:
<https://github.com/eclipse-zenoh/zenoh-c/releases>

There's still work to do to setup ZigROS to link this as a system library (and include the zenoh-c
and zenoh-cpp headers) reliably without hard-coded paths.

You can also download a prebuilt zenohd executable from:
<https://zenoh.io/docs/getting-started/installation/>

## Debugging Notes

- You MUST set `AMENT_PREFIX_PATH` and have the Zenoh config JSON files installed to run any
  binaries using Zenoh.
- If you don't have the path set properly (or the config file is not found), ROS will throw a
  `std::bad_alloc` exception (super unhelpful; it's not actually an allocation issue, it's from a
  file-not-found error in `ament_index_cpp`).
- Next problem is that the typesupport libraries are not setup properly...
  ```
  libc++abi: terminating due to uncaught exception of type rclcpp::exceptions::RCLError: failed to initialize rosout publisher: Type support not from this implementation. Got:
  error not set
  error not set
  ```
  - This comes back to the same error that FastDDS is having, but _hopefully_ with a simpler
    solution (hopefully only 1 typesupport library is necessary, like with CycloneDDS; otherwise,
    `dlopen` will need to be used to switch between libraries).

### "Type support not from this implementation" error

**Trace:**

- Repo: rmw_zenoh
  - rmw_zenoh.cpp, line 77, function `find_message_type_support()`
    - Function that finds the typesupport for a `.msg` struct
    - The service (`.srv`) version is at line 104
  - Failing call:
    ```cpp
    type_support = get_message_typesupport_handle(type_supports, RMW_ZENOH_CPP_TYPESUPPORT_CPP);
    ```
- Repo: rosidl, package: rosidl_runtime_c
  - File: `rosidl_runtime_c/src/message_type_support.c`
  - Function:
    ```cpp
    const rosidl_message_type_support_t * get_message_typesupport_handle(
      const rosidl_message_type_support_t * handle, const char * identifier)
    {
      assert(handle);
      assert(handle->func);
      rosidl_message_typesupport_handle_function func =
        (rosidl_message_typesupport_handle_function)(handle->func);
      return func(handle, identifier);
    }
    ```
  - Uses the `func` field of the `handle` (which came from `type_supports` at the rmw_zenoh layer)
    to get the `rosidl_message_typesupport_handle_function`
    - `func` points to `get_message_typesupport_handle_function()`
- Repo: rosidl_typesupport
  - File: type_support_dispatch.hpp, function: get_typesupport_handle_function()
    ```cpp
    template <typename TypeSupport>
    const TypeSupport *get_typesupport_handle_function(
        const TypeSupport *handle, const char *identifier) noexcept
    {
      if (strcmp(handle->typesupport_identifier, identifier) == 0) {
        return handle;
      }
      ...
    ```
  - (Called by some basic C++ wrapper code; shared between 'message', 'service', and 'action' type
    supports)
  - it's this function that calls `lib = new rcpputils::SharedLibrary(library_name);` (which uses
    `dlopen`) if the first typesupport provided doesn't match:
