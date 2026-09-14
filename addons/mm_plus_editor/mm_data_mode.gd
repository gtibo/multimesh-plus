class_name MMDataMode

enum Mode {
	## Stores 12 integer values: for position, rotation, and scale.
	TransformOnly,
	## Stores 12 integer values: for position, rotation, scale and color.
	TransformAndVertexColor
}

static func get_data_mode_size(mode: Mode) -> int:
	match mode:
		Mode.TransformOnly:
			return 12
		Mode.TransformAndVertexColor:
			return 16
	return 12
