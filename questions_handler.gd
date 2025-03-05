extends Node

signal questions_ready
signal random_pick

@export var main_scene: Node

var current_question: Dictionary
var questions_set: Dictionary

var questions: Array
var answers: Array


func _ready():
	await get_tree().process_frame
	main_scene = get_node_or_null("/root/Main")
	await main_scene.data_ready
	questions = GameData.questions
	answers = GameData.answers
	
	current_question = questions.pick_random()
	questions_set.get_or_add(current_question.id)
	questions_ready.emit()


func pick_random_question():
	if (questions_set.size() == questions.size()):
		questions_set.clear()
		questions_set.get_or_add(current_question)
	var random_question = questions.pick_random()
	while (questions_set.has(random_question.id)):
		random_question = questions.pick_random()
	questions_set.get_or_add(random_question.id)
	current_question = random_question
