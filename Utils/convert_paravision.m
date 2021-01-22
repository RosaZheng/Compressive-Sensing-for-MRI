function convert_paravision(directory,fileout)

disp('Converting Paravision FID data to MAT file...');

% Open all relevant files
acqp = fopen([directory '/acqp'],'r');
fid = fopen([directory '/fid'],'r');
dmask = fopen([directory '/mask.txt'],'r');
undersampled = 1;
if(dmask==-1)
    undersampled = 0;
else
    maskdim = str2num(fgetl(dmask));
end

% Get dimensions and data size from acqp
dimfound = 0;
while(~dimfound&&~feof(acqp))
    l = fgetl(acqp);
    if(strfind(l,'ACQ_size'))
       dimfound = 1; 
    end
end
datadim = str2num(fgetl(acqp));
datadim(1) = datadim(1)/2;
fclose(acqp);

% Read in all the data from the file in order
totalpoints = prod(datadim);
kspace = zeros(totalpoints,1);
for a = 1:totalpoints
    realpoint = fread(fid,1,'int32');
    imagpoint = fread(fid,1,'int32');
    kspace(a) = double(realpoint + 1i*imagpoint);
end
fclose(fid);

% Reshape data into matrix and write to file
if(undersampled)
    d = zeros(maskdim);
    mask = false(maskdim);
    for a = 1:prod(maskdim(2:end))
        startind = maskdim(1)*(a-1)+1;
        endind = maskdim(1)*a;
        mask(startind:endind) = logical(str2double(fgetl(dmask)));
    end
    fclose(dmask);
    dataindex = 0;
    for idx = 1:prod(maskdim)
        if(mask(idx)==1)
            dataindex = dataindex + 1;
            d(idx) = kspace(dataindex);
        end
    end
    save(fileout,'d','mask');
else
    d = reshape(kspace,datadim);
    save(fileout,'d');
end

disp('Finished.');

end
