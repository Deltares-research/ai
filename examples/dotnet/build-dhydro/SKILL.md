---
name: build-dhydro
description: Builds the main D-HYDRO 1D2D or 2D3D solution in Debug or Release mode across differing Visual Studio and .NET SDK installations. Use when asked to compile, rebuild, or restore D-HYDRO 1D2D or 2D3D; do not use it to create an MSI installer.
---

# Build D-HYDRO

Build the primary D-HYDRO solution for one selected product. This skill builds
source code only; use `build-dhydro-msis` when the request is to package an
installer/MSI.

## Interpret the request

- **Product** (required): `1d2d` or `2d3d` (case-insensitive).
- **Configuration**: `Debug` or `Release` (case-insensitive). Default to
  `Debug` when omitted.
- Do not infer a product from a similarly named directory. If the product is
  unspecified and cannot be determined unambiguously, ask for it.
- Use the primary solution, never a `-Setup` solution:

  | Product | Solution |
  | --- | --- |
  | `1d2d` | `DHYDRO.1D2D.sln` |
  | `2d3d` | `DHYDRO.2D3D.sln` |

Both solutions support `Debug|Any CPU` and `Release|Any CPU`.

## Run the build script

Use the included script rather than duplicating discovery logic:

```powershell
& '<skill-directory>\scripts\Build-DHydro.ps1' `
    -Product 1d2d `
    -Configuration Debug
```

Pass `-Rebuild` only when the user explicitly requests a clean build or
rebuild. When the workspace root cannot be inferred from the skill location,
pass `-WorkspaceRoot`. A known solution can instead be supplied with
`-Solution`.

```powershell
& '<skill-directory>\scripts\Build-DHydro.ps1' `
    -Product 2d3d `
    -Configuration Debug `
    -WorkspaceRoot '<workspace-root>' `
    -Rebuild
```

The script:

1. Locates the selected solution and derives its Git checkout root.
2. Discovers every `MSBuild.exe` available from `PATH` and Visual Studio
   installations that contain MSBuild and the .NET desktop development
   workload.
3. Honors `global.json` when present.
4. Probes candidates with an integrated restore. It first uses the normal
   Visual Studio SDK resolver, then tries installed .NET SDKs explicitly only
   when SDK resolution is broken.
5. Retries only recognized toolchain compatibility failures. NuGet, source,
   authentication, and other genuine restore failures stop immediately.
6. Builds with the first compatible Visual Studio/MSBuild/.NET SDK
   combination.

Do not replace Visual Studio MSBuild with `dotnet build` or `dotnet msbuild`.
These solutions combine SDK-style projects with legacy .NET Framework desktop
projects and require the Visual Studio build tools.

## Delegate to subagent
This skill should be run by the sub-agent 'build-dhydro'. The parent agent is responsible for invoking this sub-agent with the appropriate parameters and handling its output. Only if specified sub-agent is not available may you use a default sub-agent.

## Report the result

Report:

- selected solution;
- configuration and `Any CPU` platform;
- selected MSBuild path and version;
- SDK selection (`Visual Studio resolver` or explicit SDK version);
- whether restore and build succeeded.

On failure, report the final actionable error from the script. Do not claim
that an SDK or workload is missing unless discovery or the compatibility probe
establishes that.
