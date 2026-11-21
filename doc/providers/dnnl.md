# oneDNN (DNNL)

Runs models on the CPU with Intel's oneDNN library (formerly MKL-DNN), which
can be faster than the default CPU provider on Intel processors.

| | |
|---|---|
| Platforms | Windows, Linux (x64) |
| In the bundled binaries | **no**: appending it reports "oneDNN execution provider is not enabled in this build" |
| Requirements | an ONNX Runtime 1.22 build with oneDNN |
| Method | `appendDNNLProvider([Map<String, String>? options])` |
| How options reach ONNX Runtime | ONNX Runtime's oneDNN V2 options object: created with ORT's defaults, then your map is applied by `UpdateDnnlProviderOptions` |
| 1.22 source | [`dnnl_execution_provider_info.cc`](https://github.com/syntax-syndicate/onnxruntime/blob/v1.22.0/onnxruntime/core/providers/dnnl/dnnl_execution_provider_info.cc) |

## Usage

```dart
options
  ..appendDNNLProvider({'use_arena': '1'})
  ..appendCPUProvider(CPUFlags.useArena);
```

## Options

| Key | Values | What it does |
|---|---|---|
| `use_arena` | `1`/`0` | Reuse memory between runs through ONNX Runtime's arena. |

The other key, `threadpool_args`, takes a memory address and can't be used
from Dart.
