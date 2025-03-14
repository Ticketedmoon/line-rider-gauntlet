package game

import rl "vendor:raylib"

main :: proc() {

    rl.InitWindow(1280, 720, "Line Rider Gauntlet")

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        rl.ClearBackground(rl.)
        rl.EndDrawing()
    }

    rl.CloseWindow()
}