# CPU

ONNX Runtime's default provider. It runs every operator, on every platform, so
it's the fallback for anything another provider can't run. If you append no
provider at all, ONNX Runtime uses CPU.

| | |
|---|---|
| Platforms | all |
| In the bundled binaries | yes, everywhere |
| Requirements | none |
| Method | `appendCPUProvider(CPUFlags flags)` |
| How options reach ONNX Runtime | one integer, `use_arena`, passed to `OrtSessionOptionsAppendExecutionProvider_CPU` |
| 1.22 source | [`cpu_provider_factory.h`](https://github.com/syntax-syndicate/onnxruntime/blob/v1.22.0/include/onnxruntime/core/providers/cpu/cpu_provider_factory.h) |

## Usage

```dart
options.appendCPUProvider(CPUFlags.useArena);
```

Append it **last**, after any accelerator, so it only takes the operators the
accelerators can't run.

## Options

| Flag | Meaning |
|---|---|
| `CPUFlags.useArena` | Use ONNX Runtime's memory arena: memory is reused between runs instead of being allocated each time. Usually faster. |
| `CPUFlags.useNone` | No arena. Uses less memory when idle. |

That's the only setting ONNX Runtime has for the CPU provider.

## Threads and optimization

Thread counts and graph optimization aren't provider options; they're set on
the session options and apply to the whole session:

```dart
final options = OrtSessionOptions()
  ..setIntraOpNumThreads(4) // threads inside one operator
  ..setInterOpNumThreads(1) // operators run in parallel
  ..setSessionGraphOptimizationLevel(GraphOptimizationLevel.ortEnableAll)
  ..appendCPUProvider(CPUFlags.useArena);
```
