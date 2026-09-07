classdef Piesa < handle
    properties
        tip
        pozitie  % [coloana, linie] 0-based
        imagine
        ax
    end

    properties (Constant)
        PAD = 0.14  % ~72% din pătrat, padding egal
    end

    methods
        function obj = Piesa(tip, pozitie, ax)
            obj.tip = tip;
            obj.pozitie = pozitie;
            obj.ax = ax;

            hold(ax, 'on');
            [cdata, alpha] = obj.loadImage(tip);
            [xd, yd] = obj.dataRect(pozitie);
            obj.imagine = image(ax, 'CData', cdata, ...
                'XData', xd, 'YData', yd, ...
                'AlphaData', alpha, ...
                'AlphaDataMapping', 'none', ...
                'HitTest', 'off', ...
                'PickableParts', 'none');
        end

        function img = getImagine(~, c)
            switch c
                case 'P', img = 'img/pion1.png';
                case 'B', img = 'img/nebun1.png';
                case 'N', img = 'img/cal1.png';
                case 'R', img = 'img/tura1.png';
                case 'Q', img = 'img/regina1.png';
                case 'K', img = 'img/rege1.png';
                case 'p', img = 'img/pion2.png';
                case 'b', img = 'img/nebun2.png';
                case 'n', img = 'img/cal2.png';
                case 'r', img = 'img/tura2.png';
                case 'q', img = 'img/regina2.png';
                case 'k', img = 'img/rege2.png';
                otherwise, img = '';
            end
        end

        function [xd, yd] = dataRect(~, poz)
            % Cu YDir=normal, image mapează primul rând CData la YData(1).
            % Punem YData descrescător ca vârful piesei să fie sus în pătrat.
            p = Piesa.PAD;
            c = poz(1);
            l = poz(2);
            xd = [c + p, c + 1 - p];
            yd = [l + 1 - p, l + p];
        end

        function muta(obj, mousePos)
            % mousePos = [x, y] în coordonate de date pe axes
            half = (1 - 2 * Piesa.PAD) / 2;
            x = mousePos(1);
            y = mousePos(2);
            obj.imagine.XData = [x - half, x + half];
            obj.imagine.YData = [y + half, y - half];
            uistack(obj.imagine, 'top');
        end

        function mutaLaNouaPozitie(obj, poz)
            obj.pozitie = poz;
            [xd, yd] = obj.dataRect(poz);
            obj.imagine.XData = xd;
            obj.imagine.YData = yd;
            drawnow expose;
        end

        function promoveaza(obj, tipNou)
            obj.tip = tipNou;
            [cdata, alpha] = obj.loadImage(tipNou);
            if isempty(cdata)
                return;
            end
            if ~isempty(obj.imagine) && isvalid(obj.imagine)
                obj.imagine.CData = cdata;
                obj.imagine.AlphaData = alpha;
            end
        end

        function [cdata, alpha] = loadImage(obj, tip)
            rel = obj.getImagine(tip);
            path = obj.resolveImagePath(rel);
            if isempty(path)
                cdata = [];
                alpha = [];
                return;
            end
            [cdata, ~, alpha] = imread(path);
            if size(cdata, 3) == 1
                cdata = repmat(cdata, 1, 1, 3);
            end
            if isempty(alpha)
                alpha = ones(size(cdata, 1), size(cdata, 2));
            elseif ~isa(alpha, 'double')
                alpha = double(alpha) / 255;
            end
        end

        function path = resolveImagePath(~, rel)
            if isempty(rel)
                path = '';
                return;
            end
            classDir = fileparts(mfilename('fullpath'));
            candidate = fullfile(classDir, rel);
            if exist(candidate, 'file') == 2
                path = candidate;
            else
                path = rel;
            end
        end

        function delete(obj)
            if ~isempty(obj.imagine) && isvalid(obj.imagine)
                delete(obj.imagine);
            end
        end
    end
end
