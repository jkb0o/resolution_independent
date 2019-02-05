extends Node2D

enum  {
	CURVE_TYPE_UNKNOWN,
	CURVE_TYPE_SERPENTINE,
	CURVE_TYPE_LOOP,
	CURVE_TYPE_CUSP_INF_INFLECTION,
	CURVE_TYPE_CUSP_INF_CUSP,
	CURVE_TYPE_QUADRATIC,
	CURVE_TYPE_LINE
}

var curve = Curve2D.new()

func _ready():
	ui.draw_triangles.connect("pressed", self, "update")
	ui.draw_outline.connect("pressed", self, "update")
	set_process_unhandled_input(true)
	for p in get_children():
		curve.add_point(p.position, p.p_in, p.p_out)
	var p = get_child(0)
	curve.add_point(p.position, p.p_in, p.p_out)
	
	
	
func _draw():
	for i in range(get_child_count()+1):
		var p = get_child(i%get_child_count())
		curve.set_point_position(i, p.position)
		curve.set_point_in(i, p.p_in)
		curve.set_point_out(i, p.p_out)
	
	var triangles = []
	for i in range(get_child_count()):
		var p0 = get_child(i)
		var p1 = get_child((i+1)%get_child_count())
		var seg = create_segment(p0.position,  p0.position+p0.p_out, p1.position+p1.p_in, p1.position)
		triangles.append([p0.position,  p0.position+p0.p_out])
		triangles.append([p0.position+p0.p_out, p1.position+p1.p_in])
		triangles.append([p1.position+p1.p_in, p1.position])
		triangles.append([p0.position, p1.position+p1.p_in])
		triangles.append([p0.position, p1.position])
		var conf = triangulate(seg)
		VisualServer.canvas_item_add_triangle_array(get_canvas_item(), conf[0], conf[1], conf[2])
		
	var center = PoolVector2Array()
	var center_color = PoolColorArray()
	for c in get_children():
		center.push_back(c.position)
		center_color.push_back(Color(1,0,0,0.5))
	draw_polygon(center, center_color)
	
	if ui.draw_outline.pressed:
		var points = curve.tessellate(6, 1)
		draw_polyline(points, Color(1,1,1), 1.0, true)
	if ui.draw_triangles.pressed:
		for line in triangles:
			draw_line(line[0], line[1], Color(), 1, true)
	
	
func create_mesh():
	var vertices = PoolVector2Array()
	var indices = PoolIntArray()
	for i in range(get_child_count()+1):
		var p0 = get_child(i%get_child_count())
		var p1 = get_child((i+1)%get_child_count())
		vertices.push_back(p0.position)
		vertices.push_back(p1.position)
		vertices.push_back(p1.position+p1.p_in)
		vertices.push_back(p0.position+p0.p_out)
	return vertices
	
func 	is_clockwise (p0:Vector2, p1:Vector2, p2:Vector2):	
	var edge0 = p0-p1
	var edge1 = p2-p1
	return edge0.x * edge1.y - edge0.y * edge1.x <= 0.0

func is_inside_circle(p0:Vector2, p1:Vector2, p2:Vector2, v:Vector2):
	var dxsq = v.x*v.x
	var dysq = v.y*v.y
	var r = determinant_3x3(
		p0.x-v.x, p0.y-v.y, 
		p0.x*p0.x - dxsq + p0.y*p0.y - dysq,
		p1.x-v.x, p1.y-v.y, 
		p1.x*p1.x - dxsq + p1.y*p1.y - dysq,
		p2.x-v.x, p2.y-v.y, 
		p2.x*p2.x - dxsq + p2.y*p2.y - dysq
	)
	if is_clockwise(p0, p1, p2):
		return r > 0.0
	else:
		return r <= 0.0
		
		
		

func determinant_3x3 (x0, y0, w0, x1, y1, w1, x2, y2, w2):
	return x0 * y1 * w2 + \
	       y0 * w1 * x2 + \
	       w0 * x1 * y2 - \
	       w0 * y1 * x2 - \
	       y0 * x1 * w2 - \
	       x0 * w1 * y2
				

class TypeResult:
	extends Reference
	var curve_type:int
	var d0:float
	var d1:float
	var d2:float
	var d3:float
	

func determine_type (
		p0:Vector2,
		p1:Vector2,
		p2:Vector2,
		p3:Vector2):

	var r = TypeResult.new()
	r.curve_type = CURVE_TYPE_UNKNOWN

	#if !v0 || !v1 || !v2 || !v3 || !d0 || !d1 || !d2 || !d3:
	#	return r
	var v0 = Vector3(p0.x, p0.y, 1.0)
	var v1 = Vector3(p1.x, p1.y, 1.0)
	var v2 = Vector3(p2.x, p2.y, 1.0)
	var v3 = Vector3(p3.x, p3.y, 1.0)
	# convert control-points vN to power basis
	var b0 = v0
	var b1 = Vector3()
	var b2 = Vector3()
	var b3 = Vector3()
	b1.x = -3.0 * v0.x + 3.0 * v1.x
	b1.y = -3.0 * v0.y + 3.0 * v1.y
	b1.z = -3.0 * v0.z + 3.0 * v1.z
	b2.x = 3.0 * v0.x - 6.0 * v1.x + 3.0 * v2.x
	b2.y = 3.0 * v0.y - 6.0 * v1.y + 3.0 * v2.y
	b2.z = 3.0 * v0.z - 6.0 * v1.z + 3.0 * v2.z
	b3.x = -1.0 * v0.x + 3.0 * v1.x - 3.0 * v2.x + v3.x
	b3.y = -1.0 * v0.y + 3.0 * v1.y - 3.0 * v2.y + v3.y
	b3.z = -1.0 * v0.z + 3.0 * v1.z - 3.0 * v2.z + v3.z

	r.d0 = determinant_3x3(b3.x, b3.y, b3.z, b2.x, b2.y, b2.z, b1.x, b1.y, b1.z)
	r.d1 = -determinant_3x3(b3.x, b3.y, b3.z, b2.x, b2.y, b2.z, b0.x, b0.y, b0.z)
	r.d2 = determinant_3x3 (b3.x, b3.y, b3.z, b1.x, b1.y, b1.z, b0.x, b0.y, b0.z)
	r.d3 = -determinant_3x3 (b2.x, b2.y, b2.z, b1.x, b1.y, b1.z, b0.x, b0.y, b0.z)

	var D = 3.0 * r.d2 * r.d2 - 4.0 * r.d1 * r.d3

	if r.d1 != 0.0:
		if D > 0.0:
			r.curve_type = CURVE_TYPE_SERPENTINE
		if D < 0.0:
			r.curve_type = CURVE_TYPE_LOOP
		if D == 0.0:
			r.curve_type = CURVE_TYPE_CUSP_INF_INFLECTION
	else:
		if r.d2 != 0.0:
			r.curve_type = CURVE_TYPE_CUSP_INF_CUSP;
		else:
			if r.d3 != 0.0:
				r.curve_type = CURVE_TYPE_QUADRATIC;
			else:
				r.curve_type = CURVE_TYPE_LINE;
	return r
	
	
class Segment:
	extends Reference
	var curve_type:int
	var vertices:Array
	var colors:Array

	
func triangulate(segment:Segment):
	var v = segment.vertices
	var indices = PoolIntArray()
	if is_inside_circle(v[0], v[1], v[2], v[3]):
		indices.push_back(0)
		indices.push_back(1)
		indices.push_back(2)
	if is_inside_circle(v[0], v[2], v[3], v[1]):
		indices.push_back(2)
		indices.push_back(0)
		indices.push_back(3)
	if is_inside_circle(v[1], v[2], v[3], v[0]):
		indices.push_back(2)
		indices.push_back(1)
		indices.push_back(3)
	if is_inside_circle(v[0], v[1], v[3], v[2]):
		indices.push_back(1)
		indices.push_back(0)
		indices.push_back(3)
	var res =  [PoolIntArray(indices), PoolVector2Array(v), PoolColorArray(segment.colors)]
	return res

func create_segment(p0:Vector2, p1:Vector2, p2:Vector2, p3:Vector2):
	var segment = Segment.new()
	segment.vertices = []
	segment.colors = []
	var r = determine_type(p0, p1, p2, p3)
	if r.curve_type == CURVE_TYPE_SERPENTINE:
		var tmp = 1.0 / sqrt (3.0) * sqrt (3.0 * r.d2 * r.d2 - 4.0 * r.d1 * r.d3)
		var tl = r.d2 + tmp
		var sl = 2.0 * r.d1
		var tm = r.d2 - tmp
		var sm = sl
		var tn = 1.0
		var sn = 0.0
		var k0 = Vector3(tl*tm, tl*tl*tl, tm*tm*tm)
		var k1 = Vector3(-sm*tl-sl*tm, -3.0*sl*tl*tl, -3.0*sm*tm*tm)
		var k2 = Vector3(sl*sm, 3.0*sl*sl*tl, 3.0*sm*sm*tm)
		var k3 = Vector3(0.0, -sl*sl*sl, -sm*sm*sm)
		segment.colors.push_back(Color(k0.x, k0.y, k0.z, 0))
		
		var tmp_k = k0+k1/3.0
		segment.colors.push_back(Color(tmp_k.x, tmp_k.y, tmp_k.z, 0))
		
		var tmp_n = k0 + k2/3.0 + k1*2.0/3.0
		segment.colors.push_back(Color(tmp_n.x, tmp_n.y, tmp_n.z, 0))
		
		var tmp_m = k0 + k1 + k2 + k3
		segment.colors.push_back(Color(tmp_m.x, tmp_m.y, tmp_m.z, 0))
	elif r.curve_type == CURVE_TYPE_LOOP:
		var tmp = sqrt (4.0 * r.d1 * r.d3 - 3.0 * r.d2 * r.d2);
		var td = r.d2 + tmp;
		var sd = 2.0 * r.d1;
		var te = r.d2 - tmp;
		var se = 2.0 * r.d1;

		var k0 = Vector3(td*te, td*td*te, td*te*te)
		var k1 = Vector3(-se*td-sd*te, -se*td*td-2.0*sd*te*td,-sd*te*te-2.0*se*td*te)
		var k2 = Vector3(sd*se, te*sd*sd+2.0*se*td*sd, td*se*se+2.0*sd*te*se)
		var k3 = Vector3(0.0, -sd*sd*se, -sd*se*se)
		
		segment.colors.push_back(Color(k0.x, k0.y, k0.z, 0))
		
		var tmp_k = k0 + k1/3.0
		segment.colors.push_back(Color(tmp_k.x, tmp_k.y, tmp_k.z, 0))
		
		var tmp_n = k0 + k1*2.0/3.0 + k2/3.0
		segment.colors.push_back(Color(tmp_n.x, tmp_n.y, tmp_n.z, 0))
		
		var tmp_m = k0 + k1 + k2 + k3
		segment.colors.push_back(Color(tmp_m.x, tmp_m.y, tmp_m.z, 0))
	
	segment.curve_type = r.curve_type
	segment.vertices.push_back(p0)
	segment.vertices.push_back(p1)
	segment.vertices.push_back(p2)
	segment.vertices.push_back(p3)
	
	return segment
		

func _unhandled_input(event):
	update()

