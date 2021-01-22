function XFM = cs_genXFM(basis,inputsize)

% generate 2D transform operator, use identity transform if none specified

inputsize = inputsize(1:2);
XFM.times = @(x) x;
XFM.trans = @(x) x;

if(~isempty(strfind(basis,'Wavelet'))) % Wavelet
    dwtmode('per');
    wavName = basis(9:end);
    wavScale = wmaxlev(inputsize,wavName);
    [~,s] = wavedec2(ones(inputsize),wavScale,wavName);
    XFM.times = @(x) DWT2(x,wavName,wavScale,inputsize,s,0);
    XFM.trans = @(x) DWT2(x,wavName,wavScale,inputsize,s,1);
elseif(~isempty(strfind(basis,'DCT'))) % DCT
    if(~isempty(strfind(basis,'Full')))
        XFM.times = @(x) DCT2_full(x,inputsize,0);
        XFM.trans = @(x) DCT2_full(x,inputsize,1);
    else
        XFM.times = @(x) DCT2_block(x,str2double(basis(5:end)),inputsize,0);
        XFM.trans = @(x) DCT2_block(x,str2double(basis(5:end)),inputsize,1);
    end
elseif(~isempty(strfind(basis,'DFT'))) % DFT
    XFM.times = @(x) DFT2(x,inputsize,0);
    XFM.trans = @(x) DFT2(x,inputsize,1);
elseif(~isempty(strfind(basis,'FDX'))) % FDX
    if(~isempty(strfind(basis,'-')))
        XFM.times = @(x) FDX2(x,str2double(basis(5:end)),inputsize,0);
        XFM.trans = @(x) FDX2(x,str2double(basis(5:end)),inputsize,1);
    else
        XFM.times = @(x) FDX2(x,1,inputsize,0);
        XFM.trans = @(x) FDX2(x,1,inputsize,1);    
    end
elseif(~isempty(strfind(basis,'FDY'))) % FDY
    if(~isempty(strfind(basis,'-')))
        XFM.times = @(x) FDY2(x,str2double(basis(5:end)),inputsize,0);
        XFM.trans = @(x) FDY2(x,str2double(basis(5:end)),inputsize,1);
    else
        XFM.times = @(x) FDY2(x,1,inputsize,0);
        XFM.trans = @(x) FDY2(x,1,inputsize,1);    
    end
end

end

