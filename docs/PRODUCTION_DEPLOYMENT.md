# Production Deployment Guide for ShaydZ AVMo

This document outlines the steps required to deploy ShaydZ AVMo to a production environment.

## 1. Infrastructure Requirements

### Backend Infrastructure
- Kubernetes cluster (EKS, AKS, or GKE recommended)
- MongoDB instance (Atlas, Cosmos DB, or self-hosted)
- Redis for caching (optional)
- Object storage (S3, Azure Blob, or GCS) for app binaries and VM images
- Load balancer with SSL termination
- DNS with proper SSL certificates

### VM Infrastructure
- Physical or virtual servers capable of running VMs or containers
- Hardware with virtualization support (for VM orchestrator nodes)
- High bandwidth network connectivity
- Storage optimized for VM images

## 2. Backend Setup

### 2.1 Environment Configuration

Create production environment configuration files for each service:

```bash
# Create .env.production files for each service
cp backend/api-gateway/.env.example backend/api-gateway/.env.production
cp backend/auth-service/.env.example backend/auth-service/.env.production
cp backend/app-catalog/.env.example backend/app-catalog/.env.production
cp backend/vm-orchestrator/.env.example backend/vm-orchestrator/.env.production
```

Edit each `.env.production` file with appropriate production values:

- Generate strong JWT secret keys
- Configure secure database connection strings with authentication
- Set appropriate logging levels
- Configure proper service URLs

### 2.2 Docker Compose for Production

Create a production Docker Compose file:

```bash
cp docker-compose.yml docker-compose.production.yml
```

Edit `docker-compose.production.yml`:
- Remove development-specific settings
- Add production environment variables
- Configure proper logging
- Set resource limits
- Remove exposed ports except as needed
- Configure proper restart policies

### 2.3 Kubernetes Deployment (Recommended)

Convert the Docker Compose configuration to Kubernetes manifests:

```bash
# Install kompose tool
# Then convert compose file to k8s resources
kompose convert -f docker-compose.production.yml
```

Enhance the generated Kubernetes manifests:
- Add proper resource requests/limits
- Configure horizontal pod autoscaling
- Set up proper liveness/readiness probes
- Configure persistent volume claims
- Set up ingress resources with TLS

## 3. Database Setup

### 3.1 MongoDB Configuration

- Set up MongoDB with proper authentication
- Create separate databases for each service
- Configure users with least privilege access
- Enable database auditing
- Set up regular backups
- Configure proper indexes for performance

### 3.2 Initial Data Migration

Create and run database migration scripts:

```bash
# Example migration script execution
node backend/scripts/init-db.js --env=production
```

## 4. iOS Client Configuration

### 4.1 Update API Configuration

Update `APIConfig.swift` with production endpoints:

```swift
import Foundation

/// Central place to manage API configuration
struct APIConfig {
    #if DEBUG
    static let baseURL = "http://localhost:8080/api"
    #else
    static let baseURL = "https://api.shaydz-avmo.io/api"
    #endif
    
    // Other configurations...
}
```

### 4.2 Build Configuration

- Create production signing certificates
- Configure App Store Connect settings
- Update app version and build number
- Configure proper entitlements
- Disable debug features

### 4.3 Distribution

- Archive the app with production configuration
- Submit to App Store or distribute via enterprise distribution

## 5. Security Considerations

### 5.1 Secrets Management

- Use a secrets management solution (Vault, AWS Secrets Manager, etc.)
- Avoid hardcoded secrets in code or Docker images
- Implement secret rotation policies

### 5.2 Network Security

- Implement proper network policies
- Configure firewalls to restrict access
- Use SSL/TLS for all connections
- Implement API gateway rate limiting

### 5.3 Authentication & Authorization

- Implement proper token-based authentication
- Set appropriate token expiration policies
- Configure role-based access control (RBAC)
- Implement multi-factor authentication for admin access

## 6. Monitoring and Logging

### 6.1 Logging Configuration

- Configure structured logging for all services
- Set up a centralized logging solution (ELK Stack, Loki, etc.)
- Implement log rotation and retention policies

### 6.2 Monitoring Setup

- Deploy Prometheus for metrics collection
- Configure Grafana dashboards for visualization
- Set up alerts for critical metrics
- Monitor API performance and error rates

### 6.3 Health Checks

- Implement service health endpoints
- Configure uptime monitoring
- Set up status page for service availability

## 7. CI/CD Pipeline

### 7.1 Continuous Integration

- Set up automated testing for all components
- Configure code quality checks
- Implement security scanning

### 7.2 Continuous Deployment

- Set up automated deployment pipelines
- Configure blue/green deployment strategy
- Implement rollback procedures

## 8. VM Orchestrator Configuration

### 8.1 VM Image Preparation

- Create secure baseline VM images
- Implement proper image versioning
- Configure automated security updates

### 8.2 Resource Allocation

- Configure proper CPU, memory, and storage allocation
- Implement auto-scaling policies
- Set up resource quotas per user/organization

## 9. Scaling Strategy

### 9.1 Horizontal Scaling

- Configure auto-scaling for all services
- Implement proper load balancing
- Design for stateless operation where possible

### 9.2 Database Scaling

- Configure MongoDB replication
- Implement database sharding if needed
- Set up read replicas for improved performance

## 10. Backup and Disaster Recovery

### 10.1 Backup Configuration

- Set up regular automated backups for all data
- Configure backup retention policies
- Validate backup integrity regularly

### 10.2 Disaster Recovery Plan

- Document recovery procedures
- Set up failover mechanisms
- Configure geo-redundant storage where appropriate
- Define RPO (Recovery Point Objective) and RTO (Recovery Time Objective)

## 11. Production Checklist

Before going live:

- [ ] Perform security audit
- [ ] Complete performance testing
- [ ] Validate all backups and recovery procedures
- [ ] Verify scaling capabilities
- [ ] Conduct user acceptance testing
- [ ] Document incident response procedures
- [ ] Prepare monitoring dashboards
- [ ] Configure alerting systems
- [ ] Train support staff
- [ ] Perform dry run of deployment process
