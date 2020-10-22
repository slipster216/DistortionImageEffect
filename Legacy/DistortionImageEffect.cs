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
   public class DistortionImageEffect : MonoBehaviour
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
      public Shader compositeShader;
      private Material compositeMaterial;
      private Camera effectCamera;
      private Camera mCamera;
      [Range(0.0f, 0.2f)]
      public float distortionScale = 0.01f;

      
      [Serializable]
      public class DebugOptions
      {
         [Tooltip("Draws buffers in top-left side of screen for debugging")]
         public bool debugDrawBuffers;
      }
      
      public DebugOptions debugOptions = new DebugOptions();

      void Start()
      {
         mCamera = GetComponent<Camera>();
         mCamera.depthTextureMode |= DepthTextureMode.Depth;
      }

      void OnDisable()
      {
         if (compositeMaterial != null)
         {
            DestroyImmediate(compositeMaterial);
         }
      }

      void EnforceCamera()
      {
         effectCamera.CopyFrom(mCamera);
         effectCamera.renderingPath = RenderingPath.Forward; // force forward
         effectCamera.cullingMask = distortionLayers;
         effectCamera.clearFlags = CameraClearFlags.Nothing;
         effectCamera.depthTextureMode = DepthTextureMode.None;
         effectCamera.useOcclusionCulling = false;
         effectCamera.backgroundColor = new Color(0.5f, 0.5f, 1, 0);
         effectCamera.clearFlags = CameraClearFlags.Color;
      }

      void OnRenderImage(RenderTexture src, RenderTexture dest)
      {
         // make sure everything is assigned correctly
         if (!enabled || compositeShader == null)
         {
            if (compositeShader == null)
            {
               Debug.Log("DistortionImageEffect: composite shader not assigned");
            }
            Graphics.Blit(src, dest);
            return;
         }
         
         UnityEngine.Profiling.Profiler.BeginSample("Distortion Image Effect");
         // setup materials
         if (compositeMaterial == null)
         {
            compositeMaterial = new Material(compositeShader);
         }

         // setup cameras
         if (effectCamera == null)
         {
            effectCamera = new GameObject("DistortionCam", typeof(Camera)).GetComponent<Camera>();
            effectCamera.enabled = false;
            effectCamera.transform.parent = this.transform;
            effectCamera.targetTexture = dest;
         }

         
         // render distortions into buffer
         UnityEngine.Profiling.Profiler.BeginSample("Render Distortion");
         RenderTexture distortionRT = RenderTexture.GetTemporary(Screen.width / (int)factor, Screen.height / (int)factor, 0);
         EnforceCamera();
         effectCamera.targetTexture = distortionRT;
         effectCamera.Render();

         UnityEngine.Profiling.Profiler.EndSample();

         compositeMaterial.SetTexture("_MainTex", src);
         compositeMaterial.SetTexture("_DistortionRT", distortionRT);
         compositeMaterial.SetFloat("_DistortionScale", distortionScale);

         UnityEngine.Profiling.Profiler.BeginSample("Composite");
         Graphics.Blit(src, dest, compositeMaterial);
         UnityEngine.Profiling.Profiler.EndSample();
         
         
         
         if (debugOptions.debugDrawBuffers)
         {
            GL.PushMatrix();
            GL.LoadPixelMatrix(0, Screen.width, Screen.height, 0);
            Graphics.DrawTexture(new Rect(0, 0, 128, 128), distortionRT);
            GL.PopMatrix();
         }
         
         // cleanup
         RenderTexture.ReleaseTemporary(distortionRT);
         UnityEngine.Profiling.Profiler.EndSample();
         
      }
   }
}