extends Label

var section_theme: StyleBoxFlat = StyleBoxFlat.new()
const OPEN_SANS_BOLD: FontFile = preload("../../assets/fonts/OpenSans-Bold.ttf")

func _init(section_title: String) -> void:
	text = section_title

func _update_theme() -> void:
	var base_color: Color = EditorInterface.get_base_control().get_theme_color("base_color", "Editor")
	section_theme.bg_color = base_color.darkened(0.15)

func _ready() -> void:
	section_theme.set_corner_radius_all(4)
	section_theme.set_content_margin_all(4)
	_update_theme()
	EditorInterface.get_base_control().theme_changed.connect(_update_theme)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_theme_stylebox_override("normal", section_theme)
	add_theme_font_override("font", OPEN_SANS_BOLD)
