// -*- mode: C; -*-
// Licence: GPL v2
// © Emilian Huminiuc and Vivian Meazza 2011
#version 120

varying	vec3	rawpos;
varying	vec3	VNormal;
varying	vec3	VTangent;
varying	vec3	VBinormal;
varying	vec3	vViewVec;
varying vec3	vertVec;
varying	vec3	reflVec;

varying	float	alpha;

attribute	vec3	tangent;
attribute	vec3	binormal;

uniform	float		pitch;
uniform	float		roll;
uniform	float		hdg;
uniform	int  		refl_dynamic;
uniform int  		nmap_enabled;
uniform int  		shader_qual;
uniform int			rembrandt_enabled;
uniform int     color_is_position;

//////Fog Include///////////
// uniform	int 	fogType;
// void	fog_Func(int type);
////////////////////////////

void	rotationMatrixPR(in float sinRx, in float cosRx, in float sinRy, in float cosRy, out mat4 rotmat)
{
	rotmat = mat4(	cosRy ,	sinRx * sinRy ,	cosRx * sinRy,	0.0,
									0.0   ,	cosRx        ,	-sinRx * cosRx,	0.0,
									-sinRy,	sinRx * cosRy,	cosRx * cosRy ,	0.0,
									0.0   ,	0.0          ,	0.0           ,	1.0 );
}

void	rotationMatrixH(in float sinRz, in float cosRz, out mat4 rotmat)
{
	rotmat = mat4(	cosRz,	-sinRz,	0.0,	0.0,
									sinRz,	cosRz,	0.0,	0.0,
									0.0  ,	0.0  ,	1.0,	0.0,
									0.0  ,	0.0  ,	0.0,	1.0 );
}

void	main(void)
{
    float sr = sin(6.28 * gl_Color.a);
    float cr = cos(6.28 * gl_Color.a);    
    rawpos = gl_Vertex.xyz;
  
    // Rotation of the object and movement into position
    rawpos.xy = vec2(dot(rawpos.xy, vec2(cr, sr)), dot(rawpos.xy, vec2(-sr, cr)));
    rawpos = rawpos + gl_Color.xyz;    
    
		vec4 ecPosition = gl_ModelViewMatrix * vec4(rawpos.x, rawpos.y, rawpos.z, 1.0);
		//fog_Func(fogType);

    // Rotate the normal.
    vec3 normal = gl_Normal;
    normal.xy = vec2(dot(normal.xy, vec2(cr, sr)), dot(normal.xy, vec2(-sr, cr)));
    //normal = gl_NormalMatrix * normal;

    VNormal = normalize(gl_NormalMatrix * normal);
    vec3 n = normalize(normal);
    vec3 tempTangent = cross(n, vec3(1.0,0.0,0.0));
    vec3 tempBinormal = cross(n, tempTangent);

    if (nmap_enabled > 0){
        tempTangent = tangent;
        tempBinormal  = binormal;
      }

    VTangent = normalize(gl_NormalMatrix * tempTangent);
    VBinormal = normalize(gl_NormalMatrix * tempBinormal);
    vec3 t = tempTangent;
    vec3 b = tempBinormal;

		// Super hack: if diffuse material alpha is less than 1, assume a
		// transparency animation is at work
		if (gl_FrontMaterial.diffuse.a < 1.0)
			alpha = gl_FrontMaterial.diffuse.a;
		else
			alpha = 1.0;

    // Vertex in eye coordinates
		vertVec = ecPosition.xyz;
		vViewVec.x = dot(t, vertVec);
		vViewVec.y = dot(b, vertVec);
		vViewVec.z = dot(n, vertVec);

		// calculate the reflection vector
		vec4 reflect_eye = vec4(reflect(vertVec, VNormal), 0.0);
		vec3 reflVec_stat = normalize(gl_ModelViewMatrixInverse * reflect_eye).xyz;
		if (refl_dynamic > 0){
			//prepare rotation matrix
			mat4 RotMatPR;
			mat4 RotMatH;
			float _roll = roll;
			if (_roll>90.0 || _roll < -90.0)
			{
				_roll = -_roll;
			}
			float cosRx = cos(radians(_roll));
			float sinRx = sin(radians(_roll));
			float cosRy = cos(radians(-pitch));
			float sinRy = sin(radians(-pitch));
			float cosRz = cos(radians(hdg));
			float sinRz = sin(radians(hdg));
			rotationMatrixPR(sinRx, cosRx, sinRy, cosRy, RotMatPR);
			rotationMatrixH(sinRz, cosRz, RotMatH);
			vec3 reflVec_dyn = (RotMatH * (RotMatPR * normalize(gl_ModelViewMatrixInverse * reflect_eye))).xyz;

			reflVec = reflVec_dyn;
		} else {
			reflVec = reflVec_stat;
		}

		if(rembrandt_enabled < 1){
		gl_FrontColor = gl_FrontMaterial.emission + vec4(1.0,1.0,1.0,1.0)
					  * (gl_LightModel.ambient + gl_LightSource[0].ambient);
		} else {
		  gl_FrontColor = vec4(1.0,1.0,1.0,1.0);
		}
		gl_Position  = gl_ModelViewProjectionMatrix * vec4(rawpos,1.0);
		gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;
}
