:- module(bot,
      [  get_moves/3
      ]).
	
% Fonction principale
get_moves(Moves, _, Board):-moveandWin(Board, Moves,0,silver).
get_moves(Moves, _, Board):-play(Board,Moves,0).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%% Fonctions auxiliaires  %%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Concaténation de deux listes
concat([],L2,L2).
concat([T|Q],L2,[T|R]):-concat(Q,L2,R).

% Vérifie si deux termes non numériques sont différents.
diff(X,X):-!,fail.
diff(_,_).

% Retourne vrai si X (arg1) est dans la liste (arg2)
element(X,[X|_]).
element(X,[_|T]):-element(X,T).

% Retire un élément (arg1) du board (arg2) et renvoyant le résultat dans arg3

retire_element(X,[X|Q],Q):-!.
retire_element(X,[T|Q],[T|R1]):-retire_element(X,Q,R1).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%% Fonctions propres au jeu  %%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Fonction qui vérifie si on peut jouer selon le nombre de coups
verifyCounter(NbCoups):-NbCoups>=0,NbCoups<4.

% Retourne true si le pion passé en paramètre est sur les coordonnées [X,Y]
isOn([X,Y,_,_],[X,Y]).

% Retourne true si aucun pion du plateau n est sur les coordonnées [X,Y]
isEmpty([], [_,_]).
isEmpty([H|Q], [X,Y]):- not(isOn(H,[X,Y])), isEmpty(Q,[X,Y]).

% Retourne true si la case est une trappe
isDarkSquare([2,2]).
isDarkSquare([2,5]).
isDarkSquare([5,2]).
isDarkSquare([5,5]).

% Retourne true s il existe un pion gold sur la position [X,Y]
hasGoldOnThePosition([X,Y], [[X,Y,Type,gold]|_],Type).
hasGoldOnThePosition([X,Y], [_|T],_):-hasGoldOnThePosition([X,Y], T,_).

% Retourne si l'emplacement est compris dans le jeu
isOntheBoard([X,Y]):- X>=0,X=<7,Y>=0,Y=<7.

% Constantes: Définition des priorités
% Pas forcément 1,2,3,4 etc. Ici horse=6 et rabbit=3 => Un cheval équivaut à avoir deux lapins
lengthPriority(elephant, 8).
lengthPriority(dog, 7).
lengthPriority(horse, 6).
lengthPriority(camel, 5).
lengthPriority(cat, 4).
lengthPriority(rabbit, 3).

% Retourne true si le typeA a une plus grande priorité que le deuxieme
isStrongerThan(TypeA,TypeB):-lengthPriority(TypeA, X), lengthPriority(TypeB, Y), X>Y.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     Fonction existNear     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Permet de récupérer un ensemble de pièces d'une couleur définie par le 3eme argument, adverses ou non, à proximité (autour) d'une coordonnée, 
% grâce à des appels récursifs

%Argument1:Coordonnées dont nous voulons récupérer les pièces aux alentours
%Argument2:Board
%Argument3:sidePiece {gold,silver}, pièces "retourner"
%Argument4:ensemble de solutions

existNear(_,[],_,[]):-!.

existNear([Row,Col],[[PRow,Col,Type,SidePiece]|Q],SidePiece,[[PRow,Col,Type,SidePiece]|Solutions]):- PRow is Row+1,existNear([Row,Col],Q,SidePiece,Solutions),!.

%Vérification sur les côtés
existNear([Row,Col],[[Row,PCol,Type,SidePiece]|Q],SidePiece,[[Row,PCol,Type,SidePiece]|Solutions]):- PCol is Col-1,existNear([Row,Col],Q,SidePiece,Solutions),!.
existNear([Row,Col],[[Row,PCol,Type,SidePiece]|Q],SidePiece,[[Row,PCol,Type,SidePiece]|Solutions]):- PCol is Col+1,existNear([Row,Col],Q,SidePiece,Solutions),!.

%Vérification sur l'arrière
existNear([Row,Col],[[PRow,Col,Type,SidePiece]|Q],SidePiece,[[PRow,Col,Type,SidePiece]|Solutions]):- PRow is Row-1,existNear([Row,Col],Q,SidePiece,Solutions),!.

%La pièce en tête du 2eme argument ne vérifie aucun des cas précédents, on passe aux pièces suivantes contenues dans Q
existNear([Row,Col],[_|Q],SidePiece,Solutions):-existNear([Row,Col],Q,SidePiece,Solutions).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Fonction goldAndStrongerNear%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Fonction qui permet de vérifier s' il n'existe pas de pions adversaires (gold) plus forts autour de la potentielle nouvelle place située en [Row,Col]
%PType = le type du pion adverse qui a une plus grande priorité que le pion que l'on veut faire bouger
% la variable Solutions contient les pions qui sont autour d'une trappe (Dark square)

goldAndStrongerNear([Row,Col,Type,silver],Board):-existNear([Row,Col],Board,gold,Solutions), element([_,_,PType,_],Solutions),isStrongerThan(PType,Type),!.

goldNearDarkSquare([Row,Col],Board,Solutions):-isDarkSquare([Row,Col]),existNear([Row,Col],Board,gold,Solutions).

% Amélioration possible : les faire plus génériques en utilisant le prédicat sideAdverse pour déterminer les pièces silver à proximité des pièces gold/trappes.
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Fonction scorecalcul    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%permet le calcul du score d'un joueur (somme des valeurs des pièces)
% Type = le type de pion
% Side = silver/gold
scoreCalcul([],0).
%Prise en compte dans le score de la position des lapins (vers la ligne gagnante)
scoreCalcul([[CoordX,_,rabbit,Side]|R], ActualScore, Side) :- scoreCalcul(R,N1), lengthPriority(rabbit,X), ActualScore is CoordX+N1+X,!.
scoreCalcul([[_,_,Type,Side]|R], ActualScore, Side) :- scoreCalcul(R,N1), lengthPriority(Type,X), ActualScore is N1+X.

% Fonction d'évaluation : Score contient la différence de points de valeur.
% Plus Score est grand, plus la situation est favorable pour Silver
evaluateFunction(Board,Score):-
	scoreCalcul(Board,ScoreSilver,silver), 
	scoreCalcul(Board,ScoreGold,gold), 
	Score is ScoreSilver - ScoreGold.

% Max contient l'état du Board pour lequel la fonction d'évaluation retourne le meilleur score
% Le premier argument contient alors une liste contenant tout les états de Board que l'on veut tester
bestShotPossible([Max], Max):-!.
bestShotPossible([Head|List], Max):- 
	bestShotPossible(List, MaxList),
	evaluateFunction(Head, ScoreHead),
	evaluateFunction(MaxList, MaxListScored),
	(ScoreHead > MaxListScored -> Max = Head ; Max = MaxList). % if -> then ; else

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      Fonction isLocked     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Retourne true s'il existe un pion du board (argument 2, Board) sur les coordonnées X,Y (argument 1)
existPionOn([X,Y], [[X,Y,_,_]|_]):-!.
existPionOn([X,Y], [_|T]):-existPionOn([X,Y], T).

%Retourne true si coordonnees directement adjacentes (pas diagonales)
areAdjacent([Row,Col],[Row,ColAdv]):-ColAdv is Col-1,!.
areAdjacent([Row,Col],[Row,ColAdv]):-ColAdv is Col+1,!.
areAdjacent([Row,Col],[RowAdv,Col]):-RowAdv is Row-1,!.
areAdjacent([Row,Col],[RowAdv,Col]):-RowAdv is Row+1,!.

% retourne le side adverse ; permet de génériser les autres fonctions
sideAdverse(silver,gold).
sideAdverse(gold,silver).

% retourne true si le pion (argument1) est gelé par un pion adverse adjacent plus fort

isLocked([Row,Col,Type,Side], [[RowAdv,ColAdv,TypeAdv,SideA]|_],Board):-
	sideAdverse(Side,SideA),
	isStrongerThan(TypeAdv,Type), %Pion adverse plus fort
	areAdjacent([Row,Col],[RowAdv,ColAdv]),
	existNear([Row,Col],Board,Side,[]),!. %vérifie si un pion ami n'est pas adjacent à la pièce (arg1), sinon elle n'est pas lockée.

isLocked(Pion, [_|Q],Board):-isLocked(Pion, Q,Board).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      Fonction isValid      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% permet de savoir si un coup est valide, c'est à dire si la position visée est libre, si nombre de coups le permet etc

%arg1:le pion à faire bouger
%arg2:coordonnées visées
%NbCoups:nb de coups joués

isValid_aux([Row,Col,Type,Side],[NewRow,NewCol], Board, NbCoups):-
	verifyCounter(NbCoups), %vérifie le compteur
	isOntheBoard([NewRow,NewCol]), %Vérifie que la case voulue est sur le board
	not(existPionOn([NewRow,NewCol], Board)), %vérifie que la case est libre
	not(isLocked([Row,Col,Type,Side], Board,Board)),!. %vérifie qu'il n'existe pas un pion plus fort qui "lock" notre pion

isValid([Row,Col,Type,Side],[NewRow,Col], Board, NbCoups):-
	isValid_aux([Row,Col,Type,Side],[NewRow,Col], Board, NbCoups),
	NewRow is Row+1,!. %Tous les pions silver peuvent aller vers le bas

isValid([Row,Col,Type,gold],[NewRow,Col], Board, NbCoups):-
	Type\=rabbit,
	isValid_aux([Row,Col,Type,gold],[NewRow,Col], Board, NbCoups),
	NewRow is Row+1,!. %Tous les pions peuvent aller vers le bas sauf les rabbits gold

isValid([Row,Col,Type,Side],[Row,NewCol], Board, NbCoups):-
	isValid_aux([Row,Col,Type,Side],[Row,NewCol], Board, NbCoups),
	NewCol is Col-1,!. %Tous les pions peuvent aller vers la gauche

isValid([Row,Col,Type,Side],[Row,NewCol], Board, NbCoups):-
	isValid_aux([Row,Col,Type,Side],[Row,NewCol], Board, NbCoups),
	NewCol is Col+1,!. %Tous les pions peuvent aller vers la droite

isValid([Row,Col,Type,silver],[NewRow,Col], Board, NbCoups):-
	Type\=rabbit, %sauf les lapins silver qui ne peuvent aller en arrière
	isValid_aux([Row,Col,Type,silver],[NewRow,Col], Board, NbCoups),
	NewRow is Row-1,!.

isValid([Row,Col,Type,gold],[NewRow,Col], Board, NbCoups):-
	isValid_aux([Row,Col,Type,gold],[NewRow,Col], Board, NbCoups),
	NewRow is Row-1,!. %Tous les pions gold peuvent aller vers le haut

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Fonction canMoveWithoutDead %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Fonction qui permet de savoir si un pion peut se déplacer sur une case sans mourir
%Attention: Ne vérifie pas si le coup est valide
%arg1: Pion [Row,Col,Type,SidePiece]
%arg2: Coordonnées visées [X,Y]
%arg3: Board
%Diff permet de s'assurer que le pion silver qui sert de "soutient" ne soit pas le même que celui qui veut se diriger sur la cellule

canMoveWithoutDead(_, CoordonneesVisees, _):-not(isDarkSquare(CoordonneesVisees)),!. %Pas une trappe = retourne true
canMoveWithoutDead([Row,Col,Type,silver], CoordonneesVisees, Board):- %permet de se mettre sur une darksquare sans mourir
	retire_element([Row,Col,Type,silver],Board,BoardTemp),
	existNear(CoordonneesVisees,BoardTemp,silver, Solutions), %Liste des pions silver autour de la case visée
	Solutions\=[].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Fonctions du tri du board %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
%Complexité : O(n^2)

%arg1: Board
%arg2: minimun/maximun actuel
%arg3: solution effectivement trouvé
%on itère sur le board tant qu'on n'est pas arrivé à la fin

%recherche du minimun
min([],[MinRow,MinCol,MinType,MinSidePiece],[MinRow,MinCol,MinType,MinSidePiece]):-!.
min([[Row,Col,Type,SidePiece]|Q],[MinRow,_,_,_],[SolRow,SolCol,SolType,SolSidePiece]):-Row<MinRow,min(Q,[Row,Col,Type,SidePiece],[SolRow,SolCol,SolType,SolSidePiece]),!.
min([[Row,Col,Type,SidePiece]|Q],[MinRow,MinCol,_,_],[SolRow,SolCol,SolType,SolSidePiece]):-Row=:=MinRow,Col=<MinCol,min(Q,[Row,Col,Type,SidePiece],[SolRow,SolCol,SolType,SolSidePiece]),!.
min([[_,_,_,_]|Q],[MinRow,MinCol,MinType,MinSidePiece],[SolRow,SolCol,SolType,SolSidePiece]):-min(Q,[MinRow,MinCol,MinType,MinSidePiece],[SolRow,SolCol,SolType,SolSidePiece]),!.

%recherche du maximun
max([],[MaxRow,MaxCol,MaxType,MaxSidePiece],[MaxRow,MaxCol,MaxType,MaxSidePiece]):-!.
max([[Row,Col,Type,SidePiece]|Q],[MaxRow,_,_,_],[SolRow,SolCol,SolType,SolSidePiece]):-Row>MaxRow,max(Q,[Row,Col,Type,SidePiece],[SolRow,SolCol,SolType,SolSidePiece]),!.
max([[Row,Col,Type,SidePiece]|Q],[MaxRow,MaxCol,_,_],[SolRow,SolCol,SolType,SolSidePiece]):-Row=:=MaxRow,Col>=MaxCol,max(Q,[Row,Col,Type,SidePiece],[SolRow,SolCol,SolType,SolSidePiece]),!.
max([[_,_,_,_]|Q],[MaxRow,MaxCol,MaxType,MaxSidePiece],[SolRow,SolCol,SolType,SolSidePiece]):-max(Q,[MaxRow,MaxCol,MaxType,MaxSidePiece],[SolRow,SolCol,SolType,SolSidePiece]),!.

%Tri du board en fonction d'un critère (arg3) {croissant|décroissant}
%arg1 : Board actuel
%arg2 : Board trié
trierBoard([],[],_):-!.
trierBoard([[Row,Col,Type,SidePiece]|Q],L,croissant):-
	min(Q,[Row,Col,Type,SidePiece],[SolRow,SolCol,SolType,SolSidePiece]),
	retire_element([SolRow,SolCol,SolType,SolSidePiece],[[Row,Col,Type,SidePiece]|Q],NewBoard),
	trierBoard(NewBoard,L2,croissant),
	concat([[SolRow,SolCol,SolType,SolSidePiece]],L2,L),!.
trierBoard([[Row,Col,Type,SidePiece]|Q],L,decroissant):-
	max(Q,[Row,Col,Type,SidePiece],[SolRow,SolCol,SolType,SolSidePiece]),
	retire_element([SolRow,SolCol,SolType,SolSidePiece],[[Row,Col,Type,SidePiece]|Q],NewBoard),
	trierBoard(NewBoard,L2,decroissant),
	concat([[SolRow,SolCol,SolType,SolSidePiece]],L2,L).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Fonctions de déplacement  %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% pousser : pushAndMove  %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%permet de savoir s'il existe un pion silver à côté d'une pièce gold et qui peut prend sa place
%arg1: emplacement de la pièce gold
%arg2: board
%arg3: pièce silver qui peut prendre la place
%arg4: board modifié en retirant la pièce silver
silverdAndStrongerNear([GRow,GCol,GType,gold],Board,[SRow,SCol,SType,_],NewBoard):-
	existNear([GRow,GCol],Board,silver,Solutions), 
	element([SRow,SCol,SType,_],Solutions),
	isStrongerThan(SType,GType),
	retire_element([GRow,GCol,GType,gold],Board,BoardTemp),
	isValid([SRow,SCol,SType,silver],[GRow,GCol], BoardTemp, 0),
	not(goldAndStrongerNear([GRow,GCol,SType,silver],BoardTemp)), %Si on n'est pas à côté d'un pion adverse qui a une plus grande priorité que notre pion
	canMoveWithoutDead([SRow,SCol,SType,silver], [GRow,GCol], BoardTemp), %on vérifie si malgré que la nouvelle position soit éventuellement une trappe, le coup est possible
	retire_element([SRow,SCol,SType,_],BoardTemp,NewBoard),!.

%Pousse un pion adverse sur une case noire
%arg1 : Board
%arg2: Concaténation des mouvements avec la nouvelle position du pion silver et celle du pion gold
%arg3: ancien nombre de coups
%arg4: nouveau nombre de coups 
%arg5: board mis à jour

pushAndMove(Board,[[[GoldRow,GoldCol],[DarkCoorX,DarkCoorY]],[[SilverRow,SilverCol],[GoldRow, GoldCol]]],OldNbCoups,NewNbCoups,NewBoard):- 
	element([DarkCoorX,DarkCoorY],[[2,2],[2,5],[5,2],[5,5]]), %on regarde si des pièces gold sont positionnées à côté d'une trappe
	goldNearDarkSquare([DarkCoorX,DarkCoorY],Board,Solutions),
	element([GoldRow,GoldCol,GoldType,_],Solutions),
	silverdAndStrongerNear([GoldRow,GoldCol,GoldType,_],Board,[SilverRow,SilverCol,SilverType,_],BoardTemp), %on regarde mtn si un pion silver peut déplacer le pion  gold trouvé dans la trappe
	concat([[DarkCoorX,DarkCoorY,GoldType,gold],[GoldRow,GoldCol,SilverType,silver]],BoardTemp,NewBoard), %on renvoie le nouveau board modifié
	NewNbCoups is OldNbCoups + 2,!.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%  tirer : pullAndMove  %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		
deplacementPull([Row,Col],[Row,NewCol]):-NewCol is Col-1.
deplacementPull([Row,Col],[Row,NewCol]):-NewCol is Col+1.
deplacementPull([Row,Col],[NewRow,Col]):-NewRow is Row-1.

%Fonction pull ; non utilisée
pullAndMove([Row,Col,Type,silver],Board,[[[Row,Col],[NewRow, NewCol]],[[GoldRow,Col],[Row,Col]]],OldNbCoups,NewNbCoups):- /*renvoyer le nouveau board éventuellement*/
	GoldRow is Row + 1,
	existNear([Row,Col],Board,gold,[[GoldRow,Col,GoldType,gold]]),% on regarde si un pion doré est situé devant un pion silver
	isStrongerThan(Type,GoldType),% on compare les types
	deplacementPull([Row,Col],[NewRow,NewCol]),% déplacement possible sur la même ligne Col+1/Col-1 ou en arrière
	isValid([Row,Col,Type,silver],[NewRow,NewCol],Board,0), %vérification si le coup est possible
	NewNbCoups is OldNbCoups + 2,!. %modification du nombre de coups

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Fonction moveDownPawn   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Fonction qui permet d'avancer un pion en avant

%1er argmt : Les pièces que l'on peut avancer
%2e argmt : Board
%3e argmt : Moves : prend en compte le mouvement si succès
%4e argmt : OldNbCoups : ancien nombre de coups
%5e argmt : NewNbCoups: nouveau nombre de coups (compte pour un)
%6e argmt : NewBoard (mis à jour)

moveDownPawn([],Board,_,OldNbCoups,OldNbCoups,Board):-fail,!. %en cas d'échec de trouver un coup valide pour avancer
	
moveDownPawn([[Row,Col,Type,silver]|_],Board,[[Row,Col],[NewRow,Col]],OldNbCoups,NewNbCoups,NewBoard):-
	NewRow is Row+1, 
	isValid([Row,Col,Type,silver],[NewRow,Col], Board, OldNbCoups), %on regarde si le coup est valide
	not(goldAndStrongerNear([NewRow,Col,Type,silver],Board)), %Si on n'est pas à côté d'un pion adverse qui a une plus grande priorité que notre pion
	canMoveWithoutDead([Row,Col,Type,silver], [NewRow,Col], Board), %on vérifie si malgré que la nouvelle position soit éventuellement une trappe, le coup est possible
	NewNbCoups is OldNbCoups + 1, 
	deplacerPion([Row, Col, Type, silver], [NewRow, Col, Type, silver], Board, NewBoard),!. %appel à la fonction qui met à jour le board

moveDownPawn([_|Q],Board, Moves,OldNbCoups,NewNbCoups,NewBoard):-moveDownPawn(Q,Board,Moves,OldNbCoups,NewNbCoups,NewBoard). 
%on fait des appels récursifs slmt si le coup n'était pas valide

%NewBoard contient le board en ayant effectué le déplacement (Arg1 -> Arg2)
deplacerPion([Row, Col, Type, Side], [NewRow, NewCol, Type, Side], Board, NewBoard):-
	retire_element([Row, Col, Type, Side], Board, BoardTmp),
	concat([[NewRow,NewCol,Type,Side]], BoardTmp, NewBoard).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Fonction moveandWin 	 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Définition des prédicats qui vont être utiles pour déterminer si un joueur peut gagner au tour
%Ces prédicats sont susceptibles d'être utilisés par d'autres règles.

% Permet de connaitre les déplacements autorisés pour les lapins (prise en compte de la couleur {silver,gold})
deplacementRabbit([Row,Col],[NewRow,Col],silver):-NewRow is Row+1.
deplacementRabbit([Row,Col],[NewRow,Col],gold):-NewRow is Row-1.
deplacementRabbit([Row,Col],[Row,NewCol],_):-NewCol is Col-1.
deplacementRabbit([Row,Col],[Row,NewCol],_):-NewCol is Col+1.

%arg1: Board à parcourir
%arg2: Liste des lapins sur le Board
%arg3: qui sont de "couleur" Side {gold,silver}
listeLapins([], [], _).
listeLapins([[Row,Col,rabbit, Side]|Q], Solutions, Side):-listeLapins(Q,L, Side),concat([[Row, Col, rabbit, Side]],L,Solutions),!.
listeLapins([_|Q], L, Side):-listeLapins(Q,L, Side),!.

%arg1: Lapin à déplacer
%arg2: board
%arg3: nb coups joués
%arg4: Moves solutions
%arg5: Side lapin gagnant

existCoupGagnant(_, _, 4, _, _):-fail,!. %échec dans le cas où le nombre de coups joués est déjà à 4 sans que le lapin considéré soit parvenu à atteindre une position gagnante.

existCoupGagnant([Row, Col,rabbit, Side], Board, NbCoupsJoues, [[[Row, Col],[7, NewCol]]],Side):-
	deplacementRabbit([Row,Col],[7,NewCol], Side), 
	isValid([Row,Col,rabbit,Side],[7,NewCol], Board, NbCoupsJoues),!. %cas où un lapin est capable d'atteindre une position gagnante en un seul déplacement

existCoupGagnant([Row, Col,rabbit, Side], Board, NbCoupsJoues, [[[Row, Col],[NewRow, NewCol]]|Q],Side):-
	deplacementRabbit([Row,Col],[NewRow,NewCol], Side), 
	isValid([Row,Col,rabbit,Side],[NewRow,NewCol], Board, NbCoupsJoues),
	deplacerPion([Row, Col, rabbit, Side], [NewRow, NewCol, rabbit, Side], Board, NewBoard), 
	NouveauCoupsJoues is NbCoupsJoues+1,
	existCoupGagnant([NewRow,NewCol, rabbit, Side],NewBoard, NouveauCoupsJoues, Q, Side). %le lapin peut potentiellement atteindre une position gagnante mais en plusieurs mouvements

choixOrdreTrie(gold,croissant).
choixOrdreTrie(silver,decroissant).

%Parcours les lapins silvers, NbCoupsJoues contient les coups qu'un lapin peut faire permettant de gagner la partie

moveandWin(Board, Moves, NbCoupsJoues, Side):-
	listeLapins(Board, ListeLapins, Side), %on récupère une liste de lapins propres au side envoyé
	choixOrdreTrie(Side,ChoixTri),
	trierBoard(ListeLapins,LstTrie,ChoixTri), %on trie la liste, suivant un ordre défini en fonction du side, pour avancer en priorité le lapin le plus proche de la ligne gagnante
	element(Lapin, LstTrie),
	existCoupGagnant(Lapin, Board, NbCoupsJoues, Moves, Side),!.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Fonction preventGoldVictory &&  freezeGold %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Fonction défensive: Bloquer un lappin gold pouvant gagner au prochain tour
%arg1: Board
%arg2: Moves
preventGoldVictory(Board, Moves,NewBoard):-
	moveandWin(Board,MovesGoldWin, 0, gold),
	MovesGoldWin\=[], %il existe un pion gold permettant de gagner au tour prochain
	freezeGold(Board,MovesGoldWin,Moves,NewBoard).

%fonction pour geler une pièce adverse (en l'occurence, ici utilisée pour geler un lapin gold qui peut gagner)
%arg1:Board
%arg2: liste des mouvements d'un pion gold qui peut gagner
%arg3: mouvement d'un pion silver qui peut l'empêcher de gagner
%arg4: NewBoard

freezeGold(Board,[[_|[CoordX,CoordY]]|_],[[SRow,SCol],[CoordX,CoordY]],NewBoard):-
	existNear([CoordX,CoordY],Board,silver,Solutions), %on regarde si des pions silver se situent à proximité de l'un des états du parcours du lapin gold
	element([SRow,SCol,SType,silver],Solutions),
	isValid([SRow,SCol,SType,silver],[CoordX,CoordY], Board, 0),
	not(goldAndStrongerNear([CoordX,CoordY,SType,silver],Board)), %Si on n'est pas à côté d'un pion adverse qui a une plus grande priorité que notre pion
	canMoveWithoutDead([SRow,SCol,SType,silver], [CoordX,CoordY], Board), %on vérifie si malgré que la nouvelle position soit éventuellement une trappe, le coup est possible
	retire_element([SRow,SCol,SType,_],Board,NewBoard),!.

freezeGold(Board,[_|Q],Moves,NewBoard):- 
	freezeGold(Board,Q,Moves,NewBoard). %cas où il n'est pas possible de le geler au premier état. 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% Algo principal  %%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Permet de connaitre le meilleur coup à jouer parmis (pousser, avancer un pion silver, avancer un autre pion)

chooseMoves(Board,Moves,OldNbCoups,NewNbCoups,NewBoard):-
	OldNbCoups=<2,
	pushAndMove(Board,Moves,OldNbCoups,NewNbCoups,NewBoard),!.

%on choisit d'avancer d'abord les lapins en priorité ceux qui sont le plus proche d'un état gagnant
chooseMoves(Board,Moves,OldNbCoups,NewNbCoups,NewBoard):-	
	choixOrdreTrie(silver,ChoixTri),
	listeLapins(Board,LstLapinsSilvers, silver),
	trierBoard(LstLapinsSilvers,LstTrie,ChoixTri),
	moveDownPawn(LstTrie,Board,Moves,OldNbCoups,NewNbCoups,NewBoard),!. %On vérifie qu'il existe des nouveaux coups

%on choisit ensuite d'avancer les autres prions : le premier qui vient 
chooseMoves(Board,Moves,OldNbCoups,NewNbCoups,NewBoard):-
	moveDownPawn(Board,Board,Moves,OldNbCoups,NewNbCoups,NewBoard).

	
%boucle principale qui retournera les mouvements sélectionnés

play([],[],_).
play(_,[],4):-!. %on s'arrête si on a atteint les 4 coups
play(Board,Moves,NbCoups):-verifyCounter(NbCoups), 
	chooseMoves(Board,NewStep,NbCoups,NewNbCoups,NewBoard), %choix du mouvement
	play(NewBoard,Step,NewNbCoups), %appels récursifs jusqu'à qu'il n'y ait plus de coups possibles ou que le nombre de coups soit déjà à 4, en considérant le nouveau board.
	concat([NewStep],Step,Moves). %on concatène les différents résultats obtenus.

