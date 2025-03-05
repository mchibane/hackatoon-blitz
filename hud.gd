extends CanvasLayer

signal start_game

func _ready() -> void:
	QuestionsHandler.random_pick.connect(_on_questions_handler_random_pick)
	$QuestionLabel.hide()

func		set_message(text):
	$MessageLabel.text = text

func show_message(text):
	set_message(text)
	$MessageLabel.show()
	$MessageTimer.start()
	
func show_game_over():
	show_message("Game Over")
	
	await $MessageTimer.timeout
	
	$MessageLabel.text = "Click on the Enemies !"
	$MessageLabel.show()
	
	await get_tree().create_timer(1.0).timeout
	$StartButton.show()
	$TimerBar.hide()
	
func		update_score(score):
	$ScoreLabel.text = "Score : " + str(score)


func _on_start_button_pressed() -> void:
	$QuestionLabel.text = QuestionsHandler.current_question.name
	$MessageLabel.hide()
	$StartButton.hide()
	$TimerBar.show()
	$QuestionLabel.show()
	set_progress_bar_ratio(1.0)
	start_game.emit()

func _on_message_timer_timeout() -> void:
	$MessageLabel.hide()


func set_progress_bar_ratio(ratio):
	$TimerBar.ratio = ratio

func set_progres_bar(progress):
	$TimerBar.set_value_no_signal(progress)


func _on_questions_handler_random_pick() -> void:
	$QuestionLabel.text = QuestionsHandler.current_question.name
