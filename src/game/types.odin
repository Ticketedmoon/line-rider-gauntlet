package game

import rl "vendor:raylib"
import b2 "vendor:box2d"

Conversion :: struct {
	scale:         f32,
	tile_size:     f32,
	screen_width:  f32,
	screen_height: f32,
}

Entity :: struct {
	body_id: b2.BodyId,
    texture: rl.Texture2D
}