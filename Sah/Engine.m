classdef Engine < handle

    properties
        adancime = 3;
        mutari Mutari

    end

    methods

        function obj = Engine(mutari, adancime)
             %Constructor
            obj.mutari = mutari;
            obj.adancime = adancime;
        end

        function mutareOptima = cautaMutare(obj)
            mutareOptima = 0;
            f = bitget(obj.mutari.bitboard.flags, 1);
            if f
                scorMaxim = Inf;
            else
                scorMaxim = -Inf;
            end
            obj.mutari.generareMutari();
            nr = obj.mutari.numarMutariPosibile;
            moves = obj.mutari.toateMutarile;
            alpha = -Inf;
            beta = Inf;
            for i = 1:nr
                obj.mutari.bitboard.actualizareTabla(moves(i, :));
                val = obj.alphabeta(obj.adancime-1, alpha, beta);
                if (f && val < scorMaxim) || (~f && val > scorMaxim)
                    scorMaxim = val;
                    mutareOptima = moves(i, :);
                end
                obj.mutari.bitboard.anulareMutare(moves(i, :));
            end
        end


        function scor = alphabeta(obj, adancime, alpha, beta)

            if adancime == 0
                scor = obj.mutari.bitboard.evaluareTabla();
                return;
            end


            obj.mutari.generareMutari();
            nr = obj.mutari.numarMutariPosibile;
            moves = obj.mutari.toateMutarile;

            if nr == 0

                if obj.mutari.sahMat
                    if ~bitget(obj.mutari.bitboard.flags, 1)
                        scor = -Inf;
                    else
                        scor = Inf;
                    end
                else
                    scor = 0;
                end
                return;
            end

            if ~bitget(obj.mutari.bitboard.flags, 1)
                scor = -Inf;
                for i = 1:nr
                    obj.mutari.bitboard.actualizareTabla(moves(i, :));
                    valoare = obj.alphabeta(adancime-1, alpha, beta);
                    scor = max(scor, valoare);
                    alpha = max(alpha, scor);
                    obj.mutari.bitboard.anulareMutare(moves(i, :));
                    if alpha >= beta
                        break;
                    end

                end
            else
                scor = Inf;
                for i = 1:nr
                    obj.mutari.bitboard.actualizareTabla(moves(i, :));
                    valoare = obj.alphabeta(adancime-1, alpha, beta);
                    scor = min(scor, valoare);
                    beta = min(beta, scor);
                    obj.mutari.bitboard.anulareMutare(moves(i, :));
                    if alpha >= beta
                        break;
                    end

                end
            end

        end
    end
end
