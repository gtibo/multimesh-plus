@tool
class_name MMPlusMesh
extends Resource

@export var name : StringName = "" : set = _set_name
@export var mesh : Mesh : set = _set_mesh
## Minimum space between this instance and another to avoid any overlap.
@export var spacing : float = 0.5 : set = _set_spacing
## Offset applied to the transformation of the instance during placement.
@export var offset : Vector3 = Vector3.ZERO : set = _set_offset
## Base scale of the instance used during placement.
@export_range(0.1, 10.0, 0.1, "or_greater") var base_scale : float = 1.0 : set = _set_base_scale
## How likely this layer is going to be picked for placement.
## from 0.0 (never) to 1.0 (always).
@export_range(0.0, 1.0, 0.01) var probability : float = 1.0

func _set_name(new_name : StringName) -> void:
	name = new_name

func _set_mesh(new_mesh : Mesh) -> void:
	mesh = new_mesh
	emit_changed()

func _set_spacing(new_spacing : float) -> void:
	spacing = new_spacing

func _set_base_scale(new_scale : float) -> void:
	base_scale = new_scale

func _set_offset(new_offset: Vector3) -> void:
	offset = new_offset
	emit_changed()
