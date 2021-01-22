function [] = cs_execute2Dfull(p,handles)

warning('off','MATLAB:tex');
delete('Output\*.png');

expstart = tic;
maskparams = [p.mask.uniformity ', ' p.mask.coherence ', ' p.mask.symmetry ', ' p.mask.samplingtype '-Based Sampling'];

% Initialize error parameters
rmse = zeros(length(p.imgname),p.trialnum,length(p.ratio),length(p.csbasis));
psnr = zeros(length(p.imgname),p.trialnum,length(p.ratio),length(p.csbasis));
totalruns = length(p.imgname)*p.trialnum*length(p.ratio);
basiscalc = zeros(length(p.imgname),length(p.csbasis),length(p.ratio));
giniL1 = zeros(length(p.imgname),length(p.csbasis));
giniL2 = zeros(length(p.imgname),length(p.csbasis));
impuls = zeros(length(p.imgname),length(p.csbasis));
kurtos = zeros(length(p.imgname),length(p.csbasis));


for i = 1:length(p.imgname)
    
    imgstart = tic;
    
    % Load image and reconstruct from all coefficients
    y = load(p.imgname{i});
    y = y.d;
    x = fft2c(y);
    x = x/max(max(abs(x)));
    [~, shortname, ~] = fileparts(p.imgname{i});
    
    img_setOutput(handles.outputImage,abs(x));
    set(handles.textOutput,'String',['Full Image -  ' shortname]);
    drawnow;
    
	f = figure('Visible', 'off');
	imshow(abs(x),[0 1]);
	title(['Fully Sampled Reconstruction for ' shortname]);
	saveas(f,['Output\img' num2str(i) '_full.png']);
    close(f);
    
    for n = 1:p.trialnum
    
        trialstart = tic;
        for a = 1:length(p.ratio);

            ratiostart = tic;
            rmsetrial = zeros(length(p.csbasis),1);
            psnrtrial = zeros(length(p.csbasis),1);
            % Generate image mask with some of the coefficients set to zero
            [mask npdf] = cs_generatemask2D(size(y), p.ratio(a), p.mask);
        
            figlabel = [maskparams sprintf('\n') 'Relative Density ' num2str(p.mask.density) ', ' num2str(p.ratio(a)*100) '% of coefficients sampled'];
            if(p.savemask)
            	f = figure('Visible', 'off');
            	imshow(mask,[0 1]);
            	title(['Mask of Sampled FFT Coefficients for ' shortname]);
            	xlabel(figlabel);
                saveas(f,['Output\img' num2str(i) '_trial' num2str(n) '_ratio' num2str(p.ratio(a)*100) '_mask.png']);
                close(f);
            end

            x_cs_full = zeros([size(x) length(p.csbasis)]);
            parfor b = 1:length(p.csbasis);
            
                recontime = tic;
                
                % Perform CS on the k-space data
                csparam = cs_setparams2D(y,mask,npdf,p.csbasis{b},p.dc,p.opts);
                disp(['Performing CS with basis ' p.csbasis{b}]);
                x_cs = cs_optimizeL12D(csparam);
                x_cs = x_cs/max(max(abs(x_cs)));
            
                % Find error and plot images
                rmsetrial(b) = sqrt(mean(mean((abs(x)-abs(x_cs)).^2)));
                psnrtrial(b) = 1/(rmsetrial(b).^2);
                
                % Find sparsity measures for full image
                if(n==1&&a==1)
                    z = csparam.opts.basis.times(x);
                    z = z(:);
                    giniL1(i,b) = gini(z,1);
                    giniL2(i,b) = gini(z,2);
                    impuls(i,b) = impulsiveness(z);
                    kurtos(i,b) = kurt(z);
                end
                
                % Save reconstructed image to array
                x_cs_full(:,:,b) = x_cs;
                
                disp(['BASIS ' p.csbasis{b} ' COMPLETE - ' num2str(toc(recontime)) ' SECONDS']);
            
            end
            
            if(p.saverecon)
                for b = 1:length(p.csbasis)
                    f = figure('Visible', 'off');
                    imshow(abs(x_cs_full(:,:,b)),[0 1]);
                    title(['Reconstructed Image - ' shortname sprintf('\n') 'RMS Error = ' num2str(rmsetrial(b))]);
                    xlabel([figlabel ', CS basis = ' p.csbasis{b}]);
                    saveas(f,['Output\img' num2str(i) '_trial' num2str(n) '_ratio' num2str(p.ratio(a)*100) '_basis' num2str(b) '.png']);
                    saveas(f,['Output\img' num2str(i) '_trial' num2str(n) '_ratio' num2str(p.ratio(a)*100) '_basis' num2str(b) '.fig']);
                    close(f);
                end
            end
            
            currentrun = (i-1)*p.trialnum*length(p.ratio) + (n-1)*length(p.ratio) + a;
            set(handles.textPercentDone,'String',[num2str(floor(currentrun*100/totalruns)) '%']);
            img_setProgress(handles.progressImage,currentrun/totalruns);
            
            [~,bestbasistrial] = min(rmsetrial);
            img_setOutput(handles.outputImage,abs(x_cs_full(:,:,bestbasistrial)));
            
            set(handles.textOutput,'String',['Reconstructed Image -  '...
                shortname sprintf('\n') num2str(p.ratio(a)*100)...
                '% of coefficents sampled' sprintf('\n') 'Best Basis is '...
                p.csbasis{bestbasistrial}]);
            
            drawnow;
            rmse(i,n,a,:) = rmsetrial;
            psnr(i,n,a,:) = psnrtrial;
            if(strcmp(get(handles.textRunning,'String'),'Aborting...'))
                set(handles.textRunning,'String','Stopped');
                drawnow;
                return;
            end
            
            disp(['RATIO ' num2str(p.ratio(a)) ' COMPLETE - ' num2str(toc(ratiostart)) ' SECONDS']);
 
        end
        
        % Pause, then calculate remaining time
        trialtime = toc(trialstart) + 2;
        disp(['TRIAL ' num2str(n) ' COMPLETE - ' num2str(trialtime) ' SECONDS']);
        esttimeleft = ceil(trialtime*((length(p.imgname)*p.trialnum)-((i-1)*p.trialnum+n)));
        thours = floor(esttimeleft/3600);
        tminutes = floor(esttimeleft/60) - 60*thours;
        tseconds = esttimeleft - 3600*thours - 60*tminutes;
        timeleftstr = sprintf('%u:%02u:%02u',thours,tminutes,tseconds);
        set(handles.figureMain,'Name',['MRI CS Toolbox - Estimated Time Left ' timeleftstr]);
        pause(2);
        
    end
    
    % Plot errors of different CS methods
    f = figure('Visible', 'off');
    for b = 1:length(p.csbasis)
        if(p.trialnum==1)
            datapoints = 10*log10(squeeze(rmse(i,1,:,b)));
        else
            if(length(p.ratio)==1)
                datapoints = 10*log10(squeeze(mean(squeeze(rmse(i,:,1,b)))));
            else
                datapoints = 10*log10(squeeze(mean(squeeze(rmse(i,:,:,b)),1)));
            end
        end
        plot(p.ratio*100,datapoints);
        hold all;
    end
    hold off;
    title(['RMS Error vs. Coefficient Percentage - ' shortname]);
    xlabel('% of Coefficients Sampled'); ylabel('RMS Error (dB)');
    legend(p.csbasis);
    if(length(p.ratio)>1&&p.saveerror)
        saveas(f,['Output\img' num2str(i) '_RMSE.png']);
    end
    close(f);

    f = figure('Visible', 'off');
    for b = 1:length(p.csbasis)
        if(p.trialnum==1)
            datapoints = 10*log10(squeeze(psnr(i,1,:,b)));
        else
            if(length(p.ratio)==1)
                datapoints = 10*log10(squeeze(mean(squeeze(psnr(i,:,1,b)))));
            else
                datapoints = 10*log10(squeeze(mean(squeeze(psnr(i,:,:,b)),1)));
            end
        end
        basiscalc(i,b,:) = datapoints(:);
        plot(p.ratio*100,datapoints);
        hold all;
    end
    hold off;
    title(['PSNR vs. Coefficient Percentage - ' shortname]);
    xlabel('% of Coefficients Sampled'); ylabel('PSNR (dB)');
    legend(p.csbasis);
    if(length(p.ratio)>1&&p.saveerror)
        saveas(f,['Output\img' num2str(i) '_PSNR.png']);
    end
    close(f);
    
    disp(['IMAGE ' num2str(i) ' COMPLETE - ' num2str(toc(imgstart)) ' SECONDS']);
    
end

% Find experiment's best basis from data
save('Output\output.mat','basiscalc','p','giniL1','giniL2','impuls','kurtos');
basispoints = mean(10.^(basiscalc/10),3);
disp('Best Basis Results (from best to worst, ranked by mean PSNR)');
[hits,ranking] = sort(10*log10(mean(basispoints,1)),'descend');
for b = 1:length(p.csbasis)
    disp([p.csbasis{ranking(b)} ' - ' num2str(hits(b)) ' dB']);
end

disp(['EXPERIMENT COMPLETE - ' num2str(toc(expstart)) ' SECONDS']);

end
