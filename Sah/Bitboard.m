classdef Bitboard < handle
    % Poziție pe bitboards. Format mutare: [from, to, piece, captured, special, promo]
    % special: 0 obișnuit, 1 rocadă pe flancul regelui (KS), 2 rocadă pe flancul damei (QS),
    %          3 en passant, 4 promovare

    properties
        % Piese albe
        P
        N
        B
        R
        K
        Q

        % Piese negre
        p
        n
        b
        r
        k
        q

        pieseA
        pieseN
        tabla

        flags     % bit1: cine mută (STM; 1=negru); biții 2–5: drepturi de rocadă KQkq
        epSquare    % -1 = niciun EP; altfel pătrat 0..63

        % Istoric pentru anulare: [flags, epSquare] la fiecare make
        istoric
        istoricLen

        % Material + PST incremental (alb − negru)
        material
        pstScore

        % Cheie Zobrist a poziției
        zobristKey
    end

    properties (Constant)
        % tip piesă -> ASCII majusculă: P N B R Q K
        PIECE_ASCII = [80, 78, 66, 82, 81, 75]
        VAL_PION = 100
        VAL_CAL = 300
        VAL_NEBUN = 310
        VAL_TURA = 500
        VAL_REGINA = 900
        VAL_REGE = 10000
    end

    properties
        % Public pentru ordonarea mutărilor: delta PST (6×64, perspectiva albului, a1=0)
        pst
    end

    properties (Access = private)
        zobristPieces   % 12 × 64
        zobristSide
        zobristCastle   % 16 stări de rocadă
        zobristEp       % 8 fișiere
        istoricZobrist  % stivă uint64 paralelă cu istoric
    end

    methods
        function obj = Bitboard(fen)
            obj.initZobrist();
            obj.initPst();
            obj.istoric = zeros(512, 2);
            obj.istoricZobrist = zeros(512, 1, 'uint64');
            obj.istoricLen = 0;
            obj.FEN(fen);
        end

        function reseteaza(obj)
            obj.P = uint64(0); obj.N = uint64(0); obj.B = uint64(0);
            obj.R = uint64(0); obj.K = uint64(0); obj.Q = uint64(0);
            obj.p = uint64(0); obj.n = uint64(0); obj.b = uint64(0);
            obj.r = uint64(0); obj.k = uint64(0); obj.q = uint64(0);
            obj.pieseA = uint64(0);
            obj.pieseN = uint64(0);
            obj.tabla = uint64(0);
            obj.flags = uint8(0);
            obj.epSquare = int32(-1);
            obj.istoricLen = 0;
            obj.material = int32(0);
            obj.pstScore = 0;
            obj.zobristKey = uint64(0);
        end

        function delta = pstDelta(obj, tip, from, to, isBlack)
            % Câștig pozițional la mutarea tip from→to (pozitiv pentru alb)
            if isBlack
                delta = obj.pst(tip, bitxor(to, 56)+1) - obj.pst(tip, bitxor(from, 56)+1);
                delta = -delta;
            else
                delta = obj.pst(tip, to+1) - obj.pst(tip, from+1);
            end
        end

        function FEN(obj, fen)
            obj.reseteaza();
            linie = 7;
            coloana = 0;
            str = strsplit(fen, ' ');
            piese = str{1};

            for i = 1:length(piese)
                if piese(i) == '/'
                    linie = linie - 1;
                    coloana = 0;
                elseif piese(i) >= '0' && piese(i) <= '9'
                    coloana = coloana + str2double(piese(i));
                else
                    obj.(piese(i)) = bitset(obj.(piese(i)), 8*linie+coloana+1);
                    obj.tabla = bitset(obj.tabla, 8*linie+coloana+1);
                    if piese(i) >= 'a' && piese(i) <= 'z'
                        obj.pieseN = bitset(obj.pieseN, 8*linie+coloana+1);
                    else
                        obj.pieseA = bitset(obj.pieseA, 8*linie+coloana+1);
                    end
                    coloana = coloana + 1;
                end
            end

            if numel(str) >= 2 && str{2} == 'b'
                obj.flags = bitset(obj.flags, 1);
            end

            if numel(str) >= 3
                flag = str{3};
                for i = 1:length(flag)
                    switch flag(i)
                        case 'K', obj.flags = bitset(obj.flags, 2);
                        case 'Q', obj.flags = bitset(obj.flags, 3);
                        case 'k', obj.flags = bitset(obj.flags, 4);
                        case 'q', obj.flags = bitset(obj.flags, 5);
                    end
                end
            end

            obj.epSquare = int32(-1);
            if numel(str) >= 4 && ~strcmp(str{4}, '-')
                obj.epSquare = int32(obj.algebraicToSquare(str{4}));
            end

            obj.recomputeMaterial();
            obj.recomputePst();
            obj.recomputeZobrist();
        end

        function ocupat = Ocupat(obj, poz)
            ocupat = bitand(obj.tabla, bitshift(uint64(1), poz)) ~= 0;
        end

        function piesa = obtinePiesa(obj, poz)
            piesa = '0';
            bit = bitshift(uint64(1), poz);
            if bitand(obj.P, bit), piesa = 'P';
            elseif bitand(obj.N, bit), piesa = 'N';
            elseif bitand(obj.B, bit), piesa = 'B';
            elseif bitand(obj.R, bit), piesa = 'R';
            elseif bitand(obj.K, bit), piesa = 'K';
            elseif bitand(obj.Q, bit), piesa = 'Q';
            elseif bitand(obj.p, bit), piesa = 'p';
            elseif bitand(obj.n, bit), piesa = 'n';
            elseif bitand(obj.b, bit), piesa = 'b';
            elseif bitand(obj.r, bit), piesa = 'r';
            elseif bitand(obj.k, bit), piesa = 'k';
            elseif bitand(obj.q, bit), piesa = 'q';
            end
        end

        function piesa = obtineValoare(obj, poz)
            % 1-pion, 2-cal, 3-nebun, 4-tura, 5-regina, 6-rege
            bit = bitshift(uint64(1), poz);
            if bitand(obj.P, bit) || bitand(obj.p, bit)
                piesa = 1;
            elseif bitand(obj.N, bit) || bitand(obj.n, bit)
                piesa = 2;
            elseif bitand(obj.B, bit) || bitand(obj.b, bit)
                piesa = 3;
            elseif bitand(obj.R, bit) || bitand(obj.r, bit)
                piesa = 4;
            elseif bitand(obj.Q, bit) || bitand(obj.q, bit)
                piesa = 5;
            elseif bitand(obj.K, bit) || bitand(obj.k, bit)
                piesa = 6;
            else
                piesa = 0;
            end
        end

        function actualizareTabla(obj, mutare)
            % mutare: [from, to, piece, captured, special, promo]
            mutare = obj.normalizeMove(mutare);
            from = mutare(1); to = mutare(2);
            piece = mutare(3); captured = mutare(4);
            special = mutare(5); promo = mutare(6);

            obj.pushHistory();

            f = bitget(obj.flags, 1); % 0 alb, 1 negru
            fromBit = bitshift(uint64(1), from);
            toBit = bitshift(uint64(1), to);

            % Șterge EP implicit; se poate seta din nou după avansul dublu al pionului
            oldEp = obj.epSquare;
            if oldEp >= 0
                obj.zobristXorEp(oldEp);
            end
            obj.epSquare = int32(-1);

            switch special
                case 1 % rocadă pe flancul regelui
                    obj.movePieceBits(piece, f, from, to);
                    if f
                        obj.movePieceBits(4, f, 63, 61); % h8→f8
                    else
                        obj.movePieceBits(4, f, 7, 5);   % h1→f1
                    end
                    obj.clearCastlingForSide(f);

                case 2 % rocadă pe flancul damei
                    obj.movePieceBits(piece, f, from, to);
                    if f
                        obj.movePieceBits(4, f, 56, 59); % a8→d8
                    else
                        obj.movePieceBits(4, f, 0, 3);   % a1→d1
                    end
                    obj.clearCastlingForSide(f);

                case 3 % en passant — pionul capturat e pe alt pătrat decât destinația
                    if f
                        capSq = to + 8;
                    else
                        capSq = to - 8;
                    end
                    obj.removePieceBits(1, ~f, capSq); % scoate pionul advers
                    obj.movePieceBits(1, f, from, to);
                    obj.updateCastlingRightsOnMove(piece, f, from, to, 1, ~f, capSq);

                case 4 % promovare
                    if captured
                        obj.removePieceBits(captured, ~f, to);
                    end
                    obj.removePieceBits(1, f, from);
                    obj.placePieceBits(promo, f, to);
                    obj.updateCastlingRightsOnMove(1, f, from, to, captured, ~f, to);

                otherwise
                    if captured
                        obj.removePieceBits(captured, ~f, to);
                    end
                    obj.movePieceBits(piece, f, from, to);
                    obj.updateCastlingRightsOnMove(piece, f, from, to, captured, ~f, to);

                    % Avans dublu de pion → setează pătratul EP
                    if piece == 1 && abs(to - from) == 16
                        obj.epSquare = int32((from + to) / 2);
                        obj.zobristXorEp(obj.epSquare);
                    end
            end

            obj.flags = bitxor(obj.flags, uint8(1));
            obj.zobristKey = bitxor(obj.zobristKey, obj.zobristSide);
        end

        function anulareMutare(obj, mutare)
            mutare = obj.normalizeMove(mutare);
            from = mutare(1); to = mutare(2);
            piece = mutare(3); captured = mutare(4);
            special = mutare(5); promo = mutare(6);

            [savedFlags, savedEp, savedZob] = obj.popHistory();
            f = bitget(savedFlags, 1);

            switch special
                case 1
                    obj.movePieceBits(piece, f, to, from);
                    if f
                        obj.movePieceBits(4, f, 61, 63);
                    else
                        obj.movePieceBits(4, f, 5, 7);
                    end

                case 2
                    obj.movePieceBits(piece, f, to, from);
                    if f
                        obj.movePieceBits(4, f, 59, 56);
                    else
                        obj.movePieceBits(4, f, 3, 0);
                    end

                case 3
                    obj.movePieceBits(1, f, to, from);
                    if f
                        capSq = to + 8;
                    else
                        capSq = to - 8;
                    end
                    obj.placePieceBits(1, ~f, capSq);

                case 4
                    obj.removePieceBits(promo, f, to);
                    obj.placePieceBits(1, f, from);
                    if captured
                        obj.placePieceBits(captured, ~f, to);
                    end

                otherwise
                    obj.movePieceBits(piece, f, to, from);
                    if captured
                        obj.placePieceBits(captured, ~f, to);
                    end
            end

            % Restaurează meta + snapshot Zobrist exact (evită reconstrucție O(piese))
            obj.flags = savedFlags;
            obj.epSquare = savedEp;
            obj.zobristKey = savedZob;
        end

        function scor = evaluareTabla(obj)
            scor = double(obj.material) + obj.pstScore;
        end

        function n = avantajMaterial(obj)
            % Avantaj material în unități de pion (alb - negru). Regii sunt ignorați.
            % Greutăți: P=1, N/B=3, R=5, Q=9.
            n = obj.popcount(obj.P) + 3 * obj.popcount(obj.N) + 3 * obj.popcount(obj.B) ...
                + 5 * obj.popcount(obj.R) + 9 * obj.popcount(obj.Q) ...
                - obj.popcount(obj.p) - 3 * obj.popcount(obj.n) - 3 * obj.popcount(obj.b) ...
                - 5 * obj.popcount(obj.r) - 9 * obj.popcount(obj.q);
        end

        function nullMoveBegin(obj)
            obj.pushHistory();
            if obj.epSquare >= 0
                obj.zobristXorEp(obj.epSquare);
            end
            obj.epSquare = int32(-1);
            obj.flags = bitxor(obj.flags, uint8(1));
            obj.zobristKey = bitxor(obj.zobristKey, obj.zobristSide);
        end

        function nullMoveEnd(obj)
            [savedFlags, savedEp, savedZob] = obj.popHistory();
            obj.flags = savedFlags;
            obj.epSquare = savedEp;
            obj.zobristKey = savedZob;
        end

        function disp(obj)
            fprintf('Tabla:\n');
            for i = 7:-1:0
                for j = 0:7
                    fprintf(' %s', obj.obtinePiesa(8*i+j));
                end
                fprintf('\n');
            end
        end
    end

    methods (Access = private)
        function m = normalizeMove(~, mutare)
            m = zeros(1, 6);
            n = numel(mutare);
            m(1:n) = mutare(1:n);
        end

        function pushHistory(obj)
            obj.istoricLen = obj.istoricLen + 1;
            if obj.istoricLen > size(obj.istoric, 1)
                obj.istoric = [obj.istoric; zeros(512, 2)];
                obj.istoricZobrist = [obj.istoricZobrist; zeros(512, 1, 'uint64')];
            end
            obj.istoric(obj.istoricLen, 1) = double(obj.flags);
            obj.istoric(obj.istoricLen, 2) = double(obj.epSquare);
            obj.istoricZobrist(obj.istoricLen) = obj.zobristKey;
        end

        function [flags, ep, zob] = popHistory(obj)
            flags = uint8(obj.istoric(obj.istoricLen, 1));
            ep = int32(obj.istoric(obj.istoricLen, 2));
            zob = obj.istoricZobrist(obj.istoricLen);
            obj.istoricLen = obj.istoricLen - 1;
        end

        function code = pieceCode(~, tip, isBlack)
            code = Bitboard.PIECE_ASCII(tip);
            if isBlack
                code = code + 32;
            end
        end

        function val = pieceValue(~, tip)
            switch tip
                case 1, val = Bitboard.VAL_PION;
                case 2, val = Bitboard.VAL_CAL;
                case 3, val = Bitboard.VAL_NEBUN;
                case 4, val = Bitboard.VAL_TURA;
                case 5, val = Bitboard.VAL_REGINA;
                case 6, val = Bitboard.VAL_REGE;
                otherwise, val = 0;
            end
        end

        function movePieceBits(obj, tip, isBlack, from, to)
            obj.removePieceBits(tip, isBlack, from);
            obj.placePieceBits(tip, isBlack, to);
        end

        function removePieceBits(obj, tip, isBlack, sq)
            bit = bitshift(uint64(1), sq);
            code = char(obj.pieceCode(tip, isBlack));
            % Șterge biții (nu XOR): scoaterea de pe un pătrat gol trebuie să fie no-op
            if bitand(obj.(code), bit) == 0
                return;
            end
            mask = bitcmp(bit);
            obj.(code) = bitand(obj.(code), mask);
            obj.tabla = bitand(obj.tabla, mask);
            if isBlack
                obj.pieseN = bitand(obj.pieseN, mask);
                obj.material = obj.material + int32(obj.pieceValue(tip));
                obj.pstScore = obj.pstScore + obj.pst(tip, bitxor(sq, 56)+1);
            else
                obj.pieseA = bitand(obj.pieseA, mask);
                obj.material = obj.material - int32(obj.pieceValue(tip));
                obj.pstScore = obj.pstScore - obj.pst(tip, sq+1);
            end
            obj.zobristXorPiece(tip, isBlack, sq);
        end

        function placePieceBits(obj, tip, isBlack, sq)
            bit = bitshift(uint64(1), sq);
            code = char(obj.pieceCode(tip, isBlack));
            % Deja ocupat de același tip: evită dublarea material/PST/Zobrist
            if bitand(obj.(code), bit) ~= 0
                return;
            end
            obj.(code) = bitor(obj.(code), bit);
            obj.tabla = bitor(obj.tabla, bit);
            if isBlack
                obj.pieseN = bitor(obj.pieseN, bit);
                obj.material = obj.material - int32(obj.pieceValue(tip));
                obj.pstScore = obj.pstScore - obj.pst(tip, bitxor(sq, 56)+1);
            else
                obj.pieseA = bitor(obj.pieseA, bit);
                obj.material = obj.material + int32(obj.pieceValue(tip));
                obj.pstScore = obj.pstScore + obj.pst(tip, sq+1);
            end
            obj.zobristXorPiece(tip, isBlack, sq);
        end

        function clearCastlingForSide(obj, isBlack)
            oldIdx = obj.castleHashIndex();
            if isBlack
                if bitget(obj.flags, 4), obj.flags = bitset(obj.flags, 4, 0); end
                if bitget(obj.flags, 5), obj.flags = bitset(obj.flags, 5, 0); end
            else
                if bitget(obj.flags, 2), obj.flags = bitset(obj.flags, 2, 0); end
                if bitget(obj.flags, 3), obj.flags = bitset(obj.flags, 3, 0); end
            end
            newIdx = obj.castleHashIndex();
            if oldIdx ~= newIdx
                obj.zobristKey = bitxor(obj.zobristKey, obj.zobristCastle(oldIdx));
                obj.zobristKey = bitxor(obj.zobristKey, obj.zobristCastle(newIdx));
            end
        end

        function updateCastlingRightsOnMove(obj, piece, isBlack, from, to, captured, capIsBlack, capSq)
            oldIdx = obj.castleHashIndex();
            changed = false;
            if piece == 6
                if isBlack
                    if bitget(obj.flags, 4), obj.flags = bitset(obj.flags, 4, 0); changed = true; end
                    if bitget(obj.flags, 5), obj.flags = bitset(obj.flags, 5, 0); changed = true; end
                else
                    if bitget(obj.flags, 2), obj.flags = bitset(obj.flags, 2, 0); changed = true; end
                    if bitget(obj.flags, 3), obj.flags = bitset(obj.flags, 3, 0); changed = true; end
                end
            end
            if piece == 4
                if ~isBlack
                    if from == 7 && bitget(obj.flags, 2)
                        obj.flags = bitset(obj.flags, 2, 0); changed = true;
                    elseif from == 0 && bitget(obj.flags, 3)
                        obj.flags = bitset(obj.flags, 3, 0); changed = true;
                    end
                else
                    if from == 63 && bitget(obj.flags, 4)
                        obj.flags = bitset(obj.flags, 4, 0); changed = true;
                    elseif from == 56 && bitget(obj.flags, 5)
                        obj.flags = bitset(obj.flags, 5, 0); changed = true;
                    end
                end
            end
            if captured == 4
                if ~capIsBlack
                    if capSq == 7 && bitget(obj.flags, 2)
                        obj.flags = bitset(obj.flags, 2, 0); changed = true;
                    elseif capSq == 0 && bitget(obj.flags, 3)
                        obj.flags = bitset(obj.flags, 3, 0); changed = true;
                    end
                else
                    if capSq == 63 && bitget(obj.flags, 4)
                        obj.flags = bitset(obj.flags, 4, 0); changed = true;
                    elseif capSq == 56 && bitget(obj.flags, 5)
                        obj.flags = bitset(obj.flags, 5, 0); changed = true;
                    end
                end
            end
            if changed
                newIdx = obj.castleHashIndex();
                obj.zobristKey = bitxor(obj.zobristKey, obj.zobristCastle(oldIdx));
                obj.zobristKey = bitxor(obj.zobristKey, obj.zobristCastle(newIdx));
            end
            %#ok<*INUSD>
            to;
        end

        function recomputeMaterial(obj)
            obj.material = int32(0);
            obj.material = obj.material + int32(Bitboard.VAL_PION) * int32(obj.popcount(obj.P) - obj.popcount(obj.p));
            obj.material = obj.material + int32(Bitboard.VAL_CAL) * int32(obj.popcount(obj.N) - obj.popcount(obj.n));
            obj.material = obj.material + int32(Bitboard.VAL_NEBUN) * int32(obj.popcount(obj.B) - obj.popcount(obj.b));
            obj.material = obj.material + int32(Bitboard.VAL_TURA) * int32(obj.popcount(obj.R) - obj.popcount(obj.r));
            obj.material = obj.material + int32(Bitboard.VAL_REGINA) * int32(obj.popcount(obj.Q) - obj.popcount(obj.q));
            obj.material = obj.material + int32(Bitboard.VAL_REGE) * int32(obj.popcount(obj.K) - obj.popcount(obj.k));
        end

        function n = popcount(~, bb)
            % bitget e fiabil pe uint64 în versiunile MATLAB
            n = sum(bitget(uint64(bb), 1:64));
        end

        function sq = algebraicToSquare(~, alg)
            file = lower(alg(1)) - 'a';
            rank = str2double(alg(2)) - 1;
            sq = rank * 8 + file;
        end

        function recomputePst(obj)
            obj.pstScore = 0;
            obj.pstScore = obj.pstScore + obj.pstSide(obj.P, 1, false) - obj.pstSide(obj.p, 1, true);
            obj.pstScore = obj.pstScore + obj.pstSide(obj.N, 2, false) - obj.pstSide(obj.n, 2, true);
            obj.pstScore = obj.pstScore + obj.pstSide(obj.B, 3, false) - obj.pstSide(obj.b, 3, true);
            obj.pstScore = obj.pstScore + obj.pstSide(obj.R, 4, false) - obj.pstSide(obj.r, 4, true);
            obj.pstScore = obj.pstScore + obj.pstSide(obj.Q, 5, false) - obj.pstSide(obj.q, 5, true);
            obj.pstScore = obj.pstScore + obj.pstSide(obj.K, 6, false) - obj.pstSide(obj.k, 6, true);
        end

        function initPst(obj)
            % Control mai puternic al centrului — deschiderea preferă pionii d/e și cai dezvoltați
            % Rândurile = rang8..rang1 (vizual), apoi convertite la index a1=0
            pawn = [
                0,  0,  0,  0,  0,  0,  0,  0
               80, 80, 80, 80, 80, 80, 80, 80
               20, 20, 30, 45, 45, 30, 20, 20
               10, 10, 20, 40, 40, 20, 10, 10
                5,  5, 15, 35, 35, 15,  5,  5
                5, -5,-10, 10, 10,-10, -5,  5
                5, 10, 10,-25,-25, 10, 10,  5
                0,  0,  0,  0,  0,  0,  0,  0
            ];
            knight = [
               -50,-40,-30,-30,-30,-30,-40,-50
               -40,-20,  0,  5,  5,  0,-20,-40
               -30,  5, 15, 20, 20, 15,  5,-30
               -30, 10, 20, 25, 25, 20, 10,-30
               -30,  5, 20, 25, 25, 20,  5,-30
               -30,  5, 15, 20, 20, 15,  5,-30
               -40,-20,  0, 10, 10,  0,-20,-40
               -50,-40,-20,-20,-20,-20,-40,-50
            ];
            bishop = [
               -20,-10,-10,-10,-10,-10,-10,-20
               -10,  5,  0,  0,  0,  0,  5,-10
               -10, 10, 10, 15, 15, 10, 10,-10
               -10,  0, 15, 20, 20, 15,  0,-10
               -10,  5, 10, 20, 20, 10,  5,-10
               -10, 10, 10, 10, 10, 10, 10,-10
               -10,  5,  0,  0,  0,  0,  5,-10
               -20,-10,-10,-10,-10,-10,-10,-20
            ];
            rook = [
                0,  0,  0,  5,  5,  0,  0,  0
               10, 15, 15, 15, 15, 15, 15, 10
               -5,  0,  0,  0,  0,  0,  0, -5
               -5,  0,  0,  0,  0,  0,  0, -5
               -5,  0,  0,  0,  0,  0,  0, -5
               -5,  0,  0,  0,  0,  0,  0, -5
               -5,  0,  0,  0,  0,  0,  0, -5
                0,  0,  0, 10, 10,  5,  0,  0
            ];
            queen = [
               -20,-10,-10, -5, -5,-10,-10,-20
               -10,  0,  5,  0,  0,  0,  0,-10
               -10,  5,  5,  5,  5,  5,  0,-10
                -5,  0,  5,  5,  5,  5,  0, -5
                 0,  0,  5,  5,  5,  5,  0, -5
               -10,  5,  5,  5,  5,  5,  0,-10
               -10,  0,  5,  0,  0,  0,  0,-10
               -20,-10,-10, -5, -5,-10,-10,-20
            ];
            king = [
               -30,-40,-40,-50,-50,-40,-40,-30
               -30,-40,-40,-50,-50,-40,-40,-30
               -30,-40,-40,-50,-50,-40,-40,-30
               -30,-40,-40,-50,-50,-40,-40,-30
               -20,-30,-30,-40,-40,-30,-30,-20
               -10,-20,-20,-20,-20,-20,-20,-10
                20, 20,  0,  0,  0,  0, 20, 20
                20, 30, 10,  0,  0, 10, 30, 20
            ];
            obj.pst = zeros(6, 64);
            tables = {pawn, knight, bishop, rook, queen, king};
            for t = 1:6
                T = tables{t};
                for r = 0:7
                    for c = 0:7
                        obj.pst(t, r*8+c+1) = T(8-r, c+1);
                    end
                end
            end
        end

        function s = pstSide(obj, bb, tip, isBlack)
            s = 0;
            bits = find(bitget(bb, 1:64)) - 1;
            for i = 1:numel(bits)
                sq = bits(i);
                if isBlack
                    s = s + obj.pst(tip, bitxor(sq, 56)+1);
                else
                    s = s + obj.pst(tip, sq+1);
                end
            end
        end

        function initZobrist(obj)
            rng(12345, 'twister');
            lo = uint64(randi([0, 2147483647], 12, 64));
            hi = uint64(randi([0, 2147483647], 12, 64));
            obj.zobristPieces = bitor(lo, bitshift(hi, 32));
            obj.zobristSide = bitor(uint64(randi(2147483647)), bitshift(uint64(randi(2147483647)), 32));
            lo = uint64(randi([0, 2147483647], 16, 1));
            hi = uint64(randi([0, 2147483647], 16, 1));
            obj.zobristCastle = bitor(lo, bitshift(hi, 32));
            lo = uint64(randi([0, 2147483647], 8, 1));
            hi = uint64(randi([0, 2147483647], 8, 1));
            obj.zobristEp = bitor(lo, bitshift(hi, 32));
        end

        function idx = pieceZobristIndex(~, tip, isBlack)
            idx = tip + 6 * double(isBlack);
        end

        function zobristXorPiece(obj, tip, isBlack, sq)
            idx = obj.pieceZobristIndex(tip, isBlack);
            obj.zobristKey = bitxor(obj.zobristKey, obj.zobristPieces(idx, sq+1));
        end

        function zobristXorEp(obj, ep)
            if ep >= 0
                file = rem(double(ep), 8) + 1;
                obj.zobristKey = bitxor(obj.zobristKey, obj.zobristEp(file));
            end
        end

        function castleIndex = castleHashIndex(obj)
            castleIndex = 1 + bitget(obj.flags, 2) + 2*bitget(obj.flags, 3) + ...
                4*bitget(obj.flags, 4) + 8*bitget(obj.flags, 5);
        end

        function recomputeZobristMeta(obj)
            key = uint64(0);
            boards = {obj.P, obj.N, obj.B, obj.R, obj.Q, obj.K, ...
                      obj.p, obj.n, obj.b, obj.r, obj.q, obj.k};
            for idx = 1:12
                bits = find(bitget(boards{idx}, 1:64)) - 1;
                for i = 1:numel(bits)
                    key = bitxor(key, obj.zobristPieces(idx, bits(i)+1));
                end
            end
            if bitget(obj.flags, 1)
                key = bitxor(key, obj.zobristSide);
            end
            key = bitxor(key, obj.zobristCastle(obj.castleHashIndex()));
            obj.zobristKey = key;
        end

        function recomputeZobrist(obj)
            obj.recomputeZobristMeta();
            if obj.epSquare >= 0
                obj.zobristXorEp(obj.epSquare);
            end
        end
    end
end
