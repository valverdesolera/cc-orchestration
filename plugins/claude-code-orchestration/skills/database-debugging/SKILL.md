---
name: database-debugging
description: Use when investigating SQL, ORM behavior, migrations, schema mismatches, transactions, indexes, connection pools, slow queries, locks, or data constraints.
---

# Database Debugging

Use read-only database access only. Never run `INSERT`, `UPDATE`, `DELETE`, `ALTER`, `DROP`, `TRUNCATE`, `CREATE`, migrations, admin commands, or lock-changing commands.

Check schema/code mismatch, query behavior, transactions, performance, constraints, indexes, tenant scoping, soft deletes, and ORM mappings. Output suspected table/column/index/constraint, read-only queries used, findings, and minimal fix plan.
