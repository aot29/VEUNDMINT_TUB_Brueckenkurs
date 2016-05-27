%  modulSchwingungen erzeugt Abbildungen

%==========================================================================
%
%  Name:        modulSchwingungen.m
%
%  Author:      EH
%  Date:        2012/01/19
%
%  Modifications on 2013/03/04 by EH: Neue Abb. nach Korrekturen am Ende
%                on 2013/03/07 by EH: Rechnungen in SI
%
%  Bugs, suggestions, remarks:
%
%==========================================================================

function modulSchwingungen()

printOpt=1;
fW=9; %figure width in cm, in HTML max. 700px;
fH=6; %figure hight in cm
fWMax=16; %figure width in cm, genauer 16.8, in HTML max. 700px;
printForm = '-dpng';
printResLow = '-r150';
printResMed = '-r200';
printResHigh = '-r300';

t0=.5; %Periode in Sekunden
tAx=0:t0/50:3; %Zeitachse für Darstellung
x0=10e-3; %Maximale Auslenkung in mm -> m (in SI)
x=x0*cos(2*pi/t0*tAx); %Auslenkung für entsprechende RB
v=-x0*2*pi/t0*sin(2*pi/t0*tAx); %Geschwindigkeit dazu, im mm/s -> m/s (SI)
k=10*1e3; %Kraftkonstante in N/mm -> in N/m (SI)
omega0=2*pi/t0; %Kreisfrequenz in Hz
m=1e0*k*t0^2/(2*pi)^2; %Masse in kg
hatX=1e-3; %Maximale Auslenkung der Federaufhängung in mm -> m (SI)
omegaAx=0:omega0/40:(2*omega0);
gammaReib=4; %Reibungskonstante in Hz für Berechnung von rho
omegaF=10; %Anregungsfrequenz in rad/s
f0=k*hatX; %Amplitude der Anregungskraft in N
deltaF=pi/2; %Phase der Anregungskraft, pi/2 f"ur Sinus
%---
x0Bsp=1; %Max. Auslenkung in m für Beispiele mit Einheitswerten
kBsp=1; %Kraftkonstante in N/m für s. o.
mBsp=1; %Masse in kg für s. o.
omega0Bsp=sqrt(kBsp/mBsp); %Kreisfrequenz in rad/s für s. o. (=1/s)
hatXBsp=1; %Maximale Auslenkung der Aufhängung in m für s. o.
t0Bsp=2*pi/omega0Bsp; %Periode in s für s. o.
tAxBsp=0:t0Bsp/50:t0Bsp; %Zeitachse für die Darstellung
xBsp=x0Bsp*cos(omega0Bsp*tAxBsp); %Auslenkung für entsprechende AB für s. o.
vBsp=-x0Bsp*omega0Bsp*sin(omega0Bsp*tAxBsp); %Geschwindigkeit in m/s für so
omegaAxBsp=0:omega0Bsp/40:(2*omega0Bsp);
gammaReibBsp=1; %Reibungskonstante in Hz für Berechnung von rho für s. o.
%---Neu mit homogener Lsg (Einschwingung) und ggf. partikul"arer Lsg.
omegaD=sqrt(omega0^2-(gammaReib/2)^2);
xD=x0*exp(-gammaReib/2*tAx).*cos(omegaD*tAx); %homogene Lsg ab x0, v0 fast 0
omegaDBsp=sqrt(omega0Bsp^2-(gammaReibBsp/2)^2);
xDBsp=x0Bsp*exp(-gammaReibBsp*tAxBsp/2).*cos(omegaDBsp*tAxBsp); %s.o.
phiF=atan(-omegaF*gammaReib/(omega0^2-omegaF^2)); %Phasenverschiebung partikul"ar
rhoF=1/(m*sqrt((omega0^2-omegaF^2)^2+(omegaF*gammaReib)^2)); %Faktor parikul"ar
%Parameter ab x=v=0:
phiD=atan((omegaF*tan(phiF-deltaF)-gammaReib/2)/omegaD);
cHomogen=-rhoF*f0*cos(phiF-deltaF)/cos(phiD);
%bzw. 
aHomogen=-rhoF*f0*cos(phiF-deltaF);
bHomogen=rhoF*f0*gammaReib/2/omegaD*(2*omegaF/gammaReib*sin(phiF-deltaF)-cos(phiF-deltaF));



%%% Numerische Simulation (mögliche Parameter, ggf. unten geändert)
%---Anfangsbedingungen
xAlt = x0; %Anfangswert der Auslenkung in mm
vAlt = v(1); %Anfangswert der Geschwindigkeit in mm/s
%---Diskretisierung
deltaT=t0/64; %Zeitdiskretisierung in s
tMax=1*max(tAx); %Simulationsdauer in s
nT=round(tMax/deltaT); %Anzahl von Simulationsschritten


if 0
    plot(tAx,x*1e3)
    xlabel 't/s'
    ylabel 'x/mm'
    if printOpt==1
        set(gcf,'PaperPosition', [2 2 fW fH])
        print(printForm, printResHigh, 'abbIntroTX')
    end
end

if 0
    subplot(121)
    plot(tAxBsp,xBsp)
    xlabel 't/s'
    ylabel 'x/m'
    axis tight
    grid on
    subplot(122)
    plot(tAxBsp,vBsp)
    xlabel 't/s'
    ylabel '(dx/dt) / (m/s)'
    axis ([0 t0Bsp -x0Bsp x0Bsp])
    grid on
    if printOpt==1
        set(gcf,'PaperPosition', [2 2 fWMax fH])
        print(printForm, printResHigh, 'abbBspTXTV')
    end
end

if 0
    plot(tAx,v*1e3)
    xlabel 't/s'
    ylabel '(dx/dt) / (mm/s)'
    xlim([0 1])
    grid on
    if printOpt==1
        set(gcf,'PaperPosition', [2 2 fW fH])
        print(printForm, printResHigh, 'abbIntroTV')
    end
end

if 0
    subplot(121)
    plot(x*1e3,-k*x)
    xlabel 'x/mm'
    ylabel 'F/N'
%     xlim([0 1])
    grid on
    subplot(122)
    plot(tAx,-k*x)
    xlabel 't/s'
    ylabel 'F/N'
    xlim([0 1])
    grid on
    if printOpt==1
        set(gcf,'PaperPosition', [2 2 fWMax fH])
        print(printForm, printResHigh, 'abbBetrachtungXFTF')
    end
end

if 0
    hold on
    plot(tAx,.5*k*x.^2,'b-')
    plot(tAx,.5*m*v.^2,'r-.')
    xlabel 't/s'
    ylabel 'E/J'
    legend('E_{pot}','E_{kin}')
    xlim([0 t0])
    grid on
    if printOpt==1
        set(gcf,'PaperPosition', [2 2 fW fH])
        print(printForm, printResHigh, 'abbBetrachtungEpotEkin')
    end
end

if 0
    hold on
    plot(tAxBsp,.5*kBsp*xBsp.^2,'b-')
    plot(tAxBsp,.5*mBsp*vBsp.^2,'r-.')
    xlabel 't/s'
    ylabel 'E/J'
    legend('E_{pot}','E_{kin}')
    xlim([0 t0Bsp])
    grid on
    if printOpt==1
        set(gcf,'PaperPosition', [2 2 fW fH])
        print(printForm, printResHigh, 'abbBetrachtungEpotEkinBsp')
    end
end

if 0 %Abbildung entfaellt
    hold on
    plot(omegaAxBsp,hatXBsp./(1-(omegaAxBsp/omega0Bsp).^2),'b-')
    plot([omega0Bsp omega0Bsp],[-5 5],'m')
    xlabel '\omega/(rad/s)'
    ylabel 'Vorfaktor / m'
    axis([0 2*omega0Bsp -4*x0Bsp 4*x0Bsp])
    grid on
    if printOpt==1
        set(gcf,'PaperPosition', [2 2 fW fH])
        print(printForm, printResHigh, 'abbErzwungenBsp')
    end
end

if 0 %Abbildung entfaellt
    hold on
    plot(omegaAx,1e3*hatX./(1-(omegaAx/omega0).^2),'b-')
    plot([omega0 omega0],[-10 10],'m')
    xlabel '\omega/(rad/s)'
    ylabel 'Vorfaktor / mm'
    axis([0 2*omega0 -x0*1e3 x0*1e3])
    grid on
    if printOpt==1
        set(gcf,'PaperPosition', [2 2 fW fH])
        print(printForm, printResHigh, 'abbErzwungen')
    end
end

if 0
    zaehler=omega0^2*hatX;
    nenner=sqrt((omegaAx.^2-omega0^2).^2+gammaReib^2*omegaAx.^2);
    vorfaktor=zaehler./nenner;
    hold on
    plot(omegaAx,1e3*vorfaktor,'b-')
    plot([omega0 omega0],[0 max(vorfaktor)],'m')
    xlabel '\omega/(rad/s)'
    ylabel 'Vorfaktor / mm'
    xlim([0 2*omega0])
    grid on
    if printOpt==1
        set(gcf,'PaperPosition', [2 2 fW fH])
        print(printForm, printResHigh, 'abbReibung')
    end
end

if 1
    zaehler=omega0Bsp^2*hatXBsp;
    nenner=sqrt((omegaAxBsp.^2-omega0Bsp^2).^2+gammaReibBsp^2*omegaAxBsp.^2);
    vorfaktor=zaehler./nenner;
    hold on
    plot(omegaAxBsp,vorfaktor,'b-')
    plot([omega0Bsp omega0Bsp],[0 max(vorfaktor)],'m')
    xlabel '\omega/(rad/s)'
    ylabel '\rho F_0 / m'
    xlim([0 2*omega0Bsp])
    grid on
    if printOpt==1
        set(gcf,'PaperPosition', [2 2 fW fH])
        print(printForm, printResHigh, 'abbReibungBsp')
    end
end

if 0
    zaehler=omegaAxBsp*gammaReibBsp;
    nenner=omegaAxBsp.^2-omega0Bsp^2;
    phasenVerschiebung=atan(zaehler./nenner);
    phasenVerschiebung(phasenVerschiebung>0)=...
        phasenVerschiebung(phasenVerschiebung>0)-1*pi;
    plot(omegaAxBsp,phasenVerschiebung,'b-')
    xlabel '\omega/(rad/s)'
    ylabel '\theta / rad'
    xlim([0 2*omega0Bsp])
    grid on
    if printOpt==1
        set(gcf,'PaperPosition', [2 2 fW fH])
        print(printForm, printResHigh, 'abbPhasenVerschiebungBsp')
    end
end

if 0
    zaehler=omegaAx*gammaReib;
    nenner=omegaAx.^2-omega0^2;
    phasenVerschiebung=atan(zaehler./nenner);
    phasenVerschiebung(phasenVerschiebung>0)=...
        phasenVerschiebung(phasenVerschiebung>0)-1*pi;
    plot(omegaAx,phasenVerschiebung,'b-')
    xlabel '\omega/(rad/s)'
    ylabel '\theta / rad'
    xlim([0 2*omega0])
    grid on
    if printOpt==1
        set(gcf,'PaperPosition', [2 2 fW fH])
        print(printForm, printResHigh, 'abbPhasenVerschiebung')
    end
end

if 0
    %---Referenzfall ohne äußere Kraft und ohne Reibung
    omega0Q=omega0^2;
    a=-omega0Q*xAlt;
    vHalbAlt=vAlt-a*deltaT/2; %Für Leapfrog, hier Rückwärts, v(0-deltaT/2)
    xAltLF=xAlt; %Variable für Leapfrog Verfahren
    hold on
    for iT=1:nT
        %---Einfache Variante
        a=-omega0Q*xAlt;
        vNeu=vAlt+a*deltaT;
        xNeu=xAlt+vAlt*deltaT;
        xAlt=xNeu;
        vAlt=vNeu;
        %---Variante mit versetzten Diskretisierungspunkte, Fey. S. 127
        aLF=-omega0Q*xAltLF;
        vHalbNeu=vHalbAlt+aLF*deltaT;
        xNeuLF=xAltLF+vHalbNeu*deltaT;
        xAltLF=xNeuLF;
        vHalbAlt=vHalbNeu;
        plot(iT,1e3*xNeu,'b.')
        plot(iT,1e3*xNeuLF,'m.')
        pause(.01)
    end
    xlabel 't / \delta t'
    ylabel 'x / mm'
    xlim([0 nT])
    grid on
    if printOpt==1
        set(gcf,'PaperPosition', [2 2 fW fH])
        print(printForm, printResHigh, 'abbNumVgl')
    end
end

if 0
    %---Es geht los...
    %---Diskretisierung
    nProPeriode=2*32; %Zeitschritte pro Periode der natürlichen Frequenz
    deltaT=t0/nProPeriode; %Zeitdiskretisierung in s
    tMax=14*t0; %Simulationsdauer in s
    nT=round(tMax/deltaT); %Anzahl von Simulationsschritten
    %---Externe Kraft bzw. Auslenkung der Aufhängung
    fExtDurchM = omega0^2*hatX*cos(omegaF*deltaT*(1:nT)-deltaF); %F_extern/m in mm/s^2 -> m/s**2 (SI)
    fExtDurchM((round(nT/2)+1):nT)=fExtDurchM(round(nT/2)); %Aufh"angung stoppt
    %---
    xVec=zeros(1,nT); %für die Darstellung als Linie
    omega0Q=omega0^2;
    xAltLF=0;
    vAlt=0;
    aLF=-gammaReib*vAlt...
        -omega0Q*xAltLF...
        +fExtDurchM(1);
    vHalbAlt=vAlt-aLF*deltaT/2; %Für Leapfrog, hier Rückwärts, v(0-deltaT/2)
    hold on
    for iT=1:nT
        aLF=-gammaReib*vHalbAlt-omega0Q*xAltLF+fExtDurchM(iT);
        vHalbNeu=vHalbAlt+aLF*deltaT;
        xNeuLF=xAltLF+vHalbNeu*deltaT;
        xAltLF=xNeuLF;
        vHalbAlt=vHalbNeu;
        %---
        xVec(iT)=xNeuLF;
    end
    plot(1:nT,1e3*fExtDurchM/omega0Q,'g-.')
    plot(1:nT,1e3*xVec,'b.')
    %analytische Lsg ohne Abschalten
    tAnalyt=deltaT*(1:nT);
%     xAnalyt=cHomogen*exp(-gammaReib*tAnalyt/2).*cos(omegaD*tAnalyt+phiD)...
%         +f0*rhoF*cos(omegaF*tAnalyt-deltaF+phiF);
%     bzw.
    xAnalyt=exp(-gammaReib*tAnalyt/2).*(aHomogen*cos(omegaD*tAnalyt)...
        +bHomogen*sin(omegaD*tAnalyt))+f0*rhoF*cos(omegaF*tAnalyt-deltaF+phiF);
    plot(1:nT,xAnalyt*1e3,'m')
    xlabel 't / \delta t'
    ylabel 'x / mm'
    xlim([0 nT])
    grid on
    if printOpt==1
        set(gcf,'PaperPosition', [2 2 fW fH])
        print(printForm, printResHigh, 'abbNumLFLos')
    end
end

%---

if 0
    plot(tAxBsp,xBsp,'r-.')
    hold on
    plot(tAxBsp,xDBsp)
    xlabel 't/s'
    ylabel 'x/m'
    axis tight
    grid on
    legend('\gamma = 0','\gamma = 1 s^{-1}')
    if printOpt==1
        set(gcf,'PaperPosition', [2 2 fW fH])
        print(printForm, printResHigh, 'abbBspTXD')
    end
end

if 0
    plot(tAx,x,'r-.')
    hold on
    plot(tAx,xD)
    grid on
    xlabel 't/s'
    ylabel 'x/mm'
    legend('\gamma = 0','\gamma = 4 s^{-1}')
    if printOpt==1
        set(gcf,'PaperPosition', [2 2 fW fH])
        print(printForm, printResHigh, 'abbTXD')
    end
end

if 0
%     plot(tAx,x,'r-.')
    hold on
%     plot(tAx,xD,'m-.')
    xAnalyt=cHomogen*exp(-gammaReib*tAx/2).*cos(omegaD*tAx+phiD)...
        +f0*rhoF*cos(omegaF*tAx-deltaF+phiF);
    plot(tAx,xAnalyt*1e3)
    plot(tAx,hatX*cos(omegaF*tAx-deltaF)*1e3,'g-.')
    grid on
    xlabel 't/s'
    ylabel 'x/mm'
%     legend('x_p + x_h','Aufhängung')
    if printOpt==1
        set(gcf,'PaperPosition', [2 2 fW fH])
        print(printForm, printResHigh, 'abbTXDF')
    end
end
