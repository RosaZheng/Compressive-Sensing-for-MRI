function [] = cs_execute(p,handles)

% Open parallel worker pool
if(matlabpool('size')==0&&~p.saverecon)
    matlabpool open;
end

maskparams = [p.mask.uniformity ', ' p.mask.coherence ', ' p.mask.symmetry ', ' p.mask.samplingtype '-Based Sampling'];

% Initialize error parameters
rmse = zeros(length(p.imgname),p.trialnum,length(p.ratio),length(p.csbasis));
totalruns = length(p.imgname)*p.trialnum*length(p.ratio);
shortname = p.imgname;

for i = 1:length(p.imgname)
    
    % Load image and reconstruct from all coefficients
    y = load(p.imgname{i});
    y = y.d;
    x = fft2c(y);
    x = x/max(max(abs(x)));
    
    img_setOutput(handles.outputImage,abs(x));
    set(handles.textOutput,'String',['Full Image -  ' shortname{i}]);
    drawnow;
    
    for n = 1:p.trialnum
    
        trialstart = tic;
        for a = 1:length(p.ratio);

            rmsetrial = zeros(length(p.csbasis),1);
            % Generate image mask with some of the coefficients set to zero
            [mask npdf] = cs_generatemask(size(y), p.ratio(a), p.mask);
        
            figlabel = [maskparams sprintf('\n') num2str(p.ratio(a)*100) '% of coefficients sampled'];
            if(p.savemask)
            	%f = figure(a*10+i);
            	%imshow(mask,[0 1]);
            	%title(['Mask of Sampled FFT Coefficients for ' p.imgname{i}]);
            	%xlabel(figlabel);
            	%set(f,'Position',[200 200 500 400]); drawnow;
            end

            x_cs_full = zeros([size(x) length(p.csbasis)]);
            parfor b = 1:length(p.csbasis);
            
                % Perform CS on the k-space data
                csparam = cs_setparams(y,mask,npdf,p.csbasis{b},p.dc);
                disp(['Performing CS with basis ' p.csbasis{b}]);
                x_cs = cs_optimizeL1(csparam);
                x_cs = x_cs/max(max(abs(x_cs)));
            
                % Find error and plot images
                rmsetrial(b) = sqrt(mean(mean((abs(x)-abs(x_cs)).^2)));
                x_cs_full(:,:,b) = x_cs;
            
                if(p.saverecon)
                    %f = figure(b*100+a*10+i);
                    %imshow(abs(x_cs),[0 1]);
                    %title(['Reconstructed Image - ' p.imgname{i} sprintf('\n') 'RMS Error = ' num2str(rmsetrial(b))]);
                    %xlabel([figlabel ', CS basis = ' p.csbasis{b}]);
                    %set(f,'Position',[200 200 500 400]); drawnow;
                end
            
            end
            
            currentrun = (i-1)*p.trialnum*length(p.ratio) + (n-1)*length(p.ratio) + a;
            set(handles.textPercentDone,'String',[num2str(floor(currentrun*100/totalruns)) '%']);
            img_setProgress(handles.progressImage,currentrun/totalruns);
            
            [~,bestbasis] = min(rmsetrial);
            img_setOutput(handles.outputImage,abs(x_cs_full(:,:,bestbasis)));
            
            set(handles.textOutput,'String',['Reconstructed Image -  '...
                shortname{i} sprintf('\n') num2str(p.ratio(a)*100)...
                '% of coefficents sampled' sprintf('\n') 'Best Basis is '...
                p.csbasis{bestbasis}]);
            
            drawnow;
            rmse(i,n,a,:) = rmsetrial;
            if(strcmp(get(handles.textRunning,'String'),'Aborting...'))
                set(handles.textRunning,'String','Stopped');
                drawnow;
                return;
            end
 
        end
        toc(trialstart);
        pause(2);
        
    end
    
    % Plot errors of different CS methods
    f = figure(i+5);
    for b = 1:length(p.csbasis)
        if(p.trialnum==1)
            plot(p.ratio*100,10*log10(squeeze(rmse(i,1,:,b))));
        else
            plot(p.ratio*100,10*log10(mean(squeeze(rmse(i,:,:,b)),1)));
        end
        hold all;
    end
    hold off;
    title(['RMS Error vs. Coefficient Percentage - ' p.imgname{i}]);
    xlabel('% of Coefficients Sampled'); ylabel('RMS Error (dB)');
    legend(p.csbasis); hold off;
    set(f,'Position',[200 200 500 400]); 
    
end

if(matlabpool('size')>0)
    matlabpool close;
end

end