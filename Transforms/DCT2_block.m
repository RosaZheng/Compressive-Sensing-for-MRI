function y = DCT2_block(x,blkSize,inputsize,dir)

x = reshape(x,inputsize);
if dir
	y = IDCT_block(x,blkSize);
else
	y = FDCT_block(x,blkSize);
end
y = y(:);