HEADER
{
	Description = "Simple shader that makes use of a model's vertex colors as lighting. Requires a full recompile of the model after setting at least one of its materials to this shader or any other shader that also uses vertex colors.";
	Version = 1;
}

MODES
{
	VrForward();
	Depth(); 
	ToolsVis( S_MODE_TOOLS_VIS );
	ToolsWireframe( "vr_tools_wireframe.shader" );
	ToolsShadingComplexity( "vr_tools_shading_complexity.shader" );
}

FEATURES
{
	#include "vr_common_features.fxc"

	Feature( F_TEXTURE_FILTERING, 0..4 ( 0="Anisotropic", 1="Bilinear", 2="Trilinear", 3="Point Sample", 4="Nearest Neighbour" ), "Texture Filtering" );
	Feature( F_WRAPPING_U, 0..4 ( 0="Wrap", 1="Mirror", 2="Clamp", 3="Border", 4="Mirror Once" ), "Texture Wrapping U" );
	Feature( F_WRAPPING_V, 0..4 ( 0="Wrap", 1="Mirror", 2="Clamp", 3="Border", 4="Mirror Once" ), "Texture Wrapping V" );
	Feature( F_WRAPPING_W, 0..4 ( 0="Wrap", 1="Mirror", 2="Clamp", 3="Border", 4="Mirror Once" ), "Texture Wrapping W" );
}

COMMON
{
	#define BLEND_MODE_ALREADY_SET
	#define CUSTOM_MATERIAL_INPUTS

	#include "common/shared.hlsl"
}

struct VertexInput
{
	#include "common/vertexinput.hlsl"

	float4 vColor : COLOR0 < Semantic( Color ); >;
};

struct PixelInput
{
	#include "common/pixelinput.hlsl"
};

VS
{
	#include "common/vertex.hlsl"

	// Old code, use if VextorText gets a better descriptive means, such as configurable text above the sliders.
	//float3 g_vVertexColorBrightness < UiType( VectorText ); Default3( 1.0, 1.0, 1.0 ); UiGroup( "Vertex Color Brightness,0/2" ); Range3( -10000, -10000, -10000, 10000, 10000, 10000); >;
	//Float3Attribute( g_vVertexColorBrightness, g_vVertexColorBrightness );
	
	// Old code, use if VextorText gets a better descriptive means, such as configurable text above the sliders.
	//float3 g_vVertexColorSaturation < UiType( VectorText ); Default3( 1.0, 1.0, 1.0 ); UiGroup( "Vertex Color Saturation,0/3" ); Range3( 0, 0, 0, 1000, 1000, 1000); >;
	//Float3Attribute( g_vVertexColorSaturation, g_vVertexColorSaturation );

	float g_vBrightnessRed < UiType( Slider ); Default( 1.0 ); UiGroup( "Vertex Color Brightness,0/Colors,0/1" ); Range( -8000, 8000 ); >;
	FloatAttribute( g_vBrightnessRed, g_vBrightnessRed );
	float g_vBrightnessGreen < UiType( Slider ); Default( 1.0 ); UiGroup( "Vertex Color Brightness,0/Colors,0/2" ); Range( -8000, 8000 ); >;
	FloatAttribute( g_vBrightnessGreen, g_vBrightnessGreen );
	float g_vBrightnessBlue < UiType( Slider ); Default( 1.0 ); UiGroup( "Vertex Color Brightness,0/Colors,0/3" ); Range( -8000, 8000 ); >;
	FloatAttribute( g_vBrightnessBlue, g_vBrightnessBlue );

	float g_vSaturationRed < UiType( Slider ); Default( 1.0 ); UiGroup( "Vertex Color Saturation,1/Colors,1/1" ); Range( 0, 1000 ); >;
	FloatAttribute( g_vSaturationRed, g_vSaturationRed );
	float g_vSaturationGreen < UiType( Slider ); Default( 1.0 ); UiGroup( "Vertex Color Saturation,1/Colors,1/2" ); Range( 0, 1000 ); >;
	FloatAttribute( g_vSaturationGreen, g_vSaturationGreen );
	float g_vSaturationBlue < UiType( Slider ); Default( 1.0 ); UiGroup( "Vertex Color Saturation,1/Colors,1/3" ); Range( 0, 1000 ); >;
	FloatAttribute( g_vSaturationBlue, g_vSaturationBlue );

	PixelInput MainVs( VertexInput i )
	{
		PixelInput o = ProcessVertex( i );
		
		o.vVertexColor.rgb = SrgbGammaToLinear( i.vColor.rgb );
		o.vVertexColor.rgb *= pow(o.vVertexColor.rgb, (float3(g_vSaturationRed, g_vSaturationGreen, g_vSaturationBlue) - 1));
		o.vVertexColor.rgb *= float3(g_vBrightnessRed, g_vBrightnessGreen, g_vBrightnessBlue);
		o.vVertexColor.a =  i.vColor.a;

		return FinalizeVertex( o );
	}
}

PS
{
	#include "common/pixel.hlsl"
	
	// Sampler for all textures
	SamplerState g_sTexSampler < // got dam this is ugly
	Filter( (F_TEXTURE_FILTERING == 0 ? ANISOTROPIC : (F_TEXTURE_FILTERING == 1 ? BILINEAR : (F_TEXTURE_FILTERING == 2 ? TRILINEAR : (F_TEXTURE_FILTERING == 3 ? POINT : NEAREST)))));
	AddressU( (F_WRAPPING_U == 0 ? WRAP : (F_WRAPPING_U == 1 ? MIRROR : (F_WRAPPING_U == 2 ? CLAMP : (F_WRAPPING_U == 3 ? BORDER : MIRROR_ONCE)))));
	AddressV( (F_WRAPPING_V == 0 ? WRAP : (F_WRAPPING_V == 1 ? MIRROR : (F_WRAPPING_V == 2 ? CLAMP : (F_WRAPPING_V == 3 ? BORDER : MIRROR_ONCE)))));
	AddressW( (F_WRAPPING_W == 0 ? WRAP : (F_WRAPPING_W == 1 ? MIRROR : (F_WRAPPING_W == 2 ? CLAMP : (F_WRAPPING_W == 3 ? BORDER : MIRROR_ONCE)))));
	>;
	
	// Input Textures
	CreateInputTexture2D( TextureColor, Srgb, 8, "None", "_color", "Material,0/1", Default( 1.00 ) );
	CreateInputTexture2D( TextureNormal, Linear, 8, "NormalizeNormals", "_normal", "Normal Map,10/1", Default( 1.00 ) );
	CreateInputTexture2D( TextureRoughness, Linear, 8, "None", "_rough", "Roughness,10/2", Default( 1.00 ) );
	CreateInputTexture2D( TextureMetalness, Linear, 8, "None", "_metal", "Metalness,10/3", Default( 0.00 ) );
	CreateInputTexture2D( TextureAmbientOcclusion, Linear, 8, "None", "_ao", "Ambient Occlusion,10/4", Default( 1.00 ) );
	
	// Textures from Input for Tex2DS
	Texture2D g_tTextureColor < Channel( RGBA, Box( TextureColor ), Srgb ); OutputFormat( RGBA8888 ); SrgbRead( true ); >;
	Texture2D g_tTextureNormal < Channel( RGBA, Box( TextureNormal ), Linear ); OutputFormat( BC7 ); SrgbRead( false ); >;
	Texture2D g_tRMA < 
	Channel( R, Box( TextureRoughness ), Linear ); 
	Channel( G, Box( TextureMetalness ), Linear ); 
	Channel( B, Box( TextureAmbientOcclusion ), Linear ); 
	OutputFormat( RGBA8888 ); SrgbRead( false ); 
	>;
	
	float4 MainPs( PixelInput i ) : SV_Target0
	{
		Material m;
		m.TintMask = 1;
		m.Opacity = 1;
		m.Emission = float3( 0, 0, 0 );
		m.Transmission = 0;
		
		float4 l_0 = Tex2DS( g_tTextureColor, 	g_sTexSampler, 	i.vTextureCoords.xy );
		float4 l_1 = Tex2DS( g_tTextureNormal, 	g_sTexSampler, 	i.vTextureCoords.xy );
		float4 l_2 = Tex2DS( g_tRMA, 			g_sTexSampler, 	i.vTextureCoords.xy );
		
		m.Albedo = l_0.xyz;
		m.Albedo *= i.vVertexColor.rgb;
		//i.vVertexColor.rgb *= pow(i.vVertexColor.rgb, g_vVertexColorSaturation - 1); // This is for the singular VectorText slider
		//m.Albedo *= i.vVertexColor.rgb * g_vVertexColorBrightness; // This is for the singular VectorText slider
		
		m.Normal = TransformNormal( i, DecodeNormal( l_1.xyz ) );
		m.Roughness = l_2.r;
		m.Metalness = l_2.g;
		m.AmbientOcclusion = l_2.b;
		
		return ShadingModelStandard::Shade( i, m );
	}
}
