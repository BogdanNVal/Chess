classdef Utilizator < Jucator

    properties

        logic
        %listaMutari
    end

    methods

        function obj = Utilizator(logic)

            obj.logic = logic;
        end

        function pozitieNoua(obj)

            obj.logic.generareMutari();
        end

        function ok = muta(obj, mutare)
            
            ok = 1;

            if obj.valid(mutare(1), mutare(2))

                obj.logic.bitboard.actualizareTabla(mutare)
            else

                ok = 0;
            end
        end

        function bool = valid(obj, pozI, pozF)

            bool = false;
            mutariPiesa = obj.logic.toateMutarile(obj.logic.toateMutarile(:, 1) == pozI, :);

            if any(mutariPiesa(:, 2) == pozF)

                bool = true;
            end
        end
    end
end
