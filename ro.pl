%Drawing the board..
size(5).

print_board(Size) :-
    print_row_separator(Size),
    print_rows(Size, 1),
    print_row_separator(Size).

print_rows(Size, Row) :-
    (Row > Size -> true ; print_row(Size, Row, 1), NextRow is Row + 1, print_rows(Size, NextRow)).

print_row(Size, Row, Col) :-
    (Col > Size -> write('|'), nl ; print_cell(Row, Col), NextCol is Col + 1, print_row(Size, Row, NextCol)).

print_cell(Row, Col) :-
    (write('|'),
     fixed_cell(Row, Col, Num) -> write('[ '), write(Num), write(' ]') ;
     (solve_cell(Row, Col, Color) -> write('['), write(Color), write(']') ;
     write('[   ]'))).


print_row_separator(Size) :-
    write_list('-', 4*Size), nl.

write_list(_, 0).
write_list(Item, N) :-
    write(Item),
    N1 is N - 1,
    write_list(Item, N1).

fixed_cell(1, 5, 1).
fixed_cell(1, 1, 4).
fixed_cell(3, 5, 2).
fixed_cell(5, 4, 1).
fixed_cell(2, 4, 2). %هي الخلية ويلي تحتها بينشالوا بالطلب الأول
fixed_cell(3, 1, 2).

/*
 solve_cell(1, 1, blue).
 solve_cell(1, 2, blue).
 solve_cell(1, 3, blue).
 solve_cell(1, 4, blue).

 solve_cell(2, 1, blue).
 solve_cell(2, 2, green).
 solve_cell(2, 4, blue).
 solve_cell(2, 5, blue).

 solve_cell(3, 1, blue).
 solve_cell(3, 2, green).
 solve_cell(3, 3, blue).
 solve_cell(3, 4, green).

 solve_cell(4, 1, blue).
 solve_cell(4, 2, green).
 solve_cell(4, 3, blue).
 solve_cell(4, 4, blue).
 solve_cell(4, 5, green).

 solve_cell(5, 1, blue).
 solve_cell(5, 2, blue).
 solve_cell(5, 3, blue).
 solve_cell(5, 5, blue).

*/
:- dynamic solve_cell/3.

is_blue_with_green_neighbors(Row, Col) :-
    solve_cell(Row, Col, blue),
    RowUp is Row - 1, get_cell_color(RowUp, Col, green),
    RowDown is Row + 1, get_cell_color(RowDown, Col, green),
    ColLeft is Col - 1, get_cell_color(Row, ColLeft, green),
    ColRight is Col + 1, get_cell_color(Row, ColRight, green).

%firstly:first..
get_neighbors(Row, Col, Neighbors) :-
    get_cell_color(Row, Col, Color),
    find_neighbors(Row, Col, Color, [], Neighbors).


find_neighbors(Row, Col, Color, Acc, Neighbors) :-
    findall([X, Y],
            (neighbor_position(Row, Col, X, Y),
             get_cell_color(X, Y, Color),
             \+ member([X, Y], Acc)),
            NewNeighbors),
    append(NewNeighbors, Acc, Neighbors).

get_cell_color(Row, Col, green) :-
    fixed_cell(Row, Col, _), !.
get_cell_color(Row, Col, Color) :-
    solve_cell(Row, Col, Color).

neighbor_position(Row, Col, X, Y) :-
    (X is Row + 1, Y is Col);
    (X is Row - 1, Y is Col);
    (X is Row, Y is Col + 1);
    (X is Row, Y is Col - 1).

get_island(Row, Col, Island) :-
    get_neighbors(Row, Col, Neighbors),
    explore_neighbors(Neighbors, [[Row, Col]], Island).

explore(Row, Col, _, Visited, Island) :-
    member([Row, Col], Visited),
    !,
    Island = Visited.
explore(Row, Col, Color, Visited, Island) :-
    find_neighbors(Row, Col, Color, Visited, Neighbors),
    explore_neighbors(Neighbors, [[Row, Col] | Visited], Island).

explore_neighbors([], Island, Island).
explore_neighbors([[Row, Col] | Rest], Visited, Island) :-
    get_cell_color(Row, Col, Color),
    explore(Row, Col, Color, Visited, NewVisited),
    explore_neighbors(Rest, NewVisited, Island).

%firstly:second..
get_sea_or_island(Row, Col, Result) :-
    get_neighbors(Row, Col, Result).

find_blue_with_green_neighbors(Size, Row, Col) :-
    (Row > Size -> false
    ; (Col > Size -> NextRow is Row + 1, find_blue_with_green_neighbors(Size, NextRow, 1)
    ; (is_blue_with_green_neighbors(Row, Col) -> true
    ; NextCol is Col + 1, find_blue_with_green_neighbors(Size, Row, NextCol)))).

%firstly:third
%one:
one_sea :-
    size(Size),
        find_blue_with_green_neighbors(Size, 1, 1).

%two:
one_fixed_cell_in_island :-
    size(Size),
    findall(Islands, (between(1, Size, Row), between(1, Size, Col), get_island(Row, Col, Islands)), AllIslands),
    remove_duplicates(AllIslands, UniqueIslands),
    forall(member(Island, UniqueIslands), valid_island(Island)).

%three:
valid_island(Island) :-
    findall(Cell, (member([Row, Col], Island), fixed_cell(Row, Col, Cell)), FixedCells),
    length(FixedCells, Length),
    Length =< 1.

no_four_blue_cells_adjacent :-
    \+ (between(1, 4, Row),
        between(1, 4, Col),
        check_square_2x2(Row, Col)).

check_square_2x2(Row, Col) :-
    R1 is Row + 1,
    C1 is Col + 1,
    solve_cell(Row, Col, blue),
    solve_cell(Row, C1, blue),
    solve_cell(R1, Col, blue),
    solve_cell(R1, C1, blue).

%four:
island_number_equals_size :-
    size(Size),
    forall((between(1, Size, Row), between(1, Size, Col), fixed_cell(Row, Col, Num)),
           (get_island(Row, Col, Island),
            list_length(Island, Length),
            Length == Num)).

remove_duplicates([], []).
remove_duplicates([H|T], Result) :-
    member(H, T),
    !,
    remove_duplicates(T, Result).
remove_duplicates([H|T], [H|Result]) :-
    remove_duplicates(T, Result).


solve :-
    one_fixed_cell_in_island,
    \+ one_sea,
    island_number_equals_size,
    no_four_blue_cells_adjacent.


%secondly:starting strategy: island_of_1 strategy:

island_of_1 :-retractall(solve_cell(_,_,_)),
    size(Size),
    between(1, Size, Row),
    between(1, Size, Col),
    (   ( fixed_cell(Row, Col, 1)) ->
        (Col2 is Col - 1, assert(solve_cell(Row, Col2, blue))),
        (Row2 is Row - 1, assert(solve_cell(Row2, Col, blue)));
    true
    ),

    fail;
    true.

island_of_11 :-  size(Size),
    between(1, Size, Row),
    between(1, Size, Col),
    (   ( fixed_cell(Row, Col, 1)) ->
        (Col2 is Col + 1, assert(solve_cell(Row, Col2, blue))),
        (Row2 is Row + 1, assert(solve_cell(Row2, Col, blue)));
    true
    ),

    fail;
    true.

 %secondly:starting strategy: clues_separated_by_one_square strategy:

clues_separated_by_one_square :-
    size(Size),
   (    between(1, Size, Row),
    between(1, Size, Col),
    (   (Col1 is Col - 2, fixed_cell(Row, Col, _), fixed_cell(Row, Col1, _)) ->
        (Col2 is Col - 1, assert(solve_cell(Row, Col2, blue)));
        true
    ),
    (   (Row1 is Row - 2, fixed_cell(Row, Col, _), fixed_cell(Row1, Col, _)) ->
        (Row2 is Row - 1, assert(solve_cell(Row2, Col, blue)));
        true
    ),
    (   ( Col1 is Col+2, fixed_cell(Row, Col, _), fixed_cell(Row, Col1, _)) ->
        (Col2 is Col + 1, assert(solve_cell(Row, Col2, blue)));
        true
    ),
    (   (Row1 is Row + 2, fixed_cell(Row, Col, _), fixed_cell(Row1, Col, _)) ->
        (Row2 is Row + 1, assert(solve_cell(Row2, Col, blue)));
        true
    ),

    fail;
    true,
print_board(5)).

 %secondly:starting strategy: diagonally_adjacent_clues strategy:

diagonally_adjacent_clues :-
    size(Size),
   ( between(1, Size, Row),
    between(1, Size, Col),
    (   (Row1 is Row - 1, Col1 is Col - 1, fixed_cell(Row, Col, _), fixed_cell(Row1, Col1, _)) ->
        (Col2 is Col - 1, assert(solve_cell(Row, Col2, blue)), Row2 is Row - 1, assert(solve_cell(Row2, Col, blue)));
        true
    ),
    (   (Row1 is Row - 1, Col1 is Col + 1, fixed_cell(Row, Col, _), fixed_cell(Row1, Col1, _)) ->
        (Row2 is Row - 1, assert(solve_cell(Row2, Col, blue)), Col2 is Col + 1, assert(solve_cell(Row, Col2, blue)));
        true
    ),
    (   (Row1 is Row + 1, Col1 is Col - 1, fixed_cell(Row, Col, _), fixed_cell(Row1, Col1, _)) ->
        (Col2 is Col - 1, assert(solve_cell(Row, Col2, blue)), Row2 is Row + 1, assert(solve_cell(Row2, Col, blue)));
        true
    ),
    (   (Row1 is Row + 1, Col1 is Col + 1, fixed_cell(Row, Col, _), fixed_cell(Row1, Col1, _)) ->
        (Col2 is Col + 1, assert(solve_cell(Row, Col2, blue)), Row2 is Row + 1, assert(solve_cell(Row2, Col, blue)));
        true
    ),

    fail;
    true,
print_board(5)).


 %secondly:basic strategy: wall_expansion strategy:

 wall_expansion :-
    size(Size),
   ( between(1, Size, Row),
    between(1, Size, Col),
    (   ( solve_cell(1, 2, blue)) ->
        (Col2 is Col - 1,Row1 is Row+1,Row2 is Row+2 ,
         assert(solve_cell(Row, Col2, blue)),
         assert(solve_cell(Row1, Col2, blue)),
         assert(solve_cell(Row2, Col2, blue)));
        true
    ),
     (   ( solve_cell(1, Size-1, blue)) ->
        (Col2 is Size - 1,Row1 is Row+1,Row2 is Row+2 ,
         assert(solve_cell(Row, Col2, blue)),
         assert(solve_cell(Row1, Col2, blue)),
         assert(solve_cell(Row2, Col2, blue)));
        true
    ),
     (   ( solve_cell(Size, 2, blue)) ->
        (Col2 is Col - 1,Row1 is Row-1,Row2 is Row-2 ,
         assert(solve_cell(Row, Col2, blue)),
         assert(solve_cell(Row1, Col2, blue)),
         assert(solve_cell(Row2, Col2, blue)));
        true
    ),
     (   ( solve_cell(Size, Size-1, blue)) ->
        (Col2 is Size - 1,Row1 is Row-1,Row2 is Row-2 ,
         assert(solve_cell(Row, Col2, blue)),
         assert(solve_cell(Row1, Col2, blue)),
         assert(solve_cell(Row2, Col2, blue)));
        true
    ),

       fail;
       true,
print_board(5)).



update_solved_cells :-
   island_of_1 ,
   island_of_11.

print_updated_board :-
    update_solved_cells,
    print_board(5).

 %main prdicate..
 run :-
    print_updated_board.

