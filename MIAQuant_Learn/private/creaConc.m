function res=creaConc(img,regs,R)
    if nargin<3
        regsF=imfill(regs,'holes');
        if any(~regsF(:))
            imgDistR=bwdist(regsF & (~(imerode(regsF,strel('disk',2)))));
            imgDistR(~regsF)=0;
            limitUp=round(max(imgDistR(:))/25);
        else; limitUp=round(double(max(size(regs)))/25); end
        limitDown=0;
        img=logical(img);
        imgDist=bwdist(img);
        imgDist(~regs)=0; 
        h=smooth(hist(imgDist(regs(:)),0:limitUp+10),20);
        h(limitUp+1:end)=0;
        h(1:limitDown-1)=0; 
        [~,R]=max(h);
        imgConc=imgDist<R/2 & regs;
        while (sum(imgConc(:))/sum(regs(:)))< min(0.075,(sum(img(:))/sum(regs(:)))*50)
            R=R+3;
            imgConc=imgDist<R/2 & regs;
        end
    else
        imgDist=bwdist(img);
        imgDist(~regs)=0; 
        imgConc=imgDist<R/2 & regs;
    end
    disp(['raggio dilatazione ' num2str(R)]);
    imgConc=bwareaopen(imgConc,R*5*R);
    imgConc2=imgDist<R & regs;
    [r,c]=find(imgConc & imgConc2);
    imgConc=bwselect(imgConc2, c,r);
    res.imgConc=imfill(bwareaopen(imgConc,R*20*R),'holes');
    res.R=R;
end