using Godot;
using System;

public partial class FPSLabel : Label
{
    public override void _Process(double delta)
    {
        base._Process(delta);
        Text = $"FPS: {Engine.GetFramesPerSecond()}";
    }
}
