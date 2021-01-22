function varargout = MRI_CS_Toolbox(varargin)
% Full MRI_CS_TOOLBOX V0.22
%
% Copyright (c) Brice Hirst, 2013
%
% See Help -> Contents for more information

% Run this m-file to open the GUI

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @MRI_CS_Toolbox_OpeningFcn, ...
                   'gui_OutputFcn',  @MRI_CS_Toolbox_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before MRI_CS_Toolbox is made visible.
function MRI_CS_Toolbox_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to MRI_CS_Toolbox (see VARARGIN)

% Add paths
addpath(strcat(pwd,'/Measures'));
addpath(strcat(pwd,'/Transforms'));
addpath(strcat(pwd,'/Utils'));
addpath(strcat(pwd,'/YALL1'));

% Create and init output image
pos = get(handles.axesOutput,'Position');
pimage = zeros(pos(4),pos(3));
handles.outputImage = imshow(pimage,'Parent',handles.axesOutput);

% Create and init progress bar
pos = get(handles.axesProgress,'Position');
pimage = ones(pos(4),pos(3),3);
handles.progressImage = imshow(pimage,'Parent',handles.axesProgress);
img_setProgress(handles.progressImage,0);

% Init YALL1 settings struct and time basis
handles.yall1.model = 3;
handles.yall1.tol = 1e-4;
handles.yall1.param = 5e-4;
handles.timebasis = 'DFT';
handles.CSdimensions = 2;
handles.maskincluded = 0;

% Choose default command line output for MRI_CS_Toolbox
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = MRI_CS_Toolbox_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in buttonAddImage.
function buttonAddImage_Callback(hObject, eventdata, handles)
% hObject    handle to buttonAddImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[filename pathname] = uigetfile('.\Data\*.mat','Select MATLAB k-space data file','MultiSelect','on');

if(iscell(filename))
    for a = 1:length(filename)
        fullpath = [pathname filename{a}];
        relpath = fullpath;
        if(~isempty(strfind(fullpath, pwd)))
            relpath = ['.' fullpath(length(pwd)+1:end)];
        end
        y = load(relpath);
        if(isfield(y,'d'))
            handles.CSdimensions = ndims(y.d);
            if(isfield(y,'mask'))
                handles.maskincluded = 1;
            else
                handles.maskincluded = 0;
            end
            oldstr = get(handles.listImages,'String');
            newstr = [oldstr;{relpath}];
            set(handles.listImages,'String',newstr);
        else
            msgbox('File is not a valid format','File Error','error');
        end
    end
    set(handles.textOutput,'String',[num2str(length(filename)) ' Data Files Loaded']);
else
    if(filename)
        fullpath = [pathname filename];
        relpath = fullpath;
        if(~isempty(strfind(fullpath, pwd)))
            relpath = ['.' fullpath(length(pwd)+1:end)];
        end
        y = load(relpath);
        if(isfield(y,'d'))
            handles.CSdimensions = ndims(y.d);
            if(isfield(y,'mask'))
                handles.maskincluded = 1;
            else
                handles.maskincluded = 0;
            end
            if(handles.maskincluded)
                set(handles.textOutput,'String',['Data Loaded - ' filename]);
            else
                y = y.d;
                if(ndims(y)==2)
                    x = fft2c(y);
                    x = x/max(max(abs(x)));
                    img_setOutput(handles.outputImage,abs(x));
                    set(handles.textOutput,'String',['Image Loaded - ' filename]);
                else
                    for a = 1:size(y,3)
                        x = fft2c(y(:,:,a));
                        x = x/max(max(abs(x)));
                        img_setOutput(handles.outputImage,abs(x));
                        pause(0.1);
                    end
                    set(handles.textOutput,'String',['Video Loaded - ' filename]);
                end
            end
            oldstr = get(handles.listImages,'String');
            newstr = [oldstr;{relpath}];
            set(handles.listImages,'String',newstr);
        else
            msgbox('File is not a valid format','File Error','error');
        end
    end
end

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in buttonDeleteImage.
function buttonDeleteImage_Callback(hObject, eventdata, handles)
% hObject    handle to buttonDeleteImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

index = get(handles.listImages,'Value');
if(index(1)>0)
    oldstr = get(handles.listImages,'String');
    newstr = {};
    for a = 1:length(oldstr)
        if(isempty(find(index==a,1)))
            newstr = [newstr;oldstr(a)];
        end
    end
    set(handles.listImages,'String',newstr);
    set(handles.listImages,'Value',1);
end


% --- Executes on button press in buttonAddBasis.
function buttonAddBasis_Callback(hObject, eventdata, handles)
% hObject    handle to buttonAddBasis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

bases = {'ZP' 'Identity' 'DFT' 'DCT-8' 'DCT-16' 'DCT-32' 'DCT-64' 'DCT-Full'};

for a = 1:45
    bases = [bases {['Wavelet-db' num2str(a)]}];
end
for a = 2:45
    bases = [bases {['Wavelet-sym' num2str(a)]}];
end
for a = 1:5
    bases = [bases {['Wavelet-coif' num2str(a)]}];
end

bases = [bases {  'Wavelet-bior1.3' 'Wavelet-bior1.5'...
'Wavelet-bior2.2' 'Wavelet-bior2.4' 'Wavelet-bior2.6' 'Wavelet-bior2.8'...
'Wavelet-bior3.1' 'Wavelet-bior3.3' 'Wavelet-bior3.5' 'Wavelet-bior3.7'...
'Wavelet-bior3.9' 'Wavelet-bior4.4' 'Wavelet-bior5.5' 'Wavelet-bior6.8'...
'Wavelet-rbio1.3' 'Wavelet-rbio1.5'...
'Wavelet-rbio2.2' 'Wavelet-rbio2.4' 'Wavelet-rbio2.6' 'Wavelet-rbio2.8'...
'Wavelet-rbio3.1' 'Wavelet-rbio3.3' 'Wavelet-rbio3.5' 'Wavelet-rbio3.7'...
'Wavelet-rbio3.9' 'Wavelet-rbio4.4' 'Wavelet-rbio5.5' 'Wavelet-rbio6.8'}];
        
bases = [bases {'Wavelet-dmey' 'FDX' 'FDX-2' 'FDX-3' 'FDY' 'FDY-2' 'FDY-3'}];

[s,v] = listdlg('PromptString','Select a Basis:','SelectionMode','multiple','ListString',bases);
if(v)
    newstr = get(handles.listBases,'String');
    for a = 1:length(s)
        newstr = [newstr;bases(s(a))];
    end
    set(handles.listBases,'String',newstr);
end
            

% --- Executes on button press in buttonDeleteBasis.
function buttonDeleteBasis_Callback(hObject, eventdata, handles)
% hObject    handle to buttonDeleteBasis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

index = get(handles.listBases,'Value');
if(index(1)>0)
    oldstr = get(handles.listBases,'String');
    newstr = {};
    for a = 1:length(oldstr)
        if(isempty(find(index==a,1)))
            newstr = [newstr;oldstr(a)];
        end
	end
    set(handles.listBases,'String',newstr);
    set(handles.listBases,'Value',1);
end


% --- Executes on button press in buttonExecute.
function buttonExecute_Callback(hObject, eventdata, handles)
% hObject    handle to buttonExecute (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.textRunning,'String','Running...');
set(handles.textPercentDone,'String','0%');
img_setProgress(handles.progressImage,0);
p = get_params(handles);
if(isempty(p.imgname)||isempty(p.csbasis))
    msgbox('You must add at least one data file and one basis','Parameter Error','error');
elseif(isempty(p.ratio)||length(p.ratio)>100)
    msgbox('Sampling coefficients must consist of between 1 and 100 steps','Parameter Error','error');
elseif(~strcmp(p.mask.uniformity,'Uniform')&&~strcmp(p.mask.coherence,'Incoherent'))
    msgbox('Nonuniform, coherent sampling is not available','Parameter Error','error');
else
    clc; disp('INITIALIZING EXPERIMENT...');
    if(matlabpool('size')==0)
        matlabpool open;
    end
    if(p.CSdimensions==2)
        if(p.maskincluded==0)
            disp('Input data is 2D, fully sampled...');
            cs_execute2Dfull(p,handles);
        else
            disp('Input data is 2D, undersampled...');
            cs_execute2Dunder(p,handles);
        end
    else
        if(p.maskincluded==0)
            disp('Input data is 3D, fully sampled...');
            cs_execute3Dfull(p,handles);
        else
            disp('Input data is 3D, undersampled...');
            cs_execute3Dunder(p,handles);
        end
    end
end

set(handles.textRunning,'String','Stopped');
set(handles.figureMain,'Name','MRI CS Toolbox');


% --- Executes on button press in pushbuttonStop.
function pushbuttonStop_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonStop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.textRunning,'String','Aborting...');
drawnow;


% --- Executes on button press in pushbuttonYALL1.
function pushbuttonYALL1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonYALL1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

timebases = {'Identity' 'DFT' 'DCT' 'FD'};
[s,v] = listdlg('PromptString','Select a minimization model:','SelectionMode','single','ListString',{'BP (basis pursuit)','L1/L1 unconstrained','L1/L2 unconstrained','L1/L2 constrained'});
if(v)
    handles.yall1.model = s;
    if(s==1)
        answer = inputdlg({'Enter a stopping tolerance:'},'',1,{'1e-4'});
        handles.yall1.tol = str2double(answer{1});
    else
        vtype = 'nu';
        if(s==3)
           vtype = 'rho';
        end
        if(s==4)
           vtype = 'delta';
        end
        answer = inputdlg({'Enter a stopping tolerance:' ['Enter the value for ' vtype ':']},'',1,{'1e-4' '5e-4'});
        handles.yall1.tol = str2double(answer{1});
        handles.yall1.param = str2double(answer{2});
    end
    [s2,v2] = listdlg('PromptString','Select a 3D time domain basis 3D:','SelectionMode','single','ListString',timebases);
    if(v2)
        handles.timebasis = timebases{s2};
    end
end

% Update handles structure
guidata(hObject, handles);


% --------------------------------------------------------------------
function Load_Settings_Callback(hObject, eventdata, handles)
% hObject    handle to Load_Settings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[filename pathname] = uigetfile('.\Settings\*.mat','Select MATLAB settings file');
if(filename)
    load([pathname filename]);
    handles = set_params(p,handles);
    
    % Update handles structure
    guidata(hObject, handles);
end


% --------------------------------------------------------------------
function Save_Settings_Callback(hObject, eventdata, handles)
% hObject    handle to Save_Settings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

p = get_params(handles);
[filename pathname] = uiputfile('.\Settings\*.mat','Save MATLAB settings file');
if(filename)
    save([pathname filename],'p');
end


% --------------------------------------------------------------------
function Exit_Callback(hObject, eventdata, handles)
% hObject    handle to Exit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

close;


% --------------------------------------------------------------------
function Convert_Paravision_FID_Callback(hObject, eventdata, handles)
% hObject    handle to Convert_Paravision_FID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

foldername = uigetdir('.\','Select directory containing FID file');
[filename pathname] = uiputfile('.\','Save output MAT file');
convert_paravision(foldername,[pathname filename]);


% --------------------------------------------------------------------
function Contents_Callback(hObject, eventdata, handles)
% hObject    handle to Contents (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

web('./Help/index.html','-browser');


% --------------------------------------------------------------------
function About_Callback(hObject, eventdata, handles)
% hObject    handle to About (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

doc MRI_CS_Toolbox;


% --------------------------------------------------------------------
function p = get_params(handles)

p.imgname = get(handles.listImages,'String');
p.csbasis = get(handles.listBases,'String');
p.saverecon = get(handles.checkboxSaveRecon,'Value');
p.savemask = get(handles.checkboxSaveMasks,'Value');
p.saveerror = get(handles.checkboxSaveError,'Value');
p.dc = get(handles.checkboxDC,'Value');

p.ratio = str2double(get(handles.editStartRatio,'String')):str2double(get(handles.editStepRatio,'String')):str2double(get(handles.editStopRatio,'String'));
p.trialnum = str2double(get(handles.editTrials,'String'));

if(get(handles.radioUniform,'Value'))
    p.mask.uniformity = 'Uniform';
else
    p.mask.uniformity = 'Nonuniform';
end
if(get(handles.radioIncoherent,'Value')) 
    p.mask.coherence = 'Incoherent';
else
    p.mask.coherence = 'Coherent';
end
if(get(handles.radioLine,'Value'))
    p.mask.samplingtype = 'Line';
else
    p.mask.samplingtype = 'Point';
end
if(get(handles.radioSymmetric,'Value'))
    p.mask.symmetry = 'Symmetric';
else
    p.mask.symmetry = 'Asymmetric';
end
p.mask.density = str2double(get(handles.editDensity,'String'));
p.mask.trials = str2double(get(handles.editMaskTrials,'String'));

p.opts.tol = handles.yall1.tol;
if(handles.yall1.model==2)
    p.opts.nu = handles.yall1.param;
end
if(handles.yall1.model==3)
    p.opts.rho = handles.yall1.param;
end
if(handles.yall1.model==4)
    p.opts.delta = handles.yall1.param;
end
p.timebasis = handles.timebasis;
p.CSdimensions = handles.CSdimensions;
p.maskincluded = handles.maskincluded;

% --------------------------------------------------------------------
function handles = set_params(p,handles)

set(handles.listImages,'String',p.imgname);
set(handles.listImages,'Value',1);
set(handles.listBases,'String',p.csbasis);
set(handles.listBases,'Value',1);
set(handles.checkboxSaveRecon,'Value',p.saverecon);
set(handles.checkboxSaveMasks,'Value',p.savemask);
set(handles.checkboxSaveError,'Value',p.saveerror);
set(handles.checkboxDC,'Value',p.dc);

set(handles.editStartRatio,'String',num2str(p.ratio(1)));
set(handles.editStopRatio,'String',num2str(p.ratio(end)));
if(length(p.ratio)>1)
    set(handles.editStepRatio,'String',num2str(p.ratio(2)-p.ratio(1)));   
else
    set(handles.editStepRatio,'String','0.1');      
end
set(handles.editTrials,'String',num2str(p.trialnum));

if(strcmp(p.mask.uniformity,'Uniform'))
    set(handles.radioUniform,'Value',1);
else
    set(handles.radioNonuniform,'Value',1);
end
if(strcmp(p.mask.coherence,'Incoherent'))
    set(handles.radioIncoherent,'Value',1);
else
    set(handles.radioCoherent,'Value',1);
end
if(strcmp(p.mask.samplingtype,'Line'))
    set(handles.radioLine,'Value',1);
else
    set(handles.radioPoint,'Value',1);
end
if(strcmp(p.mask.symmetry,'Symmetric'))
    set(handles.radioSymmetric,'Value',1);
else
    set(handles.radioAsymmetric,'Value',1);
end
set(handles.editDensity,'String',num2str(p.mask.density));
set(handles.editMaskTrials,'String',num2str(p.mask.trials));

handles.yall1.tol = p.opts.tol;
handles.yall1.model = 1;
if(isfield(p.opts,'nu'))
    handles.yall1.model = 2;
    handles.yall1.param = p.opts.nu;
end
if(isfield(p.opts,'rho'))
    handles.yall1.model = 3;
    handles.yall1.param = p.opts.rho;
end
if(isfield(p.opts,'delta'))
    handles.yall1.model = 4;
    handles.yall1.param = p.opts.delta;
end
handles.timebasis = p.timebasis;
handles.CSdimensions = p.CSdimensions;
handles.maskincluded = p.maskincluded;


% --- Executes on button press in checkboxSaveError.
function checkboxSaveError_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxSaveError (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxSaveError

% --- Executes on button press in checkboxSaveRecon.
function checkboxSaveRecon_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxSaveRecon (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxSaveRecon

% --- Executes on button press in checkboxSaveMasks.
function checkboxSaveMasks_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxSaveMasks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxSaveMasks

function editTrials_Callback(hObject, eventdata, handles)
% hObject    handle to editTrials (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editTrials as text
%        str2double(get(hObject,'String')) returns contents of editTrials as a double

% --- Executes during object creation, after setting all properties.
function editTrials_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editTrials (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editStartRatio_Callback(hObject, eventdata, handles)
% hObject    handle to editStartRatio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editStartRatio as text
%        str2double(get(hObject,'String')) returns contents of editStartRatio as a double

% --- Executes during object creation, after setting all properties.
function editStartRatio_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editStartRatio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editStopRatio_Callback(hObject, eventdata, handles)
% hObject    handle to editStopRatio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editStopRatio as text
%        str2double(get(hObject,'String')) returns contents of editStopRatio as a double

% --- Executes during object creation, after setting all properties.
function editStopRatio_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editStopRatio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editStepRatio_Callback(hObject, eventdata, handles)
% hObject    handle to editStepRatio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editStepRatio as text
%        str2double(get(hObject,'String')) returns contents of editStepRatio as a double

% --- Executes during object creation, after setting all properties.
function editStepRatio_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editStepRatio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in checkboxDC.
function checkboxDC_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxDC (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxDC

% --- Executes on selection change in listImages.
function listImages_Callback(hObject, eventdata, handles)
% hObject    handle to listImages (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listImages contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listImages

% --- Executes during object creation, after setting all properties.
function listImages_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listImages (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in listBases.
function listBases_Callback(hObject, eventdata, handles)
% hObject    handle to listBases (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listBases contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listBases

% --- Executes during object creation, after setting all properties.
function listBases_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listBases (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editDensity_Callback(hObject, eventdata, handles)
% hObject    handle to editDensity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editDensity as text
%        str2double(get(hObject,'String')) returns contents of editDensity as a double

% --- Executes during object creation, after setting all properties.
function editDensity_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDensity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editMaskTrials_Callback(hObject, eventdata, handles)
% hObject    handle to editMaskTrials (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editMaskTrials as text
%        str2double(get(hObject,'String')) returns contents of editMaskTrials as a double

% --- Executes during object creation, after setting all properties.
function editMaskTrials_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editMaskTrials (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
