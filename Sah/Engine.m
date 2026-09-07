classdef Engine < handle
    % Minimax + alpha-beta with iterative deepening, quiescence,
    % MVV-LVA ordering (via Mutari), killers, and transposition table.

    properties
        adancime = 3
        mutari
        tt
        killers      % depth x 2 x 6
        nodes
        bestMoveRoot
    end

    properties (Constant)
        MATE = 100000
        FLAG_EXACT = 0
        FLAG_LOWER = 1
        FLAG_UPPER = 2
    end

    methods
        function obj = Engine(mutari, adancime)
            obj.mutari = mutari;
            obj.adancime = adancime;
            obj.tt = TranspositionTable(131072);
            obj.killers = zeros(64, 2, 6);
            obj.nodes = 0;
            obj.bestMoveRoot = [];
        end

        function mutareOptima = cautaMutare(obj)
            obj.tt.clear();
            obj.killers(:) = 0;
            obj.nodes = 0;
            mutareOptima = [];
            obj.bestMoveRoot = [];

            f = bitget(obj.mutari.bitboard.flags, 1);
            maximizing = ~f; % white maximizes

            for depth = 1:obj.adancime
                [~, best] = obj.searchRoot(depth, maximizing);
                if ~isempty(best)
                    mutareOptima = best;
                    obj.bestMoveRoot = best;
                end
            end

            if isempty(mutareOptima)
                mutareOptima = 0;
            end
        end
    end

    methods (Access = private)
        function [scor, best] = searchRoot(obj, depth, maximizing)
            obj.mutari.generareMutari();
            moves = obj.orderWithHints(obj.mutari.toateMutarile, obj.mutari.numarMutariPosibile, obj.bestMoveRoot, 0);
            nr = size(moves, 1);
            best = [];
            if nr == 0
                scor = 0;
                return;
            end

            alpha = -inf;
            beta = inf;
            if maximizing
                scor = -inf;
            else
                scor = inf;
            end

            for i = 1:nr
                obj.mutari.bitboard.actualizareTabla(moves(i, :));
                val = obj.alphabeta(depth - 1, alpha, beta, 1);
                obj.mutari.bitboard.anulareMutare(moves(i, :));
                obj.nodes = obj.nodes + 1;

                if maximizing
                    if val > scor
                        scor = val;
                        best = moves(i, :);
                    end
                    alpha = max(alpha, scor);
                else
                    if val < scor
                        scor = val;
                        best = moves(i, :);
                    end
                    beta = min(beta, scor);
                end
            end
        end

        function scor = alphabeta(obj, depth, alpha, beta, ply)
            obj.nodes = obj.nodes + 1;
            alphaOrig = alpha;
            key = obj.mutari.bitboard.zobristKey;

            [found, ttDepth, ttScore, ttFlag, ttMove] = obj.tt.probe(key);
            if found && ttDepth >= depth
                if ttFlag == Engine.FLAG_EXACT
                    scor = ttScore;
                    return;
                elseif ttFlag == Engine.FLAG_LOWER
                    alpha = max(alpha, ttScore);
                elseif ttFlag == Engine.FLAG_UPPER
                    beta = min(beta, ttScore);
                end
                if alpha >= beta
                    scor = ttScore;
                    return;
                end
            end

            if depth == 0
                scor = obj.quiescence(alpha, beta);
                return;
            end

            obj.mutari.generareMutari();
            nr = obj.mutari.numarMutariPosibile;
            if nr == 0
                if obj.mutari.sah()
                    % Side to move is checkmated
                    f = bitget(obj.mutari.bitboard.flags, 1);
                    if f
                        scor = Engine.MATE - ply;  % black mated -> white good
                    else
                        scor = -Engine.MATE + ply;
                    end
                else
                    scor = 0; % stalemate
                end
                return;
            end

            hint = [];
            if found
                hint = ttMove;
            end
            moves = obj.orderWithHints(obj.mutari.toateMutarile, nr, hint, ply);

            maximizing = ~bitget(obj.mutari.bitboard.flags, 1);
            bestMove = moves(1, :);

            if maximizing
                scor = -inf;
                for i = 1:size(moves, 1)
                    obj.mutari.bitboard.actualizareTabla(moves(i, :));
                    val = obj.alphabeta(depth - 1, alpha, beta, ply + 1);
                    obj.mutari.bitboard.anulareMutare(moves(i, :));
                    if val > scor
                        scor = val;
                        bestMove = moves(i, :);
                    end
                    alpha = max(alpha, scor);
                    if alpha >= beta
                        obj.storeKiller(ply, moves(i, :));
                        break;
                    end
                end
            else
                scor = inf;
                for i = 1:size(moves, 1)
                    obj.mutari.bitboard.actualizareTabla(moves(i, :));
                    val = obj.alphabeta(depth - 1, alpha, beta, ply + 1);
                    obj.mutari.bitboard.anulareMutare(moves(i, :));
                    if val < scor
                        scor = val;
                        bestMove = moves(i, :);
                    end
                    beta = min(beta, scor);
                    if alpha >= beta
                        obj.storeKiller(ply, moves(i, :));
                        break;
                    end
                end
            end

            if scor <= alphaOrig
                flag = Engine.FLAG_UPPER;
            elseif scor >= beta
                flag = Engine.FLAG_LOWER;
            else
                flag = Engine.FLAG_EXACT;
            end
            obj.tt.store(key, depth, scor, flag, bestMove);
        end

        function scor = quiescence(obj, alpha, beta)
            obj.nodes = obj.nodes + 1;
            standPat = obj.mutari.bitboard.evaluareTabla();
            maximizing = ~bitget(obj.mutari.bitboard.flags, 1);

            if maximizing
                if standPat >= beta
                    scor = beta;
                    return;
                end
                if standPat > alpha
                    alpha = standPat;
                end
            else
                if standPat <= alpha
                    scor = alpha;
                    return;
                end
                if standPat < beta
                    beta = standPat;
                end
            end

            obj.mutari.generareMutari(true); % captures (+ EP/promo captures)
            moves = obj.mutari.toateMutarile;
            nr = obj.mutari.numarMutariPosibile;
            if nr == 0
                scor = standPat;
                return;
            end

            if maximizing
                scor = standPat;
                for i = 1:nr
                    obj.mutari.bitboard.actualizareTabla(moves(i, :));
                    val = obj.quiescence(alpha, beta);
                    obj.mutari.bitboard.anulareMutare(moves(i, :));
                    scor = max(scor, val);
                    alpha = max(alpha, scor);
                    if alpha >= beta
                        break;
                    end
                end
            else
                scor = standPat;
                for i = 1:nr
                    obj.mutari.bitboard.actualizareTabla(moves(i, :));
                    val = obj.quiescence(alpha, beta);
                    obj.mutari.bitboard.anulareMutare(moves(i, :));
                    scor = min(scor, val);
                    beta = min(beta, scor);
                    if alpha >= beta
                        break;
                    end
                end
            end
        end

        function moves = orderWithHints(obj, raw, nr, hint, ply)
            if nr <= 0
                moves = zeros(0, 6);
                return;
            end
            moves = raw(1:nr, :);
            % Already MVV-LVA sorted by Mutari; pull TT / killer to front
            prefer = zeros(0, 6);
            if ~isempty(hint) && any(hint)
                prefer = [prefer; hint(1, 1:6)];
            end
            if ply >= 1 && ply <= size(obj.killers, 1)
                k1 = squeeze(obj.killers(ply, 1, :))';
                k2 = squeeze(obj.killers(ply, 2, :))';
                if any(k1), prefer = [prefer; k1]; end
                if any(k2), prefer = [prefer; k2]; end
            end
            if isempty(prefer)
                return;
            end
            front = zeros(0, 6);
            used = false(nr, 1);
            for p = 1:size(prefer, 1)
                for i = 1:nr
                    if ~used(i) && isequal(moves(i, :), prefer(p, :))
                        front = [front; moves(i, :)]; %#ok<AGROW>
                        used(i) = true;
                        break;
                    end
                end
            end
            moves = [front; moves(~used, :)];
        end

        function storeKiller(obj, ply, move)
            if ply < 1 || ply > size(obj.killers, 1)
                return;
            end
            if move(4) ~= 0 || move(5) == 3 || move(5) == 4
                return; % only quiet
            end
            k1 = squeeze(obj.killers(ply, 1, :))';
            if ~isequal(k1, move)
                obj.killers(ply, 2, :) = obj.killers(ply, 1, :);
                obj.killers(ply, 1, :) = move;
            end
        end
    end
end
