function param = cs_setparams3D(data,mask,npdf,csbasis,dc,opts,timebasis)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% L1 Recon Parameters 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% generate 2D transform operator
XFM = cs_genXFM(csbasis,size(data));

% generate 3D transform operator
fullXFM.times = @(x) compositeXFM(x,XFM.times,timebasis,size(mask),0);
fullXFM.trans = @(x) compositeXFM(x,XFM.trans,timebasis,size(mask),1);

% generate 3D partial Fourier sampling operator
FT.times = @(x) pDFT3_inv(x,mask);
FT.trans = @(x) pDFT3_fwd(x,mask);

% scale data
if(dc)
    data = data./npdf;
end

% initialize Parameters for reconstruction
param.FT = FT;
param.data = data;
param.mask = mask;
param.opts = opts;
param.opts.basis = fullXFM;

if(strcmp(csbasis,'ZP'))
    param.performCS = 0;
else
    param.performCS = 1;
end

end

