# Test fixtures

| File | Source | License |
|---|---|---|
| `mnist-12.onnx` | [onnx/models](https://github.com/onnx/models/tree/main/validated/vision/classification/mnist) `validated/vision/classification/mnist/model/mnist-12.onnx` | Apache 2.0 |

`mnist-12.onnx` is used by `test/gpu_test.dart` because its shapes are fixed
(input `1×1×28×28`), which TensorRT needs. The example's VAD model has dynamic
shapes and TensorRT rejects it.
