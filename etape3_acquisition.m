%% Étape 3 : acquisition FFT sur les 32 satellites
% Un seul satellite est présent dans le signal (PRN 7). L'acquisition doit
% le trouver, estimer son retard et son Doppler, et rejeter les 31 autres.
clear; clc; close all;
rng(3);

fs = 4.092e6;
[x, ~, vrai] = simuler_signal(7, 'retard', 612.3, 'doppler', -3120, 'CN0', 45, 'fs', fs);

metriques = zeros(1, 32);
for prn = 1:32
    r = acquerir(x, fs, prn);
    metriques(prn) = r.metrique;
    if prn == vrai.prn, resVrai = r; end
end

detectes = find(metriques > 2.5);
fprintf('Satellites détectés : %s\n', mat2str(detectes));
fprintf('\nPRN %d :\n', vrai.prn);
fprintf('  retard  : estimé %.2f chips, vrai %.2f chips (erreur %.2f)\n', ...
        resVrai.retard, vrai.retard, resVrai.retard - vrai.retard);
fprintf('  Doppler : estimé %d Hz, vrai %.0f Hz (erreur %.0f)\n', ...
        resVrai.doppler, vrai.doppler, resVrai.doppler - vrai.doppler);
fprintf('  métrique : %.2f (seuil 2,5)\n', resVrai.metrique);
fprintf('  métrique max des satellites absents : %.2f\n', ...
        max(metriques(setdiff(1:32, vrai.prn))));

if ~exist('figures', 'dir'), mkdir('figures'); end

% Figure 1 : carte d'acquisition du satellite présent
figure;
mesh(resVrai.grilleRetard, resVrai.grilleDoppler/1e3, resVrai.carte);
xlabel('Retard de code (chips)'); ylabel('Doppler (kHz)'); zlabel('|r|^2');
title(sprintf('Carte d''acquisition, PRN %d, C/N_0 = %d dB-Hz', vrai.prn, vrai.CN0));
view(-30, 35);
exportgraphics(gcf, fullfile('figures', 'carte_acquisition.png'));

% Figure 2 : métrique de détection pour les 32 satellites
figure;
bar(1:32, metriques); hold on;
yline(2.5, 'r--', 'Seuil');
xlabel('PRN'); ylabel('Pic principal / pic secondaire');
title('Métrique de détection sur les 32 satellites');
grid on;
dossierFig = fullfile(pwd, 'figures');
if ~isfolder(dossierFig), mkdir(dossierFig); end