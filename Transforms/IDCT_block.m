function res = IDCT_block(x,blkSize)

% res = IDCT(x,blkSize)
%
% local idct implementation
%
% (c) Zengli Yang 2011

D = dctmtx(blkSize);
fun = @(block_struct) D'*block_struct.data*D;
res = blockproc(x,[blkSize,blkSize],fun);