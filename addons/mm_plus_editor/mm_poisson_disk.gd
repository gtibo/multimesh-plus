class_name MMPoissonDisk
extends Object

var points: Array[Dictionary] = []
var active_list: Array = []
var cell_size: float = -1.0
var cells_row_count: int = 0
var cells_count: int = 0
var cells_id: Array[PackedInt32Array] = []
var min_radius: float = 0.0
var max_radius: float = 0.0
var zone_size: float = 0.0
var max_compute: int = 64

func get_points_in_circle(_min_radius: float, _max_radius: float, _zone_size: float) -> Array[Dictionary]:
	active_list = []
	points = []
	cells_id = []
	# Initiliaze grid
	min_radius = _min_radius
	max_radius = _max_radius
	zone_size = _zone_size
	cell_size = min_radius / sqrt(2)
	cells_row_count = ceil(zone_size / cell_size) - 1
	cells_count = pow(cells_row_count, 2)
	cells_id.resize(cells_count)

	#var first_point : Vector2 = Vector2(randf() * zone_size, randf() * zone_size)
	var first_point : Vector2 = Vector2(zone_size / 2.0, zone_size / 2.0)
	_add_point({
		"position": first_point,
		"radius": randf_range(min_radius, max_radius),
	})

	var compute_count: int = 0

	while !active_list.is_empty():
		var picked_id: int = active_list.pick_random()
		var picked_valid_point: Dictionary = points[picked_id]
		var candidate_points: Array[Dictionary] = _get_candidate_points(picked_valid_point)
		# Keep in memory how many points where added
		var valid_count: int = 0

		for point in candidate_points:
			var is_valid: bool = _add_point(point)
			if is_valid: valid_count += 1

		if valid_count == 0:
			active_list.erase(picked_id)

		if compute_count >= max_compute: break
		compute_count += 1


	return points

func _get_candidate_points(point: Dictionary) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for i in range(16):
		var pos: Vector2 = point.position + (Vector2.from_angle(randf() * TAU) * randf_range(point.radius , max_radius * 2.0))
		if (pos - Vector2.ONE * zone_size / 2.0).length() > zone_size / 2.0: continue
		if pos.x < 0.0 || pos.x > zone_size: continue
		if pos.y < 0.0 || pos.y > zone_size: continue

		candidates.append({
			"position": pos,
			"radius": randf_range(min_radius, max_radius)
		})
	return candidates

func _add_point(point: Dictionary) -> bool:
	var cell_sample_width: int = ceil(point.radius / cell_size) + 1
	
	var cell_sample_count: int = pow(cell_sample_width * 2, 2)
	# Which cell this point is on
	var point_cell: Vector2i = Vector2i(
		round(point.position.x / cell_size),
		round(point.position.y / cell_size),
	)

	var current_cell_idx: int = (cells_row_count * point_cell.y) + point_cell.x
	
	# Check for overlaps
	#var overlaps: PackedInt32Array = cells_id[current_cell_idx]
	#if !overlaps.is_empty():
		#for idx in overlaps:
			#var other_point: Dictionary = points[idx]
			#var dist: float = (point.position - other_point.position).length()
			#if dist < (point.radius + other_point.radius): return false

	for other_point in points:
		var dist: float = (point.position - other_point.position).length()
		if dist < (point.radius + other_point.radius): return false

	# Top left cell of this point
	points.append(point)
	active_list.append(points.size() - 1)
	
	var start_cell: Vector2i = point_cell - Vector2i.ONE * (cell_sample_width)

	for idx in cell_sample_count:
		var x: int = start_cell.x + idx % (cell_sample_width * 2) 
		var y: int = start_cell.y + floor(idx / (cell_sample_width * 2)) 
		if x < 0 || x > cells_row_count - 1: continue
		if y < 0 || y > cells_row_count - 1: continue
		var cell_idx: int = x + y * cells_row_count
		#if cell_idx > cells_id.size() - 1: continue
		cells_id[cell_idx].append(points.size() - 1)

	return true
