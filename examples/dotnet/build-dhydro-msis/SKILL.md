---
name: build-dhydro-msis
description: Build D-HYDRO MSI installers for the 1D2D and/or 2D3D plugins. Use when asked to build, rebuild, package, or create an installer/MSI for D-HYDRO, 1D2D, or 2D3D.
---

# Build D-HYDRO MSIs

Interpret the request as follows:

- Plugin: `1d2d`, `2d3d`, or both when omitted.
- Configuration: `Debug` or `Release`; default to `Release`.
- Variant: one or more variants, or all when omitted.
- Treat `open` as `fmo`.
- Valid variants:
  - 1D2D: `fm`, `rws`, `fmo`
  - 2D3D: `fm`, `rws`, `fmo`, `fmwaq`
- Reject a variant that is not supported by the selected plugin.

Run `scripts/build-msi.ps1` from this skill. Derive the repository root from
Git rather than hard-coding a checkout path. The root must contain the selected
plugin directory and `build\targets`.

Examples:

```powershell
& "$PSScriptRoot\scripts\build-msi.ps1" -Product Both
& "$PSScriptRoot\scripts\build-msi.ps1" -Product 1d2d -Variant fmo
& "$PSScriptRoot\scripts\build-msi.ps1" -Product 2d3d -Variant fmwaq -Configuration Debug
& "$PSScriptRoot\scripts\build-msi.ps1" -Product Both -Variant fm,rws
```

If the solution has yet been built, use the `build-dhydro` skill first to compile the necessary projects before creating the MSI installers.