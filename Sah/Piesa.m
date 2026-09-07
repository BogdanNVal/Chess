classdef Piesa < handle
    properties
        tip
        pozitie % [coloana, linie] 0-based
        imagine
        fig
    end

    properties (Constant)
        % Must match Sah board axes: Position [48,50,800,800] → 100px squares
        BOARD_LEFT = 48
        BOARD_BOTTOM = 50
        SQUARE = 100
        PIECE = 88   % centered in square with 6px padding on each side
    end

    methods
        function obj = Piesa(tip, pozitie, fig)
            obj.tip = tip;
            obj.pozitie = pozitie;
            obj.fig = fig;

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

        function rect = pixelRect(~, poz)
            % Center piece sprite inside its board square (same for all ranks)
            pad = (Piesa.SQUARE - Piesa.PIECE) / 2;
            x = Piesa.BOARD_LEFT + Piesa.SQUARE * poz(1) + pad;
            y = Piesa.BOARD_BOTTOM + Piesa.SQUARE * poz(2) + pad;
            rect = [x, y, Piesa.PIECE, Piesa.PIECE];
        end

        function muta(obj, mousePos)
            d = Piesa.PIECE;
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
