function info=parseName(strName)
    pos=strfind(strName,'_');
    posP=strfind(strName,'.');
    if numel(pos)>=1; info.patName=strName(1:(pos(1)-1)); 
    else; info.patName=strName(1:end-4);return;  end    
    if numel(pos)>=2; info.markerName=strName(pos(1)+1:pos(2)-1);
    else; info.markerName=strName(pos(1)+1:end-4); end       
    if numel(pos)==2 
        if numel(posP)>0; info.markerColor=strName(pos(2)+1:posP-1); 
        else; info.markerColor=strName(pos(2)+1:end); end
    end  
    if numel(posP)>0; info.ext=strName(posP+1:end);
    else; info.ext= ''; end
end