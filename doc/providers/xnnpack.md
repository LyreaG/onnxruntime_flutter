# XNNPACK

Runs models on the CPU with Google's XNNPACK library, optimized for ARM and
x86 and mainly useful on phones.

| | |
|---|---|
| Platforms | Android, iOS (others if the build includes it) |
| In the bundled binaries | Android, iOS: yes *(not verified)*. Windows: no |
| Requirements | none |
| Method | `appendXnnpackProvider()` |
| How options reach ONNX Runtime | by name: `SessionOptionsAppendExecutionProvider("XNNPACK", …)` |
| 1.22 source | documented on `SessionOptionsAppendExecutionProvider` in [`onnxruntime_c_api.h`](https://github.com/syntax-syndicate/onnxruntime/blob/v1.22.0/include/onnxruntime/core/session/onnxruntime_c_api.h) |

## Usage

```dart
options
  ..setIntraOpNumThreads(4)
  ..appendXnnpackProvider()
  ..appendCPUProvider(CPUFlags.useArena);
```

## Options

XNNPACK has one option, `intra_op_num_threads`. The plugin sets it for you to
the session's intra-op thread count (`setIntraOpNumThreads`), so call that
before appending XNNPACK.
