shader_type spatial;

uniform vec3 albedo : source_color;
uniform bool use_vertex_color;

group_uniforms object_fade;
uniform float distance_fade_min : hint_range(0.0, 4096.0, 0.01);
uniform float distance_fade_max : hint_range(0.0, 4096.0, 0.01);


void fragment() {

	if(use_vertex_color){
		ALBEDO = albedo * COLOR.rgb;
	}else{
		ALBEDO = albedo;
	}
	ROUGHNESS = 0.6;

	{
		// Distance Fade: Object Dither
		float fade_distance = length(
			VERTEX
		);
		
		// Use interleaved gradient noise, which is fast but still looks good.
		const vec3 magic = vec3(0.06711056, 0.00583715, 52.9829189);
		float fade = clamp(smoothstep(distance_fade_min, distance_fade_max, fade_distance), 0.0, 1.0);
		// Use a hard cap to prevent a few stray pixels from remaining when past the fade-out distance.
		if (fade < 0.001 || fade < fract(magic.z * fract(dot(FRAGCOORD.xy, magic.xy)))) {
			discard;
		}
	}
}
