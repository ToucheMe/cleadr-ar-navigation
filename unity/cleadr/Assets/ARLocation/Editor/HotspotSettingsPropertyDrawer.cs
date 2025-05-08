using UnityEngine;
using UnityEditor;

namespace ARLocation
{
    [CustomPropertyDrawer(typeof(Hotspot.HotspotSettingsData))]
    public class HotspotSettingsPropertyDrawer : PropertyDrawer
    {
        private SerializedProperty prefab;
        private SerializedProperty positionMode;
        private SerializedProperty alignToCamera;
        private SerializedProperty distanceFromCamera;
        private SerializedProperty activationRadius;
        private SerializedProperty useRawLocation;
        private SerializedProperty canDeactivate;
        private SerializedProperty canReactivate;
        private SerializedProperty deactivationRadius;
        private SerializedProperty id;
        bool open;

        private int padding = 4;

        void findSerializedProperties(SerializedProperty property)
        {
            prefab = property.FindPropertyRelative("Prefab");
            positionMode = property.FindPropertyRelative("PositionMode");
            alignToCamera = property.FindPropertyRelative("AlignToCamera");
            distanceFromCamera = property.FindPropertyRelative("DistanceFromCamera");
            activationRadius = property.FindPropertyRelative("ActivationRadius");
            useRawLocation = property.FindPropertyRelative("UseRawLocation");
            canDeactivate = property.FindPropertyRelative("DeactivateOnLeave");
            canReactivate = property.FindPropertyRelative("Reactivate");
            deactivationRadius = property.FindPropertyRelative("DeactivationRadius");
            id = property.FindPropertyRelative("Id");
        }

        public override void OnGUI(Rect position, SerializedProperty property, GUIContent label)
        {
            findSerializedProperties(property);

            var contentHeight = EditorGUIUtility.singleLineHeight;
            var lineHeight = EditorGUIUtility.singleLineHeight + padding;
            
            position.height = lineHeight;
            open = EditorGUI.BeginFoldoutHeaderGroup(position, open, label);

            if (open)
            {
                EditorGUI.indentLevel++;
                
                position.y += lineHeight;
                position.height = contentHeight;
                
                EditorGUI.PropertyField(position, prefab);
                position.y += lineHeight;

                EditorGUI.PropertyField(position, positionMode);
                position.y += lineHeight;

                EditorGUI.PropertyField(position, alignToCamera);
                position.y += lineHeight;

                EditorGUI.PropertyField(position, distanceFromCamera);
                position.y += lineHeight;

                EditorGUI.PropertyField(position, activationRadius);
                position.y += lineHeight;
                
                EditorGUI.PropertyField(position, canDeactivate);
                position.y += lineHeight;

                if (canDeactivate.boolValue)
                {
                    EditorGUI.indentLevel++;
                    
                    EditorGUI.PropertyField(position, deactivationRadius);
                    position.y += lineHeight;
                    
                    EditorGUI.PropertyField(position, canReactivate);
                    position.y += lineHeight;
                    
                    EditorGUI.indentLevel--;
                }

                EditorGUI.PropertyField(position, useRawLocation);
                position.y += lineHeight;

                EditorGUI.PropertyField(position, id);
                position.y += lineHeight;

                EditorGUI.indentLevel--;
            }

            EditorGUI.EndFoldoutHeaderGroup();
        }

        public override float GetPropertyHeight(SerializedProperty property, GUIContent label)
        {
            findSerializedProperties(property);

            var lineHeight = EditorGUIUtility.singleLineHeight + padding;
            var height = lineHeight;

            if (!open)
            {
                return height;
            }

            if (canDeactivate.boolValue)
            {
                height += 10 * lineHeight;
            }
            else
            {
                height += 8 * lineHeight;
            }

            return height;
        }
    }
}
