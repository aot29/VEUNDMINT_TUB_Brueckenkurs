%  modulSchwingungenRLC erzeugt Abbildungen

%==========================================================================
%
%  Name:        modulSchwingungenRLC.m
%
%  Author:      EH
%  Date:        2012/02/14
%
%  Modifications on 2012/00/00 by EH:
%
%  Bugs, suggestions, remarks:
%
%==========================================================================

function modulSchwingungenRLC()

printOpt=1;
fW=9; %figure width in cm, in HTML max. 700px;
fH=6; %figure hight in cm
fWMax=16; %figure width in cm, genauer 16.8, in HTML max. 700px;
printForm = '-dpng';
printResLow = '-r150';
printResMed = '-r200';
printResHigh = '-r300';

lBsp=1e-6; %Induktivität in H für Beispiel
cBsp=1e-12; %Kapazität in F für Beispiel
omega0Bsp=sqrt(1/lBsp/cBsp); %Kreisfrequenz in rad/s für s. o. (=1/s)
hatUBsp=1; %Scheitelwert der Spannungsquellenspannung in V für s. o.
omegaAxBsp=0:omega0Bsp/40:(2*omega0Bsp);
rBsp=1; %Widerstand in Ohm für s. o.
gammaBsp=rBsp/lBsp; %Dämpfungskonstante in Hz für Berechnung von rho für s. o.

aC=.01; %Kondensatorfläche in m*m
dC=.001; %Kondensatorabstand in m
epsi0=8.854e-12; %elektrische Feldkonstante in F/m
c=epsi0*aC/dC %Kapazität in Aufgabe in F
aL=15e-6; %Spulenquerschnitt in m*m
lL=20e-3; %Spulenlänge in m
nL=20; %Windungszahl
lD=nL*2*sqrt(pi*aL) %Drahtlänge in m
aD=pi*(.0005/2)^2 %Drahtquerschnitt in m^2
sigmaD=6e7; %Leitfähigkeit in S/m
rD=1/sigmaD*lD/aD; %Drahtwiderstand in Ohm
mu0=4*pi*1e-7; %magnetische Feldkonstante in H/m
l=mu0*nL*nL/lL*aL %Induktivität in Aufgabe in H
gammaLD=rD/l; %Dämpfungskonstante in Hz für berechnung von rho etc in Aufg.
omega0=sqrt(1/l/c); %Kreisfrequenz in rad/s für Aufgabe
omegaAx=0:omega0/40:(2*omega0);

if 1; figure
    hold on
    plot(omegaAxBsp,hatUBsp/lBsp./(omega0Bsp.^2-omegaAxBsp.^2),'b-')
%     plot([omega0Bsp omega0Bsp],[-5 5],'m')
    xlabel '\omega/(rad/s)'
    ylabel 'Amplitude / C'
    axis([0 2*omega0Bsp -4*cBsp*hatUBsp 4*cBsp*hatUBsp])
    grid on
    if printOpt==1
        set(gcf,'PaperPosition', [2 2 fW fH])
        print(printForm, printResHigh, 'abbLCUBsp')
    end
end

if 1; figure
    hold on
    plot(omegaAxBsp,hatUBsp/lBsp*omegaAxBsp./(omega0Bsp.^2-omegaAxBsp.^2),'b-')
%     plot([omega0Bsp omega0Bsp],[-5 5],'m')
    xlabel '\omega/(rad/s)'
    ylabel 'Amplitude / A'
    axis([0 2*omega0Bsp -4*cBsp*hatUBsp*omega0Bsp 4*cBsp*hatUBsp*omega0Bsp])
    grid on
    if printOpt==1
        set(gcf,'PaperPosition', [2 2 fW fH])
        print(printForm, printResHigh, 'abbLCUBspI')
    end
end

if 1; figure
    hold on
    plot(omegaAx,hatUBsp/l./(omega0.^2-omegaAx.^2),'b-')
%     plot([omega0Bsp omega0Bsp],[-5 5],'m')
    xlabel '\omega/(rad/s)'
    ylabel 'Amplitude / C'
    axis([0 2*omega0 -4*c*hatUBsp 4*c*hatUBsp])
    grid on
    if printOpt==1
        set(gcf,'PaperPosition', [2 2 fW fH])
        print(printForm, printResHigh, 'abbLCUVorfaktor')
    end
end

if 1; figure
    hold on
    plot(omegaAx,hatUBsp/l*omegaAx./(omega0.^2-omegaAx.^2),'b-')
%     plot([omega0Bsp omega0Bsp],[-5 5],'m')
    xlabel '\omega/(rad/s)'
    ylabel 'Amplitude / A'
    axis([0 2*omega0 -4*c*hatUBsp*omega0 4*c*hatUBsp*omega0])
    grid on
    if printOpt==1
        set(gcf,'PaperPosition', [2 2 fW fH])
        print(printForm, printResHigh, 'abbLCUVorfaktorI')
    end
end

if 1; figure
    hold on
    plot(omegaAxBsp,hatUBsp/lBsp*(1/omega0Bsp.^2-1./omegaAxBsp.^2),'b-')
%     plot([omega0Bsp omega0Bsp],[-5 5],'m')
    xlabel '\omega/(rad/s)'
    ylabel 'Amplitude / C'
    axis([0 2*omega0Bsp -4*cBsp*hatUBsp 1*cBsp*hatUBsp])
    grid on
    if printOpt==1
        set(gcf,'PaperPosition', [2 2 fW fH])
        print(printForm, printResHigh, 'abbLCUParBsp')
    end
end

if 1; figure
    hold on
    plot(omegaAxBsp,hatUBsp*(1./(lBsp*omegaAxBsp)-omegaAxBsp*cBsp),'b-')
%     plot([omega0Bsp omega0Bsp],[-5 5],'m')
    xlabel '\omega/(rad/s)'
    ylabel 'Amplitude / A'
%     axis([0 2*omega0Bsp -4*cBsp*hatUBsp*omega0Bsp 4*cBsp*hatUBsp*omega0Bsp])
    grid on
    if printOpt==1
        set(gcf,'PaperPosition', [2 2 fW fH])
        print(printForm, printResHigh, 'abbLCUParBspI')
    end
end

if 1; figure
    hold on
    plot(omegaAx,hatUBsp/l*(1/omega0.^2-1./omegaAx.^2),'b-')
%     plot([omega0Bsp omega0Bsp],[-5 5],'m')
    xlabel '\omega/(rad/s)'
    ylabel 'Amplitude / C'
    axis([0 2*omega0 -4*c*hatUBsp 1*c*hatUBsp])
    grid on
    if printOpt==1
        set(gcf,'PaperPosition', [2 2 fW fH])
        print(printForm, printResHigh, 'abbLCUParVorfaktor')
    end
end

if 1; figure
    hold on
    plot(omegaAx,hatUBsp*(1./(l*omegaAx)-omegaAx*c),'b-')
%     plot([omega0Bsp omega0Bsp],[-5 5],'m')
    xlabel '\omega/(rad/s)'
    ylabel 'Amplitude / A'
%     axis([0 2*omega0Bsp -4*cBsp*hatUBsp*omega0Bsp 4*cBsp*hatUBsp*omega0Bsp])
    grid on
    if printOpt==1
        set(gcf,'PaperPosition', [2 2 fW fH])
        print(printForm, printResHigh, 'abbLCUParVorfaktorI')
    end
end

if 1; figure
    zaehler=hatUBsp;
    nenner=lBsp*sqrt((omegaAxBsp.^2-omega0Bsp^2).^2+gammaBsp^2*omegaAxBsp.^2);
    vorfaktor=zaehler./nenner;
    hold on
    plot(omegaAxBsp,log10(vorfaktor),'b-')
    plot([omega0Bsp omega0Bsp],[log10(min(vorfaktor)) log10(max(vorfaktor))],'m')
    xlabel '\omega / (rad/s)'
    ylabel 'log_{10} (Amplitude / 1 C)'
    xlim([0 2*omega0Bsp])
    grid on
    if printOpt==1
        set(gcf,'PaperPosition', [2 2 fW fH])
        print(printForm, printResHigh, 'abbRLCUBsp')
    end
end

if 0
    zaehler=omegaAxBsp*gammaBsp;
    nenner=omegaAxBsp.^2-omega0Bsp^2;
    phasenVerschiebung=atan(zaehler./nenner);
    phasenVerschiebung(phasenVerschiebung>0)=...
        phasenVerschiebung(phasenVerschiebung>0)-1*pi;
    plot(omegaAxBsp,phasenVerschiebung,'b-')
    xlabel '\omega/(rad/s)'
    ylabel '\theta / rad'
    xlim([0 2*omega0Bsp])
    ylim([-1.1*pi .1*pi])
    grid on
    if printOpt==1
        set(gcf,'PaperPosition', [2 2 fW fH])
        print(printForm, printResHigh, 'abbRLCPhasenVerschiebungBsp')
    end
end

if 1; figure
    zaehler=hatUBsp;
    nenner=l*sqrt((omegaAx.^2-omega0^2).^2+gammaLD^2*omegaAx.^2);
    vorfaktor=zaehler./nenner;
    hold on
    plot(omegaAx,log10(vorfaktor),'b-')
    plot([omega0 omega0],[log10(min(vorfaktor)) log10(max(vorfaktor))],'m')
    xlabel '\omega / (rad/s)'
    ylabel 'log_{10} (Amplitude / 1 C)'
    xlim([0 2*omega0])
    grid on
    if printOpt==1
        set(gcf,'PaperPosition', [2 2 fW fH])
        print(printForm, printResHigh, 'abbRLCUVorfaktor')
    end
end

if 1; figure
    zaehler=omegaAx*gammaLD;
    nenner=omegaAx.^2-omega0^2;
    phasenVerschiebung=atan(zaehler./nenner);
    phasenVerschiebung(phasenVerschiebung>0)=...
        phasenVerschiebung(phasenVerschiebung>0)-1*pi;
    plot(omegaAx,phasenVerschiebung,'b-')
    xlabel '\omega/(rad/s)'
    ylabel '\theta / rad'
    xlim([0 2*omega0])
    ylim([-1.1*pi .1*pi])
    grid on
    if printOpt==1
        set(gcf,'PaperPosition', [2 2 fW fH])
        print(printForm, printResHigh, 'abbRLCPhasenVerschiebung')
    end
end


