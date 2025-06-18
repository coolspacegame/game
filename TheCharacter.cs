using Godot;
using System;

public partial class TheCharacter : RigidBody2D
{
    [Signal]
    public delegate void InputForceAppliedEventHandler(Vector2 force);
    
    private Vector2 _mouseUpdate = Vector2.Zero;
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
        }
        
    }

    public override void _Process(double delta)
    {
        base._Process(delta);
    }

    public override void _PhysicsProcess(double delta)
    {
        
        // GD.Print("test");
        // base._PhysicsProcess(delta);

        ApplyCentralForce(-1.0f * GlobalPosition);
        var force = 1.0f * _mouseUpdate;
        ApplyCentralForce(force);
        
        EmitSignalInputForceApplied(_mouseUpdate);
        // _mouseUpdate = Vector2.Zero;
        base._PhysicsProcess(delta);
    }
}
