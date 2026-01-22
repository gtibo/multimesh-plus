extends Node3D

@onready var camera_3d: Camera3D = %Camera3D

func _ready() -> void:
	Engine.time_scale = 4.0

	var t : Tween = create_tween()
	t.tween_property(camera_3d, "position:z", 160.0, 5.0).set_delay(5.0)
	t.tween_property(camera_3d, "position:z", 80.0, 5.0).set_delay(5.0)
	t.tween_callback(get_tree().quit).set_delay(5.0)
