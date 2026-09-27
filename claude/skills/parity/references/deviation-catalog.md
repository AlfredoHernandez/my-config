# Deviation catalog

A deviation is a divergence that is **correct**. Without this catalog an audit flags real platform
limits as debt and loses credibility on its first run. With it used too freely, real debt gets
laundered into "an accepted difference" and parity quietly dies. Both failures are expensive; this
file exists to make the call deliberate rather than convenient.

## The bar

A deviation needs all four, or it is not a deviation:

1. `platform` and the `criteria` it covers.
2. `reason` — the constraint, named specifically. Not "Android is different".
3. `constraint` — one of `os`, `store`, `hardware`, `legal`, `sdk`.
4. `evidence` — a link or a repo doc. A claim without a citation is reported as `unknown·contract`.

Three questions that decide it:

- Could the platform do this if someone wrote more code? → **gap**, not deviation.
- Is the *user-visible outcome* the same, reached differently? → neither. That is parity; fix the
  contract's criterion so it describes the outcome rather than the mechanism.
- Would the platform's own reviewers reject the parity-preserving version? → deviation.

Most claimed deviations are the second case. A criterion written about a mechanism manufactures
deviations; written about an outcome it usually dissolves them.

## Recurring genuine divergences

These are where to look first, and each still needs its own evidence in your project:

- **Background execution.** Guaranteed-interval work is not grantable on either platform, but the
  shapes differ enough that "refresh every N minutes" is a criterion that cannot be written
  portably. Write the outcome ("the user never sees data older than N without being told it is
  stale") and both platforms can satisfy it.
- **Widget and complication refresh.** Budgeted by the OS, differently, and not under the app's
  control on either side.
- **Device-usage and screen-time data.** Different APIs, different consent models, different
  granularity, and some data available to one platform only.
- **Subscription lifecycle.** Grace periods, billing retry, refunds, family sharing and the review
  flow differ per store. The *entitlement* must be at parity; the plumbing cannot be.
- **Notification permission and channels.** One platform groups by channel with per-channel user
  control; the other does not. Parity is "the user can silence this category", not the mechanism.
- **Consent and tracking prompts.** Ordering and wording are constrained by different regimes.
- **Assistant and system integrations.** App Intents, App Actions, AppFunctions, share sheets and
  quick settings do not map one to one. Parity is the capability, not the surface.
- **Navigation gestures and system back.** Semantics must be at parity; the gesture must be native.

## What is never a deviation

- One platform has no tests for a behaviour the other tests. That is debt, always.
- One platform has no CI for a step the other automates. That is debt.
- A string, an error message, or an empty state that exists on one side only.
- "Nobody has had time yet." That is a `gap`, which is an honest and perfectly acceptable thing for
  a contract to record.
- "The other platform's SDK does it for us." Then the criterion belongs behind a port, and the
  platform without the SDK owes an adapter.
