---
inclusion: always
---

# Professional DevOps Practices for FluentFly AI

## Deployment Maturity Levels

### Level 1: Manual Deployment (Current)
- SSH to server
- Git pull manually
- Restart services manually
- ❌ Error-prone, slow, not scalable

### Level 2: Automated CI/CD (Target)
- Push to GitHub
- Automated tests run
- Auto-deploy on success
- ✅ Fast, reliable, professional

### Level 3: Enterprise (Future)
- Multi-environment (dev/staging/prod)
- Blue-green deployments
- Auto-rollback on failure
- Infrastructure as Code (Terraform)

## Current Setup: GitHub Actions + AWS EC2

### Deployment Flow
```
1. Developer commits code
2. Push to GitHub (main branch)
3. GitHub Actions triggers
4. Run tests automatically
5. Build Docker images
6. Deploy to AWS EC2
7. Health check
8. Notify on Slack/Email
```

### Infrastructure Components

**AWS Resources:**
- EC2: Application server
- RDS: PostgreSQL database (managed)
- ElastiCache: Redis (managed)
- S3: Static assets & backups
- CloudWatch: Monitoring & logs
- Route53: DNS management
- ALB: Load balancer (for scaling)

**Monitoring Stack:**
- CloudWatch: AWS metrics
- Prometheus: Application metrics
- Grafana: Dashboards
- Sentry: Error tracking
- Uptime Robot: Availability monitoring

## Best Practices

### 1. Environment Management
```
Development → Staging → Production
```

**Environments:**
- `dev` - Local development
- `staging` - Pre-production testing
- `production` - Live users

### 2. Secrets Management
- Use AWS Secrets Manager
- Never commit secrets to Git
- Rotate credentials regularly
- Use IAM roles (not access keys)

### 3. Database Management
- Automated backups (daily)
- Point-in-time recovery
- Read replicas for scaling
- Migration scripts in version control

### 4. Monitoring & Alerts
- Set up health checks
- Monitor error rates
- Track response times
- Alert on anomalies

### 5. Disaster Recovery
- Automated backups
- Documented recovery procedures
- Regular DR drills
- Multi-region setup (future)

## Deployment Checklist

### Before Deployment
- [ ] All tests pass
- [ ] Code reviewed
- [ ] Database migrations tested
- [ ] Environment variables updated
- [ ] Backup created
- [ ] Rollback plan ready

### During Deployment
- [ ] Deploy to staging first
- [ ] Run smoke tests
- [ ] Monitor error rates
- [ ] Check performance metrics

### After Deployment
- [ ] Verify all features work
- [ ] Check logs for errors
- [ ] Monitor for 30 minutes
- [ ] Update documentation

## Zero-Downtime Deployment

### Strategy: Blue-Green Deployment
```
1. Current version (Blue) running
2. Deploy new version (Green)
3. Test Green environment
4. Switch traffic to Green
5. Keep Blue as backup
6. Decommission Blue after 24h
```

### Implementation:
- Use Docker containers
- Load balancer switches traffic
- Instant rollback if issues
- No user impact

## Scaling Strategy

### Horizontal Scaling
```
1 Server → 2 Servers → 4 Servers → Auto-scaling
```

**When to scale:**
- CPU > 70% for 5 minutes
- Memory > 80%
- Response time > 500ms
- Error rate > 1%

### Vertical Scaling
```
t2.medium → t2.large → t2.xlarge
```

**When to scale:**
- Database queries slow
- Memory constraints
- CPU bottlenecks

## Cost Optimization

### AWS Cost Management
- Use Reserved Instances (save 40%)
- Auto-scaling (scale down at night)
- S3 lifecycle policies
- CloudWatch cost alerts
- Regular cost reviews

### Current Costs (Estimated)
- EC2 t2.medium: $36/month
- RDS db.t3.micro: $15/month
- ElastiCache: $13/month
- Data transfer: $5/month
- **Total: ~$70/month**

### With Optimization
- Spot instances: Save 70%
- Reserved instances: Save 40%
- Auto-scaling: Save 30%
- **Optimized: ~$35/month**

## Security Best Practices

### Infrastructure Security
- VPC with private subnets
- Security groups (firewall rules)
- SSL/TLS certificates (Let's Encrypt)
- WAF (Web Application Firewall)
- DDoS protection (CloudFlare)

### Application Security
- Rate limiting
- Input validation
- SQL injection prevention
- XSS protection
- CORS configuration
- JWT token expiration

### Access Control
- MFA for AWS console
- IAM roles (least privilege)
- SSH key rotation
- Audit logs enabled
- Regular security scans

## Monitoring Dashboards

### Key Metrics to Track
1. **Availability**: Uptime %
2. **Performance**: Response time
3. **Errors**: Error rate
4. **Traffic**: Requests/second
5. **Resources**: CPU, Memory, Disk

### Alert Thresholds
- Error rate > 1%: Warning
- Error rate > 5%: Critical
- Response time > 1s: Warning
- Response time > 3s: Critical
- Uptime < 99.9%: Critical

## Backup Strategy

### Automated Backups
- Database: Daily at 2 AM UTC
- Files: Weekly full backup
- Retention: 30 days
- Test restore: Monthly

### Backup Locations
- Primary: AWS S3
- Secondary: Different region
- Tertiary: Local backup (encrypted)

## Incident Response

### Severity Levels
- **P0 (Critical)**: Service down
- **P1 (High)**: Major feature broken
- **P2 (Medium)**: Minor issue
- **P3 (Low)**: Enhancement

### Response Times
- P0: Immediate (< 15 min)
- P1: < 1 hour
- P2: < 4 hours
- P3: Next sprint

### Incident Workflow
1. Detect issue (monitoring)
2. Alert team (Slack/PagerDuty)
3. Assess severity
4. Implement fix or rollback
5. Post-mortem analysis
6. Update runbooks

## Documentation Requirements

### Must Document
- Architecture diagrams
- Deployment procedures
- Rollback procedures
- Troubleshooting guides
- API documentation
- Environment variables
- Database schema

### Keep Updated
- README.md
- DEPLOYMENT.md
- API_DOCUMENTATION.md
- TROUBLESHOOTING.md

## Tools & Services

### Essential Tools
- **Git**: Version control
- **Docker**: Containerization
- **GitHub Actions**: CI/CD
- **AWS CLI**: Infrastructure management
- **Terraform**: Infrastructure as Code (future)

### Monitoring Tools
- **CloudWatch**: AWS monitoring
- **Sentry**: Error tracking
- **Uptime Robot**: Availability
- **New Relic**: APM (optional)

### Communication
- **Slack**: Team communication
- **PagerDuty**: On-call alerts
- **Jira**: Issue tracking

## Performance Optimization

### Backend Optimization
- Database query optimization
- Redis caching
- Connection pooling
- Gzip compression
- CDN for static assets

### Frontend Optimization
- Image optimization
- Lazy loading
- Code splitting
- Service workers
- PWA features

## Compliance & Governance

### Data Protection
- GDPR compliance
- Data encryption at rest
- Data encryption in transit
- Regular security audits
- Privacy policy

### Audit Trail
- All deployments logged
- Access logs retained
- Change management process
- Compliance reports

## Future Improvements

### Short-term (1-3 months)
- [ ] Set up GitHub Actions CI/CD
- [ ] Migrate to RDS (managed database)
- [ ] Add CloudWatch monitoring
- [ ] Implement automated backups
- [ ] Set up staging environment

### Medium-term (3-6 months)
- [ ] Add load balancer
- [ ] Implement auto-scaling
- [ ] Set up CDN
- [ ] Add error tracking (Sentry)
- [ ] Implement blue-green deployment

### Long-term (6-12 months)
- [ ] Multi-region deployment
- [ ] Kubernetes migration
- [ ] Infrastructure as Code (Terraform)
- [ ] Advanced monitoring (Prometheus/Grafana)
- [ ] Chaos engineering

## Learning Resources

### DevOps Fundamentals
- AWS Well-Architected Framework
- The Phoenix Project (book)
- Site Reliability Engineering (book)
- DevOps Handbook

### Certifications
- AWS Certified Solutions Architect
- AWS Certified DevOps Engineer
- Docker Certified Associate
- Kubernetes Administrator (CKA)
