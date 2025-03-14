package game

import "core:fmt"
import "core:math/rand"

import rl "vendor:raylib"

background_colour: rl.Color = rl.ORANGE

player_size :: rl.Vector2{64, 64}
player_colour: rl.Color = rl.BLUE
player_pos := rl.Vector2{320, 320}

main :: proc() {

    rl.InitWindow(1280, 720, "Skybreak/Line-Rider-Gauntlet")
    rl.SetTargetFPS(60)

    for !rl.WindowShouldClose() {

        old_player_pos := player_pos

        update()
        render()

        if rl.CheckCollisionRecs(
            rl.Rectangle{player_pos.x, player_pos.y, player_size.x, player_size.y},
            rl.Rectangle{960, 320, 64, 64}) {
            player_colour = rl.RED
            player_pos = old_player_pos
        } else {
            player_colour = rl.BLUE
        }

    }

    rl.CloseWindow()
}

update :: proc() {

    if rl.IsKeyPressed(.H) {
        background_colour = rl.Color{
            cast(u8) (rand.float32()*255),
            cast(u8) (rand.float32()*255),
            cast(u8) (rand.float32()*255),
            255
        }
    }

    mPos: rl.Vector2 = rl.GetMousePosition()
    fmt.println("Mouse Position: ", mPos)

    if rl.IsKeyDown(.UP) {
        player_pos.y -= 400 * rl.GetFrameTime()
    }
    if rl.IsKeyDown(.DOWN) {
        player_pos.y += 400 * rl.GetFrameTime()
    }
    if rl.IsKeyDown(.LEFT) {
        player_pos.x -= 400 * rl.GetFrameTime()
    }
    if rl.IsKeyDown(.RIGHT) {
        player_pos.x += 400 * rl.GetFrameTime()
    }
}

render :: proc() {
    rl.BeginDrawing()
    rl.ClearBackground(background_colour)
    rl.DrawRectangleV(player_pos, player_size, player_colour)
    rl.DrawRectangleV({960,320}, {64, 64}, rl.GREEN)
    rl.EndDrawing()
}