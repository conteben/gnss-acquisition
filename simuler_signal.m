function [x, t, vrai] = simuler_signal(prn, opts)
%SIMULER_SIGNAL  Signal GPS L1 C/A reçu, en bande de base complexe.
%   [x, t, vrai] = simuler_signal(prn, opts)
%
%   Modèle : x(t) = c(t - tau) * exp(j(2*pi*fd*t + phi)) + n(t)
%     c     : code C/A (+1/-1), cadence 1,023 Mchip/s corrigée du Doppler de code
%     tau   : retard de code (en chips)
%     fd    : Doppler porteuse (Hz)
%     n     : bruit blanc gaussien complexe, de densité N0
%   Amplitude du signal = 1, donc puissance C = 1 et N0 = 1 / 10^(CN0/10).
%   Pas de bit de données : on suppose une intégration de 1 ms sans transition.
%
%   Champs de opts (tous facultatifs) :
%     fs        fréquence d'échantillonnage (Hz)       [4.092e6]
%     duree     durée du signal (s)                    [1e-3]
%     retard    retard de code (chips, 0 à 1023)       [aléatoire]
%     doppler   Doppler porteuse (Hz)                  [aléatoire, ±5 kHz]
%     CN0       rapport porteuse sur bruit (dB-Hz)     [45]
%     phase     phase porteuse (rad)                   [aléatoire]
%
%   Sorties : x (signal), t (temps), vrai (paramètres réellement utilisés)

    arguments
        prn (1,1) double
        opts.fs      (1,1) double = 4.092e6
        opts.duree   (1,1) double = 1e-3
        opts.retard  (1,1) double = 1023*rand
        opts.doppler (1,1) double = -5000 + 10000*rand
        opts.CN0     (1,1) double = 45
        opts.phase   (1,1) double = 2*pi*rand
    end

    fc  = 1.023e6;        % cadence de code (chip/s)
    fL1 = 1575.42e6;      % fréquence porteuse L1 (Hz)

    N = round(opts.duree * opts.fs);
    t = (0:N-1) / opts.fs;

    % Code C/A en +1/-1, échantillonné avec retard et Doppler de code
    code   = 1 - 2*generer_code_ca(prn);
    fc_eff = fc * (1 + opts.doppler/fL1);
    idx    = mod(floor(fc_eff*t - opts.retard), 1023) + 1;
    c      = code(idx);

    % Signal utile
    s = c .* exp(1j*(2*pi*opts.doppler*t + opts.phase));

    % Bruit : variance par échantillon complexe = N0 * fs
    N0     = 1 / 10^(opts.CN0/10);
    sigma2 = N0 * opts.fs;
    n      = sqrt(sigma2/2) * (randn(1,N) + 1j*randn(1,N));

    x = s + n;

    vrai = struct('prn', prn, 'retard', opts.retard, 'doppler', opts.doppler, ...
                  'CN0', opts.CN0, 'phase', opts.phase, 'fs', opts.fs, ...
                  'SNR_echantillon_dB', 10*log10(1/sigma2));
end