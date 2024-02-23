function [Total_Intensity, High_f_content, Simple_Contrast] = Calc_Merits_for_an_image_non_square_images(Current_Image, Lambda, NA, Magnification, Pixel_size, IS_MEAN_or_MAX)
% Copyright (c) 2020-2024, Intelligent Imaging Inovations, Inc. (3i) 
% Use of this code is subject to a non-exclusive, revocable, non-transferable, and limited right to use the code
% for the purpose of academic, governmental, or not-for-profit research. Use of the code for commercial purposes
% is strictly prohibited in the absence of a license agreement from Intelligent Imaging Innovations, Inc.

    IS_SHOW_IMAGE = 0;
    IS_SHOW_FFT = 0;
    IS_SHOW_DISK = 0;
    if IS_SHOW_IMAGE
        figure()
        imagesc(Current_Image);
    end

    Image_size = size(Current_Image);
    Center_size_number = Image_size / 2 + 1;

    %% FFT
    FFT_Current_image = fft2(Current_Image);
    amp = abs(fftshift((FFT_Current_image)));
    DC_filtered_amplitude = amp;
    DC_filtered_amplitude(Center_size_number, Center_size_number) = 0;
    F = log(DC_filtered_amplitude + 1);     % Use log, for perceptual scaling, and + 1 since log(0) is undefined
    F = mat2gray(F);    % Use mat2gray to scale the image between 0 and 1

    % scaling   
    N_pixels = size(Current_Image, 1);                      % Size in pixels
    N = N_pixels * Pixel_size / Magnification;              % Size in microns
    Fs = 1 / N;                                             % Sampling frequency
    Fv = -N_pixels / 2 * Fs:Fs:(N_pixels / 2 - Fs) * Fs;    % Frequency vector
    Diffraction_limit = Lambda / 2 / NA;
    Diffraction_limit_cutoff_frequency = 1 / Diffraction_limit / 2; % The factor of 2 is due to the Nyquist criteria
    Frequency_range = Fv<Diffraction_limit_cutoff_frequency & Fv>(-1 * Diffraction_limit_cutoff_frequency);
    Radius = find(Frequency_range > 0);
    Radius_index_high = Radius(1);  % in pixels
    
    Frequency_range_low = Fv<Diffraction_limit_cutoff_frequency / 3 & Fv>(-1 * Diffraction_limit_cutoff_frequency / 3);
    Radius = find(Frequency_range_low > 0);
    Radius_index_low = Radius(1);   % in pixels
    
    if IS_SHOW_FFT
        figure()
        imshow(F, []);
        imcontrast
    end

    %% generate a spatial filter in the shape of a disk
    center_index = [Center_size_number(1), Center_size_number(2)];
    [I,J] = meshgrid(1:Image_size(2), 1:Image_size(1));
    R = double((I - center_index(2)).^2 + (J - center_index(1)).^2);
    disk_high = R(Radius_index_high, Center_size_number(1));
    disk_low = R(Radius_index_low, Center_size_number(1));

    Filter = R > disk_low & R < disk_high;
    Filtered_image = Filter .* amp;
    High_f_content = sum(sum(Filtered_image));

    if IS_SHOW_DISK
        figure;
        imshow(F.*Filter, []);
    end

    %% total intensity
    if (IS_MEAN_or_MAX)
        Total_Intensity = mean(mean(Current_Image));
    else
        Total_Intensity = max(max(Current_Image));
    end

    %% contrast
    BR_Current_Image = Current_Image - mean(mean(Current_Image));
    Contrast_rms = sqrt(sum(sum(BR_Current_Image.^2))) / Image_size(1);
    Simple_Contrast = (Total_Intensity - mean(mean(Current_Image))) / (Total_Intensity + mean(mean(Current_Image)));
end

