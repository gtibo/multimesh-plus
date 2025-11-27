class_name Octree
extends Object

var grid_size : Vector3 = Vector3.ONE * 20.0
var half_grid_size : Vector3 = grid_size * 0.5

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

var region_map : Dictionary[AABB, IdPosList] = {}

func add_point(idx : int, point : Vector3) -> AABB:
	var center : Vector3 = (point / grid_size).floor() * grid_size + half_grid_size
	var region : AABB = AABB(center - half_grid_size, grid_size)

	if !region_map.has(region):
		region_map[region] = IdPosList.new()

	region_map[region].add(idx, point)

	return region

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

func get_points_in_sphere(position : Vector3, radius : float = 1.0):
	pass

func remove_points_in_sphere(position : Vector3, radius : float = 1.0) -> Array[int]:
	var result : Array[int] = []

	for aabb in region_map.keys():
		aabb = aabb as AABB
		if !aabb_overlap_with_sphere(aabb, position, radius): continue
		var id_pos_list : IdPosList = region_map[aabb]
		for i in id_pos_list.count:
			var point : Vector3 = id_pos_list.position_list[i]
			if point.distance_to(position) < radius:
				result.append(id_pos_list.idx_list[i])
	result.sort()

	for r in range(result.size() -1, -1, -1):
		var deleted_idx : int = result[r]
		for aabb in region_map.keys():
			var id_pos_list : IdPosList = region_map[aabb]
			for i in range(id_pos_list.count -1, -1, -1):
				var other_idx : int = id_pos_list.idx_list[i]
				if other_idx > deleted_idx:
					id_pos_list.idx_list[i] = other_idx - 1
				if other_idx == deleted_idx:
					id_pos_list.remove(other_idx)
	return result

func aabb_overlap_with_sphere(aabb : AABB, position, radius : float = 1.0) -> bool:
	var closest_point = position.clamp(aabb.position, aabb.end)
	var intersect : bool = position.distance_to(closest_point) < radius
	return intersect
