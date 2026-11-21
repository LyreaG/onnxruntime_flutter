<p align="center"><img width="50%" src="https://github.com/microsoft/onnxruntime/raw/main/docs/images/ONNX_Runtime_logo_dark.png" /></p>

This is a **fork** of the original [onnxruntime Flutter plugin](https://github.com/gtbluesky/onnxruntime_flutter), which appears to be no longer maintained.
**This fork adds support for 16KB memory page size and full GPU and hardware acceleration support**


# OnnxRuntime Plugin
[![pub package](https://img.shields.io/pub/v/onnxruntime.svg)](https://pub.dev/packages/onnxruntime)

## Overview

Flutter plugin for OnnxRuntime via `dart:ffi` provides an easy, flexible, and fast Dart API to integrate Onnx models in flutter apps across mobile and desktop platforms.

| **Platform**      | Android       | iOS | Linux | macOS | Windows |
|-------------------|---------------|-----|-------|-------|---------|
| **Compatibility** | API level 21+ | *   | *     | *     | *       |
| **Architecture**  | arm32/arm64   | *   | *     | *     | *       |

*: [Consistent with Flutter](https://docs.flutter.dev/reference/supported-platforms)

## Key Features

* Multi-platform Support for Android, iOS, Linux, macOS, Windows, and Web(Coming soon).
* Flexibility to use any Onnx Model.
* Acceleration using multi-threading.
* Similar structure as OnnxRuntime Java and C# API.
* Inference speed is not slower than native Android/iOS Apps built using the Java/Objective-C API.
* Run inference in different isolates to prevent jank in UI thread.

## Getting Started

In your flutter project add the dependency:

```yml
dependencies:
  ...
  onnxruntime: x.y.z
```

## Usage example

### Import

```dart
import 'package:onnxruntime_flutter/onnxruntime_flutter.dart';
```

### Initializing environment

```dart
OrtEnv.instance.init();
```

### Creating the Session

```dart
final sessionOptions = OrtSessionOptions();

// Use an accelerator if one is available, with CPU as fallback
await sessionOptions.appendDefaultProviders();

const assetFileName = 'assets/models/test.onnx';
final rawAssetFile = await rootBundle.load(assetFileName);
final bytes = rawAssetFile.buffer.asUint8List();
final session = OrtSession.fromBuffer(bytes, sessionOptions);
```

### Performing inference

```dart
final shape = [1, 2, 3];
final inputOrt = OrtValueTensor.createTensorWithDataList(data, shape);
final inputs = {'input': inputOrt};
final runOptions = OrtRunOptions();
final outputs = await _session?.runAsync(runOptions, inputs);
inputOrt.release();
runOptions.release();
outputs?.forEach((element) {
  element?.release();
});
```

### Releasing environment

```dart
OrtEnv.instance.release();
```

## 🚀 GPU Acceleration

This fork includes full support for GPU and hardware acceleration across multiple platforms!

### Supported Execution Providers

| Provider | Platform | Hardware | Speedup |
|----------|----------|----------|---------|
| **CUDA** | Windows/Linux | NVIDIA GPU | 5-10x |
| **TensorRT** | Windows/Linux | NVIDIA GPU | 10-20x |
| **DirectML** | Windows | AMD/Intel/NVIDIA GPU | 3-8x |
| **ROCm** | Linux | AMD GPU | 5-10x |
| **CoreML** | iOS/macOS | Apple Neural Engine | 5-15x |
| **NNAPI** | Android | Google NPU/GPU | 3-7x |
| **OpenVINO** | Windows/Linux | Intel GPU/VPU | 3-6x |
| **DNNL** | All | Intel CPU | 2-4x |
| **XNNPACK** | All | CPU optimizations | 1.5-3x |

### Quick Start: Automatic GPU Selection

The easiest way to enable GPU acceleration:

```dart
final sessionOptions = OrtSessionOptions();
await sessionOptions.appendDefaultProviders(); // 🎯 That's it!
```

This automatically selects the best available provider in this order:
1. **NPU**: CoreML → NNAPI → QNN
2. **GPU**: CUDA → DirectML → ROCm
3. **Optimized CPU**: DNNL → XNNPACK
4. **Fallback**: Standard CPU

It adds at most one accelerator, with default options, and never tries
TensorRT. See [doc/automatic_selection.md](doc/automatic_selection.md) for
what you get on each platform and how to write your own selection.

### Manual Provider Selection

For fine-grained control:

```dart
// NVIDIA GPU (Windows/Linux)
sessionOptions.appendCudaProvider({'device_id': '0'});

// NVIDIA with TensorRT optimizations + FP16
sessionOptions.appendTensorRTProvider({'trt_fp16_enable': '1'});

// DirectML for Windows (any GPU)
sessionOptions.appendDirectMLProvider();

// Apple Neural Engine (iOS/macOS)
sessionOptions.appendCoreMLProvider({'ModelFormat': 'MLProgram'});

// Android acceleration
sessionOptions.appendNnapiProvider({NnapiFlags.useFp16});

// AMD GPU on Linux
sessionOptions.appendRocmProvider({'device_id': '0'});

// Intel optimization
sessionOptions.appendDNNLProvider({'use_arena': '1'});

// Always add CPU as fallback
sessionOptions.appendCPUProvider(CPUFlags.useArena);
```

Every option each provider accepts in ONNX Runtime 1.22, which providers the
bundled binaries include, and how to migrate from the old flag enums:
**[doc/execution_providers.md](doc/execution_providers.md)**.

### Performance Tips

1. **Use `appendDefaultProviders()` first** - it handles everything automatically
2. **CUDA vs TensorRT**: TensorRT is faster but takes longer to initialize
3. **DirectML**: Great for cross-vendor support on Windows
4. **Mobile**: CoreML (iOS) and NNAPI (Android) provide massive speedups
5. **Thread count**: Set `setIntraOpNumThreads()` to your CPU core count for CPU inference

### GPU Setup Requirements

**Windows (NVIDIA)**:
- Install [CUDA Toolkit](https://developer.nvidia.com/cuda-downloads)
- Optional: [TensorRT](https://developer.nvidia.com/tensorrt) for extra speed

**Linux (NVIDIA)**:
- Install CUDA runtime: `apt install nvidia-cuda-toolkit`
- Optional: TensorRT

**Linux (AMD)**:
- Install [ROCm](https://www.amd.com/en/graphics/servers-solutions-rocm)

**Windows (Any GPU)**:
- DirectML works out-of-the-box on Windows 10+

**iOS/macOS**:
- CoreML works automatically (no setup needed)

**Android**:
- NNAPI works automatically on Android 8.1+ (no setup needed)

### Troubleshooting

If GPU acceleration isn't working:

1. Check available providers:
```dart
OrtEnv.instance.availableProviders().forEach((provider) {
  print('Available: $provider');
});
```

2. Catch provider errors gracefully:
```dart
try {
  sessionOptions.appendCudaProvider();
} catch (e) {
  print('CUDA not available, falling back to CPU');
  sessionOptions.appendCPUProvider(CPUFlags.useArena);
}
```

3. Verify GPU runtime is installed (CUDA, DirectML, etc.)

4. Check that you're using the GPU-enabled ONNX Runtime library

