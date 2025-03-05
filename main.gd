extends Node

signal	data_ready

@export var question_duration = 5.0
@export var max_enemies = 10
@export var spawn_radius = 50
@export var enemy_scene: PackedScene
@export var reduce_spawn_interval: int = 2

var time_elapsed = 0
var spawn_interval = 2.0
var spawn_interval_counter = 0.0
var score = 0
var is_in_game = false
var spawn_counter = 0.0
var http_data
var modulate_color: Color
var game_duration: float
var z_index_counter = 0

@onready var hud = $HUD
@onready var game_timer = $GameTimer
@onready var question_timer = $QuestionTimer
@onready var http_handler = $HttpRequestHandler
@onready var enemies_group: Node = $EnemiesGroup

var test_data

func restart_game():
	print("GODOT : test_data -> ", test_data)
	score = 0
	time_elapsed = 0
	spawn_interval = 2.0
	hud.update_score(score)
	game_timer.start(game_duration)
	question_timer.start(question_duration)


func process_game_data(data: Dictionary):
	GameData.gameSeed = data.seed
	GameData.schoolclassId = data.schoolclassId
	GameData.studentId = data.studentId
	GameData.professorId = data.professorId
	GameData.subjectId = data.subjectId
	GameData.lessonContent = data.hackatoonRaid.lessonContent
	GameData.questions = data.questions
	GameData.answers = data.answers

var callback = JavaScriptBridge.create_callback(self.receive_data)

func _ready() -> void:
	JavaScriptBridge.eval("""
		if (window.opener) {
			window.opener.postMessage({type:'godot-ready'}, '*');
		}
	""", true)
	
	var window = JavaScriptBridge.get_interface("window")
	window.postMessage = callback
	http_handler.data_sent.connect(_on_data_received)
	#QuestionsHandler.questions_ready.connect(_on_questions_ready)
	await http_handler.send_request('http://localhost:8080/api/hackatoon')
	await http_handler.data_sent
	process_game_data(http_data)
	randomize()
	seed(GameData.gameSeed)
	data_ready.emit()
	if (QuestionsHandler.questions.is_empty()):
		await QuestionsHandler.questions_ready
	game_duration = GameData.questions.size() * question_duration * 2

func receive_data(data):
	print("GODOT : Receive data from Vue app : ")
	print(data)
	test_data = data

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (not is_in_game):
		return
	time_elapsed += delta
	spawn_counter += delta
	spawn_interval_counter += delta
	var ratio = clamp(1.0 - (time_elapsed / game_duration), 0.0, 1.0)
	hud.set_progress_bar_ratio(ratio)
	if (time_elapsed >= game_duration):
		end_game()
		return
	if (spawn_counter >= spawn_interval):
		if (get_tree().get_nodes_in_group("enemies").size() < max_enemies):
			spawn_enemy()
		spawn_counter = 0.0
	
	if (spawn_interval_counter >= reduce_spawn_interval):
		spawn_interval = max(0.2, spawn_interval - 0.2)
		spawn_interval_counter = 0.0


func spawn_enemy():
	var enemy = enemy_scene.instantiate()
	enemy.position = get_random_position()
	enemies_group.add_child(enemy)
	enemy.z_index = z_index_counter
	z_index_counter += 1
	enemy.connect("enemy_clicked", _on_enemy_clicked)


func get_random_position():
	var pos
	var tries = 0
	while tries < 10:
		pos = Vector2(randf_range(50, 750), randf_range(50, 550))
		var overlaps = false
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if (enemy.position.distance_to(pos) < spawn_radius):
				overlaps = true
				break
		if not overlaps:
			return pos
		tries += 1
	print("Tries : " + str(tries))
	return pos


func end_game():
	game_timer.stop()
	question_timer.stop()
	hud.show_game_over()
	is_in_game = false
	get_tree().call_group("enemies", "queue_free")


func _on_enemy_clicked(is_good):
	score += 100 if is_good else -75
	modulate_color = Color(0.796, 0.883, 0.712, 0.1) if is_good else Color(0.983, 0.416, 0.542, 0.1)
	$ColorRect.color = modulate_color
	hud.update_score(score)
	$FlashTimer.start(randf_range(0.1, 0.5))


func _on_hud_start_game() -> void:
	get_tree().call_group("enemies", "queue_free")
	is_in_game = true
	restart_game()


func _on_data_received(data):
	http_data = data


func _on_flash_timer_timeout() -> void:
	$ColorRect.color = Color(1, 1, 1, 0)


func _on_question_timer_timeout() -> void:
	QuestionsHandler.pick_random_question()
	var current_enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in current_enemies:
		if (enemy.answer.questionId == QuestionsHandler.current_question.id and enemy.answer.isValid):
			enemy.is_good_answer = true
		else:
			enemy.is_good_answer = false
	QuestionsHandler.random_pick.emit()
