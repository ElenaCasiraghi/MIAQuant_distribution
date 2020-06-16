function MIAQuant_Learn_TMANoRheinard(dirImgs,templates)
% Last Update 09 May 2019
% % Copyright: Elena Casiraghi

    global fScreen scrsz FigPosition msgPosition magFactor
    global optMsg
    warning off;
    clc;
    close all;
    optMsg.Interpreter = 'tex';
    optMsg.WindowStyle = 'normal';
    magFactor = 200;
    fScreen=10; scrsz = get(groot,'ScreenSize'); 
    FigPosition=[0 0  1 1];
    msgPosition=[100 scrsz(4)/2];
    
    warning off;
    strClassMarkers='Markers'; 
    
    if (nargin==0); dirImgs=uigetdir(...
            ['C:' filesep 'DATI' filesep 'Elab_Imgs_Mediche' filesep 'MIA' filesep 'immagini_MIA'],...
        'Select the img folder'); end %#ok<ALIGN>


    %% CREA LA LISTA DEI MARKERS (cell array templates)
    if (nargin<2)
        lineMarkers=input([newline '-------------------' newline 'Insert the '...
            '(space separated) marker Names (e.g. CD3 CD68 CD163) ' newline],'s');
        pos=strfind(lineMarkers,' ');
        templates={};
        oldPos=0;
        for i=1:numel(pos); templates{i,1}=lineMarkers(oldPos+1:pos(i)-1); oldPos=pos(i); end
        templates{end+1,1}=lineMarkers(oldPos+1:end);
    end
    disp(['DIRECTORY PATHNAME: ' dirImgs]);
    dirClassifiers=['.' filesep 'TrainedClassifiers'];
    dimLimitOut=8000; dimLimitIn=8000;  
    factorRed=input([newline '-------------------' newline 'If wanted insert the reduction factor'...
        newline 'e.g: 0.1 for reduction at 10% image size, 0.5 to halve the image size,... ' newline]);
    if numel(factorRed)==0; factorRed=1; end
    
    dirMasks=[dirImgs filesep 'Masks']; 
    
    methodRed='nearest';    
    thrArea=3;
    offset=11; 
    st11 = strel('disk',11); st3 = strel('disk',3);
    if ~exist(dirMasks,'dir'); mkdir(dirMasks); end
    disp(dirMasks);
    markersDir=[dirImgs filesep strClassMarkers];
    if ~exist(markersDir,'dir'); mkdir(markersDir); end
    
    nameDensity=[markersDir filesep 'MarkerDensityData.txt'];
    fidDensity = fopen(nameDensity,'w');
    
   
    %% FILE CONTENENTE DATI MARKER SEGMENTATION AND DENSITY ESTIMATION 
    %delete(gcp('nocreate')); parpool;
%     strTitle=['Img Name' sprintf('\t') 'TissueArea' sprintf('\t') 'MarkerArea' sprintf('\t') 'MarkerDensity' sprintf('\t')...
%         'Marker Area - Red Tissue' sprintf('\t') 'Red Tissue Area'  sprintf('\t') 'Marker Density w.r.t Red tissue' sprintf('\t') ...
%         'Marker Area - Yellow Tissue' sprintf('\t') 'Yellow Tissue Area' sprintf('\t') 'Marker Density w.r.t Yellow tissue' sprintf('\t') ...
%         'Marker Area - Green Tissue' sprintf('\t') 'Green Tissue Area' sprintf('\t') 'Marker Density w.r.t Green tissue'];
    
    strTitle=['Img Name' sprintf('\t') 'TissueArea' sprintf('\t') 'MarkerArea' sprintf('\t') 'MarkerDensity'];
   

    disp(strTitle);
    
    fprintf(fidDensity, '%s\n',strTitle); clear strTitle;
    
    %% SEGMENTO TUTTE LE TISSUE REGIONS e i manual landmarks
    %inputCorrect = input('Correct Marker later?','s');
    inputCorrect = 'N';
    interactive = false;
    fnsAll=[dir([dirImgs filesep '*_' templates{1} '_*.tif']);
                dir([dirImgs filesep '*_' templates{1} '_*.jpg']);
                dir([dirImgs filesep '*_' templates{1} '_*.png']);];
    for numTemp=2: numel(templates)
           tempMarker=templates{numTemp};
           fns=[dir([dirImgs filesep '*_' tempMarker '_*.tif']);
               dir([dirImgs filesep '*_' tempMarker '_*.jpg']);
               dir([dirImgs filesep '*_' tempMarker '_*.png'])];
           fnsAll=[fnsAll; fns];
    end
    
    
    baseNames = cell(numel(fnsAll),1);
    regAreas = NaN(numel(fnsAll),1);
    markerAreas = NaN(numel(fnsAll),1);
    densities = NaN(numel(fnsAll),1);
    for numI= 1:numel(fnsAll)
        fName=fnsAll(numI,1).name;
        info=parseName(fName);
        disp(['imgName=' info.patName ...
              ' - Marker=' info.markerName ' - Color=' info.markerColor]);
        baseName=[info.patName '_' info.markerName '_' info.markerColor];
        disp(baseName)
        if ~exist([dirMasks filesep baseName '_IRGB.mat'],'file') 
            if (factorRed~=1); I=imresize(imread([dirImgs filesep fName]),factorRed,methodRed);
            else; I= imread([dirImgs filesep fName]); end
            I = uint8(I(:,:,1:3));
            IRGB = I-I;
            for nc=1:3; IRGB(:,:,nc) = imgaussfilt(medfilt2(I(:,:,nc))); end
        else
            load([dirMasks filesep baseName '_IRGB.mat'],'IRGB'); 
            load([dirMasks filesep baseName '_IOrig.mat'],'I');
        end
        disp('Marker segmentation and density estimation After Region opening');

        extRegsName = [info.patName '_' info.markerName '_Regs.mat'];
        disp([num2str(numI) '->' baseName '<-']);
        
        if exist([dirMasks filesep extRegsName],'file')
            load([dirMasks filesep extRegsName],'Regs', 'binHoles', 'deposito');
            Regs = imresize(Regs, [size(IRGB,1), size(IRGB,2)], 'nearest');
            binHoles = imresize(binHoles, [size(IRGB,1), size(IRGB,2)], 'nearest');
            if exist('deposito','var');  deposito = imresize(deposito, [size(IRGB,1), size(IRGB,2)], 'nearest');
            else; deposito = false(size(Regs)); end
        else; Regs = ones(size(IRGB,1), size(IRGB,2)); 
            binHoles = false(size(Regs)); 
            deposito = false(size(Regs));   end
       % binHolesinImg = bwareaopen(mean(IRGB,3)<5,1000);
        newR = Regs;
        newR(binHoles) = 0;
        
%         regs = sort(unique(newR(:)));
%         if numel(regs)==2 % ho una sola regione
%             IS = drawMarkers(I, false(size(Regs)), Regs, 1, 5);
%             figure('Position', FigPosition); imshow(IS);
%            % answ = input('extend Reg? (Y/N)', 's');
%            answ = 'Y'; 
%            if ~strcmpi(answ,'N')
%                 R = Regs >0 & (~binHoles); facStd = -0.5;
%                 iR = double(IRGB(:,:,1)); meanR = mean(iR(~R)); stdR = std(iR(~R));
%                 iG = double(IRGB(:,:,2)); meanG = mean(iG(~R)); stdG = std(iG(~R));
%                 iB = double(IRGB(:,:,3)); meanB = mean(iB(~R)); stdB = std(iB(~R));
%                 imgR = (~binHoles) & ExtractNLargestRegions(imclose((iR < meanR+facStd*stdR) & ...
%                                 (iG < meanG+facStd*stdG) & ... 
%                                 (iB < meanB+facStd*stdB),st3),1);
%                 areaR = sum(uint8(imgR(:)));
%                 holes = bwareaopen(imfill(imgR, 'holes') & (~imgR), round(areaR/1000));
%                 regHoles = bwlabel(holes);
%                 meanI = mean(IRGB,3);
%                 stdOut = std(meanI(~R));
%                 for nR = 1: max(regHoles(:))
%                     stdR = std(meanI(regHoles==nR));
%                     if stdR>stdOut; holes(regHoles)=0; end
%                 end
%                 imgR = uint8(imfill(imgR, 'holes')) - uint8(holes);
%                 imgR = imgR*max(regs); % se era una unic regione rossa
%                                         % la rimetto rossa
%                                         % se era verde la rimetto verede
%                                         % se era blu la rimetto blu
%                 IS = drawMarkers(I, false(size(Regs)), uint8(imgR), 1, 5);
%                 imshow(IS);
%                 newR = imgR;
%                 
%                 extnewRegsName = [info.patName '_' info.markerName '_newR'];
%                 imwrite(newR*255/max(newR(:)),[dirMasks filesep  extnewRegsName '.jpg'])
%                 save([dirMasks filesep  extnewRegsName '.mat'],'newR');
%             end
%         end


%         img = imresize(IRGB, [1000 1000] );
%         reg = imresize(newR, [1000 1000] );
%         r = double(img(:,:,1)); g = double(img(:,:,2)); b = double(img(:,:,3));
%         rm = mean(r(reg>0));
%         gm = mean(g(reg>0));
%         bm = mean(b(reg>0));
%         disp(num2str([rm gm bm]))
%         rmin = min(r(reg>0)); rmax = max(r(reg>0));
%         gmin = min(g(reg>0)); gmax = max(g(reg>0));
%         bmin = min(b(reg>0)); bmax = max(b(reg>0));
%         figure; imshow(img);
%         disp(num2str([rmin gmin bmin]))
%         input('','s');
%         img = uint8(round(cat(3,100+55*(r-rmin)/(rmax-rmin), ...
%         100+55*(g-gmin)/double(gmax-gmin), ...
%         100+55*(b-bmin)/double(bmax-bmin))));
%         max(img(:))
%         figure; imshow(img);
%         
        if ~exist([markersDir filesep baseName '_markers.mat'],'file') %#ok<ALIGN>
            %% se una immagine ha nome colore= presetCol-addCol
            % presetCol è il colore più selettivo che permette di selezionare 
            % solo porzioni di regioni di marker, 
            % ma tali regioni vengono spesso sottosegmentate
            % addCol è un colore più generico che prende di più ma permette di ottenere
            % zone di marker meglio definite
            % quindi prendo le regioni di marker cercando zone con colore presetCol
            %% e poi uso le forme date dalla ricerca di zone di colore addCol
            presetmarkerColor=[];
            basemarkerColor=[];
            sz=size(newR);
            if numel(presetmarkerColor)==0 
                presetmarkerColor=info.markerColor; 
                disp(['Segment markers with color ' presetmarkerColor]);
                if contains(presetmarkerColor, 'globuli', 'IgnoreCase', true)
                    thrArea = 30;
                elseif contains(presetmarkerColor, 'W', 'IgnoreCase', true); thrArea = 3;
                else; thrArea = 16; end
            end
            ind=strfind(presetmarkerColor,'-');
            if numel(ind)>0 
                basemarkerColor=presetmarkerColor(ind+1:end);
                presetmarkerColor=presetmarkerColor(1:ind-1);
                disp(['discard most not marker by Base marker Color =  ' basemarkerColor]);
                disp(['then select markers with color ' presetmarkerColor]);  
            end
            
           
                stepCut(2)=uint32(ceil(double(sz(2))/double(dimLimitOut)));
                stepCut(1)=uint32(ceil(double(sz(1))/double(dimLimitOut)));
                taglioC=uint32(ceil(double(sz(2))/double(stepCut(2))));
                taglioR=uint32(ceil(double(sz(1))/double(stepCut(1))));
                markers= zeros(sz(1),sz(2));
                for i=uint32(1):uint32(stepCut(1))
                    for j=uint32(1):uint32(stepCut(2))
                        miny=max((i-1)*taglioR+1-offset,1);
                        maxy=min(i*taglioR+offset,sz(1));
                        minx=max((j-1)*taglioC+1-offset,1);
                        maxx=min(j*taglioC+offset,sz(2));
                        img=double(IRGB(miny:maxy,minx:maxx,:));  
                        reg=newR(miny:maxy,minx:maxx);
                        mark=par_trees_svm_knn24(img,reg,dimLimitIn,...
                                dirClassifiers, presetmarkerColor,basemarkerColor,thrArea,strClassMarkers,filesep);
                        clear img reg;
                        if (miny>1); miny=miny+offset; mark=mark(1+offset:end,:); end
                        if (maxy<sz(1)); maxy=maxy-offset; mark=mark(1:end-offset,:); end
                        if (minx>1); minx=minx+offset; mark=mark(:,offset+1:end); end
                        if (maxx<sz(2)); maxx=maxx-offset; mark=mark(:,1:end-offset); end
                        markers(miny:maxy,minx:maxx)=mark;
                    end
                end 

                if (interactive && strcmpi(inputCorrect,'N')); markers = correctMarkersNow(I,markers,newR); end
                save([markersDir filesep baseName '_markers.mat'],'markers');
            
        else; load([markersDir filesep  baseName '_markers.mat'],'markers'); end
        
        
        markers(deposito) = false;
        markers(~Regs) = false;
        imgMarkers = drawMarkers(I, markers, newR);
        figure; imshow(imgMarkers);
        
        imwrite(I,[markersDir filesep baseName '_Rescaled.tif']);
        imwrite(imgMarkers,[markersDir filesep baseName '_RGBMarkers.tif']);
        imwrite(uint8(markers)*255,[markersDir filesep baseName '_BINmarkers.tif']);
        
        areaReg=double(sum(uint8(newR(:)>0)));
        areaMarkers=double(sum(markers(:)));
        percArea=areaMarkers/areaReg;     

        areaRegOld=double(sum(uint8(Regs(:)>0)));
        percAreaOld=areaMarkers/areaRegOld;     

        disp(num2str(percArea)); 
        disp(num2str(percAreaOld)); 
        
        
%        RegsR = newR==1;
%         RegsY = newR==2;
%         RegsG = newR==3;
%         
%        markersR = markers & RegsR;
%         markersY = markers & RegsY;
%         markersG = markers & RegsG;
%         
%         areaRegRed=double(sum(uint8(RegsR(:))));
%         areaMarkersRed=double(sum(markersR(:)));
%         percAreaRed=areaMarkersRed/areaRegRed;     
% 
%         areaRegY=double(sum(uint8(RegsY(:))));
%         areaMarkersY=double(sum(markersY(:)));
%         percAreaY=areaMarkersY/areaRegY;  
% 
%         areaRegG=double(sum(uint8(RegsG(:))));
%         areaMarkersG=double(sum(markersG(:)));
%         percAreaG=areaMarkersG/areaRegG; 
% 
%         str=[baseName sprintf('\t') num2str(areaReg) sprintf('\t')...
%             num2str(areaMarkers) sprintf('\t') num2str(percArea) sprintf('\t')...
%             num2str(areaMarkersRed) sprintf('\t') num2str(areaRegRed)...
%             sprintf('\t') num2str(percAreaRed)  sprintf('\t') ...
%             num2str(areaMarkersY) sprintf('\t') num2str(areaRegY)...
%             sprintf('\t') num2str(percAreaY)  sprintf('\t') ...
%             num2str(areaMarkersG) sprintf('\t') num2str(areaRegG)...
%             sprintf('\t') num2str(percAreaG)];
        
            str=[baseName sprintf('\t') num2str(areaReg) sprintf('\t')...
            num2str(areaMarkers) sprintf('\t') num2str(percArea)];
        fprintf(fidDensity, '%s\n',str); clear str;
        baseNames(numI,1) =  {baseName};
        regAreas(numI,1) = areaReg;
        markerAreas(numI,1) = areaMarkers;
        densities(numI,1) = percArea;
        
        
        tab = table(baseNames, regAreas, markerAreas, densities, 'VariableNames',{'ImgName','tissueArea','markerArea','markeDensity'});

        clear areaReg areaMarkers percArea areaMarkersG areaMarkersY areaMarkersRed str;
        clear areaRegRed areaRegY areaRegG percAreaRed percAreaG percAreaY;
        
        clear imgMarkers I IRGB Regs;
        close all  
    end
    clear fnsAll;
    fclose(fidDensity);
    writetable(tab, [markersDir filesep 'markerData.xlsx']);
    if strcmpi(inputCorrect,'Y'); CorrectMarkersLater(dirImgs); end
end

