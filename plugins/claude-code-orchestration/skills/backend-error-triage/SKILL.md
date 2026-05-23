---
name: backend-error-triage
description: Use when investigating backend exceptions, API errors, failing backend tests, runtime crashes, CI failures, worker errors, or service regressions.
---

# Backend Error Triage

1. Capture the exact error: message, stack trace, failing command, endpoint/job/worker, environment, timestamp, release or commit.
2. Classify the failure: API/routing, validation/schema, auth/authz, database, queue/async, external integration, config/env, performance, security, CI/test-only.
3. Localize the code path from stack trace through route/controller, service/use-case, repository/database, integration/client, and middleware.
4. Reproduce narrowly using one failing test, endpoint call, worker invocation, or exact CI command.
5. Report root cause, confidence, evidence, minimal fix plan, and regression test recommendation.
