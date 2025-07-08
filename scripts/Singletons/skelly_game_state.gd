extends Node

const DebugLibrary = preload("res://scripts/Develop/OutputFL.gd")

enum EGameState {
	LOADING,
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER
}

enum EInGameState {
	NONE,
	ASTEROID,
	SPACE
}

var _game_state : EGameState
var _in_game_state: EInGameState

signal on_in_game_state_changed(new_player_position : EInGameState)
signal on_game_state_changed(new_game_state : EGameState)

func get_game_state():
	return _game_state

func set_game_state(new_game_state : EGameState):
	if _game_state != new_game_state:
		_game_state = new_game_state
		on_game_state_changed.emit(_game_state)
		_output_notify_game_state(_game_state, Color.ORCHID)

func get_in_game_state():
	return _in_game_state
	
func set_in_game_state(new_in_game_state : EInGameState):
	if _in_game_state != new_in_game_state:
		_in_game_state = new_in_game_state
		on_in_game_state_changed.emit(_in_game_state)
		_output_notify_in_game_state(_in_game_state, Color.AQUAMARINE)
		
static func _output_notify_game_state(notify_state : EGameState, text_color : Color) -> void:
	var output = DebugLibrary.as_rich_color(text_color)
	print_rich(output[0] + EGameState.keys()[notify_state] + output[1])
	
static func _output_notify_in_game_state(notify_state : EInGameState, text_color : Color) -> void:
	var output = DebugLibrary.as_rich_color(text_color)
	print_rich(output[0] + EInGameState.keys()[notify_state] + output[1])
	


func _init() -> void:
	set_game_state(EGameState.PLAYING)
	set_in_game_state(EInGameState.SPACE)
