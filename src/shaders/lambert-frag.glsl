#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

float random(float p) {
    return fract(sin(p * 127.1) * 43758.5453);
}

vec3 random3(vec3 p) {
    return fract(sin(vec3(
        dot(p, vec3(127.1, 311.7, 74.7)),
        dot(p, vec3(269.5, 183.3, 246.1)),
        dot(p, vec3(113.5, 271.9, 124.6))
    )) * 43758.5453);
}

float voronoi3D(vec3 xyz, int gridSize, out vec3 closestCell) {
    vec3 stw = xyz * float(gridSize);

    vec3 i = floor(stw);
    vec3 f = fract(stw);


    float minDist = 100.;
    closestCell = i;

    for (int x = -1; x <=1; x++) {
        for (int y = -1; y <= 1; y++) {
            for (int z = -1; z <= 1; z++) {
                vec3 offset = vec3(float(x), float(y),float(z));
                vec3 randomPt = random3(i + offset);
                float currDist = length(f - (randomPt + offset));
                
                if (currDist < minDist) {
                   closestCell = i + offset;
                   minDist = currDist;
                }
               // minDist = min(minDist, currDist);
            }
        }
    }
    return minDist;
}


void main()
{
    // Material base color (before shading)
        vec4 diffuseColor = u_Color;

        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        diffuseTerm = max(diffuseTerm, 0.0);
        // Avoid negative lighting values
        // diffuseTerm = clamp(diffuseTerm, 0, 1);

        float ambientTerm = 0.2;

        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

        vec3 baseCol = diffuseColor.rgb * lightIntensity;
        vec3 closestCell;
        int gridSize = 5;
        voronoi3D(fs_Pos.xyz, 5, closestCell);
        float cellId = dot(closestCell, vec3(gridSize * gridSize, gridSize, 1.));
       
        vec3 cellColor = 0.5 + 0.5 * cos(vec3(cellId) * 2.0 + vec3(0, 2, 4));
    
        
        // vec3 finalCol = cellColor * baseCol;//cellColor * 0.5 + finalCol * 0.5; // [152,255,170]
        // vec3 finalCol = baseCol + (cellColor * 0.3);
        vec3 finalCol = (random(cellId) > 0.5) ? baseCol : mix(baseCol, cellColor, 0.9);
        // finalCol *= lightIntensity;

        // Compute final shaded color
        out_Col = vec4(finalCol, diffuseColor.a);


}


