using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;


public class RF_TintRendererFeature : ScriptableRendererFeature
{
    class TintPass : ScriptableRenderPass
    {
        private static readonly int m_BlitScaleBiasID = Shader.PropertyToID("_BlitScaleBias");

            private static readonly int m_BlitTextureID = Shader.PropertyToID("_BlitTextureID");
        private static MaterialPropertyBlock s_SharedPropertyBlock = null;
        private string m_PassName;
        // public Material m_BlitMaterial;

        private Material m_Material;
        // private string m_PassName;
        private ProfilingSampler m_Sampler;
        public int passIndex = 0;

        private class PassData
        {
            internal Material material;
            internal TextureHandle source;
        }
        public void Setup(Material material)
        {
            m_Material = material;
            // requiresIntermediateTexture = true;
        }

        public TintPass(Material mat, string name)
        {
            m_PassName = name;
            m_Material = mat;
            m_Sampler ??= new ProfilingSampler(GetType().Name + "_" + name);
        }
        // RecordRenderGraph is where the RenderGraph handle can be accessed, through which render passes can be added to the graph.
        // FrameData is a context container through which URP resources can be accessed and managed.
        public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
        {
            var stack = VolumeManager.instance.stack;
            var customEffect = stack.GetComponent<SphereVolumeComponent>();

            if (!customEffect.IsActive())
            {
                return;
            }

            UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();

            if (resourceData.isActiveTargetBackBuffer)
            {
                Debug.LogError("Skipping render pass. RF_TintEffectRenderFeature requires an intermediate ColorTexture, we cant use the back buffer as a texture input");
                return;
            }

            var colCopyDesc = renderGraph.GetTextureDesc(resourceData.afterPostProcessColor);
            colCopyDesc.name = $"CameraColor-{m_PassName}";
            TextureHandle copiedColorTexture = renderGraph.CreateTexture(colCopyDesc);
            using (var builder = renderGraph.AddRasterRenderPass<PassData>(m_PassName + "_CopyPass", out var passData, m_Sampler))
            {
                passData.source = resourceData.activeColorTexture;
                builder.UseTexture(resourceData.activeColorTexture, AccessFlags.Read);
                builder.SetRenderAttachment(copiedColorTexture, 0, AccessFlags.Write);
                builder.SetRenderFunc((PassData data, RasterGraphContext rgContext) => ExecuteCopyColorPass(rgContext.cmd, data.source));
            }

            using (var builder = renderGraph.AddRasterRenderPass<PassData>(m_PassName + "_FullScreenPass", out var passData, m_Sampler))
            {
                passData.source = resourceData.activeColorTexture;
                passData.material = m_Material;
                builder.UseTexture(copiedColorTexture, AccessFlags.Read);
                builder.SetRenderAttachment(resourceData.activeColorTexture, 0,
                AccessFlags.Write);
                builder.SetRenderFunc(
                (PassData data, RasterGraphContext rgContext) => ExecuteMainPass(rgContext.cmd, data.material, passIndex, data.source));
            }
        }

        private static void ExecuteCopyColorPass(RasterCommandBuffer cmd, RTHandle sourceTexture)
        {
            Blitter.BlitTexture(cmd, sourceTexture, new Vector4(1, 1, 0, 0), 0.0f, false);
        }
        private static void ExecuteMainPass(RasterCommandBuffer cmd, Material material, int passIndex, RTHandle copiedColor)
        {
            // Clear any previous properties in the shared property block
            s_SharedPropertyBlock.Clear();

            // Set the _BlitScaleBias property if needed
            s_SharedPropertyBlock.SetVector(m_BlitScaleBiasID, new Vector4(1, 1, 0, 0));

            // Set the copiedColor texture in the material's property block if it is not null
            if (copiedColor != null)
            {
                s_SharedPropertyBlock.SetTexture(m_BlitTextureID, copiedColor);
            }

            // material.SetColor("_TintColor", Color.red);

            // Perform the drawing operation with the procedural mesh and material
            cmd.DrawProcedural(Matrix4x4.identity, material, passIndex, MeshTopology.Triangles, 3, 1, s_SharedPropertyBlock);
        }

        // private static void ExecuteMainPass(RasterCommandBuffer cmd, Material material, int passIndex, RTHandle copiedColor)
        // {
        //     s_SharedPropertyBlock.Clear();
        //     s_SharedPropertyBlock.SetVector(m_BlitScaleBiasID, new Vector4(1, 1, 0, 0));
        //     cmd.DrawProcedural(Matrix4x4.identity, material, passIndex, MeshTopology.Triangles,
        //     3, 1, s_SharedPropertyBlock);
        // }
    }

    public RenderPassEvent injectionPoint = RenderPassEvent.AfterRenderingPostProcessing;
    public Material passMaterial;
    public ScriptableRenderPassInput requirements = ScriptableRenderPassInput.Color;

    TintPass m_pass;
    public override void Create()
    {
        m_pass = new TintPass(passMaterial, name);
        m_pass.renderPassEvent = injectionPoint;
        m_pass.ConfigureInput(requirements);
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (passMaterial == null)
        {
            Debug.LogWarning("RF_DitherEffectRenderFeature material is null and will be skipped.");
            return;
        }

        m_pass.Setup(passMaterial);
        renderer.EnqueuePass(m_pass);
    }
}

