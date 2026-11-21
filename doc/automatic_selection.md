# Automatic provider selection

```dart
final options = OrtSessionOptions();
await options.appendDefaultProviders();
final session = OrtSession.fromBuffer(modelBytes, options);
```

`appendDefaultProviders()` picks **one** accelerator for you, then adds CPU as
the fallback. It's the quickest way to get acceleration without knowing the
device, but it makes choices you can't change. This page explains exactly what
it does.

## What it does

It tries these calls in order and **stops at the first one that succeeds**:

| Step | Call | Goes for |
|---|---|---|
| 1 | `appendCoreMLProvider()` | Apple Neural Engine / GPU |
| 2 | `appendNnapiProvider()` | Android GPU, DSP, NPU |
| 3 | `appendQnnProvider()` | Qualcomm NPU |
| 4 | `appendCudaProvider()` | NVIDIA GPU |
| 5 | `appendDirectMLProvider()` | any DirectX 12 GPU |
| 6 | `appendRocmProvider()` | AMD GPU |
| 7 | `appendDNNLProvider()` | Intel CPU (oneDNN) |
| 8 | `appendXnnpackProvider()` | optimized mobile CPU |
| always | `appendCPUProvider(CPUFlags.useArena)` | everything else |

So a session ends up with **at most one accelerator plus CPU**.

## What it doesn't do

- **No options.** Every call is made without a map, so each provider runs with
  ONNX Runtime's defaults: first GPU, no FP16, no model caching, and so on.
  There's no way to pass options through it.
- **Doesn't try every provider.** TensorRT, OpenVINO, MIGraphX and CANN are
  never tried, even when the binary has them.
- **Doesn't tell you what it picked.** It returns nothing, and each failure is
  caught and dropped.
- **Doesn't check `availableProviders()` first.** It simply tries each call and
  moves on when one throws.
- **Isn't really asynchronous.** It's declared `async`, but all the work runs
  synchronously on the calling isolate.

## The red line in the console

Errors are caught in Dart, but ONNX Runtime **logs some of them itself before
returning**. On Windows without cuDNN you'll see this once per session, even
though everything works on CPU afterwards:

```
[E:onnxruntime:..., provider_bridge_ort.cc:1938 ...] Error loading
"onnxruntime_providers_cuda.dll" which depends on "cudnn64_9.dll" which is missing.
```

It's harmless: step 4 failed, and the session continues with the next steps.
Installing cuDNN makes it go away and turns CUDA on. With CUDA active you may
see a warning instead, such as *"1 Memcpy nodes are added to the graph … for
CUDAExecutionProvider"*: also harmless, it means part of the model runs on the
CPU and data is copied between the two.

**A GPU isn't always faster.** For small models called many times, like the
example's voice-activity detector (one call per 64 ms of audio), copying data
to and from the GPU costs more than the work itself: on an RTX 4070 the
example's VAD took about 250–620 ms on CUDA against about 50–130 ms on CPU.
GPUs pay off on larger models.

## What you get on each platform

With the binaries this plugin bundles:

| Platform | Result | Why |
|---|---|---|
| iOS | **CoreML** + CPU | step 1 succeeds |
| macOS | **CoreML** + CPU *(not verified)* | step 1 succeeds |
| Android | **NNAPI** + CPU *(not verified)* | CoreML isn't in the Android build, so step 2 succeeds; XNNPACK is never reached |
| Windows with cuDNN | **CUDA** + CPU | steps 1–3 fail, step 4 succeeds |
| Windows without cuDNN | **CPU only** | step 4 fails (the red line); DirectML, ROCm, oneDNN and XNNPACK aren't in the Windows build |
| Linux | **CUDA** + CPU if the CUDA libraries are installed, else CPU *(not verified)* | |

## When to write your own

Use the explicit `append…Provider` methods instead when you need options, want
TensorRT, want to know which provider is active, or want a different order.
The same pattern, under your control:

```dart
String? accelerator;
final attempts = <String, void Function()>{
  // CUDA after TensorRT takes the operators TensorRT can't run.
  'TensorRT + CUDA': () => options
    ..appendTensorRTProvider({
      'trt_fp16_enable': '1',
      'trt_engine_cache_enable': '1',
      'trt_engine_cache_path': cacheDir,
    })
    ..appendCudaProvider(),
  'CUDA': () => options.appendCudaProvider(),
  'CoreML': () => options.appendCoreMLProvider({'ModelFormat': 'MLProgram'}),
  'NNAPI': () => options.appendNnapiProvider({NnapiFlags.useFp16}),
};
for (final MapEntry(key: name, value: append) in attempts.entries) {
  try {
    append();
    accelerator = name;
    break;
  } catch (_) {
    // Not available here; try the next one.
  }
}
options.appendCPUProvider(CPUFlags.useArena);
print('Running on ${accelerator ?? 'CPU'}');
```

Unlike `appendDefaultProviders()`, an unknown key in one of these maps makes
that `append…` call throw, so a typo silently skips that provider. Check the
keys against each provider's page.

**TensorRT can still fail later.** Appending it succeeds even for a model
TensorRT can't handle (for example one without fixed shapes, like the
example's VAD model); the error comes from `OrtSession.fromBuffer` /
`fromFile`. If TensorRT is in your list, create the session inside a `try`
and, if it fails, build new options without TensorRT and create it again.
See [TensorRT](providers/tensorrt.md#notes).
