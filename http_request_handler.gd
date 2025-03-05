extends Node

signal data_sent(data)

var http_request: HTTPRequest

func _ready():
	# Création d'une instance HTTPRequest
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

# Fonction générique pour faire des requêtes HTTP
func send_request(url: String, method: HTTPClient.Method = HTTPClient.METHOD_GET, body_data: Dictionary = {}):
	var headers = ["Content-Type: application/json"]  # Ajout du header JSON
	var body_string = ""

	if method == HTTPClient.METHOD_POST or method == HTTPClient.METHOD_PUT:
		body_string = JSON.stringify(body_data)  # Convertir le dictionnaire en JSON

	var error = http_request.request(url, headers, method, body_string)
	if error != OK:
		push_error("Erreur lors de la requête HTTP.")
	else:
		print("Requête envoyée :", method, url)

# Gestion de la réponse
func _on_request_completed(result, response_code, headers, body):
	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())

	if parse_result == OK:
		var response = json.get_data()
		
		# Gestion des réponses en fonction de l'URL ou du type de requête
		_handle_response(response_code, response)
	else:
		print("Error while parsing JSON")

# Fonction pour gérer différentes réponses selon la requête envoyée
func _handle_response(response_code: int, response: Dictionary):
	data_sent.emit(response)
