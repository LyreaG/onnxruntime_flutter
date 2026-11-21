# Execution providers

An execution provider (EP) is the backend ONNX Runtime uses to run a model:
CPU, an NVIDIA GPU through CUDA, Apple's Neural Engine through CoreML, and so
on. You add providers to `OrtSessionOptions` before creating the session.
ONNX Runtime tries them in the order you added them; operators the first one
can't run go to the next.

```dart
final options = OrtSessionOptions()
  ..appendCudaProvider({'device_id': '0'})
  ..appendCPUProvider(CPUFlags.useArena);
final session = OrtSession.fromBuffer(modelBytes, options);
```

> **Version:** this plugin ships **ONNX Runtime 1.22**. Every option in these
> docs comes from the 1.22 source (links go to the `v1.22.0` tag). The pages on
> onnxruntime.ai describe the *latest* release and may list options 1.22
> doesn't have; ONNX Runtime rejects those with an error.
>
> **Source links (temporary):** they point to
> [`syntax-syndicate/onnxruntime`](https://github.com/syntax-syndicate/onnxruntime/tree/v1.22.0),
> a mirror of ONNX Runtime pinned to the `v1.22.0` tag (commit `731cb2f`),
> because `github.com/microsoft/onnxruntime` currently returns 404. Once
> Microsoft's repository is back, these links should point there again: every
> one starts with `https://github.com/syntax-syndicate/onnxruntime/`, so it's a
> single find-and-replace across `doc/`. The headers in `src/onnxruntime/` are
> byte-for-byte that tag's either way.

## Providers

| Provider | Hardware | Platforms | Bundled? | Method |
|---|---|---|---|---|
| [CPU](providers/cpu.md) | any CPU | all | ✔ | `appendCPUProvider(CPUFlags)` |
| [CUDA](providers/cuda.md) | NVIDIA GPU | Windows, Linux | ✔ Windows | `appendCudaProvider([Map])` |
| [TensorRT](providers/tensorrt.md) | NVIDIA GPU | Windows, Linux | ✔ Windows | `appendTensorRTProvider([Map])` |
| [DirectML](providers/directml.md) | any DirectX 12 GPU | Windows | ✘ | `appendDirectMLProvider([Map])` |
| [CoreML](providers/coreml.md) | Neural Engine, GPU, CPU | iOS, macOS | ✔ iOS | `appendCoreMLProvider([Map])` |
| [NNAPI](providers/nnapi.md) | phone GPU, DSP, NPU | Android | ✔ | `appendNnapiProvider([Set<NnapiFlags>])` |
| [QNN](providers/qnn.md) | Qualcomm NPU | Android, Windows on ARM | ✘ | `appendQnnProvider()` |
| [ROCm](providers/rocm.md) | AMD GPU | Linux | ✘ | `appendRocmProvider([Map])` |
| [MIGraphX](providers/migraphx.md) | AMD GPU | Linux | ✘ | `appendMIGraphXProvider([Map])` |
| [OpenVINO](providers/openvino.md) | Intel CPU, GPU, NPU | Windows, Linux | ✘ | `appendOpenVINOProvider([Map])` |
| [oneDNN](providers/dnnl.md) | Intel CPU | Windows, Linux | ✘ | `appendDNNLProvider([Map])` |
| [CANN](providers/cann.md) | Huawei Ascend NPU | Linux | ✘ | `appendCANNProvider([Map])` |
| [XNNPACK](providers/xnnpack.md) | ARM / x86 CPU | Android, iOS | ✔ mobile | `appendXnnpackProvider()` |

"Bundled" means the ONNX Runtime binary this plugin ships includes it. A
method existing in Dart doesn't mean the binary has the provider.

## Automatic selection

```dart
await options.appendDefaultProviders();
```

Tries CoreML → NNAPI → QNN → CUDA → DirectML → ROCm → oneDNN → XNNPACK, keeps
the first one that can be added, then always appends CPU. It passes no
options, never tries TensorRT, and doesn't tell you which provider it picked.
**[How it works, what you get per platform, and how to write your own](automatic_selection.md).**

`OrtEnv.instance.availableProviders()` lists the providers **compiled into**
the loaded library. That doesn't mean they can load: CUDA is listed on Windows
even without cuDNN, and only fails when you append it.

## What the bundled binaries include

| Platform | Providers in the bundled ONNX Runtime 1.22 | Extra requirements |
|---|---|---|
| Windows x64 | CPU, CUDA, TensorRT (both tested on an RTX 4070) | CUDA: [cuDNN 9](https://developer.nvidia.com/cudnn) for CUDA 12 on `PATH`. TensorRT: also TensorRT 10.9, and models with fixed shapes. [Setup guide](gpu_setup.md) |
| Linux | CPU, CUDA, TensorRT *(not verified)* | as Windows |
| Android | CPU, NNAPI, XNNPACK *(not verified)* | |
| iOS | CPU, CoreML, XNNPACK (standard `onnxruntime-objc` pod) | |
| macOS | CPU, CoreML *(not verified)* | |

To use another provider, bundle an ONNX Runtime 1.22 build that includes it;
no plugin change is needed.

## Passing options

Most providers take an optional `Map<String, String>` whose keys are ONNX
Runtime's own option names; each provider's page lists them.

- **All values are strings**, numbers included: `{'device_id': '0'}`.
- **On/off options** take `'1'` or `'0'`. Some providers ignore anything but
  `'1'` (CoreML treats `'true'` as off), so stick to `'1'`/`'0'`.
- **Omitted keys** keep ONNX Runtime's default.
- **Validation:** ONNX Runtime checks the keys, except for MIGraphX, where the
  plugin does.

Internally the map takes one of four routes, depending on what ONNX Runtime
offers for that provider:

| Route | Providers |
|---|---|
| ONNX Runtime options object (`Create…` / `Update…` with the map) | CUDA, TensorRT, ROCm, oneDNN, CANN |
| Generic by-name call with the map | CoreML, DirectML, OpenVINO, QNN, XNNPACK |
| Struct filled by the plugin | MIGraphX |
| Flags (an integer) | CPU, NNAPI |

## Errors

| Situation | What you get |
|---|---|
| Provider not compiled into the binary | ONNX Runtime error, e.g. `CANN execution provider is not enabled in this build` |
| Provider compiled in but its libraries are missing | ONNX Runtime error naming the missing library, e.g. `cudnn64_9.dll` |
| Unknown key or invalid value | ONNX Runtime error; for MIGraphX an `ArgumentError` listing the valid keys |
| Native library older than 1.22 | `StateError` when `OrtEnv` starts |

All but the last are thrown by the `append…Provider` call, so you can catch
them and fall back:

```dart
try {
  options.appendCudaProvider();
} catch (e) {
  // CUDA unavailable; the CPU provider below still runs the model.
}
options.appendCPUProvider(CPUFlags.useArena);
```

## Migrating from the flag-based API

The GPU flag enums never reached ONNX Runtime's options (CUDA's flags were
even passed as the GPU index), so they were removed:

| Before | After |
|---|---|
| `appendCudaProvider(CUDAFlags.useArena)` | `appendCudaProvider()` |
| `appendRocmProvider(ROCmFlags.useArena)` | `appendRocmProvider()` |
| `appendMIGraphXProvider(MIGraphXFlags.useFp16)` | `appendMIGraphXProvider({'migraphx_fp16_enable': '1'})` |
| `appendDNNLProvider(DNNLFlags.useArena)` | `appendDNNLProvider({'use_arena': '1'})` |
| `appendTensorRTProvider(deviceId, cachePath)` | `appendTensorRTProvider({'device_id': '0', 'trt_engine_cache_enable': '1', 'trt_engine_cache_path': cachePath})` |
| `appendCoreMLProvider(CoreMLFlags.useCpuOnly)` | `appendCoreMLProvider({'MLComputeUnits': 'CPUOnly'})` |
| `appendNnapiProvider(NnapiFlags.useFp16)` | `appendNnapiProvider({NnapiFlags.useFp16})` |
| `appendNnapiProvider(NnapiFlags.useNone)` | `appendNnapiProvider()` |

`DirectMLFlags`, `OpenVINOFlags`, `CANNFlags` and `TensorRTFlags` were never
used by any method and were removed too. The old `appendTensorRTProvider`
turned on FP16, engine caching and subgraph dumping by itself; see
[TensorRT](providers/tensorrt.md#notes) to keep that.
