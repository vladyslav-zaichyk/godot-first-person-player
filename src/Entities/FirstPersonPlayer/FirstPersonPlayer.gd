extends KinematicBody

# movement
const GRAVITY_FORSE_DEFAULT = 30
const MOVE_SPEED_DEFAULT = 12
const JUMP_FORSE_DEFAULT = 12
# friction
const FRICTION_GROUND = 0.5
const FRICTION_AIR = 0.009
# view & aim
const VIEW_SENSITIVITY_X = 0.25
const VIEW_SENSITIVITY_Y = 0.25
const VIEW_LOCK_TOP = 90
const VIEW_LOCK_BOTTOM = -90

var gravity_direction: Vector3 = Vector3.DOWN
var gravity_forse: float = GRAVITY_FORSE_DEFAULT
var velocity: Vector3 = Vector3.ZERO
var snap: Vector3 = Vector3.ZERO
var move_speed: float = MOVE_SPEED_DEFAULT
var jump_forse: float = JUMP_FORSE_DEFAULT
var friction: float

# optional, used for degugging
var _state: String = ""

onready var head: Spatial = $Head
onready var camera: Camera = $Head/Camera
onready var raycast: RayCast = $RayCast


func get_floor_normal() -> Vector3:
	return raycast.get_collision_normal()


func get_floor_angle() -> float:
	return acos(get_floor_normal().dot(Vector3.UP))


func is_on_slope():
	return rad2deg(get_floor_angle()) > 1


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()


func _physics_process(delta):
	# optional
	_debug()
	
	if is_on_floor():
		_on_floor()
	else:
		_in_air()
	
	var _target_velocity = get_global_transform().basis * _input_direction() * move_speed
	velocity.x =  lerp(velocity.x, _target_velocity.x, friction)
	velocity.z =  lerp(velocity.z, _target_velocity.z, friction)
	
	velocity += gravity_direction * gravity_forse * delta
	velocity = move_and_slide_with_snap(velocity, snap, Vector3.UP, true, 4, PI/4, true)


func _on_floor():
	# optional
	_state = "on_floor"
	
	snap = -get_floor_normal()
	gravity_direction = -get_floor_normal()
	friction = FRICTION_GROUND
	
	if Input.is_action_pressed("jump"):
		_jump(jump_forse)


func _in_air():
	# optional
	_state = "in_air"
	
	gravity_direction = Vector3.DOWN
	friction = FRICTION_AIR


func _input(event):
	if event is InputEventMouseMotion:
		_aim(event)


func _jump(forse) -> void:
	snap = Vector3.ZERO
	velocity.y = forse


func _aim(event) -> void:
	rotate_y(deg2rad(-event.relative.x * VIEW_SENSITIVITY_X))
	head.rotate_x(deg2rad(-event.relative.y * VIEW_SENSITIVITY_Y))
	head.rotation.x = clamp(head.rotation.x, deg2rad(VIEW_LOCK_BOTTOM), deg2rad(VIEW_LOCK_TOP))


func _input_direction() -> Vector3:
	var direction = Vector3()

	if Input.is_action_pressed("move_forward"):
		direction += Vector3.FORWARD
	elif Input.is_action_pressed("move_backward"):
		direction += Vector3.BACK

	if Input.is_action_pressed("move_left"):
		direction += Vector3.LEFT
	elif Input.is_action_pressed("move_right"):
		direction += Vector3.RIGHT

	return direction.normalized()


func _debug():
	$Debug/FloorAngleLabel.text = "floor angle: %s\nfloor_normal: %s" % [rad2deg(get_floor_angle()), get_floor_normal()]
	$Debug/SpeedLabel.text = "speed: %s" % Vector2(velocity.x, velocity.z).length()
	$Debug/StateLabel.text = "state: %s" % _state
