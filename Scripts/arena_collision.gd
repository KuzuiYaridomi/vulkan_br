extends Node
## The imported arena/prop .glb files have no collision shapes.
## This generates static trimesh collision for every mesh under the listed nodes
## at startup, so the player can stand on the floor and bump into walls/stands.

@export var targets: Array[NodePath] = []


func _ready() -> void:
	for path in targets:
		var node := get_node_or_null(path)
		if node:
			_add_collision(node)


func _add_collision(node: Node) -> void:
	if node is MeshInstance3D and node.mesh:
		node.create_trimesh_collision()
	for child in node.get_children():
		_add_collision(child)
