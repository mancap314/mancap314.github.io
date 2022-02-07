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
    return np.floor(1 / np.sqrt(5) \
        * (((1 + np.sqrt(5)) / 2) ** n \
        - ((1 - np.sqrt(5)) / 2) ** n))
```

Perfect. Note also the [golden ratio](https://en.wikipedia.org/wiki/Golden_ratio) in the formula. What is the problem with this? Let’s try it out:

```sh
fibonacci(1500)
ipykernel_launcher.py:2: 
    RuntimeWarning: 
        overflow encountered in double_scalars
inf
```

So when trying to compute the 1500th Fibonacci value, we get an overflow and an infinite result… This Binet formula doesn’t seem to work in practice. But… we can modify it on order to make it computable.

## Trick 1: Splitting the Powers

We can expand and simplify this term: `(1 + np.sqrt(5)) / 2) ** n - ((1 - np.sqrt(5)) / 2) ** n)` by using the binomial theorem:

$$
\begin{align}
\frac{1 + \sqrt{5}^n}{2} - \frac{1 - \sqrt{5}^n}{2} 
&= \frac{1}{2^n}\sum_{k=0}^n\binom{n}{k}\sqrt{5}^k - \frac{1}{2^n}\sum_{k=0}^n\binom{n}{k}(-1)^k\sqrt{5}^k \\
&= \frac{1}{2^n}\sum_{k=0}^n\binom{n}{k}(1 - (-1)^k)\sqrt{5}^k \\
&= \frac{1}{2^n}\sum_{k=0, odd}^n\binom{n}{k}2\sqrt{5}^k \\
&= \frac{1}{2^{n-1}}\sum_{k=0, odd}^n\binom{n}{k}\sqrt{5}^k \\
\end{align}
$$

The terms in the sum are smaller, but still not small enough. For $$n > 1000$$ we still get infinity result, so we need another trick:

## Trick 2: Log Down

The terms in the sum just consist in multiplication and power operation, so it calls for using logarithm. Bear in mind the basic logarithm property: $$log(a.b) = log(a) + log(b)$$ and that the bigger $$n$$, the smallest $$log(n)$$ compared to n. So we get:

$$
ln\big(\binom{n}{k}\sqrt{5}^k\big) = ln\binom{n}{k} + k.ln\sqrt{5}
$$

where `ln` here stands for the [natural logarithm](https://en.wikipedia.org/wiki/Natural_logarithm). That's already a big improvement, but we still have a problem: The binomial factor gets too high before we take its log. The solution is thus to inject the log directly into it:

$$
\begin{align}
ln\binom{n}{k} &= ln\big(\frac{n!}{k!(n-k)!}\big) \\
&= ln\big(\prod_{i=1}^{n}i\big) - ln\big(\prod_{j=1}^{k}j\big) - ln\big(\prod_{l=1}^{n-k}l\big) \\
&= \sum_{i=1}^{n}ln(i) - \sum_{j=1}^{k}ln(j) - \sum_{l=1}^{n-k}ln(l)
\end{align}
$$

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
    res = np.subtract(res, np.log(2)*(n-1) \
            + np.log(np.sqrt(5)))
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
print(f'fibonacci({n})={fibonacci(n)}')
```

which gives:
```sh
performance fib(): 0.019920013000955805
fib(10000)=54438373113565281338734260993750380135389184554
6959670262477158412085828656223490170830515479389605411738
2267597802631738435958475111624143917470264295916992558633
4117906063048089793531476108466259072759367899150677960088
3065979666419658249377218003814411588410424809979846964873
7533718002816376331778192794110136926275097950980071359671
8023814710669912644214775254478587674568963808002962265133
1113599297627266794414001015758000435107774659358053625024
6170791805922641467900569075232189586814236784959388075642
3483754386342639635970733756260098962462668746112041739819
4048750624437098686543156268471861956201461266422327118150
4036701882520531484587581719353352982783780035190252923951
7836689467661917953884712441028463935449484614450778762529
5209618875972728892207685373964758695431591724345371936112
6374392633731300589616724805173798630636811500308839674958
7102619524631352447499505204198305187168321623283859794627
2459197714546282183996957892237989121994317754697052161310
8109655995063829726125384824200789710905475402843814961193
0465061866170122983288964352733750792786069444761853525144
4210779280459799045612981294238091560550330323389196091622
3669875992278292319189668801771857555552099465332012844650
2371153715141749290913104897203455577507196645425232862022
0195060914835852238827110167084330511699421157751512555102
5165593188816404834412955703882547752111157739578011586839
7072602565614824956460538700280331311861485399805397031555
7275296933995860798503815814462764338588285295358034248508
4542644647168153100153318047956743639681565332615250957112
7480411928196022148849148284389124178520174507305538928717
8579235094177433833315068982393544219888054293324403711948
6721554357654856549913451927109891980266518456492782782721
2957649240235507595558205647569365394873317659000206373126
5706435097094826497100387335174777134033190281055756679317
8947002411880309460403436295347199746139227479154973035641
2633074230824051999996101549784667340458326852960388301120
7656292459981362516523470939630497340464451063653041636308
2366924225776146828846179184322479343440607991788336067684
6711185597501

performance fibonacci(): 0.005696072999853641
fibonacci(10000)=(57.919468677010926, 4807.735689890051)
```

For `n=10000` our implementation is about 3.5x faster than the original implementation, challenge completed! (and this gap increases with `n`). Also, notice that the 10000th term of the Fibonacci sequence is pretty huge.

To the best of our knowledge, this way of using the Binet formula (with the tricks) has never been used so far. [This paper](https://arxiv.org/pdf/1803.07199.pdf) for example mentions the Binet closed form, but in its direct expression which, as we saw, throws an overflow or returns infinity value for large n.

Note also that our algorithm is completely parallelizable.

It would be also interesting to compare the performance of this algorithm with the [fast doubling](https://www.nayuki.io/page/fast-fibonacci-algorithms), considered as the fastest algorithm for computing Fibonacci values, in its provided [Python implementation](https://www.nayuki.io/res/fast-fibonacci-algorithms/fastfibonacci.py):

```python
def fibonacci_fd(n):
    if n < 0:
        raise ValueError(
            "Negative arguments not implemented"
        )
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
    t_fibonacci = timeit.Timer(
                    functools.partial(fibonacci, n)
                )
    perf_fibonacci = t_fibonacci.timeit(10)
    print(f'performance fibonacci(): {perf_fibonacci}')

    print()

    perf_fibonacci_fd = timeit.Timer(
                        functools.partial(fibonacci_fd, n)
                    )

    print(f'performance fibonacci_fd() (fast doubling): \
        {perf_fibonacci}')

```

First try with small `n=1000`:

```sh
compare(1000)
performance fibonacci(): 0.004257305001374334
performance fibonacci_fd() (fast doubling): 0.0001327530044
3638116
```

In this case, the *fast doubling* algorithm is about 30x faster than our algorithm.

Let’s take now a bigger `n = 100000`:

```sh
compare(100000)
performance fibonacci(): 0.06739291800477076
performance fibonacci_fd() (fast doubling): 0.0190047310024
96555
```

Now *fast doubling* is only 3.5x faster.

And with an even bigger `n=2000000`:

```sh
compare(2000000)
performance fibonacci(): 1.1456952699954854
performance fibonacci_fd() (fast doubling): 1.68371414799185
```

This time, our algorithm is about 30% faster than *fast doubling* which was considered so far the fastest Fibonacci algorithm.
