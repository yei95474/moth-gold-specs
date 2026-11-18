# Business Logic
## Project Details
- Company/Team Name: <SaBai>
- Project Code Name: <Moth Gold>
- Project Short Code: <MG>
- Short Description: <A community marketplace connecting local buyers and sellers for daily opportunities.>
- Long Description: <Moth Gold is a community marketplace connecting local buyers and sellers for daily opportunities. It allows users to post and goods, products and services in their community, with a focus on trust and local engagement.>

## User Levels

> Note: Modify/rename the list of users based on the actual users that you expect to use the
system.

| User Level | Description |
| ----------------------- | ----------- |
| A. System Administrator | Maintains/overrides system/server configurations and perform 
regular backups. |
| B. Administrator | Manages the general settings of the system and generates periodic
system analytics and reports. |
| C. Moderator | Moderates user content and behaviors, banning users, deleting posts, etc.|
| D. Contributor | End users that post products, offers services, and buyers.|
| E. Guest | Users who do not log in, but view limited contents on the app/web. |

## System Requirements
1. The app shall allow the users to authenticate using Google Sign-In integration.
2. The app shall allow the users to publish listings for goods, products and services.
3. The app shall allow the users to browse, search, and view active listings.
4. The app shall allow the users to edit their own listings and mark them as closed when the item or service is no longer available.
5. The app shall allow the users to communicate with each other to negotiate and coordinate transactions.
6. The app shall allow the users to add reviews and ratings to each other only after a transaction is marked as completed by both parties.
7. The app shall allow the users to report a listing or account for an alleged community rule violation and provide a reason for the report.
8. The app shall allow users to review reports, remove listings that violate community rules, and suspend accounts that violate those rules.
9. The app shall allow users to add, rename, and deactivate listing categories.
10. The app shall allow users to schedule regular database backups and verify whether the latest backup succeeded.
11. The app shall allow users to start a discussion thread describing a good or service they need. Other contributors shall be able to reply directly in the thread and link to an existing marketplace listing that may meet the request.
12. The app shall allow administrators to set how long a listing stays active before it expires.
13. The app shall allow administrators to publish and update the community rules that users and moderators can view.

## Required Solution Layers

1. Security and Privacy by Design. The system shall comply with the Philippine Data Privacy Act of 2012 (RA 10173), protect personal information, restrict access to sensitive data, avoid unnecessary location tracking, establish data retention limits, and require consent before collecting or sharing optional personal information.
2. Authentication and Authorization. The system shall implement Google Sign-In, student verification, and role-based access control to ensure that users can only access features and information permitted by their assigned roles.
3. Data Management and Integrity. The system shall maintain accurate records of users, item listings, exchange requests, and transactions while preventing duplicate or inconsistent records.
4. Communication and Notifications. The system shall provide a messaging and notification mechanism to keep students informed about exchange requests, listing updates, and transaction progress.
5. Search and Recommendation. The system shall support efficient item discovery through category-based filtering, and relevant item recommendations.
6. System Monitoring and Moderation. The system shall provide tools for administrators and moderators to monitor platform activities, review reported content, and address suspicious or inappropriate listings.

## MVP Features and Access

> See the User Levels table for reference.

| Feature | Access |
| --- | --- |
| 1. Sign in with Google | A, B, C, D, E |
| 2. Publish listings for goods and services | D |
| 3. Browse, search, and view active listings | A, B, C, D. E |
| 4. Edit and close own listings | D |
| 5. Message other contributors to negotiate and coordinate transactions | D |
| 6. Confirm transaction completion and leave mutual reviews and ratings | D |
| 7. Report a listing or account and provide a reason | D |
| 8. Review reports, remove listings, and suspend accounts | C |
| 9. Add, rename, and deactivate listing categories | B |
| 10. Schedule database backups and check whether the latest backup succeeded | A |
| 11. Start community request threads and reply with links to existing listings | D |
| 12. Set how long listings stay active before expiring | B |
| 13. Publish, update, and view community rules | B can publish and update. A, B, C, D, and E can view. |

## Notes
- xxx