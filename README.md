# MetalMusic

The code in this repo is adapted from the tutorial [How to Make Your First Circle Using Metal Shaders](https://betterprogramming.pub/making-your-first-circle-using-metal-shaders-1e5049ec8505) by Alex Barbulescu. 

The tutorial was written in 2019 and was designed for the old UIKit. I adapted it to work with the new SwiftUI 2023.

This app in this branch (`nhan/audio_part2`) can analyze a song's `loudness` and `frequency` using [Swift's Discrete Fourier Transforms](https://developer.apple.com/documentation/accelerate/discrete_fourier_transforms) and visualize them using Metal Shader.


Test branch (`nhan/sphere_morph`)
- There's an additional SceneKit view where we can modify a sphere's vertices with audio (in progress)
![Apr-30-2023 21-39-17](https://user-images.githubusercontent.com/10265967/235388803-89598e77-2c3a-454c-bd78-c5c119928af4.gif)



### Video (click on the Speaker icon to unmute)

https://user-images.githubusercontent.com/10265967/229957128-e144787a-14ff-49b1-9f2d-a5f1d21af072.mov



For Part 1 code: see branch `nhan/audio_tinkering`

For Part 0 (static circle render), see branch `nhan/static_circle_render` (no audio involved)

![image](https://user-images.githubusercontent.com/10265967/229384048-14da5362-35ea-4fbb-8788-1846dd4ce1ff.png)
