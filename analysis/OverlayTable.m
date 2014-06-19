function [h,hbox] = OverlayTable(hfig,tableData,left,top,width,height,varargin)
%OverlayTable   Make a fully formatable table displayed in a figure
%
%Usage:  [h,hbox] = OverlayTable(gcf,dataTable,left,top,width,height,varargin)
%        [h,hbox] = OverlayTable(gcf,dataTable)
%        [h,hbox] = OverlayTable(gcf,dataTable,[],[],[],[],'fontsize',12)
%
%Note:  The table is composed of annotation textboxes with one per cell in
%the table. Full formatting of the table including fonts, colors, symbols,
%superscripts and substripts is supported.    Right click on the table to
%display a context menu with extensive formatting and editing tools to
%modify the appearance of the table (see below).
%
%Acknowledgements
%OverlayTable requires the wonderfully useful "GUI Layout Toolbox" written
%by Ben Tordoff which is available from the MATLAB File Exchange.
%OverlayTable also relies on a modified version of dsxy2figxy.m which
%appears as an example in the MATLAB documentation.
%
%Inputs
%======
%   hfig ................... Handle of figure in which the table will be
%                            created.
%   tableData .............. Cell array of strings or scalars to appear in
%                            the table. The dimensions of the table (cells)
%                            will match the dimensions of cell array.
%   left ................... Left edge of table in normalized figure units
%                            (0 = left edge of figure).  If empty or absent
%                            the user is prompted to select upper left
%                            corner via the cursor.
%   top .................... Top edge of table (1 = top of figure)
%   width .................. Column widths in normalized units.  If width
%                            is a scalar then all columns have the same
%                            width; if a vector each column has specified
%                            width. If set to zero, empty or absent width
%                            for each column is determined automatically.
%   height ................. Column height.  If set to zero, empty or
%                            absent height for each row is set
%                            automatically.
%   varargin ............... Arguments passed directly to to annotation.
%                            Any valid property,value pair for a textbox
%                            annotation object may be included in this
%                            argument.
%
%Outputs
%=======
%   h ...................... Matrix of handles to text boxes (table cells).
%                            Each entry in h is a handle of an individual
%                            annotation textbox.  Settings in the table can
%                            be changed programatically using
%                            set(h,prop,value) or interactively via the
%                            context menu (see below).
%   hbox ................... Handle to the bounding box for the table.
%
%
%Context Menu Usage
%===================
%   Edit ................... Edit cell contents via OverlayTableEdit
%   Move Table ............. Move the table on the current figure.  User is
%                            presented with cursors which should be used to
%                            select the location of the upper left corner
%                            of the new table location.
%   Format
%       Table .............. Apply selected formatting operation to the
%                            entire table.
%           Font Size ...... Change the table font size
%           Font Weight .... Change the table font weight (bold/normal)
%           Font Color ..... Change the table font color
%           Font ........... Access to all font settings
%           Alignment ...... Set the horizontal or vertical alignment of
%                            the table entries.
%           All ............ Access to ALL table settings via the
%                            properties editor.  WARNING - you have access
%                            here to some settings that should not be
%                            changed.
%       Row ................ As above except settings are only applied to
%                            the currently selected row .
%       Column ............. Settings applied to the current column
%       Cell ............... Settings applied only to the selected cell
%
%   Insert ................. Insert a new column/row to the left/above the
%                            currently selected cell.
%   Append ................. Insert a new column/row to the right/below the
%                            currently selected cell.
%   Delete ................. Delete the selected column, row, or entire
%                            table.
%   Resize Now ............. Force an update to resize the table to match
%                            the cell contents.
%   Enable Auto-Size ....... If checked automatically update the table size
%                            when settings/contents are changed.  (Default
%                            = enabled).
%                            Notes on Auto-Size:
%                               1.  Changes to cell properties or contents
%                               that are initiated in the built-in property
%                               editor will not trigger an automatic resize.
%
%                               2.  In a complex table automatic resize can
%                               generate a lot of overhead especially when
%                               moving figure windows.  The resize function
%                               is triggered by a listener which is
%                               attached to the current window position.  I
%                               am not an expert in this - if anybody could
%                               tell me how to listen to a parameter which
%                               tracks only an actual resize of the window
%                               rather than just the window position
%                               performance of the auto-resize option could
%                               be dramatically improved.
%==========================================================================
%
%Example
%======
%figure
%plot(rand(1,10))
% dTable = {'Column 1','Column 2','Column 3';...
%     '300\circC','\Omega_0','Text Entry'};
%OverlayTable(gcf,dTable);  %User is prompted to use the cursors to place
%the table in the active figure.  Right click on the resulting table to
%further customize appearance or contents.
%
%See also: annotation  OverlayTableEdit

% Jon Caspar
% $Date: 2012/07/31 21:20:24 $
% $Revision: 1.6 $

    %% Initializing
    set(hfig,'Pointer','watch')
    drawnow
        
    [nrows,ncols] = size(tableData);

    if ~ismember('width',who)
        width = 0;
    end
    if ~ismember('height',who)
        height = 0;
    end
    if ~ismember('left',who)
        left = [];
    end
    if~ismember('top',who)
        top = [];
    end
    
    if numel(width) == 1
        width = ones(1,ncols) * width;
    end
    if numel(height) == 1
        height = ones(nrows,1) * height;
    end
        
    h = nan(nrows,ncols);

    %input checking
    if ~iscell(tableData)
        set(hfig,'Pointer','arrow')
        error('Table contents must be provided in a cell array')
    end
    if numel(width) > ncols
        set(hfig,'Pointer','arrow')
        error('Number of columns must match number of specified column widths');
    end
    if numel(height) > nrows
        set(hfig,'Pointer','arrow')
        error('Number of rows must match number of specified row heights');
    end

    if isempty(left) || isempty(top)
        %No position specified, get user to enter position with cursors
        figure(hfig)
        myhappysound
        [x,y] = ginput(1);
        [left,top] = mydsxy2figxy(x,y);
    end

    %% Build context menu
    mnu = uicontextmenu;
    uimenu('Parent',mnu,'Label','Edit','Callback',@EditCell)
    uimenu('Parent',mnu,'Label','Move','Callback',@MoveTable)
    
    uimenu('Parent',mnu,'Label','Format','Separator','on');
    mnuTable = uimenu('Parent',mnu,'Label','    Table...','Tag','Table');
    mnuRow = uimenu('Parent',mnu,'Label','    Row...','Tag','Row');
    mnuCol = uimenu('Parent',mnu,'Label','    Column...','Tag','Col');
    mnuCell = uimenu('Parent',mnu,'Label','    Cell...','Tag','Cell');
    mnuBox = uimenu('Parent',mnu,'Label','    Box...');
    
    mnuBoxBorder = uimenu('Parent',mnuBox,'Label','Border Width');
    uimenu('Parent',mnuBoxBorder,'Label','None',...
        'Callback',@(src,evt)BoxBorder(src,evt,0))
    uimenu('Parent',mnuBoxBorder,'Label','1',...
        'Callback',@(src,evt)BoxBorder(src,evt,1))
    uimenu('Parent',mnuBoxBorder,'Label','2',...
        'Callback',@(src,evt)BoxBorder(src,evt,2))
    uimenu('Parent',mnuBoxBorder,'Label','3',...
        'Callback',@(src,evt)BoxBorder(src,evt,3))
    uimenu('Parent',mnuBox,'Label','Format Box','Callback',@FormatBox);
    
    mnufontsize = uimenu('Parent',mnuTable,'Label','Font Size');
    uimenu('Parent',mnufontsize,'Label','8',...
        'Callback',@(src,evt)FontSize(src,evt,8))
    uimenu('Parent',mnufontsize,'Label','9',...
        'Callback',@(src,evt)FontSize(src,evt,9))
    uimenu('Parent',mnufontsize,'Label','10',...
        'Callback',@(src,evt)FontSize(src,evt,10))
    uimenu('Parent',mnufontsize,'Label','12',...
        'Callback',@(src,evt)FontSize(src,evt,12))
    uimenu('Parent',mnufontsize,'Label','14',...
        'Callback',@(src,evt)FontSize(src,evt,14))
    uimenu('Parent',mnufontsize,'Label','16',...
        'Callback',@(src,evt)FontSize(src,evt,16))

    mnufontweight = uimenu('Parent',mnuTable,'Label','Font Weight');
    uimenu('Parent',mnufontweight,'Label','Normal',...
        'Callback',@(src,evt)FontWeight(src,evt,'normal'))
    uimenu('Parent',mnufontweight,'Label','Bold',...
        'Callback',@(src,evt)FontWeight(src,evt,'bold'))

    mnufontcolor = uimenu('Parent',mnuTable,'Label','Font Color');
    uimenu(mnufontcolor,'Label','Black','ForegroundColor','k',...
        'Callback',@(src,evt)FontColor(src,gco,'k'));
    uimenu(mnufontcolor,'Label','Red','ForegroundColor','r',...
        'Callback',@(src,evt)FontColor(src,gco,'r'));
    uimenu(mnufontcolor,'Label','Green','ForegroundColor',[0,0.75,0],...
        'Callback',@(src,evt)FontColor(src,gco,[0,0.75,0]));
    uimenu(mnufontcolor,'Label','Blue','ForegroundColor','b',...
        'Callback',@(src,evt)FontColor(src,gco,'b'));
    uimenu(mnufontcolor,'Label','Cyan','ForegroundColor','c',...
        'Callback',@(src,evt)FontColor(src,gco,'c'));
    uimenu(mnufontcolor,'Label','Magenta','ForegroundColor','m',...
        'Callback',@(src,evt)FontColor(src,gco,'m'));
    uimenu(mnufontcolor,'Label','Yellow','ForegroundColor','y',...
        'Callback',@(src,evt)FontColor(src,gco,'y'));
    uimenu(mnufontcolor,'Label','Custom','ForegroundColor','k',...
        'Callback',@(src,evt)FontColor(src,gco,uisetcolor));

    uimenu('Parent',mnuTable,'Label','Font...','Callback',@ModifyFont)
    
    mnuAlignment = uimenu('Parent',mnuTable,'Label','Alignment');
    mnuHoriz = uimenu('Parent',mnuAlignment,'Label','Horizontal');
    uimenu('Parent',mnuHoriz,'Label','Left',...
        'Callback',@(src,evt)HorizAlign(src,evt,'left'))
    uimenu('Parent',mnuHoriz,'Label','Center',...
        'Callback',@(src,evt)HorizAlign(src,evt,'center'))
    uimenu('Parent',mnuHoriz,'Label','Right',...
        'Callback',@(src,evt)HorizAlign(src,evt,'right'))
    
    mnuVert = uimenu('Parent',mnuAlignment,'Label','Vertical');
    uimenu('Parent',mnuVert,'Label','Top',...
        'Callback',@(src,evt)VertAlign(src,evt,'top'))
    uimenu('Parent',mnuVert,'Label','Cap',...
        'Callback',@(src,evt)VertAlign(src,evt,'cap'))
    uimenu('Parent',mnuVert,'Label','Middle',...
        'Callback',@(src,evt)VertAlign(src,evt,'middle'))
    uimenu('Parent',mnuVert,'Label','Baseline',...
        'Callback',@(src,evt)VertAlign(src,evt,'baseline'))
    uimenu('Parent',mnuVert,'Label','Bottom',...
        'Callback',@(src,evt)VertAlign(src,evt,'bottom'))
    
    uimenu('Parent',mnuTable,'Label','All...','CallBack',@FormatTable)
    
    copyobj(mnufontsize,[mnuRow,mnuCell,mnuCol]);    
    copyobj(mnufontweight,[mnuRow,mnuCell,mnuCol]);
    copyobj(mnufontcolor,[mnuRow,mnuCell,mnuCol]);
    
    uimenu('Parent',mnuRow,'Label','Font...','Callback',@ModifyFont)
    uimenu('Parent',mnuCell,'Label','Font...','Callback',@ModifyFont)
    uimenu('Parent',mnuCol,'Label','Font...','Callback',@ModifyFont)

    copyobj(mnuAlignment,[mnuRow,mnuCell,mnuCol]);

    uimenu('Parent',mnuRow,'Label','All...','CallBack',@FormatTable)
    uimenu('Parent',mnuCell,'Label','All...','CallBack',@FormatTable)
    uimenu('Parent',mnuCol,'Label','All...','CallBack',@FormatTable)
    
    mnuInsert = uimenu('Parent',mnu,'Label','Insert...','Separator','on');
        uimenu('Parent',mnuInsert,'Label','Row','Callback',@insertRow)
        uimenu('Parent',mnuInsert,'Label','Column','Callback',@insertColumn)

    mnuAppend = uimenu('Parent',mnu,'Label','Append...');
        uimenu('Parent',mnuAppend,'Label','Row','Callback',@appendRow)
        uimenu('Parent',mnuAppend,'Label','Column','Callback',@appendColumn)
        
    mnuDelete = uimenu('Parent',mnu,'Label','Delete...');
        uimenu('Parent',mnuDelete,'Label','Row','Callback',@deleteRow)
        uimenu('Parent',mnuDelete,'Label','Column','Callback',@deleteColumn)
        uimenu('Parent',mnuDelete,'Label','Table','Callback',@DeleteTable,...
            'Separator','on')

    uimenu('Parent',mnu,'Label','Resize Now','Callback',@AutoFitTableNow,...
        'Separator','on')
    hAutoEnable = uimenu('Parent',mnu,'Label','Enable Auto-Size',...
        'Checked','off','Callback',@AutoSizeEnable);
    
    %% Auto-size table
    if sum(width) == 0 || sum(height) == 0
        %Autoscale row height and column width
        [rowHeight,colWidth] = deal(zeros(size(tableData)));
        for j=1:nrows
            for k=1:ncols                
                if ischar(tableData{j,k})
                    str = tableData{j,k};
                elseif isnumeric(tableData{j,k})
                    if ~isempty(tableData{j,k})
                        str = num2str(tableData{j,k});
                    else
                        str = '-';
                    end
                else
                    %unsupported value type
                    str = '??';
                end
                htest = annotation('textbox',[0.1,0.9,0,0],...
                    'visible','off',...
                    'FitBoxtoText','on',...
                    'VerticalAlignment','middle',...
                    'string',str,...
                    varargin{:});
                p = get(htest,'Position');
                delete(htest)
                rowHeight(j,k) = p(4);
                colWidth(j,k) = p(3);
            end
        end
        for k=1:ncols
            width(k) = max(colWidth(:,k));
        end
        for j=1:nrows
            height(j) = max(rowHeight(j,:));
        end
    end
    
    %% Create the outer bounding box
    hbox = annotation('textbox',...
        [left, top-sum(height(:)), sum(width(:)),sum(height(:))],...
        'linewidth',1,...
        'BackgroundColor','k',...
        'DeleteFcn',@TableCleanup,...
        'Visible','off');
    set(hbox,'units','pixels')
    p = get(hbox,'position');
    boxweight = 1;
    p = p + [-1,-1,2,2] * boxweight;%add 1 pixel margin to box size
    set(hbox,'position',p)
    set(hbox,'units','normalized','Visible','on')
    
    T = top;
    L = left;

    %% Create final table
    for j = 1:nrows
        T = T - height(j);
        for k = 1:ncols
            h(j,k) = annotation('textbox',...
                'position',[L,T,width(k),height(j)],...
                'FontName','Arial',...
                'BackgroundColor','w',...
                'VerticalAlignment','middle',...
                'string',tableData{j,k},...
                'UIContextMenu',mnu,...
                varargin{:});
            L = L + width(k);
        end
        L = left;
    end
    ud.handles = h;
    ud.hbox = hbox;
    ud.autosize = 0;
    ud.boxweight = 1;
    ud.boxTop = top;
    ud.boxLeft = left;
    set([h(:);hbox],'UserData',ud)%store handles in each cell for future reference
    AutoFitTable(ud.handles,ud.hbox)    
    ud.listener = addlistener(gcf,'Position',...
        'PostSet',@(src,evt)AutoFitTableListener(ud.hbox,src,evt));
    ud.autosize = 1;
    set([h(:);hbox],'UserData',ud)%store settings in each cell for future reference
    set(hAutoEnable,'Checked','on')
    set(hfig,'Pointer','arrow')
    
end
%% ==== Callback Functions ================================================
function DeleteTable(~,~)
    ud = get(gco,'UserData');
    delete(ud.handles)
    delete(ud.hbox)
end
function FontSize(hmnu,~,fs)
    myhandle = gco;
    ud = get(myhandle,'UserData');
    caller = get(get(get(hmnu,'Parent'),'Parent'),'Tag');
    switch caller
        case 'Table'
            set(ud.handles,'fontsize',fs)
        case 'Cell'
            set(myhandle,'fontsize',fs)
        case 'Row'
            [j,~] = find(ud.handles == myhandle);
            set(ud.handles(j,:),'fontsize',fs)            
        case 'Col'            
            [~,k] = find(ud.handles == myhandle);
            set(ud.handles(:,k),'fontsize',fs)            
    end
    if ud.autosize == 1
        AutoFitTable(ud.handles,ud.hbox)
    end    
end
function ModifyFont(hmnu,~)
    myhandle = gco;
    ud = get(myhandle,'UserData');    
    caller =  get(get(hmnu,'Parent'),'Tag');
    switch caller
        case 'Table'
            F = uisetfont(myhandle);
            set(ud.handles,F)            
        case 'Cell'
            F = uisetfont(myhandle);
            set(myhandle,F)
        case 'Row'
            [j,~] = find(ud.handles == myhandle);
            F = uisetfont(ud.handles(j,1));
            set(ud.handles(j,:),F)
        case 'Col'            
            [~,k] = find(ud.handles == myhandle);
            F = uisetfont(ud.handles(1,k));
            set(ud.handles(:,k),F)            
    end
    
    if ud.autosize == 1
        AutoFitTable(ud.handles,ud.hbox)
    end
end
function MoveTable(~,~)
    ud = get(gco,'UserData');
    h = ud.handles(:);
    h(end+1) = ud.hbox;
    set(h,'Visible','off')
    myhappysound
    [x,y] = ginput(1);
    [left,top] = mydsxy2figxy(x,y);
    
    dx = ud.boxLeft - left;
    dy = ud.boxTop - top;

    for j=1:numel(h)
        p = get(h(j),'Position');
        p(1) = p(1) - dx;
        p(2) = p(2) - dy;
        set(h(j),'Position',p);
    end
    ud.boxLeft = left;
    ud.boxTop = top;
    
    set(h,'Visible','on','UserData',ud)
end
function EditCell(~,~)
    myhandle = gco;
    ud = get(myhandle,'UserData');
    [nrows,ncols] = size(ud.handles);
    d = cell(nrows,ncols);
    for j=1:nrows
        for k=1:ncols
            d{j,k} = get(ud.handles(j,k),'String');
        end
    end
    [j,k] = find(myhandle == ud.handles);
    d = OverlayTableEdit(d,[j,k]);
    if isempty(d)
        return
    end
    for j=1:nrows
        for k=1:ncols
            set(ud.handles(j,k),'String',d{j,k});
        end
    end
    if ud.autosize == 1
        AutoFitTable(ud.handles,ud.hbox)
    end    
end
function FormatTable(hmnu,~)
    myhandle = gco;
    ud = get(myhandle,'UserData');    
    caller =  get(get(hmnu,'Parent'),'Tag');
    switch caller
        case 'Table'
            inspect(ud.handles(:))
        case 'Cell'
            inspect(myhandle)
        case 'Row'
            [j,~] = find(ud.handles == myhandle);
            inspect(ud.handles(j,:))
        case 'Col'            
            [~,k] = find(ud.handles == myhandle);
            inspect(ud.handles(:,k))
    end
end
function FormatBox(~,~)
    ud = get(gco,'UserData');
    inspect(ud.hbox)
end
function AutoFitTableNow(~,~)
    ud = get(gco,'UserData');
    AutoFitTable(ud.handles,ud.hbox)
end
function AutoFitTableListener(hbox,~,~)
    ud = get(hbox,'UserData');
    AutoFitTable(ud.handles,hbox);
end
function AutoFitTable(h,hbox)
    set([h(:);hbox],'Visible','off')
    [rowHeight,colWidth] = deal(zeros(size(h)));
    [nrows,ncols] = size(h);
    for j=1:nrows
        for k=1:ncols
            set(h(j,k),'FitBoxtoText','on')
            p = get(h(j,k),'Position');
            set(h(j,k),'FitBoxtoText','off')
            rowHeight(j,k) = p(4);
            colWidth(j,k) = p(3);
        end
    end
    
    width = nan(1,ncols);
    for k=1:ncols
        width(k) = max(colWidth(:,k));
    end
    
    height = nan(1,nrows);
    for j=1:nrows
        height(j) = max(rowHeight(j,:));
    end
    
    ud = get(h(1),'UserData');
    left = ud.boxLeft;
    top = ud.boxTop;
    
    %bounding box
    set(hbox,'Position',[left, top-sum(height(:)), sum(width(:)),sum(height(:))]);
    set(hbox,'units','pixels')
    p = get(hbox,'position');
%     boxweight = 1;
    p = p + [-1,-1,2,2] * ud.boxweight;%add pixel margin to box size
    set(hbox,'position',p)
    set(hbox,'units','normalized')
    
    T = top;
    L = left;
    for j = 1:nrows
        T = T - height(j);
        for k = 1:ncols
            set(h(j,k),'position',[L,T,width(k),height(j)])
            L = L + width(k);
        end
        L = left;
    end

    set([h(:);hbox],'Visible','on')
end
function AutoSizeEnable(hdl,~)
    if strcmp(get(hdl,'Checked'),'on')
        set(hdl,'Checked','off')
    else
        set(hdl,'Checked','on')
    end
    if strcmp(get(hdl,'Checked'),'on')
        %enable
        ud = get(gco,'UserData');
        AutoFitTable(ud.handles,ud.hbox)    
        ud.listener = addlistener(gcf,'Position',...
            'PostSet',@(src,evt)AutoFitTableListener(ud.hbox,src,evt));
        ud.autosize = 1;
    else
        %disable
        ud = get(gco,'UserData');
        ud = get(ud.hbox,'UserData');
        delete(ud.listener)
        ud.listener = [];
        ud.autosize = 0;
    end
    set(ud.hbox,'UserData',ud)
    set(ud.handles,'UserData',ud)
end
function deleteRow(~,~)
    myhandle = gco;
    ud = get(myhandle,'UserData');
    h = ud.handles;
    [j,~] = find(h == myhandle);
    delete(h(j,:));
    h(j,:) = [];
    ud.handles = h;
    set(ud.handles,'UserData',ud)
    set(ud.hbox,'UserData',ud)
    AutoFitTable(ud.handles,ud.hbox);
end
function deleteColumn(~,~)
    myhandle = gco;
    ud = get(myhandle,'UserData');
    h = ud.handles;
    [~,k] = find(h == myhandle);
    delete(h(:,k));
    h(:,k) = [];
    ud.handles = h;
    set(ud.handles,'UserData',ud)
    set(ud.hbox,'UserData',ud)
    AutoFitTable(ud.handles,ud.hbox);
end
function insertColumn(~,~)
    myhandle = gco;
    ud = get(myhandle,'UserData');
    h = ud.handles;
    [~,k] = find(h == myhandle);
    h(:,end+1) = nan;
    for m=size(h,2):-1:k
        if m == 1
            break
        end
        h(:,m) = h(:,m-1);
    end
    h(:,k) = nan;
    for m=1:size(h,1)
        s = get(h(m,k+1));
        s = rmfield(s,'Annotation');
        s = rmfield(s,'BeingDeleted');
        s = rmfield(s,'Type');
        f = fieldnames(s);
        h(m,k) = annotation('textbox','Position',s.Position);
        for p=1:numel(f)
            try
                set(h(m,k),f{p},s.(f{p}))
            catch
            end
        end
        set(h(m,k),'string','-')
    end  
    ud.handles = h;
    set(ud.handles,'UserData',ud)
    AutoFitTable(ud.handles,ud.hbox)
end
function insertRow(~,~)
    myhandle = gco;
    ud = get(myhandle,'UserData');
    h = ud.handles;
    [j,~] = find(h == myhandle);
    h(end+1,:) = nan;
    for m=size(h,1):-1:j
        if m == 1
            break
        end
        h(m,:) = h(m-1,:);
    end
    h(j,:) = nan;
    for m=1:size(h,2)
        s = get(h(j+1,m));
        s = rmfield(s,'Annotation');
        s = rmfield(s,'BeingDeleted');
        s = rmfield(s,'Type');
        f = fieldnames(s);
        h(j,m) = annotation('textbox','Position',s.Position);
        for p=1:numel(f)
            try
                set(h(j,m),f{p},s.(f{p}))
            catch
            end
        end
        set(h(j,m),'string','-')
    end  
    ud.handles = h;
    set(ud.handles,'UserData',ud)
    AutoFitTable(ud.handles,ud.hbox)
end
function appendRow(~,~)
    myhandle = gco;
    ud = get(myhandle,'UserData');
    h = ud.handles;
    [j,~] = find(h == myhandle);
    h(end+1,:) = nan;
    j = j + 1;
    for m=size(h,1):-1:j
        if m == 1
            break
        end
        h(m,:) = h(m-1,:);
    end
    h(j,:) = nan;
    for m=1:size(h,2)
        s = get(h(j-1,m));
        s = rmfield(s,'Annotation');
        s = rmfield(s,'BeingDeleted');
        s = rmfield(s,'Type');
        f = fieldnames(s);
        h(j,m) = annotation('textbox','Position',s.Position);
        for p=1:numel(f)
            try
                set(h(j,m),f{p},s.(f{p}))
            catch
            end
        end
        set(h(j,m),'string','-')
    end  
    ud.handles = h;
    set(ud.handles,'UserData',ud)
    AutoFitTable(ud.handles,ud.hbox)
end
function appendColumn(~,~)
    myhandle = gco;
    ud = get(myhandle,'UserData');
    h = ud.handles;
    [~,k] = find(h == myhandle);
    h(:,end+1) = nan;
    k = k + 1;
    for m=size(h,2):-1:k
        if m == 1
            break
        end
        h(:,m) = h(:,m-1);
    end
    h(:,k) = nan;
    for m=1:size(h,1)
        s = get(h(m,k-1));
        s = rmfield(s,'Annotation');
        s = rmfield(s,'BeingDeleted');
        s = rmfield(s,'Type');
        f = fieldnames(s);
        h(m,k) = annotation('textbox','Position',s.Position);
        for p=1:numel(f)
            try
                set(h(m,k),f{p},s.(f{p}))
            catch
            end
        end
        set(h(m,k),'string','-')
    end  
    ud.handles = h;
    set(ud.handles,'UserData',ud)
    AutoFitTable(ud.handles,ud.hbox)

end
function FontColor(hmnu,~,c)
    myhandle = gco;
    ud = get(myhandle,'UserData');
    caller = get(get(get(hmnu,'Parent'),'Parent'),'Tag');
    switch caller
        case 'Table'
            set(ud.handles,'Color',c)
        case 'Cell'
            set(myhandle,'Color',c)
        case 'Row'
            [j,~] = find(ud.handles == myhandle);
            set(ud.handles(j,:),'Color',c)            
        case 'Col'            
            [~,k] = find(ud.handles == myhandle);
            set(ud.handles(:,k),'Color',c)            
    end
    if ud.autosize == 1
        AutoFitTable(ud.handles,ud.hbox)
    end    
end
function FontWeight(hmnu,~,wt)
    myhandle = gco;
    ud = get(myhandle,'UserData');
    caller = get(get(get(hmnu,'Parent'),'Parent'),'Tag');
    switch caller
        case 'Table'
            set(ud.handles,'FontWeight',wt)
        case 'Cell'
            set(myhandle,'FontWeight',wt)
        case 'Row'
            [j,~] = find(ud.handles == myhandle);
            set(ud.handles(j,:),'FontWeight',wt)            
        case 'Col'            
            [~,k] = find(ud.handles == myhandle);
            set(ud.handles(:,k),'FontWeight',wt)            
    end
    if ud.autosize == 1
        AutoFitTable(ud.handles,ud.hbox)
    end    
end
function BoxBorder(~,~,W)
    ud = get(gco,'UserData');
    ud.boxweight = W;
    set(ud.handles,'UserData',ud)
    AutoFitTable(ud.handles,ud.hbox)
end
function myhappysound(n,Fs)
%happysound     A calmer alternative to system beep
    if ~ismember('n',who)
        n = 1500;
    end
    if ~ismember('Fs',who)
        Fs = 1500;
    end

    x = 1:2:n;
    y = sin(x).*exp(-x/(0.3*n));

    soundsc(y,Fs);
end
function TableCleanup(h,~)
    ud = get(h,'UserData');
    if ud.autosize == 1
        %disable listener
        delete(ud.listener)
    end
end
function VertAlign(hmnu,~,align)
    myhandle = gco;
    ud = get(myhandle,'UserData');
    caller =  get(get(get(get(hmnu,'Parent'),'parent'),'parent'),'tag');
    switch caller
        case 'Table'
            set(ud.handles,'VerticalAlignment',align)
        case 'Cell'
            set(myhandle,'VerticalAlignment',align)
        case 'Row'
            [j,~] = find(ud.handles == myhandle);
            set(ud.handles(j,:),'VerticalAlignment',align)            
        case 'Col'            
            [~,k] = find(ud.handles == myhandle);
            set(ud.handles(:,k),'VerticalAlignment',align)            
    end
    if ud.autosize == 1
        AutoFitTable(ud.handles,ud.hbox)
    end    

end
function HorizAlign(hmnu,~,align)
    myhandle = gco;
    ud = get(myhandle,'UserData');
    caller =  get(get(get(get(hmnu,'Parent'),'parent'),'parent'),'tag');
    switch caller
        case 'Table'
            set(ud.handles,'HorizontalAlignment',align)
        case 'Cell'
            set(myhandle,'HorizontalAlignment',align)
        case 'Row'
            [j,~] = find(ud.handles == myhandle);
            set(ud.handles(j,:),'HorizontalAlignment',align)            
        case 'Col'            
            [~,k] = find(ud.handles == myhandle);
            set(ud.handles(:,k),'HorizontalAlignment',align)            
    end
    if ud.autosize == 1
        AutoFitTable(ud.handles,ud.hbox)
    end    
end
function varargout = mydsxy2figxy(varargin)
    % dsxy2figxy -- Transform point or position from axis to figure coords
    % Transforms [axx axy] or [xypos] from axes hAx (data) coords into coords
    % wrt GCF for placing annotation objects that use figure coords into data
    % space. The annotation objects this can be used for are
    %    arrow, doublearrow, textarrow
    %    ellipses (coordinates must be transformed to [x, y, width, height])
    % Note that line, text, and rectangle anno objects already are placed
    % on a plot using axes coordinates and must be located within an axes.
    % Usage: Compute a position and apply to an annotation, e.g.,
    %   [axx axy] = ginput(2);
    %   [figx figy] = getaxannopos(gca, axx, axy);
    %   har = annotation('textarrow',figx,figy);
    %   set(har,'String',['(' num2str(axx(2)) ',' num2str(axy(2)) ')'])
    %modified by JVC to correctly treat logarithmic axis scales
    % Obtain arguments (only limited argument checking is performed).
    % Determine if axes handle is specified
    if length(varargin{1})== 1 && ishandle(varargin{1}) && ...
      strcmp(get(varargin{1},'type'),'axes')	
        hAx = varargin{1};
        varargin = varargin(2:end);
    else
        hAx = gca;
    end;
    % Parse either a position vector or two 2-D point tuples
    if length(varargin)==1	% Must be a 4-element POS vector
        pos = varargin{1};
    else
        [x,y] = deal(varargin{:});  % Two tuples (start & end points)
    end
    % Get limits
    axun = get(hAx,'Units');
    set(hAx,'Units','normalized');  % Need normaized units to do the xform
    axpos = get(hAx,'Position');    %left,bottom, width, height
    axlim = axis(hAx);              % Get the axis limits [xlim ylim (zlim)]
    axwidth = diff(axlim(1:2));
    axheight = diff(axlim(3:4));

    %Transform data from figure space to data space
    if exist('x','var')     % Transform a and return pair of points
        if strcmp(get(hAx,'xscale'),'linear')
            if strcmp(get(hAx,'xdir'),'reverse') 
                varargout{1} = (axlim(2) - x)*axpos(3)/axwidth + axpos(1) ; 
            else
                % ((x - xmin) * width) / (width + left)
                varargout{1} = (x - axlim(1))*axpos(3)/axwidth + axpos(1);
            end
        else
            varargout{1} = (log10(x/axlim(1)) / log10(axlim(2)/axlim(1))) * axpos(3) + axpos(1);
        end        
        if strcmp(get(hAx,'yscale'),'linear')
            varargout{2} = (y-axlim(3))*axpos(4)/axheight + axpos(2);
        else
            varargout{2} = (log10(y/axlim(3)) / log10(axlim(4)/axlim(3))) * axpos(4) + axpos(2);
        end
    else                    % Transform and return a position rectangle
        pos(1) = (pos(1)-axlim(1))/axwidth*axpos(3) + axpos(1);
        pos(2) = (pos(2)-axlim(3))/axheight*axpos(4) + axpos(2);
        pos(3) = pos(3)*axpos(3)/axwidth;
        pos(4) = pos(4)*axpos(4)/axheight;
        varargout{1} = pos;
    end
    % Restore axes units
    set(hAx,'Units',axun)
end