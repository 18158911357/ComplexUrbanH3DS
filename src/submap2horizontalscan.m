function [visible_points] = submap2horizontalscan(submap)

%% projection config 
config_projection;


%% project into spherical view 
num_u = round(H_FOV / AZI_DELTA);
num_v = round((V_FOV + ELE_DELTA*2) / ELE_DELTA);
roi_num_v = num_v - 2;

[sph_scan, range_data] = sphericalProj(submap);
        
sph_scan_x_deg = rad2deg(sph_scan(:, 1));
sph_scan_y_deg = rad2deg(sph_scan(:, 2));

% azimuth = -1 * (sph_scan_x_deg - 180);
azimuth = (sph_scan_x_deg + 90);
elevation = sph_scan_y_deg + V_FOV_LOWER + ELE_DELTA;

u_list = int64(azimuth / AZI_DELTA);
v_list = int64(elevation / ELE_DELTA);

v_list(find(v_list < 1)) = 1;
v_list(find(v_list > num_v)) = int64(num_v);

u_list(find(u_list < 1)) = 1;
u_list(find(u_list > num_u)) = int64(num_u);


%% take nearest points corresponding to each pixel 
vertex_map = zeros(num_v, num_u, 3);
range_map = zeros(num_v, num_u);

num_points = length(submap);
for pt_idx = 1:num_points
    
    cur_vertex = submap(pt_idx, :);
    
    cur_pixel_u = u_list(pt_idx);
    cur_pixel_v = v_list(pt_idx);
    
    prv_range = range_map(cur_pixel_v, cur_pixel_u);
    cur_range = range_data(pt_idx);
    
    if(prv_range == 0)
        range_map(cur_pixel_v, cur_pixel_u) = cur_range;
        vertex_map(cur_pixel_v, cur_pixel_u, :) = cur_vertex;
        continue;
    end
    
    if(cur_range < prv_range)
        vertex_map(cur_pixel_v, cur_pixel_u, :) = cur_vertex;    
    end
end

%% parse 3d points 
maxnum_visible_points = num_u*num_v;
visible_points = zeros(maxnum_visible_points, 3);
visible_points_counter = 1;
for u_idx = 1:num_u        
    for v_idx = 1:num_v
        vertex = squeeze(vertex_map(v_idx, u_idx, :))';
        if(norm(vertex) == 0)
            continue;
        end
        
        visible_points(visible_points_counter, :) = vertex;
        visible_points_counter = visible_points_counter + 1;
    end
end
visible_points = visible_points(1:visible_points_counter-1, :);

end


%% helper 
function [sph_scan, rangemap] = sphericalProj(submap)

x = submap(:, 1);
y = submap(:, 2);
z = submap(:, 3);

depth = sqrt(x.*x + y.*y);
rangemap = sqrt(x.*x + y.*y + z.*z);

azimuth = atan(y./x);
negativ_y_idx = find(y < 0);
azimuth(negativ_y_idx) = azimuth(negativ_y_idx) + pi;

elevation = atan(z./depth);

sph_scan = [azimuth, elevation, depth];

end