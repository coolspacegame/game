using Godot;
using System;
using System.Collections.Generic;
using GArray = Godot.Collections.Array;

public struct GenerateParameters
{
    public Noise NoiseSource;
    public float NoiseMin;
    public float NoiseMax;
    public float SquareTileSize;
    
}
public class Tile;

public partial class TheAsteroid : Node2D
{

    private MeshInstance2D _meshNode;
    
    public TheAsteroid()
    {
        var m = new MeshInstance2D();
        AddChild(m);
        _meshNode = GetChild<MeshInstance2D>(0);
    }


    public void GenerateMesh(IEnumerable<Vector2I> tileCoords, float squareTileSize, Vector2 asteroidOrigin)
    {
        // Generate two mesh triangles for every tile
        // TODO do this more efficiently, reuse vertices
        // TODO maybe smooth out the mesh or add noise so it doesn't look blocky

        var verticesList = new List<Vector2>();
        
        foreach (var tileV in tileCoords)
        {
            verticesList.Add(squareTileSize * new Vector2(tileV.X, tileV.Y) - asteroidOrigin);
            verticesList.Add(squareTileSize * new Vector2(tileV.X, tileV.Y + 1) - asteroidOrigin);
            verticesList.Add(squareTileSize * new Vector2(tileV.X + 1, tileV.Y + 1) - asteroidOrigin);
            verticesList.Add(squareTileSize * new Vector2(tileV.X, tileV.Y) - asteroidOrigin);
            verticesList.Add(squareTileSize * new Vector2(tileV.X + 1, tileV.Y + 1) - asteroidOrigin);
            verticesList.Add(squareTileSize * new Vector2(tileV.X + 1, tileV.Y) - asteroidOrigin);
        }
        
        
        // Piece together the vertices to make the mesh
        var arrMesh = new ArrayMesh();
        GArray arrays = [];
        arrays.Resize((int)Mesh.ArrayType.Max);
        arrays[(int)Mesh.ArrayType.Vertex] = verticesList.ToArray();
        
        arrMesh.AddSurfaceFromArrays(Mesh.PrimitiveType.Triangles, arrays);
        _meshNode.Mesh = arrMesh;
    }
 
}


