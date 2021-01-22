function [] = img_setProgress(hImage,progress)
%IMG_SETPROGRESS Summary of this function goes here
%   Detailed explanation goes here
    imgsize = size(get(hImage,'CData'));
    cutoff = floor(progress*(imgsize(2)-4))+2;
    newimage = zeros(imgsize);
    newimage(3:imgsize(1)-2,3:cutoff,3) = 1;
    newimage(3:imgsize(1)-2,cutoff+1:imgsize(2)-2,:) = 1;
    set(hImage,'CData',newimage);
end

