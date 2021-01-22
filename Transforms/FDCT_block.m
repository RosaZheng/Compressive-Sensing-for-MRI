function res = FDCT_block(x,blkSize)

% res = FDCT(x,blkSize)
%
% local dct implementation
%
% (c) Zengli Yang 2011

D = dctmtx(blkSize);
fun = @(block_struct) D*block_struct.data*D';
res = blockproc(x,[blkSize,blkSize],fun);