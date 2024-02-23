function [zernikeVector] = set_zernike_ALPAO_DM(dm, nZern, Z2C, zernikeVector, System_Aberation_Vector, ZernikeCoeff, zernikeAmplitude, p)
% Calculates and sets Zernike patterns on DM

% Copyright (c) 2020-2024, Intelligent Imaging Inovations, Inc. (3i) 
% Use of this code is subject to a non-exclusive, revocable, non-transferable, and limited right to use the code
% for the purpose of academic, governmental, or not-for-profit research. Use of the code for commercial purposes
% is strictly prohibited in the absence of a license agreement from Intelligent Imaging Innovations, Inc.

    Zernike_Defocus_Coeff = 3;
    Zernike_Spherical_Coeff = 10;
    if ZernikeCoeff == Zernike_Spherical_Coeff
        zernikeVector(Zernike_Spherical_Coeff) = zernikeAmplitude;
        zernikeVector(Zernike_Defocus_Coeff) = polyval(p, zernikeAmplitude);
        zernikeVector = zernikeVector + System_Aberation_Vector;
    else
        zernikeVector(ZernikeCoeff) = zernikeAmplitude;
        zernikeVector = zernikeVector + System_Aberation_Vector;
    end
    dm.Send(zernikeVector * Z2C);
end

