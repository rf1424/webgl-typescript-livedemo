#version 300 es

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself
uniform float u_Time;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

mat3 rotateAboutX(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat3(
        1.0, 0.0, 0.0,
        0.0,    c,   -s,
        0.0,    s,    c
    );
}

mat3 rotateAboutY(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat3(
         c, 0.0,    s,
        0.0, 1.0, 0.0,
        -s, 0.0,    c
    );
}

mat3 rotateAboutZ(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat3(
         c,   -s, 0.0,
         s,    c, 0.0,
        0.0, 0.0, 1.0
    );
}


vec3 random3(vec3 p) {
    return fract(sin(vec3(
        dot(p, vec3(127.1, 311.7, 74.7)),
        dot(p, vec3(269.5, 183.3, 246.1)),
        dot(p, vec3(113.5, 271.9, 124.6))
    )) * 43758.5453);
}

float voronoi3D(vec3 xyz, int gridSize) {
    vec3 stw = xyz * float(gridSize);

    vec3 i = floor(stw);
    vec3 f = fract(stw);


    float minDist = 100.;
    for (int x = -1; x <=1; x++) {
        for (int y = -1; y <= 1; y++) {
            for (int z = -1; z <= 1; z++) {
                vec3 offset = vec3(float(x), float(y),float(z));
                vec3 randomPt = random3(i + offset);
                float currDist = length(f - (randomPt + offset));
            
               minDist = min(minDist, currDist);
            }
        }
    }
    return minDist;
}


void main()
{
    vec4 localPos = vs_Pos;
    

    vec3 dir = normalize(vs_Pos.xyz);
    // localPos.x += sin(u_Time + vs_Pos.y * 5.0 + sin(u_Time)) * cos(u_Time);
    
    // localPos.xyz *= sin(u_Time) * 0.5 + 0.5;
    // float scale = voronoi3D(vec3(vs_Pos.xy, u_Time), 2);
    float explode = cos(u_Time * 0.5) * 0.5 + 0.5; // 0 - 1
    

    vec3 displaced = localPos.xyz + dir * explode * 2.0;

    if (dir.x * dir.y * dir.z > 0.) {
        localPos = vec4(displaced, 1.0);
    } 
    
    localPos.xyz = rotateAboutX(u_Time * 0.5) * rotateAboutZ(0.5 * u_Time) * localPos.xyz;
    localPos.xyz *= cos(u_Time * 1.) * 0.5 + 0.5 + 0.1;

    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation
    fs_Pos = localPos;

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.
    

    vec4 modelposition = u_Model * localPos;   // Temporarily store the transformed vertex positions for use below

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
