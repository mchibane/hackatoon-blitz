extends Area2D

signal enemy_clicked

const MAX_WIDTH = 10

@export var	life_time = 3.0;
@export var text: String = "Default Text"

var answer: Dictionary

@onready var is_good_answer: bool = randf() < GameData.good_spawn_ratio
@onready var label = $AnswerText
@onready var collision_shape = $CollisionShape2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pick_random_text()
	$LifeTime.start(life_time)
	self.rotate(randf_range(-(PI / 12), (PI / 12)))

func update_text(new_text: String):
	text = new_text
	label.text = text
	
	await get_tree().process_frame
	
	var text_size = label.get_minimum_size()
	
	var rect_shape = collision_shape.shape as RectangleShape2D
	rect_shape.size = text_size + Vector2(10, 10)
	

func pick_random_text():
	var current_question_id = QuestionsHandler.current_question.id
	var random_answer: Dictionary
	if (is_good_answer):
		for answer in QuestionsHandler.answers:
			if (answer.isValid and answer.questionId == current_question_id):
				random_answer = answer
				break
	else:
		random_answer = QuestionsHandler.answers.pick_random()
		while(random_answer.questionId == current_question_id and random_answer.isValid):
			random_answer = QuestionsHandler.answers.pick_random()
	answer = random_answer
	update_text(answer.text)
		

func dstroy():
	$CPUParticles2D.emitting = true
	label.hide()
	collision_shape.disabled = true
	await get_tree().create_timer(0.3).timeout
	queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()):
		var highest_enemy = self
		var mouse_pos = event.global_position
		for enemy: Area2D in get_overlapping_areas():
			var shape: Shape2D = enemy.collision_shape.shape
			var local_mouse_pos = enemy.collision_shape.global_transform.affine_inverse().basis_xform(mouse_pos)
			if (is_point_inside_shape_global(shape, enemy.collision_shape.global_transform, mouse_pos)):
				if (enemy.z_index > highest_enemy.z_index):
					highest_enemy = enemy
		if (highest_enemy != self):
			return
		enemy_clicked.emit(is_good_answer)
		dstroy()

func is_point_inside_shape_global(shape: Shape2D, global_transform: Transform2D, point: Vector2) -> bool:
	# Check if the point is inside the shape based on its type
	if shape is RectangleShape2D:
		var rect: RectangleShape2D = shape as RectangleShape2D
		var rect_half_extents: Vector2 = rect.size / 2.0

		# Get the rectangle's global position and size
		var rect_global_position = global_transform.origin
		var rect_global_extents = rect_half_extents * global_transform.get_scale()

		# Calculate the rectangle's global bounds
		var rect_global_left = rect_global_position.x - rect_global_extents.x
		var rect_global_right = rect_global_position.x + rect_global_extents.x
		var rect_global_top = rect_global_position.y - rect_global_extents.y
		var rect_global_bottom = rect_global_position.y + rect_global_extents.y

		# Check if the point is within the rectangle's global bounds
		return point.x >= rect_global_left and point.x <= rect_global_right and \
			   point.y >= rect_global_top and point.y <= rect_global_bottom
	else:
		return false


func _on_life_time_timeout() -> void:
	queue_free()
