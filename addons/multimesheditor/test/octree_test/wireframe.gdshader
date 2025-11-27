shader_type spatial;
render_mode wireframe, unshaded;

uniform vec3 albedo : source_color = vec3(0.5);

void fragment() {
	ALBEDO = albedo;
	ALPHA *= 0.5;
}

