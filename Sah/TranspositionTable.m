classdef TranspositionTable < handle
    % TT de dimensiune fixă. Intrare: key, depth, score, flag, move(1×6)
    % flag: 0 exact, 1 lower (bound inferior), 2 upper (bound superior)

    properties
        size
        keys
        depths
        scores
        flags
        moves
        hits
        stores
    end

    methods
        function obj = TranspositionTable(n)
            if nargin < 1
                n = 1e5;
            end
            obj.size = n;
            obj.keys = zeros(n, 1, 'uint64');
            obj.depths = -ones(n, 1);
            obj.scores = zeros(n, 1);
            obj.flags = zeros(n, 1, 'uint8');
            obj.moves = zeros(n, 6);
            obj.hits = 0;
            obj.stores = 0;
        end

        function clear(obj)
            obj.keys(:) = 0;
            obj.depths(:) = -1;
            obj.scores(:) = 0;
            obj.flags(:) = 0;
            obj.moves(:) = 0;
            obj.hits = 0;
            obj.stores = 0;
        end

        function idx = index(obj, key)
            idx = double(mod(key, uint64(obj.size))) + 1;
        end

        function store(obj, key, depth, score, flag, move)
            idx = obj.index(key);
            if obj.depths(idx) <= depth
                obj.keys(idx) = key;
                obj.depths(idx) = depth;
                obj.scores(idx) = score;
                obj.flags(idx) = flag;
                if nargin >= 6 && ~isempty(move)
                    m = zeros(1, 6);
                    m(1:numel(move)) = move(1:min(6,numel(move)));
                    obj.moves(idx, :) = m;
                end
                obj.stores = obj.stores + 1;
            end
        end

        function [found, depth, score, flag, move] = probe(obj, key)
            idx = obj.index(key);
            if obj.keys(idx) == key && obj.depths(idx) >= 0
                found = true;
                depth = obj.depths(idx);
                score = obj.scores(idx);
                flag = obj.flags(idx);
                move = obj.moves(idx, :);
                obj.hits = obj.hits + 1;
            else
                found = false;
                depth = -1;
                score = 0;
                flag = 0;
                move = [];
            end
        end
    end
end
