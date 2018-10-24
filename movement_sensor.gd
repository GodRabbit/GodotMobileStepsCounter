extends Node

#Copyright 2018, Dor "GodRabbit" Shlush
#
#Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation 
#files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, 
#modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software
# is furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT 
#LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
#THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
#TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#this class record the movement of the phone via accelerometer for steps counting
#it records the user acceleration every tick and calculate if a step was made
#based on this information.
#Notes: 
#1). shakes of the phone will count as steps. But this is a limitation of the accelerometer,
#and the fact that this algorithm is really general.
#2). works best when the phone is placed firmly on the body
#3). this won't use the gyroscope, only the accelerometer. its better because some devices don't have gyroscope, but do have
#accelerometer. Using the gyroscope might make the algorithm easier and more effecient though.
#4). this script won't be useful on non-mobile devices and won't show results in the editor [EVEN ON YOUR PHONE!]
#the only way to test this is with a game build. so build frequently to test that everything works fine [this is a Godot 
#limitation, the Input.get_accelerometer() returns a non 0 value only while building]
#5). Never tested this on iOs. 
#
#How to use in project:
#0). Create a scene instancing Node, and attach this script to it (I'd call it movement_sensor, 
#but you can call it whatever you want).
#1). Instance the scene (from step 0)  in your tree somewhere
#2).read get_steps_counter() every time you need to know how much
#steps have gone since the monitoring started
#or use the signal "steps_updated"
#note that the class is updated every tick anyways.
#if you want to stop monitoring the steps, use the function stop_monitoring()
#3). adjust the the step_threshold value for your needs. this is what controls the sensitivity.
#higher values are are less sensitive. e.g. values below 25, will most likely count every small movement as a step made
#while values higher than 1 won't count any steps on my device.
#

#emitted everytime the class sense a step was made
signal steps_updated

export var is_monitoring = true

#represnts the time it takes to take a step. I saw this value in many algorithms, so I keep it this way
const STEP_DELAY = 0.25 #in seconds.

export var step_threshold = 0.25 #change this for sensitivity, higher values -> less sensitive

#a list of vectors supposed to be a "resting" vectors
#they estimate the gravity vectors of the player at rest
var rest_vector_sample = [] 
var rest_sample_size = 50

var current_rest_axis = Vector3(0, 0, -9.8)

var last_velocity_estimate = Vector3(0, 0, 0)

var steps_counter = 0

var steps_timer = 0.0

func _ready():
	set_process(true)

func stop_monitoring():
	is_monitoring = false

func start_monitoring():
	is_monitoring = true
	steps_timer = 0.0

#arr will be an array of vector3 probably, but this 
#function can work with every summable type
static func _sum(arr):
	var result = arr[0]
	for i in range(1, arr.size()):
		result += arr[i]
	return result

func _increase_steps_counter():
	steps_counter += 1
	steps_timer = 0.0
	emit_signal("steps_updated")

func is_rest_acceleration(acc):
	var acc_length = acc.length()
	if(acc_length > 9.2 && acc_length < 10.3):
		return true
	else:
		return false

func update_acceleration(delta):
	#try to find the resting position
	#assuming the player won't jump up and down too much
	var acc = Input.get_accelerometer()
	var acc_length = acc.length()
	
	var velocity #current estimated velocity
	
	#if the player is at rest, the length of the vector should be around 9.8 [due to gravity]
	if(is_rest_acceleration(acc)): #this is the "rest" condition, we can do better btw
		#record the resting position in the resting sample:
		if(rest_vector_sample.size() < rest_sample_size): #in case there arent yet 50 samples
			rest_vector_sample.append(acc)
		else:
			rest_vector_sample.remove(0) #remove first element to keep the sample size at 50
			rest_sample_size.append(acc)
		
		velocity = Vector3(0, 0, 0)
		last_velocity_estimate = Vector3(0, 0, 0)
		return
	
	#approximate the rest axis:
	if(rest_vector_sample.size() == 0): #if rest data is empty:
		#in case there is no rest data, assume phone is on the floor
		current_rest_axis = -9.8*Vector3(0, 0, 1)
	else:
		#we use regular average, but we can use weighted average that take acoount of the later values more than the 
		#old values
		current_rest_axis = _sum(rest_vector_sample)/float(rest_vector_sample.size())
	
	#this is the true acceleration of the player, without the gravity, we hope
	var true_acc = acc - current_rest_axis
	
	#velocity estimate: using the simple formula we get: v = v0+a*t
	velocity = last_velocity_estimate + true_acc*delta
	steps_timer += delta
	
	var velocity_length = velocity.length()
	
	#is this velocity enough to make a step:
	if(velocity_length > step_threshold && last_velocity_estimate.length() <= step_threshold && steps_timer > STEP_DELAY):
		_increase_steps_counter()
	
	last_velocity_estimate = velocity

func _process(delta):
	if(is_monitoring):
		update_acceleration(delta)

#how many steps the player did since the monitoring started
func get_steps_counter():
	return steps_counter


#resets the steps counter to zero
func reset_steps_counter():
	steps_counter = 0
	steps_timer = 0.0
	emit_signal("steps_updated")

func get_last_velocity():
	return last_velocity_estimate