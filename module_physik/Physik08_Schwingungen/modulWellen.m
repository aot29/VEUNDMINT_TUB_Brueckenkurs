%  modulWellen erzeugt Abbildungen für den zweiten Teil vom Modul
%  Schwingungen und Wellen

%==========================================================================
%
%  Name:        modulWellen.m
%
%  Author:      EH
%  Date:        2012/08/29
%
%  Modifications on 2012/00/00 by EH:
%
%  Bugs, suggestions, remarks:
%
%==========================================================================

function modulWellen()

printOpt=1;
fW=9; %figure width in cm, in HTML max. 700px;
fH=6; %figure hight in cm
fWMax=16; %figure width in cm, genauer 16.8, in HTML max. 700px;
printForm = '-dpng';
printResLow = '-r150';
printResMed = '-r200';
printResHigh = '-r300';

cS=343; %Schallgeschwindigkeit in m/s bei 20 Grad Celsius
nu=1e4; %Beispielfrequenz in Hz

t=1/nu; %Beispielperiode in s
omega=2*pi*nu; %omega=kc in rad/s
k=omega/cS; %Wellenvektor in rad/m
lamb=2*pi/k; %Wellenlänge in m

xAx=-.25:.005:.25; %Ortsachse in m
yShift=2.5; %y-Verschiebung für versetzte Plots zu unterschiedlichen Zeiten

[xMat,tMat]=meshgrid(-.255:.00255:.255,0:750e-8:1500e-6); %je 15 Osz.

%---
[xMat2,yMat]=meshgrid(-.12:.0005:.12,-.12:.0005:.12);
rMat=sqrt(xMat2.^2+yMat.^2);
% vMat=1/k./rMat.*(1+1/1i/k./rMat).*exp(-1i*k*rMat); %Kugelwelle

if 0
    hold on
    for tMult=-5:1:5
        argM=xAx-cS*tMult*t;
        plot(1e3*xAx,f1(k,lamb,argM)-tMult*yShift,'color',[0 0 1])
    end
    xlabel 'x / mm'
    ylabel '\chi / a.u.'
    grid on
    annotation(gcf,'textbox',...
        [0.759 0.497 0.0821 0.0714],...
    'String',{'Zeit'},...
    'LineStyle','none');
    annotation(gcf,'arrow',[0.752 0.752],...
    [0.651 0.395]);
    if printOpt==1
        set(gcf,'PaperPosition', [2 2 fW fH*1.4])
        print(printForm, printResHigh, 'abbWelleBspM')
    end
end

if 0
    figure,hold on
    for tMult=-5:1:5
        argP=xAx+cS*tMult*t;
        plot(1e3*xAx,f2(lamb,argP)-tMult*yShift,'color',[0 1 0])
    end
    xlabel 'x / mm'
    ylabel '\chi / a.u.'
    grid on
    annotation(gcf,'textbox',...
        [0.759 0.497 0.0821 0.0714],...
    'String',{'Zeit'},...
    'LineStyle','none');
    annotation(gcf,'arrow',[0.752 0.752],...
    [0.651 0.395]);
    if printOpt==1
        set(gcf,'PaperPosition', [2 2 fW fH*1.4])
        print(printForm, printResHigh, 'abbWelleBspP')
    end
end

if 0
    figure,hold on
    for tMult=-5:1:5
        argM=xAx-cS*tMult*t;
        plot(1e3*xAx,f1(k,lamb,argM)-tMult*yShift,'color',[.5 .5 1])
        argP=xAx+cS*tMult*t;
        plot(1e3*xAx,f2(lamb,argP)-tMult*yShift,'color',[.5 1 .5])
        plot(1e3*xAx,f1(k,lamb,argM)+f2(lamb,argP)-tMult*yShift,'color',[1 0 0])
    end
    xlabel 'x / mm'
    ylabel '\chi / a.u.'
    grid on
    annotation(gcf,'textbox',...
        [0.759 0.497 0.0821 0.0714],...
    'String',{'Zeit'},...
    'LineStyle','none');
    annotation(gcf,'arrow',[0.752 0.752],...
    [0.651 0.395]);
    if printOpt==1
        set(gcf,'PaperPosition', [2 2 fW fH*1.4])
        print(printForm, printResHigh, 'abbWelleBsp')
    end
end

if 0
    figure,hold on
    imagesc(1e3*xMat(1,:),1e3*tMat(:,1),...
        cos(k*(xMat-cS*tMat))+cos(.8*k*(xMat-cS*tMat)))
    xlabel 'x / mm'
    ylabel 't / ms'
    zlabel '\chi / a.u.'
    colorbar
    axis tight
    if printOpt==1
        set(gcf,'PaperPosition', [2 2 fW*700/600 fH*1.2])
        print(printForm, printResHigh, 'abbWelleInter')
    end
    figure,hold on
    plot(1e3*tMat(:,1),...
        cos(k*(xMat(1,1)-cS*tMat(:,1)))+cos(.8*k*(xMat(:,1)-cS*tMat(:,1))))
    xlabel 't / ms'
    ylabel '\chi / a.u.'
    grid on
    if printOpt==1
        set(gcf,'PaperPosition', [2 2 fW fH])
        print(printForm, printResHigh, 'abbWelleInterVonT')
    end
end

if 1
    iMitte=(length(yMat)+1)/2;
    rVec=rMat(:,iMitte);
    yl=1.0;
    %---
%     figure
%     hold on
%     ylim([-yl yl])
%     xlim([-.1 .1])
%     for ot=0:.2:2*pi
%         plot(yMat(:,iMitte),cos(ot-k*rVec)/k./rVec,'.-')
%         pause%(.1)
%     end
    figure,axis equal tight
    cutArea=ones(size(yMat));
    cutArea(rMat<5.5e-3)=0;
    count=1;
    for ot=pi/6:pi/6:2*pi
        imagesc(1e3*yMat(:,iMitte),1e3*yMat(:,iMitte),cutArea.*cos(ot-k*rMat)/k./rMat,[-yl yl]),colorbar
        xlabel 'x / mm'
        ylabel 'y / mm'
        zlabel 'p / a.u.'
        colorbar
        if printOpt==1
            set(gcf,'PaperPosition', [2 2 fW*.8 fH*.8])
            print(printForm, printResMed, ['abbKugelWelle' num2str(count)])
        end
        count=count+1;
        pause%(.1)
    end
    %animated gif: gimp starten und open as new layer, save as gif
    %grid on
    %axis tight
end

function y=f1(k,lamb,arg)
y=sin(k*arg).*exp(-(arg/(2*lamb)).^2);

function y=f2(lamb,arg)
y=1.5./(1+(arg/(lamb/1)).^2);