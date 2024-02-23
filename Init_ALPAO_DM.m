function [nZern, Z2C, dm] = Init_ALPAO_DM()

    addpath([pwd '/Wrapper/']);

    %% Set your mirror serial name
    mirrorSN = 'BAX189';

    %% Initialise new mirror object
    dm = asdkDM(mirrorSN);

    %% Load matrix Zernike to command matrix
    % in NOLL's order without Piston in µm RMS
    Z2C = importdata([mirrorSN '-Z2C.mat']);

    % Number of Zernike in Z2C (Zernike to mirror Command matrix)
    nZern = size(Z2C, 1);

    % Check the number of actuator
    if dm.nAct ~= size(Z2C, 2)
        error('ASDK:NAct', 'Number of actuator mismatch.');
    end
end

