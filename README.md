# Sah — Joc de sah cu interfata grafica (MATLAB)

Joc de sah scris in MATLAB, cu tabla desenata intr-o interfata grafica proprie
(drag & drop cu mouse-ul), reprezentare a pozitiei prin bitboard-uri si un
motor propriu de cautare a mutarilor (minimax cu alpha-beta pruning) pentru
modul Utilizator vs Robot.

## Screenshot-uri

![Tabla la pozitia initiala](docs/screenshots/tabla-initiala.png)
![O partida in desfasurare](docs/screenshots/partida.png)
![Sah / sah mat evidentiat](docs/screenshots/sah-mat.png)

## Functionalitati

- **Interfata grafica proprie**: tabla de 8x8 desenata cu componente MATLAB
  App (`uifigure`, `uiimage`), cu piesele randate din imagini PNG.
- **Mutare prin drag & drop**: piesele se prind, se trag si se elibereaza cu
  mouse-ul (`startDrag` / `dragging` / `stopDrag`), nu prin introducerea
  manuala a coordonatelor.
- **Doua moduri de joc**: Utilizator vs Utilizator (doi jucatori la aceeasi
  tabla) si Utilizator vs Robot (impotriva calculatorului).
- **Motor propriu de cautare**: algoritm minimax cu alpha-beta pruning,
  adancime de cautare configurabila, folosit de `Robot` pentru a alege
  mutarea optima.
- **Generare corecta a mutarilor** pentru fiecare tip de piesa (pion, cal,
  nebun, tura, regina, rege), cu filtrarea mutarilor care si-ar lasa
  propriul rege in sah.
- **Detectare sah, sah mat si pat**, cu evidentierea vizuala a patratelului
  regelui aflat in sah si afisarea rezultatului partidei pe interfata.
- **Evidentiere a ultimei mutari** efectuate direct pe tabla.
- **Incarcare pozitie din FEN** (Forsyth-Edwards Notation) — pozitia de start
  standard este incarcata implicit la deschiderea jocului si la resetare.

## Stack tehnic

- MATLAB, programare orientata pe obiecte (`classdef`, clase `handle`)
- Reprezentarea pozitiei ca **bitboard**: cate un `uint64` pentru fiecare
  combinatie tip de piesa + culoare (12 bitboard-uri), plus bitboard-uri
  auxiliare pentru piesele albe, piesele negre si toate patratele ocupate;
  operatii pe biti (`bitand`, `bitor`, `bitxor`, `bitshift`, `bitget`,
  `bitset`) pentru interogarea si actualizarea rapida a tablei
- Interfata grafica: `uifigure`, `uiimage`, evenimente
  `WindowButtonDownFcn` / `WindowButtonMotionFcn` / `WindowButtonUpFcn`
  pentru drag & drop
- Parsare **FEN** pentru initializarea si resetarea pozitiei (piese, cine
  muta, drepturi de roca)
- Cautare: **minimax + alpha-beta pruning** (`Engine.m`), cu evaluare a
  pozitiei bazata pe valoarea materialului (pion, cal, nebun, tura, regina,
  rege)
- Clase proprii pentru fiecare concept al jocului: `Bitboard` (pozitia
  bruta), `Mutari` (generarea si validarea mutarilor), `Engine` (cautarea
  mutarii optime), `Jucator` (clasa abstracta) cu implementarile
  `Utilizator` si `Robot`, `Joc` (leaga logica de jucatori), `Piesa` (piesa
  desenata pe interfata), `Sah` (fereastra principala si interactiunea cu
  mouse-ul)
- Imagini PNG pentru piese, in folderul `img/`

## Rulare locala

1. Deschide MATLAB (recomandat R2020a sau mai nou, pentru suportul complet
   de `uifigure`/`uiimage` si validarea de tip pe proprietati folosita in
   clase, ex. `mutari Mutari`).
2. Seteaza folderul `Sah/` (cel care contine fisierele `.m` si subfolderul
   `img/`) ca **Current Folder** in MATLAB, sau adauga-l la path — altfel
   clasele si imaginile pieselor nu vor fi gasite (caile catre imagini sunt
   relative, ex. `img/pion1.png`).
3. In Command Window, porneste jocul:
   ```matlab
   joc = Sah();
   ```
4. Implicit se porneste modul **Utilizator vs Utilizator**. Pentru a juca
   impotriva calculatorului, apeleaza:
   ```matlab
   joc.UtilizatorVsRobot(3); % 3 = adancimea de cautare a motorului
   ```
   O adancime mai mare inseamna un adversar mai puternic, dar si un timp de
   gandire mai lung (cautarea explora exhaustiv arborele de mutari pana la
   adancimea data).

## Decizii tehnice de retinut

- **Bitboard in loc de matrice de celule**: operatiile pe biti sunt mult mai
  rapide decat interogarea unei matrice `cell(8,8)` piesa cu piesa, lucru
  important mai ales pentru motorul de cautare, care exploreaza sute/mii de
  pozitii intermediare la fiecare mutare calculata.
- **Mutarea e reprezentata compact ca un vector `[pozitieInitiala,
  pozitieFinala, tipPiesaMutata, tipPiesaCapturata]`**. Acelasi format e
  folosit atat de `actualizareTabla` (aplica mutarea), cat si de
  `anulareMutare` (o anuleaza exact), ceea ce permite motorului sa faca si
  sa desfaca mutari pe acelasi obiect `Bitboard`/`Mutari`, fara sa cloneze
  tabla la fiecare nod din arborele minimax.
- **Legalitatea unei mutari se verifica prin simulare**: fiecare mutare
  candidata e aplicata temporar pe tabla, se verifica daca propriul rege
  ramane in sah, apoi mutarea e anulata (`Mutari.valid`) — mai simplu de
  implementat corect decat un calcul static al liniilor de atac spre rege,
  desi ceva mai costisitor.
- **Evaluarea pozitiei e strict materiala** (suma valorilor pieselor ramase
  pe tabla), fara factori pozitionali (control de centru, siguranta
  regelui, structura de pioni). Suficienta pentru o adancime mica de
  cautare, dar limiteaza taria motorului la adancimi mai mari.
- **Roca, en passant si promovarea pionului nu sunt implementate**: bitboard-ul
  retine deja drepturile de roca citite din FEN (`flags`), dar generarea de
  mutari nu le foloseste inca pentru a produce mutari de roca sau de
  capturare en passant, iar un pion ajuns pe ultima linie nu e promovat
  automat la alta piesa — ar necesita extinderea formatului mutarii si a
  functiilor de generare/actualizare a tablei.

## Structura proiectului

```
Sah/
  Sah/
    Sah.m                 -> fereastra principala, desenarea tablei, drag & drop cu mouse-ul
    Joc.m                 -> leaga logica jocului (Mutari) de cei doi jucatori
    Bitboard.m             -> reprezentarea pozitiei (bitboard-uri uint64), FEN, evaluare
    Mutari.m               -> generarea si validarea mutarilor pentru fiecare tip de piesa
    Engine.m               -> motorul de cautare (minimax + alpha-beta pruning)
    Jucator.m              -> clasa abstracta pentru un jucator
    Utilizator.m            -> jucator uman (mutari primite din interfata)
    Robot.m                 -> jucator calculator (foloseste Engine pentru a alege mutarea)
    Piesa.m                 -> o piesa desenata pe interfata (imagine + pozitie)
    img/                     -> imagini PNG pentru piese (pion, cal, nebun, tura, regina, rege), alb/negru
```
