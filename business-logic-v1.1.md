# Business Logic v1.1 — MVP Specification

This specification defines the Moth Gold MVP and guides the database design.

## Project Details

- **Team** — SaBai
- **Project code name** — Moth Gold
- **Project short code** — `MG`
- **Short description** — A community marketplace for finding, offering, and requesting local goods and services.
- **Long description** — Members in one pilot community can find what is available nearby, post what they need, and arrange pickup or service delivery through private messages. Reviews come from members who both confirm they completed an exchange.

## User Levels

| Level | Responsibility |
| --- | --- |
| A. System Administrator | Assigns staff roles and owns backups and recovery. |
| B. Administrator | Manages listing categories, the expiry duration, and community rules. |
| C. Moderator | Reviews reports, removes violating content, and suspends or reinstates accounts. |
| D. Contributor | Uses one member account to buy, sell, offer services, or post a request. |
| E. Guest | Browses active offers, reads public policies, and can start Google Sign-In. |

The API checks the assigned role, ownership, and participation for each restricted action. Staff permissions are scoped to the assigned role. Marketplace activity requires contributor access.

## System Requirements

1. **Sign in and discover.** Guests can browse active offers, search by keyword, and filter by category. Show the pilot area and a display name alongside offers. Contributors sign in with Google, meet the pilot’s eligibility rule, and accept the community rules and terms before posting or messaging. Requests and member reviews are visible to contributors.
2. **Publish and maintain offers.** A contributor can publish a good or service with a title, description, category, price or “request a quote,” and an optional photo. Owners can edit or close their offers and renew an expired offer after confirming availability. Apply the current expiry duration at publication or renewal. Closed, expired, and removed offers disappear from discovery, and only active offers accept new conversations. A deactivated category remains visible on existing offers and requests until they close or expire. New posts and renewals use an active category.
3. **Request goods or services.** A contributor can post a request with a title, description, and category. Another contributor can reply to an open request by linking their own active offer. Show when the linked offer becomes unavailable. A request closes when its owner closes it or it reaches the same expiry duration used for offers. Members coordinate the exchange from the linked offer.
4. **Coordinate, confirm, and review.** Use one private text conversation per offer and interested contributor. While the offer is active, either participant can open an exchange in that conversation. Only one can be pending at a time. Either participant can cancel it or confirm their own side after handoff. The exchange completes only after both confirm. Existing conversations and pending exchanges can continue after owner closure or expiry. After completion, each participant can leave one rating and an optional short review for the other. A goods offer represents one item or lot. Its first completed exchange closes it and cancels any competing pending exchanges in the same operation. Service offers can stay active until closure or expiry. The inbox shows unread messages and pending confirmations.
5. **Report, block, and moderate.** Contributors can report accounts and user content, including messages they received, with a reason. Blocking prevents direct messages, request replies, and new exchanges between the pair and cancels their pending exchanges. Prior messages remain available to participants for reporting. Moderators can dismiss reports, remove violating content, and suspend or reinstate an account. Removing an offer cancels its pending exchanges. Suspension hides that member’s offers and requests, prevents new exchanges with that member, revokes their contributor actions across existing sessions, and cancels their pending exchanges. Record each moderation decision, reason, moderator, and time. Limit access to reported messages to participants and the staff handling the report.
6. **Run the pilot.** Administrators can add, rename, and deactivate categories, set listing expiry, and publish community rules. System administrators assign staff roles and use the existing operations console or a documented procedure to schedule backups, verify the latest run, and test recovery of records and listing photos. A named support owner verifies and processes account-deletion requests from Android or the web under the published retention rules.

## Required Solution Layers

| Layer | MVP requirement |
| --- | --- |
| Security and privacy by design | Publish a privacy notice and support contact. Collect only the account and area data needed for the pilot. Keep email, phone numbers, and exact locations out of public profile fields. Use the pilot area for discovery without collecting live location. Set retention periods for accounts, messages, reports, and backups. Obtain consent before collecting or sharing optional personal information. [Data Privacy Act of 2012](https://lawphil.net/statutes/repacts/ra2012/ra_10173_2012.html) |
| Authentication and authorization | Use Google Sign-In, one approved eligibility rule, and explicit staff permissions. If the pilot is student-only, choose a verification method that avoids retaining unnecessary student records. |
| Data management and integrity | Enforce offer visibility, exchange state, and review eligibility in the API. Prevent self-exchanges and duplicate confirmations or reviews. Allow only one completed exchange for a goods offer, even when confirmations arrive simultaneously. |
| Communication and notifications | Show new messages and pending confirmations in the private inbox. |
| Search and discovery | Return active offers in the pilot area with keyword search, a category filter, and newest first as the default. |
| Monitoring and moderation | Maintain one report queue. Assign owners for moderation, privacy requests, and backups. Preserve applicable retention and deletion decisions during recovery. |

## MVP Features and Access

| Requirement | Feature | Access |
| --- | --- | --- |
| 1 | View public policies and browse, search, or filter active offers | Everyone |
| 1 | Sign in with Google | E starts sign-in. The account’s assigned role determines access. |
| 2 | Publish, edit, close, or renew offers | D for their own offers |
| 3 | View requests, post or close requests, and reply with linked offers | D. Only the request owner can close it. |
| 4 | Use the private inbox, open, confirm, or cancel an exchange, and leave a review | D for their own conversations and exchanges. D can read published member reviews. |
| 5 | Report or block. Review reports and take moderation action. | D can report or block. C handles reports and moderation. |
| 6 | Configure categories and expiry. Publish community rules. | B |
| 6 | Assign staff roles, schedule and verify backups, and test recovery | A |
| 6 | Request account deletion | Account owners can start in Android or on the public web page. The designated support owner verifies and handles requests. |

## Notes

### Open pilot decisions

- Name the pilot community and decide whether eligibility is open to local members or limited to verified students before building onboarding. Confirm seller eligibility and the distribution channel. Review obligations for the chosen seller model and any Google Play submission. [DTI Internet Transactions Act and implementing rules](https://ecommerce.dti.gov.ph/ra11967/) · [Google Play user-generated content policy](https://support.google.com/googleplay/android-developer/answer/9876937?hl=en) · [Google Play account deletion policy](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en)
- Agree on the initial categories, expiry duration, data retention periods, and staff ownership. Recruit initial contributors with real offers before inviting the rest of the pilot community.

### Pilot acceptance

- With a guest and two contributors, find an offer, link an offer from a request, and arrange an exchange. Verify that one confirmation leaves reviews locked, both confirmations unlock one review per participant, and a completed goods offer leaves search. Check cancellation, expiry, and simultaneous confirmations.
- Verify that private conversations and staff actions are access-controlled. Exercise reporting, blocking, suspension, and account deletion. Restore a backup in a test environment before launch.
- During the pilot, count active offers, requests with a reply, and completed exchanges to see whether people are finding what they need.

### Deferred scope

Defer personalized recommendations, push notifications, nested discussions, the full web marketplace, in-app payments, fulfillment, and analytics dashboards.
