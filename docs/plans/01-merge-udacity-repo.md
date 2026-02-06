# Plan: Merge Udacity Repo with Our Implementation

**Created:** February 6, 2026  
**Status:** Pending Execution  
**Branch:** dev

---

## Objective

Merge the official Udacity project template with our tested implementation while:
- Keeping a single repository
- Preserving our verified, working code
- Adding missing Udacity-specific files (IAM templates, etc.)
- Ensuring full alignment with project requirements

---

## Execution Steps

### Step 1: Prepare Dev Branch

```bash
cd /Users/skazo4nick/Documents/code/udacity-python-dev-flask-k8s

# Stage and commit our current work
git add .
git commit -m "feat: complete local implementation before Udacity merge"

# Create and switch to dev branch
git checkout -b dev
```

### Step 2: Download Udacity Repository

```bash
# Download as zip
curl -L -o udacity-repo.zip https://github.com/udacity/cd0157-Server-Deployment-and-Containerization/archive/refs/heads/master.zip

# Unzip
unzip udacity-repo.zip

# Verify contents
ls -la cd0157-Server-Deployment-and-Containerization-master/
```

### Step 3: Update .gitignore

Add to `.gitignore`:
```
# Downloaded archives
*.zip
udacity-repo.zip

# Archive directory (our backup code)
archive/
```

### Step 4: Create Archive Directory

```bash
mkdir -p archive
```

Move redundant/backup files here if we replace them with Udacity versions.

### Step 5: File Comparison & Merge Strategy

| File | Udacity Has | We Have | Action |
|------|-------------|---------|--------|
| `main.py` | ✅ Template | ✅ Complete | Keep ours (tested) |
| `test_main.py` | ✅ Empty/TODO | ✅ 9 tests | Keep ours (tested) |
| `requirements.txt` | ✅ Basic | ✅ Complete | Keep ours |
| `Dockerfile` | ✅ Template | ✅ Complete | Keep ours (tested) |
| `buildspec.yml` | ✅ Template | ✅ Complete | Compare & merge |
| `simple_jwt_api.yml` | ✅ Template | ✅ Complete | Compare & merge |
| `ci-cd-codepipeline.cfn.yml` | ✅ Template | ✅ Complete | Compare & merge |
| `trust.json` | ✅ Yes | ❌ Missing | **Copy from Udacity** |
| `iam-role-policy.json` | ✅ Yes | ❌ Missing | **Copy from Udacity** |
| `aws-auth-patch.yml` | ✅ Sample | ❌ Missing | **Copy from Udacity** |
| `.env_file` | ❓ Unknown | ✅ Yes | Keep ours |
| `devlog.md` | ❌ No | ✅ Yes | Keep ours |
| `README.md` | ✅ Instructions | ✅ Complete | Merge best of both |

### Step 6: Copy Missing Files from Udacity

```bash
# Copy IAM templates (we don't have these)
cp cd0157-Server-Deployment-and-Containerization-master/trust.json .
cp cd0157-Server-Deployment-and-Containerization-master/iam-role-policy.json .
cp cd0157-Server-Deployment-and-Containerization-master/aws-auth-patch.yml .
```

### Step 7: Compare Critical Files

Review and merge if Udacity templates have required structure we might have missed:

1. **buildspec.yml** - Check if Udacity's has different phases/commands
2. **ci-cd-codepipeline.cfn.yml** - May have required parameter names
3. **simple_jwt_api.yml** - Check K8s manifest structure

### Step 8: Cleanup

```bash
# Remove extracted folder
rm -rf cd0157-Server-Deployment-and-Containerization-master/

# Optionally remove zip (or keep for reference)
rm udacity-repo.zip
```

### Step 9: Validate

```bash
# Run tests to ensure nothing broke
python -m pytest test_main.py -v

# Rebuild Docker image
docker build -t simple-jwt-api .

# Test container
docker run -d -p 8080:8080 --env-file .env_file --name test-merge simple-jwt-api
curl http://localhost:8080/
docker stop test-merge && docker rm test-merge
```

### Step 10: Commit Merged Code

```bash
git add .
git commit -m "feat: merge Udacity template with tested implementation"
```

---

## Expected Final Structure

```
.
├── main.py                      # Our implementation (tested)
├── test_main.py                 # Our 9 unit tests (tested)
├── requirements.txt             # Our dependencies
├── Dockerfile                   # Our container config (tested)
├── .env_file                    # Local env vars
├── buildspec.yml                # Merged/verified
├── simple_jwt_api.yml           # Merged K8s manifest
├── ci-cd-codepipeline.cfn.yml   # Merged CloudFormation
├── trust.json                   # FROM UDACITY
├── iam-role-policy.json         # FROM UDACITY  
├── aws-auth-patch.yml           # FROM UDACITY
├── README.md                    # Merged documentation
├── devlog.md                    # Our progress log
├── LICENSE
├── .gitignore                   # Updated
├── archive/                     # Backup of replaced files
├── docs/
│   ├── plans/
│   │   └── 01-merge-udacity-repo.md  # This file
│   └── project_description/
│       └── ...
└── venv/                        # gitignored
```

---

## Rollback Plan

If merge causes issues:
```bash
# Return to main branch with original implementation
git checkout main

# Or reset dev branch
git checkout dev
git reset --hard HEAD~1
```

---

## Success Criteria

- [ ] All 9 unit tests pass
- [ ] Docker build succeeds
- [ ] All 3 endpoints work in container
- [ ] `trust.json` present
- [ ] `iam-role-policy.json` present
- [ ] `aws-auth-patch.yml` present
- [ ] CloudFormation template has required defaults
- [ ] buildspec.yml references JWT_SECRET from Parameter Store
- [ ] No duplicate/conflicting files

---

## Notes

- The Udacity repo provides **templates** with TODOs
- Our repo has **complete, tested implementations**
- We only need their IAM-related files that we didn't create
- Keep archive/ for any files we replace (audit trail)
