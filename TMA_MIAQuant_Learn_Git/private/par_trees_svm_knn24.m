function markersBIN=par_trees_svm_knn24(I,maskReg,dimLimit,dirClassifiers,...
    colorName,basicColorName, thrArea,strClassMarkers, slash)
    
    
   
    if ~isempty(basicColorName); strClassBasic='BasicColor'; end
    numFeat=42; numFeatBasic = 6;
    stSmall = strel('disk',1);
    sz=size(maskReg);  
    if (sz(2)>dimLimit); stepCut(1)=uint32(round(sz(2)/dimLimit)); else; stepCut(1)=1; end
    if (sz(1)>dimLimit); stepCut(2)=uint32(round(sz(1)/dimLimit)); else; stepCut(2)=1; end
    taglioC=uint32(ceil(double(sz(2))/double(stepCut(2))));
    taglioR=uint32(ceil(double(sz(1))/double(stepCut(1))));
    subImgs(stepCut(1),stepCut(2)).irgb=[];
    subImgs(stepCut(1),stepCut(2)).reg=[];          
    for i=uint32(1):uint32(stepCut(1))
        for j=uint32(1):uint32(stepCut(2))
            miny=max((i-1)*taglioR,1);
            maxy=min(i*taglioR+1,sz(1));
            minx=max((j-1)*taglioC,1);
            maxx=min(j*taglioC+1,sz(2));
            subImgs(i,j).irgb=I(miny:maxy,minx:maxx,:);  
            subImgs(i,j).range=[miny,maxy,minx,maxx]; %taglioC, taglioR];
            subImgs(i,j).reg=maskReg(miny:maxy, minx:maxx);
            %% classificatori per markers
            if ((i==1) && (j==1)) 
                if ~isempty(basicColorName) && ...
                        exist([dirClassifiers slash 'Mdltree_' strClassBasic '_' basicColorName '.mat'],'file')
                    mdltreeRoughStr=load([dirClassifiers slash 'Mdltree_' strClassBasic '_' basicColorName '.mat']);
                    flagBasic=true;
                else; flagBasic=false; end
                mdltreeStr=load([dirClassifiers slash 'Mdltree' num2str(numFeat) '_' ...
                        strClassMarkers '_' colorName '.mat']); 
                mdltreeStrBasic=load([dirClassifiers slash 'MdltreeBasic' num2str(numFeatBasic) '_' ...
                        strClassMarkers '_' colorName '.mat']); 
            end
            if flagBasic; subImgs(i,j).roughTreeClass={mdltreeRoughStr.mdltree;}; end
            subImgs(i,j).treeClass={mdltreeStr.Mdltree};
            subImgs(i,j).treeBasicClass={mdltreeStrBasic.MdltreeBasic};
        end
    end
    clear i j;
    clear mdlsvmColorsStr mdltreeColorsStr mdltreeDivStr;
    clear mdlsvmColorsCriticalStr mdlsvmDivCriticalStr mdltreeColorsCriticalStr mdltreeDivCriticalStr;
    markersBIN=zeros(sz);
    
    for ii=uint32(1):uint32(stepCut(1))
        macrCol=[];
        miny=(ii-1)*taglioR+1;
        maxy=ii*taglioR;
        for jj=uint32(1):uint32(stepCut(2))
      %  parfor jj=uint32(1):uint32(stepCut(2))
            markSubCol=zeros(size(subImgs(ii,jj).reg));
            if any(any(subImgs(ii,jj).reg>0))       
               if flagBasic; MdltreeRough=subImgs(ii,jj).roughTreeClass; end
               Mdltree=subImgs(ii,jj).treeClass;
               MdltreeBasic=subImgs(ii,jj).treeBasicClass;
               %Mdlsvm=subImgs(ii,jj).treeClass; 
               Ifeats = ComputeFeatures(subImgs(ii,jj).irgb);
              
               indTrue=find(subImgs(ii,jj).reg);
               featsColors=double(computePtsVals(indTrue,Ifeats)); 
               Ifeats=[]; featsCol = featsColors; indT = indTrue;
                if flagBasic 
                    labsOff=predict(MdltreeRough{1,1}, [featsColors(:,1:3)])==0;
                    featsColors(labsOff,:)=[];  
                    indTrue(labsOff)=[]; labsOff=[]; 
                end     
                markSubCol(indTrue)=markSubCol(indTrue)+1;   
                
%                 labsOff=predict(MdltreeBasic{1,1}, featsColors(:,1:numFeatBasic))==0 ;
%                 featsColors(labsOff,:)=[];  
%                indTrue(labsOff)=[]; labsOff=[];
%                markSubCol(indTrue)=markSubCol(indTrue)+1;  
%                
%                 labsOff=predict(Mdltree{1,1}, featsColors)==0 ;
%                 featsColors(labsOff,:)=[];  
%                indTrue(labsOff)=[]; labsOff=[];
%                markSubCol(indTrue)=markSubCol(indTrue)+1;    
               
            else; indTrue=find(subImgs(ii,jj).reg); end
            range=subImgs(ii,jj).range;
            minyOrig=range(1); maxyOrig=range(2); 
            minxOrig=range(3); maxxOrig=range(4);
            
            minx=(jj-1)*taglioC+1;
            maxx=jj*taglioC; 
            if (minyOrig<miny);  markSubCol=markSubCol(2:end,:); end
            if (maxyOrig>maxy);  markSubCol=markSubCol(1:end-1,:); end
            if (minxOrig<minx);  markSubCol=markSubCol(:,2:end); end
            if (maxxOrig>maxx);  markSubCol=markSubCol(:,1:end-1); end
            macrCol=[macrCol markSubCol];
            taglioCC=[]; taglioRR=[];
        end
        markersBIN(((ii-1)*taglioR)+1:min(ii*taglioR,sz(1)),:)=macrCol;
    end
    
%     markersBIN=activecontour(I,imopen(markersBIN,stSmall)) & maskReg;
%     Ifeats=IRGB;  
%     indTrue=find(markersBIN);
%     featsColors=double(computePtsVals(indTrue,Ifeats));
% %     labsOff=predict(MdlKNN{1,1},featsColors(:,1:3))==0; 
% %     featsColors(labsOff,:)=[];
% %     indTrue(labsOff)=[]; labsOff=[];
%     markersBIN(:,:)=false;
%     markersBIN(indTrue)=true;
   markersBIN=bwareaopen(markersBIN,30);
end
