using Godot;
using System;

public partial class TheCamera : RigidBody2D
{
    public void OnCharacterPositionUpdated(Vector2 position)

    {
        const float springConstant = 10.0f;
        const float dampingConstant = 3.0f;
        var springForce = -springConstant * (GlobalPosition - position) - dampingConstant * LinearVelocity;
        ApplyCentralForce(springForce);
    }
}
