---
layout: post
comments: true
author: Manuel Capel
title: Solver for Des Chiffres Et Des Lettres 
date: 2025-04-17
categories: [C,programming]
---
[Des Chiffres et des Lettres](https://en.wikipedia.org/wiki/Des_chiffres_et_des_lettres) was a French TV game broadcasted from 1965 up until 2024, means almost 60 years long, a record. It consists in two games: *chiffres*, where you get a set of number and combine them to reach a target number as close as possible; and *lettres*, where you combine a set of letters to get the longest possible word. This article presents a solver for those games implemented in C.

## Game Rules
### Chiffres
In *chiffres* you get a set of positive integers, and you must combine them using basic arithmetic operations (addition, subtraction, multiplication and division) to approach as close as possible a target number, which is also a positive integer. For example you get `10`, `3` and `5` and your target is `36`. The best you can approach the target with those numbers is by reaching `35`, and there are two ways to do it:
- Solution 1:
    - 10 - 3 = 7
    - 7 * 5 = 35
- Solution 2:
    - 10 * 3 = 30
    - 30 + 5 = 35

You are allowed to use each initial number and each intermediary result only once, no re-use. All intermediary results must be a positive integer as well.

In the TV version, there were 6 initial numbers sampled without from {1..10, 25, 50, 75, 100} and the target was sampled in {101..999}.

### Lettres
For this game, 10 letters are sampled from the latin alphabet (26 letters). Each candidate chooses alternatively if he wants a vowel or a consonant to be picked are random, until there are 10 letters. With those 10 letters, you must form the longest possible valid french word. If a lwords contains accentuented letters like `à` or `é`, they are considered non-accentuated for the purpose of this game (e.g. you can form the word "âme" with the letters `à`, `m` and `e`).

## Implementation
### Chiffres
At the beginning we have a list of numbers, all marked as `unused`. The first two numbers are picked, and combined with an operation. If the result is invalid (negative or fractional), then pass. Otherwise mark those two numbers as `used`, the result is appended to the list of numbers, and from there we proceed recursively. The result is structured in a set of *solution*s containing *step*s. A step consists in three positive integers (the two operands and the result) and the operation (`+` or `-` or...). If a better solution is found, the set of solutions is re-initialized, so that the final result contains only solutions for the best possible result.

N.B.: 
- A solution is "better" than another if it approximates the target better, or if it approximates the target with the same precision, but has a less number of steps
- If some numbers are repeated in the input, some solutions maybe repeated, since each repeated number is considered distinct in this implementation

On top of this, there is also a mechanism to avoid *dead steps*, means steps which results are not used to compute the final result.

Let's try: 
```{sh}
./chiffres_lettres.o --chiffres --target 594 --values 8,5,75,100,9,3
[INFO] Solving chiffres with following parameters:
        - chiffres: 8, 5, 75, 100, 9, 3
        - target: 594
[INFO] All combinations computed for 6 chiffres in 0.26s.
SUCCESS
Best solution(s) found:
- 2995512 combinations computed (from which 1173663 or 39.18% are valid)
- Min. delta to target reached: 0.
- 4 solutions:
solution 1:
        1. 8 * 75 = 600
        2. 9 - 3 = 6
        3. 600 - 6 = 594
===
solution 2:
        1. 8 * 75 = 600
        2. 3 + 600 = 603
        3. 603 - 9 = 594
===
solution 3:
        1. 8 * 75 = 600
        2. 600 - 9 = 591
        3. 3 + 591 = 594
===
solution 4:
        1. 9 - 3 = 6
        2. 8 * 75 = 600
        3. 600 - 6 = 594
===
```

This output displays the numbers of combinations (steps) computed. A combination is invalid if it produces a negative or fractional number. Interestingly, the percentage of valid steps is pretty stable, around 38 +- 2% most of the time empirically. It's also pretty fast, as you can see. You can also notice that `solution 1` and `solution 4` are the same, just we steps in a different order. A possible improvement would be to remove such identical solutions, or better, not compute them in the first place (though I implemented already some mechanisms to reduce quite drastically the numbers of computed steps, that would be quite overwhelming otherwise in a naïve implementation).

In the current implementation, you can input max. 10 numbers containing max. 10 digits, and it computes max. 10 solutions.

### Lettres
All the permutations of the input letters are combined with a (non-recursive) [Heap's algorithm](https://en.wikipedia.org/wiki/Heap%27s_algorithm). For the list of French words, I used the one made by [Christophe Pallier](http://www.pallier.org/) in his [openlexicon](http://openlexicon.fr/) containing 336k+ French words. For each permutation, we use binary search to find the longest word in this list starting with the same letters (modulo accents). 

For example I was curious to find out which are the longest French words containing the first 10 letters of the alphabet:
```{sh}
./chiffres_lettres.o --lettres --values abcdefghij     
[INFO] Solving for lettres with following parameters:
        - lettres: A, B, C, D, E, F, G, H, I, J
[INFO] main(): number of lines in liste.de.mots.francais.frgut.txt: 336531
[INFO] main(): 336531 words loaded from dictionnaire file in 0.100s.
[INFO] main(): matches for 10 letters found in 0.673s.
matches:
        * fichage
        * déficha
```
Ok, both contain 7 letters.

## Conclusion
It's a pretty efficient implementation of a solver for *des chiffres et des lettres*, that could be extended to other languages. Feel free to try. The code is available on [this Github repo](https://github.com/mancap314/chiffres_lettres). If someone would like to use it as a backend for an app to play this game, it would be great :)
