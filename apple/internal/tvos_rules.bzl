# Copyright 2018 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Experimental implementation of tvOS rules."""

load(
    "@build_bazel_rules_apple//apple/bundling:platform_support.bzl",
    "platform_support",
)
load(
    "@build_bazel_rules_apple//apple/bundling:run_actions.bzl",
    "run_actions",
)
load(
    "@build_bazel_rules_apple//apple/internal:apple_product_type.bzl",
    "apple_product_type",
)
load(
    "@build_bazel_rules_apple//apple/internal:outputs.bzl",
    "outputs",
)
load(
    "@build_bazel_rules_apple//apple/internal:partials.bzl",
    "partials",
)
load(
    "@build_bazel_rules_apple//apple/internal:processor.bzl",
    "processor",
)
load(
    "@build_bazel_rules_apple//apple/internal:rule_factory.bzl",
    "rule_factory",
)
load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "TvosApplicationBundleInfo",
    "TvosExtensionBundleInfo",
)

def _tvos_application_impl(ctx):
    """Experimental implementation of tvos_application."""

    top_level_attrs = [
        "app_icons",
        "launch_images",
        "strings",
    ]

    binary_provider_struct = apple_common.link_multi_arch_binary(ctx = ctx)
    binary_provider = binary_provider_struct.binary_provider
    debug_outputs_provider = binary_provider_struct.debug_outputs_provider
    binary_artifact = binary_provider.binary

    bundle_id = ctx.attr.bundle_id

    embeddable_targets = ctx.attr.extensions
    swift_dylib_dependencies = ctx.attr.extensions

    processor_partials = [
        partials.app_assets_validation_partial(
            app_icons = ctx.files.app_icons,
            launch_images = ctx.files.launch_images,
        ),
        partials.apple_bundle_info_partial(bundle_id = bundle_id),
        partials.binary_partial(binary_artifact = binary_artifact),
        partials.bitcode_symbols_partial(
            binary_artifact = binary_artifact,
            debug_outputs_provider = debug_outputs_provider,
            dependency_targets = ctx.attr.extensions,
            package_bitcode = True,
        ),
        partials.clang_rt_dylibs_partial(binary_artifact = binary_artifact),
        partials.debug_symbols_partial(
            debug_dependencies = ctx.attr.extensions,
            debug_outputs_provider = debug_outputs_provider,
        ),
        partials.embedded_bundles_partial(
            bundle_embedded_bundles = True,
            embeddable_targets = embeddable_targets,
        ),
        partials.resources_partial(
            bundle_id = bundle_id,
            bundle_verification_targets = [struct(target = ext) for ext in ctx.attr.extensions],
            plist_attrs = ["infoplists"],
            top_level_attrs = top_level_attrs,
        ),
        partials.settings_bundle_partial(),
        partials.swift_dylibs_partial(
            binary_artifact = binary_artifact,
            dependency_targets = swift_dylib_dependencies,
            bundle_dylibs = True,
            # TODO(kaipi): Revisit if we can add this only for non enterprise optimized
            # builds, or at least only for device builds.
            package_swift_support = True,
        ),
    ]

    if platform_support.is_device_build(ctx):
        processor_partials.append(
            partials.provisioning_profile_partial(profile_artifact = ctx.file.provisioning_profile),
        )

    processor_result = processor.process(ctx, processor_partials)

    return [
        DefaultInfo(
            files = processor_result.output_files,
            runfiles = ctx.runfiles(
                files = run_actions.start_simulator(ctx),
            ),
        ),
        TvosApplicationBundleInfo(),
    ] + processor_result.providers

def _tvos_extension_impl(ctx):
    """Experimental implementation of tvos_extension."""
    top_level_attrs = [
        "app_icons",
        "strings",
    ]

    binary_provider_struct = apple_common.link_multi_arch_binary(ctx = ctx)
    binary_provider = binary_provider_struct.binary_provider
    debug_outputs_provider = binary_provider_struct.debug_outputs_provider
    binary_artifact = binary_provider.binary

    bundle_id = ctx.attr.bundle_id

    processor_partials = [
        partials.apple_bundle_info_partial(bundle_id = bundle_id),
        partials.binary_partial(binary_artifact = binary_artifact),
        partials.bitcode_symbols_partial(
            binary_artifact = binary_artifact,
            debug_outputs_provider = debug_outputs_provider,
        ),
        partials.clang_rt_dylibs_partial(binary_artifact = binary_artifact),
        partials.debug_symbols_partial(
            debug_outputs_provider = debug_outputs_provider,
        ),
        partials.embedded_bundles_partial(plugins = [outputs.archive(ctx)]),
        partials.resources_partial(
            bundle_id = bundle_id,
            plist_attrs = ["infoplists"],
            top_level_attrs = top_level_attrs,
        ),
        partials.swift_dylibs_partial(
            binary_artifact = binary_artifact,
        ),
    ]

    if platform_support.is_device_build(ctx):
        processor_partials.append(
            partials.provisioning_profile_partial(profile_artifact = ctx.file.provisioning_profile),
        )

    processor_result = processor.process(ctx, processor_partials)

    return [
        DefaultInfo(
            files = processor_result.output_files,
        ),
        TvosExtensionBundleInfo(),
    ] + processor_result.providers

tvos_application = rule_factory.create_apple_bundling_rule(
    implementation = _tvos_application_impl,
    platform_type = "tvos",
    product_type = apple_product_type.application,
    doc = "Builds and bundles a tvOS Application.",
)

tvos_extension = rule_factory.create_apple_bundling_rule(
    implementation = _tvos_extension_impl,
    platform_type = "tvos",
    product_type = apple_product_type.app_extension,
    doc = "Builds and bundles a tvOS Extension.",
)
