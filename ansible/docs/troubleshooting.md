# Troubleshooting Guide

This guide helps you diagnose and resolve common issues with the DevSecOps environment.

## 🔍 General Troubleshooting

### Debug Mode

Run playbooks with verbose output:
```bash
# Basic verbose
ansible-playbook -i inventory/hosts.yml playbooks/site.yml -v

# More verbose (recommended for troubleshooting)
ansible-playbook -i inventory/hosts.yml playbooks/site.yml -vvv

# Maximum verbosity
ansible-playbook -i inventory/hosts.yml playbooks/site.yml -vvvv
```

### Check Connectivity

```bash
# Test basic connectivity
ansible -i inventory/hosts.yml devsecops -m ping

# Test with verbose output
ansible -i inventory/hosts.yml devsecops -m ping -vvv

# Test sudo access
ansible -i inventory/hosts.yml devsecops -m command -a "sudo whoami"
```

## 🐧 System-Level Issues

### SSH Connection Problems

**Problem:** SSH connection refused or timeout
```bash
# Test SSH directly
ssh -v ubuntu@<server-ip>

# Check SSH service on target
ansible -i inventory/hosts.yml devsecops -m command -a "systemctl status ssh"
```

**Solutions:**
1. Verify SSH service is running
2. Check firewall rules (port 22)
3. Verify SSH key permissions (600 for private key)
4. Check `/etc/ssh/sshd_config` for restrictions

### Permission Denied

**Problem:** "Permission denied" errors during execution
```bash
# Check sudo configuration
ansible -i inventory/hosts.yml devsecops -m command -a "sudo -l"

# Test privilege escalation
ansible -i inventory/hosts.yml devsecops -m command -a "whoami" --become
```

**Solutions:**
1. Add user to sudoers: `usermod -aG sudo ubuntu`
2. Configure passwordless sudo: `echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers`
3. Check sudo group membership: `groups ubuntu`

### Package Installation Failures

**Problem:** Package installation fails
```bash
# Check package manager
ansible -i inventory/hosts.yml devsecops -m command -a "apt update"

# Check repository configuration
ansible -i inventory/hosts.yml devsecops -m command -a "apt-cache policy"
```

**Solutions:**
1. Update package cache: `apt update`
2. Fix broken packages: `apt --fix-broken install`
3. Check disk space: `df -h`
4. Verify internet connectivity: `curl -I google.com`

## 🐳 Docker Issues

### Docker Installation Problems

**Problem:** Docker installation fails
```bash
# Check if Docker is running
ansible -i inventory/hosts.yml devsecops -m command -a "systemctl status docker"

# Check Docker version
ansible -i inventory/hosts.yml devsecops -m command -a "docker --version"
```

**Solutions:**
1. Remove old Docker versions first
2. Check system architecture compatibility
3. Verify GPG key installation
4. Check available disk space

### Docker Permission Issues

**Problem:** "Permission denied" when running Docker commands
```bash
# Check Docker group membership
ansible -i inventory/hosts.yml devsecops -m command -a "groups ubuntu"

# Test Docker access
ansible -i inventory/hosts.yml devsecops -m command -a "docker ps" --become-user ubuntu
```

**Solutions:**
1. Add user to docker group: `usermod -aG docker ubuntu`
2. Log out and log back in
3. Restart Docker service: `systemctl restart docker`
4. Use `newgrp docker` to apply group changes

### Docker Build Failures

**Problem:** Docker image build fails
```bash
# Check Docker daemon logs
ansible -i inventory/hosts.yml devsecops -m command -a "journalctl -u docker.service -n 50"

# Check available space
ansible -i inventory/hosts.yml devsecops -m command -a "docker system df"
```

**Solutions:**
1. Clean up Docker: `docker system prune -f`
2. Check Dockerfile syntax
3. Verify base image availability
4. Check network connectivity during build

## ☸️ Kubernetes/MicroK8s Issues

### MicroK8s Installation Problems

**Problem:** MicroK8s installation fails
```bash
# Check snap service
ansible -i inventory/hosts.yml devsecops -m command -a "systemctl status snapd"

# Check MicroK8s status
ansible -i inventory/hosts.yml devsecops -m command -a "microk8s status"
```

**Solutions:**
1. Ensure snapd is installed and running
2. Check available disk space (>20GB recommended)
3. Wait for snap to be ready: `snap wait system seed.loaded`
4. Restart snapd: `systemctl restart snapd`

### MicroK8s Not Ready

**Problem:** MicroK8s status shows "not ready"
```bash
# Check MicroK8s detailed status
ansible -i inventory/hosts.yml devsecops -m command -a "microk8s status --wait-ready --timeout 300"

# Check addon status
ansible -i inventory/hosts.yml devsecops -m command -a "microk8s kubectl get pods -A"
```

**Solutions:**
1. Wait for all pods to be running: `microk8s status --wait-ready`
2. Check system resources: `free -h && df -h`
3. Restart MicroK8s: `microk8s stop && microk8s start`
4. Check DNS resolution: `microk8s kubectl get pods -n kube-system`

### Pod Startup Issues

**Problem:** Pods stuck in pending/error state
```bash
# Check pod status
ansible -i inventory/hosts.yml devsecops -m command -a "microk8s kubectl get pods -A"

# Describe problematic pod
ansible -i inventory/hosts.yml devsecops -m command -a "microk8s kubectl describe pod <pod-name> -n <namespace>"

# Check pod logs
ansible -i inventory/hosts.yml devsecops -m command -a "microk8s kubectl logs <pod-name> -n <namespace>"
```

**Solutions:**
1. Check resource constraints: `kubectl top nodes`
2. Verify storage availability: `kubectl get pv,pvc -A`
3. Check image pull issues: `kubectl describe pod <pod-name>`
4. Verify node readiness: `kubectl get nodes`

### Storage Issues

**Problem:** PersistentVolume claims pending
```bash
# Check PV and PVC status
ansible -i inventory/hosts.yml devsecops -m command -a "microk8s kubectl get pv,pvc -A"

# Check storage class
ansible -i inventory/hosts.yml devsecops -m command -a "microk8s kubectl get storageclass"
```

**Solutions:**
1. Ensure storage addon is enabled: `microk8s enable storage`
2. Check available disk space on host
3. Verify hostpath provisioner: `kubectl get pods -n kube-system | grep hostpath`
4. Check PVC events: `kubectl describe pvc <pvc-name> -n <namespace>`

## 🚀 Service-Specific Issues

### Jenkins Issues

**Problem:** Jenkins pod not starting
```bash
# Check Jenkins pod status
ansible -i inventory/hosts.yml devsecops -m command -a "microk8s kubectl get pods -n jenkins"

# Check Jenkins logs
ansible -i inventory/hosts.yml devsecops -m command -a "microk8s kubectl logs -n jenkins -l app.kubernetes.io/instance=jenkins"
```

**Solutions:**
1. Check image pull status: `kubectl describe pod <jenkins-pod> -n jenkins`
2. Verify RBAC permissions
3. Check resource limits vs. available resources
4. Verify custom image build was successful

### SonarQube Issues

**Problem:** SonarQube not connecting to database
```bash
# Check SonarQube logs
ansible -i inventory/hosts.yml devsecops -m command -a "microk8s kubectl logs -n sonarqube -l app=sonarqube"

# Check PostgreSQL status
ansible -i inventory/hosts.yml devsecops -m command -a "microk8s kubectl get pods -n sonarqube -l app.kubernetes.io/name=postgresql"
```

**Solutions:**
1. Verify PostgreSQL is running and ready
2. Check database connection credentials
3. Verify network policies allow communication
4. Check database initialization logs

### Monitoring Stack Issues

**Problem:** Grafana can't connect to Loki
```bash
# Check Loki status
ansible -i inventory/hosts.yml devsecops -m command -a "microk8s kubectl get pods -n monitoring -l app.kubernetes.io/name=loki"

# Test Loki endpoint
ansible -i inventory/hosts.yml devsecops -m command -a "microk8s kubectl exec -n monitoring <grafana-pod> -- curl -I http://loki:3100/ready"
```

**Solutions:**
1. Verify Loki service is running: `kubectl get svc -n monitoring`
2. Check Loki logs for errors
3. Verify service discovery configuration
4. Test network connectivity between pods

## 🌐 Network and Access Issues

### Ingress Not Working

**Problem:** Services not accessible via ingress
```bash
# Check ingress status
ansible -i inventory/hosts.yml devsecops -m command -a "microk8s kubectl get ingress -A"

# Check ingress controller
ansible -i inventory/hosts.yml devsecops -m command -a "microk8s kubectl get pods -n ingress"
```

**Solutions:**
1. Ensure ingress addon is enabled: `microk8s enable ingress`
2. Check ingress controller logs
3. Verify DNS resolution or /etc/hosts entries
4. Check service endpoints: `kubectl get endpoints -A`

### LoadBalancer External IP Pending

**Problem:** LoadBalancer services stuck with pending external IP
```bash
# Check LoadBalancer services
ansible -i inventory/hosts.yml devsecops -m command -a "microk8s kubectl get svc -A | grep LoadBalancer"

# Check MetalLB status (if enabled)
ansible -i inventory/hosts.yml devsecops -m command -a "microk8s kubectl get pods -n metallb-system"
```

**Solutions:**
1. Enable MetalLB: `microk8s enable metallb`
2. Configure IP range for MetalLB
3. Use NodePort services as alternative
4. Check cloud provider LoadBalancer support

### DNS Resolution Issues

**Problem:** Pod-to-pod communication fails
```bash
# Check DNS pods
ansible -i inventory/hosts.yml devsecops -m command -a "microk8s kubectl get pods -n kube-system -l k8s-app=kube-dns"

# Test DNS resolution
ansible -i inventory/hosts.yml devsecops -m command -a "microk8s kubectl exec -n default <pod-name> -- nslookup kubernetes.default"
```

**Solutions:**
1. Ensure DNS addon is enabled: `microk8s enable dns`
2. Restart CoreDNS pods
3. Check DNS configuration: `kubectl get configmap coredns -n kube-system -o yaml`
4. Verify network policies don't block DNS

## 📊 Resource and Performance Issues

### Out of Memory

**Problem:** Pods getting OOMKilled
```bash
# Check resource usage
ansible -i inventory/hosts.yml devsecops -m command -a "microk8s kubectl top pods -A"

# Check node resources
ansible -i inventory/hosts.yml devsecops -m command -a "microk8s kubectl top nodes"

# Check pod resource limits
ansible -i inventory/hosts.yml devsecops -m command -a "microk8s kubectl describe pod <pod-name> -n <namespace>"
```

**Solutions:**
1. Increase memory limits in configuration
2. Add more RAM to the server
3. Optimize application memory usage
4. Scale down non-essential services

### Disk Space Issues

**Problem:** No space left on device
```bash
# Check disk usage
ansible -i inventory/hosts.yml devsecops -m command -a "df -h"

# Check Docker disk usage
ansible -i inventory/hosts.yml devsecops -m command -a "docker system df"

# Check large files
ansible -i inventory/hosts.yml devsecops -m command -a "du -sh /* 2>/dev/null | sort -hr | head -10"
```

**Solutions:**
1. Clean up Docker: `docker system prune -a`
2. Clean up logs: `journalctl --vacuum-time=1d`
3. Remove unused files and packages
4. Expand disk or add additional storage

## 🔧 Configuration Issues

### Variable Not Defined

**Problem:** Ansible fails with undefined variable
```bash
# Check variable definition
ansible -i inventory/hosts.yml devsecops -m debug -a "var=undefined_variable"

# List all variables for host
ansible -i inventory/hosts.yml devsecops -m debug -a "var=hostvars[inventory_hostname]"
```

**Solutions:**
1. Define missing variables in group_vars or host_vars
2. Use default filters: `{{ variable_name | default('default_value') }}`
3. Check variable scope and inheritance
4. Verify variable file syntax (YAML)

### Template Rendering Issues

**Problem:** Jinja2 template errors
```bash
# Test template syntax locally
ansible -i inventory/hosts.yml devsecops -m template -a "src=template.j2 dest=/tmp/test"

# Check template variables
ansible -i inventory/hosts.yml devsecops -m debug -a "var=template_variables"
```

**Solutions:**
1. Validate Jinja2 syntax
2. Check variable names and types
3. Use debug module to inspect variables
4. Test templates with simple values first

## 🆘 Emergency Procedures

### Complete System Recovery

**If the entire system is broken:**

1. **Stop all services:**
   ```bash
   ansible-playbook -i inventory/hosts.yml playbooks/cleanup.yml --tags all
   ```

2. **Reset MicroK8s:**
   ```bash
   ansible -i inventory/hosts.yml devsecops -m command -a "microk8s reset --destructive"
   ```

3. **Clean Docker:**
   ```bash
   ansible -i inventory/hosts.yml devsecops -m command -a "docker system prune -a --volumes"
   ```

4. **Redeploy from scratch:**
   ```bash
   ansible-playbook -i inventory/hosts.yml playbooks/site.yml
   ```

### Backup and Restore

**Create backup:**
```bash
# Backup configurations
ansible -i inventory/hosts.yml devsecops -m command -a "microk8s kubectl get all -A -o yaml" > backup.yaml

# Backup persistent volumes
ansible -i inventory/hosts.yml devsecops -m command -a "tar -czf /tmp/pv-backup.tar.gz /var/snap/microk8s/common/default-storage/"
```

**Restore from backup:**
```bash
# Restore configurations
ansible -i inventory/hosts.yml devsecops -m shell -a "microk8s kubectl apply -f backup.yaml"

# Restore persistent volumes (if needed)
ansible -i inventory/hosts.yml devsecops -m unarchive -a "src=/tmp/pv-backup.tar.gz dest=/ remote_src=yes"
```

## 📞 Getting Help

### Log Collection

Before seeking help, collect relevant logs:

```bash
# System logs
ansible -i inventory/hosts.yml devsecops -m command -a "journalctl -n 100 --no-pager" > system.log

# Ansible logs (run with -vvv)
ansible-playbook -i inventory/hosts.yml playbooks/site.yml -vvv > ansible.log 2>&1

# Kubernetes logs
ansible -i inventory/hosts.yml devsecops -m command -a "microk8s kubectl get events -A --sort-by='.lastTimestamp'" > k8s-events.log

# Service logs
ansible -i inventory/hosts.yml devsecops -m command -a "microk8s kubectl logs -n jenkins -l app.kubernetes.io/instance=jenkins" > jenkins.log
```

### Information to Include

When reporting issues, include:

1. **Environment details:** OS version, hardware specs, network setup
2. **Ansible version:** `ansible --version`
3. **Error messages:** Complete error output with -vvv
4. **System status:** Output of diagnostic commands
5. **Configuration:** Relevant parts of your configuration files
6. **Steps to reproduce:** What you were trying to do when the error occurred

### Community Resources

- Check existing issues in project repository
- Search community forums and Stack Overflow
- Review official documentation
- Join project Discord/Slack channels

### Professional Support

For production environments:
- Consider commercial support options
- Engage DevOps consultants
- Use managed Kubernetes services
- Implement proper monitoring and alerting
