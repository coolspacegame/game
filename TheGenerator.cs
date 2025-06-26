using Godot;
using System;
using System.Collections.Generic;

public partial class TheGenerator : Node2D
{
    // [Export] private FastNoiseLite _noise;
    [Export] private FastNoiseLite _spawnNoise;

    
    private const float squareChunkSize = 512;

    // private const float asteroidRadius = squareChunkSize / 10;

    // how many times the chunk is subdivided to get the fine grid
    private const int fineGridDepth = 5;

    // private const int searchDepth = 2;

    private void GenerateChunk(Vector2I chunkCoord)
    {
        // chunk location in world coordinates
        var chunkStart = squareChunkSize * new Vector2(chunkCoord.X, chunkCoord.Y);
        var chunkSize = squareChunkSize * Vector2.One;
        var chunkBounds = new Rect2(chunkStart, chunkSize);
        

        var fineGridResolution = Mathf.RoundToInt(Mathf.Pow(2, fineGridDepth));
        // chunk location in fine grid coordinates
        var fineGridChunkCoord = chunkCoord * fineGridResolution;

        var fineGridSize = squareChunkSize / fineGridResolution;
        

        var p = new GenerateParameters();
        p.SquareTileSize = fineGridSize;
        p.NoiseMin = -1.0f;
        p.NoiseMax = -0.65f;
        p.NoiseSource = _spawnNoise;
        
        var noiseInRange = (float noise) => noise > p.NoiseMin && noise < p.NoiseMax;

        var fineGridTiles = new Dictionary<Vector2I, Tile>();

        for (var i = 0; i < fineGridResolution; i++)
        {
            for (var j = 0; j < fineGridResolution; j++)
            {

                fineGridTiles.Add(fineGridChunkCoord + new Vector2I(i, j), new Tile());
            }
        }

        // while there's still possible asteroids to generate
        while (fineGridTiles.Count > 0)
        {
            var asteroidTiles = new List<Vector2I>();

            var e = fineGridTiles.GetEnumerator();
            e.MoveNext();
            var (coord, tile) = e.Current;

            // visited.Add(coord);
            
            var worldPos = new Vector2(coord.X, coord.Y) * fineGridSize + Vector2.One * fineGridSize / 2;
            var noise = p.NoiseSource.GetNoise2Dv(worldPos);
            
            // repeat until there's a valid seed
            while ( !noiseInRange(noise) || !chunkBounds.HasPoint(worldPos))
            {
                fineGridTiles.Remove(coord);
                
                // if there's no tiles left to check, then there's no valid asteroid seeds and the chunk is finished
                if (fineGridTiles.Count == 0)
                {
                    return;
                }
                
                e = fineGridTiles.GetEnumerator();
                e.MoveNext();
                (coord, tile) = e.Current;
                // visited.Add(coord);
                worldPos = new Vector2(coord.X, coord.Y) * fineGridSize + Vector2.One * fineGridSize / 2;
                noise = p.NoiseSource.GetNoise2Dv(worldPos);
            }

            // if we made it this far, we have an asteroid seed
            
            // asteroidTiles.Add(coord);
    
            var stack = new List<Vector2I>();
            var visited = new HashSet<Vector2I>();

            var current = coord;
            stack.Add(current);

            while (stack.Count > 0)
            {
                current = stack[stack.Count - 1];
                visited.Add(current);
                fineGridTiles.Remove(current);
                stack.RemoveAt(stack.Count - 1);
        
                var directions = new[]
                {
                    Vector2I.Up,
                    Vector2I.Left,
                    Vector2I.Right,
                    Vector2I.Down,
                };

                foreach (var d in directions)
                {
                    var neighbor = current + d;

                    var posWorld = p.SquareTileSize * new Vector2(neighbor.X, neighbor.Y);
                    noise = p.NoiseSource.GetNoise2Dv(posWorld);
                    if (fineGridTiles.ContainsKey(neighbor) 
                        && !visited.Contains(neighbor) 
                        && noiseInRange(noise)
                        && chunkBounds.HasPoint(posWorld))
                    {
                        stack.Add(neighbor);
                    }
                }
            }

            var maxCorner = new Vector2(float.MinValue, float.MinValue);
            var minCorner = new Vector2(float.MaxValue, float.MaxValue);
            
            foreach (var t in visited)
            {
                var v = new Vector2(t.X,  t.Y) * p.SquareTileSize;

                if (v.X > maxCorner.X)
                {
                    maxCorner.X = v.X;
                }
                if (v.Y > maxCorner.Y)
                {
                    maxCorner.Y = v.Y;
                }
                if (v.X < minCorner.X)
                {
                    minCorner.X = v.X;
                }
                if (v.Y < minCorner.Y)
                {
                    minCorner.Y = v.Y;
                }
                
                asteroidTiles.Add(t);
            }

            // easy way to clean up the noise
            if (asteroidTiles.Count == 1)
            {
                continue;
            }
            
            var asteroid = new TheAsteroid();
            var rigidBody = new RigidBody2D();
            var collisionShape = new CollisionShape2D();

            var shape = new RectangleShape2D();
            shape.Size = maxCorner - minCorner;
            collisionShape.Shape = shape;

            var asteroidCenter = (maxCorner + minCorner) / 2;
            
            rigidBody.Mass = 10f * asteroidTiles.Count;
            rigidBody.Transform = rigidBody.Transform.Translated(asteroidCenter);
            
            asteroid.GenerateMesh(asteroidTiles, p.SquareTileSize, asteroidCenter);
            
            rigidBody.AddChild(collisionShape);
            rigidBody.AddChild(asteroid);
            AddChild(rigidBody);
        }
    }
    public override void _Ready()
    {
        const int size = 4;
        for (int i = -size/2; i < size/2; i++)
        {
            for (int j = -size/2; j < size/2; j++)
            {
                GenerateChunk(new Vector2I(i, j));
            }
        }
    }
}
