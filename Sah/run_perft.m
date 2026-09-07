function run_perft()
% Validare perft pentru motorul de șah (harness de corectitudine pentru lucrare).
% Rulează din folderul Sah/:
%   cd Sah
%   run_perft
%
% Numărări așteptate pe poziția inițială (perft standard):
%   adâncime 1 = 20
%   adâncime 2 = 400
%   adâncime 3 = 8902
%   adâncime 4 = 197281  (lent în MATLAB — opțional)

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

    % Kiwipete — poziție cunoscută din suite (stres pe rocadă/EP/promovare)
    fenKiwipete = 'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1';
    expectedKiwi = [48, 2039]; % adâncimile 1 și 2
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

    % Poziție cu oportunitate de en passant
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
