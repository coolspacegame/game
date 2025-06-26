using Godot;
using System;

public partial class Background : MeshInstance2D
{
    public void OnCameraPositionUpdated (Vector2 position)
    {
        GlobalPosition = position;
    }
}
