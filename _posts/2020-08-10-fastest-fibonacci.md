---
layout: post
comments: true
author: Manuel Capel
title: The Fastest Way to Compute the Fibonacci Sequence
date: 2020-08-10
categories: [miscellanous]
---
What is the [Fibonacci sequence](https://en.wikipedia.org/wiki/Fibonacci_number)? It’s easy to define: the first element is 1, the second is 2, and the following elements are the sum of the two previous ones: the 3rd element is 3 (2 +1), the 4th is 5 (3+2), the 5th is 8 (5+3) etc.

Tonight on the Python [Discord](https://discord.com/) channel, a user came up with a challenge: find a faster Python implementation to compute the elements of the Fibonacci sequence than this one:

```python
def fib(n):
    if not isinstance(n, int):
        raise TypeError
    if n < 0:
        raise ValueError
    if n <= 1:
        return 1
    a, b = 1, 2
    for _ in range(n-2):
        a, b = b, a + b
    return b
```

Challenge accepted. I already knew there is a closed form (direct formula) to compute the Fibonacci values, so I thought it would be enough to apply it directly to beat this implementation… but it was not that easy

## Binet Formula

There is a closed form called [Binet formula](http://mathonline.wikidot.com/a-closed-form-of-the-fibonacci-sequence) for computing the n-th Fibonacci value. Translated in Python (with numpy), it gives:

```python
import numpy as np

def fibonacci(n):
    return np.floor(1 / np.sqrt(5) * (((1 + np.sqrt(5)) / 2) ** n - ((1 - np.sqrt(5)) / 2) ** n))
```

Perfect. Note also the [golden ratio](https://en.wikipedia.org/wiki/Golden_ratio) in the formula. What is the problem with this? Let’s try it out:

```python
fibonacci(1500)
/home/manuel/.local/lib/python3.6/site-packages/ipykernel_launcher.py:2: RuntimeWarning: overflow encountered in double_scalars
inf
```

So when trying to compute the 1500th Fibonacci value, we get an overflow and an infinite result… This Binet formula doesn’t seem to work in practice. But… we can modify it on order to make it computable.

## Trick 1: Splitting the Powers

We can expand and simplify this term: `(1 + np.sqrt(5)) / 2) ** n - ((1 - np.sqrt(5)) / 2) ** n)` by using the binomial theorem:

![binomial-expansion](assets/fibonacci-binomial-expansion.png "Binomial Expansion")

The terms in the sum are smaller, but still not small enough. For `n > 1000` we still get infinity result, so we need another trick:

## Trick 2: Log Down

The terms in the sum just consist in multiplication and power operation, so it calls for using logarithm. Bear in mind the basic logarithm property: `log(a.b) = log(a) + log(b)` and that the bigger `n`, the smallest `log(n)` compared to n. So we get:

![first-log-expansion](assets/fibonacci-1st-log-expansion.png "First Log Expansion")

where `ln` here stands for the [natural logarithm](https://en.wikipedia.org/wiki/Natural_logarithm). That's already a big improvement, but we still have a problem: The binomial factor gets too high before we take its log. The solution is thus to inject the log directly into it:

![second-log-expansion](assets/fibonacci-2nd-log-expansion.png "Second Log Expansion")

Note that the last two sums are the same made in reversed order.

So we just have to implement this:


```python
import numpy as np


def log_binom(n, ks):
    r = np.arange(n) + 1
    r = np.log(r)
    s = np.sum(r)
    r = np.cumsum(r)
    z = np.zeros(r.shape[0] + 1)
    z[1:] = r
    z1 = z[::-1]
    z = np.add(z, z1)
    z = np.subtract(s, z)
    return z[ks]def fibonacci(n):
    n += 1
    ks = np.arange(np.ceil(n / 2)).astype(np.uint32)
    coeffs = log_binom(n,  2 * ks + 1).astype(np.float64)
    terms = np.multiply(np.log(np.sqrt(5)), 2*ks+1)
    res = np.add(coeffs, terms)
    res = np.subtract(res, np.log(2)*(n-1) + np.log(np.sqrt(5)))
    m = np.max(res)
    res = np.subtract(res, m)
    res = np.exp(res)
    res = np.sum(res)
    return res, m
```

If you are attentive you can see three additional tricks used here:
* `res = np.subtract(res, np.log(2)*(n-1) + np.log(np.sqrt(5)))`: is the logarithmic equivalent of dividing by `sqrt(5)` and by `2^(n-1)` in the Binet Formula
* The elements in the array are divided by `m`, the max element of the array, in order to avoid hitting infinity in the following sum
* `fibonacci()` returns `res` and `m`. The result is in fact `res.exp(m)` but encoding it like that with two numbers avoids hitting the format width limit for integers.

## Results

The challenge was to beat the performance of the `fib()` function above. Let's see what we get for large `n` (you have to scroll a bit down the result, sorry):

```python
import timeit, functools

n = 10000

t_fib = timeit.Timer(functools.partial(fib, n)) 
print(f'performance fib(): {t_fib.timeit(10)}')
print(f'fib({n})={fib(n)}')

print()

t_fibonacci = timeit.Timer(functools.partial(fibonacci, n)) 
print(f'performance fibonacci(): {t_fibonacci.timeit(10)}')
print(f'fibonacci({n})={fibonacci(n)}')performance fib(): 0.019920013000955805
fib(10000)=54438373113565281338734260993750380135389184554695967026247715841208582865622349017083051547938960541173822675978026317384359584751116241439174702642959169925586334117906063048089793531476108466259072759367899150677960088306597966641965824937721800381441158841042480997984696487375337180028163763317781927941101369262750979509800713596718023814710669912644214775254478587674568963808002962265133111359929762726679441400101575800043510777465935805362502461707918059226414679005690752321895868142367849593880756423483754386342639635970733756260098962462668746112041739819404875062443709868654315626847186195620146126642232711815040367018825205314845875817193533529827837800351902529239517836689467661917953884712441028463935449484614450778762529520961887597272889220768537396475869543159172434537193611263743926337313005896167248051737986306368115003088396749587102619524631352447499505204198305187168321623283859794627245919771454628218399695789223798912199431775469705216131081096559950638297261253848242007897109054754028438149611930465061866170122983288964352733750792786069444761853525144421077928045979904561298129423809156055033032338919609162236698759922782923191896688017718575555520994653320128446502371153715141749290913104897203455577507196645425232862022019506091483585223882711016708433051169942115775151255510251655931888164048344129557038825477521111577395780115868397072602565614824956460538700280331311861485399805397031555727529693399586079850381581446276433858828529535803424850845426446471681531001533180479567436396815653326152509571127480411928196022148849148284389124178520174507305538928717857923509417743383331506898239354421988805429332440371194867215543576548565499134519271098919802665184564927827827212957649240235507595558205647569365394873317659000206373126570643509709482649710038733517477713403319028105575667931789470024118803094604034362953471997461392274791549730356412633074230824051999996101549784667340458326852960388301120765629245998136251652347093963049734046445106365304163630823669242257761468288461791843224793434406079917883360676846711185597501performance fibonacci(): 0.005696072999853641
fibonacci(10000)=(57.919468677010926, 4807.735689890051)
```

For `n=10000` our implementation is about 3.5x faster than the original implementation, challenge completed! (and this gap increases with `n`). Also, notice that the 10000th term of the Fibonacci sequence is pretty huge.

To the best of our knowledge, this way of using the Binet formula (with the tricks) has never been used so far. [This paper](https://arxiv.org/pdf/1803.07199.pdf) for example mentions the Binet closed form, but in its direct expression which, as we saw, throws an overflow or returns infinity value for large n.

Note also that our algorithm is completely parallelizable.

It would be also interesting to compare the performance of this algorithm with the [fast doubling](https://www.nayuki.io/page/fast-fibonacci-algorithms), considered as the fastest algorithm for computing Fibonacci values, in its provided [Python implementation](https://www.nayuki.io/res/fast-fibonacci-algorithms/fastfibonacci.py):

```python
def fibonacci_fd(n):
    if n < 0:
        raise ValueError("Negative arguments not implemented")
    return _fib_fd(n)[0]


# (Private) Returns the tuple (F(n), F(n+1)).
def _fib_fd(n):
    if n == 0:
        return (0, 1)
    else:
        a, b = _fib_fd(n // 2)
        c = a * (b * 2 - a)
        d = a * a + b * b
        if n % 2 == 0:
            return (c, d)
        else:
            return (d, c + d)def compare(n):
    t_fibonacci = timeit.Timer(functools.partial(fibonacci, n)) 
    print(f'performance fibonacci(): {t_fibonacci.timeit(10)}')

    print()

    t_fibonacci_fd = timeit.Timer(functools.partial(fibonacci_fd, n)) 
    print(f'performance fibonacci_fd() (fast doubling): {t_fibonacci_fd.timeit(10)}')

```

First try with small `n=1000`:

```sh
compare(1000)
performance fibonacci(): 0.004257305001374334
performance fibonacci_fd() (fast doubling): 0.00013275300443638116
```

In this case, the *fast doubling* algorithm is about 30x faster than our algorithm.

Let’s take now a bigger `n = 100000`:

```sh
compare(100000)
performance fibonacci(): 0.06739291800477076
performance fibonacci_fd() (fast doubling): 0.019004731002496555
```

Now *fast doubling* is only 3.5x faster.

And with an even bigger `n=2000000`:

```sh
compare(2000000)
performance fibonacci(): 1.1456952699954854
performance fibonacci_fd() (fast doubling): 1.68371414799185
```

This time, our algorithm is about 30% faster than *fast doubling* which was considered so far the fastest Fibonacci algorithm.
