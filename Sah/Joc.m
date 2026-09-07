classdef Joc < handle

    properties
        utilizator
        adversar
        logic
        rand
        ultimaMutare
    end

    methods
        function obj = Joc(fen)
            obj.logic = Mutari(Bitboard(fen));
            obj.utilizator = Utilizator(obj.logic);
            obj.ultimaMutare = [];
            obj.rand = bitget(obj.logic.bitboard.flags, 1);
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
            obj.ultimaMutare = [];
            obj.rand = bitget(obj.logic.bitboard.flags, 1);
            obj.start();
        end

        function start(obj)
            obj.utilizator.logic.generareMutari();
        end

        function ok = realizeazaMutare(obj, varargin)
            if ~obj.rand
                if nargin < 2 || isempty(varargin)
                    ok = 0;
                    return;
                end
                ok = muta(obj.utilizator, varargin{1});
                if ok
                    obj.ultimaMutare = obj.utilizator.ultimaMutare;
                    if isa(obj.adversar, "Utilizator")
                        obj.adversar.pozitieNoua();
                    end
                    obj.rand = ~obj.rand;
                end
            else
                if isa(obj.adversar, "Utilizator")
                    if nargin < 2 || isempty(varargin)
                        ok = 0;
                        return;
                    end
                    ok = muta(obj.adversar, varargin{1});
                    if ok
                        obj.ultimaMutare = obj.adversar.ultimaMutare;
                        obj.utilizator.pozitieNoua();
                        obj.rand = ~obj.rand;
                    end
                else
                    % Robot: ignoră orice payload accidental de mutare din UI
                    ok = muta(obj.adversar);
                    if ~isequal(ok, 0) && ~isempty(ok)
                        obj.ultimaMutare = obj.adversar.lastMove;
                        obj.utilizator.pozitieNoua();
                        obj.rand = ~obj.rand;
                    else
                        ok = 0;
                        obj.ultimaMutare = [];
                    end
                end
            end
        end
    end
end
