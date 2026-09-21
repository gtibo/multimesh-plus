extends HBoxContainer

var button_group = ButtonGroup.new()
var btn_default_theme: StyleBoxFlat = null
var btn_hover_theme: StyleBoxFlat = null
var btn_active_theme: StyleBoxFlat = null

const btn_mode_map : Dictionary[MMPlusEditorPlugin.MODE, Dictionary] = {
	MMPlusEditorPlugin.MODE.PAINT: {"title": "Paint", "icon": "Paint"},
	MMPlusEditorPlugin.MODE.SCALE: {"title": "Scale", "icon": "ToolScale"},
	MMPlusEditorPlugin.MODE.COLOR: {"title": "Colorize", "icon": "Bucket"},
}

func _update_theme() -> void:
	var bg_color: Color = EditorInterface.get_base_control().get_theme_color("base_color", "Editor")
	var accent_color: Color = EditorInterface.get_base_control().get_theme_color("accent_color", "Editor")
	btn_default_theme.bg_color = bg_color.darkened(0.15)
	btn_hover_theme.bg_color = bg_color.darkened(0.25)
	btn_active_theme.bg_color = accent_color.lerp(bg_color, 0.8)

func _ready() -> void:
	btn_default_theme = StyleBoxFlat.new()
	btn_default_theme.set_corner_radius_all(8)
	btn_default_theme.set_content_margin_all(8)
	btn_hover_theme = btn_default_theme.duplicate()
	btn_active_theme = btn_default_theme.duplicate()
	_update_theme()
	EditorInterface.get_base_control().theme_changed.connect(_update_theme)

	var gui = EditorInterface.get_base_control()

	for btn_id in btn_mode_map:
		var btn : Button = Button.new()
		btn.text = btn_mode_map[btn_id].title
		btn.icon = gui.get_theme_icon(btn_mode_map[btn_id].icon, "EditorIcons")
		btn.button_group = button_group
		btn.toggle_mode = true
		btn.set_meta("ID", btn_id)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(btn)
		btn.set("theme_override_styles/normal", btn_default_theme)
		btn.set("theme_override_styles/hover", btn_hover_theme)
		btn.set("theme_override_styles/hover_pressed", btn_active_theme)
		btn.set("theme_override_styles/pressed", btn_active_theme)

	button_group.allow_unpress = true
