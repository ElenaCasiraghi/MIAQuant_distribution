function MIAQuant_CellCount(dirImgs,templates)
% Last Update 05 December 2017
% % Copyright: Elena Casiraghi
% % This software is described in 
% % 
% % A novel computational method for automatic segmentation, quantification 
% % and comparative analysis of immunohistochemically labeled tissue sections
% % Authors: Elena Casiraghi(1), Veronica Huber(2), Marco Frasca(1), Mara Cossa(2), 
% % Matteo Tozzi(3), Licia Rivoltini(2), Biagio Eugenio Leone(4), 
% % Antonello Villa(4,5) and Barbara Vergani(4,5)
% % (1)Department of Computer Science �Giovanni Degli Antoni�, 
% %         Universit� degli Studi di Milano, Milan, Italy.
% % (2)Unit of Immunotherapy of Human Tumors, Department of Experimental Oncology and Molecular Medicine, 
% %         Fondazione IRCCS Istituto Nazionale dei Tumori, Milan, Italy.
% % (3)Department of medicine and surgery, Vascular Surgery, 
% %         University of Insubria Hospital, Varese, Italy.
% % (4)School of Medicine and Surgery, 
% %         University of Milano Bicocca, Monza, Italy.
% % (5)Consorzio MIA � Microscopy and Image Analysis, 
% %         University of Milano Bicocca, Monza, Italy.
% %
% % BMC BioInformatics
% % 
% % MIAQuant_Learn is freely available for clinical studies, pathological research, and diagnosis.
% % For any trouble refer to 
% % casiraghi@di.unimi.it
% % 
% % If MIAQuant is helpful for your studies/research, please cite the above mentioned article.

    warning off;
    delete(gcp('nocreate')); parpool;
    if (nargin==0); dirImgs=uigetdir(...
            'C:\',...
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
    dirInfoImgs=[dirImgs '\InfoImgs'];
  %  dirClassifiers=uigetdir([],'Select the folder containing trained classifiers'); 
    dirClassifiers='.\TrainedClassifiers';
    dimLimitOut=12000; dimLimitIn=3000;  
    factorRed=input([newline '-------------------' newline 'If wanted insert the reduction factor'...
        newline 'e.g: 0.1 for reduction at 10% image size, 0.5 to halve the image size,... ' newline]);
    if numel(factorRed)==0; factorRed=1; end
    dd=input(['insert the experiment identification' newline],'s');
    dirSave=[dirImgs '\Exp_Reduction_' num2str(factorRed*100) '_' dd]; 
    methodRed='nearest'; 
    
   
    %% per regTissue;
    threshSmallAreas=round(10*(factorRed)^2);
    crop=true; gaussDev=0.5*factorRed; 
    fsz=round(25*factorRed); if (mod(fsz,2)==0); fsz=fsz+1; end
    %% per aree di massima concentrazione!
    %thrAreaConc=round(1500*(factorRed*1.25)^2);
    thrArea=round(6*(factorRed*1.25)^2);
    stSmall=strel('disk',3); regFill=true;
    %stBig2=strel('disk',max(1,double(round(30*factorRed))));
    offset=8;
      
    if ~exist(dirSave,'dir'); mkdir(dirSave); end
    disp(dirSave);
    dirSaveMarker=[dirSave '\Markers'];
    if ~exist(dirSaveMarker,'dir'); mkdir(dirSaveMarker); end
   
    nameDensity=[dirSaveMarker '\MarkerDensityData.txt'];
    if ~exist(nameDensity,'file'); fidDensity = fopen(nameDensity,'w');
    else; fidDensity = fopen(nameDensity,'a'); end
    fprintf(fidDensity,'directory pathname: %s\n',dirImgs); 
   
    mAreas={};
    nameArea=[dirSave '\markerAreas.txt'];
    if ~exist(nameArea,'file'); fidArea = fopen(nameArea,'w');
    else; fidArea = fopen(nameArea,'a'); end
    fprintf(fidArea,'directory pathname: %s\n',dirImgs); 
    
   
    numZero=2;
    %% SEGMENTO TUTTE LE TISSUE REGIONS e i manual landmarks
    trailer='01';
    fnsAll=[dir([dirImgs '\*_' templates{1} '_*_' trailer '.tif']);
                dir([dirImgs '\*_' templates{1} '_*_' trailer '.jpg']);
                dir([dirImgs '\*_' templates{1} '_*_' trailer '.png']);];
    for numTemp=2: numel(templates)
           tempMarker=templates{numTemp};
           fns=[dir([dirImgs '\*_' tempMarker '_*_' trailer '.tif']);
               dir([dirImgs '\*_' tempMarker '_*_' trailer '.jpg']);
               dir([dirImgs '\*_' tempMarker '_*_' trailer '.png'])];
           fnsAll=[fnsAll; fns];
    end
    strAdd='A'; maxSz=0;
    for numI=1:numel(fnsAll)
        fName=fnsAll(numI,1).name;
        info=parseName(fName);
        disp(['imgName=' info.patName ...
            ' - #SubImg=' info.numFetta ...
            ' - Marker=' info.markerName ' - Color=' info.markerColor]);
        baseName=[info.patName '_' info.markerName '_' info.markerColor];
        disp(baseName)
        if ~exist([dirSave '\' baseName '_' strAdd 'Regs.mat'],'file') || ...
                ~exist([dirSave '\' baseName '_' strAdd 'RegsF.mat'],'file') || ...
                ~exist([dirSave '\' baseName '_' strAdd 'Ipoly.mat'],'file') || ...
                ~exist([dirSave '\' baseName '_' strAdd 'Size.mat'],'file') || ...
                ~exist([dirSave '\' baseName '_' strAdd 'bordersOI.mat'],'file') 
            if (factorRed~=1) 
                I=[]; InfoImg=[]; numF=1; strNumF=num2str(numF);
                while(numel(strNumF)<numZero); strNumF=['0' strNumF]; end
                strFetta=[baseName '_' strNumF ]; clear strNumF;
                while exist([dirImgs '\' strFetta '.' info.ext],'file')
                    I=[I imresize(imread([dirImgs '\' strFetta '.' info.ext]),factorRed,methodRed)];
                    if exist([dirInfoImgs '\' strFetta '.' info.ext],'file') 
                        InfoImg=[InfoImg ...
                            imresize(imread([dirInfoImgs '\' strFetta '.' info.ext]),factorRed,methodRed)];
                    end; clear strFetta strNumF;
                    numF=numF+1; strNumF=num2str(numF); 
                    while(numel(strNumF)<numZero); strNumF=['0' strNumF]; end 
                    strFetta=[baseName '_' strNumF];
                end
            else; I=[]; InfoImg=[]; numF=1; strNumF=num2str(numF);
                while(numel(strNumF)<numZero); strNumF=['0' strNumF]; end %#ok<*AGROW>
                strFetta=[baseName '_' strNumF ]; clear str
                while exist([dirImgs '\' strFetta '.' info.ext],'file')
                    I=[I imread([dirImgs '\' strFetta '.' info.ext])]; 
                    if exist([dirInfoImgs '\' strFetta '.' info.ext],'file')
                        InfoImg=[InfoImg imread([dirInfoImgs '\' strFetta '.' info.ext])];
                    end; clear strNumF strFetta;
                    numF=numF+1; strNumF=num2str(numF); 
                    while(numel(strNumF)<numZero); strNumF=['0' strNumF]; end 
                    strFetta=[baseName '_' strNumF];
                end
            end
            I=I(:,:,1:3);
            sz=regTissue(I,InfoImg,baseName, dirSave,strAdd, crop,regFill,fsz,gaussDev, threshSmallAreas);
            clear I;
            maxSz=max(maxSz, sz);
            save([dirSave '\' strAdd 'maxSz.mat'],'maxSz');
        end
    end
    
    %% MARKER SEGMENTATION AND DENSITY ESTIMATION 
    disp('Marker segmentation and density estimation');
    strTitle=['--------------marker Density per Img----------------' newline ...
              '-----------------------' strAdd '-------------------------' newline...
        'Img Name' sprintf('\t') 'Tissue Area' sprintf('\t') ...
        'Marker Area' sprintf('\t') 'Marker Density w.r.t tissue' sprintf('\t') ...
        'Concentrated-Marker Area' sprintf('\t') 'Concentrated-Marker Density w.r.t tissue'...
         sprintf('\t') 'Concentrated-Marker Density w.r.t Conc.Areas'];
    disp(strTitle);
    fprintf(fidDensity, '%s\n',strTitle); clear strTitle;
    
    for numI=1:numel(fnsAll)
        fName=fnsAll(numI,1).name;
        info=parseName(fName);
        baseName=[info.patName '_' info.markerName '_' info.markerColor];
        disp([num2str(numI) '->' baseName '<-']);
        load([dirSave '\' baseName '_' strAdd 'RegsF.mat']);
        load([dirSave '\' baseName '_' strAdd 'Regs.mat']);  
        load([dirSave '\' baseName '_' strAdd 'IRGB1.mat']);
        load([dirSave '\' baseName '_' strAdd 'IRGB2.mat']);
        load([dirSave '\' baseName '_' strAdd 'IRGB3.mat']);
        load([dirSave '\' baseName '_' strAdd 'IRGB4.mat']);
        IRGB=[IRGB1 IRGB2; IRGB3 IRGB4];
        clear IRGB1 IRGB2 IRGB3 IRGB4; 
        if exist('RegsF','var') && exist('IRGB','var')
            if ~exist([dirSave '\' baseName '_' strAdd 'markers.mat'],'file') %#ok<ALIGN>
                %% se una immagine ha nome colore= presetCol-addCol
                %% presetCol � il colore pi� selettivo che permette di selezionare 
                %% solo porzioni di regioni di marker, 
                %% ma tali regioni vengono spesso sottosegmentate
                %% addCol � un colore pi� generico che prende di pi� ma permette di ottenere
                %% zone di marker meglio definite
                %% quindi prendo le regioni di marker cercando zone con colore presetCol
                %% e poi uso le forme date dalla ricerca di zone di colore addCol
                presetmarkerColor=[];
                basemarkerColor=[];
                sz=size(RegsF);
                if numel(presetmarkerColor)==0 
                    presetmarkerColor=info.markerColor; 
                    disp(['Segment markers with color ' presetmarkerColor]);
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
                markers=false(sz(1),sz(2));
                for i=uint32(1):uint32(stepCut(1))
                    for j=uint32(1):uint32(stepCut(2))
                        miny=max((i-1)*taglioR+1-offset,1);
                        maxy=min(i*taglioR+offset,sz(1));
                        minx=max((j-1)*taglioC+1-offset,1);
                        maxx=min(j*taglioC+offset,sz(2));
                        img=double(IRGB(miny:maxy,minx:maxx,:));  
                        reg=Regs(miny:maxy,minx:maxx);
                        mark=logical(par_trees_svm_knn24(img,reg,dimLimitIn,...
                                dirClassifiers, presetmarkerColor,basemarkerColor,thrArea));
                        clear img reg;
                        if (miny>1); miny=miny+offset; mark=mark(1+offset:end,:); end
                        if (maxy<sz(1)); maxy=maxy-offset; mark=mark(1:end-offset,:); end
                        if (minx>1); minx=minx+offset; mark=mark(:,offset+1:end); end
                        if (maxx<sz(2)); maxx=maxx-offset; mark=mark(:,1:end-offset); end
                        markers(miny:maxy,minx:maxx)=mark;
                    end 
                end 
                markers=activecontour(IRGB,imopen(markers,stSmall));
                save([dirSave '\' baseName '_' strAdd 'markers.mat'],'markers');
            else; load([dirSave '\' baseName '_' strAdd 'markers.mat']); end
            figure('Name', baseName); imshow(IRGB);
            figure('Name', baseName); imshow(IRGB.*cat(3,uint8(markers),uint8(markers),uint8(markers)));
            r=size(markers,1); c=size(markers,2); 
            markDel=bwselect(markers,ones(r,1),(1:r)');
            markDel=markDel | bwselect(markers,ones(r,1)*c,(1:r)');
            markDel=markDel | bwselect(markers,1:c,ones(c,1));
            markDel=markDel | bwselect(markers,1:c,ones(c,1)*r);
            markers=markers & ~markDel; clear markDel;
            markDel=bwselect(markers);
            markers=markers & ~markDel;
            close all;
            area=regionprops(markers,'Area');
            fprintf(fidArea, '%s\n',baseName); 
            indM=find(strcmpi(templates,info.markerName)); 
            if numel(mAreas)<indM; mAreas{indM}.areas=[]; 
                mAreas{indM}.num=numel(area); 
            else; mAreas{indM}.num=[mAreas{indM}.num ;numel(area)]; end
            for numA=1:numel(area)
                fprintf(fidArea,'%s\n',num2str(area(numA).Area)); 
                mAreas{indM}.areas=[mAreas{indM}.areas; area(numA).Area];
            end
            areaReg=double(sum(RegsF(:)));
            areaMarkers=double(sum(markers(:)));
            percArea=areaMarkers/areaReg;     
            if exist([dirSave '\' baseName '_' strAdd 'markersConc.mat'],'file')
                load([dirSave '\' baseName '_' strAdd 'markersConc.mat']);
            else 
                resConc=creaConc(markers,Regs);
                markersConc=resConc.imgConc;
                RConc=resConc.R;  %#ok<NASGU>
                save([dirSave '\' baseName '_' strAdd 'markersConc.mat'],'markersConc');
                save([dirSave '\' baseName '_' strAdd 'RConc.mat'],'RConc');
            end
                  
            areaMarkersConc=double(sum(markersConc(:) & markers(:)));
            percAreaConcInReg=areaMarkersConc/areaReg;
            percAreaConcInConcArea=areaMarkersConc/sum(markersConc(:));
            str=[baseName sprintf('\t') num2str(areaReg) sprintf('\t')...
                num2str(areaMarkers) sprintf('\t') num2str(percArea) sprintf('\t')...
                num2str(areaMarkersConc) sprintf('\t') num2str(percAreaConcInReg)...
                sprintf('\t') num2str(percAreaConcInConcArea)];
            fprintf(fidDensity, '%s\n',str); clear str;
            clear areaReg areaMarkers percArea areaMarkersConc perAreaConc str;
            imgMarkers=cat(3,uint8(markers),uint8(markers),uint8(markers));
            imgMarkers=imgMarkers.*IRGB;
            imgMarkersConc=cat(3,uint8(markersConc),uint8(markersConc),uint8(markersConc));
            imgMarkersConc=imgMarkersConc.*IRGB;
            imwrite(imgMarkers,[dirSaveMarker '\' baseName '_' strAdd 'RGBMarkers.tif']);
            imwrite(imgMarkersConc,[dirSaveMarker '\' baseName '_' strAdd 'RGBMarkersCONC.tif']);
            imwrite(uint8(markers)*255,[dirSaveMarker '\' baseName '_' strAdd 'BINmarkers.tif']);
            clear imgMarkers markersConc;
            
        end
    end
    clear fnsAll;
    
    for numT=1:numel(templates)
        arrAreas=mAreas{numT}.areas;
        figure('Name', ['marker: ' templates{numT} ' (hist of areas)']);
        plot(min(arrAreas):+50:max(arrAreas),hist(arrAreas,min(arrAreas):+50:max(arrAreas)));
        disp(['Marker ' templates{numT} ':' newline ...
            'mean of markers Areas:' num2str(mean(arrAreas)) newline ...
            'std of markers Areas:' num2str(std(arrAreas))]); 
    end
   
    fclose(fidDensity);
    fclose(fidArea);    
end

