# Prerequisites — crAPI + Zuplo on AWS Lab

Everything you need before you start. If any of these aren't in place, something will break and it won't be obvious why.

---

## 1. AWS Account & CLI

**What you need:**
- An active AWS account
- AWS CLI installed and configured with credentials

**Check it works:**
```bash
aws sts get-caller-identity
```
Should return your account ID, user ID, and ARN. If it errors, your credentials aren't set up.

**Install AWS CLI (if missing):**
```bash
# Mac
brew install awscli

# Or download from:
# https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html
```

**Configure credentials:**
```bash
aws configure
# Enter: Access Key ID, Secret Access Key, region (us-east-2), output format (json)
```

---

## 2. AWS Key Pair

**What you need:**
- A key pair named `mcropsey-aws-labs` in AWS region `us-east-2`
- The private key file at `~/.ssh/mcropsey-aws-labs` on your machine

**Why it matters:** The CloudFormation template references this key pair by name. If it doesn't exist in AWS, the stack will fail to create.

**⚠️ Mac users (OpenSSH 10+):** Do NOT let AWS generate the key for you. AWS-generated ed25519 keys are incompatible with newer macOS SSH clients. Generate locally and import.

**Create it (do this once):**
```bash
# Step 1 - Generate locally
ssh-keygen -t ed25519 -f ~/.ssh/mcropsey-aws-labs -N ""

# Step 2 - Import public key to AWS
aws ec2 import-key-pair \
  --key-name mcropsey-aws-labs \
  --public-key-material fileb://~/.ssh/mcropsey-aws-labs.pub \
  --region us-east-2

# Step 3 - Verify
aws ec2 describe-key-pairs --region us-east-2 \
  --key-names mcropsey-aws-labs \
  --query 'KeyPairs[0].KeyName' --output text
# Should print: mcropsey-aws-labs
```

**Check private key exists locally:**
```bash
ls -la ~/.ssh/mcropsey-aws-labs
# Should show the file. If missing, redo steps above.
```

---

## 3. Required Lab Files

You need these three files in the same folder before running anything:

| File | Purpose |
|---|---|
| `deploy.sh` | Deploys the CloudFormation stack |
| `mcropsey-aws-crapi-lab.yaml` | The CloudFormation template |
| `routes.oas.json` | The patched OpenAPI spec for Zuplo import |

**Make deploy.sh executable:**
```bash
chmod +x deploy.sh
```

If `deploy.sh` isn't executable you'll get `permission denied` when you try to run it.

---

## 4. Zuplo Account

**What you need:**
- Access to the Zuplo portal at portal.zuplo.com
- Account: `rose_yearning_carp`
- Project: `crapi-cropseyit-com`

**Why it matters:** The gateway URL `https://crapi-cropseyit-com-main-64db34b.zuplo.app` only works if the project is deployed and configured. Without BASE_URL set and routes imported, all requests will fail.

---

## 5. curl

Used to test all API endpoints from the command line.

**Check it's installed:**
```bash
curl --version
```

**Install if missing:**
```bash
# Mac
brew install curl

# Linux
sudo apt install curl
```

---

## 6. python3 (for pretty-printing JSON responses)

The curl test script pipes responses through `python3 -m json.tool` to format them readably. Without it the output is one long unreadable line.

**Check it's installed:**
```bash
python3 --version
```

**Install if missing:**
```bash
# Mac
brew install python3

# Linux
sudo apt install python3
```

If you don't have python3 and don't want to install it, remove the `| python3 -m json.tool` from the end of each curl command — the commands still work, output just won't be formatted.

---

## 7. A Valid JWT Token (for authenticated curl commands)

Most crAPI endpoints require a Bearer token. You get one by logging in first.

**Run this before anything else in the test script:**
```bash
curl -s -X POST "https://crapi-cropseyit-com-main-64db34b.zuplo.app/identity/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"mike1@my.lab","password":"Mylab123!"}' | python3 -m json.tool
```

**Copy the token value from the response** and paste it into the `TOKEN=` variable at the top of `crapi-curl-tests.sh`:
```bash
TOKEN="eyJhbGciOiJSUzI1NiJ9.eyJzdWIi..."
```

**Token expiry:** Tokens expire after ~7 days. If you get 401 Unauthorized, just log in again and get a fresh token.

---

## 8. A Registered crAPI User Account

The test script uses `mike1@my.lab` / `Mylab123!` as the test account. This user must already exist in the crAPI database.

**If the account doesn't exist yet**, run the signup curl first (test #1 in the script), then log in to get a token.

**MailHog** is available to see emails crAPI sends (password resets, vehicle details, etc.):
```
http://ec2-18-191-123-226.us-east-2.compute.amazonaws.com:8025
```

---

## 9. The crAPI Stack Must Be Running

The EC2 instance and all Docker containers must be up before any API calls will work.

**Check stack status:**
```bash
aws cloudformation describe-stacks \
  --stack-name mcropsey-lab \
  --region us-east-2 \
  --query 'Stacks[0].StackStatus' --output text
# Should return: CREATE_COMPLETE or UPDATE_COMPLETE
```

**Check containers are running (SSH in first):**
```bash
ssh -i ~/.ssh/mcropsey-aws-labs ec2-user@ec2-18-191-123-226.us-east-2.compute.amazonaws.com
cd /opt/crapi && docker-compose ps
```
All containers (crapi-web, crapi-identity, crapi-community, crapi-workshop, postgresdb, mongodb, mailhog) should show `Up`.

**If containers are still starting**, wait 5 minutes and retry. A 502 or connection refused from Zuplo means crAPI isn't ready yet.

---

## Quick Checklist

Before running the curl test script, confirm all of these:

- [ ] `aws sts get-caller-identity` works
- [ ] `~/.ssh/mcropsey-aws-labs` private key exists
- [ ] Key pair `mcropsey-aws-labs` exists in AWS us-east-2
- [ ] CloudFormation stack status is `CREATE_COMPLETE`
- [ ] All Docker containers show `Up`
- [ ] `curl --version` works
- [ ] `python3 --version` works
- [ ] Zuplo project has `BASE_URL` set to `http://ec2-18-191-123-226.us-east-2.compute.amazonaws.com:8888`
- [ ] `routes.oas.json` has been imported into Zuplo
- [ ] You have a valid JWT token in the `TOKEN=` variable in the test script
- [ ] Test user `mike1@my.lab` exists in crAPI (or run signup first)
