function run_perft()
% Perft validation for the chess engine (thesis correctness harness).
% Run from the Sah/ folder:
%   cd Sah
%   run_perft
%
% Expected start-position counts (standard chess perft):
%   depth 1 = 20
%   depth 2 = 400
%   depth 3 = 8902
%   depth 4 = 197281  (slow in MATLAB — optional)

    here = fileparts(mfilename('fullpath'));
    addpath(here);

    fenStart = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
    expectedStart = [20, 400, 8902];

    fprintf('=== Perft: starting position ===\n');
    ok = true;
    for d = 1:numel(expectedStart)
        m = Mutari(Bitboard(fenStart));
        n = m.perft(d);
        exp = expectedStart(d);
        status = 'OK';
        if n ~= exp
            status = 'FAIL';
            ok = false;
        end
        fprintf('  depth %d: %d (expected %d) [%s]\n', d, n, exp, status);
    end

    % Kiwipete — known suite position for castling/EP/promo stress
    fenKiwipete = 'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1';
    expectedKiwi = [48, 2039]; % depth 1 and 2
    fprintf('=== Perft: Kiwipete ===\n');
    for d = 1:numel(expectedKiwi)
        m = Mutari(Bitboard(fenKiwipete));
        n = m.perft(d);
        exp = expectedKiwi(d);
        status = 'OK';
        if n ~= exp
            status = 'FAIL';
            ok = false;
        end
        fprintf('  depth %d: %d (expected %d) [%s]\n', d, n, exp, status);
    end

    % Position with en passant opportunity
    fenEP = 'rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPP1PPP/RNBQKBNR w KQkq f6 0 3';
    fprintf('=== Perft: EP position (depth 1) ===\n');
    m = Mutari(Bitboard(fenEP));
    m.generareMutari();
    fprintf('  legal moves: %d\n', m.numarMutariPosibile);
    hasEP = any(m.toateMutarile(:,5) == 3);
    fprintf('  has en passant move: %d\n', hasEP);
    if ~hasEP
        ok = false;
    end

    if ok
        fprintf('\nAll critical perft checks passed.\n');
    else
        fprintf('\nSome perft checks FAILED — inspect move generation/make-unmake.\n');
    end
end
