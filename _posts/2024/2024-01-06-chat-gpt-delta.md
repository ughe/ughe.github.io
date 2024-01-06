---
title: "Evaluating ChatGPT on Delta Fare Codes"
---

# Background

Delta (the airline) has several Fare Classes (or Codes) to categorize its ticket prices. Delta also offers Companion Ticket Vouchers which can only be booked on tickets of certain Fare Classes. The goal of this post is to understand Delta's Fare Classes, using ChatGPT and Delta's website.

# ChatGPT on Delta Fare Codes

Here's the long and short according to ChatGPT (prompts not shown):

> A Delta fare class refers to the category or code assigned to a specific type of airline ticket based on various factors such as cabin class, flexibility, and restrictions. For example, Delta Air Lines uses fare classes like First Class (A), Business Class (C, D, I, J), Main Cabin (Y, B, M), Comfort+ (W, S), and Basic Economy (E). Each class may have its own set of rules...

| Fare Class     | Description          |
|----------------|----------------------|
| A              | First Class          |
| B              | Main Cabin           |
| C              | Business Class       |
| D              | Business Class       |
| E              | Basic Economy        |
| I              | Business Class       |
| J              | Business Class       |
| M              | Main Cabin           |
| S              | Comfort+             |
| W              | Comfort+             |
| Y              | Main Cabin           |

# Delta on Delta Fare Codes

According to Delta's ["Earning Miles with Exception Fares"](https://www.delta.com/us/en/skymiles/how-to-earn-miles/exception-fares) webpage, here's an adaption of their words:

> Delta One / First Class (J); Discounted Delta One / First Class (C, D, I, Z); Delta One / First Class / Delta Premium Select (F); Delta Premium Select (P, A, G); Full Fare Main Cabin / Delta Comfort+ (Y, B, M, W, S); Main Cabin (H, Q, K, L); Discounted Main Cabin (U, T); Deeply Discounted Main Cabin (X, V); Basic Economy (E)

And summarized in a table (with some editorialized description) of all 26 possible letters:

| Fare Class     | Name - Description               |
|----------------|----------------------------------|
| J              | Delta One - First Class          |
| C              | Delta One - Discounted Tier 1    |
| D              | Delta One - Discounted Tier 2    |
| I*             | Delta One - Discounted Tier 3    |
| Z*             | Delta One - Discounted Tier 4    |
| F              | Delta One or Delta Premium Select - Unknown   |
| P              | Delta Premium Select - Tier 1    |
| A              | Delta Premium Select - Tier 2    |
| G              | Delta Premium Select - Tier 3    |
| S*             | Comfort+ - Tier 1                |
| W*             | Comfort+ - Tier 2                |
| Y              | Main Cabin - Full Fare           |
| B              | Main Cabin - Flexible            |
| M              | Main Cabin - Standard            |
| H              | Main Cabin - Tier 1              |
| Q              | Main Cabin - Tier 2              |
| K              | Main Cabin - Tier 3              |
| L*             | Main Cabin - Tier 4              |
| U*             | Main Cabin Discounted - Tier 1   |
| T*             | Main Cabin Discounted - Tier 2   |
| X*             | Main Cabin Deeply Discounted - Tier 1|
| V*             | Main Cabin Deeply Discounted - Tier 2|
| E              | Basic Economy                    |
|||
| N              | Unused code - Similar to Basic Economy |
| O              | Unused code - Similar to Main Cabin    |
| R              | Unused code - Similar to Basic Economy |

\* Companion Ticket available. Caveats: for (S, W) to be booked: (L, U, T, X, or V) must be available to book.

Note: the ordering of "Tiers" in the table above may be incorrect. Generally it goes of off the order in the adaption of Delta's statement above. Additionally was adjusted to flip S and W for Comfort+.

## Companion Ticket Voucher Rules

The rules for Companion Ticket Vouchers are in the Terms & Conditions on the [companion certificates page](https://www.delta.com/us/en/booking-information/companion-certificates):

> Tickets are only available in I and Z classes of service for First Class travel, and only available in L, U, T, X, and V classes of service for Main Cabin travel. For Delta Comfort+ travel, tickets are available in W and S classes of service, but only when L, U, T, X, or V classes of service are available in the Main Cabin. Tickets may not be available on all flights or markets.

## Example Codes and Prices

According to ChatGPT, the busiest domestic flight route in the U.S. is LAX to ATL. Let's take a look at today's prices from Delta.com for flights from LAX to ATL for concrete examples of fare codes and prices:

| Date (2024)       | Flight Number | Time | Main Fare Code / Price | Comfort+ Fare Code / Price | First Fare Code / Price | Unbooked / Total Seats |
|------------|---------------|------|-------------------------|-----------------------------|--------------------------|---|
| Jan 7      | DL780 | 6:30am (4:17 min) | M / $659 | Sold Out | Sold Out | 4 / 191 (2.09%) |
| Jan 14     | DL430 | 6:00am (4:15 min) | M / $509 | Sold Out | C / $1,619 | 30 / 191 (15.71%) |
| Feb 4      | DL430 | 6:00am (4:15 min) | M / $359 | W / $609 | I* / $1,219 | 68 / 191 (37.57%) |
| Apr 28   | DL390 | 6:00am (4:19 min) | U* / $339 | W* / $589 | Z* / $1,139 | 150 / 191 (78.53%) |
| Aug 18  | DL390 | 6:00am (4:25 min) | U* / $339 | W* / $589 | I* / $1,269 | 160 / 191 (83.77%) |
| Dec 1 | DL390 | 6:00am (4:18 min) | L* / $489 | W* / $739 | I* / $1,369 | 160 / 191 (83.77%) |

\* eligible for Companion Ticket based on the above rules. No Basic Economy available on any flights above.

### Methodology / Parameters:
* Airline: Delta
* Route: LAX to ATL
* Direction: One Way
* Dates: First Sunday that leaves in:
    * 1 day (Jan 7)
    * 1 week (Jan 14)
    * 4 weeks (Feb 4)
    * 16 weeks (April 28)
    * 32 weeks (Aug 18)
    * 47 (max available from today) weeks (Dec 1)
* Today: Saturday Jan 6, 2024 at approximately 3pm ET
* Selection Criteria:
    * Nonstop
    * First Flight of the day as long as flight leaves on or after 4am

# Conclusion

The results were mixed. ChatGPT got 47% of the fee code letters (11 out of the 23 total letters used). Of the 11 letters, ChatGPT was able to categorize Main Cabin and Comfort+ correctly (5/11). The remaining 6/11 codes would have been correct if Delta One was Business Class and if Delta Premium Select was First Class. Version information: used ChatGPT 3.5 which said that it was last updated in January 2022 when asked. All in all, ChatGPT was useful for learning about what Delta's Fare Codes are as well as listing concrete examples.

## Further Reading

* Wikipedia: [https://en.wikipedia.org/wiki/Fare_basis_code](https://en.wikipedia.org/wiki/Fare_basis_code)
* Yale: [https://your.yale.edu/work-yale/campus-services/travel/air-travel/airfare-codes](https://your.yale.edu/work-yale/campus-services/travel/air-travel/airfare-codes)
* TPG: [https://thepointsguy.com/guide/airline-fare-classes/](https://thepointsguy.com/guide/airline-fare-classes/)
