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

func set_buffer_color_in_sphere(position : Vector3, radius : float = 1.0, base_color : Color = Color.BLACK, random_color : bool = false):

	var result : Dictionary[AABB, PackedInt64Array] = octree.get_points_in_sphere(position, radius)
	for aabb in result:
		for idx in result[aabb]:
			idx *= 16
			var color : Color = Color(randf(), randf(), randf(), randf()) if random_color else base_color
			buffer_map[aabb][idx + 12] = color.r
			buffer_map[aabb][idx + 13] = color.g
			buffer_map[aabb][idx + 14] = color.b
			buffer_map[aabb][idx + 15] = color.a

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

func get_buffer_transform_basis(aabb : AABB, idx : int) -> Basis:
	return Basis(
		Vector3(buffer_map[aabb][idx + 0], buffer_map[aabb][idx + 4], buffer_map[aabb][idx + 8]),
		Vector3(buffer_map[aabb][idx + 1], buffer_map[aabb][idx + 5], buffer_map[aabb][idx + 9]),
		Vector3(buffer_map[aabb][idx + 2], buffer_map[aabb][idx + 6], buffer_map[aabb][idx + 10])
	)

func get_buffer_transform(aabb : AABB, idx : int) -> Transform3D:
	var basis : Basis = get_buffer_transform_basis(aabb, idx)
	return Transform3D(basis, Vector3(idx + 3, idx + 7, idx + 11))

func set_buffer_transform_scale(aabb : AABB, idx : int, scale : float) -> void:
	idx *= 16
	var basis : Basis = get_buffer_transform_basis(aabb, idx)
	basis = basis.orthonormalized().scaled_local(Vector3.ONE * scale)
	_apply_basis_to_buffer(aabb, idx, basis)

func increment_buffer_transform_scale(aabb : AABB, idx : int, increment : float = 0.0) -> void:
	idx *= 16
	var basis : Basis = get_buffer_transform_basis(aabb, idx)
	var scale : float = basis.get_scale()[0] + increment
	scale = clampf(scale, 0.1, 10.0)
	basis = basis.orthonormalized().scaled_local(Vector3.ONE * scale)
	_apply_basis_to_buffer(aabb, idx, basis)

func _apply_basis_to_buffer(aabb : AABB, idx, basis : Basis) -> void:
	buffer_map[aabb][idx + 0] = basis.x.x
	buffer_map[aabb][idx + 1] = basis.y.x
	buffer_map[aabb][idx + 2] = basis.z.x

	buffer_map[aabb][idx + 4] = basis.x.y
	buffer_map[aabb][idx + 5] = basis.y.y
	buffer_map[aabb][idx + 6] = basis.z.y

	buffer_map[aabb][idx + 8] = basis.x.z
	buffer_map[aabb][idx + 9] = basis.y.z
	buffer_map[aabb][idx + 10] = basis.z.z
