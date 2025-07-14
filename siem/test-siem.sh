#!/bin/bash

# SIEM Test Script
# This script tests the SIEM functionality by generating security events

echo "🧪 SIEM Test Script"
echo "==================="
echo ""

# Function to generate SSH failed login attempts (simulated)
test_ssh_failures() {
    echo "📋 Testing SSH failure detection..."
    
    # Log simulated SSH failures to auth log
    for i in {1..5}; do
        logger -p auth.info -t sshd "Failed password for invalid user test$i from 10.10.10.$i port 22 ssh2"
        echo "  - Simulated failed login: user test$i from 10.10.10.$i"
    done
    
    echo "✅ Simulated SSH failures logged"
}

# Function to test system file modifications (simulated)
test_file_modifications() {
    echo "📋 Testing system file modification detection..."
    
    # Create test file
    local testfile="/tmp/siem-test-file.txt"
    echo "Test content" > "$testfile"
    
    # Log simulated file modification events
    logger -p auth.info -t audit "type=PATH msg=audit($(date +%s).$(shuf -i 100-999 -n 1):$(shuf -i 1000-9999 -n 1)): item=0 name=\"/etc/passwd\" inode=12345 dev=ca:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=unconfined_u:object_r:passwd_file_t:s0 objtype=NORMAL cap_fp=0 cap_fi=0 cap_fe=0 cap_fver=0 type=CWD msg=audit($(date +%s).$(shuf -i 100-999 -n 1):$(shuf -i 1000-9999 -n 1)): cwd=\"/root\" type=SYSCALL msg=audit($(date +%s).$(shuf -i 100-999 -n 1):$(shuf -i 1000-9999 -n 1)): arch=x86_64 syscall=open success=yes exit=3 a0=0x7fff98552264 a1=O_WRONLY|O_CREAT a2=0644 a3=0x0 items=1 ppid=12345 pid=12346 auid=0 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=tty1 ses=1 comm=\"nano\" exe=\"/usr/bin/nano\" subj=unconfined_u:unconfined_r:unconfined_t:s0 key=\"passwd_changes\""
    logger -p auth.info -t audit "type=PATH msg=audit($(date +%s).$(shuf -i 100-999 -n 1):$(shuf -i 1000-9999 -n 1)): item=0 name=\"/etc/shadow\" inode=12346 dev=ca:01 mode=0100600 ouid=0 ogid=0 rdev=00:00 obj=unconfined_u:object_r:shadow_t:s0 objtype=NORMAL cap_fp=0 cap_fi=0 cap_fe=0 cap_fver=0 type=CWD msg=audit($(date +%s).$(shuf -i 100-999 -n 1):$(shuf -i 1000-9999 -n 1)): cwd=\"/root\" type=SYSCALL msg=audit($(date +%s).$(shuf -i 100-999 -n 1):$(shuf -i 1000-9999 -n 1)): arch=x86_64 syscall=open success=yes exit=3 a0=0x7fff98552264 a1=O_WRONLY a2=0600 a3=0x0 items=1 ppid=12345 pid=12346 auid=0 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=tty1 ses=1 comm=\"nano\" exe=\"/usr/bin/nano\" subj=unconfined_u:unconfined_r:unconfined_t:s0 key=\"shadow_changes\""
    
    echo "✅ Simulated system file modifications logged"
}

# Function to test package management activities (simulated)
test_package_activities() {
    echo "📋 Testing package management detection..."
    
    # Log simulated package installation/update events
    logger -p daemon.notice -t dpkg "installed nginx package"
    logger -p daemon.notice -t apt "Unpacking nginx (1.18.0-6ubuntu14.4) ..."
    logger -p daemon.notice -t apt "Setting up nginx (1.18.0-6ubuntu14.4) ..."
    
    echo "✅ Simulated package management activities logged"
}

# Function to test privilege escalation (simulated)
test_privilege_escalation() {
    echo "📋 Testing privilege escalation detection..."
    
    # Log simulated sudo events
    logger -p auth.notice -t sudo "testuser : TTY=pts/0 ; PWD=/home/testuser ; USER=root ; COMMAND=/bin/bash"
    logger -p auth.notice -t sudo "pam_unix(sudo:session): session opened for user root(uid=0) by testuser(uid=1000)"
    
    echo "✅ Simulated privilege escalation events logged"
}

# Function to test webhook activity (real HTTP request)
test_webhook_activity() {
    echo "📋 Testing webhook endpoint..."
    
    # Get external IP
    EXTERNAL_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || curl -s icanhazip.com)
    
    # Create test payload
    cat > /tmp/webhook-payload.json << EOF
{
  "repository": {
    "name": "sample-devsecops",
    "full_name": "test-user/sample-devsecops"
  },
  "sender": {
    "login": "test-user"
  },
  "commits": [
    {
      "id": "abc1234567890",
      "message": "Test commit for SIEM",
      "timestamp": "$(date -Iseconds)",
      "author": {
        "name": "Test User",
        "email": "test@example.com"
      },
      "added": ["test.txt"],
      "modified": ["app.py"],
      "removed": []
    }
  ]
}
EOF
    
    # Send test webhook request
    if ! command -v curl &> /dev/null; then
        echo "❌ curl is not installed. Skipping webhook test."
    else
        echo "  - Sending test webhook to http://webhook.$EXTERNAL_IP.nip.io/webhook"
        curl -s -X POST -H "Content-Type: application/json" -H "X-GitHub-Event: push" -H "X-GitHub-Delivery: $(date +%s)" -d @/tmp/webhook-payload.json "http://webhook.$EXTERNAL_IP.nip.io/webhook" || echo "  - Failed to connect to webhook endpoint (this is normal if you're running locally without external access)"
    fi
    
    echo "✅ Webhook test completed"
}

# Main test function
run_siem_tests() {
    echo "🚀 Running SIEM tests..."
    echo ""
    
    test_ssh_failures
    echo ""
    
    test_file_modifications
    echo ""
    
    test_package_activities
    echo ""
    
    test_privilege_escalation
    echo ""
    
    test_webhook_activity
    echo ""
    
    echo "✅ All SIEM tests completed"
    echo ""
    echo "🔍 Check the SIEM dashboard in Grafana to see these events"
    echo "   URL: http://grafana.EXTERNAL_IP.nip.io or http://grafana.local"
    echo "   Dashboard: SIEM Dashboard"
}

# Run the tests
run_siem_tests
