% Performs a CS optimization algorithm on coefficients given by the mask

function im_res = cs_optimizeL13D(param)

if(param.performCS)

    % Perform a CS reconstruction
    target = [];
    for a=1:size(param.mask,3)
        target = [target;twoD_to_oneD(param.data(:,:,a),param.mask(:,:,a))];
    end

    % call YALL1
    fprintf('Problem Size: n = %u, m = %u\n',numel(param.mask),numel(target));
    im_res = yall1(param.FT, target, param.opts);
    im_res = reshape(im_res,size(param.mask));
    
else
    
    for a=1:size(param.mask,3)
        im_res(:,:,a) = fft2c(param.data(:,:,a).*param.mask(:,:,a));
    end
    
end
        
end

