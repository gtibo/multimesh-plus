extends Node3D

var octree : Octree = Octree.new()

func _ready() -> void:
	var points : PackedVector3Array = PackedVector3Array(get_random_point_in_sphere(100, 10.0))
	#for point in points:
		#octree.add_point(point)

func get_random_point_in_sphere(res : int, radius : float = 1.0) -> Array[Vector3]:
	var result : Array[Vector3] = []
	for idx in res:
		result.append(
			Vector3(
				randfn(0.0, radius),
				randfn(0.0, radius),
				randfn(0.0, radius)
			).normalized() * radius
		)
	return result

#const WIREFRAME_MAT = preload("res://addons/multimesheditor/test/octree_test/wireframe_mat.tres")
#const POINT_MESH = preload("res://addons/multimesheditor/test/point_mesh.obj")
#const DOT_MAT = preload("res://addons/multimesheditor/test/octree_test/dot_mat.tres")
#@export var noise : NoiseTexture3D
#
#var m_rid : RID = RenderingServer.multimesh_create()
#var octree : Octree = Octree.new()
#@onready var camera_root = %CameraRoot
#
#func _ready() -> void:
	#
	##var tween : Tween = create_tween().set_loops(0)
	##tween.tween_property(camera_root, "rotation_degrees:y", 360.0, 20.0).from(0.0)
#
	#var i_rid : RID = RenderingServer.instance_create2(m_rid, get_world_3d().scenario)
#
	#RenderingServer.instance_set_transform(i_rid, Transform3D.IDENTITY)
	#
	## Populate
	#
	#var count : int = 25
	#var points : PackedVector3Array = get_random_point_in_sphere(1000)
#
	#POINT_MESH.surface_set_material(0, DOT_MAT)
	#RenderingServer.multimesh_set_mesh(m_rid, POINT_MESH.get_rid())
	#RenderingServer.multimesh_allocate_data(m_rid, points.size(), RenderingServer.MULTIMESH_TRANSFORM_3D, true, true)
	#
	##for idx in points.size():
		##var t : Transform3D = Transform3D.IDENTITY
		##t.origin = points[idx]
		##RenderingServer.multimesh_instance_set_transform(m_rid, idx, t)
		##RenderingServer.multimesh_instance_set_color(m_rid, idx, Color.DODGER_BLUE * 0.2)
#
	##octree.initialize([])
	#octree.add(points)
	##octree.add(get_random_point_in_sphere(16))
#
	#for idx in points.size():
		#var t : Transform3D = Transform3D.IDENTITY
		#t.origin = points[idx]
		#RenderingServer.multimesh_instance_set_transform(m_rid, idx, t)
		#RenderingServer.multimesh_instance_set_color(m_rid, idx, Color.DODGER_BLUE * 0.2)
#
#
#
	#for region in octree.regions:
		#var color : Color = Color.DODGER_BLUE.lerp(Color.LAWN_GREEN, randf())
		#var mat : ShaderMaterial = WIREFRAME_MAT.duplicate(false)
		#mat.set_shader_parameter("albedo", color)
#
		#var mesh : BoxMesh = BoxMesh.new()
		#mesh.size = region.aabb.size
		#mesh.material = mat
		#var mesh_instance : MeshInstance3D = MeshInstance3D.new()
		#mesh_instance.mesh = mesh
		#add_child(mesh_instance)
		#mesh_instance.position = region.aabb.position + region.aabb.size / 2.0
#
#var previous_picked_idx : Array[int]
#var pick_position : Vector3 = Vector3.ZERO
#@onready var pick_mesh = %PickMesh
#
#func _physics_process(delta):
	#var t : float = Time.get_ticks_msec() / 1000.0
	#pick_position.x = sin(t * 2.0) * 4.0
	#pick_position.y = sin(cos(t * 0.5) - sin(t * 0.25)) * 4.0
	#pick_position.z = cos(t) * 4.0
	#pick_mesh.position = pick_position
	#var picked_idx : Array[int] = octree.get_points_in_sphere(pick_position, 2.0)
#
	#for idx in previous_picked_idx:
		#RenderingServer.multimesh_instance_set_color(m_rid, idx, Color.DODGER_BLUE * 0.2)
		#RenderingServer.multimesh_instance_set_custom_data(m_rid, idx, Color.BLACK)
#
	#for idx in picked_idx:
		#RenderingServer.multimesh_instance_set_color(m_rid, idx, Color.DODGER_BLUE)
		#RenderingServer.multimesh_instance_set_custom_data(m_rid, idx, Color.WHITE)
	#
	#previous_picked_idx = picked_idx
#

#
#func get_random_point_in_noise(res : int) -> PackedVector3Array:
	#var result : Array[Vector3] = []
	#var total : int = res * res * res
	#var face : int = res * res
#
	#for idx in total:
		#var x : int = (idx % res) 
		#var y : int = floor(idx / face)
		#var z : int = floor(idx / res) % res
		#var point_percent : Vector3 = Vector3(x, y, z) / (res - 1) - Vector3(0.5, 0.5, 0.5)
		##point_percent *= Vector3(1.0, 0.5, 1.0)
		#var point : Vector3 = point_percent * 10.0
		#var n_value : float = noise.noise.get_noise_3dv(point_percent * 200.0)
		#n_value = (n_value + 1.0) / 2.0
		#
		#if n_value > 0.5 && point.length() > 5.0 && point.length() < 6.0:
			#result.append(point)
		#
	#return result
