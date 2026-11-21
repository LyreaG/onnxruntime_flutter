# DirectML

Runs models on any DirectX 12 GPU on Windows: NVIDIA, AMD or Intel, including
integrated graphics. No vendor drivers or toolkits beyond the normal GPU
driver.

| | |
|---|---|
| Platforms | Windows |
| In the bundled binaries | **no**: the bundled Windows build has CPU, CUDA and TensorRT only |
| Requirements | an ONNX Runtime 1.22 build with DirectML (e.g. the `Microsoft.ML.OnnxRuntime.DirectML` NuGet package) bundled instead |
| Method | `appendDirectMLProvider([Map<String, String>? options])` |
| How options reach ONNX Runtime | by name: `SessionOptionsAppendExecutionProvider("DML", keys, values)`; ONNX Runtime parses the keys |
| 1.22 source | [`dml_provider_factory.cc`](https://github.com/syntax-syndicate/onnxruntime/blob/v1.22.0/onnxruntime/core/providers/dml/dml_provider_factory.cc) |

## Usage

```dart
options
  ..appendDirectMLProvider({'performance_preference': 'high_performance'})
  ..appendCPUProvider(CPUFlags.useArena);
```

## Options

| Key | Values | What it does |
|---|---|---|
| `device_id` | adapter index | Which GPU to use. |
| `performance_preference` | `default`, `high_performance`, `minimum_power` | On laptops with two GPUs, prefer the fast one or the power-saving one. |
| `device_filter` | `gpu`, `npu`, `any` | Which kind of adapter may be picked. |
| `disable_metacommands` | `true`/`false` | Turn off DirectML metacommands (vendor-optimized kernels); can help with driver bugs. |

## Notes

- With the bundled binary, this call throws an ONNX Runtime error saying the
  provider isn't available.
- Microsoft's `Microsoft.ML.OnnxRuntime.DirectML` NuGet package stopped at
  version 1.24.4, while the other ONNX Runtime packages are at 1.32.
