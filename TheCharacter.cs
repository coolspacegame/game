using Godot;
using System;

public partial class TheCharacter : RigidBody2D
{
    [Signal]
    public delegate void InputForceAppliedEventHandler(Vector2 force);
    
    [Signal]
    public delegate void PositionUpdatedEventHandler(Vector2 position);
    
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
        const float meteorMass = 5000000.0f;
        const float characterMass = 1.0f;
        const float gravitationalConstant = 10.0f;

        var forceDir = -1.0f * GlobalPosition.Normalized();
        var radius = GlobalPosition.Length();
        var forceMagnitude = gravitationalConstant * meteorMass * characterMass / (radius * radius);

        ApplyCentralForce(forceMagnitude * forceDir);
        var inputForce = 1.0f * _mouseUpdate;
        ApplyCentralForce(inputForce);
        
        EmitSignalInputForceApplied(_mouseUpdate);
        EmitSignalPositionUpdated(GlobalPosition);
        
        base._PhysicsProcess(delta);
    }
}
