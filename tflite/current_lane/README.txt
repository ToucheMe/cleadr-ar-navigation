1. /dataset/annotation

2. model.ipynb

3. train.py

4. /saved_model/model_float32.tflite -> /models/current_lane_model.tflite

* model.pth (model_float32.tflite) -> model.ipynb [Demo]

* last.pth, best.pth, model.onnx are intermediate files

* last.pth is able to resume training if train.py is interrupted (delete if training from scratch)
