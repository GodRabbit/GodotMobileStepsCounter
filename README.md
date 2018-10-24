# GodotMobileStepsCounter
This class record the movement of the phone via accelerometer for steps counting.

It records the user acceleration every tick and calculate if a step was made
based on this information.

Notes: 
1). shakes of the phone will count as steps. But this is a limitation of the accelerometer,
and the fact that this algorithm is really general.

2). works best when the phone is placed firmly on the body

3). this won't use the gyroscope, only the accelerometer. its better because some devices don't have gyroscope, but do have
accelerometer. Using the gyroscope might make the algorithm easier and more effecient though.

4). this script won't be useful on non-mobile devices and won't show results in the editor (EVEN ON YOUR PHONE!)
the only way to test this is with a game build. so build frequently to test that everything works fine (this is a Godot 
limitation, the Input.get_accelerometer() returns a non 0 value only while building)

5). Never tested this on iOs. 


How to use in project:
0). Create a scene instancing Node, and attach this script to it (I'd call it movement_sensor, 
but you can call it whatever you want).

1). Instance the scene (from step 0)  in your tree somewhere

2).read get_steps_counter() every time you need to know how much
steps have gone since the monitoring started
or use the signal "steps_updated"
note that the class is updated every tick anyways.
if you want to stop monitoring the steps, use the function stop_monitoring()

3). adjust the the step_threshold value for your needs. This is what controls the sensitivity.
Higher values are are less sensitive. e.g. values below 25, will most likely count every small movement as a step made
while values higher than 1 won't count any steps on my device.
