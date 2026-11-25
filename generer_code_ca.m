function code = generer_code_ca(prn)
%GENERER_CODE_CA  Code C/A GPS L1 (1023 chips) d'un satellite.
%   code = generer_code_ca(prn) renvoie un vecteur ligne de 1023 chips
%   à valeurs 0/1 pour le satellite prn (1 à 32).
%
%   Deux registres à décalage de 10 bits (LFSR), initialisés à 1 :
%     G1 : polynôme 1 + x^3 + x^10
%     G2 : polynôme 1 + x^2 + x^3 + x^6 + x^8 + x^9 + x^10
%   Le code est G1(10) XOR (G2(s1) XOR G2(s2)), où (s1, s2) sont les
%   prises du sélecteur de phase propres à chaque satellite (IS-GPS-200).

    prises = [ 2  6;  3  7;  4  8;  5  9;  1  9;  2 10;  1  8;  2  9;
               3 10;  2  3;  3  4;  5  6;  6  7;  7  8;  8  9;  9 10;
               1  4;  2  5;  3  6;  4  7;  5  8;  6  9;  1  3;  4  6;
               5  7;  6  8;  7  9;  8 10;  1  6;  2  7;  3  8;  4  9];

    if ~isscalar(prn) || prn < 1 || prn > 32 || prn ~= round(prn)
        error('generer_code_ca:prn', 'prn doit être un entier entre 1 et 32.');
    end

    s  = prises(prn, :);
    g1 = ones(1, 10);
    g2 = ones(1, 10);
    code = zeros(1, 1023);

    for k = 1:1023
        code(k) = xor(g1(10), xor(g2(s(1)), g2(s(2))));
        r1 = xor(g1(3), g1(10));
        r2 = mod(g2(2) + g2(3) + g2(6) + g2(8) + g2(9) + g2(10), 2);
        g1 = [r1, g1(1:9)];
        g2 = [r2, g2(1:9)];
    end
end