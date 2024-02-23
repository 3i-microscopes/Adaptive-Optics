function [Maximal_zernike_Amp_Naive, Maximal_zernike_Amp_fit] = Find_maximal_zernike_amplitude_from_Merit_data(index, zernikeAmplitude, Merit_data, Poly_Degree, IS_SHOW_FIT_RESULTS)
% Copyright (c) 2020-2024, Intelligent Imaging Inovations, Inc. (3i) 
% Use of this code is subject to a non-exclusive, revocable, non-transferable, and limited right to use the code
% for the purpose of academic, governmental, or not-for-profit research. Use of the code for commercial purposes
% is strictly prohibited in the absence of a license agreement from Intelligent Imaging Innovations, Inc.

    Max_index = find(Merit_data == max(Merit_data));
    Max_index = round(mean(Max_index));
    Maximal_zernike_Amp_Naive = zernikeAmplitude(Max_index);
    
    % fit a curve 
    p = polyfit(zernikeAmplitude, Merit_data, Poly_Degree);
    % evaluate on a finer grid
    x1 = linspace(zernikeAmplitude(1), zernikeAmplitude(end), 1000);
    y1 = polyval(p, x1);
    %  maximum point search (could be replaced with a formula)
    Max_index_fit = find(y1 == max(y1));
    Maximal_zernike_Amp_fit = x1(Max_index_fit);
    Maximal_zernike_Amp_fit = mean(Maximal_zernike_Amp_fit);
        
    if (IS_SHOW_FIT_RESULTS)
        zernikeCoeff = index + 3;
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
           
        figure;
        plot(zernikeAmplitude, Merit_data, 'ob');
        hold on
        plot(x1, y1);
        plot(Maximal_zernike_Amp_fit, y1(Max_index_fit), 'xk');
        plot(Maximal_zernike_Amp_Naive, Merit_data(Max_index), 'xb');
        hold off
        
        title(['Data for ', str], 'FontSize', 14);
        xlabel('zernike Amplitude', 'FontSize', 14);
        ylabel('Merit', 'FontSize', 14);
        end
end

