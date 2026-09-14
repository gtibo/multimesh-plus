extends Node2D

var PD: MMPoissonDisk = MMPoissonDisk.new()
var points: Array[Dictionary]
@onready var timer: Timer = %Timer

func _ready() -> void:
	timer.timeout.connect(get_tree().quit)

func _physics_process(delta: float) -> void:
	points = PD.get_points_in_circle(0.5, 1.0, 20.0)
	queue_redraw()

func _draw() -> void:
	var zoom: float = 40.0
	#draw_rect(
		#Rect2(Vector2.ZERO, Vector2.ONE * PD.zone_size * zoom),
		#Color.BLACK, false, 1.0, true
	#)

	#for idx in PD.cells_count:
		#var x: float = idx % PD.cells_row_count
		#var y: float = floor(idx / PD.cells_row_count)
		#draw_rect(
			#Rect2(Vector2(x, y) * PD.cell_size * zoom, Vector2.ONE * PD.cell_size * zoom),
			#Color.BLACK * 0.1,
			#true if PD.cells_id[idx].has(0) else false,
			#-1.0 if PD.cells_id[idx].has(0) else 1.0,
			#true
		#)

	draw_circle(
		Vector2.ONE * PD.zone_size * 0.5 * zoom, PD.zone_size * 0.5 * zoom, Color.BLACK * 0.5, false, 2.0, true
	)

	for idx in points.size():
		var point: Dictionary = points[idx]
		draw_circle(point.position * zoom, point.radius * zoom, Color.RED if idx == 0 else Color.ROYAL_BLUE, false, 2.0, true)
		draw_circle(point.position * zoom, 2.0 , Color.RED if idx == 0 else Color.ROYAL_BLUE, false, 2.0, true)
