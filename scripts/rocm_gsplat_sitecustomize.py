#!/usr/bin/env python3
"""Opt-in bootstrap for a prebuilt gsplat ROCm extension.

Copy this file to ``sitecustomize.py`` in an isolated directory, prepend that
directory to ``PYTHONPATH``, and set ``BIGYM_GSPLAT_PREBUILT_DIR`` to the torch
extension build directory.  This bypasses gsplat's CUDA-toolkit probe without
modifying the installed package.
"""

from __future__ import annotations

import os
import sys
import types


build_directory = os.environ.get("BIGYM_GSPLAT_PREBUILT_DIR")
if build_directory:
    from torch.utils.cpp_extension import _import_module_from_library

    extension = _import_module_from_library(
        "gsplat_cuda",
        build_directory,
        True,
    )
    backend = types.ModuleType("gsplat.cuda._backend")
    backend._C = extension
    backend.__all__ = ["_C"]
    sys.modules[backend.__name__] = backend
