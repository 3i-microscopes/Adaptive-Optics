%% Acquire_images_in_SlideBook_with_ALPAO_DM

% Copyright (c) 2020-2024, Intelligent Imaging Inovations, Inc. (3i) 
% Use of this code is subject to a non-exclusive, revocable, non-transferable, and limited right to use the code
% for the purpose of academic, governmental, or not-for-profit research. Use of the code for commercial purposes
% is strictly prohibited in the absence of a license agreement from Intelligent Imaging Innovations, Inc.

%% This script preformes indirect, image-based adaptive optics

%% Instructions for user:

%% 1 - Calibrate spherical interaction with defocus by measuring the defocus with ramping spherical aberations on a specimen such as beads. 

% experimental calibration of objective 63x 1.4 Zeiss oil:
Spherical_calibration = [-3:1:3]; % in um RMS
Defocus_corection = [-10.1, -7, -3.3, 0, 1.3, 3.9, 6.8]; % measured with beads, in um RMS

p = polyfit(Spherical_calibration, Defocus_corection, 1);

%% 2 - Define which modes participate in the optimization. 

Zernike_index = [7, 1:6];   % Zernike modes that participate in the optimization 
% Consider using only spherical (7) if the enhancment is too low

%% 3 - Define the range of amplitudes.

% if the aberation is very close to zero, using it in the optimization is only harmful. Therefore a treshold is applied in the code.

    ZernikeAmplitude = [-2:0.5:2];
    Treshold_Value = 0.1; % added to prevent errors
    Polynom_degree = length(ZernikeAmplitude) - 1;
    if (Polynom_degree) > 5
        Polynom_degree = 5;
    end

%% 4 - Define parameters for saving data.

TestName = 'sample mouse 1  ALPAO DM test 9 THG calib with beads 200um deep 512 pixels';
filename = ['M:\Slidebook Data\Hughes lab\Michael\AO data', date, '_DM_images_', TestName, '.mat'];

%% 5 - Define system parameters.

Lambda = 500e-3; % wavelength of flourecence in microns
NA =1; % Numerical apperture of the objective 
Magnification = 20; 
Pixel_size = 16; %camera pixel size in microns;
IS_SHOW_FIT_RESULTS = 1;
IS_SYSTEM_CORRECTION_EXIST = 0;
% Important:
IS_Keep_Optimized_Mode = 1; % this flag defines if the optimized zernike value is kept for the next mode
IS_KEEP_OPTIMIZED_VOLATGED_ON_DM_AT_THE_END = 0;

%% 6 - Define the merit function.
HF_MERIT = 0; % resolution
Intensity_MERIT = 1; % intensity
Intensity_MERIT_Naive = 0;
IS_MEAN_or_MAX = 1 ; % Set 1 for mean and 0 for max for the intensity merit calculation

tic    
% clear some variables 
High_f_content = []; 
Total_Intensity = [];
Maximal_zernike_Amp_Naive_HF = []; Maximal_zernike_Amp_fit_HF = []; 
Maximal_zernike_Amp_Naive_Intensity = []; Maximal_zernike_Amp_fit_Intensity = [];

%% Operate ALPAO DM
[nZern, Z2C, dm] = Init_ALPAO_DM();
dm.Reset(); % write zeros + factory calibration to the DM

%% initialize the parameters
zernikeVector = zeros(1, nZern);
System_Aberation_Vector = zeros(1, nZern);
Optimized_zernike_zernikeVector = zeros(1, nZern);

%% get a first flat Image
isRequestingFrame = 1;
while (isFrameReady == 0)
    pause(0.5);
end
isFrameReady = 0;
flat_Image = AOI;
[Total_Intensity_flat, High_f_content_flat, Contrast_flat] = Calc_Merits_for_an_image_non_square_images(flat_Image, Lambda, NA, Magnification, Pixel_size, IS_MEAN_or_MAX);

%% main loop : go over zernike modes at different amplitudes      
for i = Zernike_index;
    zernikeCoeff = i + 3
    for j = 1:length(ZernikeAmplitude) 
        [zernikeVector] = set_zernike_ALPAO_DM(dm, nZern, Z2C,zernikeVector, System_Aberation_Vector, zernikeCoeff, ZernikeAmplitude(j), p);           
        pause(0.01);

        %% get an image
        isRequestingFrame = 1;
        while (isFrameReady == 0)
            pause(0.1);
        end
        isFrameReady = 0;
        Current_Image = AOI;

        %% calculate merits 
        [Total_Intensity(i,j), High_f_content(i,j), Contrast(i,j)] = Calc_Merits_for_an_image_non_square_images(Current_Image, Lambda, NA, Magnification, Pixel_size, IS_MEAN_or_MAX);
    end 

    % find optimal amplitudes for the Zernike modes
    [Maximal_zernike_Amp_Naive_HF(i), Maximal_zernike_Amp_fit_HF(i)] = Find_maximal_zernike_amplitude_from_Merit_data(Zernike_index, ZernikeAmplitude, High_f_content(i,:), Polynom_degree, IS_SHOW_FIT_RESULTS);
    [Maximal_zernike_Amp_Naive_Intensity(i), Maximal_zernike_Amp_fit_Intensity(i)] = Find_maximal_zernike_amplitude_from_Merit_data(Zernike_index, ZernikeAmplitude, Total_Intensity(i,:), Polynom_degree, IS_SHOW_FIT_RESULTS);
    
    %% Calculate Optimized_zernikePatterns for the different merits according to user selection
    if(HF_MERIT)
        Optimized_zernike_zernikeVector(zernikeCoeff) = Maximal_zernike_Amp_fit_HF(i);
    elseif(Intensity_MERIT)
        if (abs(Maximal_zernike_Amp_fit_Intensity(i))> Treshold_Value)
            Optimized_zernike_zernikeVector(zernikeCoeff) = Maximal_zernike_Amp_fit_Intensity(i);
        else
            Optimized_zernike_zernikeVector(zernikeCoeff) = 0;
        end
    elseif(Intensity_MERIT_Naive)
        Optimized_zernike_zernikeVector(zernikeCoeff) = Maximal_zernike_Amp_Naive_Intensity(i);   
    end
        
    %% Locking spherical and defocus
    Zernike_Defocus_Coeff = 3;
    Zernike_Spherical_Coeff = 10;
    if (zernikeCoeff == Zernike_Spherical_Coeff)
        Optimized_zernike_zernikeVector(Zernike_Defocus_Coeff) = polyval(p, Optimized_zernike_zernikeVector(Zernike_Spherical_Coeff));
    end
         
    if (IS_Keep_Optimized_Mode)
        %% calculate the optimal pattern to display while keeping the previously optimized modes
        zernikeVector = Optimized_zernike_zernikeVector + System_Aberation_Vector;
    else % optimize new mode from a flat pattern , used for ortogonal modes
        zernikeVector = zeros( 1, nZern );
    end    
end
 
%% Sending the optimal puttern to the DM
zernikeVector = Optimized_zernike_zernikeVector;
dm.Send(zernikeVector * Z2C);
toc  % end of main loop 
    
save([filename(1:end-4),'Optimized voltages for ALPAO DM.mat'], 'zernikeVector','Z2C');
pause(0.1);

%% take before and after images
% take an image
isRequestingFrame = 1;
while (isFrameReady == 0)
    pause(0.1);
end
Optimized_image = AOI; % get variable from MATLAB.
isFrameReady = 0;
[Total_Intensity_optimized, High_f_content_optimized, Contrast_optimized] = Calc_Merits_for_an_image_non_square_images(Optimized_image, Lambda, NA, Magnification, Pixel_size, IS_MEAN_or_MAX);
        
% set a flat DM
dm.Reset(); % write zeros + factory calibration to the DM        
if (IS_SYSTEM_CORRECTION_EXIST)
    zernike_Flat_Vector = zeros(1, nZern);
    zernike_Flat_Vector = zernike_Flat_Vector + System_Aberation_Vector;
    dm.Send(zernike_Flat_Vector * Z2C);
end

% take an image
isRequestingFrame = 1;
while (isFrameReady == 0)
    pause(0.1);
end
flat_mirror_image = AOI; % get variable from MATLAB
isFrameReady = 0;
[Total_Intensity_flat, High_f_content_flat, Contrast_flat] = Calc_Merits_for_an_image_non_square_images(flat_mirror_image, Lambda, NA, Magnification, Pixel_size, IS_MEAN_or_MAX);
Enhancement = [Total_Intensity_optimized / Total_Intensity_flat, High_f_content_optimized / High_f_content_flat, Contrast_optimized / Contrast_flat]; 
     
%% Ploting the results
figure() % Zernike modes plot
for i = Zernike_index
    
    zernikeCoeff = i + 3;
    str=[];
    switch (zernikeCoeff)
        case 4
            str = 'ASTIG Y';
        case 5 
            str = 'ASTIG X';
        case 6
            str = 'COMA Y';
        case 7
            str = 'COMA X';
        case 8 
            str = 'Trefoil X';
        case 9
            str = 'Trefoil Y';
        case 10
            str = 'SPHERICAL';
    end      
            
    subplot(1, length(Zernike_index), i)
    plot(ZernikeAmplitude, Total_Intensity(i,:) / max(Total_Intensity(i,:)), 'b');
    xlabel('zernike amplitude'); ylabel('Normelized Merit'); title(['zernike mode #', num2str(i + 3), ' : ' , str])
    hold on
    plot(ZernikeAmplitude, High_f_content(i, :) / max(High_f_content(i, :)), 'r');
    if (i == 1)
        legend('Total_Intensity', 'High_f_content');
    end
    plot(Maximal_zernike_Amp_fit_HF(i), 1, 'ok');
    plot(Maximal_zernike_Amp_fit_Intensity(i), 1, 'og');
end

%% Saving the image
saveas(gcf, [filename(1:end - 4), 'optimization_process.fig']);

figure()
ax1 = subplot(1, 2, 1)
MAX_VALUE = max(max(Optimized_image));
imshow(Optimized_image, [0 MAX_VALUE]);
title(['Optimized Image, enhancements(I HF C): ',num2str(Enhancement)])
ax2 = subplot(1, 2, 2)
imshow(flat_mirror_image, [0 MAX_VALUE]); 
title('flat Image')
Link = linkprop([ax1, ax2], {'CameraUpVector', 'CameraPosition', 'CameraTarget', 'XLim', 'YLim', 'ZLim'});
setappdata(gcf, 'StoreTheLink', Link);

%% Saving the data
saveas(gcf, [filename(1:end - 4), 'before and after results.fig']);
save([filename(1:end - 4),'before_and_after.mat'], 'Optimized_image','flat_mirror_image', 'Enhancement');

w = waitforbuttonpress;
 
%% selecting what to display for the experiment   
answer = questdlg('What AO pattern would you like to use?', ...
	'AO pattern selection Menu', ...
	'Optimized DM', 'Flat DM', 'Close DM and exit', 'Optimized DM');

% Handle response
switch answer
    case 'Optimized DM'
        dm.Send( zernikeVector * Z2C );
    case 'Flat DM'
        % Reset the mirror
        dm.Reset();
    case 'Close DM and exit'
        % Reset the mirror
        dm.Reset();
        %Clear object
        clear dm;
end
