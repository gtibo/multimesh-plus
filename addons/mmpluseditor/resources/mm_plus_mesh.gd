@tool
class_name MMPlusMesh
extends Resource

@export var name : StringName = "" : set = _set_name
@export var mesh : Mesh : set = _set_mesh
@export var spacing : float = 0.5 : set = _set_spacing

func _set_name(new_name : StringName) -> void:
	name = new_name
	emit_changed()

func _set_mesh(new_mesh : Mesh) -> void:
	mesh = new_mesh
	emit_changed()

func _set_spacing(new_spacing : float) -> void:
	spacing = new_spacing
	emit_changed()
