%
%   CONTRAST BASED AUTOFOCUS
%   ver 1.0a
%
%   The Contrast Measure based on Squared Laplacian (CMSL)
%
%   Description:
%   The script works in real time, finding the best focus for
%   the region indicated by the mouse.
%
%   Using article:
%  "Robust Automatic Focus Algorithm for
%   Low Contrast Images Using a New Contrast Measure".
%   Xin Xu, Yinglin Wang, Jinshan Tang, Xiaolong Zhang and Xiaoming Liu
%   http://www.mdpi.com/1424-8220/11/9/8281/pdf
%
%   Video with result:  https://youtu.be/nW57o0fwX2k
%
%   Manarov Zaur, 2017
%
%
    clc; close all; clear all;

%%
%   A u t o f u c u s   P a r a m e t e r s
%   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%
    
afr_height      =  100;
afr_width       =  100;
afr_outline     =  true;
limit_t1        =  6;
boxline_width   =  4;
box_color       = [0,162,255];
img_height      =  1080;
img_width       =  1440;
first_frame     =  0;
frame           =  0;
last_frame      =  149;
filename        = 'source_';
input_path      = 'IN\';
output_path     = 'OUT\';


%%
%  C o m p u t a t i o n   p a r t
%  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%

step            = 0;
pass            = 0;
L               = 0;
L_max           = 0;
L_max_i         = 0;
sum_G           = uint32(0);
jk_reciprocal   = 1 / (afr_height * afr_width);
afr_width_half  = ceil(afr_width   / 2);
afr_height_half = ceil(afr_height  / 2);
x_exit          = img_width  - afr_width_half  - boxline_width;
y_exit          = img_height - afr_height_half - boxline_width;
sign_inc        = 1;
middle_frame    = ceil((last_frame - first_frame) / 2);


% Source image downloading from file
file = strcat(input_path, filename, num2str(frame,'%0.3i'), '.jpeg');
img_rgb = imread(file, 'jpg');
f1 = figure(1); imshow(img_rgb);


while true

    step    = 0;
    pass    = 0;
    L_max   = 0;
    L_max_i = 0;
    
    [x y] = getpts;
    loc = int16([x y]);
    if size(loc)>1
        loc = [loc(1,1) loc(1,2)];
    end
    afr_x = loc(1); afr_y = loc(2);
    
    if afr_x < afr_width_half;
        afr_x = afr_width_half + boxline_width;
    elseif afr_x > img_width - afr_width_half - boxline_width
        afr_x = img_width - afr_width_half - boxline_width;
    end
    if afr_y < afr_height_half;
        afr_y = afr_height_half + boxline_width;
    elseif afr_y > img_height - afr_height_half - boxline_width
        afr_y = img_height - afr_height_half - boxline_width;
    end
    
    if (afr_x == x_exit) && (afr_y == y_exit)
        fprintf('\nDone\n');
        break;
    end
    
    afr_start_x     = afr_x - afr_width_half;
    afr_end_x       = afr_start_x + afr_width;
    afr_start_y     = afr_y - afr_height_half;
    afr_end_y       = afr_start_y + afr_height;

    img_rgb = imread(file, 'jpg');

  while true
    %
    % Contrast measurement
    %
    img_ycbcr       = rgb2ycbcr(img_rgb(afr_start_y:afr_end_y, ...
                                        afr_start_x:afr_end_x,:));
    img_y           = img_ycbcr(:,:,1);
    for x = 2 : afr_width-1
        for y = 2 : afr_height-1
            for i = -1 : 1
                sum_G = sum_G + uint32(abs(img_y(y,x) - img_y(y,x+i)));
                sum_G = sum_G + uint32(abs(img_y(y,x) - img_y(y+i,x)));
               %sum_G = sum_G^2;
            end
        end
    end
    L       = jk_reciprocal * double(sum_G);
    sum_G   = 0;
    
    if step == 0
       %if frame < middle_frame
       %    sign_inc =  1;
       %else
       %    sign_inc = -1;
       %end
    else
        if limit_t1 < L
            if L_max < L;
                L_max   = L;
                L_max_i = frame;
            end
            if last_frame == frame || frame == first_frame
                sign_inc = -sign_inc;
                pass = pass + 1;
            end
        else
            if 0 < L_max
                pass = pass + 1;
                sign_inc = -sign_inc;
            end
        end
    end
    
    step  = step  + 1;
    frame = frame + sign_inc;
    
    if (last_frame == frame) || (frame == first_frame)
        sign_inc = -sign_inc;
    end

	file = strcat(input_path, filename, num2str(frame,'%0.3i'), '.jpeg');
    img_rgb = imread(file, 'jpg');
    f1 = figure(1); imshow(img_rgb);
    
    if (pass == 2) || (step == 200)
      file = strcat(input_path, filename, num2str(frame,'%0.3i'), '.jpeg');
      img_rgb = imread(file, 'jpg');
      f1 = figure(1); imshow(img_rgb);
     %sign_inc = -sign_inc;
      break;
    end
    
  end % while true
  
   frame = L_max_i;
   file = strcat(input_path, filename, num2str(frame,'%0.3i'), '.jpeg');
   img_rgb = imread(file, 'jpg');
   
       % Box rendering
    for i = afr_start_x : afr_end_x
        for j = 0 : boxline_width
            img_rgb(afr_start_y + j, i, :) = box_color;
            img_rgb(afr_end_y - j,   i, :) = box_color;
        end
    end
    for i = afr_start_y : afr_end_y
        for j = 0 : boxline_width
            img_rgb(i, afr_start_x + j, :) = box_color;
            img_rgb(i, afr_end_x   - j, :) = box_color;
        end
    end
    f1 = figure(1); imshow(img_rgb);
    
end % endless cycle