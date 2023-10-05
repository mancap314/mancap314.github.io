---
layout: post
comments: true
author: Manuel Capel
title: Overview of Smart Order Routing for Efficient and Compliant Trading
date: 2023-02-07
categories: [finance]
---
Smart Order Routing (SOR) consists in processing orders 
on trading venues the most optimal way. On the surface, it's pretty simple: as a
broker-dealer you get from a customer a request to buy a certain amount of a
company's stock, you take a quick look at the different exchanges, maybe you
will split this order if its volume is high, and that's it. Well, not quite...

## State of affairs
The two main factors complexifying SOR are

1. **Fragmentation of trading venues**: this fragmentation is more or less
   pronounced depending on the asset class (equities, derivatives, forex), with
   some mainly traded on exchanges and some almost exclusively OTC. Even for a
   pretty vanilla asset class like equities, there are several types of venues
   for executing an order:  exchanges (like the NYSE), dark pools (pools of
   orders keeping them quite obfuscated for preventing large orders from
   skewing the market, often managed by major banks) etc. For each of them,
   there are a number of parameters to consider, like: price, liquidity (how
   abundant the order book for this asset on this venue in order to absorb
   absorb smoothly the order at hand), execution time, order rejection rate
   etc. Getting live data about the state of the available venues, navigating
   this information in order to design the best executions can be a daunting
   tasks

2. **High Frequency trading**: since its inception in the mid-2000 by pioneers
   like Dan Matthison, HFT captured a large part of the trading volume.
   According to the Reasearch Service of the US Congress, the algorithms
   behind, often highly sophisticated and efficient, capture now over 40% of
   stock trades in Europe. Lack of SOR awareness will make your orders get
   "eaten alive" by those bots, leading to compounding substantial losses.

## Market drivers
The two main market drivers for the adoption of SOR solutions are regulation
and ROI
### Regulation
The regulations regarding SOR are mainly focused on ensuring best execution for
the customers of execution venues. The main are:

- **Reg NMS** (US): published in 2005 by the SEC for the US market, is focusing
  on guaranteeing best prices for the orders, detrimental to other important
  factors like execution time etc., thus criticized, and could be revised in
  the near future

- **MIFI ii** (EU): published by the ESMA, aims at guaranteeing best effort
  when executing orders.

With regulations come reporting duties, like mandatory BestEx (best execution)
reports, Top 5 Venues Execution report etc.

## ROI
SOR can generate a significant return on investment for trading venues and
their customers, in particular through:
- lower execution costs
- lower operational expenses (in IT infrastructures, operations,
  maintenance...)
- competitive advantage for brokers, getting visible market differenciation

## Technical challenges
- **IT infrastructure**: Seriously doing SOR implies to ingest and react to a
  constant tsunami of live data, requiring advanced, performant and reliable IT
  infrastructure deploying SmartNIC, implementing kernel by-passes, with
  parallelized GPU computation etc. Reducing the latency is key.
- **Monitoring the execution quality** through TCA (Total Cost analysis) is of
  paramount importance too, for business as well as for regulatory reasons. A
  TCA monitoring should comprise factors like:
- execution price, related to slippage prevention
    - execution latency (time for an order to get registered on the trading
      venue)
    - execution speed (by the trading venue)
    - fill ratio
    - spread (to the mid-point between bid and ask at execution)

Some of these metrics are not in the control of the brokers, who should those
monitor them in order to dynamically adapt their order execution strategy when
needed.

- Execution algorithm that should be:
    - explainable, so that its decisions can get reviewed by the broker and
       audited by the regulator
    - fast, for reducing latency and vulnerability of the orders. Will
      probably require a low-level implementation in C/C++/Rust, or CUDA
      if aimed for GPUs.
    - adaptable, self-learning, for adapting to changing conditions
      (price, liquidity, latency...) on the trading venues at hand

## How to choose a SOR solution
Considering the asset classes you are trading, the most important points to
consider when reviewing a SOR solution are:
- number and diversity of trading venues provided
- the quality of performance analysis for those venues
- user-friendliness of its UI
- metrics used to evaluation the transactions
- performance of the core technology / algorithms
- number and quality of the execution strategies provided
- if cloud-based: quality of the infrastructure, measured through latency,
  throughput, uptime guaranteed through a solid SLA

## Steps to Implement
It could be a good idea to divide and conquer the SOR challenge through
smaller, manageable and measurable steps, like:
1. TCA evaluation: which metrics are mandatory? Which ones would make sense
   from an operational viewpoint? From a strategic viewpoint?
2. Remaining regulatory tasks, typically report generation
3. Implementing / improving collection, ingestion and processing of live
      data related to the venues for the asset classes traded
4. Implementing / improving execution algorithm
5. Enhance IT-Infrastructure

## Conclusion
For banks, funds, broker-dealers and every trading venue in general, SOR is of
operational and strategic relevance, deeply impacting business and compliance.
State of the art is evolving fast following always more fragmenting markets and
efficient actors.
