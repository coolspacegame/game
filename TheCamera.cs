using Godot;
using System;

public partial class TheCamera : RigidBody2D
{
    [Signal]
    public delegate void PositionUpdatedEventHandler(Vector2 position);
    
    public void OnCharacterPositionUpdated(Vector2 position)

    {
        const float springConstant = 10.0f;
        const float dampingConstant = 2.0f;
        var springForce = -springConstant * (GlobalPosition - position) - dampingConstant * LinearVelocity;
        ApplyCentralForce(springForce);
        
    }
    
    public void OnCharacterRotationUpdated(float rotation)

    {
        // const float springConstant = 2000.0f;
        // const float dampingConstant = 2.32f;
        //
        // var rotationDiff = GlobalRotation - rotation;
        // if (Mathf.Abs(rotationDiff) > Mathf.Pi)
        // {
        //     if (rotationDiff > 0)
        //     {
        //         rotationDiff -= 2 * Mathf.Pi;
        //     }
        //     else
        //     {
        //         rotationDiff += 2 * Mathf.Pi;
        //     }
        // }
        //
        //
        // var springTorque = -springConstant * rotationDiff - dampingConstant * AngularVelocity;
        // ApplyTorque(springTorque);

        GlobalRotation = rotation;

    }

    public override void _PhysicsProcess(double delta)
    {
        base._PhysicsProcess(delta);
        
        EmitSignalPositionUpdated(GlobalPosition);
    }
}
