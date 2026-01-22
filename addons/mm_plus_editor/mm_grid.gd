class_name MMGrid
extends Object

var grid_size : Vector3
var half_grid_size : Vector3

class IdPosList:
	var count : int = 0
	var position_list : PackedVector3Array = []
	var idx_list : PackedInt64Array = []

	func add(idx : int, position : Vector3) -> void:
		idx_list.append(idx)
		position_list.append(position)
		count += 1

	func remove(idx : int) -> void:
		var i : int = idx_list.find(idx)
		idx_list.remove_at(i)
		position_list.remove_at(i)
		count -= 1
	
	func duplicate() -> IdPosList:
		var new_id_pos_list : IdPosList = IdPosList.new()
		new_id_pos_list.count = count
		new_id_pos_list.position_list = position_list.duplicate()
		new_id_pos_list.idx_list = idx_list.duplicate()
		return new_id_pos_list

var region_map : Dictionary[AABB, IdPosList] = {}

func _init(_grid_size : Vector3) -> void:
	grid_size = _grid_size
	half_grid_size = grid_size / 2.0

func duplicate() -> MMGrid:
	var mm_grid_clone : MMGrid = MMGrid.new(self.grid_size)
	var new_r_m : Dictionary[AABB, IdPosList] = {}
	for aabb in region_map:
		new_r_m[aabb] = region_map[aabb].duplicate()
	mm_grid_clone.region_map = new_r_m
	return mm_grid_clone

func populate(aabb : AABB, points : PackedVector3Array) -> void:
	var id_pos_list : IdPosList = IdPosList.new()
	for idx in points.size():
		id_pos_list.add(idx, points[idx])
	region_map[aabb] = id_pos_list

func check_region_for_point(point : Vector3) -> AABB:
	var center : Vector3 = (point / grid_size).floor() * grid_size + half_grid_size
	var region : AABB = AABB(center - half_grid_size, grid_size)

	if !region_map.has(region):
		region_map[region] = IdPosList.new()

	return region

func add_point_in_region(region : AABB, idx : int, point : Vector3) -> void:
	region_map[region].add(idx, point)

func is_point_in_sphere(position : Vector3, radius : float = 1.0) -> bool:
	for aabb in region_map.keys():
		aabb = aabb as AABB
		if !aabb_overlap_with_sphere(aabb, position, radius): continue
		var id_pos_list : IdPosList = region_map[aabb]
		for i in id_pos_list.count:
			var point : Vector3 = id_pos_list.position_list[i]
			if point.distance_to(position) < radius:
				return true
	return false

func get_points_in_sphere(position : Vector3, radius : float = 1.0) -> Dictionary[AABB, PackedInt64Array]:
	var result : Dictionary[AABB, PackedInt64Array] = {}
	for aabb in region_map.keys():
		aabb = aabb as AABB
		if !aabb_overlap_with_sphere(aabb, position, radius): continue
		var id_pos_list : IdPosList = region_map[aabb]
		result[aabb] = PackedInt64Array()
		for i in id_pos_list.count:
			var point : Vector3 = id_pos_list.position_list[i]
			if point.distance_to(position) < radius:
				result[aabb].append(id_pos_list.idx_list[i])

	return result

func get_point_position(aabb : AABB, idx : int):
	var p_idx : int = region_map[aabb].idx_list.find(idx)
	return region_map[aabb].position_list[p_idx]

func remove_points_in_sphere(position : Vector3, radius : float = 1.0) -> Dictionary[AABB, PackedInt64Array]:
	var result : Dictionary[AABB, PackedInt64Array] = {}

	for aabb in region_map.keys():
		aabb = aabb as AABB
		if !aabb_overlap_with_sphere(aabb, position, radius): continue
		var id_pos_list : IdPosList = region_map[aabb]
		result[aabb] = PackedInt64Array()
		for i in id_pos_list.count:
			var point : Vector3 = id_pos_list.position_list[i]
			if point.distance_to(position) < radius:
				result[aabb].append(id_pos_list.idx_list[i])
		result[aabb].sort()

	#Updated to a version that produces better performance results
	for aabb in result:
		var deleted_indices : PackedInt64Array = result[aabb]  # Already sorted ascending
		var id_pos_list : IdPosList = region_map[aabb]

		# Build a hash set from deleted indices for O(1)
		var deleted_set : Dictionary = {}
		for idx in deleted_indices:
			deleted_set[idx] = true

		# Prepare new arrays to hold only the surviving (non-deleted) items
		var new_idx_list : PackedInt64Array = PackedInt64Array()
		var new_pos_list : PackedVector3Array = PackedVector3Array()

		# Single pass through all items in this region
		for i in id_pos_list.count:
			var old_idx : int = id_pos_list.idx_list[i]
			if not deleted_set.has(old_idx):
				var decrement : int = deleted_indices.bsearch(old_idx)
				# Add surviving item with its adjusted index
				new_idx_list.append(old_idx - decrement)
				new_pos_list.append(id_pos_list.position_list[i])

		# Replace old arrays with the filtered/adjusted versions
		id_pos_list.idx_list = new_idx_list
		id_pos_list.position_list = new_pos_list
		id_pos_list.count = new_idx_list.size()
	return result

func aabb_overlap_with_sphere(aabb : AABB, position, radius : float = 1.0) -> bool:
	var closest_point = position.clamp(aabb.position, aabb.end)
	var intersect : bool = position.distance_to(closest_point) < radius
	return intersect
