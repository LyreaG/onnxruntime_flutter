# NNAPI

Runs models through Android's Neural Networks API, which hands work to the
device's GPU, DSP or NPU depending on the phone.

| | |
|---|---|
| Platforms | Android 8.1+ |
| In the bundled binaries | Android: yes *(not verified)* |
| Requirements | none beyond the OS; quality of acceleration depends on the phone's NNAPI drivers |
| Method | `appendNnapiProvider([Set<NnapiFlags> flags = const {}])` |
| How options reach ONNX Runtime | the set is combined into one bitmask passed to `OrtSessionOptionsAppendExecutionProvider_Nnapi` |
| 1.22 source | [`nnapi_provider_factory.h`](https://github.com/syntax-syndicate/onnxruntime/blob/v1.22.0/include/onnxruntime/core/providers/nnapi/nnapi_provider_factory.h) |

## Usage

```dart
options
  ..appendNnapiProvider({NnapiFlags.useFp16})
  ..appendCPUProvider(CPUFlags.useArena);

options.appendNnapiProvider(); // ONNX Runtime defaults
```

## Options

Pass any combination as a set; the plugin ORs them together (`useFp16` +
`useNCHW` = `0x1 | 0x2`).

| Flag | What it does |
|---|---|
| `useFp16` | Allow float16 instead of float32: faster on most phones, less precise. |
| `useNCHW` | Use NCHW layout. Android API 29+ only, and currently slower than the default NHWC. |
| `cpuDisabled` | Never use NNAPI's own CPU implementation; operators the accelerator can't run go to ONNX Runtime's CPU provider instead. |
| `cpuOnly` | Only use NNAPI's CPU implementation. For checking results, not speed. |

`cpuDisabled` together with `cpuOnly` is an error.

## Notes

- On iOS, Windows, macOS and Linux the call throws: NNAPI doesn't exist there.
