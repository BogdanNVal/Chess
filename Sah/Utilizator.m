classdef Utilizator < Jucator

    properties
        logic
        ultimaMutare
    end

    methods
        function obj = Utilizator(logic)
            obj.logic = logic;
            obj.ultimaMutare = [];
        end

        function pozitieNoua(obj)
            obj.logic.generareMutari();
        end

        function ok = muta(obj, mutare)
            ok = 1;
            % Rezolvă mutarea completă din lista generată (special/promo)
            full = obj.resolveMove(mutare);
            if isempty(full)
                ok = 0;
                obj.ultimaMutare = [];
                return;
            end
            obj.logic.bitboard.actualizareTabla(full);
            obj.ultimaMutare = full;
        end

        function full = resolveMove(obj, mutare)
            % mutare poate fi [from,to,piece,captured] sau formatul complet pe 6 câmpuri
            full = [];
            if isempty(obj.logic.toateMutarile)
                return;
            end
            moves = obj.logic.toateMutarile;
            from = mutare(1);
            to = mutare(2);
            cand = moves(moves(:,1)==from & moves(:,2)==to, :);
            if isempty(cand)
                return;
            end
            if size(cand, 1) == 1
                full = cand(1, :);
                return;
            end
            % Mai multe (promovări): preferă promo-ul potrivit dacă e dat
            if numel(mutare) >= 6 && mutare(5) == 4 && mutare(6) > 0
                match = cand(cand(:,6)==mutare(6), :);
                if ~isempty(match)
                    full = match(1, :);
                    return;
                end
            end
            % Implicit: promovare la damă
            match = cand(cand(:,6)==5, :);
            if ~isempty(match)
                full = match(1, :);
            else
                full = cand(1, :);
            end
        end

        function bool = valid(obj, pozI, pozF)
            bool = false;
            if isempty(obj.logic.toateMutarile)
                return;
            end
            mutariPiesa = obj.logic.toateMutarile(obj.logic.toateMutarile(:, 1) == pozI, :);
            if any(mutariPiesa(:, 2) == pozF)
                bool = true;
            end
        end
    end
end
