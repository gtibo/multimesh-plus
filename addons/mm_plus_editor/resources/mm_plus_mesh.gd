@tool
class_name MMPlusMesh
extends Resource

@export var name : StringName = "" : set = _set_name
@export var thumbnail: Texture = null
@export_tool_button("Generate Thumbnail") var update_thumbnail_action: Callable = update_thumbnail
@export_category("Display")
@export var mesh : Mesh : set = _set_mesh
@export var cast_shadow : RenderingServer.ShadowCastingSetting = RenderingServer.ShadowCastingSetting.SHADOW_CASTING_SETTING_ON : set = _set_shadow_cast
@export var data_mode : MMDataMode.Mode = MMDataMode.Mode.TransformOnly : set = _set_data_mode
@export_category("Distribution")
## Minimum space between this instance and another to avoid any overlap.
@export var spacing : float = 0.5 : set = _set_spacing
## How likely this layer is going to be picked for placement.
## from 0.0 (never) to 1.0 (always).
@export_range(0.0, 1.0, 0.01) var probability : float = 1.0
## Offset applied to the transformation of the instance during placement.
@export var offset : Vector3 = Vector3.ZERO : set = _set_offset
@export var align_on_surface_normal : bool = true
@export var rotation_mode : RotationMode = RotationMode.NONE
## Base scale of the instance used during placement.
@export_range(0.1, 10.0, 0.1, "or_greater") var base_scale : float = 1.0 : set = _set_base_scale
@export_group("Random Scale Variation")
@export_range(0.01, 1.0, 0.01, "or_greater") var min_scale : float = 1.0 : set = _set_min_scale
@export_range(0.01, 1.0, 0.01, "or_greater") var max_scale : float = 1.0 : set = _set_max_scale

enum RotationMode {
	## No rotation mode.
	NONE,
	## The instance is randomly rotated around the UP axis.
	RANDOM_Y_AXIS,
	## The forward axis of the instance is aligned with the direction of the brush.
	ALIGN_BRUSH_DIR
}

func update_thumbnail() -> void:
	if Engine.is_editor_hint():
		var editor_interface = Engine.get_singleton("EditorInterface") # Avoids explicitly using the Singleton
		thumbnail = editor_interface.make_mesh_previews([mesh], 64)[0]

func _set_name(new_name : StringName) -> void:
	name = new_name

func _set_mesh(new_mesh : Mesh) -> void:
	mesh = new_mesh
	emit_changed()

func _set_shadow_cast(new_shadow_cast : RenderingServer.ShadowCastingSetting) -> void:
	cast_shadow = new_shadow_cast
	emit_changed()

func _set_spacing(new_spacing : float) -> void:
	spacing = new_spacing

func _set_base_scale(new_scale : float) -> void:
	base_scale = new_scale

func _set_min_scale(new_min_scale) -> void:
	min_scale = new_min_scale
	if min_scale > max_scale: _set_max_scale(min_scale)

func _set_max_scale(new_max_scale) -> void:
	max_scale = new_max_scale
	if max_scale < min_scale: _set_min_scale(max_scale)

func _set_offset(new_offset: Vector3) -> void:
	offset = new_offset
	emit_changed()

func _set_data_mode(new_data_mode: MMDataMode.Mode) -> void:
	data_mode = new_data_mode
	emit_changed()
