function [regs, ok] =  analizeRegs(regs, ok, areaDet, factorComp, thrEcc, ...
                                    thrEquivDiam, factorMinArea,factorMaxArea)  
    
    conn = 4;
    if nargin< 8; factorMaxArea = 1; end
    if nargin< 7; factorMinArea = 1; end
    if nargin< 6; thrEquivDiam = 0.2; end
    if nargin< 5; thrEcc = 0.9; end
    if nargin< 4; factorComp = 2; end
    
    if any(regs(:))
        cc = bwconncomp(regs,conn); 
        labs = labelmatrix(cc);
        stats = regionprops(cc, 'Area','Eccentricity','Perimeter', 'MinorAxisLength', ...
                                'MajorAxisLength', 'EquivDiameter','ConvexArea'); 

        idx = find( [stats.Area]<= factorMaxArea*areaDet.maxArea & ... % l'area non deve essere troppo grossa
                    [stats.Area]>= factorMinArea*areaDet.minArea & ...                % ne troppo piccola
                    [stats.MinorAxisLength]>=areaDet.minRad*1.2 & ...  % gli assi devono stare nel range [minRad*2,maxRad*2]
                        (([stats.Area]>mean([areaDet.minArea, areaDet.medianArea]) & ...
                        [stats.MinorAxisLength]./[stats.MajorAxisLength]>0.6) | ...
                        ([stats.Area]<=mean([areaDet.minArea, areaDet.medianArea]) & ...
                        [stats.MinorAxisLength]./[stats.MajorAxisLength]>0.5 )) ...
                        & ...
                        [stats.MajorAxisLength]<=areaDet.maxRad*2.5 & ...
                        [stats.EquivDiameter]./[stats.MajorAxisLength]>= 1-thrEquivDiam & ... % il diametro equivalente
                        [stats.EquivDiameter]./[stats.MajorAxisLength]<= 1+thrEquivDiam & ... % e quello della regione sono simili
                        round(([stats.Perimeter]./[stats.Area])*100)<round((factorComp*(4./[stats.MajorAxisLength]))*100) ...
                         ...      % deve avere lo stesso rapporto di quello che
                          ...      % avrebbe il cerchio con raggio
                          ...      % MajorAxisLength/2
                        &  [stats.Eccentricity] < thrEcc); % e eccentricità sotto soglia
        if numel(idx)>0 % le rimuovo da notOk e le metto in ok!
            rr = ismember(labs, idx);
            % prendo le prime regioni piccole
            labs(rr) = 0;
            clear idx;
            % aggiungo quelle grosse
            idx = find( [stats.Area]<= areaDet.maxArea & ... % l'area non deve essere troppo grossa
                        [stats.Area]>= factorMaxArea*areaDet.maxArea & ... % l'area non deve essere troppo grossa
                        [stats.MinorAxisLength]./[stats.MajorAxisLength]>0.75 & ...
                        [stats.MajorAxisLength]<=areaDet.maxRad*2.5 & ...
                        [stats.EquivDiameter]./[stats.MajorAxisLength]>= 1-thrEquivDiam & ... % il diametro equivalente
                        [stats.EquivDiameter]./[stats.MajorAxisLength]<= 1+thrEquivDiam & ... % e quello della regione sono simili
                        round(([stats.Perimeter]./[stats.Area])*100)<round((factorComp*(4./[stats.MajorAxisLength]))*100) ...
                         ...      % deve avere lo stesso rapporto di quello che
                          ...      % avrebbe il cerchio con raggio
                          ...      % MajorAxisLength/2
                        &  [stats.Area]./[stats.ConvexArea]> 0.9 ... % la sua area diviso l'area della regione convessa 
                        ...                    %deve essere prossima a 1
                        &  [stats.Eccentricity] < thrEcc); % e eccentricità sotto soglia
                   
            if numel(idx)>0 % le rimuovo da notOk e le metto in ok!
                rr = rr | ismember(labs, idx);
            end
            clear labs idx cc
            if any(rr(:))
               % controllo anche che il raggio minimo e massimo non abbiano un 
               % rapporto troppo scompensato
               cc = bwconncomp(rr,conn); 
               labs = labelmatrix(cc);
               stats = regionprops(cc,'Area','Image','ConvexImage');
               idx = find( [stats.Area]>= areaDet.medianArea);
               discarded = double(labs-labs);
               if numel(idx)>0 % le rimuovo da notOk e le metto in ok!
                   for indR = 1 : numel(idx)
                       nR = idx(indR);
                       distR = bwdist(bwskel(stats(nR).Image));
                       maxR = max(distR(bwperim(stats(nR).Image)));
                       minR = min(distR(bwperim(stats(nR).Image)));

                       distR = bwdist(bwskel(stats(nR).ConvexImage));
                       maxRC = max(distR(bwperim(stats(nR).ConvexImage)));
                       minRC = min(distR(bwperim(stats(nR).ConvexImage)));
                     %  disp(['nR = ' num2str(nR) ', minR/maxR = ' num2str(minR/maxR)...
                      %         ', minRC/maxRC = ' num2str(minRC/maxRC)]);
                       if (stats(nR).Area < (areaDet.maxArea*factorMaxArea) && minR/maxR<0.15 && minRC/maxRC<0.5) ...
                           || (stats(nR).Area >= (areaDet.maxArea*factorMaxArea) && minR/maxR<0.1 && minRC/maxRC<0.45)                       
                           rr(labs == nR) = false;
                       %   disp(['DISCARDED ---- nR = ' num2str(nR) ', minR/maxR = ' num2str(minR/maxR)...
                       %        ', minRC/maxRC = ' num2str(minRC/maxRC)]);

                           discarded = discarded + double(labs == nR)*nR;

                       end
                   end
               end
               rr = imfill(rr,'holes');
               ok(rr) = max(ok(:));
               ok = ok + bwlabel(rr, conn);
               regs(imdilate(rr,strel('disk',1))) = false;
            end
%         if any(any(discarded>0))
%                figure; imshow(discarded,[]);
%         end   
            clear cc labs stats idx rr;
        end
    end
 end