function dataAnalisys24Feat(ptsOnVals,ptsOffVals,ptsCOffVals, ... 
            markerColor,dirSave,strClassDef, baseColor, slash)
    
    if nargin<5; dirSave=['.' slash 'TrainedClassifiers']; end
    
   
    numFeat=size(ptsOnVals,2);
    ptsOnCoded=ptsOnVals;
    ptsOffCoded=ptsOffVals;
    ptsCOffCoded=ptsCOffVals;
    
    
      disp([newline ...
      '----------------------------------------' newline ...
          'TRAINING BASIC tree on ptsOn + ptsOff' newline ...
          '----------------------------------------' newline]);
     ptsOffBasi=[ptsOffCoded(:,1:3); ptsCOffCoded(:,1:3)];
     ptsOnBasic=ptsOnCoded(:,1:3);  
     testD=[ptsOnBasic; ptsOffBasi];
     testLab=[true(size(ptsOnBasic,1),1); 
                false( size(ptsOffBasi,1),1)];
     cost = [0 0.5;
             1.5  0];
         % Faccio in modo di essere sicura di non buttare via marker!
     mdltree= fitctree(testD, testLab, 'Cost', cost, ...
                'OptimizeHyperparameters','all', ...
                'HyperparameterOptimizationOptions',struct('MaxObjectiveEvaluations',100));
    save([dirSave slash 'MdlTree_BasicColor_' baseColor '.mat'],'mdltree');
    
    
     
%     if exist([dirSave slash 'MdltreeBasic' num2str(size(ptsOnBasic,2)) '_' strClassDef '_' markerColor '.mat'],'file')
%         load([dirSave slash 'MdltreeBasic' num2str(size(ptsOnBasic,2)) '_' strClassDef '_' markerColor '.mat']);
%     else
        %% learn Basic Tree to select Marker against Not Marker
        disp([newline ...
              '----------------------------------------' newline ...
              'TRAINING BASIC TREE on all Training Data' newline ...
              '----------------------------------------' newline]);
        ptsOffBasic=[ptsOffCoded(:,1:6)];
        ptsOnBasic=ptsOnCoded(:,1:6);  
        testD=[ptsOnBasic; ptsOffBasic];
        testLab=[true(size(ptsOnBasic,1),1); 
                false( size(ptsOffBasic,1),1)];
        maxSens = -1;
        for i=1:5
            structLearn=learnDT(ptsOnBasic,ptsOffBasic,100, testD, testLab);
            close all;
            if (structLearn.sens>maxSens)
                MdltreeBasic=structLearn.Mdltree;
                maxSens=structLearn.sens;
            end
            clear structLearn;
        end
        view(MdltreeBasic,'Mode','graph');
        save([dirSave slash 'MdltreeBasic' num2str(size(ptsOnBasic,2)) '_' strClassDef '_' markerColor '.mat'],'MdltreeBasic');
   % end
   

    ptsOff = ptsOffCoded;
    testD=[ptsOnCoded; ptsOff; ptsCOffCoded];       
    testLab=[true(size(ptsOnCoded,1),1); 
                false( size(ptsOff,1),1); false(size(ptsCOffCoded,1),1)];
            
            
    predicted=predict(MdltreeBasic,ptsOff(:,1:6)); 
    clear ptsOnBasic ptsOffBasic;
    clear MdltreeBasic;
    On=ptsOnCoded;

    Off=[ptsCOffCoded; ptsOff(predicted,:)];  
    if size(On,1)>size(Off,1)
        ptsOffAdd=ptsOff(~predicted,:); 
        ptsOffAdd=ptsOffAdd(randperm(size(ptsOffAdd,1)),:);
        ptsOffAdd=ptsOffAdd(1:min(size(ptsOffAdd,1),...
            size(On,1)-size(Off,1)),:);
        Off=[Off; ptsOffAdd]; 
        clear ptsOffAdd;
    end
    clear predicted;
    maxAcc=-1.0;
    fUnbalanced=Inf;
    
    disp([newline ...
          '----------------------------------------' newline ...
          'TRAINING second TREE on ptsOn + ptsOff' newline ...
          '----------------------------------------' newline]);
    for i=1:5
        structLearn=learnDT(On,Off,fUnbalanced, testD, testLab);
        close all;
        if (structLearn.acc>maxAcc)
            Mdltree=structLearn.Mdltree;
            maxAcc=structLearn.acc;
        end
        clear structLearn;
    end
    save([dirSave slash 'Mdltree' num2str(numFeat) '_' strClassDef '_' markerColor '.mat'],'Mdltree');
    view(Mdltree,'Mode','graph');
    clear On Off;
   
  
    clear On Off;
     
    
end
    
