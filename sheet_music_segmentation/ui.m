function varargout = ui(varargin)
% UI MATLAB code for ui.fig
%      UI, by itself, creates a new UI or raises the existing
%      singleton*.
%
%      H = UI returns the handle to a new UI or the handle to
%      the existing singleton*.
%
%      UI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in UI.M with the given input arguments.
%
%      UI('Property','Value',...) creates a new UI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ui

% Last Modified by GUIDE v2.5 26-Feb-2020 01:03:39

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ui_OpeningFcn, ...
                   'gui_OutputFcn',  @ui_OutputFcn, ...
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


% --- Executes just before ui is made visible.
function ui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ui (see VARARGIN)

% Choose default command line output for ui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ui wait for user response (see UIRESUME)
% uiwait(handles.figure1);

set(handles.axesImage, 'visible','off');
set(handles.axesFinal, 'visible','off');

% --- Outputs from this function are returned to the command line.
function varargout = ui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in btnInput.
function btnInput_Callback(hObject, eventdata, handles)
% hObject    handle to btnInput (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% 0.读取图片并显示
[filename, pathname] = uigetfile( ...
{  '*.jpg;*.tif;*.png;*.gif','All Image Files';...
   '*.*','All Files' },'mytitle',...
   '001_01_01.jpg');
% png读取，imread比较特殊
% https://blog.csdn.net/daniu2007/article/details/83650294

% 防止空字符串报错bug
if filename == 0
    return
end

if endsWith(filename,'.png')
    [X,map] = imread([pathname, '\', filename]);
    % 防止读取32位bug
    if isempty(map)
        im = rgb2gray(X);
    else
        im= ind2rgb(X,map);
    end
else
    im = imread([pathname, '\', filename]);
end
axes(handles.axesImage);
imshow(im,[]);
method(im,handles);

function method(im,handles)
    cla(handles.axesFinal);
    cla(handles.axesH);
    cla(handles.axesV);
    %% 1.图像二值化并显示水平与垂直方向像素和图像
    if(length(im(1,1,:))==3)
        imGray = rgb2gray(im);
    else
        imGray = im;
    end
    % 加入去除水印的设置
    imBin = imbinarize(imGray,'adaptive','ForegroundPolarity','dark','Sensitivity',0.4);
    se = strel('line',1,0);
    imBin = imopen(imBin,se);
    
    
    [sa, sb] = size(imBin);
    axes(handles.axesV);
    v = sum(imBin,1);
    plot(v);
    axes(handles.axesH);
    h = sum(imBin,2);
    plot(h);


    %% 2.水平方向切割
    minh = min(h);
    res = find(h <= min(h)+10);
    
    %% 3.垂直方向切割
    
    % 此处修正曲谱抬头内容过多的问题
    % 这里好像有bug
    
    axes(handles.axesV);
    if isempty(res)
       return 
    end
    v = sum(imBin(res(1):length(v),:),1);
    plot(v);
    maxv = max(v);
    [~,left]=max(v);
    while v(left) == maxv
       left = left + 1; 
    end
    right = length(v);
    while v(right) == maxv
       right = right - 1; 
    end
    
    %% 2.水平方向切割续
    diffRes = res(2:length(res))-res(1:length(res)-1);
    lineWidth = min(diffRes);
    diffRes = diffRes(find(diffRes ~= lineWidth));
    lineSpace = min(diffRes)+1;

    % 水平方向五线谱
    areaLine = [];
    puLine = [];
    r = length(res);
    areaLine = [areaLine,res(1)];
    num = 2;
    for i = 2:r
        if(res(i)-res(i - 1)~=lineWidth)
            if(num == 6)
                puLine = [puLine,res(i)];
                localArea = h(res(i)+lineSpace:min(res(i)+3*lineSpace,length(h)));
                localSearch = min(localArea);
                down = find(h==localSearch);
                down = max(down);
                areaLine = [areaLine,down];
                num = 0;
            elseif(num == 1)
                areaLine = [areaLine,res(i)];
            else
                puLine = [puLine,res(i)];
            end
            num = num + 1;
        end
    end

    % 和弦图水平
    heLine = [];
    for i = 1:floor(length(areaLine)/2)
        localArea = h(floor(areaLine(i*2-1)-4*lineSpace):floor(areaLine(i*2-1)-lineSpace*0.5));
        localSearch = min(localArea);
        lines = find(localArea<=localSearch*1.1);
        lines = lines + areaLine(i*2-1)-4*lineSpace;
        linesFinal = [lines(1)];
        % 过滤
        for j = 2:length(lines)
            if(lines(j) - lines(j-1)>lineWidth*2)
                linesFinal = [linesFinal;lines(j)];
            end
        end
        heLine = [heLine;linesFinal];
    end

    % 和弦图垂直
    temp = zeros(100,120); % 临时数组，支持一页50行乐谱，20个和弦图
    for i = 1:length(heLine)/4
        localArea = imBin(heLine(i*4-3):heLine(i*4),1:sb);
        localV = sum(localArea,1);
        localV = find(localV == 0);
        if(~isempty(localV))
            temp(i, 1) = localV(1);
        end
        n = 2;
        % 过滤
        for j = 2:length(localV)
            if(localV(j) - localV(j-1)>lineWidth*2)
                temp(i, n) = localV(j);
                n = n + 1;
            end
        end
    end

    % 简谱与歌词区域
    hnew = sum(imBin(:,left+20:right),2);
    maxh = max(hnew);
    sepLine = [];
    for i = 2:length(heLine)/4
        sepLine = [sepLine,areaLine(i*2-2)+lineSpace,heLine(i*4-3)-((heLine(i*4) - heLine(i*4-3)))];
    end
    sepLine = [sepLine,areaLine(i*2)+lineSpace,sa-100];

    sepArea = [];
    for i = 1:length(sepLine)/2
        sign = (hnew(sepLine(i*2-1)) == maxh);
        for j = sepLine(i*2-1)+1:sepLine(i*2)
            if((hnew(j) == maxh) ~= sign)
                sepArea = [sepArea, j];
                sign = (hnew(j) == maxh);
            end
        end
    end

    if ~isempty(sepArea)
        sepAreaFinal = [sepArea(1)];
        sepAreaSign = [hnew(sepArea(1))==maxh];
        for i = 2 : length(sepArea)
           if(sepArea(i) - sepArea(i - 1) > lineSpace)
               sepAreaFinal = [sepAreaFinal,sepArea(i)];
               sepAreaSign = [sepAreaSign, hnew(sepArea(i))==maxh];
           end
        end
    else
        sepAreaFinal = [];
    end
    %% 4.分割结果绘制
    % 原图
    axes(handles.axesFinal);
    imshow(imBin,[]);
    % 垂直方向切割
    % line([left, left],[0, sa], 'color', 'r');
    % line([right, right],[0, sa], 'color', 'r');
    if handles.checkbox1.Value == 1
        % 水平方向五线谱
        for i = 1:length(areaLine)
            line([left, right],[areaLine(i), areaLine(i)], 'color', 'g');
        end
        for i = 1:length(puLine)
            line([left, right],[puLine(i), puLine(i)], 'color', 'b');
        end
    end
    if handles.checkbox2.Value == 1
        % 和弦图谱线
        for i = 1:length(heLine)
            j = 1;
            while temp(ceil(i/5), j) ~= 0
                line([temp(ceil(i/4), j), temp(ceil(i/4),j+5)],[heLine(i), heLine(i)], 'color', 'y');
                j = j + 6;
            end  
        end
        for i = 1:length(heLine)/4
            j = 1;
            while temp(i, j) ~= 0
                line([temp(i, j),temp(i, j)],[heLine(i*4-3), heLine(i*4)], 'color', 'y');
                j = j + 1;
            end  
        end
    end
    if handles.checkbox3.Value == 1
        % 和弦图框
        i = 1;
        j = 1;
        while temp(i, j) ~= 0
            while temp(i, j) ~= 0
                rectangle('Position',[temp(i,j)-5,heLine(i*4-3) - (heLine(i*4) - heLine(i*4-3)),temp(i,j+5) - temp(i,j)+10,(heLine(i*4) - heLine(i*4-3))*2+10],'EdgeColor','r')
                j = j + 6;
            end  
            i = i + 1;
            j = 1;
        end
    end

    % 简谱与歌词区域
    % 未来需要大型修改
    hold on;
    i = 2;
    while i <= length(sepAreaFinal) && sepAreaSign(i) == 0
            i = i + 1;
    end
    imgLyric = [];
    numLyric = [];
    while i <= length(sepAreaFinal)
        if handles.checkbox4.Value == 1
            fill ([left right right left left],[sepAreaFinal(i-1) sepAreaFinal(i-1) sepAreaFinal(i) sepAreaFinal(i) sepAreaFinal(i)],'r','facealpha',0.5);
            imgLyric = [imgLyric;im(sepAreaFinal(i-1):sepAreaFinal(i),left:right)];
            numLyric = [numLyric,sepAreaFinal(i)-sepAreaFinal(i-1)+1];
        end
        i = i + 1;
        while i <= length(sepAreaFinal) && sepAreaSign(i) ~= 0
            if handles.checkbox5.Value == 1
                fill ([left right right left left],[sepAreaFinal(i-1) sepAreaFinal(i-1) sepAreaFinal(i) sepAreaFinal(i) sepAreaFinal(i)],'m','facealpha',0.5);
            end
            i = i + 1;
        end 
        i = i + 1;
    end

% --- Executes on button press in checkbox1.
function checkbox1_Callback(hObject, eventdata, handles)
    im = getimage(handles.axesImage);
    if ~isempty(im)
        method(im,handles);
    end
% hObject    handle to checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox1


% --- Executes on button press in checkbox2.
function checkbox2_Callback(hObject, eventdata, handles)
    im = getimage(handles.axesImage);
    if ~isempty(im)
        method(im,handles);
    end
% hObject    handle to checkbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox2


% --- Executes on button press in checkbox3.
function checkbox3_Callback(hObject, eventdata, handles)
    im = getimage(handles.axesImage);
    if ~isempty(im)
        method(im,handles);
    end
% hObject    handle to checkbox3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox3


% --- Executes on button press in checkbox4.
function checkbox4_Callback(hObject, eventdata, handles)
    im = getimage(handles.axesImage);
    if ~isempty(im)
        method(im,handles);
    end
% hObject    handle to checkbox4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox4


% --- Executes on button press in checkbox5.
function checkbox5_Callback(hObject, eventdata, handles)
    im = getimage(handles.axesImage);
    if ~isempty(im)
        method(im,handles);
    end
% hObject    handle to checkbox5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox5
