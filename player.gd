extends CharacterBody3D

@export var footstep_sound: Array[AudioStream]

var run_speed = 5.5
var speed = run_speed
var walk_speed = 3
var crouch_speed = 1.8

var jump_velocity = 7
var landing_velocity

var distance = 0
var footstep_distance = 2.1


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotation_degrees.y -= event.relative.x / 10
		$HeadPosition/LandingAnimation/Camera3D.rotation_degrees.x -= event.relative.y / 10
		$HeadPosition/LandingAnimation/Camera3D.rotation_degrees.x = clamp($HeadPosition/LandingAnimation/Camera3D.rotation_degrees.x, -90, 90)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * 2 * delta
		landing_velocity = -velocity.y
		distance = 0
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# Jump with Space - only if on floor and no ceiling above
	var has_ceiling = $CeilingDetector.is_colliding() if has_node("CeilingDetector") else false
	if Input.is_key_pressed(KEY_SPACE) and is_on_floor() and not has_ceiling:
		velocity.y = jump_velocity
		play_random_footstep_sound()

	var ceiling_check = has_node("CeilingDetector") and $CeilingDetector.is_colliding()
	if not ceiling_check:
		$CollisionShape3D.shape.height = lerp($CollisionShape3D.shape.height, 1.85, 0.1)
	else:
		$CollisionShape3D.shape.height = lerp($CollisionShape3D.shape.height, 1.38, 0.1)
	if is_on_floor():
		if landing_velocity != 0:
			landing_animation(landing_velocity)
			landing_velocity = 0

		speed = run_speed
		# Crouch with Control
		if Input.is_key_pressed(KEY_CTRL):
			speed = crouch_speed
		# Walk with Shift
		elif Input.is_key_pressed(KEY_SHIFT):
			speed = walk_speed

	if Input.is_key_pressed(KEY_CTRL):
		$CollisionShape3D.shape.height = lerp($CollisionShape3D.shape.height, 1.38, 0.1)

	$MeshInstance3D.scale.y = $CollisionShape3D.shape.height
	$HeadPosition.position.y = $CollisionShape3D.shape.height - 0.25

	# Movement inputs
	var input_dir = Vector2.ZERO
	# Forward (W or Z)
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_Z):
		input_dir.y -= 1
	# Backward (S)
	if Input.is_key_pressed(KEY_S):
		input_dir.y += 1
	# Left (A or Q)
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_Q):
		input_dir.x -= 1
	# Right (D)
	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1

	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	distance += get_real_velocity().length() * delta

	if distance >= footstep_distance:
		distance = 0
		if speed > walk_speed:
			play_random_footstep_sound()

	move_and_slide()


func landing_animation(landing_vel):
	if landing_vel >= 2:
		play_random_footstep_sound()

	var tween = get_tree().create_tween().set_trans(Tween.TRANS_SINE)
	var amplitude = clamp(landing_vel / 100, 0.0, 0.3)

	tween.tween_property($HeadPosition/LandingAnimation, "position:y", -amplitude, amplitude)
	tween.tween_property($HeadPosition/LandingAnimation, "position:y", 0, amplitude)


func play_random_footstep_sound() -> void:
	if footstep_sound.size() > 0:
		$FootstepSound.stream = footstep_sound.pick_random()
		$FootstepSound.play()
