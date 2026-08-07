# 09. Show direct expenses and net profit on the sale page

Spec: ../spec.md
Status: done
Blocked by: 04

## What to build

The sale page reports cost of goods as a single number, so the ad-hoc expenses recorded against a purchase are invisible, and there is no profit figure for the order as a whole — only per line. Add a summary that separates merchandise cost from direct expenses and states net profit.

Sales that are part of a payment plan need care: a follow-up charge has no purchase links of its own, so computing it in isolation would report its full revenue as profit while the originating order shows a matching loss. For a sale belonging to exactly one plan, the summary covers the whole plan and says so.

## Acceptance criteria

- [x] The sale page shows revenue, merchandise cost, direct expenses, operating expenses, and net profit, and the four deducted terms reconcile exactly to the stated profit.
- [x] Direct expenses are no longer folded invisibly into cost of goods; the per-item cost-of-goods column keeps its current meaning.
- [x] A sale belonging to one payment plan reports the plan's economics and labels the figures as covering the whole plan.
- [x] A follow-up charge does not report its revenue as profit, and its originating order does not report the whole plan's cost against a deposit.
- [x] A sale with no recorded costs shows no profit claim.
- [x] A cancelled sale does not present its revenue and cost as realised.
- [x] The summary is separate from the payment card and follows its own visibility rule.
