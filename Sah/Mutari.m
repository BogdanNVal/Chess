classdef Mutari < handle
    properties
        bitboard Bitboard
        toateMutarile
        numarMutariPosibile
    end


    methods

        
        function obj = Mutari(bitboard)
            %Constructor
            obj.bitboard = bitboard;
            obj.reseteazaMutari;
        end

        function reseteazaMutari(obj)
            obj.numarMutariPosibile = 0;
            obj.toateMutarile = zeros(256, 4);
        end


        
        function generareMutari(obj)
            %genereaza toate mutarile
            obj.reseteazaMutari;
            f = bitget(obj.bitboard.flags, 1);
            pion = obj.bitboard.(char(80+f*32));    % P = 80
            rege = obj.bitboard.(char(75+f*32));    % K = 75
            cal = obj.bitboard.(char(78+f*32));     % N = 78
            nebun = obj.bitboard.(char(66+f*32));   % B = 66
            tura = obj.bitboard.(char(82+f*32));    % R = 82
            regina = obj.bitboard.(char(81+f*32));  % Q = 81

            obj.mutariPion(pion, f);
            obj.mutariSetPiese(rege, f);
            obj.mutariSetPiese(cal, f);
            obj.mutariSetPiese(nebun, f);
            obj.mutariSetPiese(tura, f);
            obj.mutariSetPiese(regina, f);
            obj.valid();

            obj.toateMutarile = obj.toateMutarile(any(obj.toateMutarile, 2), :);
            obj.toateMutarile = sortrows(obj.toateMutarile, [-size(obj.toateMutarile, 2), 3]);
        end


        
        function valid(obj)
            % Elimina mutarile ilegale
            mutariValide = zeros(size(obj.toateMutarile));
            k = 0;

            for i = 1:obj.numarMutariPosibile
                mutare = obj.toateMutarile(i, :);
                obj.bitboard.actualizareTabla(mutare);

                f = bitget(obj.bitboard.flags, 1);
                if f
                    regePoz = find(bitget(obj.bitboard.K, 1:64)) - 1; % rege alb
                else
                    regePoz = find(bitget(obj.bitboard.k, 1:64)) - 1; % rege negru
                end

                if ~obj.patratAtacat(regePoz)
                    k = k + 1;
                    mutariValide(k, :) = mutare;
                end

                obj.bitboard.anulareMutare(mutare);
            end

            obj.toateMutarile = mutariValide(1:k, :);
            obj.numarMutariPosibile = k;
        end


        function bool = patratAtacat(obj, patrat)
            bool = 0;
            f = bitget(obj.bitboard.flags, 1); % 1 = alb, 0 = negru

            % piesele adversarului
            pion = obj.bitboard.(char(80+f*32));
            cal = obj.bitboard.(char(78+f*32));
            nebun = obj.bitboard.(char(66+f*32));
            tura = obj.bitboard.(char(82+f*32));
            regina = obj.bitboard.(char(81+f*32));
            rege = obj.bitboard.(char(75+f*32));

            % Pion
            index = find(bitget(pion, 1:64)) - 1;
            for i = 1:length(index)
                mask = obj.maskPion(index(i), f);
                if bitand(mask, bitshift(1, patrat))
                    bool = 1;

                    return;
                end
            end

            % Cal
            index = find(bitget(cal, 1:64)) - 1;
            for i = 1:length(index)
                mask = obj.maskCal(index(i));
                if bitand(mask, bitshift(1, patrat))

                    bool = 1;
                    return;
                end
            end

            % Nebun
            index = find(bitget(nebun, 1:64)) - 1;
            for i = 1:length(index)
                mask = obj.maskNebun(index(i));
                if bitand(mask, bitshift(1, patrat))

                    bool = 1;
                    return;
                end
            end

            % Tura
            index = find(bitget(tura, 1:64)) - 1;
            for i = 1:length(index)
                mask = obj.maskTura(index(i));
                if bitand(mask, bitshift(1, patrat))

                    bool = 1;
                    return;
                end
            end

            % Regină
            index = find(bitget(regina, 1:64)) - 1;
            for i = 1:length(index)
                mask = bitor(obj.maskTura(index(i)), obj.maskNebun(index(i)));
                if bitand(mask, bitshift(1, patrat))

                    bool = 1;
                    return;
                end
            end

            % Rege
            index = find(bitget(rege, 1:64)) - 1;
            for i = 1:length(index)
                mask = obj.maskRege(index(i));

                if bitand(mask, bitshift(1, patrat))
                    bool = 1;
                    return;
                end
            end
        end

        function bool = sah(obj)

            f = bitget(obj.bitboard.flags, 1);
            obj.bitboard.flags = bitset(uint8(obj.bitboard.flags), 1, ~f);

            if f
                regePoz = find(bitget(obj.bitboard.k, 1:64)) - 1;
            else
                regePoz = find(bitget(obj.bitboard.K, 1:64)) - 1;
            end


            bool = obj.patratAtacat(regePoz);
            obj.bitboard.flags = bitset(uint8(obj.bitboard.flags), 1, f);

        end


        function bool = sahMat(obj)
            obj.generareMutari();
            bool = obj.sah() && obj.numarMutariPosibile == 0;
        end

        function bool = pat(obj)
            obj.generareMutari();
            bool = obj.numarMutariPosibile == 0;
        end

    end

    methods (Access = private)

       
        function mutariPion(obj, piesa, f)
            % genereaza mutarile pionilor
            poz = find(bitget(piesa, 1:64)) - 1;
            for i = 1:length(poz)
                mask = obj.mPion(poz(i), f);
                % mutari unde nu este piesa
                mutariSimple = bitand(mask, bitcmp(obj.bitboard.tabla));
                if mutariSimple
                    obj.mutariSimple(1, poz(i), mutariSimple);
                end
                mask = obj.maskPion(poz(i), f);
                if f
                    capturi = bitand(mask, obj.bitboard.pieseA);
                else

                    capturi = bitand(mask, obj.bitboard.pieseN);
                end
                if capturi
                    obj.capturari(1, poz(i), capturi);
                end
            end
        end

        
        function mutariSetPiese(obj, piesa, f)
            % genereaza mutarile pentru un anumit set de piese
            % [cal, nebun, tura, regina, rege]
            poz = find(bitget(piesa, 1:64)) - 1;
            for i = 1:length(poz)
                v = obj.bitboard.obtineValoare(poz(i));
                mask = obj.getMask(v, poz(i));
                % mutari unde nu este piesa
                mutariSimple = bitand(mask, bitcmp(obj.bitboard.tabla));
                if mutariSimple
                    obj.mutariSimple(v, poz(i), mutariSimple);
                end
                % capturari
                if f
                    capturi = bitand(mask, obj.bitboard.pieseA);
                else
                    capturi = bitand(mask, obj.bitboard.pieseN);
                end
                if capturi
                    obj.capturari(v, poz(i), capturi);
                end
            end
        end


       
        function capturari(obj, piesa, pozI, mutari)
            % returneaza [pozitia initiala, pozitia finala, piesa, piesa capturata
            index = find(bitget(mutari, 1:64));
            for i = 1:length(index)
                piesa_capturata = obj.bitboard.obtineValoare(index(i)-1);
                obj.toateMutarile(obj.numarMutariPosibile+i, :) = [pozI, index(i) - 1, piesa, piesa_capturata];

            end
            obj.numarMutariPosibile = obj.numarMutariPosibile + length(index);
        end

        
        function mutariSimple(obj, piesa, pozI, mutari)
            % returneaza [pozitia initiala, pozitia finala, piesa, piesa capturata
            index = find(bitget(mutari, 1:64));
            for i = 1:length(index)
                obj.toateMutarile(obj.numarMutariPosibile+i, :) = [pozI, index(i) - 1, piesa, 0];
            end
            obj.numarMutariPosibile = obj.numarMutariPosibile + length(index);

        end
    end


   
    methods (Access = private)
        % bitmasks
        
        function mutari = maskPion(~, poz, f)
            mutari = uint64(0);

            if ~f

                if rem(poz+1, 8) % piesa nu pe coloana H
                    mutari = bitor(mutari, bitshift(1, poz+9));
                end
                if rem(poz, 8) % piesa nu pe coloana A
                    mutari = bitor(mutari, bitshift(1, poz+7));
                end
            else
                if rem(poz+1, 8) % piesa nu pe coloana H
                    mutari = bitor(mutari, bitshift(1, poz-7));
                end
                if rem(poz, 8) % piesa nu pe coloana A
                    mutari = bitor(mutari, bitshift(1, poz-9));
                end
            end
        end

        function mutari = mPion(obj, poz, f)

            mutari = uint64(0);
            if ~f

                if ~obj.bitboard.Ocupat(poz+8)
                    mutari = bitor(mutari, bitshift(uint64(1), poz+8)); % mutare un patrat
                    if floor(poz/8) == 1 && ~obj.bitboard.Ocupat(poz+16)
                        mutari = bitor(mutari, bitshift(uint64(1), poz+16)); % mutare 2 patrate
                    end
                end
            else
                if ~obj.bitboard.Ocupat(poz-8)

                    mutari = bitor(mutari, bitshift(uint64(1), poz-8)); % mutare un patrat

                    if floor(poz/8) == 6 && ~obj.bitboard.Ocupat(poz-16)
                        mutari = bitor(mutari, bitshift(uint64(1), poz-16)); % mutare 2 patrate
                    end
                end

            end
        end

        function mutari = maskCal(~, poz)


            mutari = uint64(0);
            if rem(poz+1, 8) %verific ca piesa sa nu fie pe linia H
                mutari = bitor(mutari, bitshift(1, poz+17));
                mutari = bitor(mutari, bitshift(1, poz-15));
            end
            if rem(poz, 8) %verific ca piesa sa nu fie pe linia A
                mutari = bitor(mutari, bitshift(1, poz+15));
                mutari = bitor(mutari, bitshift(1, poz-17));
            end
            if rem(poz, 8) < 6 %verific ca piesa sa nu fie pe linia G sau H
                mutari = bitor(mutari, bitshift(1, poz+10));
                mutari = bitor(mutari, bitshift(1, poz-6));
            end

            if rem(poz, 8) > 1 %verific ca piesa sa nu fie pe linia A sau B
                mutari = bitor(mutari, bitshift(1, poz+6));
                mutari = bitor(mutari, bitshift(1, poz-10));
            end

        end

        function mutari = maskRege(~, poz)
            mutari = uint64(0);
            mutari = bitor(mutari, bitshift(1, poz+8));
            mutari = bitor(mutari, bitshift(1, poz-8));
            if rem(poz+1, 8) % verific ca piesa sa nu fie pe linia H
                mutari = bitor(mutari, bitshift(1, poz+9));
                mutari = bitor(mutari, bitshift(1, poz+1));
                mutari = bitor(mutari, bitshift(1, poz-7));
            end
            if rem(poz, 8) % verific ca piesa sa nu fie pe linia A
                mutari = bitor(mutari, bitshift(1, poz+7));
                mutari = bitor(mutari, bitshift(1, poz-1));
                mutari = bitor(mutari, bitshift(1, poz-9));
            end

        end


        function mutari = maskNebun(obj, poz)
            mutari = uint64(0);
            linie = floor(poz/8);
            coloana = rem(poz, 8);
            l = linie;
            c = coloana;

            while l < 7 && c < 7

                l = l + 1;
                c = c + 1;
                mutari = bitor(mutari, bitshift(1, l*8+c));
                if obj.bitboard.Ocupat(l*8+c)
                    break;
                end

            end

            l = linie;
            c = coloana;

            while l > 0 && c > 0
                l = l - 1;
                c = c - 1;
                mutari = bitor(mutari, bitshift(1, l*8+c));
                if obj.bitboard.Ocupat(l*8+c)
                    break;
                end

            end

            l = linie;
            c = coloana;

            while l < 7 && c > 0
                l = l + 1;
                c = c - 1;
                mutari = bitor(mutari, bitshift(1, l*8+c));
                if obj.bitboard.Ocupat(l*8+c)
                    break;
                end

            end
            l = linie;
            c = coloana;

            while l > 0 && c < 7
                l = l - 1;
                c = c + 1;
                mutari = bitor(mutari, bitshift(1, l*8+c));
                if obj.bitboard.Ocupat(l*8+c)
                    break;
                end
            end
        end

        function mutari = maskTura(obj, poz)
            mutari = uint64(0);
            linie = floor(poz/8);
            coloana = rem(poz, 8);


            for l = linie + 1:7

                mutari = bitor(mutari, bitshift(1, l*8+coloana));
                if obj.bitboard.Ocupat(l*8+coloana)
                    break;
                end
            end

            for l = linie - 1:-1:0

                mutari = bitor(mutari, bitshift(1, l*8+coloana));
                if obj.bitboard.Ocupat(l*8+coloana)
                    break;
                end
            end

            for c = coloana + 1:7

                mutari = bitor(mutari, bitshift(1, linie*8+c));
                if obj.bitboard.Ocupat(linie*8+c)
                    break;
                end
            end

            for c = coloana - 1:-1:0

                mutari = bitor(mutari, bitshift(1, linie*8+c));
                if obj.bitboard.Ocupat(linie*8+c)
                    break;
                end
            end
        end

        function mask = getMask(obj, v, poz)

            switch v

                case 1
                    mask = obj.maskPion(poz);
                case 2
                    mask = obj.maskCal(poz);
                case 3
                    mask = obj.maskNebun(poz);
                case 4
                    mask = obj.maskTura(poz);
                case 5
                    mask = obj.maskNebun(poz);
                    mask = bitor(mask, obj.maskTura(poz));
                case 6
                    mask = obj.maskRege(poz);
            end
        end

        function AfisareTabla(~, tabla)
            fprintf("Tabla "+"\n\n")
            for i = 7:-1:0
                fprintf(i+1+"   ")
                for j = 0:7
                    bit_index = 8 * i + j;


                    if bitand(tabla, bitshift(uint64(1), bit_index)) ~= 0

                        fprintf(" 1 ");
                    else
                        fprintf(" 0 ");
                    end


                end
                fprintf("\n");

            end

            fprintf("\n     ");
            for i = 0:7
                fprintf(i+1+"  ")
            end
            fprintf("\n     ");
        end
    end
end
