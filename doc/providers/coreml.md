# CoreML

Runs models through Apple's Core ML, which can use the Neural Engine, the GPU
or the CPU. The way to accelerate models on iPhone, iPad and Mac.

| | |
|---|---|
| Platforms | iOS, macOS |
| In the bundled binaries | iOS: yes (`onnxruntime-objc` pod). macOS: yes *(not verified)* |
| Requirements | none beyond the OS; `ModelFormat: MLProgram` needs Core ML 5 (iOS 15 / macOS 12) |
| Method | `appendCoreMLProvider([Map<String, String>? options])` |
| How options reach ONNX Runtime | by name: `SessionOptionsAppendExecutionProvider("CoreML", keys, values)`; ONNX Runtime rejects unknown keys and values |
| 1.22 source | keys and values: [`coreml_options.cc`](https://github.com/syntax-syndicate/onnxruntime/blob/v1.22.0/onnxruntime/core/providers/coreml/coreml_options.cc) · key names: [`coreml_provider_factory.h`](https://github.com/syntax-syndicate/onnxruntime/blob/v1.22.0/include/onnxruntime/core/providers/coreml/coreml_provider_factory.h) |

## Usage

```dart
final dir = (await getApplicationSupportDirectory()).path; // path_provider
options
  ..appendCoreMLProvider({
    'ModelFormat': 'MLProgram',
    'MLComputeUnits': 'ALL',
    'ModelCacheDirectory': '$dir/coreml_cache',
  })
  ..appendCPUProvider(CPUFlags.useArena);
```

## Options

| Key | Values | Default | What it does |
|---|---|---|---|
| `MLComputeUnits` | `ALL`, `CPUAndNeuralEngine`, `CPUAndGPU`, `CPUOnly` | `ALL` | Which hardware Core ML may use. `CPUOnly` gives reference results for checking accuracy. |
| `ModelFormat` | `MLProgram`, `NeuralNetwork` | `NeuralNetwork` | Core ML model type to convert to. `MLProgram` is newer and supports more operators. |
| `ModelCacheDirectory` | directory path | temporary, deleted with the session | Keep the converted Core ML model, so later launches skip the conversion. |
| `RequireStaticInputShapes` | `1`/`0` | `0` | Only take operators whose inputs have fixed shapes; dynamic shapes can be slow. |
| `EnableOnSubgraphs` | `1`/`0` | `0` | Also use Core ML inside control-flow subgraphs (If, Loop). |
| `SpecializationStrategy` | `Default`, `FastPrediction` | `Default` | Apple's compile strategy: `FastPrediction` trades longer loading for faster predictions. |
| `ProfileComputePlan` | `1`/`0` | `0` | Log which hardware runs each operator and its estimated time. For debugging. |
| `AllowLowPrecisionAccumulationOnGPU` | `1`/`0` | `0` | Let the GPU accumulate in float16: faster, less precise. |

## Notes

- **Use exactly `'1'`** for on/off options. ONNX Runtime 1.22 treats anything
  else, including `'true'`, as off.
- **Spelling matters:** the values are `ALL`, `CPUOnly`, and so on. Older docs
  show `MLComputeUnitsCPUOnly`, which 1.22 rejects.
- **Model cache:** ONNX Runtime doesn't notice when the model changes. Clear
  the cache directory when you ship a new model, or set the
  `COREML_CACHE_KEY` entry in the model's metadata.
- On Windows, Android and Linux the call throws: CoreML doesn't exist there.
