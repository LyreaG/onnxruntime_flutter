# QNN

Runs models on Qualcomm hardware through the Qualcomm AI Engine Direct SDK
(QNN), mainly the Hexagon NPU (HTP) in Snapdragon phones and Windows-on-ARM
laptops.

| | |
|---|---|
| Platforms | Android (Snapdragon), Windows on ARM |
| In the bundled binaries | **no**: needs a Qualcomm build of ONNX Runtime, e.g. `com.microsoft.onnxruntime:onnxruntime-android-qnn:1.22.0` on Maven |
| Requirements | a Qualcomm device and the QNN backend libraries |
| Method | `appendQnnProvider()` |
| How options reach ONNX Runtime | by name: `SessionOptionsAppendExecutionProvider("QNN", …)` |
| 1.22 source | keys are documented on `SessionOptionsAppendExecutionProvider` in [`onnxruntime_c_api.h`](https://github.com/syntax-syndicate/onnxruntime/blob/v1.22.0/include/onnxruntime/core/session/onnxruntime_c_api.h) |

## Usage

```dart
options
  ..appendQnnProvider()
  ..appendCPUProvider(CPUFlags.useArena);
```

## Options

**The plugin doesn't pass QNN options yet**: `appendQnnProvider()` takes no
map, so ONNX Runtime's defaults apply. ONNX Runtime 1.22 does support these
keys, for when the method gets a map:

| Key | Values |
|---|---|
| `backend_type` | `cpu`, `gpu`, `htp`, `saver` |
| `backend_path` | path to a QNN backend library (instead of `backend_type`) |
| `htp_performance_mode` | `burst`, `balanced`, `default`, `high_performance`, `high_power_saver`, `low_balanced`, `extreme_power_saver`, `low_power_saver`, `power_saver`, `sustained_high_performance` |
| `htp_graph_finalization_optimization_mode` | `0`–`3`: higher prepares slower, runs faster |
| `enable_htp_fp16_precision` | `1` (default) / `0` |
| `htp_arch` | `0`, `68`, `69`, `73`, `75` |
| `soc_model` | SoC model number |
| `device_id` | device to use with `htp_arch` |
| `vtcm_mb` | VTCM size in MB |
| `rpc_control_latency` | RPC latency |
| `qnn_context_priority` | `low`, `normal`, `normal_high`, `high` |
| `profiling_level` | `off`, `basic`, `detailed` |
| `profiling_file_path` | where to write the profile |
| `offload_graph_io_quantization` | `1` (default) / `0` |
| `enable_htp_spill_fill_buffer` | `1`/`0` |
| `enable_htp_shared_memory_allocator` | `1`/`0` |
| `dump_json_qnn_graph`, `json_qnn_graph_dir` | dump graphs as JSON |
| `qnn_saver_path` | record QNN calls for debugging (gives wrong results) |

## Notes

- With the bundled binaries the call throws an ONNX Runtime error saying the
  provider isn't available.
