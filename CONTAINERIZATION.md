# Containerization Strategy

This document outlines the containerization strategy for the project.

## To Be Containerized

The following components are containerized to ensure they run in isolated, reproducible environments with all their dependencies.

-   **Flask Application**: The core Python application is containerized using a `Dockerfile`. This packages the application code, Python interpreter, and all required libraries.
-   **Jenkins**: The Jenkins server itself will be run as a container within the Kubernetes cluster. This simplifies its management, scaling, and configuration.
-   **SonarQube**: The SonarQube server for static code analysis is deployed as a Docker container, as recommended by SonarSource.
-   **Monitoring Stack (Grafana & Loki)**: Both Grafana (for visualization) and Loki (for log aggregation) are run as containers within the `monitoring` namespace in Kubernetes. This is a standard practice for deploying such services.

## Not To Be Containerized

The following components are part of the deployment and configuration infrastructure and are not containerized themselves.

-   **Kubernetes Manifests (`k8s/`, `helm/`)**: These YAML files define the desired state of the application and infrastructure in Kubernetes. They are used by `kubectl` and `helm` to create and manage the containerized services.
-   **Configuration Files (`monitoring/`, `security/`)**: These files configure the services running in containers (e.g., Grafana dashboards, Alloy configuration, SonarQube properties). They are mounted into the containers, often via ConfigMaps.
-   **CI/CD Pipeline Definition (`Jenkinsfile`)**: This file contains the code that defines the CI/CD pipeline. It is read by the Jenkins master to execute the pipeline stages.
-   **Setup & Helper Scripts (`setup.sh`)**: These are shell scripts used for bootstrapping the local development environment or performing administrative tasks. They are executed on the host machine.
-   **Documentation (`.md` files)**: All Markdown files are for documentation purposes and are not part of the application runtime.
