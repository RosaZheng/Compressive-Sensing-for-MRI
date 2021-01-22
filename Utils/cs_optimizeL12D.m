% Performs a CS optimization algorithm on coefficients given by the mask

function im_res = cs_optimizeL12D(param)

if(param.performCS)

    % Perform a CS reconstruction
    % min L1(xfm*im_res) s.t. pIDFT*im_res = data
    
    target = twoD_to_oneD(param.data,param.mask);

    % call YALL1
    fprintf('Problem Size: n = %u, m = %u\n',numel(param.mask),numel(target));
    im_res = yall1(param.FT, target, param.opts);
    im_res = reshape(im_res,size(param.mask));
    
else
    
    im_res = fft2c(param.data.*param.mask);
    
end
        
end

