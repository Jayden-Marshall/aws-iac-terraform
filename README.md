# AWS Three-Tier Architecture Deployment with Terraform  
# Brief Overview
Infrastructure as Code (IaC) Deployment Project
- ✅ Deploy a 3-tier architecture (Frontend, Backend, Database) on AWS & Azure
- ✅ Use Terraform to automate provisioning & scaling
- ✅ Set up IAM roles, security groups, Auto Scaling, Load Balancer
## Detailed Overview  
This project deploys a **three-tier architecture** on AWS using **Terraform** for Infrastructure as Code (IaC). The setup includes:  

- **VPC with public/private subnets**  
- **Application Load Balancer (ALB)** for traffic routing  
- **EC2 instances** for the app layer  
- **RDS (MySQL/PostgreSQL) database** in a private subnet  
- **IAM roles & security groups** for access control  

What started as a structured plan quickly turned into **a battle with networking, Terraform, and AWS quirks**. Every step had some issue that needed troubleshooting, but by the end, I had a fully working setup and a much deeper understanding of AWS infrastructure.

---

## Challenges & Fixes  

### 🛠 Terraform Dependency Issues  
- **Problem:** `terraform apply` kept failing due to dependency conflicts and incorrect resource ordering.  
- **Fix:**  
  - Used `depends_on` to explicitly set dependencies.  
  - Reordered resources to follow the correct creation sequence.  
  - Debugged with `terraform graph | dot -Tpng > graph.png` to visualize dependencies.  

### 🌐 VPC, Subnets & Route Table Confusion  
- **Problem:** EC2 instances couldn’t reach RDS because **they weren’t in the correct subnets** and the route tables were misconfigured.  
- **Fix:**  
  - Separated **public and private subnets correctly**.  
  - Configured proper **NACLs & security groups**.  
  - Ensured private subnets had a route to the database but not direct internet access.  

### 🔐 Security Groups & IAM Role Issues  
- **Problem:** EC2 instances couldn’t talk to RDS, S3, or the ALB.  
- **Fix:**  
  - Allowed only necessary inbound/outbound rules (**MySQL 3306, HTTP 80, HTTPS 443**).  
  - Created an **IAM role with proper S3 & EC2 permissions** and attached it correctly.  

### 🏗 ALB & Target Group Misconfigurations  
- **Problem:** ALB wasn’t forwarding traffic; health checks kept failing.  
- **Fix:**  
  - Set **target group health check path correctly** (`/index.html` instead of `/`).  
  - Switched from **IP-based targets to instance-based targets** to fix registration issues.  

### 🗄 Database Connection Issues  
- **Problem:** Couldn’t connect to RDS from the app servers.  
- **Fix:**  
  - Used **AWS Session Manager** to access instances and test connectivity.  
  - Ensured **RDS security group allowed inbound connections from app instances only** (not open to the world).  

### 🏗 Terraform State & Rollback Issues  
- **Problem:** State drift when trying to destroy and redeploy resources.  
- **Fix:**  
  - Used `terraform state rm <resource>` to remove corrupted state entries.  
  - Enabled **remote state storage with S3 & DynamoDB** to prevent future issues.  

---

## Tech Stack  
- **IaC:** Terraform  
- **Cloud Provider:** AWS  
- **Networking:** VPC, Subnets, Route Tables, Security Groups  
- **Compute:** EC2 (Amazon Linux 2)  
- **Load Balancing:** ALB  
- **Database:** AWS RDS (MySQL/PostgreSQL)  
- **IAM:** Roles & Policies for access control  

---

## Deployment Instructions  

### Prerequisites  
- **Terraform installed** (`brew install terraform` or `choco install terraform`)  
- **AWS CLI configured** (`aws configure`)  

### Steps  
```sh
git clone <repo-link>
cd <project-directory>

terraform init
terraform plan
terraform apply -auto-approve
```
To tear everything down:
```sh
terraform destroy -auto-approve
```
<h2>Final Thoughts</h2>
This project was a serious challenge, but it reinforced AWS networking, Terraform troubleshooting, and debugging skills in real-world scenarios. If you’re tackling something similar—expect errors, be patient, and take detailed notes.

<h3>🚀 On to the next project!</h3>
