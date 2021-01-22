function x = pDFT3_inv(y,mask)
% Takes a 1D image y and creates a shrunken 1D k-space x vector

fullspace = reshape(y,size(mask));

for a = 1:size(mask,3)
    fullspace(:,:,a) = ifft2c(fullspace(:,:,a));
end

x = [];
for a=1:size(mask,3)
    x = [x;twoD_to_oneD(fullspace(:,:,a),mask(:,:,a))];
end