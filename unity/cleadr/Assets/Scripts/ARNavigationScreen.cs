using System;
using Newtonsoft.Json;
using TensorFlowLite;
using TMPro;
using Unity.XR.CoreUtils;
using UnityEngine;
using UnityEngine.Rendering;

public class ARNavigationScreen : MonoBehaviour
{
    public GameObject directionalLight;
    public XROrigin XROrigin;
    public Camera captureCamera;
    public TextMeshProUGUI debugText; // Debugging

    private Message message;

    // AR
    private Vector3 eulerRotationArrow, eulerRotationLaneChange, eulerRotationDirectionalLight;
    private Vector3 previousEulerRotationLaneChange;
    public GameObject[] arrowPrefabs; // turnLeft, turnRight
    public GameObject distancePrefab; // distance
    public GameObject laneChangePrefab; // targetLane

    // TFLite
    [SerializeField, FilePopup("*.tflite")] string current_lane_model = "current_lane_model.tflite";
    private Interpreter interpreter;
    private int width = 224;
    private int height = 224;
    private int[] inputTensorShape = { 1, 224, 224, 3 };
    private float[,,] inputs = new float[224, 224, 3];
    //private int[] outputTensorShape = { 1, 201, 18, 4 };
    private float[] outputs = new float[5];
    //private string[]? labels = { "" };

    private int current_lane; // current_lane comparing to target_lane
    private float confidence;

    private float timer = 0f;
    private float timerLimit = 0.5f;
    private RenderTexture renderTexture;
    private Texture2D capturedTexture;

    public void Start()
    {
        renderTexture = new RenderTexture(width, height, 24); // RGB: 8 bits x 3 channels
        capturedTexture = new Texture2D(width, height, TextureFormat.RGB24, false);
    }


    public void Update()
    {
        timer += Time.deltaTime;

#if DEBUG
        string maneuver = "turnLeft";
        int distance = 300;
        int target_lane = 1;

        Render($"{{\"maneuver\": \"{maneuver}\", \"distance\": {distance}, \"target_lane\": {target_lane}}}");
#endif
    }

#if DEBUG
    // Debugging
    void OnGUI()
    {
        // Show capture camera frame on the top right corner
        Vector2 size = new Vector2(width, height);

        if (capturedTexture != null)
        {
            float x = Screen.width - size.x - 10; // Position at top-right with a margin of 10px
            float y = 10; // Top margin

            GUI.DrawTexture(new Rect(x, y, size.x, size.y), capturedTexture);
        }
    }
#endif

    public void Render(string jsonMessage)
    {
#if DEBUG
        // Simulate Google Maps API
        if (timer > 0.5)
        {
#endif
            // Flutter to Unity JSON Message
            message = JsonConvert.DeserializeObject<Message>(jsonMessage);
            debugText.text = "";

#if DEBUG
            DebugLog("jsonMessage received: " + jsonMessage);
            DebugLog("jsonMessage parsed: maneuver = " + message.maneuver + ", distance = " + message.distance + ", targetLane = " + message.target_lane);
#endif

            // Render AR Prefabs: Initialisation
            // Initialise EulerRotation and 
            eulerRotationArrow = eulerRotationLaneChange = eulerRotationDirectionalLight = XROrigin.Camera.transform.rotation.eulerAngles;
            eulerRotationDirectionalLight.x += 50; eulerRotationDirectionalLight.y += -30;
            directionalLight.transform.position = XROrigin.Camera.transform.position + XROrigin.Camera.transform.up * 3.0f;
            directionalLight.transform.rotation = Quaternion.Euler(eulerRotationDirectionalLight);

            // Initialise Prefabs
            for (int prefab = 0; prefab < arrowPrefabs.Length; prefab++)
            {
                arrowPrefabs[prefab].SetActive(false);
            }
            distancePrefab.SetActive(false);
            if (message.target_lane == null)
            {
                laneChangePrefab.SetActive(false);
            }

            // Initialise Maneuver
            switch (message.maneuver)
            {
                case "turnLeft":
                    eulerRotationArrow.y += -90f;
                    break;

                case "turnRight":
                    eulerRotationArrow.y += 90f;
                    break;

                default:
                    return;
            }

            // Render AR Prefabs: Logic
            // turnLeftRightPrefabs
            if (message.distance > 200 && message.distance <= 500)
            {
                // blueArrowPrefab (turnLeftRightPrefabs[0])
                arrowPrefabs[0].transform.position = XROrigin.Camera.transform.position
                                                           + XROrigin.Camera.transform.forward * 16.0f
                                                           + XROrigin.Camera.transform.up * 1.0f;
                arrowPrefabs[0].transform.rotation = Quaternion.Euler(eulerRotationArrow);

                distancePrefab.transform.position = XROrigin.Camera.transform.position
                                                  + XROrigin.Camera.transform.forward * 16.0f
                                                  + XROrigin.Camera.transform.up * 0.3f;

                arrowPrefabs[0].SetActive(true);
            }
            else if (message.distance > 50 && message.distance <= 200)
            {
                // yellowArrowPrefab (turnLeftRightPrefabs[1])
                arrowPrefabs[1].transform.position = XROrigin.Camera.transform.position
                                                           + XROrigin.Camera.transform.forward * 8.0f
                                                           + XROrigin.Camera.transform.up * 1.0f;
                arrowPrefabs[1].transform.rotation = Quaternion.Euler(eulerRotationArrow);

                distancePrefab.transform.position = XROrigin.Camera.transform.position
                                                  + XROrigin.Camera.transform.forward * 8.0f
                                                  + XROrigin.Camera.transform.up * 0.3f;

                arrowPrefabs[1].SetActive(true);
            }
            else if (message.distance > 0 && message.distance <= 50)
            {
                // redArrowPrefab (turnLeftRightPrefabs[2])
                arrowPrefabs[2].transform.position = XROrigin.Camera.transform.position
                                                           + XROrigin.Camera.transform.forward * 4.0f
                                                           + XROrigin.Camera.transform.up * 0.5f;
                arrowPrefabs[2].transform.rotation = Quaternion.Euler(eulerRotationArrow);

                distancePrefab.transform.position = XROrigin.Camera.transform.position
                                                  + XROrigin.Camera.transform.forward * 4.0f
                                                  + XROrigin.Camera.transform.up * -0.2f;

                arrowPrefabs[2].SetActive(true);
            }

            // distancePrefab
            distancePrefab.GetComponentInChildren<TextMeshPro>().text = (message.distance).ToString() + "m";
            distancePrefab.transform.rotation = Quaternion.Euler(eulerRotationLaneChange); // Unaltered eulerRotation
            distancePrefab.SetActive(true);

            // laneChangePrefab
            if (message.target_lane != null)
            {
                // target_lane_model
                if (interpreter == null)
                {
                    /*
                     * MAY ARISE SOME ISSUES DUE TO ANDROID
                     * - labels
                     * 
                     */

                    // Initialise Interpreter
                    interpreter = new Interpreter(FileUtil.LoadFile(current_lane_model), new InterpreterOptions());
                    interpreter.ResizeInputTensor(0, inputTensorShape);
                    interpreter.AllocateTensors();

                    // labels = System.IO.File.ReadAllLines(System.IO.Path.Combine(Application.streamingAssetsPath, "labels.txt"));

#if DEBUG
                    if (interpreter != null)
                    {
                        DebugLog($"Interpreter ({current_lane_model}) - Successfully initialised");
                    }
                    else
                    {
                        DebugLog($"Interpreter ({current_lane_model}) - Failed");
                    }

                    //if (labels != null)
                    //{
                    //    DebugLog($"Labels ({current_lane_model}) - successfully initialised");
                    //}
                    //else
                    //{
                    //    DebugLog($"Labels ({current_lane_model}) - failed");
                    //}
#endif
                }

                laneChangePrefab.transform.position = XROrigin.Camera.transform.position
                                    + XROrigin.Camera.transform.forward * 4.0f
                                    + XROrigin.Camera.transform.up * -1.5f;
                laneChangePrefab.transform.rotation = Quaternion.Euler(previousEulerRotationLaneChange);

                if (timer >= timerLimit)
                {
                    CaptureCameraFrame(); // Captures the live camera frame every 0.5 seconds

                    // Run Inference
                    interpreter.SetInputTensorData(0, inputs);
                    interpreter.Invoke();
                    interpreter.GetOutputTensorData(0, outputs);

                    var inference = ProcessOutputs();
                    current_lane = inference.ClassIndex + 1;
                    confidence = inference.Confidence;
                    timer = 0.0f;

#if DEBUG
                    DebugLog("Inference Results: " + string.Join(", ", outputs));

                    if (confidence >= 0.5)
                    {
                        DebugLog($"Lane {current_lane}: {confidence:F4}");
                    }
#endif
                    //Render laneChangePrefab only if confidence is greater or equal than 50%
                    if (confidence >= 0.5)
                    {
                        if (current_lane != message.target_lane)
                        {
                            // Lane change left
                            if (current_lane > message.target_lane)
                            {
                                eulerRotationLaneChange.z += 90;
                            }
                            // Lane change right
                            else if (current_lane < message.target_lane)
                            {
                                eulerRotationLaneChange.z += -90;
                            }

                            previousEulerRotationLaneChange = eulerRotationLaneChange;

                            laneChangePrefab.transform.rotation = Quaternion.Euler(eulerRotationLaneChange);
                            laneChangePrefab.SetActive(true);
                        }
                    }
                    else
                    {
                        laneChangePrefab.SetActive(false);
                    }
                }
            }
#if DEBUG
        }
#endif
    }

    public void DebugLog(string message)
    {
        Debug.Log(message);
        debugText.text += message + "\n";
    }

    public void CaptureCameraFrame()
    {
        captureCamera.targetTexture = renderTexture;
        captureCamera.Render();

        // Copy GPU texture to CPU
        AsyncGPUReadback.Request(renderTexture, 0, TextureFormat.RGB24, OnCaptureCameraFrameCompleteReadback);

        captureCamera.targetTexture = null;
    }

    void OnCaptureCameraFrameCompleteReadback(AsyncGPUReadbackRequest request)
    {
        if (request.hasError) return;

        if (capturedTexture != null)
        {
            capturedTexture.LoadRawTextureData(request.GetData<byte>());
            capturedTexture.Apply();

            // Process Image (capturedTexture) to Array Values (outputs)
            TextureToFloatArray(capturedTexture);
        }
    }

    public void TextureToFloatArray(Texture2D capturedTexture)
    {
        // Standard mean and std for image classification
        float[] mean = { 0.485f, 0.456f, 0.406f };
        float[] std = { 0.229f, 0.224f, 0.225f };

        Color32[] pixels = capturedTexture.GetPixels32();

        // Process each pixel
        int index;
        Color32 pixel;
        float r, g, b;
        for (int y = 0; y < height; y++)
        {
            for (int x = 0; x < width; x++)
            {
                // Get pixel
                index = y * width + x;
                pixel = pixels[index];

                // Convert to range [0, 1]
                r = pixel.r / 255.0f;
                g = pixel.g / 255.0f;
                b = pixel.b / 255.0f;

                // Normal mean and std
                //inputs[x, y, 0] = r; // Normalize Red
                //inputs[x, y, 1] = g; // Normalize Green
                //inputs[x, y, 2] = b; // Normalize Blue

                // Standard mean and std
                inputs[x, y, 0] = (r - mean[0]) / std[0];
                inputs[x, y, 1] = (g - mean[1]) / std[1];
                inputs[x, y, 2] = (b - mean[2]) / std[2];
            }
        }
    }

    public (int ClassIndex, float Confidence) ProcessOutputs()
    {
        if (outputs == null || outputs.Length == 0)
            throw new ArgumentException("ProcessOutputs() - Failed: Outputs array cannot be null or empty");

        float[] probabilities;
        float sum;
        int maxIndex;
        float maxConfidence;

        // Softmax Normalisation
        probabilities = new float[outputs.Length];
        sum = 0f;

        // Logits -> Probits
        // Calculate exp for each element and sum
        for (int i = 0; i < outputs.Length; i++)
        {
            probabilities[i] = MathF.Exp(outputs[i]);
            sum += probabilities[i];
        }
        // Normalize to get probabilities
        for (int i = 0; i < probabilities.Length; i++)
        {
            probabilities[i] /= sum;
        }

        // current_lane
        // Find max probability (confidence) and its index
        maxIndex = 0;
        maxConfidence = probabilities[0];

        for (int i = 1; i < probabilities.Length; i++)
        {
            if (probabilities[i] > maxConfidence)
            {
                maxConfidence = probabilities[i];
                maxIndex = i;
            }
        }

        return (maxIndex, maxConfidence); // 0-based index and confidence score
    }

    public class Message
    {
        public string maneuver { get; set; }
        public int? distance { get; set; }
        public int? target_lane { get; set; }
    }
}
