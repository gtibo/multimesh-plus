extends VBoxContainer


var collision_layer: int = 1
var btn_default_theme: StyleBoxFlat = StyleBoxFlat.new()
var btn_active_theme: StyleBoxFlat = StyleBoxFlat.new()
var warning_label: Label = Label.new()

const NO_LAYER_WARNING: String = "MM+ cannot modify instances on a surface unless there is at least one active physical layer."

func _toggle_collision_layer(toggled : bool, flag_idx : int) -> void:
	if toggled:
		# Add collision layer
		collision_layer |= 1 << (flag_idx)
	else:
		# Remove collision layer
		collision_layer &= ~( 1 << (flag_idx) )

	warning_label.visible = collision_layer == 0
	warning_label.text = NO_LAYER_WARNING

func _update_button_theme() -> void:
	var bg_color: Color = EditorInterface.get_base_control().get_theme_color("base_color", "Editor")
	var accent_color: Color = EditorInterface.get_base_control().get_theme_color("accent_color", "Editor")

	btn_default_theme.bg_color = bg_color
	btn_active_theme.bg_color = accent_color.lerp(bg_color, 0.4)

func _ready() -> void:
	warning_label.visible = false
	warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	EditorInterface.get_base_control().theme_changed.connect(_update_button_theme)
	var gui = EditorInterface.get_base_control()

	var collision_layer_popup_button: Button = Button.new()
	collision_layer_popup_button.text = "Edit Collision Layers"
	collision_layer_popup_button.icon = gui.get_theme_icon("CollisionShape3D", "EditorIcons")
	collision_layer_popup_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var collision_layer_popup: PopupPanel = PopupPanel.new()
	var collision_layer_container : GridContainer = GridContainer.new()
	collision_layer_container.set("theme_override_constants/h_separation", 1)
	collision_layer_container.set("theme_override_constants/v_separation", 1)
	collision_layer_container.columns = 16
	collision_layer_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collision_layer_popup.add_child(collision_layer_container)
	add_child(collision_layer_popup)
	add_child(collision_layer_popup_button)
	add_child(warning_label)

	collision_layer_popup_button.pressed.connect(func() -> void:
			collision_layer_popup.popup(Rect2i(
				collision_layer_popup_button.get_screen_position() + Vector2(0.0, collision_layer_popup_button.size.y),
				Vector2.ZERO
			))
	)

	_update_button_theme()

	for i in 32:
		var layer_btn : Button = Button.new()
		collision_layer_container.add_child(layer_btn)
		layer_btn.text = str(i + 1)
		layer_btn.toggle_mode = true
		if i == 0: layer_btn.set_pressed(true)
		layer_btn.toggled.connect(_toggle_collision_layer.bind(i))
		layer_btn.set("theme_override_styles/normal", btn_default_theme)
		layer_btn.set("theme_override_styles/hover", btn_active_theme)
		layer_btn.set("theme_override_styles/hover_pressed", btn_active_theme)
		layer_btn.set("theme_override_styles/pressed", btn_active_theme)
