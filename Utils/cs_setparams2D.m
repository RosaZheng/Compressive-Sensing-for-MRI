function param = cs_setparams2D(data,mask,npdf,csbasis,dc,opts)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% L1 Recon Parameters 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% generate transform operator
XFM = cs_genXFM(csbasis,size(data));

% generate Fourier sampling operator
FT.times = @(x) pDFT2_inv(x,mask);
FT.trans = @(x) pDFT2_fwd(x,mask);

% scale data
if(dc)
    data = data./npdf;
end

% initialize Parameters for reconstruction
param.FT = FT;
param.data = data;
param.mask = mask;
param.opts = opts;
param.opts.basis = XFM;

if(strcmp(csbasis,'ZP'))
    param.performCS = 0;
else
    param.performCS = 1;
end

end

