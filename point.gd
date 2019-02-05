tool
extends Node2D

const NONE = 0
const MAIN = 1
const IN = 2
const OUT = 3

const MAIN_RADIUS = 8
const HELPER_RADIUS = 6
const NORMAL_COLOR = Color(0.8, 0.2, 0.3)
const HOVER_COLOR = Color(0.3, 0.8, 0.2)
const BORDER_COLOR = Color(0.1, 0.1, 0.1)
const PRESSED_COLOR = Color(0.3, 1, 0.2)

export var p_in = Vector2(50, 50)
export var p_out = Vector2(-50, 50)
var pressed = 0

func _ready():
	pass # Replace with function body.

func _draw():
	draw_line(Vector2(), p_in, Color(0.5, 0.5, 0.5), 1, true)
	draw_line(Vector2(), p_out, Color(0.5, 0.5, 0.5), 1, true)
	var over = is_mouse_over()
	var color = PRESSED_COLOR if over==MAIN && pressed==MAIN else HOVER_COLOR if over==MAIN else NORMAL_COLOR
	draw_circle(Vector2(), MAIN_RADIUS+2, BORDER_COLOR)
	draw_circle(Vector2(), MAIN_RADIUS, color)
	
	color = PRESSED_COLOR if over==IN && pressed==IN else HOVER_COLOR if over==IN else NORMAL_COLOR
	draw_circle(p_in, HELPER_RADIUS+2, BORDER_COLOR)
	draw_circle(p_in, HELPER_RADIUS, color)
	
	color = PRESSED_COLOR if over==OUT && pressed==OUT else HOVER_COLOR if over==OUT else NORMAL_COLOR
	draw_circle(p_out, HELPER_RADIUS+2, BORDER_COLOR)
	draw_circle(p_out, HELPER_RADIUS, color)
	
	
func _unhandled_input(event):
	if event is InputEventMouseButton && event.is_pressed():
		pressed = is_mouse_over()
	if pressed && event is InputEventMouseButton && !event.is_pressed():
		pressed = 0
	if pressed && event is InputEventMouseMotion:
		if pressed == MAIN:
			position += event.relative
		elif pressed == IN:
			p_in += event.relative
			if Input.is_key_pressed(KEY_SHIFT):
				p_out = -p_in
		elif pressed == OUT:
			p_out += event.relative
			if Input.is_key_pressed(KEY_SHIFT):
				p_in = -p_out
		
	update()
	
func is_mouse_over():
	if get_local_mouse_position().length() < MAIN_RADIUS:
		return 1
	elif (get_local_mouse_position()-p_in).length() < HELPER_RADIUS:
		return 2
	elif (get_local_mouse_position()-p_out).length() < HELPER_RADIUS:
		return 3
	else:
		return 0
	
	