$input a_position, a_color0, a_texcoord0, a_texcoord1
$output v_texcoord, v_color0, v_texcoord0, v_texcoord1, v_texcoord2, v_texcoord3, v_texcoord_mask

uniform vec4 u_cameraSize;

#include "common.sh"

void main()
{
	gl_Position = mul(u_modelViewProj, vec4(a_position, 1.0) );
	
	v_texcoord = a_texcoord1 ;
	v_texcoord_mask = a_texcoord0;

    // Sample neighbours diagonally
	v_texcoord0.xy = v_texcoord + vec2(u_cameraSize.z*-5.0, u_cameraSize.w*-5.0);
    v_texcoord1.xy = v_texcoord + vec2(u_cameraSize.z*-5.0, u_cameraSize.w*7.0);
    v_texcoord2.xy = v_texcoord + vec2(u_cameraSize.z*5.0, u_cameraSize.w*-3.0);
    v_texcoord3.xy = v_texcoord + vec2(u_cameraSize.z*6.0, u_cameraSize.w*4.0);

	v_color0 = a_color0;
}
