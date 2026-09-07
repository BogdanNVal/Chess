classdef Piesa < handle
    properties
        tip
        pozitie % [coloana, linie] 0-based
        imagine
        fig
        layout  % struct: left, bottom, square, piece
    end

    methods
        function obj = Piesa(tip, pozitie, fig, layout)
            obj.tip = tip;
            obj.pozitie = pozitie;
            obj.fig = fig;
            if nargin < 4 || isempty(layout)
                layout = struct('left', 48, 'bottom', 50, 'square', 100, 'piece', 88);
            end
            obj.layout = layout;

            img = obj.resolveImagePath(obj.getImagine(tip));
            obj.imagine = uiimage(fig, 'ImageSource', img, ...
                'Position', obj.pixelRect(pozitie));
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

        function setLayout(obj, layout)
            obj.layout = layout;
            if ~isempty(obj.imagine) && isvalid(obj.imagine)
                obj.imagine.Position = obj.pixelRect(obj.pozitie);
            end
        end

        function rect = pixelRect(obj, poz)
            L = obj.layout;
            pad = (L.square - L.piece) / 2;
            x = L.left + L.square * poz(1) + pad;
            y = L.bottom + L.square * poz(2) + pad;
            rect = [x, y, L.piece, L.piece];
        end

        function muta(obj, mousePos)
            d = obj.layout.piece;
            obj.imagine.Position = [mousePos(1) - d/2, mousePos(2) - d/2, d, d];
        end

        function mutaLaNouaPozitie(obj, poz)
            obj.pozitie = poz;
            obj.imagine.Position = obj.pixelRect(poz);
            drawnow expose;
        end

        function promoveaza(obj, tipNou)
            obj.tip = tipNou;
            img = obj.resolveImagePath(obj.getImagine(tipNou));
            if isempty(img)
                return;
            end
            if ~isempty(obj.imagine) && isvalid(obj.imagine)
                obj.imagine.ImageSource = img;
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
