function y = pDFT3_fwd(x,mask)
% Takes a small 1D k-space vector x and the mask, and generates 1D image y

y = zeros(size(mask));
ind = 1;
for a = 1:size(mask,3)
    fullspace = oneD_to_twoD(x(ind:end),mask(:,:,a));
    ind = ind + sum(sum(mask(:,:,a)));
    y(:,:,a) = fft2c(fullspace);
end
y = y(:);