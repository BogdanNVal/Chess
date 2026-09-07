classdef Sah < handle
    properties
        fig
        ax
        moveflag
        tabla
        piesaSelectata
        joc
        evidentiere = gobjects(0);
        evidentiereLegale = gobjects(0);
        patraticaRege = gobjects(1);
        mutareEfectuata = true;
        finalizat = true;
        statusLabel
    end

    methods
        function obj = Sah()
            obj.moveflag = false;
            obj.finalizat = true;
            obj.mutareEfectuata = true;
            obj.tabla = cell(8, 8);
            obj.setareInterfata();
            obj.setareTabla();
            obj.deseneazaTabla();
            fen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
            obj.joc = Joc(fen);
            obj.UtilizatorVsUtilizator();
            obj.fig.WindowButtonDownFcn = @(src, event) obj.startDrag(event);
            obj.fig.WindowButtonMotionFcn = @(src, event) obj.dragging(event);
            obj.fig.WindowButtonUpFcn = @(src, event) obj.stopDrag(event);
        end
    end

    methods (Access = private)
        function reseteaza(obj)
            obj.stergeEvidentiere();
            obj.stergeEvidentiereLegale();
            obj.clearCheckHighlight();
            obj.finalizat = true;
            obj.mutareEfectuata = true;
            obj.moveflag = false;
            obj.piesaSelectata = {};
            obj.setStatus('');
            for i = 1:8
                for j = 1:8
                    piesa = obj.tabla{i, j};
                    if isa(piesa, "Piesa")
                        if isvalid(piesa.imagine)
                            delete(piesa.imagine);
                        end
                    end
                end
            end
            obj.tabla = cell(8, 8);
            fen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
            obj.joc.reseteaza(fen);
            obj.FEN(fen);
        end

        function setareInterfata(obj)
            obj.fig = uifigure("Name", "Șah — Lucrare de licență", "Icon", "img/sah.png");
            obj.fig.Position = [400, 80, 900, 940];
            obj.fig.Resize = 'off';

            obj.statusLabel = uilabel(obj.fig, ...
                'Position', [48, 900, 800, 28], ...
                'Text', '', ...
                'FontSize', 16, ...
                'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center');

            menu = uimenu(obj.fig);
            menu.Text = 'Joc nou';

            menu1 = uimenu(menu);
            menu1.Text = 'Utilizator vs Utilizator';
            menu1.MenuSelectedFcn = @(src, event) obj.UtilizatorVsUtilizator;

            menu2 = uimenu(menu);
            menu2.Text = 'Utilizator vs Robot';

            for d = 1:5
                m = uimenu(menu2);
                m.Text = sprintf('Adâncime=%d', d);
                m.MenuSelectedFcn = @(src, event) obj.UtilizatorVsRobot(d);
            end
        end

        function setareTabla(obj)
            obj.ax = uiaxes(obj.fig, 'Position', [48, 50, 800, 800]);
            obj.ax.Interactions = [];
            obj.ax.Toolbar = [];
            obj.ax.XColor = 'none';
            obj.ax.YColor = 'none';
            obj.ax.XLim = [0, 8];
            obj.ax.YLim = [0, 8];
        end

        function deseneazaTabla(obj)
            for i = 1:8
                for j = 1:8
                    if rem(i+j, 2) == 0
                        culoare = [139 / 255, 69 / 255, 19 / 255];
                    else
                        culoare = [222 / 255, 184 / 255, 135 / 255];
                    end
                    x = [j - 1, j, j, j - 1];
                    y = [i - 1, i - 1, i, i];
                    patch(obj.ax, x, y, culoare, 'EdgeColor', 'k');
                end
            end

            for i = 1:8
                txt = text(obj.ax, -0.2, i-0.30, ""+(i));
                txt.FontName = 'Arial';
                txt.FontWeight = 'bold';
                txt.FontSize = 30;
                txt.Color = [0.2, 0.2, 0.2];
            end
            label = ["a", "b", "c", "d", "e", "f", "g", "h"];
            for i = 1:8
                txt = text(obj.ax, i-0.70, -0.2, label(i));
                txt.FontName = 'Arial';
                txt.FontWeight = 'bold';
                txt.FontSize = 30;
                txt.Color = [0.2, 0.2, 0.2];
            end
        end

        function adaugaPiesa(obj, coloana, linie, c)
            p = Piesa(c, [coloana, linie], obj.fig);
            obj.tabla{linie+1, coloana+1} = p;
        end

        function FEN(obj, fen)
            linie = 7;
            coloana = 0;
            str = strsplit(fen, ' ');
            piese = str{1};

            for i = 1:length(piese)
                if piese(i) == '/'
                    linie = linie - 1;
                    coloana = 0;
                elseif piese(i) >= '0' && piese(i) <= '9'
                    coloana = coloana + str2double(piese(i));
                else
                    obj.adaugaPiesa(coloana, linie, piese(i));
                    coloana = coloana + 1;
                end
            end

            if str{2} == 'w' || str{2} == 'W'
                obj.joc.rand = 0;
            else
                obj.joc.rand = 1;
            end
        end

        function setStatus(obj, txt)
            if ~isempty(obj.statusLabel) && isvalid(obj.statusLabel)
                obj.statusLabel.Text = txt;
                drawnow limitrate;
            end
        end
    end

    methods (Access = private)
        function UtilizatorVsUtilizator(obj)
            obj.reseteaza();
            obj.joc.seteazaAdversar('Utilizator');
            obj.setStatus('Mod: Utilizator vs Utilizator');
        end

        function UtilizatorVsRobot(obj, d)
            obj.reseteaza();
            obj.joc.seteazaAdversar('Robot', d);
            obj.setStatus(sprintf('Mod: Utilizator vs Robot (adâncime %d)', d));
        end
    end

    methods (Access = private)
        function startDrag(obj, ~)
            if ~obj.finalizat
                obj.piesaSelectata = {};
                obj.moveflag = false;
                return;
            end

            mousePos = obj.fig.CurrentPoint;
            [coloana, linie] = obj.mouseToSquare(mousePos);
            if coloana >= 1 && coloana <= 8 && linie >= 1 && linie <= 8
                obj.piesaSelectata = obj.tabla{linie, coloana};
                if isa(obj.piesaSelectata, 'Piesa')
                    obj.moveflag = true;
                    obj.piesaSelectata.muta(mousePos);
                    from = (linie-1)*8 + (coloana-1);
                    obj.arataMutariLegale(from);
                    return;
                end
            end
            obj.stergeEvidentiereLegale();
            obj.moveflag = false;
        end

        function dragging(obj, ~)
            if ~obj.finalizat
                obj.piesaSelectata = {};
                return;
            end
            if obj.moveflag && isa(obj.piesaSelectata, 'Piesa')
                mousePos = obj.fig.CurrentPoint;
                obj.piesaSelectata.muta(mousePos);
            end
        end

        function stopDrag(obj, ~)
            obj.stergeEvidentiereLegale();
            if ~obj.finalizat || ~isa(obj.piesaSelectata, 'Piesa')
                obj.piesaSelectata = {};
                obj.moveflag = false;
                return;
            end
            success = false;
            if obj.moveflag && isa(obj.piesaSelectata, 'Piesa')
                mousePos = obj.fig.CurrentPoint;
                [coloana, linie] = obj.mouseToSquare(mousePos);

                if coloana >= 1 && coloana <= 8 && linie >= 1 && linie <= 8
                    success = obj.mutareUtilizator(linie, coloana);
                    drawnow expose;
                else
                    obj.piesaSelectata.mutaLaNouaPozitie(obj.piesaSelectata.pozitie);
                end
            end
            obj.piesaSelectata = {};
            obj.moveflag = false;
            obj.mutareEfectuata = success;

            % Only let the robot move if the user succeeded and the game is still on
            if success && obj.finalizat && isa(obj.joc.adversar, 'Robot') && obj.joc.rand == 1
                pause(0.05);
                drawnow;
                obj.mutareRobot();
            end
        end

        function [coloana, linie] = mouseToSquare(~, mousePos)
            % Must match Piesa layout: origin (63,66), stride 98
            coloana = floor((mousePos(1) - 63)/98) + 1;
            linie = floor((mousePos(2) - 66)/98) + 1;
        end
    end

    methods
        function ok = mutareUtilizator(obj, linie, coloana)
            ok = false;
            obj.mutareEfectuata = false;
            from = obj.piesaSelectata.pozitie(2) * 8 + obj.piesaSelectata.pozitie(1);
            to = (linie - 1) * 8 + coloana - 1;

            cand = obj.joc.logic.toateMutarile;
            if isempty(cand)
                obj.piesaSelectata.mutaLaNouaPozitie(obj.piesaSelectata.pozitie);
                return;
            end
            matches = cand(cand(:,1)==from & cand(:,2)==to, :);
            if isempty(matches)
                obj.piesaSelectata.mutaLaNouaPozitie(obj.piesaSelectata.pozitie);
                return;
            end

            mutare = matches(1, :);
            if matches(1, 5) == 4
                promo = obj.dialogPromovare(obj.piesaSelectata.tip);
                if promo == 0
                    obj.piesaSelectata.mutaLaNouaPozitie(obj.piesaSelectata.pozitie);
                    return;
                end
                mutare = matches(matches(:,6)==promo, :);
                if isempty(mutare)
                    mutare = matches(1, :);
                else
                    mutare = mutare(1, :);
                end
            end

            moved = obj.joc.realizeazaMutare(mutare);
            if moved
                obj.aplicaMutareUI(obj.joc.ultimaMutare);
                obj.actualizeazaStareJoc();
                ok = true;
            else
                obj.piesaSelectata.mutaLaNouaPozitie(obj.piesaSelectata.pozitie);
            end
        end

        function mutareRobot(obj)
            if ~obj.finalizat
                return;
            end
            obj.finalizat = false; % lock UI while thinking
            obj.setStatus(sprintf('Robotul se gândește… (max ~%.0fs)', obj.joc.adversar.logic.timeLimit));
            drawnow;
            mutare = obj.joc.realizeazaMutare();
            obj.setStatus('');
            if isequal(mutare, 0) || isempty(mutare)
                obj.finalizat = true;
                return;
            end
            obj.aplicaMutareUI(obj.joc.ultimaMutare);
            gameOver = obj.actualizeazaStareJoc();
            if ~gameOver
                obj.finalizat = true;
            end
        end

        function aplicaMutareUI(obj, full)
            if isempty(full)
                return;
            end
            from = full(1); to = full(2);
            special = full(5); promo = full(6);
            fromLin = floor(from/8) + 1;
            fromCol = rem(from, 8) + 1;
            toLin = floor(to/8) + 1;
            toCol = rem(to, 8) + 1;

            piesa = obj.tabla{fromLin, fromCol};

            switch special
                case 3 % en passant — remove captured pawn off-target
                    if bitget(obj.joc.logic.bitboard.flags, 1) == 0
                        % after move, white to move => black just moved EP
                        capLin = toLin + 1;
                    else
                        capLin = toLin - 1;
                    end
                    capCol = toCol;
                    if isa(obj.tabla{capLin, capCol}, 'Piesa')
                        delete(obj.tabla{capLin, capCol});
                        obj.tabla{capLin, capCol} = [];
                    end

                case 1 % castle KS
                    if fromLin == 1
                        obj.mutaTuraUI(1, 8, 1, 6); % h1->f1
                    else
                        obj.mutaTuraUI(8, 8, 8, 6); % h8->f8
                    end

                case 2 % castle QS
                    if fromLin == 1
                        obj.mutaTuraUI(1, 1, 1, 4); % a1->d1
                    else
                        obj.mutaTuraUI(8, 1, 8, 4); % a8->d8
                    end
            end

            if isa(obj.tabla{toLin, toCol}, 'Piesa')
                delete(obj.tabla{toLin, toCol});
                obj.tabla{toLin, toCol} = [];
            end

            obj.tabla{toLin, toCol} = piesa;
            obj.tabla{fromLin, fromCol} = [];
            if isa(piesa, 'Piesa')
                piesa.mutaLaNouaPozitie([toCol - 1, toLin - 1]);
                if special == 4
                    isBlack = isstrprop(piesa.tip, 'lower');
                    tipNou = obj.tipDinValoare(promo, isBlack);
                    piesa.promoveaza(tipNou);
                end
            end

            obj.evidentiazaMutare([fromCol-1, fromLin-1], [toCol-1, toLin-1]);
        end

        function mutaTuraUI(obj, fromLin, fromCol, toLin, toCol)
            tura = obj.tabla{fromLin, fromCol};
            if ~isa(tura, 'Piesa')
                return;
            end
            if isa(obj.tabla{toLin, toCol}, 'Piesa')
                delete(obj.tabla{toLin, toCol});
            end
            obj.tabla{toLin, toCol} = tura;
            obj.tabla{fromLin, fromCol} = [];
            tura.mutaLaNouaPozitie([toCol - 1, toLin - 1]);
        end

        function gameOver = actualizeazaStareJoc(obj)
            gameOver = false;
            if obj.joc.logic.sahMat()
                obj.afiseazaSahMat(~obj.joc.rand);
                gameOver = true;
            elseif obj.joc.logic.pat()
                obj.afiseazaPat();
                gameOver = true;
            else
                if obj.joc.logic.sah()
                    obj.EvidentiereRegeInSah(obj.joc.rand);
                else
                    obj.clearCheckHighlight();
                end
            end
        end

        function promo = dialogPromovare(obj, tipPion)
            isBlack = isstrprop(tipPion, 'lower');
            opts = {'Dama', 'Tura', 'Nebun', 'Cal'};
            [idx, tf] = listdlg('ListString', opts, 'SelectionMode', 'single', ...
                'Name', 'Promovare', 'PromptString', 'Alege piesa:', ...
                'ListSize', [200, 100]);
            if ~tf
                promo = 0;
                return;
            end
            map = [5, 4, 3, 2];
            promo = map(idx);
            %#ok<*NASGU>
            isBlack;
        end

        function tip = tipDinValoare(~, v, isBlack)
            letters = 'PNBRQK';
            tip = letters(v);
            if isBlack
                tip = lower(tip);
            end
        end

        function v = GP(~, c)
            v = 0;
            if c == 'P' || c == 'p', v = 1;
            elseif c == 'N' || c == 'n', v = 2;
            elseif c == 'B' || c == 'b', v = 3;
            elseif c == 'R' || c == 'r', v = 4;
            elseif c == 'Q' || c == 'q', v = 5;
            elseif c == 'K' || c == 'k', v = 6;
            end
        end
    end

    methods
        function arataMutariLegale(obj, from)
            obj.stergeEvidentiereLegale();
            moves = obj.joc.logic.toateMutarile;
            if isempty(moves)
                return;
            end
            dest = unique(moves(moves(:,1)==from, 2));
            hold(obj.ax, 'on');
            for i = 1:numel(dest)
                to = dest(i);
                col = rem(to, 8);
                lin = floor(to/8);
                h = patch(obj.ax, ...
                    [col+0.3, col+0.7, col+0.7, col+0.3], ...
                    [lin+0.3, lin+0.3, lin+0.7, lin+0.7], ...
                    [0.2, 0.7, 0.3], 'FaceAlpha', 0.55, 'EdgeColor', 'none');
                obj.evidentiereLegale(end+1) = h;
            end
            hold(obj.ax, 'off');
        end

        function stergeEvidentiereLegale(obj)
            if ~isempty(obj.evidentiereLegale)
                delete(obj.evidentiereLegale(ishandle(obj.evidentiereLegale)));
                obj.evidentiereLegale = gobjects(0);
            end
        end

        function evidentiazaMutare(obj, pozInitiala, pozFinala)
            obj.stergeEvidentiere();
            for poz = [pozInitiala; pozFinala]'
                col = poz(1);
                lin = poz(2);
                x = [col, col + 1, col + 1, col];
                y = [lin, lin, lin + 1, lin + 1];
                h = patch(obj.ax, x, y, [1, 1, 0], 'FaceAlpha', 0.3, 'EdgeColor', 'none');
                obj.evidentiere(end+1) = h;
            end
        end

        function stergeEvidentiere(obj)
            if ~isempty(obj.evidentiere)
                delete(obj.evidentiere(ishandle(obj.evidentiere)));
                obj.evidentiere = gobjects(0);
            end
        end

        function EvidentiereRegeInSah(obj, side)
            obj.clearCheckHighlight();
            if side == 0
                rege = 'K';
            else
                rege = 'k';
            end
            for i = 1:8
                for j = 1:8
                    piesa = obj.tabla{i, j};
                    if isa(piesa, 'Piesa') && piesa.tip == rege
                        hold(obj.ax, 'on');
                        obj.patraticaRege = patch(obj.ax, ...
                            [j - 1, j, j, j - 1], [i - 1, i - 1, i, i], ...
                            'r', 'FaceAlpha', 0.4, 'EdgeColor', 'none');
                        hold(obj.ax, 'off');
                        return;
                    end
                end
            end
        end

        function clearCheckHighlight(obj)
            if isgraphics(obj.patraticaRege)
                delete(obj.patraticaRege);
            end
        end

        function afiseazaSahMat(obj, side)
            obj.clearCheckHighlight();
            if side == 0
                rege = 'k';
                castigator = 'Alb';
            else
                rege = 'K';
                castigator = 'Negru';
            end
            for i = 1:8
                for j = 1:8
                    piesa = obj.tabla{i, j};
                    if isa(piesa, 'Piesa') && piesa.tip == rege
                        hold(obj.ax, 'on');
                        obj.patraticaRege = patch(obj.ax, ...
                            [j - 1, j, j, j - 1], [i - 1, i - 1, i, i], ...
                            'r', 'FaceAlpha', 0.7, 'EdgeColor', 'none');
                        hold(obj.ax, 'off');
                        break;
                    end
                end
            end
            obj.finalizat = false;
            uialert(obj.fig, ['Șah Mat – ', castigator, ' a câștigat!'], 'Sfârșit joc');
        end

        function afiseazaPat(obj)
            obj.clearCheckHighlight();
            obj.finalizat = false;
            uialert(obj.fig, 'Pat, jucătorul nu mai are mutări valide.', 'Remiză');
        end
    end
end
