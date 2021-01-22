function [] = cs_execute2Dunder(p,handles)

warning('off','MATLAB:tex');
delete('Output\*.png');

expstart = tic;

for i = 1:length(p.imgname)
    
    imgstart = tic;
    
    % Load image
    y = load(p.imgname{i});
    mask = y.mask;
    y = y.d;
    npdf = ones(size(y));
    [~, shortname, ~] = fileparts(p.imgname{i});
    
    figlabel = 'Pre-Undersampled';
    if(p.savemask)
        f = figure('Visible', 'off');
        imshow(mask,[0 1]);
        title(['Mask of Sampled FFT Coefficients for ' shortname]);
        xlabel(figlabel);
        saveas(f,['Output\img' num2str(i) '_mask.png']);
        close(f);
    end
    
    x_cs_full = zeros([size(y) length(p.csbasis)]);
    parfor b = 1:length(p.csbasis);
        
        recontime = tic;
        
        % Perform CS on the k-space data
        csparam = cs_setparams2D(y,mask,npdf,p.csbasis{b},p.dc,p.opts);
        disp(['Performing CS with basis ' p.csbasis{b}]);
        x_cs = cs_optimizeL12D(csparam);
        x_cs = x_cs/max(max(abs(x_cs)));
        
        % Save reconstructed image to array
        x_cs_full(:,:,b) = x_cs;
        
        disp(['BASIS ' p.csbasis{b} ' COMPLETE - ' num2str(toc(recontime)) ' SECONDS']);
        
    end
    
    if(p.saverecon)
        for b = 1:length(p.csbasis)
            f = figure('Visible', 'off');
            imshow(abs(x_cs_full(:,:,b)),[0 1]);
            title(['Reconstructed Image - ' shortname]);
            xlabel([figlabel ', CS basis = ' p.csbasis{b}]);
            saveas(f,['Output\img' num2str(i) '_basis' num2str(b) '.png']);
            saveas(f,['Output\img' num2str(i) '_basis' num2str(b) '.fig']);
            close(f);           
        end
        
    end
    
    set(handles.textPercentDone,'String',[num2str(floor(i*100/length(p.imgname))) '%']);
    img_setProgress(handles.progressImage,i/length(p.imgname));
    
    if(strcmp(get(handles.textRunning,'String'),'Aborting...'))
        set(handles.textRunning,'String','Stopped');
        drawnow;
        return;
    end

    disp(['IMAGE ' num2str(i) ' COMPLETE - ' num2str(toc(imgstart)) ' SECONDS']);
    
end

% Find experiment's best basis from data
save('Output\output.mat','p','x_cs_full');

disp(['EXPERIMENT COMPLETE - ' num2str(toc(expstart)) ' SECONDS']);

end
