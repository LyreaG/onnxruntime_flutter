# Setting up CUDA and TensorRT on Windows

The bundled Windows build of ONNX Runtime 1.22 includes the [CUDA](providers/cuda.md)
and [TensorRT](providers/tensorrt.md) providers, but not NVIDIA's own
libraries they load at run time. Without them, appending CUDA fails with
*"…depends on cudnn64_9.dll which is missing"* and TensorRT with
*"…nvinfer_10.dll which is missing"*. This guide installs them. These are the
steps used to test the plugin on an RTX 4070 Laptop GPU.

## What you need

| Component | Version for ONNX Runtime 1.22 | Needed for | Size |
|---|---|---|---|
| NVIDIA GPU driver | recent (tested: 610.91) | CUDA, TensorRT | — |
| CUDA runtime | **12.x**, 12.0 to 12.8 | CUDA, TensorRT | ~3 GB (Toolkit) |
| cuDNN | **9.x for CUDA 12** (tested: 9.10.2) | CUDA, TensorRT | 652 MB zip |
| TensorRT | **10.9 for CUDA 12.8** | TensorRT only | 1.76 GB zip |

The versions come from ONNX Runtime's requirements table: 1.22 is built
against CUDA 12.0–12.8 and TensorRT 10.9. Keep ~5 GB free for the downloads and
the unpacked files.

## 1. Check the GPU and the CUDA runtime

```powershell
nvidia-smi --query-gpu=name,driver_version --format=csv,noheader
```

```powershell
Get-Command cudart64_12.dll, cublas64_12.dll, cublasLt64_12.dll, cufft64_11.dll | Select-Object Name, Source
```

If the second command finds all four DLLs, the CUDA runtime is in place. If
not, install the **CUDA Toolkit 12.8** from NVIDIA's CUDA download archive;
its installer adds `C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.8\bin`
to `PATH`.

## 2. cuDNN 9

NVIDIA publishes cuDNN on a public server, no login needed, together with a
SHA-256 for each file.

```powershell
New-Item -ItemType Directory -Force "$HOME\nvidia\cudnn-dl" | Out-Null
$url = "https://developer.download.nvidia.com/compute/cudnn/redist/cudnn/windows-x86_64/cudnn-windows-x86_64-9.10.2.21_cuda12-archive.zip"
Invoke-WebRequest $url -OutFile "$HOME\nvidia\cudnn-dl\cudnn.zip"
```

Check the file against NVIDIA's checksum before unpacking:

```powershell
$expected = (Invoke-RestMethod "https://developer.download.nvidia.com/compute/cudnn/redist/redistrib_9.10.2.json").cudnn.'windows-x86_64'.cuda12.sha256
(Get-FileHash "$HOME\nvidia\cudnn-dl\cudnn.zip" -Algorithm SHA256).Hash -eq $expected.ToUpper()
```

It must print `True`. Then unpack:

```powershell
Expand-Archive "$HOME\nvidia\cudnn-dl\cudnn.zip" -DestinationPath "$HOME\nvidia" -Force
```

The DLLs are now in
`$HOME\nvidia\cudnn-windows-x86_64-9.10.2.21_cuda12-archive\bin`
(`cudnn64_9.dll` and seven `cudnn_*64_9.dll` companions).

Alternative: `pip install nvidia-cudnn-cu12` installs the same DLLs into
Python's `site-packages\nvidia\cudnn\bin`; put that folder on `PATH` instead.

## 3. TensorRT 10.9 (only for the TensorRT provider)

Also on NVIDIA's public server. NVIDIA doesn't publish a checksum next to it,
so compare the size instead.

```powershell
New-Item -ItemType Directory -Force "$HOME\nvidia\tensorrt-dl" | Out-Null
$url = "https://developer.download.nvidia.com/compute/machine-learning/tensorrt/10.9.0/zip/TensorRT-10.9.0.34.Windows.win10.cuda-12.8.zip"
Invoke-WebRequest $url -OutFile "$HOME\nvidia\tensorrt-dl\tensorrt.zip"
(Get-Item "$HOME\nvidia\tensorrt-dl\tensorrt.zip").Length -eq 1845842538
```

It must print `True`. Then unpack:

```powershell
Expand-Archive "$HOME\nvidia\tensorrt-dl\tensorrt.zip" -DestinationPath "$HOME\nvidia" -Force
```

The DLLs are now in `$HOME\nvidia\TensorRT-10.9.0.34\lib` (`nvinfer_10.dll`
and the other `nvinfer_*_10.dll` files).

Use **10.9** specifically: the plugin's build loads `nvinfer_10.dll`, and pip's
`tensorrt-cu12-libs` is already at version 11 with no Windows package.

## 4. Put them on PATH

This adds both folders to **your user** `PATH` (not system-wide) and keeps
everything already there:

```powershell
$add = @("$HOME\nvidia\cudnn-windows-x86_64-9.10.2.21_cuda12-archive\bin", "$HOME\nvidia\TensorRT-10.9.0.34\lib")
$parts = @([Environment]::GetEnvironmentVariable('Path','User') -split ';' | Where-Object { $_ })
[Environment]::SetEnvironmentVariable('Path', (($parts + ($add | Where-Object { $parts -notcontains $_ })) -join ';'), 'User')
```

**Restart** your terminal, editor and any running app: a program reads `PATH`
once, when it starts. To use the libraries in an already-open terminal without
restarting:

```powershell
$env:PATH = "$HOME\nvidia\cudnn-windows-x86_64-9.10.2.21_cuda12-archive\bin;$HOME\nvidia\TensorRT-10.9.0.34\lib;$env:PATH"
```

## 5. Check it works

```powershell
Get-Command cudnn64_9.dll, nvinfer_10.dll | Select-Object Name, Source
```

Then, from the plugin's folder, run the GPU tests (build the example once
first, since the tests load its bundled `onnxruntime.dll`):

```powershell
$env:ORT_GPU_TESTS = "1"; flutter test test/gpu_test.dart
```

All tests should pass. In the example app, `appendDefaultProviders()` now
picks CUDA and the red *"cudnn64_9.dll which is missing"* line is gone.

## Troubleshooting

| Message | Cause |
|---|---|
| `…depends on "cudnn64_9.dll" which is missing` | cuDNN isn't on `PATH`, or the program started before `PATH` changed |
| `…depends on "nvinfer_10.dll" which is missing` | TensorRT isn't on `PATH`, or it's not version 10 |
| `…cudart64_12.dll…` or `cublas64_12.dll` missing | CUDA 12 runtime missing (step 1) |
| `TensorRT input: … has no shape specified` | the model has dynamic shapes; see [TensorRT notes](providers/tensorrt.md#notes) |

## Shipping an app

Your users need the same libraries on their machines. Either ask them to
install them as above, or ship the cuDNN and TensorRT DLLs next to your app;
check NVIDIA's license terms for cuDNN and TensorRT before redistributing
them.
