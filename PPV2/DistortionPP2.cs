using System;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[Serializable]
[PostProcess(typeof(DistortionPP2Renderer), PostProcessEvent.AfterStack, "Custom/Distortion")]
public sealed class DistortionPP2 : PostProcessEffectSettings
{
    [Range(0f, 0.2f), Tooltip("Distortion effect intensity")]
    public FloatParameter scale = new FloatParameter {value = 0.01f};

}

public sealed class DistortionPP2Renderer : PostProcessEffectRenderer<DistortionPP2>
{
    public override DepthTextureMode GetCameraFlags()
    {
        return DepthTextureMode.Depth;
    }

    public override void Render(PostProcessRenderContext context)
    {
        var sheet = context.propertySheets.Get(Shader.Find("Hidden/Custom/DistortionPP2"));
        sheet.properties.SetFloat("_Scale", settings.scale);
        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
    }
}