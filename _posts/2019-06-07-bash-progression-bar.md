---
layout: post
comments: true
author: Manuel Capel
title: Create a Progression Bar in Bash
date: 2019-06-07
categories: [programming]
---
We will show here how to create a bash script implementing a progression bar. Imagine you have a script creating automatically a bulk of images, this script takes time and while it is running you would like to know how far it is, how fast, and how long it still needs (easily adaptable for other cases like downloading script etc.). In brief, how to get something like that:

![Progression Bar](assets/progression-bar.png)

Let's go step by step:

## Arguments
In this particular case, the script takes several arguments:
* `--interval`: the progression will be checked every `interval` seconds
* `--n-images`: the total number of images to be created. In case of a download, it would be the total number of bytes to be downloaded, just adapt it to your case
* `--output-dir` and `--prefix`: in which directory the images are created and how is their name prefixed, to be able to look up how many have been created so far at every moment

## Initializing the progression loop
We initialize a `while` loop checking the progress at regular intervals until the the process monitored (here the images creation) is completed.
```bash
progress=0
n_images_previous=0
start_time=$( date +%s.%N )
while (( $(echo "${progress} < 100" | bc -l) )); do
```
Several variables are initialized:
* `progress`: which percentage of the process has been achieved (at the beginning: 0)
* `n_images_previous`: How many images vave been created at the end of the previous iteration of the `while` loop
* `start_time` (and later `end_time`): related to the current iteration of the `while` loop. In fact, at the end of each loop the script is interrupted for `interval`seconds + a loop takes a certain time to run. With those start and end timestamps we can take both into account and get a precise estimate of the progression speed

In the condition of the `while` loop, we pipe a mathematical expression into `bc | l`. That is (IMHO) a good way to evaluate arithmetical expression in *bash*.

## Estimating the progress speed
Physically: $$speed = distance / time$$. In the same vein here, the $$distance$$ is the difference between the number of images created so far - the number of images that were created at the end of the previous loop. $$time$$ is the `runtime` of the previous loop. Thus we get:
```bash
runtime=$( echo "${end_time} - ${start_time}" | bc -l )
speed=$(printf '%.1f\n' \
    $(echo "(${n_images_created} - ${n_images_previous}) \
    / ${runtime}" | bc -l))
# Re-initialize `n_images_previous` for the next loop:
n_images_previous=${n_images_created}
```
using `bc -l` as previously. [`printf '%.1f\n'` on l.2 allows us to control the precision of the result, here 1 decimal]

## Estimating and displaying the Estimated Time Left (ETL)
How long have we roughly to wait until the monitored process is finished? We compute it as the distance left (here: number of images to be still created) divided by the current speed:

```bash
etl=$(printf '%.0f\n' \
    $(echo "${n_images_tocreate} / ${speed}" \
    | bc -l))
```
That's the ETL in seconds. But we would like to have it in a more human-readable format, like 1h 23min 4s instead of 4984s. So we start with the hours:
```bash
n_hours=$(printf '%.0f\n' $(echo "${etl} / 3600" | bc -l))
if (( $(echo "${n_hours} >= 1" | bc -l) )); then
  etl_toprint="${n_hours}h "
fi
```
On l.1 we compute the ETL in hours rounded to the previous integer. If the result is greater or equal 1, we append it with the suffix `h` to the string to print. Thus we avoid displaying `0h ...`.

Similarly for the minutes:
```bash
n_min=$(printf '%.0f\n' \
    $(echo "scale=0; (${etl} % 3600) / 60" | bc -l))
if [[ ${n_min} -ge 1 || ${n_hours} -ge 1 ]]; then
  etl_toprint="${etl_toprint}${n_min}min "
fi
```
Remarks:
* On l.1, `scale=0` is necessary for `bc -l` to perform the modulo operation correctly.
* On l.2, the condition means that `1h 0min 4s` for example would be displayed, but not `0min 15s`

## Final note
Run the process bar in the background by appending `&` at the end of the command just before running the process to monitor:
```bash
./progress-bar.sh -n 3000 &
./myscript-to-monitor.sh
```
The complete code is available in [this snippet](https://gist.github.com/mancap314/c1768a71b240009c33533faac64c1550).

Thank you for reading!
