using Godot;
using System;

public partial class TheCharacter : RigidBody2D
{
    [Signal]
    public delegate void InputTorqueAppliedEventHandler(float torque);
    [Signal]
    public delegate void InputForceAppliedEventHandler(Vector2 force);
    
    [Signal]
    public delegate void PositionUpdatedEventHandler(Vector2 position);
    
    [Signal]
    public delegate void RotationUpdatedEventHandler(float rotation);
    
    private Vector2 _mouseUpdate = Vector2.Zero;
    private Vector2I _inputDirState = Vector2I.Zero;
    private bool _mouseButtonPressed = false;
    public override void _UnhandledInput(InputEvent @event)
    {

        if (@event is InputEventMouseMotion mouseMotion)
        {

            if (_mouseButtonPressed)
            {
                _mouseUpdate += mouseMotion.Relative;
            }
        } else if (@event is InputEventMouseButton mouseButton)
        {
            _mouseUpdate = Vector2.Zero;
            _mouseButtonPressed = mouseButton.IsPressed();
        } else if (@event is InputEventKey keyEvent)
        {
            
            if (keyEvent.Keycode == Key.W)
            {
                _inputDirState += Vector2I.Up * (keyEvent.Pressed ? 1 : -1);
            } else if (keyEvent.Keycode == Key.A)
            {
                _inputDirState += Vector2I.Left * (keyEvent.Pressed ? 1 : -1);
            } else if (keyEvent.Keycode == Key.S)
            {
                _inputDirState += Vector2I.Down * (keyEvent.Pressed ? 1 : -1);
            } else if (keyEvent.Keycode == Key.D)
            {
                _inputDirState += Vector2I.Right * (keyEvent.Pressed ? 1 : -1);
            }
            _inputDirState = new Vector2I(Math.Clamp(_inputDirState.X, -1, 1), Math.Clamp(_inputDirState.Y, -1, 1));
        }
        
    }

    public override void _Process(double delta)
    {
        base._Process(delta);
    }

    public override void _PhysicsProcess(double delta)
    {
        
        // base._PhysicsProcess(delta);
        // const float meteorMass = 5000000.0f;
        // const float characterMass = 1.0f;
        // const float gravitationalConstant = 10.0f;

        // var forceDir = -1.0f * GlobalPosition.Normalized();
        // var radius = GlobalPosition.Length();
        // var forceMagnitude = gravitationalConstant * meteorMass * characterMass / (radius * radius);

        // ApplyCentralForce(forceMagnitude * forceDir);
        // var inputForce = 1.0f * _mouseUpdate;
        var inputForce = 50000f * _inputDirState.Y * Vector2.Up;
        inputForce = Transform.BasisXform(inputForce).Rotated(Mathf.Pi);
        ApplyCentralForce(inputForce);
        
        var inputTorque = 200000f * _inputDirState.X;
        ApplyTorque(inputTorque);
        
        EmitSignalInputTorqueApplied(inputTorque);
        EmitSignalInputForceApplied(inputForce);
        EmitSignalPositionUpdated(GlobalPosition);
        EmitSignalRotationUpdated(GlobalRotation);
        
        base._PhysicsProcess(delta);
    }
}
