Library for the Signal Private Group System.

Work in progress.  Subject to change without notice, use outside Signal not yet recommended.

Overview
========

This library provides zero-knowledge group functionality through several layers of APIs.  From lower-level to higher-level:

* `internal.rs` provides the actual Rust implementations, based on Rust structures.

* `simpleapi.rs` provides wrapper functions around internal.rs functions that use `serde` to serialize/deseralize byte arrays into Rust structures.

* `ffiapi.rs` and `ffiapijava.rs` provide wrapper functions around `simpleapi.rs` functions to export them via C and JNI, respectively.

* The subdirectories under `ffi` contain code in various host languages for accessing the exported functions:

    * Under `c` is a `zkgroup.h` header file.

    * Under `android` is a `ZKGroup.java` file and instructions for building an aar.

    * Under `node` is some example code for declaring the FFI functions in javascript.

Setup
=====

The rust-toolchain.toml file should get things automatically setup for you
provided you are using rustup. See it for the toolchain and channel and targets
in use for this build.

Building Rust
=============

Run `./gradlew tasks` and see `make` tasks under the "Rust tasks" group.
