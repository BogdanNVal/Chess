classdef Bitboard < handle

    properties
        % Piese Albe
        P       uint64 % pioni
        N       uint64 % cai
        B       uint64 % nebuni
        R       uint64 % ture
        K       uint64 % rege
        Q       uint64 % regina

        % piese Negre
        p       uint64 % pioni
        n       uint64 % cai
        b       uint64 % nebuni
        r       uint64 % ture
        k       uint64 % rege
        q       uint64 % regina

        pieseA  uint64
        pieseN  uint64
        tabla   uint64

        flags   uint8 %
    end


    methods
        function obj = Bitboard(fen)
            % Constructor
            obj.FEN(fen);
        end

        function reseteaza(obj)
            % reprezentarea pe 64 de biti a pozitiilor pieselor
            obj.P = 0;
            obj.N = 0;
            obj.B = 0;
            obj.R = 0;
            obj.K = 0;
            obj.Q = 0;

            obj.p = 0;
            obj.n = 0;
            obj.b = 0;
            obj.r = 0;
            obj.k = 0;
            obj.q = 0;

            obj.pieseA = 0;
            obj.pieseN = 0;
            obj.tabla = 0;

            obj.flags = 0;

        end


        function FEN(obj, fen)
            % setarea tablei folosind FEN
            obj.reseteaza();
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

                    obj.(piese(i)) = bitset(obj.(piese(i)), 8*linie+coloana+1);
                    obj.tabla = bitset(obj.tabla, 8*linie+coloana+1);
                    if isstrprop(piese(i), 'lower')
                        obj.pieseN = bitset(obj.pieseN, 8*linie+coloana+1);
                    else
                        obj.pieseA = bitset(obj.pieseA, 8*linie+coloana+1);
                    end
                    coloana = coloana + 1;

                end
            end

            if str{2} == 'b'
                obj.flags = bitset(obj.flags, 1);
            end
            flag = str{3};
            for i = 1:strlength(flag)

                switch flag(i)
                    case 'K'
                        obj.flags = bitset(obj.flags, 2);
                    case 'Q'
                        obj.flags = bitset(obj.flags, 3);
                    case 'k'
                        obj.flags = bitset(obj.flags, 4);
                    case 'q'
                        obj.flags = bitset(obj.flags, 5);

                end

            end

        end

        function ocupat = Ocupat(obj, poz)
            % Verifica daca un patrat este ocupat
            ocupat = 0;
            if bitand(obj.tabla, bitshift(uint64(1), poz))

                ocupat = 1;
            end
        end

        function piesa = obtinePiesa(obj, poz)
            %gaseste ce piesa este pe un anumit patrat
            piesa = "0";
            if bitand(obj.P, bitshift(uint64(1), poz)) ~= 0
                piesa = "P";
            elseif bitand(obj.N, bitshift(uint64(1), poz)) ~= 0
                piesa = "N";
            elseif bitand(obj.B, bitshift(uint64(1), poz)) ~= 0
                piesa = "B";
            elseif bitand(obj.R, bitshift(uint64(1), poz)) ~= 0
                piesa = "R";
            elseif bitand(obj.K, bitshift(uint64(1), poz)) ~= 0
                piesa = "K";
            elseif bitand(obj.Q, bitshift(uint64(1), poz)) ~= 0
                piesa = "Q";
            elseif bitand(obj.p, bitshift(uint64(1), poz)) ~= 0
                piesa = "p";
            elseif bitand(obj.n, bitshift(uint64(1), poz)) ~= 0
                piesa = "n";
            elseif bitand(obj.b, bitshift(uint64(1), poz)) ~= 0
                piesa = "b";
            elseif bitand(obj.r, bitshift(uint64(1), poz)) ~= 0
                piesa = "r";
            elseif bitand(obj.k, bitshift(uint64(1), poz)) ~= 0
                piesa = "k";
            elseif bitand(obj.q, bitshift(uint64(1), poz)) ~= 0
                piesa = "q";
            end
        end

        function piesa = obtineValoare(obj, poz)
            % 1-pion , 2-cal, 3-nebun, 4-tura, 5-regina, 6-rege
            piesa = 0;
            if bitand(obj.P, bitshift(uint64(1), poz)) ~= 0 || bitand(obj.p, bitshift(uint64(1), poz)) ~= 0
                piesa = 1;
            elseif bitand(obj.N, bitshift(uint64(1), poz)) ~= 0 || bitand(obj.n, bitshift(uint64(1), poz)) ~= 0
                piesa = 2;
            elseif bitand(obj.B, bitshift(uint64(1), poz)) ~= 0 || bitand(obj.b, bitshift(uint64(1), poz)) ~= 0
                piesa = 3;
            elseif bitand(obj.R, bitshift(uint64(1), poz)) ~= 0 || bitand(obj.r, bitshift(uint64(1), poz)) ~= 0
                piesa = 4;
            elseif bitand(obj.Q, bitshift(uint64(1), poz)) ~= 0 || bitand(obj.q, bitshift(uint64(1), poz)) ~= 0
                piesa = 5;
            elseif bitand(obj.K, bitshift(uint64(1), poz)) ~= 0 || bitand(obj.k, bitshift(uint64(1), poz)) ~= 0
                piesa = 6;
            end
        end


        function actualizareTabla(obj, mutare)
            % Actualizeaza tabla
            obj.tabla = bitxor(obj.tabla, bitshift(uint64(1), mutare(1)));
            obj.tabla = bitor(obj.tabla, bitshift(uint64(1), mutare(2)));
            f = bitget(obj.flags, 1);
            if f
                obj.pieseN = bitxor(obj.pieseN, bitshift(uint64(1), mutare(1)));
                obj.pieseN = bitor(obj.pieseN, bitshift(uint64(1), mutare(2)));
                if mutare(4)
                    obj.pieseA = bitxor(obj.pieseA, bitshift(uint64(1), mutare(2)));
                end
            else
                obj.pieseA = bitxor(obj.pieseA, bitshift(uint64(1), mutare(1)));
                obj.pieseA = bitor(obj.pieseA, bitshift(uint64(1), mutare(2)));
                if mutare(4)
                    obj.pieseN = bitxor(obj.pieseN, bitshift(uint64(1), mutare(2)));
                end
            end


            switch mutare(3)
                case 1
                    c = 80; % P = 80
                case 2
                    c = 78; % N = 78
                case 3
                    c = 66; % B = 66
                case 4
                    c = 82; % R = 82
                case 5
                    c = 81; % Q = 81
                case 6
                    c = 75; % K = 75
            end
            obj.(char(c+f*32)) = bitxor(obj.(char(c+f*32)), bitshift(uint64(1), mutare(1)));
            obj.(char(c+f*32)) = bitor(obj.(char(c+f*32)), bitshift(uint64(1), mutare(2)));

            switch mutare(4)
                case 0
                    c = 0;
                case 1
                    c = 80; % P = 80
                case 2
                    c = 78; % N = 78
                case 3
                    c = 66; % B = 66
                case 4
                    c = 82; % R = 82
                case 5
                    c = 81; % Q = 81
                case 6
                    c = 75; % K = 75

            end

            obj.flags = bitxor(obj.flags, uint8(1));
            f = bitget(obj.flags, 1);
            if c
                obj.(char(c+f*32)) = bitxor(obj.(char(c+f*32)), bitshift(uint64(1), mutare(2)));
            end

        end

       
        function anulareMutare(obj, mutare)
            
            switch mutare(4)
                case 0
                    c = 0;
                case 1
                    c = 80; % P = 80
                case 2
                    c = 78; % N = 78
                case 3
                    c = 66; % B = 66
                case 4
                    c = 82; % R = 82
                case 5
                    c = 81; % Q = 81
                case 6
                    c = 75; % K = 75

            end

            f = bitget(obj.flags, 1);
            if c
                obj.(char(c+f*32)) = bitor(obj.(char(c+f*32)), bitshift(uint64(1), mutare(2)));
            end


            obj.flags = bitxor(obj.flags, uint8(1));
            obj.tabla = bitor(obj.tabla, bitshift(uint64(1), mutare(1)));
            f = bitget(obj.flags, 1);

            if f
                obj.pieseN = bitor(obj.pieseN, bitshift(uint64(1), mutare(1)));
                obj.pieseN = bitxor(obj.pieseN, bitshift(uint64(1), mutare(2)));
                if mutare(4)
                    obj.pieseA = bitor(obj.pieseA, bitshift(uint64(1), mutare(2)));
                else
                    obj.tabla = bitxor(obj.tabla, bitshift(uint64(1), mutare(2)));
                end
            else
                obj.pieseA = bitor(obj.pieseA, bitshift(uint64(1), mutare(1)));
                obj.pieseA = bitxor(obj.pieseA, bitshift(uint64(1), mutare(2)));
                if mutare(4)
                    obj.pieseN = bitxor(obj.pieseN, bitshift(uint64(1), mutare(2)));
                else
                    obj.tabla = bitxor(obj.tabla, bitshift(uint64(1), mutare(2)));
                end
            end

            switch mutare(3)
                case 1
                    c = 80; % P = 80
                case 2
                    c = 78; % N = 78
                case 3
                    c = 66; % B = 66
                case 4
                    c = 82; % R = 82
                case 5
                    c = 81; % Q = 81
                case 6
                    c = 75; % K = 75
            end
            obj.(char(c+f*32)) = bitor(obj.(char(c+f*32)), bitshift(uint64(1), mutare(1)));
            obj.(char(c+f*32)) = bitxor(obj.(char(c+f*32)), bitshift(uint64(1), mutare(2)));


        end


        function scor = evaluareTabla(obj)
            % Evaluarea pozitiei

            % Valori piese
            Pion = 100;
            Cal = 300;
            Nebun = 310;
            Tura = 500;
            Regina = 900;
            Rege = 10000;

            scor = 0;
            scor = scor + Pion * (sum(bitget(obj.P, 1:64)) - sum(bitget(obj.p, 1:64)));
            scor = scor + Cal * (sum(bitget(obj.N, 1:64)) - sum(bitget(obj.n, 1:64)));
            scor = scor + Nebun * (sum(bitget(obj.B, 1:64)) - sum(bitget(obj.b, 1:64)));
            scor = scor + Tura * (sum(bitget(obj.R, 1:64)) - sum(bitget(obj.r, 1:64)));
            scor = scor + Regina * (sum(bitget(obj.Q, 1:64)) - sum(bitget(obj.q, 1:64)));
            scor = scor + Rege * (sum(bitget(obj.K, 1:64)) - sum(bitget(obj.k, 1:64)));

        end

        function disp(obj)

            fprintf("Tabla:\n");

            for i = 7:-1:0
                for j = 0:7
                    fprintf(" "+obj.obtinePiesa(8*i+j))
                end
                fprintf("\n")
            end
        end

    end

end
