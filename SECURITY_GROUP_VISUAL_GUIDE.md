# Security Group Setup - Visual Guide
## Step-by-Step with Exact Options

---

## 🔐 BACKEND SECURITY GROUP

### Basic Details Section:

```
Security group name: fluentfly-backend-sg
Description: Backend server security
VPC: vpc-xxxxx (default) - Leave as is
```

---

### Inbound Rules Section:

Click **"Add rule"** button 4 times to add these 4 rules:

---

#### ✅ RULE 1: SSH Access

```
Type: SSH (dropdown se select karo)
Protocol: TCP (automatically set hoga)
Port range: 22 (automatically set hoga)
Source: My IP (dropdown se select karo)
Description: SSH access
```

**Kaise karein:**
1. "Type" dropdown click karo
2. List mein "SSH" dhundo aur select karo
3. "Source" dropdown click karo
4. "My IP" select karo (tumhara IP automatically aa jayega)
5. "Description" field mein type karo: `SSH access`

---

#### ✅ RULE 2: Backend API (Port 3000)

```
Type: Custom TCP (dropdown se select karo)
Protocol: TCP (automatically set hoga)
Port range: 3000 (manually type karo)
Source: Anywhere-IPv4 (dropdown se select karo)
Description: Backend API
```

**Kaise karein:**
1. "Type" dropdown click karo
2. **"Custom TCP"** select karo
3. "Port range" field mein **3000** type karo
4. "Source" dropdown click karo
5. **"Anywhere-IPv4"** select karo
   - Ye automatically `0.0.0.0/0` set kar dega
6. "Description" mein type karo: `Backend API`

---

#### ✅ RULE 3: HTTP Traffic

```
Type: HTTP (dropdown se select karo)
Protocol: TCP (automatically set hoga)
Port range: 80 (automatically set hoga)
Source: Anywhere-IPv4 (dropdown se select karo)
Description: HTTP traffic
```

**Kaise karein:**
1. "Type" dropdown click karo
2. "HTTP" select karo
3. "Source" dropdown click karo
4. "Anywhere-IPv4" select karo
5. "Description" mein type karo: `HTTP traffic`

---

#### ✅ RULE 4: HTTPS Traffic

```
Type: HTTPS (dropdown se select karo)
Protocol: TCP (automatically set hoga)
Port range: 443 (automatically set hoga)
Source: Anywhere-IPv4 (dropdown se select karo)
Description: HTTPS traffic
```

**Kaise karein:**
1. "Type" dropdown click karo
2. "HTTPS" select karo
3. "Source" dropdown click karo
4. "Anywhere-IPv4" select karo
5. "Description" mein type karo: `HTTPS traffic`

---

### Final Check:

Tumhare paas ab **4 inbound rules** hone chahiye:

| Type | Protocol | Port Range | Source | Description |
|------|----------|------------|--------|-------------|
| SSH | TCP | 22 | My IP (xx.xx.xx.xx/32) | SSH access |
| Custom TCP | TCP | 3000 | 0.0.0.0/0 | Backend API |
| HTTP | TCP | 80 | 0.0.0.0/0 | HTTP traffic |
| HTTPS | TCP | 443 | 0.0.0.0/0 | HTTPS traffic |

---

### Outbound Rules:

**Kuch nahi karna!** Default outbound rule already hai:

```
Type: All traffic
Protocol: All
Port range: All
Destination: 0.0.0.0/0
```

Ye rakhne do as is.

---

### Create Button:

Neeche scroll karo aur orange **"Create security group"** button par click karo.

✅ **Backend Security Group Complete!**

---

## 🗄️ DATABASE SECURITY GROUP

### Basic Details:

```
Security group name: fluentfly-db-sg
Description: Database security
VPC: vpc-xxxxx (default) - Same as backend
```

---

### Inbound Rules:

Sirf **1 rule** add karo:

#### ✅ RULE 1: PostgreSQL Access

```
Type: PostgreSQL (dropdown se select karo)
Protocol: TCP (automatically set hoga)
Port range: 5432 (automatically set hoga)
Source: Custom (dropdown se select karo)
```

**IMPORTANT - Source field:**
1. "Source" dropdown click karo
2. **"Custom"** select karo
3. Text field mein **"sg-"** type karo
4. Dropdown mein tumhara **"fluentfly-backend-sg"** dikhega
5. Use select karo
6. Description: `Backend to database`

**Final rule:**
```
Type: PostgreSQL
Protocol: TCP
Port range: 5432
Source: sg-xxxxxxxxx (fluentfly-backend-sg)
Description: Backend to database
```

---

### Create Button:

**"Create security group"** click karo.

✅ **Database Security Group Complete!**

---

## 💾 REDIS SECURITY GROUP

### Basic Details:

```
Security group name: fluentfly-redis-sg
Description: Redis cache security
VPC: vpc-xxxxx (default) - Same as backend
```

---

### Inbound Rules:

Sirf **1 rule** add karo:

#### ✅ RULE 1: Redis Access

```
Type: Custom TCP (dropdown se select karo)
Protocol: TCP (automatically set hoga)
Port range: 6379 (manually type karo)
Source: Custom (dropdown se select karo)
```

**Kaise karein:**
1. "Type" dropdown → **"Custom TCP"** select karo
2. "Port range" field mein **6379** type karo
3. "Source" dropdown → **"Custom"** select karo
4. Text field mein **"sg-"** type karo
5. **"fluentfly-backend-sg"** select karo
6. Description: `Backend to Redis`

**Final rule:**
```
Type: Custom TCP
Protocol: TCP
Port range: 6379
Source: sg-xxxxxxxxx (fluentfly-backend-sg)
Description: Backend to Redis
```

---

### Create Button:

**"Create security group"** click karo.

✅ **Redis Security Group Complete!**

---

## 📋 QUICK REFERENCE

### Common "Type" Options in Dropdown:

```
- All ICMP - IPv4
- All TCP
- All traffic
- All UDP
- Custom ICMP - IPv4
- Custom TCP          ← Use this for custom ports
- Custom UDP
- DNS (TCP)
- DNS (UDP)
- HTTP                ← Port 80
- HTTPS               ← Port 443
- LDAP
- LDAPS
- MS SQL
- MYSQL/Aurora
- NFS
- Oracle-RDS
- PostgreSQL          ← Port 5432
- RDP
- SMTP
- SSH                 ← Port 22
- WinRM-HTTP
- WinRM-HTTPS
```

### Common "Source" Options:

```
- Custom              ← Manual IP ya security group
- Anywhere-IPv4       ← 0.0.0.0/0 (public access)
- Anywhere-IPv6       ← ::/0 (public IPv6)
- My IP               ← Tumhara current IP
```

---

## 🎯 Summary

**3 Security Groups banane hain:**

1. ✅ **fluentfly-backend-sg** - 4 inbound rules (SSH, Custom TCP 3000, HTTP, HTTPS)
2. ✅ **fluentfly-db-sg** - 1 inbound rule (PostgreSQL from backend SG)
3. ✅ **fluentfly-redis-sg** - 1 inbound rule (Custom TCP 6379 from backend SG)

---

## 💡 Pro Tips

1. **"Custom TCP"** use karo jab specific port number chahiye (3000, 6379, etc.)
2. **"My IP"** use karo SSH ke liye (security)
3. **"Anywhere-IPv4"** use karo public access ke liye (HTTP, HTTPS, API)
4. **Security Group ID** use karo internal communication ke liye (DB, Redis)

---

Koi confusion ho to screenshot bhejo! 🚀
