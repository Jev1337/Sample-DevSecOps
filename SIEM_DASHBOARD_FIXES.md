# SIEM Dashboard Query Fixes

## Issues and Solutions

### 1. SSH Invalid User Attempts - No Data

**Problem**: Dashboard expects `event_type="ssh_invalid_user"` but logs may not have this label.

**Solution**: Update the query to be more flexible:
```
{job="system-auth"} |~ "(?i)(invalid user|disconnected.*invalid)" | json | event_type="ssh_invalid_user" or {job="system-auth"} |~ "(?i)invalid user (?P<invalid_user>\\S+) from (?P<source_ip>[0-9.]+)"
```

### 2. Sudo Usage - No Data

**Problem**: Dashboard expects `event_type="sudo_usage"` but system logs may not be properly parsed.

**Solution**: Use regex to extract from raw log lines:
```
{job="system-auth"} |~ "sudo:" | regex "sudo: (?P<sudo_user>\\S+) : TTY=(?P<tty>\\S+) ; PWD=(?P<pwd>\\S+) ; USER=(?P<target_user>\\S+) ; COMMAND=(?P<command>.*)"
```

### 3. Package Installation - No Data

**Problem**: Dashboard expects `job="package-install"` but these logs might not exist.

**Solution**: Use multiple sources:
```
{job=~"package-install|apt-history"} or {job="system-auth"} |~ "(?i)(install|upgrade|remove).*(package|apt|dpkg)"
```

### 4. GitHub Webhook Events - Minimal Data

**Problem**: Webhook logs show minimal information.

**Solution**: Updated webhook handler extracts:
- Repository information
- Actor/user details
- Event-specific data (PR, issues, workflows)
- Security-relevant flags

### 5. User Activity Summary - No Data

**Problem**: Query expects specific event types that may not exist.

**Solution**: Use broader pattern matching:
```
{job="system-auth"} |~ "(?i)(sudo|session opened|successful|accepted)" | json
```

## Updated Query Examples

### SSH Invalid Users (Fixed):
```
{job="system-auth"} |~ "(?i)invalid user" | json | line_format "{{.__timestamp__}} | Invalid User: {{.invalid_user | default \"unknown\"}} from IP: {{.source_ip | default \"unknown\"}} | {{.__line__}}"
```

### Top Failed Login Sources (Fixed):
```
topk(10, sum by (source_ip) (count_over_time({job="system-auth"} |~ "(?i)(invalid user|failed password|authentication failure)" | json | unwrap source_ip [1h])))
```

### Sudo Usage (Fixed):
```
{job="system-auth"} |~ "sudo:" | regex "sudo: (?P<sudo_user>\\S+) : TTY=(?P<tty>\\S+) ; PWD=(?P<pwd>\\S+) ; USER=(?P<target_user>\\S+) ; COMMAND=(?P<command>.*)" | line_format "{{.__timestamp__}} | User: {{.sudo_user}} → {{.target_user}} | Command: {{.command}} | TTY: {{.tty}}"
```

### Package Installation (Fixed):
```
{job=~"package-install|apt-history|system-auth"} |~ "(?i)(install|upgrade|remove)" | json | line_format "{{.__timestamp__}} | {{.action | default \"package-action\"}}: {{.package | default \"unknown\"}} ({{.old_version | default \"N/A\"}} → {{.new_version | default \"N/A\"}})"
```

### GitHub Webhook Events (Enhanced):
```
{job="webhook-receiver"} | json | line_format "{{.__timestamp__}} | Event: {{.event_type}} | Source: {{.source}} | Repository: {{.repository | default \"N/A\"}} | Actor: {{.actor | default \"N/A\"}} | Level: {{.level}} | {{if .pr_action}}PR: {{.pr_action}} | {{end}}{{if .issue_action}}Issue: {{.issue_action}} | {{end}}{{if .workflow_status}}Workflow: {{.workflow_name}} ({{.workflow_status}}) | {{end}}{{.message}}"
```

### User Activity Summary (Fixed):
```
sum by (sudo_user, event_type) (count_over_time({job="system-auth"} |~ "(?i)(sudo|session opened)" | json | label_format event_type="{{if .sudo_user}}sudo_usage{{else}}successful_login{{end}}" [1h]))
```
