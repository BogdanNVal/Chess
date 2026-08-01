classdef Sah < handle
    properties
        fig  
        ax  
        moveflag
        tabla
        piesaSelectata
        joc
        evidentiere = gobjects(0);
        patraticaRege = gobjects(1);
        mutareEfectuata = true;
        finalizat = true;
    end

    methods
        % Constructor
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
        % Setari si asezarea pieselor pe tabla

        function reseteaza(obj)
            obj.stergeEvidentiere();
            obj.clearCheckHighlight();
            obj.finalizat = true;
            obj.mutareEfectuata = true;
            obj.moveflag = false;
            obj.piesaSelectata = {};
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
            % Setari interfata

            obj.fig = uifigure("Name", "Șah", "Icon", "img/sah.png");
            obj.fig.Position = [400, 100, 900, 900];
            obj.fig.Resize = 'off';
            menu = uimenu(obj.fig);
            menu.Text = 'Joc nou';

            menu1 = uimenu(menu);
            menu1.Text = 'Utilizator vs Utilizator';
            menu1.MenuSelectedFcn = @(src, event) obj.UtilizatorVsUtilizator;

            menu2 = uimenu(menu);
            menu2.Text = 'Utilizator vs Robot';

            for d = 1:4
                m = uimenu(menu2);
                m.Text = sprintf('Adâncime=%d', d);
                m.MenuSelectedFcn = @(src, event) obj.UtilizatorVsRobot(d);
            end


        end

        
        function setareTabla(obj)
            % Setari tabla de sah
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
            % Aranjeaza tabla folosind FEN
            linie = 7;
            coloana = 0;
            str = strsplit(fen, ' ');
            piese = str{1};

            for i = 1:strlength(piese)
                if piese(i) == '/'
                    linie = linie - 1;
                    coloana = 0;
                elseif isstrprop(piese(i), 'digit')
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


    end

    % Funcii apelate la selectarea obtiunilor din meniu
    methods (Access = private)

        function UtilizatorVsUtilizator(obj)
            obj.reseteaza();
            obj.joc.seteazaAdversar('Utilizator');

        end

        function UtilizatorVsRobot(obj, d)
            obj.reseteaza();
            obj.joc.seteazaAdversar('Robot', d);
        end

    end


    methods (Access = private)
        % Actiuni mouse
        function startDrag(obj, ~)

            if ~obj.finalizat
                obj.piesaSelectata = {};
                obj.moveflag = false;
                return;
            end

            mousePos = obj.fig.CurrentPoint;
            coloana = floor((mousePos(1) - 60)/98) + 1;
            linie = floor((mousePos(2) - 66)/98) + 1;
            if coloana >= 1 && coloana <= 8 && linie >= 1 && linie <= 8 % verific daca mouse-ul a fost apasat pe tabla
                obj.piesaSelectata = obj.tabla{linie, coloana};
                if isa(obj.piesaSelectata, 'Piesa') % verific daca a fost selectata o piesa
                    obj.moveflag = true;
                    obj.piesaSelectata.muta(mousePos);
                    return;
                end
            end
            obj.moveflag = false;

        end

        function dragging(obj, ~)
            if ~obj.finalizat
                obj.piesaSelectata = {};
                return;
            end
            if obj.moveflag && isa(obj.piesaSelectata, 'Piesa') % verific daca mouse-ul este inca apasat si daca este o piesa selectata
                mousePos = obj.fig.CurrentPoint;
                obj.piesaSelectata.muta(mousePos);
            end
        end


        function stopDrag(obj, ~)
            if ~obj.finalizat || ~isa(obj.piesaSelectata, 'Piesa')
                obj.piesaSelectata = {};
                obj.moveflag = false;
                return;
            end
            if obj.moveflag && isa(obj.piesaSelectata, 'Piesa')
                mousePos = obj.fig.CurrentPoint;
                coloana = floor((mousePos(1) - 60)/98) + 1;
                linie = floor((mousePos(2) - 66)/98) + 1;

                if coloana >= 1 && coloana <= 8 && linie >= 1 && linie <= 8
                    obj.mutareUtilizator(linie, coloana);

                    drawnow expose;

                    obj.mutareEfectuata = true;

                else
                    obj.piesaSelectata.mutaLaNouaPozitie(obj.piesaSelectata.pozitie);
                end
            end
            obj.piesaSelectata = {};
            obj.moveflag = false;

            if isa(obj.joc.adversar, 'Robot') && obj.joc.rand == 1 && obj.mutareEfectuata == true

                pause(0.05);
                drawnow;
                obj.mutareRobot();
                obj.finalizat = true;
            end
        end


    end

    methods

        function mutareUtilizator(obj, linie, coloana)
            obj.mutareEfectuata = false;
            mutare = [obj.piesaSelectata.pozitie(2) * 8 + obj.piesaSelectata.pozitie(1), ...
                (linie - 1) * 8 + coloana - 1, ...
                obj.GP(obj.piesaSelectata.tip),];

            if isa(obj.tabla{linie, coloana}, 'Piesa')
                mutare = [mutare, obj.GP(obj.tabla{linie, coloana}.tip)];
            else
                mutare = [mutare, 0];
            end
            ok = obj.joc.realizeazaMutare(mutare);

            if ok
                pozInitiala = obj.piesaSelectata.pozitie;

                if isa(obj.tabla{linie, coloana}, "Piesa")
                    delete(obj.tabla{linie, coloana});
                    obj.tabla{linie, coloana} = [];
                end

                obj.tabla{linie, coloana} = obj.piesaSelectata;
                obj.tabla{pozInitiala(2)+1, pozInitiala(1)+1} = [];

                obj.piesaSelectata.mutaLaNouaPozitie([coloana - 1, linie - 1]);

                obj.evidentiazaMutare(pozInitiala, [coloana - 1, linie - 1]);

                if obj.joc.logic.sahMat()
                    obj.afiseazaSahMat(~obj.joc.rand);
                elseif obj.joc.logic.pat()
                    obj.afiseazaPat();
                else
                    if obj.joc.logic.sah()
                        obj.EvidentiereRegeInSah(obj.joc.rand);
                    else
                        obj.clearCheckHighlight();
                    end
                end

            else
                obj.piesaSelectata.mutaLaNouaPozitie(obj.piesaSelectata.pozitie)

            end

        end

        function mutareRobot(obj)
            obj.finalizat = false;
            mutare = obj.joc.realizeazaMutare();
            if ~mutare
            else
                if isa(obj.tabla{mutare(3), mutare(4)}, "Piesa")
                    delete(obj.tabla{mutare(3), mutare(4)})
                    obj.tabla{mutare(3), mutare(4)} = [];
                end
                obj.tabla{mutare(3), mutare(4)} = obj.tabla{mutare(1), mutare(2)};
                obj.tabla{mutare(1), mutare(2)} = [];
                obj.tabla{mutare(3), mutare(4)}.mutaLaNouaPozitie([mutare(4) - 1, mutare(3) - 1]);

                pozInitiala = [mutare(2) - 1, mutare(1) - 1]; % [col, lin]
                pozFinala = [mutare(4) - 1, mutare(3) - 1]; % [col, lin]
                obj.evidentiazaMutare(pozInitiala, pozFinala);

                if obj.joc.logic.sahMat()
                    obj.afiseazaSahMat(~obj.joc.rand);
                elseif obj.joc.logic.pat()
                    obj.afiseazaPat();
                else
                    if obj.joc.logic.sah()
                        obj.EvidentiereRegeInSah(obj.joc.rand);
                    else
                        obj.clearCheckHighlight();
                    end
                end

            end
        end

        function v = GP(~, c)
            v = 0;
            if c == 'P' || c == 'p'
                v = 1;
            elseif c == 'N' || c == 'n'
                v = 2;
            elseif c == 'B' || c == 'b'
                v = 3;
            elseif c == 'R' || c == 'r'
                v = 4;
            elseif c == 'Q' || c == 'q'
                v = 5;
            elseif c == 'K' || c == 'k'
                v = 6;
            end

        end
    end


    %evidentieri
    methods

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
                rege = 'K'; % rege alb
            else
                rege = 'k'; % rege negru
            end

            for i = 1:8
                for j = 1:8
                    piesa = obj.tabla{i, j};
                    if isa(piesa, 'Piesa') && piesa.tip == rege
                        hold(obj.ax, 'on');
                        obj.patraticaRege = patch(obj.ax, ...
                            [j - 1, j, j, j - 1], ...
                            [i - 1, i - 1, i, i], ...
                            'r', ...
                            'FaceAlpha', 0.4, ...
                            'EdgeColor', 'none');
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
                rege = 'k'; % rege negru
                castigator = 'Alb';
            else
                rege = 'K'; %  rege alb
                castigator = 'Negru';
            end


            for i = 1:8
                for j = 1:8
                    piesa = obj.tabla{i, j};
                    if isa(piesa, 'Piesa') && piesa.tip == rege
                        hold(obj.ax, 'on');
                        obj.patraticaRege = patch(obj.ax, ...
                            [j - 1, j, j, j - 1], ...
                            [i - 1, i - 1, i, i], ...
                            'r', ...
                            'FaceAlpha', 0.7, ...
                            'EdgeColor', 'none');
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
