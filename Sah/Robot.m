classdef Robot < Jucator

    properties
        logic
        lastMove  % ultima mutare jucată, format complet pe 6 câmpuri
    end

    methods
        function obj = Robot(logic, depth)
            obj.logic = Engine(logic, depth);
            obj.lastMove = [];
        end

        function mutare = muta(obj)
            mutareOptima = obj.logic.cautaMutare();
            if isempty(mutareOptima) || isequal(mutareOptima, 0)
                mutare = 0;
                obj.lastMove = [];
            else
                obj.logic.mutari.bitboard.actualizareTabla(mutareOptima);
                obj.lastMove = mutareOptima;
                % Coordonate UI: [fromRank, fromFile, toRank, toFile] 1-based
                mutare = [floor(mutareOptima(1)/8) + 1, rem(mutareOptima(1), 8) + 1, ...
                          floor(mutareOptima(2)/8) + 1, rem(mutareOptima(2), 8) + 1];
            end
        end
    end
end
