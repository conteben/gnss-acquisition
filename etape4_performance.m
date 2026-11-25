%% Étape 4 : performances de l'acquisition (Monte-Carlo)
% Probabilité de détection correcte en fonction du C/N0, pour plusieurs
% durées d'intégration non cohérente, et probabilité de fausse alarme.
% Durée : environ 1 à 3 minutes selon le PC.
clear; clc; close all;
rng(4);

fs      = 4.092e6;
seuil   = 2.5;
listeK  = [1 2 5 10];          % nombre de blocs de 1 ms
listeCN0 = 30:2:48;            % dB-Hz
nEssais = 100;                 % essais par point
prn     = 1;

Pd = zeros(numel(listeK), numel(listeCN0));

for a = 1:numel(listeK)
    K = listeK(a);
    for b = 1:numel(listeCN0)
        succes = 0;
        for e = 1:nEssais
            [x, ~, v] = simuler_signal(prn, 'CN0', listeCN0(b), ...
                                       'duree', K*1e-3, 'fs', fs);
            r = acquerir(x, fs, prn, 'nIncoherent', K, 'seuil', seuil);
            errRetard = mod(r.retard - v.retard + 511.5, 1023) - 511.5;
            correct = r.detecte && abs(errRetard) < 1 ...
                      && abs(r.doppler - v.doppler) < 500;
            succes = succes + correct;
        end
        Pd(a, b) = succes / nEssais;
        fprintf('K = %2d ms, C/N0 = %d dB-Hz : Pd = %.2f\n', K, listeCN0(b), Pd(a, b));
    end
end

% Fausse alarme : satellite absent (bruit seul), intégration 1 ms
nFA = 500;
fa = 0;
for e = 1:nFA
    x = (randn(1, 4092) + 1j*randn(1, 4092)) / sqrt(2);
    r = acquerir(x, fs, prn, 'seuil', seuil);
    fa = fa + r.detecte;
end
fprintf('\nProbabilité de fausse alarme (1 ms, %d essais) : %.3f\n', nFA, fa/nFA);

% Sensibilité : C/N0 minimal pour Pd >= 0,9
fprintf('\nSensibilité (Pd >= 0,9) :\n');
for a = 1:numel(listeK)
    i = find(Pd(a, :) >= 0.9, 1);
    if isempty(i)
        fprintf('  K = %2d ms : > %d dB-Hz\n', listeK(a), listeCN0(end));
    else
        fprintf('  K = %2d ms : %d dB-Hz\n', listeK(a), listeCN0(i));
    end
end

% Figure
dossierFig = fullfile(pwd, 'figures');
if ~isfolder(dossierFig), mkdir(dossierFig); end
figure; hold on; grid on;
for a = 1:numel(listeK)
    plot(listeCN0, Pd(a, :), '-o', 'DisplayName', sprintf('%d ms', listeK(a)));
end
yline(0.9, 'k--', 'P_d = 0,9', 'HandleVisibility', 'off');
xlabel('C/N_0 (dB-Hz)'); ylabel('Probabilité de détection correcte');
title(sprintf('Acquisition FFT : P_d en fonction du C/N_0 (seuil %.1f, %d essais)', seuil, nEssais));
legend('Location', 'southeast');
exportgraphics(gcf, fullfile(dossierFig, 'pd_cn0.png'));

save(fullfile(pwd, 'resultats_etape4.mat'), 'Pd', 'listeK', 'listeCN0', 'seuil', 'nEssais');