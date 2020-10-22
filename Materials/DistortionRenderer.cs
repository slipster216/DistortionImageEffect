using UnityEngine;
using System.Collections;
using System;

// render distortions into a buffer, then distort screen as an image effect. 
// avoids grabpass, and can use low res buffer for distortion information

// Currently does not work with shadows on lights - because of a unity bug
// http://issuetracker.unity3d.com/issues/camera-camera-dot-render-clears-cameradepthtexture-if-theres-a-shadow-casting-directional-light-in-the-scene

namespace Jbooth
{
   [RequireComponent(typeof(Camera))]
   public class DistortionRenderer : MonoBehaviour
   {
      [Tooltip("Layer to render in low resolution")]
      public LayerMask distortionLayers;
      public enum Factor
      {
         Half = 2,
         Quarter = 4,
         Eighth = 8
      }
      [Tooltip("How much should we scale down the rendering. Lower scales have greater chances of artifacting, but better performance")]
      public Factor factor = Factor.Half;
      
      Camera parentCamera; 
      Camera effectCamera;
      RenderTexture distortionRT;
      
      void EnforceCamera()
      {
         effectCamera.CopyFrom(parentCamera);
         effectCamera.renderingPath = RenderingPath.Forward; // force forward
         effectCamera.cullingMask = distortionLayers;
         effectCamera.clearFlags = CameraClearFlags.Nothing;
         effectCamera.depthTextureMode = DepthTextureMode.None;
         effectCamera.useOcclusionCulling = false;
         effectCamera.backgroundColor = new Color(0.5f, 0.5f, 1, 0);
         effectCamera.clearFlags = CameraClearFlags.Color;
         effectCamera.targetTexture = distortionRT;
         
         if (distortionRT == null)
         {
            distortionRT = new RenderTexture(Screen.width / (int) factor, Screen.height / (int) factor, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
         }
         else if (distortionRT.width != Screen.width / (int) factor ||
                  distortionRT.height != Screen.height / (int) factor)
         {
            RenderTexture.Destroy(distortionRT);
            distortionRT = new RenderTexture(Screen.width / (int) factor, Screen.height / (int) factor, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
         }

         distortionRT.wrapMode = TextureWrapMode.Clamp;
         
         effectCamera.targetTexture = distortionRT;
         
         Shader.SetGlobalTexture("gDistortionBuffer", distortionRT);
      }

      private void OnDisable()
      {
         if (distortionRT != null)
         {
            RenderTexture.Destroy(distortionRT);
         }

         if (effectCamera != null)
         {
            DestroyImmediate(effectCamera);
         }
      }

      void OnEnable()
      {
         if (parentCamera == null)
         {
            parentCamera = GetComponent<Camera>();
         }

         // setup cameras
         if (effectCamera == null)
         {
            effectCamera = new GameObject("DistortionCam", typeof(Camera)).GetComponent<Camera>();
            effectCamera.transform.parent = parentCamera.transform;
            effectCamera.hideFlags = HideFlags.HideAndDontSave;
            effectCamera.depth = parentCamera.depth - 1;
         }

         EnforceCamera();
      }

      private void LateUpdate()
      {
         EnforceCamera();
      }
   }
}