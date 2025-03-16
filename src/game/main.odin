package game

import "core:fmt"
import "core:math/rand"

import rl "vendor:raylib"

@(private="file")
backgroundColour: rl.Color = rl.ORANGE
@(private="file")
playerSize :: rl.Vector2{64, 64}
@(private="file")
playerColour: rl.Color = rl.BLUE
@(private="file")
playerPos := rl.Vector2{320, 320}
@(private="file")
lines: [dynamic][dynamic]rl.Vector2
@(private="file")
currentlinePolygonsBuffer: [dynamic]rl.Vector2

main :: proc() {

    //rl.SetConfigFlags(rl.FLAG_WINDOW_RESIZABLE | rl.FLAG_VSYNC_HINT)
    rl.SetTraceLogLevel(rl.TraceLogLevel.WARNING)
    rl.InitWindow(1280, 720, "Skybreak/Line-Rider-Gauntlet")
    rl.SetTargetFPS(60)

    for !rl.WindowShouldClose() {
        update()
        render()
    }

    rl.CloseWindow()
}

update :: proc() {

    old_player_pos := playerPos
    checkForKeyPress()
    checkForMouseInput()
    checkForCollision(old_player_pos)
}

render :: proc() {
    rl.BeginDrawing()
    rl.ClearBackground(backgroundColour)
    rl.DrawRectangleV(playerPos, playerSize, playerColour)
    rl.DrawRectangleV({960,320}, {64, 64}, rl.GREEN)

    // Render current line polygon buffer temporarily
    if len(currentlinePolygonsBuffer) > 0 {
        for i in 0..<len(currentlinePolygonsBuffer) - 1 {
            rl.DrawLineEx(currentlinePolygonsBuffer[i], currentlinePolygonsBuffer[i + 1], 12, rl.RED)
        }
    }

    if len(lines) > 0 {
        for i in 0..<len(lines) {
            line := lines[i]
            for j in 0..<len(line) - 1 {
                rl.DrawLineEx(line[j], line[j + 1], 12, rl.BLUE)
            }
        }
    }

    rl.EndDrawing();
}

checkForMouseInput :: proc() {

    if rl.IsMouseButtonReleased(.LEFT) {
        fmt.printf("rel: %d\n", len(currentlinePolygonsBuffer))
        // If there are vertices/polygons in the temporary line buffer
        // commit them to in-memory store
        // wipe current line buffer

        if len(currentlinePolygonsBuffer) > 1 {
            append(&lines, currentlinePolygonsBuffer)
            currentlinePolygonsBuffer = [dynamic]rl.Vector2{}
        }
        return;
    }

    if rl.IsMouseButtonDown(.LEFT) {
        mPos: rl.Vector2 = rl.GetMousePosition()
        colour: rl.Color = rl.Color{0, 0, 0, 255}

        polygonPos := rl.Vector2{mPos.x, mPos.y}
        append(&currentlinePolygonsBuffer, polygonPos)
        return;
    }

}

checkForKeyPress :: proc() {
    if rl.IsKeyPressed(.H) {
        backgroundColour = rl.Color{
            cast(u8) (rand.float32()*255),
            cast(u8) (rand.float32()*255),
            cast(u8) (rand.float32()*255),
            255
        }
    }

    if rl.IsKeyDown(.UP) {
        playerPos.y -= 400 * rl.GetFrameTime()
    }
    if rl.IsKeyDown(.DOWN) {
        playerPos.y += 400 * rl.GetFrameTime()
    }
    if rl.IsKeyDown(.LEFT) {
        playerPos.x -= 400 * rl.GetFrameTime()
    }
    if rl.IsKeyDown(.RIGHT) {
        playerPos.x += 400 * rl.GetFrameTime()
    }
}

checkForCollision :: proc(old_player_pos: rl.Vector2) {
    player_rect := rl.Rectangle{playerPos.x, playerPos.y, playerSize.x, playerSize.y}
    other_rect := rl.Rectangle{960, 320, 64, 64}

    if rl.CheckCollisionRecs(player_rect, other_rect) {
        playerColour = rl.RED
        playerPos = old_player_pos
        return
    } 
    
    playerColour = rl.BLUE
}