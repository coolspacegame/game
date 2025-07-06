extends Node

class_name SkellyController

const InputConstants := preload("res://scripts/Singletons/Constants/InputConstants.gd")

signal _on_input_left()
signal _on_input_right()
signal _on_input_forward()
signal _on_input_backward()
signal _on_input_jump()
signal _on_input_0()
signal _on_input_1()
signal _on_input_2()
signal _on_input_3()
signal _on_input_pause()



var _GameInputs : Dictionary = {}

func _input(event: InputEvent) -> void:
	var InputToEmit = _GameInputs.get(event.as_text())
	if InputToEmit != null:
		_EmitMessage(InputToEmit)
		
## Finds all input mapped inputs assuming the 'skelly' prefix and sets the _GameInputs dictionary
func _InitializeControllerGameInputs() -> void:
	var InputActionArray = []
	for MappedInput in ProjectSettings.get_property_list().filter(func(Property): return "input/skelly" in Property.name):
		var MappedInputName = MappedInput.name.split("/")[-1]
		for InputActionEvent in InputMap.action_get_events(MappedInputName):
			var KeyInput : String
			if InputActionEvent is InputEventKey:
				KeyInput = OS.get_keycode_string(InputActionEvent.get_physical_keycode_with_modifiers())
				_GameInputs.get_or_add(KeyInput, InputConstants.InputActionEnumToString[MappedInputName])
			else:
				KeyInput = InputActionEvent.as_text()
				_GameInputs.get_or_add(KeyInput, InputConstants.InputActionEnumToString[MappedInputName])

func _EmitMessage(InputEnum : InputConstants.InputAction):
	match InputEnum:
		InputConstants.InputAction.INPUT_ACTION_LEFT:
			_on_input_left.emit()
			
		InputConstants.InputAction.INPUT_ACTION_RIGHT:
			_on_input_right.emit()

		InputConstants.InputAction.INPUT_ACTION_FORWARD:
			_on_input_forward.emit()

		InputConstants.InputAction.INPUT_ACTION_BACKWARD:
			_on_input_backward.emit()

		InputConstants.InputAction.INPUT_ACTION_JUMP:
			_on_input_jump.emit()

		InputConstants.InputAction.INPUT_ACTION_0:
			_on_input_0.emit()

		InputConstants.InputAction.INPUT_ACTION_1:
			_on_input_1.emit()

		InputConstants.InputAction.INPUT_ACTION_2:
			_on_input_2.emit()

		InputConstants.InputAction.INPUT_ACTION_3:
			_on_input_3.emit()

		InputConstants.InputAction.INPUT_ACTION_PAUSE:
			_on_input_pause.emit()

		InputConstants.InputAction.DEFAULT:
			print("What did you do?!?")

func _init() -> void:	
	_InitializeControllerGameInputs()
