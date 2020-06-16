function ClickSamples_TrainClassifiers
% Last Update 04 Oct 2017
    global fScreen scrsz FigPosition msgPosition magFactor handles
    global optMsg
    
    
    warning off;
    Rheinard = false;
    if Rheinard;  strClassDef = 'MarkersRheinard';
    else; strClassDef = 'Markers'; end
    slash=filesep;
    optMsg.Interpreter = 'tex';
    optMsg.WindowStyle = 'normal';
    magFactor = 400;
    fScreen=5; scrsz = get(groot,'ScreenSize'); 
    FigPosition=[1 1 0 0];
    msgPosition=[100 scrsz(4)/5];
    
    imgDir=uigetdir(['C:' slash 'DATI' slash 'Elab_Imgs_Mediche' slash 'MIA' slash 'immagini_MIA'], 'Select folder of training samples');
    dirSaveClassifiers=['.' slash 'TrainedClassifiers'];
    
    
    if ~exist(dirSaveClassifiers,'dir'); mkdir(dirSaveClassifiers); end
    
    imgList=[dir([imgDir slash '*.tif']); dir([imgDir slash '*.jpg']); dir([imgDir slash '*.png'])];
    info=parseName(imgList(1,1).name);
    %% enter the image format and the marker name
    presetmarkerColor=info.markerColor; 
    ind=strfind(presetmarkerColor,'-');
        if numel(ind)>0 
            baseColor=presetmarkerColor(ind+1:end);
            markerColor=presetmarkerColor(1:ind-1);
            disp(['Base marker Color =  ' baseColor]);
            disp(['Marker Color ' markerColor]);
        else
            markerColor=presetmarkerColor;
            baseColor='';
            disp(['No Base Color']);
            disp(['Marker Color ' markerColor]);
        end
%     if numel(ind)>0 
%         baseColor=presetmarkerColor(ind+1:end);
%         markerColor=presetmarkerColor(1:ind-1);
%         disp(['Base marker Color =  ' baseColor]);
%         disp(['Marker Color ' markerColor]);
%         if exist([dirSaveClassifiers slash 'Mdltree_BasicColor_' baseColor '.mat'],'file')
%             disp(['Basic color classifier ' baseColor ' already exist']);
%             basicCol=input(['Train novel basic color classifier? (Y/N)' newline],'s');
%             if (strcmpi(basicCol,'Y')); trainBasicColorTree(dirSaveClassifiers, baseColor,slash); end
%         else
%             if exist([dirSaveClassifiers slash 'DataColor_' baseColor],'dir')
%                 disp(['Basic color data already existing. Basic classifier will be updated with new points' newline]);
%             end
%             trainBasicColorTree(dirSaveClassifiers, baseColor,slash);     
%         end
%     else
%         markerColor=presetmarkerColor;
%         baseColor='';
%         disp(['No Base Color']);
%         disp(['Marker Color ' markerColor]);
%     end
    
    nameDirPts=['DataColor_' markerColor];
    dirSavePts=[imgDir slash  nameDirPts ];
    disp(['Training points to learn color ' markerColor ' will be saved in folder: ' '.' slash   nameDirPts newline ]);
    if ~exist(dirSavePts,'dir'); mkdir(dirSavePts); 
        classList=dir([dirSaveClassifiers slash '*' markerColor '.mat']);
        if (numel(classList)==4)
            ansClass=input(['Classifiers already trained from unknown trained points, overwrite them (Y) or stop (N)?' newline],'s');
            if strcmpi(ansClass, 'N')
                disp(['Ending training data collection and classifiers training']);
                return; end
        end
    else
        disp([nameDirPts ' directory already exist: samples selection will add more training points!' newline]);
    end
    
    disp('List of sample images:')
    for numI=1:size(imgList,1); disp(imgList(numI,1).name); end
  
    %Nhood=8; 
    for numI=1:size(imgList,1)
        imgName=imgList(numI,1).name;
        pos=strfind(imgName,'.');
        info=parseName(imgName);

        baseName=imgName(1:pos-1);
        %% load the positions of points already clicked on this image 
        %% to show their number and eventually collect again their color     
        if exist([dirSavePts slash  baseName '_pts.mat'],'file') %#ok<ALIGN>
            load([dirSavePts slash  baseName '_pts.mat'],'ptsOn','ptsOff','ptsCOff');
        else; ptsOn=[]; ptsOff=[]; ptsCOff=[];  end

        answer=input(['img to process: ->' baseName newline...
            'already selected training MARKER points=' num2str(size(ptsOn,1)) newline ...
            'already selected training NOT-marker points=' num2str(size(ptsOff,1)) newline...
            'already selected training CRITICAL NOT-marker points=' num2str(size(ptsCOff,1)) newline...
            'PROCESS THIS IMAGE (Y) or continue with next (N)? (Y/N)' newline ],'s');
        if  strcmpi(answer,'N')
            answerStop=input(['continue processing?'...
                ' (Y for continuing /N for stopping)' newline],'s');
            ptsOn=[]; ptsOff=[]; ptsCOff=[];
            if strcmpi(answerStop,'N'); break; else; continue; end
        else
            if strcmpi(info.ext,'mat')  %#ok<*ALIGN>
                load([imgDir slash imgName],'IRGB');
            else; IRGB=imread([imgDir slash imgName]); end
            %% load the positions of points already clicked on this image 
            %% to collect again their color     
            IRGB=uint8(IRGB(:,:,1:3));
            scrsz = get(groot,'ScreenSize'); 
            imgShow=IRGB;
            if size(ptsOn,1)>0
                ind=sub2ind([size(IRGB,1),size(IRGB,2)],ptsOn(:,2),ptsOn(:,1));
                bin=false(size(IRGB,1),size(IRGB,2));
                bin(ind)=true; bin = bwperim(bin);
                imgShow(cat(3,bin,bin,bin)) = 0;
                imgShow(cat(3,bin,false(size(bin)),false(size(bin)))) = 255;
                clear ind;
            end
            if size(ptsOff,1)>0
                ind=sub2ind([size(IRGB,1),size(IRGB,2)],ptsOff(:,2),ptsOff(:,1));
                bin=false(size(IRGB,1),size(IRGB,2));
                bin(ind)=true; bin =  bwperim(bin);
                imgShow(cat(3,bin,bin,bin)) = 0;
                imgShow(cat(3,false(size(bin)),false(size(bin)),bin)) = 255;
                clear ind;
            end
            if size(ptsCOff,1)>0
                ind=sub2ind([size(IRGB,1),size(IRGB,2)],ptsCOff(:,2),ptsCOff(:,1));
                bin=false(size(IRGB,1),size(IRGB,2));
                bin(ind)=true; bin =bwperim(bin);
                imgShow(cat(3,bin,bin,bin)) = 0;
                imgShow(cat(3,false(size(bin)),bin, false(size(bin)))) = 255;
                clear ind;
            end
            %% SELECT centers of areas where to select ON-marker pixels
            close all
            msg=['SELECT centers of areas where to select training pixels (double-click or Enter to end insertion)'];
            handles{end+1}=msgbox(msg, 'Title', 'none');
            h=handles{end}; h.Position(1:2)=msgPosition;
            fig=figure('Name', 'SELECT centers of areas where to select training pixels', ...
            'units','normalized', ...
            'OuterPosition', FigPosition); hold on; imshow(imgShow, ...
                    'InitialMagnification', magFactor);
            [Xareas , Yareas]= getpts; Xareas=uint32(Xareas);Yareas=uint32(Yareas);
            handles{end+1}=msgbox([num2str(numel(Xareas)) ' areas selected'], 'Title', 'none');
            h=handles{end}; h.Position(1:2)=[msgPosition(1) msgPosition(2)-100];
            %if ((numel(Xareas)>0) && (numel(Yareas)>0)) 
            close(fig);
            for i=1: size(Xareas,1)
                xc=Xareas(i); yc=Yareas(i);
                xs=max(xc-(scrsz(3)/fScreen),1); xe=min(xc+(scrsz(3)/fScreen)-1,size(IRGB,2));
                ys=max(yc-(scrsz(4)/fScreen),1); ye=min(yc+(scrsz(4)/fScreen-1),size(IRGB,1));

                figTitle = ['draw lines containing marker pixels'];
                msg = ['From the shown figure draw polygons containing' newline ...
                'marker pixels \rm'];

                resPoly = pointsInPoly( imgShow(ys:ye,xs:xe,:), figTitle, msg);
                removeDialogs()
                if numel(resPoly.points)>0
                    X=resPoly.points(:,1); Y=resPoly.points(:,2);
                    if ((numel(X)>0) && (numel(Y)>0)) 
                        newpts=[uint32(X)+xs uint32(Y)+ys];
                        indDel=find(newpts(:,1)==0 | newpts(:,1)>size(IRGB,2) |...
                        newpts(:,2)==0 | newpts(:,2)>size(IRGB,1));
                        if numel(indDel)>0; newpts(indDel,:)=[]; clear indDel; end
                        if size(newpts,1)>0
                            % aggiorno imgShow con i nuovi punti On
                            ind=sub2ind([size(IRGB,1),size(IRGB,2)],newpts(:,2),newpts(:,1));
                            bin=false(size(IRGB,1),size(IRGB,2));
                            bin(ind)=true; bin = bwperim(bin);
                            imgShow(cat(3,bin,bin,bin)) = 0;
                            imgShow(cat(3,bin,false(size(bin)),false(size(bin)))) = 255;
                            clear ind;
                        end
                        ptsOn=[ptsOn;newpts]; clear newpts;
                        removeDialogs()
                    end
                    clear X Y;
                end
                ptsOn=unique(ptsOn,'rows');                
                % save data up to now, just in case something goes wrong later
                save([dirSavePts slash baseName '_pts.mat'],'ptsOn','ptsOff','ptsCOff');

                %% SELECT centers of areas where to select OFF-NOT marker pixels
                figTitle = ['draw polygons areas containing NOT-marker pixels'];
                msg = ['From the shown figure draw polygons containing' newline ...
                'NO marker pixels \rm' newline ...
                '(after drawing polygon double-click closes it, ending insertion' newline ...
                'one-click to avoid drawing polygon' newline ...
                'one double-click lets you choose to click on each not-marker pixels)'];

                resPoly = pointsInPoly( imgShow(ys:ye,xs:xe,:), figTitle, msg);
                removeDialogs()
                if numel(resPoly.points)>0
                    X=resPoly.points(:,1); Y=resPoly.points(:,2);
                    if ((numel(X)>0) && (numel(Y)>0)) 
                        newpts=[uint32(X)+xs uint32(Y)+ys];
                        indDel=find(newpts(:,1)==0 | newpts(:,1)>size(IRGB,2) |...
                        newpts(:,2)==0 | newpts(:,2)>size(IRGB,1));
                        if numel(indDel)>0; newpts(indDel,:)=[]; clear indDel; end
                        if size(newpts,1)>0
                            % aggiorno imgShow con i nuovi punti On
                            ind=sub2ind([size(IRGB,1),size(IRGB,2)],newpts(:,2),newpts(:,1));
                            bin=false(size(IRGB,1),size(IRGB,2));
                            bin(ind)=true; bin = bwperim(bin);
                            imgShow(cat(3,bin,bin,bin)) = 0;
                            imgShow(cat(3,false(size(bin)),false(size(bin)),bin)) = 255;
                            clear ind;
                        end
                        ptsOff=[ptsOff;newpts]; clear newpts;
                        removeDialogs()
                    end
                    clear X Y;
                end
                ptsOff=unique(ptsOff,'rows');         
                save([dirSavePts slash baseName '_pts.mat'],'ptsOn','ptsOff','ptsCOff');

                figTitle = ['draw polygons areas containing CRITICAL NOT-marker pixels'];
                msg = ['From the shown figure draw polygons containing' newline ...
                'NO marker pixels \rm' newline ...
                '(after drawing polygon double-click closes it, ending insertion' newline ...
                'one-click to avoid drawing polygon' newline ...
                'one double-click lets you choose to click on each not-marker pixels)'];

                resPoly = pointsInPoly( imgShow(ys:ye,xs:xe,:), figTitle, msg);
                removeDialogs()
                if numel(resPoly.points)>0
                    X=resPoly.points(:,1); Y=resPoly.points(:,2);
                    if ((numel(X)>0) && (numel(Y)>0)) 
                        newpts=[uint32(X)+xs uint32(Y)+ys];
                        indDel=find(newpts(:,1)==0 | newpts(:,1)>size(IRGB,2) |...
                        newpts(:,2)==0 | newpts(:,2)>size(IRGB,1));
                        if numel(indDel)>0; newpts(indDel,:)=[]; clear indDel; end
                        if size(newpts,1)>0
                            % aggiorno imgShow con i nuovi punti On
                            ind=sub2ind([size(IRGB,1),size(IRGB,2)],newpts(:,2),newpts(:,1));
                            bin=false(size(IRGB,1),size(IRGB,2));
                            bin(ind)=true; bin = bwperim(bin);
                            imgShow(cat(3,bin,bin,bin)) = 0;
                            imgShow(cat(3,false(size(bin)),bin,false(size(bin)))) = 255;
                            clear ind;
                        end
                        ptsCOff=[ptsCOff;newpts]; clear newpts;
                        removeDialogs();
                    end
                    clear X Y;
                    ptsOff=unique(ptsOff,'rows');  
                end
                save([dirSavePts slash baseName '_pts.mat'],'ptsOn','ptsOff','ptsCOff');
                clear xs ys xe ye xc yc; 
            end
            clear Xareas Yareas; 
            
%             ptsCriticalOff=unique(ptsCriticalOff,'rows');
            figure('Name','Collected Points'); imshow(imgShow)
            save([dirSavePts slash baseName '_pts.mat'],'ptsOn','ptsOff','ptsCOff');

            disp(['Processed Image: ->' baseName newline...
            'signed ptsMarkers=' num2str(size(ptsOn,1)) newline ...
            'signed ptsNOMarkers=' num2str(size(ptsOff,1)) newline ...
            'signed Critical ptsNOTMarkers=' num2str(size(ptsCOff,1))]);
            clear ptsOn ptsOff;
            answerStop=input('continue processing? (Y for continuing /N for stopping) ','s');
            if strcmpi(answerStop,'N'); break; end
            %end
            clear RegsF IRGB;
        end
    end

    disp('Collecting training data...');
      collectTrainingData24(imgDir,dirSavePts, dirSaveClassifiers,slash);
    load([dirSavePts slash 'dataColor24_' markerColor '.mat']);
    
    testD=[]; testLab=[];
    if size(ptsOnColors,1)>0
        testD=[testD; ptsOnColors(:,1:3)];
        testLab=[testLab; true(size(ptsOnColors,1),1)];
    end
    if size(ptsOffColors,1)>0
        testD=[testD; ptsOffColors(:,1:3)];
        testLab=[testLab; false(size(ptsOffColors,1),1)];
    end
    if size(ptsCOffColors,1)>0
        testD=[testD; ptsCOffColors(:,1:3)];
        testLab=[testLab; false(size(ptsCOffColors,1),1)];
    end
%     if size(testD,1)>0
%         disp([newline 'Test Basic Color Classifier on training data']);
%         testBasicColorClassifier(Mdltree,testD, testLab);
%     end
    
    answerLearn=input('Train Classifiers? Y/N ', 's');
    if strcmpi(answerLearn,'Y')
        dataAnalisys24Feat(ptsOnColors,ptsOffColors, ptsCOffColors, markerColor,dirSaveClassifiers,strClassDef,baseColor,slash);    
    else; disp('Saving Training set withouth Training the classifiers'); end
end


