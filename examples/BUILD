package(default_visibility = ["//visibility:public"])

licenses(["notice"])

# Targets that are built for CI
#
# When building/testing, bazel will find all targets matching a pattern like
# "//examples/..." and try to build them (even when doing a test), but
# trying to build objc_libraries like that fails because they really rely on
# getting their sdk propagated from the apple_binary they depend on. These
# targets provide specific things to build to avoid those errors.

filegroup(
    name = "ci_build_targets",
    srcs = [
        "//examples/ios/HelloWorld",
        "//examples/ios/HelloWorldSwift",
        "//examples/ios/PrenotCalculator",
        "//examples/ios/StickersApp",
        "//examples/ios/iMessageApp",
        "//examples/macos/CommandLine",
        "//examples/macos/CommandLineSwift",
        "//examples/macos/HelloToday",
        "//examples/macos/HelloWorld",
        "//examples/macos/HelloWorldSwift",
        "//examples/macos/XPCServiceApp",
        "//examples/multi_platform/Buttons",
        "//examples/multi_platform/Buttons:ButtonsMac",
        "//examples/multi_platform/Buttons:ButtonsTV",
        "//examples/multi_platform/Buttons:ButtonsWatch",
        "//examples/tvos/HelloWorld",
        "//examples/watchos/HelloWorld",
        "//examples/watchos/HelloWorld:HelloWorld-WatchApplication",
    ],
)
