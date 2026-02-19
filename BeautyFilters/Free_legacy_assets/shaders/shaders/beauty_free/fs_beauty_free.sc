$input v_texcoord, v_texcoord_mask, v_color0, v_texcoord0, v_texcoord1, v_texcoord2, v_texcoord3

#include "common.sh"

SAMPLER2D(inputtex, 0);
SAMPLER2D(foundationtex, 1);

uniform vec4 smoothingAmount;
uniform vec4 foundationColor;


vec4 foundationBlend(vec4 src, vec4 blend, vec4 alphaMask ) {
	float lumaSrc = dot(vec3(0.2126729, 0.7151522, 0.0721750), src.rgb);
	return mix(src, blend, alphaMask.a*blend.a*clamp(lumaSrc*1.25, 0.0, 1.0));
}

void main()
{
	vec4 inputPixel = texture2D(inputtex, v_texcoord.xy);
	vec4 foundationMaskPixel = texture2D(foundationtex, v_texcoord_mask.xy);
   

	vec4 result = foundationBlend(inputPixel, foundationColor, foundationMaskPixel); //mix(result, foundationColor, foundationMaskPixel.a*foundationColor.a*1.25);
	
	result.a = 1.0;
	gl_FragColor = result;

}