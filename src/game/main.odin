package game

import b2 "vendor:box2d"
import rl "vendor:raylib"
import "core:math"

LineSegment :: struct {
    start: rl.Vector2,
    end: rl.Vector2,
    body_id: b2.BodyId,
}

Particle :: struct {
    pos: rl.Vector2,
    vel: rl.Vector2,
    color: rl.Color,
    lifetime: f32,
}

main :: proc() {
    rl.InitWindow(800, 600, "Multiple Collidable Lines with Mouse")
    defer rl.CloseWindow()

    rl.SetTargetFPS(60)
    rl.InitAudioDevice()
    defer rl.CloseAudioDevice()

    goal_sound := rl.LoadSound("assets/sfx/level-completion.mp3")
    scale: f32 = 0.085 // 100 pixels = 1 meter

    // Create Box2D world
    world_def := b2.DefaultWorldDef()
    world_def.gravity = b2.Vec2{0.0, 50.0}
    world_id := b2.CreateWorld(world_def)

    // Ball body definition (dynamic, at position 400,100 in pixels, converted to meters)
    box_body_def := b2.DefaultBodyDef()
    box_body_def.type = b2.BodyType.dynamicBody
    box_body_def.position = b2.Vec2{f32(40) * scale, f32(100) * scale}

    // Ball shape definition (density and friction typical for a ball)
    box_shape_def := b2.DefaultShapeDef()
    box_shape_def.density = 1.0
    box_shape_def.friction = 0.3
    box_shape_def.restitution = 0.3

    box_body_id := b2.CreateBody(world_id, box_body_def)

    box_vertices := b2.MakeSquare(0.5)
    circle := b2.Circle{
        center = b2.Vec2{0.0, 0.0}, // Relative to the body's origin
        radius = 0.5,          // Radius in meters
    }

    goal_pos  := rl.Vector2{700, 500} // screen space in pixels
    goal_size := rl.Vector2{40, 40}

    // Line drawing state
    drawing_line := false
    ball_created := false
    goal_reached := false
    mouse_start := rl.Vector2{}
    mouse_end   := rl.Vector2{}

    lines: [dynamic]LineSegment = {}
    particles: [dynamic]Particle = {}

    frame_counter: i32 = 0

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
            box_body_def.position = b2.Vec2{f32(40) * scale, f32(100) * scale}
            box_body_id = b2.CreateBody(world_id, box_body_def)

            box_shape_def := b2.DefaultShapeDef()
            box_shape_def.density = 1.0
            box_shape_def.friction = 0.3
            box_shape_def.restitution = 0.3
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

        pos := b2.Body_GetPosition(box_body_id)
        x := i32(pos.x / scale)
        y := i32(pos.y / scale)

        ball_screen_pos := rl.Vector2{f32(x), f32(y)}
        in_goal := rl.CheckCollisionPointRec(ball_screen_pos, rl.Rectangle{
            x = goal_pos.x,
            y = goal_pos.y,
            width = goal_size.x,
            height = goal_size.y,
        })

        frame_counter += 1
        pulse_color := (frame_counter / 16) % 2 == 0 ? rl.GREEN : rl.LIME
        color := in_goal ? rl.GREEN : pulse_color

        rl.DrawRectangleV(goal_pos, goal_size, color)
        rl.DrawRectangleLinesEx(rl.Rectangle{
            x = goal_pos.x,
            y = goal_pos.y,
            width = goal_size.x,
            height = goal_size.y,
        }, 4, rl.DARKGREEN)

        if in_goal && !goal_reached {
            goal_reached = true
            rl.PlaySound(goal_sound)
            rl.DrawText("GOAL!", 350, 50, 40, rl.DARKGREEN)
            spawn_confetti(&particles, goal_pos, goal_size)
        }

        update_and_draw_confetti(&particles, (1.0 / 60.0)) // Assuming fixed timestep

        rl.DrawCircle(x, y, circle.radius / scale, rl.RED)
        rl.DrawText("Click and drag to draw collidable lines", 10, 10, 20, rl.DARKGRAY)
        rl.EndDrawing()
    }

    b2.DestroyWorld(world_id)
}

spawn_confetti :: proc(particles: ^[dynamic]Particle, 
    goal_pos: rl.Vector2, 
    goal_size: rl.Vector2) {

    for i in 0..<20 {
        pos := rl.Vector2{
            goal_pos.x + f32(rl.GetRandomValue(0, i32(goal_size.x))),
            goal_pos.y + f32(rl.GetRandomValue(0, i32(goal_size.y))),
        }
        angle := f32(rl.GetRandomValue(0, 360)) * rl.DEG2RAD
        speed := f32(rl.GetRandomValue(20, 60) / 10.0)
        vel := rl.Vector2{
            math.cos(angle) * speed,
            math.sin(angle) * speed,
        }
        color := rl.ColorAlpha(rl.YELLOW, 1.0)
        _ = append(particles, Particle{pos, vel, color, 1.0})
    }
}

update_and_draw_confetti :: proc(particles: ^[dynamic]Particle, dt: f32) {
    i := 0
    for i < len(particles^) {
        p := &particles^[i]
        p.pos.x += p.vel.x * 60 * dt
        p.pos.y += p.vel.y * 60 * dt
        p.lifetime -= dt
        if p.lifetime <= 0 {

            // Remove by swapping with last and truncating
            last := len(particles^) - 1
            if i != last {
                particles^[i] = particles^[last]
            }

            resize(particles, last)
        } else {
            rl.DrawCircleV(p.pos, 3.0, p.color)
            i += 1
        }
    }
}