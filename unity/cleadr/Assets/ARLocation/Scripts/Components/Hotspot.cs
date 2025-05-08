using System;
using UnityEngine;
using UnityEngine.Events;
using Logger = ARLocation.Utils.Logger;

namespace ARLocation
{
    using UI;

    [AddComponentMenu("AR+GPS/Hotspot")]
    [HelpURL("https://http://docs.unity-ar-gps-location.com/guide/#hotspot")]
    [DisallowMultipleComponent]
    public class Hotspot : MonoBehaviour
    {
        [Serializable]
        public class HotspotActivatedEvent : UnityEvent<GameObject, int> { }

        [Serializable]
        public class HotspotDeactivatedEvent : UnityEvent<int> { }

        [Serializable]
        public enum PositionModes
        {
            HotspotCenter,
            CameraPosition
        };

        [Serializable]
        public class HotspotSettingsData
        {
            [Tooltip("The prefab/GameObject that will be instantiated by the Hotspot.")]
            public GameObject Prefab;

            [Tooltip("The positioning mode. 'HotspotCenter' means the object will be instantiated at the Hotpot's center geo-location. 'CameraPosition' means it will be positioned at the front of the camera.")]
            public PositionModes PositionMode;

            [Tooltip("If true, align the instantiated object to face the camera (horizontally).")]
            public bool AlignToCamera = true;

            [Tooltip("If 'PositionMode' is set to 'CameraPosition', how far from the camera the instantiated object should be placed.")]
            public float DistanceFromCamera = 3.0f;

            [Tooltip("The distance from the center that the user must be located to activate the Hotspot.")]
            public float ActivationRadius = 4.0f;

            [Tooltip("If true, use raw GPS data, instead of the filtered GPS data.")]
            public bool UseRawLocation = false;

            [Tooltip("If true, destroys the prefab when the user leaves the hotspot radius.")]
            public bool DeactivateOnLeave = false;

            [Tooltip("If true, the deactivated hotspot can be reactivated again when the user re-enters the activated readius. "
                   + "Only has effect when \"Can Deactivate\" is true.")]
            [ConditionalProperty("DeactivateOnLeave")]
            public bool Reactivate = false;

            [Tooltip("The distance from the center that the user must be located to activate the Hotspot.")]
            [ConditionalProperty("DeactivateOnLeave")]
            public float DeactivationRadius = 4.0f;

            [Tooltip("An optional integer ID which is passed to the \"On Hotspot Activated With Id\" and \"On Hotspot Leave With Id\" events.")]
            public int Id = 0;
        }

        [Serializable]
        public class StateData
        {
            public GameObject Instance;
            public bool Activated;
            public Location Location;
            public Vector3 Position;
            public bool Positioned;
        }

        public PlaceAtLocation.LocationSettingsData LocationSettings = new PlaceAtLocation.LocationSettingsData();
        public HotspotSettingsData HotspotSettings = new HotspotSettingsData();

        [Tooltip("When set to true, will enable debug logging; it will also place a red cube at the hotspot location and draw a line from " + 
                "the user position to the hotspot, indicating the distance, in meters, on the screen.")]
        public bool DebugMode;

        [Header("Events")]

        [Tooltip("Event for the Hotspot is activated.")]
        public HotspotActivatedEvent OnHotspotActivated = new HotspotActivatedEvent();

        [Tooltip("This event will be emited only once, when the user leaves the hotspot area after it is activated.")]
        public HotspotDeactivatedEvent OnHotspotDeactivated = new HotspotDeactivatedEvent();

        public GameObject Instance => state.Instance;

        public Location Location
        {
            get => state.Location;
            set => state.Location = value;
        }

        public Vector3 Position
        {
            get
            {
                if (state.Activated)
                {
                    return state.Instance.transform.position;
                }
                else
                {
                    return state.Position;
                }
            }
        }

        public float currentDistance
        {
            get
            {
                return MathUtils.HorizontalDistance(Position, arCamera.transform.position);
            }
        }

        private StateData state = new StateData();
        private Camera arCamera;
        private ARLocationProvider arLocationProvider;
        private Transform arLocationRoot;
        private GameObject cube;
        private bool initialized;

        void Start()
        {
            if (!initialized)
            {
                Init();
            }
        }

        void createDebugCube()
        {
            if (DebugMode && cube == null)
            {
                cube = GameObject.CreatePrimitive(PrimitiveType.Cube);
                cube.GetComponent<Renderer>().material.color = Color.red;
                cube.AddComponent<DebugDistance>();
            }
        }

        void Deinit()
        {
            if (HotspotSettings.UseRawLocation)
            {
                arLocationProvider.Provider.LocationUpdatedRaw -= onLocationUpdated;
            }
            else
            {
                arLocationProvider.Provider.LocationUpdated -= onLocationUpdated;
            }

            if (cube != null)
            {
                Destroy(cube);
            }

            if (state.Instance != null)
            {
                Destroy(state.Instance);
                state.Activated = false;
            }

            initialized = false;
        }

        void Init()
        {
            state = new StateData();
            arLocationProvider = ARLocationProvider.Instance;
            arLocationRoot = ARLocationManager.Instance.gameObject.transform;

            if (arLocationProvider.Provider == null)
            {
                Logger.WarnFromMethod("Hotspot", "Init", "Provider is null!");
                return;
            }

            if (HotspotSettings.UseRawLocation)
            {
                arLocationProvider.Provider.LocationUpdatedRaw += onLocationUpdated;
            }
            else
            {
                arLocationProvider.Provider.LocationUpdated += onLocationUpdated;
            }

            if (state.Location == null)
            {
                state.Location = LocationSettings.GetLocation();
            }

            arCamera = ARLocationManager.Instance.MainCamera;

            if (arLocationProvider.IsEnabled)
            {
                onLocationUpdated(arLocationProvider.CurrentLocation, arLocationProvider.LastLocation);
            }

            if (DebugMode)
            {
                createDebugCube();
            }

            initialized = true;
        }

        void OnEnable()
        {
            Init();
        }

        void OnDisable()
        {
            Deinit();
        }

        public void Restart()
        {
            if (state.Instance != null)
            {
                Destroy(state.Instance);
            }

            state = new StateData();
        }

        void OnValidate()
        {
            if (HotspotSettings.DeactivationRadius < HotspotSettings.ActivationRadius)
            {
                HotspotSettings.DeactivationRadius = HotspotSettings.ActivationRadius;
            }
        }

        void Update()
        {
            if (!state.Positioned) return;

            var cam = arCamera.transform.position;
            cam.y = 0;

            var distance = Vector3.Distance(cam, state.Position);

            if (!state.Activated)
            {
                if (distance <= HotspotSettings.ActivationRadius)
                {
                    Activate();
                }
            }
            else if (HotspotSettings.DeactivateOnLeave)
            {
                if (distance > HotspotSettings.DeactivationRadius)
                {
                    Deactivate();
                }
            }

            if (DebugMode && cube != null)
            {
                cube.transform.position = state.Position;
            }
        }

        private void onLocationUpdated(LocationReading currentLocation, LocationReading lastLocation)
        {
            if (state.Activated) return;

            var pos = Location.GetGameObjectPositionForLocation(
                    arLocationRoot,
                    arCamera.transform,
                    arLocationProvider.CurrentLocation.ToLocation(),
                    state.Location, true);
            pos.y = 0;

            state.Positioned = true;
            state.Position = pos;

            if (DebugMode)
            {
                Logger.LogFromMethod("Hotspot", "onLocationUpdated",
                        $"Current Location = {currentLocation}, Position = {state.Position}");
            }
        }

        public void Activate()
        {
            if (HotspotSettings.Prefab == null)
            {
                Logger.WarnFromMethod("Hotspot", "Activate", "Prefab is null!");
                return;
            }

            state.Instance = Instantiate(
                    HotspotSettings.Prefab,
                    HotspotSettings.AlignToCamera ? transform : arLocationRoot);

            switch (HotspotSettings.PositionMode)
            {
                case PositionModes.HotspotCenter:
                    state.Instance.transform.position = state.Position;
                    break;

                case PositionModes.CameraPosition:
                    var transform1 = arCamera.transform;
                    var forward = transform1.forward;
                    forward.y = 0;
                    state.Instance.transform.position = transform1.position + forward * HotspotSettings.DistanceFromCamera;
                    break;
            }

            if (HotspotSettings.AlignToCamera)
            {
                state.Instance.transform.LookAt(arCamera.transform);
            }
            var groundHeight = state.Instance.AddComponent<GroundHeight>();

            if (state.Location.AltitudeMode == AltitudeMode.GroundRelative)
            {
                groundHeight.Settings.Altitude = (float)state.Location.Altitude;

            }

            state.Instance.name = name + " (Hotspot)";

            Logger.LogFromMethod("Hotspot", "ActivateHotspot", $"({name}): Hotspot activated", DebugMode);

            state.Activated = true;

            if (OnHotspotActivated != null)
            {
                OnHotspotActivated.Invoke(state.Instance, HotspotSettings.Id);
            }

            if (DebugMode && cube != null)
            {
                Destroy(cube);
                cube = null;
            }
        }

        public void Deactivate()
        {
            if (state.Instance == null) return;

            Destroy(state.Instance);
            state.Instance = null;

            if (HotspotSettings.Reactivate)
            {
                state.Activated = false;

                if (DebugMode && cube == null)
                {
                    createDebugCube();
                }
            }

            OnHotspotDeactivated.Invoke(HotspotSettings.Id);
        }

        public static Hotspot AddHotspotComponent(GameObject go, Location location, HotspotSettingsData settings)
        {
            var hotspot = go.AddComponent<Hotspot>();
            hotspot.Location = location.Clone();
            hotspot.HotspotSettings = settings;

            return hotspot;
        }

        public static Hotspot AddHotspotComponent(GameObject go, Location location, HotspotSettingsData settings, int id = 0)
        {
            settings.Id = id;
            return AddHotspotComponent(go, location, settings);
        }

        public static GameObject CreateHotspotGameObject(Location location, HotspotSettingsData settings,
            string name = "GPS Hotspot")
        {
            var go = new GameObject(name);

            AddHotspotComponent(go, location, settings);

            return go;
        }

        public static GameObject CreateHotspotGameObject(Location location, HotspotSettingsData settings,
            string name = "GPS Hotspot", int id = 0)
        {
            settings.Id = id;
            return CreateHotspotGameObject(location, settings, name);
        }
    }
}
