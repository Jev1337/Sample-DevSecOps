# DevSecOps Ansible Automation

This directory contains Ansible playbooks to automate the setup of the DevSecOps environment described in the parent directory's README.

## Prerequisites

- Ansible 2.10+
- Python 3

## Installation

1.  Install Ansible. On an Ubuntu/Debian system, you can do this with:

    ```bash
    sudo apt update
    sudo apt install software-properties-common
    sudo add-apt-repository --yes --update ppa:ansible/ansible
    sudo apt install ansible
    ```

2.  Install the required Ansible collections for Docker and Kubernetes:

    ```bash
    ansible-galaxy collection install community.docker
    ansible-galaxy collection install kubernetes.core
    ```

## How to Run

To execute the full setup, run the main playbook from the root of the `Sample-DevSecOps` project:

```bash
ansible-playbook -i ansible/inventory.yml ansible/playbook.yml
```

This will:

1.  Check and install prerequisites (Docker, Snap).
2.  Install and configure MicroK8s.
3.  Build the custom Jenkins image.
4.  Deploy core services (Jenkins, SonarQube).
5.  Deploy the monitoring stack (Loki, Grafana, Alloy).
6.  Build and deploy the sample Flask application.

The playbook is designed to be idempotent, meaning you can run it multiple times without causing issues.
