# CI/CD Pipeline Architecture

## Pipeline Flow Diagram

```
┌──────────────────────────────────────────────────────────────────────────┐
│                        Multi-Environment CI/CD Pipeline                   │
└──────────────────────────────────────────────────────────────────────────┘

┌─────────────┐
│  Developer  │
└──────┬──────┘
       │
       │ git push
       ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                           GitHub Repository                              │
└─────────────────────────────────────────────────────────────────────────┘
       │
       ├─────────────────┬─────────────────┬─────────────────┐
       │                 │                 │                 │
       ▼                 ▼                 ▼                 ▼
   develop          uat/release/*       main           tags (v*.*.*)
       │                 │                 │                 │
       │                 │                 │                 │
       ▼                 ▼                 ▼                 ▼
┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│   DEV       │   │    UAT      │   │    PROD     │   │    PROD     │
│  Workflow   │   │  Workflow   │   │  Workflow   │   │  Workflow   │
└──────┬──────┘   └──────┬──────┘   └──────┬──────┘   └──────┬──────┘
       │                 │                 │                 │
       │                 │                 │                 │
       ▼                 ▼                 ▼                 ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                           Test & Build Phase                             │
│  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐           │
│  │  Lint  │  │  Unit  │  │ Integ  │  │  E2E   │  │Security│           │
│  │  Code  │  │  Test  │  │  Test  │  │  Test  │  │  Scan  │           │
│  └────────┘  └────────┘  └────────┘  └────────┘  └────────┘           │
│     DEV         ALL         UAT+       PROD        UAT+PROD             │
└──────────────────────────────────────────────────────────────────────────┘
       │                 │                 │
       │                 │                 │ Manual Approval
       │                 │                 │ (2+ reviewers, 5min wait)
       │                 │                 │
       ▼                 ▼                 ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                        Build & Push to ECR                               │
│  ┌────────────────────────────────────────────────────────────┐         │
│  │  docker build → tag → push to ECR                          │         │
│  │  - myapp-dev:latest, dev-latest                            │         │
│  │  - myapp-uat:latest, uat-latest                            │         │
│  │  - myapp-prod:latest, prod-latest, v1.0.0                  │         │
│  └────────────────────────────────────────────────────────────┘         │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────┐         │
│  │  ECR Image Vulnerability Scan                              │         │
│  │  - DEV: Basic scan                                         │         │
│  │  - UAT: Full scan + report                                 │         │
│  │  - PROD: Full scan + block critical                        │         │
│  └────────────────────────────────────────────────────────────┘         │
└──────────────────────────────────────────────────────────────────────────┘
       │                 │                 │
       ▼                 ▼                 ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                     Deploy to AWS ECS                                    │
│                                                                          │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐              │
│  │   DEV         │  │   UAT         │  │   PROD        │              │
│  │               │  │               │  │               │              │
│  │ 256 CPU       │  │ 512 CPU       │  │ 1024 CPU      │              │
│  │ 512 MB        │  │ 1024 MB       │  │ 2048 MB       │              │
│  │               │  │               │  │               │              │
│  │ Rolling       │  │ Rolling       │  │ Blue-Green    │              │
│  │ Max: 200%     │  │ Max: 200%     │  │ Max: 200%     │              │
│  │ Min: 50%      │  │ Min: 100%     │  │ Min: 100%     │              │
│  └───────┬───────┘  └───────┬───────┘  └───────┬───────┘              │
│          │                  │                  │                       │
│          │                  │                  │ Auto Rollback         │
│          │                  │                  │ on Failure            │
└──────────┴──────────────────┴──────────────────┴───────────────────────┘
           │                  │                  │
           ▼                  ▼                  ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                      Post-Deployment                                     │
│  ┌────────────────────────────────────────────────────────────┐         │
│  │  Health Checks → Smoke Tests → Monitoring                  │         │
│  └────────────────────────────────────────────────────────────┘         │
│                                                                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                    │
│  │ CloudWatch  │  │ Prometheus  │  │   Grafana   │                    │
│  │    Logs     │  │   Metrics   │  │  Dashboard  │                    │
│  └─────────────┘  └─────────────┘  └─────────────┘                    │
└──────────────────────────────────────────────────────────────────────────┘
```

## Environment Comparison

```
┌─────────────────┬─────────────────┬─────────────────┬─────────────────┐
│    Feature      │      DEV        │      UAT        │      PROD       │
├─────────────────┼─────────────────┼─────────────────┼─────────────────┤
│ Trigger         │ develop branch  │ uat branch      │ main/tags       │
│ Auto Deploy     │ Yes             │ Yes             │ Yes             │
│ Approval        │ No              │ Optional        │ Required (2+)   │
│ Resources       │ Small           │ Medium          │ Large           │
│ CPU             │ 256             │ 512             │ 1024            │
│ Memory          │ 512 MB          │ 1024 MB         │ 2048 MB         │
│ Replicas        │ 1               │ 1-2             │ 2-3             │
│ Strategy        │ Rolling         │ Rolling         │ Blue-Green      │
│ Unit Tests      │ ✅              │ ✅              │ ✅              │
│ Integration     │ ❌              │ ✅              │ ✅              │
│ E2E Tests       │ ❌              │ ❌              │ ✅              │
│ Security Scan   │ Basic           │ Full            │ Full+Block      │
│ Smoke Tests     │ ❌              │ ✅              │ ✅              │
│ Auto Rollback   │ ❌              │ ❌              │ ✅              │
│ Monitoring      │ Basic           │ Basic           │ Full            │
│ Log Level       │ DEBUG           │ INFO            │ WARN            │
│ Metrics         │ ❌              │ ✅              │ ✅              │
│ Tracing         │ ❌              │ ❌              │ ✅              │
└─────────────────┴─────────────────┴─────────────────┴─────────────────┘
```

## Resource Flow

```
┌──────────────────────────────────────────────────────────────────┐
│                        AWS Resources                              │
└──────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  ECR (Elastic Container Registry)                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │ myapp-dev   │  │ myapp-uat   │  │ myapp-prod  │            │
│  │   Images    │  │   Images    │  │   Images    │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
└─────────────────────────────────────────────────────────────────┘
         │                 │                 │
         ▼                 ▼                 ▼
┌─────────────────────────────────────────────────────────────────┐
│  ECS (Elastic Container Service)                                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │   Cluster   │  │   Cluster   │  │   Cluster   │            │
│  │     DEV     │  │     UAT     │  │     PROD    │            │
│  │             │  │             │  │             │            │
│  │  Service    │  │  Service    │  │  Service    │            │
│  │  ├─ Task 1  │  │  ├─ Task 1  │  │  ├─ Task 1  │            │
│  │             │  │  ├─ Task 2  │  │  ├─ Task 2  │            │
│  │             │  │             │  │  ├─ Task 3  │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
└─────────────────────────────────────────────────────────────────┘
         │                 │                 │
         ▼                 ▼                 ▼
┌─────────────────────────────────────────────────────────────────┐
│  Application Load Balancer (ALB)                                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │  ALB-DEV    │  │  ALB-UAT    │  │  ALB-PROD   │            │
│  │    :80      │  │    :80      │  │    :80/:443 │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
└─────────────────────────────────────────────────────────────────┘
         │                 │                 │
         ▼                 ▼                 ▼
┌─────────────────────────────────────────────────────────────────┐
│  VPC & Networking                                               │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Availability Zone A    │    Availability Zone B         │  │
│  │  ┌─────────┐           │    ┌─────────┐                 │  │
│  │  │ Subnet  │           │    │ Subnet  │                 │  │
│  │  │  Tasks  │           │    │  Tasks  │                 │  │
│  │  └─────────┘           │    └─────────┘                 │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
         │                 │                 │
         ▼                 ▼                 ▼
┌─────────────────────────────────────────────────────────────────┐
│  Supporting Services                                            │
│  ┌─────────────────┐  ┌─────────────────┐  ┌────────────────┐ │
│  │   CloudWatch    │  │     Secrets     │  │   Parameter    │ │
│  │      Logs       │  │    Manager      │  │     Store      │ │
│  └─────────────────┘  └─────────────────┘  └────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Security Flow

```
┌──────────────────────────────────────────────────────────────────┐
│                      Security Layers                             │
└──────────────────────────────────────────────────────────────────┘

1. Code Security
   ├─ GitHub Secrets (encrypted)
   ├─ Branch Protection Rules
   └─ Required Reviews (PROD)

2. Build Security
   ├─ Docker Image Scanning (ECR)
   ├─ Vulnerability Database
   └─ Critical CVE Blocking (PROD)

3. Runtime Security
   ├─ IAM Roles & Policies
   ├─ Security Groups
   ├─ VPC Network Isolation
   └─ Secrets Manager

4. Data Security
   ├─ TLS/SSL Encryption
   ├─ Data at Rest Encryption
   └─ Database Encryption

5. Monitoring & Audit
   ├─ CloudWatch Logs
   ├─ CloudTrail Audit
   └─ AWS Config
```

## Deployment Timeline

```
DEV Deployment (Fast Feedback):
├─ Commit to develop branch
├─ [1-2 min] Run tests & lint
├─ [2-3 min] Build & push image
├─ [1 min] Security scan (basic)
├─ [2-3 min] Deploy to ECS
└─ Total: ~8-10 minutes

UAT Deployment (Quality Gate):
├─ Commit to uat/release branch
├─ [2-3 min] Run tests & lint
├─ [1-2 min] Integration tests
├─ [2-3 min] Build & push image
├─ [2-3 min] Security scan (full)
├─ [3-4 min] Deploy to ECS
├─ [1 min] Smoke tests
└─ Total: ~12-15 minutes

PROD Deployment (Safe & Controlled):
├─ Commit to main or create tag
├─ [2-3 min] Run all tests
├─ [1-2 min] E2E tests
├─ [2-3 min] Security scan (full+block)
├─ [2-3 min] Build & push image
├─ [5 min] Manual approval wait
├─ [2+ reviewers] Review & approve
├─ [5-7 min] Blue-green deployment
├─ [2 min] Production smoke tests
├─ [2 min] Monitoring verification
└─ Total: ~25-30 minutes
```
