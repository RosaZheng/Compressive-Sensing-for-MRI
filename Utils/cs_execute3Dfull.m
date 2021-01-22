function [] = cs_execute3Dfull(p,handles)

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
    
    % Load image and reconstruct frames from all coefficients
    y = load(p.imgname{i});
    y = y.d;
    frames = size(y,3);
    x = zeros(size(y));
    for n = 1:frames
        x(:,:,n) = fft2c(y(:,:,n));
    end
    x = x/max(max(max(abs(x))));
    [~, shortname, ~] = fileparts(p.imgname{i});
    
    set(handles.textOutput,'String',['Full Video -  ' shortname]);
    for a = 1:size(y,3)
        img_setOutput(handles.outputImage,abs(x(:,:,a)));
        drawnow;
        pause(0.1);
    end
    
    for n = 1:frames
        f = figure('Visible', 'off');
        imshow(abs(x(:,:,n)),[0 1]);
        title(['Fully Sampled Reconstruction for ' shortname ' frame ' num2str(n)]);
        saveas(f,['Output\vid' num2str(i) '_frame' num2str(n) '_full.png']);
        close(f);
    end
    
    for n = 1:p.trialnum
    
        trialstart = tic;
        for a = 1:length(p.ratio);

            ratiostart = tic;
            rmsetrial = zeros(length(p.csbasis),1);
            psnrtrial = zeros(length(p.csbasis),1);
            
            % Generate image mask with some of the coefficients set to zero
            [mask npdf] = cs_generatemask3D(size(y), p.ratio(a), p.mask);
        
            figlabel = [maskparams sprintf('\n') 'Relative Density ' num2str(p.mask.density) ', ' num2str(p.ratio(a)*100) '% of coefficients sampled'];
            
            if(p.savemask)
                for b = 1:frames
                    f = figure('Visible', 'off');
                    imshow(mask(:,:,b),[0 1]);
                    title(['Mask of Sampled FFT Coefficients for ' shortname]);
                    xlabel(figlabel);
                    saveas(f,['Output\vid' num2str(i) '_frame' num2str(b) '_trial' num2str(n) '_ratio' num2str(p.ratio(a)*100) '_mask.png']);
                    close(f);
                end
            end

            x_cs_full = zeros([size(x) length(p.csbasis)]);
            parfor b = 1:length(p.csbasis);
            
                recontime = tic;
                
                % Perform CS on the k-space data
                csparam = cs_setparams3D(y,mask,npdf,p.csbasis{b},p.dc,p.opts,p.timebasis);
                disp(['Performing CS with basis ' p.csbasis{b}]);
                x_cs = cs_optimizeL13D(csparam);
                x_cs = x_cs/max(max(max(abs(x_cs))));
            
                % Find error measures
                rmsetrial(b) = sqrt(mean(mean(mean((abs(x)-abs(x_cs)).^2))));
                psnrtrial(b) = 1/(rmsetrial(b).^2);
                
                % Find sparsity measures for full video
                if(n==1&&a==1)
                    z = csparam.opts.basis.times(x);
                    z = z(:);
                    giniL1(i,b) = gini(z,1);
                    giniL2(i,b) = gini(z,2);
                    impuls(i,b) = impulsiveness(z);
                    kurtos(i,b) = kurt(z);
                end
                
                % Save reconstructed image to array
                x_cs_full(:,:,:,b) = x_cs;
                
                disp(['BASIS ' p.csbasis{b} ' COMPLETE - ' num2str(toc(recontime)) ' SECONDS']);
            
            end
            
            if(p.saverecon)
                for b = 1:length(p.csbasis)
                    for c = 1:frames
                        f = figure('Visible', 'off');
                        imshow(abs(x_cs_full(:,:,c,b)),[0 1]);
                        title(['Reconstructed Image - ' shortname num2str(c) sprintf('\n') 'RMS Error = ' num2str(rmsetrial(b))]);
                        xlabel([figlabel ', CS basis = ' p.csbasis{b}]);
                        saveas(f,['Output\vid' num2str(i) '_frame' num2str(c) '_trial' num2str(n) '_ratio' num2str(p.ratio(a)*100) '_basis' num2str(b) '.png']);
                        close(f);
                    end
                end
            end
            
            currentrun = (i-1)*p.trialnum*length(p.ratio) + (n-1)*length(p.ratio) + a;
            set(handles.textPercentDone,'String',[num2str(floor(currentrun*100/totalruns)) '%']);
            img_setProgress(handles.progressImage,currentrun/totalruns);
            
            [~,bestbasistrial] = min(rmsetrial);
            set(handles.textOutput,'String',['Reconstructed Video -  '...
                shortname sprintf('\n') num2str(p.ratio(a)*100)...
                '% of coefficents sampled' sprintf('\n') 'Best Basis is '...
                p.csbasis{bestbasistrial}]);
            
            for b=1:frames
                img_setOutput(handles.outputImage,abs(x_cs_full(:,:,b,bestbasistrial)));
                drawnow;
                pause(0.1);
            end
            
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
        set(handles.figureMain,'Name',['3D MRI CS Toolbox - Estimated Time Left ' timeleftstr]);
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
        saveas(f,['Output\vid' num2str(i) '_RMSE.png']);
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
        saveas(f,['Output\vid' num2str(i) '_PSNR.png']);
    end
    close(f);
    
    disp(['VIDEO ' num2str(i) ' COMPLETE - ' num2str(toc(imgstart)) ' SECONDS']);
    
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
