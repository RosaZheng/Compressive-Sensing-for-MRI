function [] = img_setOutput(hImage,imgData)
%IMG_SETPROGRESS Summary of this function goes here
%   Detailed explanation goes here
    insize = size(imgData);
    outsize = size(get(hImage,'CData'));
    scalefactor = min(floor(outsize/insize));
    if(scalefactor>1)
        imgData = imresize(imgData, scalefactor);
        insize = size(imgData);
    end
    newimage = zeros(outsize);
    border = floor((outsize - insize) / 2);
    newimage(border(1):insize(1)+border(1)-1,border(2):insize(2)+border(2)-1) = imgData;
    set(hImage,'CData',newimage);
end