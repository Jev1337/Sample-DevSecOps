FROM jenkins/jenkins:2.504.3-lts

# Switch to root to install packages
USER root

# Install system dependencies
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    python3 \
    python3-pip \
    python3-venv \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Create symlink for python command
RUN ln -s /usr/bin/python3 /usr/bin/python

# Install Docker CLI
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/

# Install Helm
RUN curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list \
    && apt-get update \
    && apt-get install -y helm \
    && rm -rf /var/lib/apt/lists/*

# Install Trivy
RUN wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | tee /usr/share/keyrings/trivy.gpg > /dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee -a /etc/apt/sources.list.d/trivy.list \
    && apt-get update \
    && apt-get install -y trivy \
    && rm -rf /var/lib/apt/lists/*

# Install SonarQube Scanner
RUN wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip \
    && unzip sonar-scanner-cli-5.0.1.3006-linux.zip -d /opt/ \
    && rm sonar-scanner-cli-5.0.1.3006-linux.zip \
    && ln -s /opt/sonar-scanner-5.0.1.3006-linux/bin/sonar-scanner /usr/local/bin/sonar-scanner

# Install common Python packages (using --break-system-packages for Docker container)
RUN pip3 install --no-cache-dir --break-system-packages \
    pytest \
    pytest-cov \
    flask \
    requests \
    coverage

# Step 1: Create Docker Group (following Docker post-installation steps)
# https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user
ARG DOCKER_GID=999
RUN groupadd -g ${DOCKER_GID} docker || true

# Step 2: Add jenkins user to the docker group
RUN usermod -aG docker jenkins

# Verify the group membership for debugging
RUN echo "Jenkins user groups:" && id jenkins

# Create a script to fix docker socket permissions at runtime if needed
RUN echo '#!/bin/bash\n# Fix docker socket permissions\nif [ -S /var/run/docker.sock ]; then\n  chown root:docker /var/run/docker.sock\n  chmod 660 /var/run/docker.sock\nfi\nexec "$@"' > /usr/local/bin/docker-entrypoint.sh \
    && chmod +x /usr/local/bin/docker-entrypoint.sh

# Switch back to jenkins user
USER jenkins

# Install Jenkins plugins
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt

# Set environment variables
ENV SONAR_RUNNER_HOME=/opt/sonar-scanner-5.0.1.3006-linux
ENV PATH=$PATH:$SONAR_RUNNER_HOME/bin
