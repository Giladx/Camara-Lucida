#define KINECT_W	640
#define KINECT_H	480
#define BASE_RAW_DEPTH 	1024 //5mts~
#define BASE_DEPTH_MTS	(k1 * tan( (float)( ((float)BASE_RAW_DEPTH / k2) + k3) ) - k4)
#define k1		0.1236
#define k2		2842.5
#define k3		1.1863
#define k4		0.0370

float raw_depth_to_meters(ushort raw_depth)
{
	if (raw_depth < BASE_RAW_DEPTH)
	{
		return k1 * tan( (float)( ((float)raw_depth / k2) + k3) ) - k4; // calculate in meters
	}
	return BASE_DEPTH_MTS;
}

__kernel void update_vertex(__global float4* vbo_buff, 
							__global float4* normals_buff, 
							__global const ushort* raw_depth_buff, 
							__global const float4* vbo_buff_const, 
							const int mesh_step, const int depth_xoff,
							const float4 depth_intrinsics)
{
	int vbo_idx = get_global_id(0);

	int mesh_w = KINECT_W/mesh_step;
	int mesh_h = KINECT_H/mesh_step;
	int vbo_length = mesh_w * mesh_h; 
	
	int mcol = vbo_idx % mesh_w;
	int mrow = (vbo_idx - mcol) / mesh_w;
	
	int col = mcol * mesh_step;
	int row = mrow * mesh_step;
	
	int depth_idx = row * KINECT_W + col;
	
	// set normals
	
	normals_buff[vbo_idx].x = 0.;
	normals_buff[vbo_idx].y = 0.;
	normals_buff[vbo_idx].z = 1.;
	normals_buff[vbo_idx].w = 0.;
	
	// set vbo pts
	
	ushort raw_depth = raw_depth_buff[depth_idx];
	int cx_d = depth_intrinsics.x;
	int cy_d = depth_intrinsics.y;
	int fx_d = depth_intrinsics.z;
	int fy_d = depth_intrinsics.w;

	float z = raw_depth_to_meters(raw_depth);
	float x = (col + depth_xoff - cx_d) * z / fx_d;
	float y = (row - cy_d) * z / fy_d;
	
	vbo_buff[vbo_idx].x = x;
	vbo_buff[vbo_idx].y = y;
	vbo_buff[vbo_idx].z = z;
	vbo_buff[vbo_idx].w = 0;
}


