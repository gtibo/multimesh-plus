extends Label

func _process(delta: float) -> void:
	text = str(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
