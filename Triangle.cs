using Godot;
using System;

public partial class Triangle : Node2D
{
    
    private Vector2 _newScale = Vector2.One;
    public void OnInputForceApplied(Vector2 force)
    {
        // GD.Print(force.Length());
        // Mathf.Lerp(0.0f, 10.0f, Mathf.Clamp())
        // Scale =  ;
        var scaledForce = force.Length() * 0.05f;

        var unitForce = force.Normalized();
        var angle = Mathf.Atan2(unitForce.Y, unitForce.X);

        var newScale = new Vector2(Mathf.Clamp(scaledForce, 0.0f, 2.0f), 1.0f);
        SetScale(newScale);
        // SetRotation(angle);
        SetGlobalRotation(angle);
    }
    
    public void OnInputTorqueApplied(float torque)
    {
        // GD.Print(force.Length());
        // Mathf.Lerp(0.0f, 10.0f, Mathf.Clamp())
        // Scale =  ;
        var scaledTorque = Mathf.Abs(torque) * 0.01f;

        // var unitForce = ;
        // var angle = Mathf.Atan2(unitForce.Y, unitForce.X);

        var newScale = new Vector2(Mathf.Clamp(scaledTorque, 0.0f, 1.0f), 1.0f);
        SetScale(newScale);
        SetRotation(torque > 0 ? 0 : Mathf.Pi);
    }
}
