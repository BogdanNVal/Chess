classdef Piesa < handle
    properties
        tip
        pozitie % [coloana, linie]
        imagine
    end

    methods
        function obj = Piesa(tip, pozitie, fig)
            obj.tip = tip;
            obj.pozitie = pozitie;


            % Desenează piesa pe UI
            l = 98;
            x = 63;
            y = 66;
            img = obj.getImagine(tip);
            obj.imagine = uiimage(fig, 'ImageSource', img, 'Position', [x + l * pozitie(1), y + 97 * pozitie(2), l, l]);
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

        function muta(obj, mousePos)
            dimensiune = 98;
            poz = [mousePos(1) - dimensiune / 2, mousePos(2) - dimensiune / 2, dimensiune, dimensiune];
            obj.imagine.Position = poz;
        end

        function mutaLaNouaPozitie(obj, poz)
            obj.pozitie = poz;
            l = 98;
            x = 63;
            y = 66;
            obj.imagine.Position = [x + l * poz(1), y + 97 * poz(2), l, l];
            drawnow expose;

        end


        function delete(obj)
            delete(obj.imagine);
        end


    end
end
