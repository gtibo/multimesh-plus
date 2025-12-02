shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec3 color : source_color;

float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}

varying vec3 v;

void vertex(){
	v = NORMAL;
}

void fragment() {
	ALBEDO = color;
	ALPHA = fresnel(0.5, NORMAL, VIEW) * clamp(v.y, 0.0, 1.0) + step(0.5, 1.0 - abs(v.y * 10.0));
}
