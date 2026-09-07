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
                layout = struct( ...
                    'left', 48, 'bottom', 50, ...
                    'squareX', 100, 'squareY', 100, ...
                    'pieceX', 78, 'pieceY', 78);
            end
            obj.layout = obj.normalizeLayout(layout);

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
            obj.layout = obj.normalizeLayout(layout);
            if ~isempty(obj.imagine) && isvalid(obj.imagine)
                obj.imagine.Position = obj.pixelRect(obj.pozitie);
            end
        end

        function layout = normalizeLayout(~, layout)
            % Accept legacy square/piece fields or explicit X/Y metrics.
            if isfield(layout, 'squareX') && isfield(layout, 'squareY')
                sqX = layout.squareX;
                sqY = layout.squareY;
            elseif isfield(layout, 'square')
                sqX = layout.square;
                sqY = layout.square;
            else
                sqX = 100; sqY = 100;
            end
            if isfield(layout, 'pieceX') && isfield(layout, 'pieceY')
                pcX = layout.pieceX;
                pcY = layout.pieceY;
            elseif isfield(layout, 'piece')
                pcX = layout.piece;
                pcY = layout.piece;
            else
                pcX = round(sqX * 0.78);
                pcY = round(sqY * 0.78);
            end
            left = 48; bottom = 50;
            if isfield(layout, 'left'), left = layout.left; end
            if isfield(layout, 'bottom'), bottom = layout.bottom; end
            layout = struct( ...
                'left', left, 'bottom', bottom, ...
                'squareX', sqX, 'squareY', sqY, ...
                'pieceX', pcX, 'pieceY', pcY);
        end

        function rect = pixelRect(obj, poz)
            L = obj.layout;
            padX = (L.squareX - L.pieceX) / 2;
            padY = (L.squareY - L.pieceY) / 2;
            x = L.left + L.squareX * poz(1) + padX;
            y = L.bottom + L.squareY * poz(2) + padY;
            rect = [x, y, L.pieceX, L.pieceY];
        end

        function muta(obj, mousePos)
            dx = obj.layout.pieceX;
            dy = obj.layout.pieceY;
            obj.imagine.Position = [mousePos(1) - dx/2, mousePos(2) - dy/2, dx, dy];
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
