extends Node3D

@export var spin_axis : Vector3 = Vector3.UP
@export var spin_time : float = 10.0

func _ready() -> void:
	spin_axis = spin_axis.normalized()
	var t : Tween = create_tween().set_loops(0)
	t.tween_property(self, "rotation", spin_axis * TAU, spin_time).from(Vector3.ZERO)
