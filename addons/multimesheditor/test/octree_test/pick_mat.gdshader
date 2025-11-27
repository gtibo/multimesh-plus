shader_type spatial;
render_mode unshaded;

uniform vec3 albedo : source_color;

float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}

void fragment() {
	ALBEDO = albedo;
	ALPHA = fresnel(1.0, NORMAL, VIEW);
	ALPHA_SCISSOR_THRESHOLD = 0.6;
}
