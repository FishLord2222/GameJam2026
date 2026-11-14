class_name WaterSimulator
extends Node2D

signal wave_impact(intensity)

@export_range(2, 1000) var resolution: int = 300
@export var water_y: float = 30.0
@export_range(0.0, 0.3) var spring_strength: float = 0.025
@export_range(0.0, 0.5) var wave_propagation: float = 0.16
@export_range(0.0, 0.2) var damping: float = 0.035
@export_range(0.0, 50.0) var ambient_wave_amplitude: float = 5.0
@export var ambient_wave_speed: float = 1.2
@export var ambient_wave_frequency: float = 3.0
@export var sim_width: float = 2000.0

var heights: PackedFloat32Array = PackedFloat32Array()
var velocities: PackedFloat32Array = PackedFloat32Array()
var _time: float = 0.0

func _ready() -> void:
 resolution = maxi(resolution, 2)
 heights.resize(resolution)
 velocities.resize(resolution)

func _physics_process(delta: float) -> void:
 _time += delta
 # Advance in fixed-size slices so the simulation remains stable at different physics rates.
 var steps: int = maxi(1, ceili(delta * 60.0))
 var dt: float = delta * 60.0 / steps
 for step in range(steps):
  var accelerations := PackedFloat32Array()
  accelerations.resize(resolution)
  for i in range(resolution):
   var left: float = heights[maxi(i - 1, 0)]
   var right: float = heights[mini(i + 1, resolution - 1)]
   accelerations[i] = -spring_strength * heights[i] + wave_propagation * (left + right - 2.0 * heights[i])
  for i in range(resolution):
   velocities[i] = (velocities[i] + accelerations[i] * dt) * pow(1.0 - damping, dt)
   heights[i] += velocities[i] * dt

func get_water_height_at(world_x: float) -> float:
 var local_x: float = world_x - global_position.x
 var index: float = clampf((local_x + sim_width * 0.5) / _get_point_spacing(), 0.0, float(resolution - 1))
 var left: int = int(floor(index))
 var right: int = mini(left + 1, resolution - 1)
 var disturbed: float = lerpf(heights[left], heights[right], index - left)
 return global_position.y + water_y + disturbed + _ambient_height(local_x)

func _ambient_height(local_x: float) -> float:
 var phase: float = local_x / sim_width * TAU * ambient_wave_frequency
 return ambient_wave_amplitude * (sin(phase + _time * ambient_wave_speed) + 0.35 * sin(phase * 2.3 - _time * 0.8))

func get_water_angle_at(world_x: float) -> float:
 return atan2(get_water_height_at(world_x + 10.0) - get_water_height_at(world_x - 10.0), 20.0)

func set_wave_at(world_x: float, height: float, radius: float = 50.0) -> void:
 var center: float = (world_x - global_position.x + sim_width * 0.5) / _get_point_spacing()
 var radius_points: float = maxf(radius / _get_point_spacing(), 1.0)
 var impulse: float = clampf(height, -8.0, 8.0)
 for i in range(resolution):
  var influence: float = maxf(0.0, 1.0 - absf(float(i) - center) / radius_points)
  velocities[i] += impulse * influence * influence

func create_impact(world_x: float, velocity: float, mass: float = 1.0) -> void:
 var intensity: float = absf(velocity) * mass
 set_wave_at(world_x, -intensity, 80.0)
 if intensity > 2.0:
  wave_impact.emit(intensity)

func calm_water() -> void:
 heights.fill(0.0)
 velocities.fill(0.0)

func _get_point_spacing() -> float:
 return sim_width / float(resolution - 1)
