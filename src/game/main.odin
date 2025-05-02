package game

import b2 "vendor:box2d"
import rl "vendor:raylib"

LineSegment :: struct {
    start: rl.Vector2,
    end: rl.Vector2,
    body_id: b2.BodyId,
}

main :: proc() {
    rl.InitWindow(800, 600, "Multiple Collidable Lines with Mouse")
    defer rl.CloseWindow()

    rl.SetTargetFPS(60)

    scale: f32 = 0.125 // 100 pixels = 1 meter

    // Create Box2D world
    world_def := b2.DefaultWorldDef()
    world_def.gravity = b2.Vec2{0.0, 9.8}
    world_id := b2.CreateWorld(world_def)

    // Ball body definition (dynamic, at position 400,100 in pixels, converted to meters)
    box_body_def := b2.DefaultBodyDef()
    box_body_def.type = b2.BodyType.dynamicBody
    box_body_def.position = b2.Vec2{f32(400) * scale, f32(100) * scale}

    // Ball shape definition (density and friction typical for a ball)
    box_shape_def := b2.DefaultShapeDef()
    box_shape_def.density = 1.0
    box_shape_def.friction = 0.3

    box_body_id := b2.CreateBody(world_id, box_body_def)

    box_vertices := b2.MakeSquare(0.5)
    circle := b2.Circle{
        center = b2.Vec2{0.0, 0.0}, // Relative to the body's origin
        radius = 0.5,          // Radius in meters
    }

    // Line drawing state
    drawing_line := false
    ball_created := false
    mouse_start := rl.Vector2{}
    mouse_end   := rl.Vector2{}

    lines: [dynamic]LineSegment = {}

    for !rl.WindowShouldClose() {
        // Handle mouse input
        if rl.IsMouseButtonPressed(.LEFT) {
            mouse_start = rl.GetMousePosition()
            drawing_line = true
        }
        if rl.IsMouseButtonReleased(.LEFT) && drawing_line {
            mouse_end = rl.GetMousePosition()
            drawing_line = false

            // Convert to Box2D world coordinates
            start_world := b2.Vec2{f32(mouse_start.x) * scale, f32(mouse_start.y) * scale}
            end_world   := b2.Vec2{f32(mouse_end.x) * scale, f32(mouse_end.y) * scale}

            // Create static edge body
            edge_body_def := b2.DefaultBodyDef()
            edge_body_def.type = b2.BodyType.staticBody
            edge_body_def.position = b2.Vec2{0.0, 0.0}
            edge_body_id := b2.CreateBody(world_id, edge_body_def)

            edge_shape_def := b2.DefaultShapeDef()
            edge_shape_def.friction = 0.6
            segment := b2.Segment{start_world, end_world}
            _ = b2.CreateSegmentShape(edge_body_id, edge_shape_def, segment)

            // Store line segment
            line := LineSegment{
                start = mouse_start,
                end   = mouse_end,
                body_id = edge_body_id,
            }
            append(&lines, line)
        }

        // Spawn the dynamic box when space is pressed
        if !ball_created && rl.IsKeyPressed(.SPACE) {
            box_body_def := b2.DefaultBodyDef()
            box_body_def.type = b2.BodyType.dynamicBody
            box_body_def.position = b2.Vec2{f32(400) * scale, f32(100) * scale}
            box_body_id = b2.CreateBody(world_id, box_body_def)

            box_shape_def := b2.DefaultShapeDef()
            box_shape_def.density = 1.0
            box_shape_def.friction = 0.3
            box_vertices := b2.MakeSquare(0.5)
            _ = b2.CreateCircleShape(box_body_id, box_shape_def, circle)

            ball_created = true
        }

        if ball_created {
            // Step the physics world
            b2.World_Step(world_id, 1.0 / 60.0, 6)

        }

        rl.BeginDrawing()
        rl.ClearBackground(rl.RAYWHITE)

        // Draw in-progress line
        if drawing_line {
            current := rl.GetMousePosition()
            rl.DrawLineV(mouse_start, current, rl.GRAY)
        }

        // Draw all stored lines
        for line in lines {
            rl.DrawLineV(line.start, line.end, rl.BLACK)
        }

        // Draw falling dynamic box
        pos := b2.Body_GetPosition(box_body_id)
        x := i32(pos.x / scale)
        y := i32(pos.y / scale)

        rl.DrawCircle(x, y, circle.radius / scale, rl.RED)
        rl.DrawText("Click and drag to draw collidable lines", 10, 10, 20, rl.DARKGRAY)
        rl.EndDrawing()
    }

    b2.DestroyWorld(world_id)
}
