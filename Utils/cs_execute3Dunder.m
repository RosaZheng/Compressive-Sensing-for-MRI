function [] = cs_execute3Dunder(p,handles)

warning('off','MATLAB:tex');
delete('Output\*.png');

expstart = tic;

for i = 1:length(p.imgname)
    
    imgstart = tic;
    
    % Load image
    y = load(p.imgname{i});
    mask = y.mask;
    y = y.d;
    frames = size(y,3);
    npdf = ones(size(y));
    [~, shortname, ~] = fileparts(p.imgname{i});
    
    figlabel = 'Pre-Undersampled'; 
    if(p.savemask)
        for b = 1:frames
            f = figure('Visible', 'off');
            imshow(mask(:,:,b),[0 1]);
            title(['Mask of Sampled FFT Coefficients for ' shortname]);
            xlabel(figlabel);
            saveas(f,['Output\vid' num2str(i) '_frame' num2str(b) '_mask.png']);
            close(f);
        end
    end
    
    x_cs_full = zeros([size(y) length(p.csbasis)]);
    parfor b = 1:length(p.csbasis);
        
        recontime = tic;
        
        % Perform CS on the k-space data
        csparam = cs_setparams3D(y,mask,npdf,p.csbasis{b},p.dc,p.opts,p.timebasis);
        disp(['Performing CS with basis ' p.csbasis{b}]);
        x_cs = cs_optimizeL13D(csparam);
        x_cs = x_cs/max(max(max(abs(x_cs))));
        
        % Save reconstructed image to array
        x_cs_full(:,:,:,b) = x_cs;
        
        disp(['BASIS ' p.csbasis{b} ' COMPLETE - ' num2str(toc(recontime)) ' SECONDS']);
        
    end
    
    if(p.saverecon)
        for b = 1:length(p.csbasis)
            for c = 1:frames
                f = figure('Visible', 'off');
                imshow(abs(x_cs_full(:,:,c,b)),[0 1]);
                title(['Reconstructed Image - ' shortname num2str(c)]);
                xlabel([figlabel ', CS basis = ' p.csbasis{b}]);
                saveas(f,['Output\vid' num2str(i) '_frame' num2str(c) '_basis' num2str(b) '.png']);
                close(f);
            end
        end
    end
    
    set(handles.textPercentDone,'String',[num2str(floor(i*100/length(p.imgname))) '%']);
    img_setProgress(handles.progressImage,i/length(p.imgname));
    
    if(strcmp(get(handles.textRunning,'String'),'Aborting...'))
        set(handles.textRunning,'String','Stopped');
        drawnow;
        return;
    end
    
    disp(['VIDEO ' num2str(i) ' COMPLETE - ' num2str(toc(imgstart)) ' SECONDS']);
    
end

% Find experiment's best basis from data
save('Output\output.mat','p');

disp(['EXPERIMENT COMPLETE - ' num2str(toc(expstart)) ' SECONDS']);

end
