classdef Engine < handle
    % Faster alpha-beta: iterative deepening, aspiration, null-move,
    % limited quiescence, TT, killers, time budget.

    properties
        adancime = 3
        mutari
        tt
        killers
        nodes
        bestMoveRoot
        timeLimit = 3.5   % seconds soft cap per move
        startTime
        timedOut
    end

    properties (Constant)
        MATE = 100000
        FLAG_EXACT = 0
        FLAG_LOWER = 1
        FLAG_UPPER = 2
        QMAX = 5          % max quiescence ply
        NULL_R = 2        % null-move reduction
    end

    methods
        function obj = Engine(mutari, adancime)
            obj.mutari = mutari;
            obj.adancime = adancime;
            obj.tt = TranspositionTable(262144);
            obj.killers = zeros(64, 2, 6);
            obj.nodes = 0;
            obj.bestMoveRoot = [];
            obj.timedOut = false;
        end

        function mutareOptima = cautaMutare(obj)
            obj.tt.clear();
            obj.killers(:) = 0;
            obj.nodes = 0;
            obj.timedOut = false;
            obj.startTime = tic;
            mutareOptima = [];
            obj.bestMoveRoot = [];

            f = bitget(obj.mutari.bitboard.flags, 1);
            maximizing = ~f;
            lastScore = 0;

            for depth = 1:obj.adancime
                if toc(obj.startTime) > obj.timeLimit
                    break;
                end
                % Aspiration window around previous score
                if depth >= 3
                    alpha = lastScore - 50;
                    beta = lastScore + 50;
                    [scor, best] = obj.searchRoot(depth, maximizing, alpha, beta);
                    if ~isempty(best) && (scor <= alpha || scor >= beta)
                        [scor, best] = obj.searchRoot(depth, maximizing, -inf, inf);
                    end
                else
                    [scor, best] = obj.searchRoot(depth, maximizing, -inf, inf);
                end
                if obj.timedOut
                    break;
                end
                if ~isempty(best)
                    mutareOptima = best;
                    obj.bestMoveRoot = best;
                    lastScore = scor;
                end
            end

            if isempty(mutareOptima)
                mutareOptima = 0;
            end
        end
    end

    methods (Access = private)
        function [scor, best] = searchRoot(obj, depth, maximizing, alpha, beta)
            obj.mutari.generareMutari();
            moves = obj.orderWithHints(obj.mutari.toateMutarile, obj.mutari.numarMutariPosibile, obj.bestMoveRoot, 0);
            nr = size(moves, 1);
            best = [];
            if nr == 0
                scor = 0;
                return;
            end

            if maximizing
                scor = -inf;
            else
                scor = inf;
            end

            for i = 1:nr
                if toc(obj.startTime) > obj.timeLimit
                    obj.timedOut = true;
                    break;
                end
                obj.mutari.bitboard.actualizareTabla(moves(i, :));
                val = obj.alphabeta(depth - 1, alpha, beta, 1, true);
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

        function scor = alphabeta(obj, depth, alpha, beta, ply, allowNull)
            obj.nodes = obj.nodes + 1;
            if mod(obj.nodes, 2048) == 0 && toc(obj.startTime) > obj.timeLimit
                obj.timedOut = true;
                scor = obj.mutari.bitboard.evaluareTabla();
                return;
            end

            alphaOrig = alpha;
            key = obj.mutari.bitboard.zobristKey;

            [found, ttDepth, ttScore, ttFlag, ttMove] = obj.tt.probe(key);
            if found && ttDepth >= depth
                if ttFlag == Engine.FLAG_EXACT
                    scor = ttScore; return;
                elseif ttFlag == Engine.FLAG_LOWER
                    alpha = max(alpha, ttScore);
                elseif ttFlag == Engine.FLAG_UPPER
                    beta = min(beta, ttScore);
                end
                if alpha >= beta
                    scor = ttScore; return;
                end
            end

            if depth == 0
                scor = obj.quiescence(alpha, beta, 0);
                return;
            end

            inCheck = obj.mutari.sah();

            % Null-move pruning
            if allowNull && ~inCheck && depth >= 3
                obj.mutari.bitboard.nullMoveBegin();
                nullScore = obj.alphabeta(depth - 1 - Engine.NULL_R, alpha, beta, ply + 1, false);
                obj.mutari.bitboard.nullMoveEnd();
                maximizing = ~bitget(obj.mutari.bitboard.flags, 1);
                if maximizing && nullScore >= beta
                    scor = beta; return;
                elseif ~maximizing && nullScore <= alpha
                    scor = alpha; return;
                end
            end

            obj.mutari.generareMutari();
            nr = obj.mutari.numarMutariPosibile;
            if nr == 0
                if inCheck
                    f = bitget(obj.mutari.bitboard.flags, 1);
                    if f
                        scor = Engine.MATE - ply;
                    else
                        scor = -Engine.MATE + ply;
                    end
                else
                    scor = 0;
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
                    % Late move reduction for quiet late moves
                    red = 0;
                    if depth >= 3 && i > 4 && moves(i, 4) == 0 && moves(i, 5) == 0 && ~inCheck
                        red = 1;
                    end
                    val = obj.alphabeta(depth - 1 - red, alpha, beta, ply + 1, true);
                    if red && val > alpha
                        val = obj.alphabeta(depth - 1, alpha, beta, ply + 1, true);
                    end
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
                    red = 0;
                    if depth >= 3 && i > 4 && moves(i, 4) == 0 && moves(i, 5) == 0 && ~inCheck
                        red = 1;
                    end
                    val = obj.alphabeta(depth - 1 - red, alpha, beta, ply + 1, true);
                    if red && val < beta
                        val = obj.alphabeta(depth - 1, alpha, beta, ply + 1, true);
                    end
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

        function scor = quiescence(obj, alpha, beta, qply)
            obj.nodes = obj.nodes + 1;
            standPat = obj.mutari.bitboard.evaluareTabla();
            maximizing = ~bitget(obj.mutari.bitboard.flags, 1);

            if maximizing
                if standPat >= beta
                    scor = beta; return;
                end
                if standPat > alpha
                    alpha = standPat;
                end
            else
                if standPat <= alpha
                    scor = alpha; return;
                end
                if standPat < beta
                    beta = standPat;
                end
            end

            if qply >= Engine.QMAX
                scor = standPat;
                return;
            end

            obj.mutari.generareMutari(true);
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
                    val = obj.quiescence(alpha, beta, qply + 1);
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
                    val = obj.quiescence(alpha, beta, qply + 1);
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
                return;
            end
            k1 = squeeze(obj.killers(ply, 1, :))';
            if ~isequal(k1, move)
                obj.killers(ply, 2, :) = obj.killers(ply, 1, :);
                obj.killers(ply, 1, :) = move;
            end
        end
    end
end
