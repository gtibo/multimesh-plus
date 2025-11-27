shader_type spatial;
render_mode unshaded;

void vertex() {
	VERTEX += NORMAL * INSTANCE_CUSTOM.x * 0.2;
	VERTEX *= 0.5;
}

void fragment() {
	ALBEDO = COLOR.rgb;
}