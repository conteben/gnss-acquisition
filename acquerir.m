function res = acquerir(x, fs, prn, opts)
%ACQUERIR  Acquisition d'un satellite GPS par recherche parallèle en code (FFT).
%   res = acquerir(x, fs, prn) cherche le satellite prn dans 1 ms de signal x.
%
%   Pour chaque case Doppler fd de la grille :
%     1. on retire la porteuse : y = x .* exp(-j 2 pi fd t)
%     2. on corrèle y avec le code local pour TOUS les retards à la fois :
%        r = IFFT( FFT(y) .* conj(FFT(code_local)) )
%   La carte |r|^2 (Doppler x retard) présente un pic si le satellite est là.
%
%   Métrique de détection : rapport pic principal / plus grand pic secondaire
%   dans la même ligne Doppler, hors de ±1 chip autour du pic principal.
%
%   Champs de opts (facultatifs) :
%     dopplerMax   demi-largeur de recherche (Hz)   [7000]
%     pasDoppler   pas de la grille (Hz)            [500]
%     seuil        seuil de détection               [2.5]
%     nIncoherent  nombre de blocs de 1 ms sommés en puissance
%                  (intégration non cohérente)      [1]
%
%   Sortie res : prn, detecte, metrique, retard (chips), doppler (Hz),
%                carte, grilleDoppler, grilleRetard

    arguments
        x   (1,:) double
        fs  (1,1) double
        prn (1,1) double
        opts.dopplerMax (1,1) double = 7000
        opts.pasDoppler (1,1) double = 500
        opts.seuil      (1,1) double = 2.5
        opts.nIncoherent (1,1) double {mustBeInteger, mustBePositive} = 1
    end

    fc = 1.023e6;
    N  = round(1e-3 * fs);          % 1 ms = une période de code
    K  = opts.nIncoherent;
    if numel(x) < K*N
        error('acquerir:longueur', 'Il faut au moins %d ms de signal.', K);
    end
    t  = (0:N-1) / fs;

    % Code local échantillonné (retard nul), puis sa FFT conjuguée
    code   = 1 - 2*generer_code_ca(prn);
    locale = code(mod(floor(fc*t), 1023) + 1);
    Floc   = conj(fft(locale));

    grilleDoppler = -opts.dopplerMax : opts.pasDoppler : opts.dopplerMax;
    carte = zeros(numel(grilleDoppler), N);

    % Intégration non cohérente : somme des cartes |r|^2 de K blocs de 1 ms.
    % La phase de chaque bloc est perdue (module), mais le bruit est moyenné.
    for b = 1:K
        xb = x((b-1)*N + (1:N));
        for i = 1:numel(grilleDoppler)
            y = xb .* exp(-1j*2*pi*grilleDoppler(i)*t);
            carte(i, :) = carte(i, :) + abs(ifft(fft(y) .* Floc)).^2;
        end
    end

    % Pic principal
    [pic, ind] = max(carte(:));
    [iD, k]    = ind2sub(size(carte), ind);

    % Pic secondaire : même ligne Doppler, en excluant ±1 chip autour du pic
    ligne = carte(iD, :);
    nChip = round(fs / fc);                       % échantillons par chip
    exclus = mod((k-1) + (-nChip:nChip), N) + 1;
    ligne(exclus) = 0;
    metrique = pic / max(ligne);

    res = struct( ...
        'prn',           prn, ...
        'detecte',       metrique > opts.seuil, ...
        'metrique',      metrique, ...
        'retard',        (k-1) * fc / fs, ...      % en chips
        'doppler',       grilleDoppler(iD), ...    % en Hz
        'carte',         carte, ...
        'grilleDoppler', grilleDoppler, ...
        'grilleRetard',  (0:N-1) * fc / fs);
end