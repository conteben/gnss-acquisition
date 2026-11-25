classdef test_code_ca < matlab.unittest.TestCase
    %TEST_CODE_CA  Tests unitaires du générateur de code C/A.
    %   Lancer avec : runtests('test_code_ca')

    methods (Test)

        function longueur_et_valeurs(tc)
            c = generer_code_ca(1);
            tc.verifySize(c, [1 1023]);
            tc.verifyTrue(all(c == 0 | c == 1));
        end

        function premiers_chips_conformes_ICD(tc)
            % 10 premiers chips en octal, table 3-Ia de l'IS-GPS-200
            attendu = {'1440','1620','1710','1744','1133', ...
                       '1455','1131','1454','1626','1504'};
            for prn = 1:10
                c = generer_code_ca(prn);
                obtenu = dec2base(bin2dec(char(c(1:10) + '0')), 8);
                tc.verifyEqual(obtenu, attendu{prn}, ...
                    sprintf('PRN %d : premiers chips incorrects', prn));
            end
        end

        function equilibre(tc)
            % Un code de Gold a 512 « 1 » et 511 « 0 »
            for prn = 1:32
                tc.verifyEqual(sum(generer_code_ca(prn)), 512);
            end
        end

        function autocorrelation(tc)
            % Pic à 1023 ; ailleurs uniquement -65, -1 ou 63
            c = 1 - 2*generer_code_ca(1);
            r = real(ifft(fft(c) .* conj(fft(c))));
            r = round(r);
            tc.verifyEqual(r(1), 1023);
            tc.verifyTrue(all(ismember(r(2:end), [-65 -1 63])));
        end

        function intercorrelation(tc)
            % Deux satellites différents : |corrélation| <= 65
            c1 = 1 - 2*generer_code_ca(1);
            c2 = 1 - 2*generer_code_ca(2);
            r = round(real(ifft(fft(c1) .* conj(fft(c2)))));
            tc.verifyLessThanOrEqual(max(abs(r)), 65);
        end

        function prn_invalide(tc)
            tc.verifyError(@() generer_code_ca(33), 'generer_code_ca:prn');
        end
    end
end