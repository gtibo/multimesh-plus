class_name MMDataMode

enum Mode {
	TransformOnly,
	TransformAndVertexColor
}

static func get_data_mode_size(mode: Mode) -> int:
	match mode:
		Mode.TransformOnly:
			return 12
		Mode.TransformAndVertexColor:
			return 16
	return 12
