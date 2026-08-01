classdef Joc < handle

    properties
        utilizator
        adversar
        logic
        rand
    end

    methods
        function obj = Joc(fen)

            obj.logic = Mutari(Bitboard(fen));
            obj.utilizator = Utilizator(obj.logic);
            obj.start();
        end

        function seteazaAdversar(obj, varargin)

            if numel(varargin) == 1

                obj.adversar = feval(varargin{1}, obj.logic);
            else

                obj.adversar = feval(varargin{1}, obj.logic, varargin{2});
            end
        end

        function reseteaza(obj, fen)

            obj.logic = Mutari(Bitboard(fen));
            obj.utilizator.logic = obj.logic;
            obj.start();
        end

        function start(obj)

            obj.utilizator.logic.generareMutari();
        end

        function ok = realizeazaMutare(obj, varargin)

            if ~obj.rand

                ok = muta(obj.utilizator, varargin{1});
                if isa(obj.adversar, "Utilizator")

                    obj.adversar.pozitieNoua();
                end

            else
                if isa(obj.adversar, "Utilizator")

                    ok = muta(obj.adversar, varargin{1}); % 1 sau 0
                else

                    ok = muta(obj.adversar); % returneaza o mutare sau 0
                end
                obj.utilizator.pozitieNoua();
            end

            if ok

                obj.rand = ~obj.rand;

            end
        end
    end
end
