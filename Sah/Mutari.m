classdef Mutari < handle
    % Generare mutări legale. Format: [from, to, piece, captured, special, promo]
    % special: 0 obișnuit, 1 rocadă KS, 2 rocadă QS, 3 EP, 4 promovare

    properties
        bitboard
        toateMutarile
        numarMutariPosibile
    end

    methods
        function obj = Mutari(bitboard)
            obj.bitboard = bitboard;
            obj.reseteazaMutari();
        end

        function reseteazaMutari(obj)
            obj.numarMutariPosibile = 0;
            obj.toateMutarile = zeros(256, 6);
        end

        function generareMutari(obj, doarCapturi)
            if nargin < 2
                doarCapturi = false;
            end
            obj.reseteazaMutari();
            f = bitget(obj.bitboard.flags, 1);
            pion = obj.bitboard.(char(80+f*32));
            rege = obj.bitboard.(char(75+f*32));
            cal = obj.bitboard.(char(78+f*32));
            nebun = obj.bitboard.(char(66+f*32));
            tura = obj.bitboard.(char(82+f*32));
            regina = obj.bitboard.(char(81+f*32));

            obj.mutariPion(pion, f, doarCapturi);
            obj.mutariSetPiese(rege, f, doarCapturi);
            obj.mutariSetPiese(cal, f, doarCapturi);
            obj.mutariSetPiese(nebun, f, doarCapturi);
            obj.mutariSetPiese(tura, f, doarCapturi);
            obj.mutariSetPiese(regina, f, doarCapturi);
            if ~doarCapturi
                obj.mutariRocada(f);
            end
            obj.valid();
            obj.ordoneazaMutari();
        end

        function valid(obj)
            mutariValide = zeros(size(obj.toateMutarile));
            k = 0;
            for i = 1:obj.numarMutariPosibile
                mutare = obj.toateMutarile(i, :);
                obj.bitboard.actualizareTabla(mutare);

                f = bitget(obj.bitboard.flags, 1); % după mutare: STM e inversat
                if f
                    regePoz = find(bitget(obj.bitboard.K, 1:64), 1) - 1;
                else
                    regePoz = find(bitget(obj.bitboard.k, 1:64), 1) - 1;
                end

                if ~isempty(regePoz) && ~obj.patratAtacat(regePoz)
                    k = k + 1;
                    mutariValide(k, :) = mutare;
                end
                obj.bitboard.anulareMutare(mutare);
            end
            obj.toateMutarile = mutariValide(1:k, :);
            obj.numarMutariPosibile = k;
        end

        function bool = patratAtacat(obj, patrat)
            % După o mutare, bit1 din flags = partea care urmează (atacatorii).
            % Atacatorii sunt partea indicată de f.
            bool = false;
            f = bitget(obj.bitboard.flags, 1); % 1 = negru la mutare = atacuri negre

            pion = obj.bitboard.(char(80+f*32));
            cal = obj.bitboard.(char(78+f*32));
            nebun = obj.bitboard.(char(66+f*32));
            tura = obj.bitboard.(char(82+f*32));
            regina = obj.bitboard.(char(81+f*32));
            rege = obj.bitboard.(char(75+f*32));

            target = bitshift(uint64(1), patrat);

            index = find(bitget(pion, 1:64)) - 1;
            for i = 1:length(index)
                if bitand(obj.maskPion(index(i), f), target)
                    bool = true; return;
                end
            end

            index = find(bitget(cal, 1:64)) - 1;
            for i = 1:length(index)
                if bitand(obj.maskCal(index(i)), target)
                    bool = true; return;
                end
            end

            index = find(bitget(nebun, 1:64)) - 1;
            for i = 1:length(index)
                if bitand(obj.maskNebun(index(i)), target)
                    bool = true; return;
                end
            end

            index = find(bitget(tura, 1:64)) - 1;
            for i = 1:length(index)
                if bitand(obj.maskTura(index(i)), target)
                    bool = true; return;
                end
            end

            index = find(bitget(regina, 1:64)) - 1;
            for i = 1:length(index)
                if bitand(bitor(obj.maskTura(index(i)), obj.maskNebun(index(i))), target)
                    bool = true; return;
                end
            end

            index = find(bitget(rege, 1:64)) - 1;
            for i = 1:length(index)
                if bitand(obj.maskRege(index(i)), target)
                    bool = true; return;
                end
            end
        end

        function bool = sah(obj)
            % Partea la mutare e în șah?
            f = bitget(obj.bitboard.flags, 1);
            % Inversează ca atacatorii să fie adversarul
            obj.bitboard.flags = bitset(uint8(obj.bitboard.flags), 1, ~f);
            if f
                regePoz = find(bitget(obj.bitboard.k, 1:64), 1) - 1;
            else
                regePoz = find(bitget(obj.bitboard.K, 1:64), 1) - 1;
            end
            bool = ~isempty(regePoz) && obj.patratAtacat(regePoz);
            obj.bitboard.flags = bitset(uint8(obj.bitboard.flags), 1, f);
        end

        function bool = sahMat(obj)
            obj.generareMutari();
            bool = obj.sah() && obj.numarMutariPosibile == 0;
        end

        function bool = pat(obj)
            obj.generareMutari();
            bool = ~obj.sah() && obj.numarMutariPosibile == 0;
        end

        function n = perft(obj, depth)
            if depth == 0
                n = 1;
                return;
            end
            obj.generareMutari();
            moves = obj.toateMutarile;
            nr = obj.numarMutariPosibile;
            if depth == 1
                n = nr;
                return;
            end
            n = 0;
            for i = 1:nr
                obj.bitboard.actualizareTabla(moves(i, :));
                n = n + obj.perft(depth - 1);
                obj.bitboard.anulareMutare(moves(i, :));
            end
        end
    end

    methods (Access = private)
        function ordoneazaMutari(obj)
            if obj.numarMutariPosibile <= 1
                return;
            end
            moves = obj.toateMutarile(1:obj.numarMutariPosibile, :);
            f = bitget(obj.bitboard.flags, 1);
            score = zeros(obj.numarMutariPosibile, 1);
            for i = 1:obj.numarMutariPosibile
                % MVV-LVA pentru capturi
                score(i) = 1000 * moves(i, 4) - moves(i, 3);
                if moves(i, 5) == 4
                    score(i) = score(i) + 800 + 50 * moves(i, 6);
                elseif moves(i, 5) == 3
                    score(i) = score(i) + 900;
                elseif moves(i, 5) == 1 || moves(i, 5) == 2
                    score(i) = score(i) + 50; % preferință ușoară pentru rocadă
                else
                    % Mutări liniștite: preferă îmbunătățirea valorii piesă-pătrat (centru)
                    tip = moves(i, 3);
                    if tip >= 1 && tip <= 6
                        d = obj.bitboard.pstDelta(tip, moves(i, 1), moves(i, 2), f);
                        % Din perspectiva STM: albul vrea +d, negrul −d în scorul alb
                        if f
                            score(i) = score(i) - d;
                        else
                            score(i) = score(i) + d;
                        end
                    end
                    % Bonus de dezvoltare: cai/nebuni ieșiți de pe rangul de bază
                    if tip == 2 || tip == 3
                        fromRank = floor(moves(i, 1) / 8);
                        if (~f && fromRank == 0) || (f && fromRank == 7)
                            score(i) = score(i) + 15;
                        end
                    end
                end
            end
            [~, ord] = sort(score, 'descend');
            obj.toateMutarile = moves(ord, :);
        end

        function mutariPion(obj, piesa, f, doarCapturi)
            poz = find(bitget(piesa, 1:64)) - 1;
            for i = 1:length(poz)
                from = poz(i);
                if ~doarCapturi
                    mask = obj.mPion(from, f);
                    mutariSimple = bitand(mask, bitcmp(obj.bitboard.tabla));
                    % Blocarea avansului dublu când cel simplu e blocat e deja tratată în mPion
                    if mutariSimple
                        obj.emitPionQuiet(from, mutariSimple, f);
                    end
                end

                mask = obj.maskPion(from, f);
                if f
                    capturi = bitand(mask, obj.bitboard.pieseA);
                else
                    capturi = bitand(mask, obj.bitboard.pieseN);
                end
                if capturi
                    obj.emitPionCaptures(from, capturi, f);
                end

                % En passant — cere un pion advers pe pătratul de captură (nu pe destinație)
                ep = obj.bitboard.epSquare;
                if ep >= 0 && bitand(mask, bitshift(uint64(1), ep))
                    if f
                        capSq = double(ep) + 8;
                        enemyPawns = obj.bitboard.P;
                    else
                        capSq = double(ep) - 8;
                        enemyPawns = obj.bitboard.p;
                    end
                    if bitand(enemyPawns, bitshift(uint64(1), capSq))
                        obj.addMove([from, double(ep), 1, 1, 3, 0]);
                    end
                end
            end
        end

        function emitPionQuiet(obj, from, bits, f)
            index = find(bitget(bits, 1:64)) - 1;
            for i = 1:length(index)
                to = index(i);
                if obj.isPromoRank(to, f)
                    obj.emitPromos(from, to, 0);
                else
                    obj.addMove([from, to, 1, 0, 0, 0]);
                end
            end
        end

        function emitPionCaptures(obj, from, bits, f)
            index = find(bitget(bits, 1:64)) - 1;
            for i = 1:length(index)
                to = index(i);
                cap = obj.bitboard.obtineValoare(to);
                if obj.isPromoRank(to, f)
                    obj.emitPromos(from, to, cap);
                else
                    obj.addMove([from, to, 1, cap, 0, 0]);
                end
            end
        end

        function emitPromos(obj, from, to, captured)
            for promo = [5, 4, 3, 2] % D T N C (damă, turn, nebun, cal)
                obj.addMove([from, to, 1, captured, 4, promo]);
            end
        end

        function tf = isPromoRank(~, to, f)
            if f
                tf = floor(to/8) == 0;
            else
                tf = floor(to/8) == 7;
            end
        end

        function mutariSetPiese(obj, piesa, f, doarCapturi)
            poz = find(bitget(piesa, 1:64)) - 1;
            for i = 1:length(poz)
                from = poz(i);
                v = obj.bitboard.obtineValoare(from);
                mask = obj.getMask(v, from, f);
                if ~doarCapturi
                    quiet = bitand(mask, bitcmp(obj.bitboard.tabla));
                    if quiet
                        obj.emitQuiet(v, from, quiet);
                    end
                end
                if f
                    capturi = bitand(mask, obj.bitboard.pieseA);
                else
                    capturi = bitand(mask, obj.bitboard.pieseN);
                end
                if capturi
                    obj.emitCaptures(v, from, capturi);
                end
            end
        end

        function mutariRocada(obj, f)
            if obj.sah()
                return; % nu se poate roca din șah
            end
            if ~f
                if bitget(obj.bitboard.flags, 2) % KS
                    if ~obj.bitboard.Ocupat(5) && ~obj.bitboard.Ocupat(6)
                        % tranzit f1,g1 neatacate; atacatorii temporari = negru
                        if obj.squaresSafeForCastle([5, 6], 0)
                            obj.addMove([4, 6, 6, 0, 1, 0]);
                        end
                    end
                end
                if bitget(obj.bitboard.flags, 3) % QS
                    if ~obj.bitboard.Ocupat(3) && ~obj.bitboard.Ocupat(2) && ~obj.bitboard.Ocupat(1)
                        if obj.squaresSafeForCastle([3, 2], 0)
                            obj.addMove([4, 2, 6, 0, 2, 0]);
                        end
                    end
                end
            else
                if bitget(obj.bitboard.flags, 4)
                    if ~obj.bitboard.Ocupat(61) && ~obj.bitboard.Ocupat(62)
                        if obj.squaresSafeForCastle([61, 62], 1)
                            obj.addMove([60, 62, 6, 0, 1, 0]);
                        end
                    end
                end
                if bitget(obj.bitboard.flags, 5)
                    if ~obj.bitboard.Ocupat(59) && ~obj.bitboard.Ocupat(58) && ~obj.bitboard.Ocupat(57)
                        if obj.squaresSafeForCastle([59, 58], 1)
                            obj.addMove([60, 58, 6, 0, 2, 0]);
                        end
                    end
                end
            end
        end

        function ok = squaresSafeForCastle(obj, squares, moverIsBlack)
            % patratAtacat așteaptă flags STM = atacator. Setează STM la adversar.
            saved = obj.bitboard.flags;
            obj.bitboard.flags = bitset(uint8(obj.bitboard.flags), 1, ~moverIsBlack);
            ok = true;
            for i = 1:numel(squares)
                if obj.patratAtacat(squares(i))
                    ok = false;
                    break;
                end
            end
            obj.bitboard.flags = saved;
        end

        function emitCaptures(obj, piece, from, bits)
            index = find(bitget(bits, 1:64)) - 1;
            for i = 1:length(index)
                to = index(i);
                obj.addMove([from, to, piece, obj.bitboard.obtineValoare(to), 0, 0]);
            end
        end

        function emitQuiet(obj, piece, from, bits)
            index = find(bitget(bits, 1:64)) - 1;
            for i = 1:length(index)
                obj.addMove([from, index(i), piece, 0, 0, 0]);
            end
        end

        function addMove(obj, m)
            obj.numarMutariPosibile = obj.numarMutariPosibile + 1;
            if obj.numarMutariPosibile > size(obj.toateMutarile, 1)
                obj.toateMutarile = [obj.toateMutarile; zeros(256, 6)];
            end
            obj.toateMutarile(obj.numarMutariPosibile, :) = m;
        end

        function mutari = maskPion(~, poz, f)
            mutari = uint64(0);
            if ~f
                if rem(poz, 8) ~= 7
                    mutari = bitor(mutari, bitshift(uint64(1), poz+9));
                end
                if rem(poz, 8) ~= 0
                    mutari = bitor(mutari, bitshift(uint64(1), poz+7));
                end
            else
                if rem(poz, 8) ~= 7
                    mutari = bitor(mutari, bitshift(uint64(1), poz-7));
                end
                if rem(poz, 8) ~= 0
                    mutari = bitor(mutari, bitshift(uint64(1), poz-9));
                end
            end
        end

        function mutari = mPion(obj, poz, f)
            mutari = uint64(0);
            if ~f
                if poz <= 55 && ~obj.bitboard.Ocupat(poz+8)
                    mutari = bitor(mutari, bitshift(uint64(1), poz+8));
                    if floor(poz/8) == 1 && ~obj.bitboard.Ocupat(poz+16)
                        mutari = bitor(mutari, bitshift(uint64(1), poz+16));
                    end
                end
            else
                if poz >= 8 && ~obj.bitboard.Ocupat(poz-8)
                    mutari = bitor(mutari, bitshift(uint64(1), poz-8));
                    if floor(poz/8) == 6 && ~obj.bitboard.Ocupat(poz-16)
                        mutari = bitor(mutari, bitshift(uint64(1), poz-16));
                    end
                end
            end
        end

        function mutari = maskCal(~, poz)
            mutari = uint64(0);
            deltas = [17, 15, 10, 6, -6, -10, -15, -17];
            file = rem(poz, 8);
            rank = floor(poz/8);
            for d = deltas
                to = poz + d;
                if to < 0 || to > 63
                    continue;
                end
                tf = rem(to, 8);
                tr = floor(to/8);
                if abs(tf - file) > 2 || abs(tr - rank) > 2
                    continue;
                end
                mutari = bitor(mutari, bitshift(uint64(1), to));
            end
        end

        function mutari = maskRege(~, poz)
            mutari = uint64(0);
            deltas = [8, -8, 1, -1, 9, 7, -7, -9];
            file = rem(poz, 8);
            rank = floor(poz/8);
            for d = deltas
                to = poz + d;
                if to < 0 || to > 63
                    continue;
                end
                tf = rem(to, 8);
                tr = floor(to/8);
                if abs(tf - file) > 1 || abs(tr - rank) > 1
                    continue;
                end
                mutari = bitor(mutari, bitshift(uint64(1), to));
            end
        end

        function mutari = maskNebun(obj, poz)
            mutari = uint64(0);
            linie = floor(poz/8);
            coloana = rem(poz, 8);
            dirs = [1,1; 1,-1; -1,1; -1,-1];
            for d = 1:4
                l = linie; c = coloana;
                while true
                    l = l + dirs(d, 1);
                    c = c + dirs(d, 2);
                    if l < 0 || l > 7 || c < 0 || c > 7
                        break;
                    end
                    sq = l*8 + c;
                    mutari = bitor(mutari, bitshift(uint64(1), sq));
                    if obj.bitboard.Ocupat(sq)
                        break;
                    end
                end
            end
        end

        function mutari = maskTura(obj, poz)
            mutari = uint64(0);
            linie = floor(poz/8);
            coloana = rem(poz, 8);
            for l = linie+1:7
                sq = l*8 + coloana;
                mutari = bitor(mutari, bitshift(uint64(1), sq));
                if obj.bitboard.Ocupat(sq), break; end
            end
            for l = linie-1:-1:0
                sq = l*8 + coloana;
                mutari = bitor(mutari, bitshift(uint64(1), sq));
                if obj.bitboard.Ocupat(sq), break; end
            end
            for c = coloana+1:7
                sq = linie*8 + c;
                mutari = bitor(mutari, bitshift(uint64(1), sq));
                if obj.bitboard.Ocupat(sq), break; end
            end
            for c = coloana-1:-1:0
                sq = linie*8 + c;
                mutari = bitor(mutari, bitshift(uint64(1), sq));
                if obj.bitboard.Ocupat(sq), break; end
            end
        end

        function mask = getMask(obj, v, poz, f)
            switch v
                case 1, mask = obj.maskPion(poz, f);
                case 2, mask = obj.maskCal(poz);
                case 3, mask = obj.maskNebun(poz);
                case 4, mask = obj.maskTura(poz);
                case 5, mask = bitor(obj.maskNebun(poz), obj.maskTura(poz));
                case 6, mask = obj.maskRege(poz);
                otherwise, mask = uint64(0);
            end
        end
    end
end
