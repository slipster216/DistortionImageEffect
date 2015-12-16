Distortion Image Effect
©2015 Jason Booth


	So, this is a novel way to do image distortion (or at least I haven’t seen it done this way before - someone likely has). It has some advantages and disadvantages, which are explained in detail below. 

	To use the effect, add the DistortionImageEffect component to your camera. Create a distortion layer and assign the layer mask on the DisortionImageEffect component to use it. Make sure your regular camera doesn’t render this layer. 
	Put distortion objects on the distortion layer. They should render normal information. An output value of 0.5, 0.5, 1.0 is no distortion, while a value of 0, 0, 1.0 would distort the image towards the top-left side of the screen. In effect, think of the xy component of the normal map as your distortion direction and amount in screen space. 
	There is a parameter on the DistortionImageEffect component called ‘Distortion Scale’ - this controls the total screen space UV distortion when a normal is output at maximum distortion. So if this value is 0.2, then the most a pixel can move from it’s original location is 20% of the screen. The value in xy, from 0-1, would move the pixel from -20% to +20%. 
	
	Distortion shaders need to do their own ztest and pre-multiply alpha; see the example shaders for how to do this. It’s pretty cheap, especially because your rendering it all at very low resolutions. 


Explanation of the effect vs. standard ways of doing things:


The two ways distortion is generally done that I’ve seen are:

A) After opaque objects are rendered, resolve the color buffer to a texture and reference it in the shader to create the distortion. 
B) When you encounter a distortion shader, capture the current buffer to a texture and render distortion, repeating as necessary.

	In Unity, most people use a variant of B via “GrabPass”, which either captures the first named grab pass for all distortion objects to use, or does it once for each distortion object. Both techniques have downsides:

For A:
   Transparent objects do not draw behind distortion - this is because they aren’t present in the color buffer that was captured. Additionally, post processing effects using the depth buffer may not work correctly, since the depth has not been distorted with the result. This often manifests as haloing around the effect. Additionally, you need a screen sized texture around with this information. 

For B:
   If using ‘GrabPass’ with a name, it captures the color buffer the first time it draws a distortion object. This means it will work with transparent objects drawn before this happens, but not ones after this happens - and since the buffer is only captured once, future distortions will exhibit the same artifacts as A does. If GrabPass doesn’t use a name, it will capture the screen buffer once per effect, which can destroy your frame rate very quickly, though it works better with transparent surfaces (but still doesn’t work with depth effects). 

	This technique offers a third approach. At post-processing time, a special camera renders all the distortion objects into a low res buffer. The shaders these object use z-test against the depth buffer, and render distortion normals into this low res buffer. Then the screen buffer is distorted using the resulting distortion buffer in a standard Graphics.Blit operation. 

	The main advantages are:

- Distortion works on transparent objects
- Distortion can be applied at any point in the post processing chain, such as after depth buffer effects like fog, etc.
- Can be easily worked into a Blit that your likely already performing in your post processing chain, making it pretty cheap.
- It is much easier to turn distortion on/off at a single location, instead of making LODs for every effect, etc.
- distortion isn’t infinitely cumulative, but maxes out at whatever your max scale is. 

	Downsides:

- Unity has lots of issues:
	- Camera overhead is not cheap in Unity, and we’re rendering another camera. This re-culls the whole scene, etc, including layers your not rendering from that camera. That said, the effect is still pretty fast. 
	- Does not work if real-time shadows are on. When you render a second camera in Unity, it will clear the depth buffer if there are realtime shadows in the scene, and there’s currently no way to disable this behavior. We could get around this by copying the depth texture into our own texture, but that’s pretty silly. Our game doesn’t use Unity’s shadow system, so it works fine for our uses. We also have a low-res version of the depth buffer that we keep around and could use for this. 
- Technique downsides
	- Distortion is culled vs. solid objects, but not verses transparent; in effect, it always draws on top of everything, which means it can distort transparent objects in front of it. 
	- Currently doesn’t take aspect ratio into account.




	


