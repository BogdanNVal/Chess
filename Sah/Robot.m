classdef Robot < Jucator

    properties

        logic
    end

    methods

        function obj = Robot(logic, depth)

            obj.logic = Engine(logic, depth);
        end

        function mutare = muta(obj)

            mutareOptima = obj.logic.cautaMutare();
            if ~mutareOptima
                mutare = 0;
            else
                obj.logic.mutari.bitboard.actualizareTabla(mutareOptima)
                mutare = [floor(mutareOptima(1)/8) + 1, rem(mutareOptima(1), 8) + 1, floor(mutareOptima(2)/8) + 1, rem(mutareOptima(2), 8) + 1];
            end
        end
    end
end
