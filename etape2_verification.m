%% Étape 2 : vérification du signal simulé
% Le signal est noyé dans le bruit (SNR par échantillon d'environ -21 dB),
% mais la corrélation avec la bonne réplique sur 1 ms le fait ressortir.
clear; clc; close all;
rng(1);                                    % résultats reproductibles

prn = 1;
[x, t, vrai] = simuler_signal(prn, 'retard', 300.5, 'doppler', 2500, 'CN0', 45);
fprintf('SNR par échantillon : %.1f dB\n', vrai.SNR_echantillon_dB);

% Réplique locale : code + porteuse, pour un retard et un Doppler supposés
fc   = 1.023e6;
code = 1 - 2*generer_code_ca(prn);
replique = @(retard, fd) code(mod(floor(fc*t - retard), 1023) + 1) ...
                         .* exp(1j*2*pi*fd*t);
correler = @(retard, fd) abs(sum(x .* conj(replique(retard, fd)))) / numel(x);

fprintf('\nCorrélation normalisée (1 = signal parfaitement aligné) :\n');
fprintf('  bons paramètres          : %.3f\n', correler(300.5, 2500));
fprintf('  Doppler faux de +1000 Hz : %.3f\n', correler(300.5, 3500));
fprintf('  Doppler faux de +250 Hz  : %.3f\n', correler(300.5, 2750));
fprintf('  retard faux de 10 chips  : %.3f\n', correler(310.5, 2500));

% SNR après corrélation : théorique = CN0 + 10 log10(T)
T = numel(x) / vrai.fs;
fprintf('\nSNR après corrélation théorique : %.1f dB\n', vrai.CN0 + 10*log10(T));

% Figure : le signal brut ne montre rien
figure;
plot(t(1:400)*1e6, real(x(1:400)));
xlabel('Temps (\mus)'); ylabel('Re\{x\}');
title(sprintf('Signal reçu, PRN %d, C/N_0 = %d dB-Hz : le code est invisible', prn, vrai.CN0));
grid on;
dossierFig = fullfile(pwd, 'figures');
if ~isfolder(dossierFig), mkdir(dossierFig); end
exportgraphics(gcf, fullfile(dossierFig, 'signal_brut.png'));
 