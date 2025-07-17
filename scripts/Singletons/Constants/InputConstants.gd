extends Node

enum InputAction {
	DEFAULT,
	INPUT_ACTION_LEFT,
	INPUT_ACTION_RIGHT,
	INPUT_ACTION_FORWARD,
	INPUT_ACTION_BACKWARD,
	INPUT_ACTION_JUMP,
	INPUT_ACTION_0,
	INPUT_ACTION_1,
	INPUT_ACTION_2,
	INPUT_ACTION_3,
	INPUT_ACTION_PAUSE
}

const InputActionStringToEnum = {
	"skelly_input_action_left": InputAction.INPUT_ACTION_LEFT,
	"skelly_input_action_right": InputAction.INPUT_ACTION_RIGHT,
	"skelly_input_action_forward": InputAction.INPUT_ACTION_FORWARD,
	"skelly_input_action_backward": InputAction.INPUT_ACTION_BACKWARD,
	"skelly_input_action_jump": InputAction.INPUT_ACTION_JUMP,
	"skelly_input_action_0": InputAction.INPUT_ACTION_0,
	"skelly_input_action_1": InputAction.INPUT_ACTION_1,
	"skelly_input_action_2": InputAction.INPUT_ACTION_2,
	"skelly_input_action_3": InputAction.INPUT_ACTION_3,
	"skelly_input_action_pause": InputAction.INPUT_ACTION_PAUSE
}
