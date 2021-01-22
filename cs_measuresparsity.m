clear all; close all; clc;

addpath(strcat(pwd,'/Measures'));
addpath(strcat(pwd,'/Utils'));

% Images to test
imgnum = 2;
imgname{1} = 'Data/fse_t1_ax_data.mat';
imgname{2} = 'Data/fse_t2_ax_data.mat';

% Bases to test
csbasis = {'Identity' 'DFT' 'DCT-8' 'DCT-16' 'Wavelet-db1' 'Wavelet-db2'};

for i=1:imgnum
    y = load(imgname{i});
    y = y.d;
    x = ifft2c(y);
    x = x/max(max(abs(x)));
    
    f = figure(i); imshow(abs(x),[0 1]);
    title(['Reconstructed Full Image - ' imgname{i}]);
    set(f,'Position',[200 200 500 400]); drawnow;
    
    for b = 1:length(csbasis);
        
        % Find transform for each basis and find sparsity measures
        XFM = cs_genXFM(csbasis{b});
        z = XFM*x;
        z = reshape(z,[],1);
    	
        %disp([csbasis{b} ' basis - Gini Index for p=1']);
        s = gini(z,1);
        %s = impulsiveness(z);
        %s = kurt(z);
        disp(num2str(s));
            
    end
end