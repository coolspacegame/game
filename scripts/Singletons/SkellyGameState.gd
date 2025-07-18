extends Node

const DebugLibrary = preload("res://scripts/Develop/OutputFL.gd")

enum EGameState { LOADING, MENU, PLAYING, PAUSED, GAME_OVER }

enum EInGameState { NONE, ASTEROID, SPACE }

var _GameState: EGameState
var _InGameState: EInGameState

signal on_world_position_changed(NewPlayerPosition: EInGameState)
signal on_game_state_changed(NewGameState: EGameState)


func GetGameState():
	return _GameState


func SetGameState(NewGameState: EGameState):
	if _GameState != NewGameState:
		_GameState = NewGameState
		on_world_position_changed.emit(_GameState)
		_OutputNotifyGameState(_GameState, Color.ORCHID)


func GetInGameState():
	return _InGameState


func SetInGameState(NewInGameState: EInGameState):
	if _InGameState != NewInGameState:
		_InGameState = NewInGameState
		on_world_position_changed.emit(_InGameState)
		_OutputNotifyInGameState(_InGameState, Color.AQUAMARINE)


static func _OutputNotifyGameState(NotifyState: EGameState, TextColor: Color) -> void:
	var Output = DebugLibrary.AsRichColor(TextColor)
	print_rich(Output[0] + EGameState.keys()[NotifyState] + Output[1])


static func _OutputNotifyInGameState(NotifyState: EInGameState, TextColor: Color) -> void:
	var Output = DebugLibrary.AsRichColor(TextColor)
	print_rich(Output[0] + EInGameState.keys()[NotifyState] + Output[1])


func _init() -> void:
	SetGameState(EGameState.PLAYING)
	SetInGameState(EInGameState.SPACE)
