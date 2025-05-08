#if UNITY_2022_2_OR_NEWER
    #define ARGPS_ARF5
#endif

using UnityEngine;
using UnityEditor;

#if !ARGPS_USE_VUFORIA
using UnityEngine.XR.ARFoundation;

#if ARGPS_ARF5
using Unity.XR.CoreUtils;
#endif
#endif

namespace ARLocation
{
    public static class GameObjectMenuItems{

        [MenuItem("GameObject/AR+GPS/ARLocationRoot", false, 20)]
        public static void CreateARLocationRoot()
        {
#if ARGPS_ARF5
            var go = new GameObject("ARLocationRoot");

            go.AddComponent<ARLocationManager>();
            go.AddComponent<ARLocationProvider>();

            var arSessionOrigin = Object.FindObjectOfType<XROrigin>(); 
            if (arSessionOrigin != null)
            {
                go.transform.SetParent(arSessionOrigin.transform);
            }
            else
            {
                Debug.LogWarning("[ARLocation][CreateARLocationRoot] XROrigin not found!");
            }
#else
            var go = new GameObject("ARLocationRoot");

            go.AddComponent<ARLocationManager>();
            go.AddComponent<ARLocationProvider>();

            var arSessionOrigin = GameObject.Find("AR Session Origin");

            if (arSessionOrigin != null)
            {
                go.transform.SetParent(arSessionOrigin.transform);
            }
#endif
        }

        [MenuItem("GameObject/AR+GPS/GPS Stage Object", false, 20)]
        public static GameObject CreateGpsStageObject()
        {
            var go = new GameObject("GPS Stage Object");

            go.AddComponent<PlaceAtLocation>();

            return go;
        }

        [MenuItem("GameObject/AR+GPS/GPS Hotspot Object", false, 20)]
        public static GameObject CreateGpsHotspotObject()
        {
            var go = new GameObject("GPS Hotspot Object");

            go.AddComponent<Hotspot>();

            return go;
        }

#if ARGPS_DEV_MODE
        [MenuItem("Assets/Print GUID", false)]
        public static void PrintGuit()
        {
            foreach (var s in Selection.assetGUIDs)
            {
                Debug.Log(s);
            }
        }
#endif

        [MenuItem("GameObject/AR+GPS/Create Basic Scene Structure", false, 20)]
        public static void CreateBasicScene()
        {
#if ARGPS_USE_VUFORIA
            EditorApplication.ExecuteMenuItem("GameObject/Vuforia Engine/AR Camera");
            Selection.activeObject = null;
            EditorApplication.ExecuteMenuItem("GameObject/Vuforia Engine/Ground Plane/Plane Finder");

            CreateARLocationRoot();
            var stage = CreateGpsStageObject();

            var capsule = GameObject.CreatePrimitive(PrimitiveType.Capsule);
            capsule.transform.SetParent(stage.transform);
#else

#if ARGPS_ARF5
            var prevMain = GameObject.FindWithTag("MainCamera");
            if (prevMain)
            {
                Object.DestroyImmediate(prevMain);
            }

            EditorApplication.ExecuteMenuItem("GameObject/XR/AR Session");
            Selection.activeObject = null;
            EditorApplication.ExecuteMenuItem("GameObject/XR/XR Origin (Mobile AR)");
            Selection.activeObject = null;
            EditorApplication.ExecuteMenuItem("GameObject/AR+GPS/ARLocationRoot");

            

            var arSessionOrigin = Object.FindObjectOfType<XROrigin>().gameObject;
            arSessionOrigin.AddComponent<ARPlaneManager>();

            var stage = CreateGpsStageObject();
            var capsule = GameObject.CreatePrimitive(PrimitiveType.Capsule);
            capsule.transform.SetParent(stage.transform);
#else
            var prevMain = GameObject.FindWithTag("MainCamera");
            if (prevMain)
            {
                Object.DestroyImmediate(prevMain);
            }

            EditorApplication.ExecuteMenuItem("GameObject/XR/AR Session");
            Selection.activeObject = null;
            EditorApplication.ExecuteMenuItem("GameObject/XR/AR Session Origin");
            Selection.activeObject = null;
            EditorApplication.ExecuteMenuItem("GameObject/AR+GPS/ARLocationRoot");

            var cam = GameObject.Find("AR Camera");

            if (cam)
            {
                cam.tag = "MainCamera";
                var camera = cam.GetComponent<Camera>();
                camera.farClipPlane = 1000.0f;
            }

            var arSessionOrigin = Object.FindObjectOfType<ARSessionOrigin>().gameObject;
            arSessionOrigin.AddComponent<ARPlaneManager>();

            var stage = CreateGpsStageObject();
            var capsule = GameObject.CreatePrimitive(PrimitiveType.Capsule);
            capsule.transform.SetParent(stage.transform);
#endif
#endif
        }
    }
}
