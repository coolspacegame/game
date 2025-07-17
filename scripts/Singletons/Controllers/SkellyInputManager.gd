extends Node

class_name SkellyController

signal _on_input_left
signal _on_input_right
signal _on_input_forward
signal _on_input_backward
signal _on_input_jump
signal _on_input_0
signal _on_input_1
signal _on_input_2
signal _on_input_3
signal _on_input_pause

var _game_inputs: Dictionary = {}


func _input(event: InputEvent) -> void:
	var input_to_emit = _game_inputs.get(event.as_text())
	if input_to_emit != null:
		print(event)
		_emit_message(input_to_emit, event)


## Finds all input mapped inputs assuming the 'skelly' prefix and sets the _game_inputs dictionary
func _initialize_controller_game_inputs() -> void:
	var input_action_array = []
	for mapped_input in ProjectSettings.get_property_list().filter(
		func(Property): return "input/skelly" in Property.name
	):
		var mapped_input_name = mapped_input.name.split("/")[-1]
		for input_action_event in InputMap.action_get_events(mapped_input_name):
			var key_input: String
			if input_action_event is InputEventKey:
				key_input = OS.get_keycode_string(
					input_action_event.get_physical_keycode_with_modifiers()
				)
				_game_inputs.get_or_add(
					key_input, InputConstants.InputActionStringToEnum[mapped_input_name]
				)
			else:
				#TODO: May need to update this else statement when/if gamepads are added
				key_input = input_action_event.as_text()
				_game_inputs.get_or_add(
					key_input, InputConstants.InputActionStringToEnum[mapped_input_name]
				)


## 	Emit message to subscribers. Subscribers should already now the action input, and the event will
##	be passed to handle modifiers and states by the subscriber
func _emit_message(InputEnum: InputConstants.InputAction, event: InputEvent):
	match InputEnum:
		InputConstants.InputAction.INPUT_ACTION_LEFT:
			_on_input_left.emit(event)

		InputConstants.InputAction.INPUT_ACTION_RIGHT:
			_on_input_right.emit(event)

		InputConstants.InputAction.INPUT_ACTION_FORWARD:
			_on_input_forward.emit(event)

		InputConstants.InputAction.INPUT_ACTION_BACKWARD:
			_on_input_backward.emit(event)

		InputConstants.InputAction.INPUT_ACTION_JUMP:
			_on_input_jump.emit(event)

		InputConstants.InputAction.INPUT_ACTION_0:
			_on_input_0.emit(event)

		InputConstants.InputAction.INPUT_ACTION_1:
			_on_input_1.emit(event)

		InputConstants.InputAction.INPUT_ACTION_2:
			_on_input_2.emit(event)

		InputConstants.InputAction.INPUT_ACTION_3:
			_on_input_3.emit(event)

		InputConstants.InputAction.INPUT_ACTION_PAUSE:
			_on_input_pause.emit(event)

		InputConstants.InputAction.DEFAULT:
			print("What did you do?!?")


func _init() -> void:
	_initialize_controller_game_inputs()
