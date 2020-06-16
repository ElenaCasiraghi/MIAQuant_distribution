function RenameFiles(dirImgs)
    % Last Update 03 July 2017
    if (nargin<1) || numel(dirImgs)==0  %#ok<ALIGN>
        dirImgs=uigetdir(...
            'C:\DATI\articoliMIEI\ArticlesSubmitted\SpecialIssueBMC_BITS\ESTRATTE50%_PLACCHE_daRegistrare\MHReg_PolyReg_100Reduction_13-Aug-2017'); end
    disp(['DIRECTORY PATHNAME: ' dirImgs]);
    fnsAll=[dir([dirImgs '\*.tif']);  dir([dirImgs '\*.jpg']);  dir([dirImgs '\*.png'])]; 
    
    for numI=1:numel(fnsAll)
        fName=fnsAll(numI,1).name;
        
        info=parseName(fName);
        fName2=[info.patName '_' info.markerName '_' info.markerColor '_' info.numFetta(3:end) '.' info.ext]; 
       
        disp(fName);
        disp(fName2);
        answer=input('change name?? Y/N','s');
        if strcmpi(answer,'Y') || (numel(answer)==0)
            str1=[dirImgs '\' fName];
            str2=[dirImgs '\' fName2];
            movefile(str1,str2); end
    end
end

