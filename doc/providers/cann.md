# CANN

Runs models on Huawei Ascend NPUs through CANN (Compute Architecture for
Neural Networks).

| | |
|---|---|
| Platforms | Linux (Ascend hardware) |
| In the bundled binaries | **no**: appending it reports "CANN execution provider is not enabled in this build" |
| Requirements | Ascend hardware, the CANN toolkit, and an ONNX Runtime 1.22 build with CANN |
| Method | `appendCANNProvider([Map<String, String>? options])` |
| How options reach ONNX Runtime | ONNX Runtime's CANN options object: created with ORT's defaults, then your map is applied by `UpdateCANNProviderOptions` |
| 1.22 source | keys: [`cann_execution_provider_info.cc`](https://github.com/syntax-syndicate/onnxruntime/blob/v1.22.0/onnxruntime/core/providers/cann/cann_execution_provider_info.cc) · descriptions: [`cann_provider_options.h`](https://github.com/syntax-syndicate/onnxruntime/blob/v1.22.0/include/onnxruntime/core/providers/cann/cann_provider_options.h) |

## Usage

```dart
options
  ..appendCANNProvider({'device_id': '0'})
  ..appendCPUProvider(CPUFlags.useArena);
```

## Options

| Key | What it does |
|---|---|
| `device_id` | Which NPU to use. |
| `npu_mem_limit` | Maximum size of the memory arena, in bytes. |
| `arena_extend_strategy` | How the arena grows: `kNextPowerOfTwo` or `kSameAsRequested`. |
| `enable_cann_graph` | `1`/`0`: prefer CANN's graph mode. |
| `dump_graphs` | `1`/`0`: dump graphs for debugging. |
| `dump_om_model` | `1`/`0`: dump the compiled OM model. |
| `precision_mode` | Operator precision mode (a CANN setting). |
| `op_select_impl_mode` | Operator implementation mode (a CANN compile setting). |
| `optypelist_for_implmode` | Operators that `op_select_impl_mode` applies to. |

The accepted values for the last three are defined by Huawei's CANN toolkit,
not by ONNX Runtime.
