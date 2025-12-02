class_name MMGroup
extends Object

var octree : Octree
var buffer_map : Dictionary[AABB, PackedFloat32Array] = {}

func _init(data : Dictionary[AABB, MultiMesh]) -> void:
	buffer_map = {}
	octree = Octree.new()
	for aabb in data:
		buffer_map[aabb] = data[aabb].buffer
		var buffer : PackedFloat32Array = data[aabb].buffer

		var points = []

		for idx in range(0, buffer.size(), 16):
			var point = Vector3(
				buffer[idx + 3],
				buffer[idx + 7],
				buffer[idx + 11]
			)
			points.append(point)

		octree.populate(aabb, points)

func remove_point_in_sphere(position : Vector3, radius : float = 1.0) -> void:
	var result : Dictionary[AABB, PackedInt64Array] = octree.remove_points_in_sphere(position, radius)
	for aabb in result:
		remove_from_buffer_at_idx_list(aabb, result[aabb])

func add_transform_to_buffer(t : Transform3D) -> void:
	var region : AABB = octree.check_region_for_point(t.origin)

	if !buffer_map.has(region):
		buffer_map[region] = PackedFloat32Array()

	buffer_map[region].append_array(
		[t.basis.x.x, t.basis.y.x, t.basis.z.x, t.origin.x, t.basis.x.y, t.basis.y.y, t.basis.z.y, t.origin.y, t.basis.x.z, t.basis.y.z, t.basis.z.z, t.origin.z, randf(), randf(), randf(), 1.0]
		)
	var idx : int = buffer_map[region].size() / 16 - 1

	octree.add_point_in_region(region, idx, t.origin)

func remove_from_buffer_at_idx_list(aabb : AABB, idx_list : PackedInt64Array):
	for idx in range(idx_list.size() - 1 , -1, -1):
		remove_from_buffer_at_idx(aabb, idx_list[idx])

func remove_from_buffer_at_idx(aabb : AABB, idx : int):
	var size : int = 16
	var idx_offset : int = size * idx
	for i in range(size - 1 + idx_offset, -1 + idx_offset, -1):
		buffer_map[aabb].remove_at(i)
