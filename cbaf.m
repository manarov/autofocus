%
%   CONTRAST BASED AUTOFOCUS
%   ver 1.0a
%
%   The Contrast Measure based on Squared Laplacian (CMSL).
%
%   Description:
%   The script finds the best focus of the region specified for
%   an arbitrary sequence of frames. Allows you to configure
%   the autofocus region, its size and position. During the search,
%   statistics is displayed. The result of the work is the frame
%   number and the maximum contrast value calculated by the CMSL
%   algorithm for the selected region.
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
afr_x           =  250;
afr_y           =  480;
box_width       =  6;
box_color       = [255,0,0];
axis_x_length   =  300;
axis_y_length   =  256;
axis_width      =  2;
axis_color      = [235,235,235];
chart_width     =  2;
chart_color     = [255,255,255];
scale_factor    =  10;
limit_t1        =  6;
img_height      =  1080;
img_width       =  1440;
first_frame     =  0;
last_frame      =  149;
fps             =  25;
filename        = 'source_';
input_path      = 'IN\';
output_path     = 'OUT\';



%%
%  C o m p u t a t i o n   p a r t
%  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%

frames          = last_frame - first_frame;
frame_counter   = -1;

L               = 0;
L_max           = 0;
L_max_i         = 0;
L_max_valid     = 0;
sum_G           = uint32(0);
jk_reciprocal   = 1 / (afr_height * afr_width);

afr_start_x     = afr_x - ceil(afr_width  / 2);
afr_end_x       = afr_start_x + afr_width;
afr_start_y     = afr_y - ceil(afr_height / 2);
afr_end_y       = afr_start_y + afr_height;

axis_x_start    = afr_x - ceil(axis_x_length / 2);
axis_x_end      = axis_x_start + axis_x_length - 1;
axis_y_end      = afr_y + afr_height;
axis_y_start    = axis_y_end + axis_y_length - 1;

text_str        = cell(4,1);
text_str{1}     = ['TCR ...'];
text_str{2}     = ['UPWORK'];
text_str{3}     = ['2017(C) Manarov'];
text_str{4}     = ['Contrast Based Autofocus Algorithm (CMSL)'];
text_str{5}     = ['L  = ...'];
text_str{6}     = ['Lm undefined'];
position        = [50 img_height-100; ...
                   img_width/2-50 img_height-100; ...
                   img_width-330 img_height-100; ...
                   50 50; ...
           afr_x + ceil(afr_width/2) + 10 afr_y - ceil(afr_height/2); ...
           afr_x + ceil(afr_width/2) + 10 afr_y - ceil(afr_height/2) + 60];
textbox_color   = {'w','w','w','w','w','w'};
second          = 0;
frame           = 0;
chart_width     = chart_width - 1;
                
%%
% Сomputation cycle
%
for frame_ctr = first_frame : last_frame

clc;
fprintf(['\nFrame ',num2str(frame_ctr,'%0.3i'),' of ',num2str(frames)]);

text_str{1} = ['TCR ',num2str(second,'%0.2i'),':',num2str(frame,'%0.2i')];

frame   = frame  + 1;
if frame == fps+1
    second  = second + 1;
    frame = 0;
end



% Source image downloading from file
file = strcat(input_path, filename, num2str(frame_ctr,'%0.3i'), '.jpeg');
img_rgb = imread(file, 'jpg');

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
        
L       = [L, jk_reciprocal * double(sum_G)];
sum_G   = 0;


% Determination of the maximum
if limit_t1 < L(frame_ctr+2)
    if L_max < L(frame_ctr+2)
        L_max   = L(frame_ctr+2);
        L_max_i = frame_ctr+2;
    end
	textbox_color{5} = 'green';    
else
    if 0 < L_max_i
        L_max_valid = 1;
        text_str{6}     = ['Lmax = ',num2str(L_max,'%2.3f'),...
                           ' at frame #',num2str(L_max_i)];
    end
	textbox_color{5} = 'white';
end

text_str{5}     = ['L(x,y) = ',num2str(L(frame_ctr+2),'%2.3f')];


%
% F r a m e   r e n d e r i n g
%


% Box rendering
for i = afr_start_x : afr_end_x
    for j = 0 : box_width
        img_rgb(afr_start_y + j, i, :) = box_color;
        img_rgb(afr_end_y - j,   i, :) = box_color;
    end
end
for i = afr_start_y : afr_end_y
    for j = 0 : box_width
        img_rgb(i, afr_start_x + j, :) = box_color;
        img_rgb(i, afr_end_x   - j, :) = box_color;
    end
end



% Axis rendering
for i = axis_x_start : axis_x_end
    for j = 0 : axis_width
        img_rgb(axis_y_start - axis_width + j, i, :) = axis_color;
    end
end
for i = axis_y_end : axis_y_start
    for j = 0 : axis_width
        img_rgb(i, axis_x_start + axis_width - j, :) = axis_color;
    end
end

% Chart rendering
for i = 1 : frame_ctr
    L_attached = ceil(axis_y_start - int16(scale_factor*L(i+1)));
    if (axis_y_start - L_attached> scale_factor * limit_t1)
        char_color = [150, 150, 255];
    else
        char_color = chart_color;
    end
    for j = L_attached : axis_y_start
        for k = 0 : chart_width
            img_rgb(j, axis_x_start+(i-chart_width)*chart_width+i+k,...
                                                        :) = char_color;
        end
    end
end

% Rendering of a mark
if L_max_valid
    L_max_attached = ceil(axis_y_start - int16(scale_factor*L(L_max_i)));
    for i = 1 : 12
        for j = 0 : 2
            img_rgb(L_max_attached - 3 - i, ...
            axis_x_start + (L_max_i - chart_width)*chart_width + ...
            L_max_i-1 +i-j, :) = [255,000,000];
            img_rgb(L_max_attached - 3 - i, ...
            axis_x_start + (L_max_i - chart_width)*chart_width + ...
            L_max_i-1 -i+j, :) = [255,000,000];
        end
    end
end

% Text rendering
img_rgb = insertText(img_rgb,position,text_str,'FontSize',30,'BoxColor',...
                    textbox_color,'BoxOpacity',0.4,'TextColor','black');
                

%%
% O u t p u t   o f   r e s u l t s
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%

f1 = figure(1);
imshow(img_rgb);

file = strcat(output_path, 'img_', num2str(frame_ctr,'%0.3i'), '.jpeg');
imwrite(img_rgb,file,'Quality',100);


end % for frame_ctr = first_frame : last_frame

fprintf('\nDone\n');