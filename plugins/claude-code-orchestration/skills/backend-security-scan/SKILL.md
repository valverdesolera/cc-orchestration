---
name: backend-security-scan
description: Use when checking backend changes for auth/authz mistakes, injection, unsafe deserialization, path traversal, SSRF, secrets in logs, tenant isolation, and unsafe defaults.
---

# Backend Security Scan

Review only the changed code path unless the change is repo-wide. Check authentication, authorization, tenant/account isolation, input validation, serialization, SQL/command injection, SSRF, path traversal, secrets in logs, unsafe defaults, and dependency risk. Report line-specific evidence and minimal fixes.
