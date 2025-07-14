#!/usr/bin/env python3
"""
SIEM Sample Data Generator
Generates realistic security log data for testing the SIEM dashboard
"""

import json
import random
import time
import logging
import requests
from datetime import datetime, timezone, timedelta
from threading import Thread
import os
import sys

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Loki endpoint
LOKI_URL = os.getenv('LOKI_URL', 'http://localhost:3100/loki/api/v1/push')

class SIEMDataGenerator:
    def __init__(self):
        self.suspicious_ips = [
            "192.168.1.100", "10.0.0.5", "172.16.0.10", 
            "203.0.113.10", "198.51.100.5", "192.0.2.15"
        ]
        self.usernames = ["admin", "root", "user", "test", "guest", "oracle", "postgres"]
        self.invalid_usernames = ["hacker", "exploit", "admin123", "test123", "backdoor"]
        self.packages = ["nginx", "apache2", "mysql-server", "postgresql", "redis-server", "docker.io"]
        self.commands = [
            "/bin/bash", "apt update", "systemctl restart nginx", 
            "cat /etc/passwd", "ls -la /home", "ps aux"
        ]
        
    def send_to_loki(self, log_entry, labels):
        """Send log entry to Loki"""
        try:
            timestamp_ns = str(int(datetime.now(timezone.utc).timestamp() * 1000000000))
            
            loki_payload = {
                "streams": [
                    {
                        "stream": labels,
                        "values": [
                            [timestamp_ns, json.dumps(log_entry) if isinstance(log_entry, dict) else log_entry]
                        ]
                    }
                ]
            }
            
            response = requests.post(LOKI_URL, json=loki_payload, timeout=5)
            response.raise_for_status()
            logger.info("Successfully sent log to Loki")
            
        except Exception as e:
            logger.error(f"Failed to send log to Loki: {e}")

    def generate_ssh_invalid_user_attempts(self):
        """Generate SSH invalid user attempt logs"""
        while True:
            try:
                invalid_user = random.choice(self.invalid_usernames)
                source_ip = random.choice(self.suspicious_ips)
                timestamp = datetime.now(timezone.utc).isoformat()
                
                log_entry = {
                    "timestamp": timestamp,
                    "message": f"Disconnected from invalid user {invalid_user} {source_ip} port 22 [preauth]",
                    "invalid_user": invalid_user,
                    "source_ip": source_ip,
                    "event_type": "ssh_invalid_user",
                    "level": "warning"
                }
                
                labels = {
                    "job": "system-auth",
                    "event_type": "ssh_invalid_user",
                    "level": "warning",
                    "source_ip": source_ip,
                    "invalid_user": invalid_user
                }
                
                self.send_to_loki(log_entry, labels)
                logger.info(f"Generated SSH invalid user attempt: {invalid_user} from {source_ip}")
                
                # Random interval between 30-120 seconds
                time.sleep(random.randint(30, 120))
                
            except Exception as e:
                logger.error(f"Error generating SSH invalid user data: {e}")
                time.sleep(30)

    def generate_sudo_usage(self):
        """Generate sudo usage logs"""
        while True:
            try:
                sudo_user = random.choice(self.usernames)
                target_user = "root" if random.random() > 0.3 else random.choice(self.usernames)
                command = random.choice(self.commands)
                tty = f"pts/{random.randint(0, 5)}"
                timestamp = datetime.now(timezone.utc).isoformat()
                
                log_entry = {
                    "timestamp": timestamp,
                    "message": f"sudo: {sudo_user} : TTY={tty} ; PWD=/home/{sudo_user} ; USER={target_user} ; COMMAND={command}",
                    "sudo_user": sudo_user,
                    "target_user": target_user,
                    "command": command,
                    "tty": tty,
                    "event_type": "sudo_usage",
                    "level": "info"
                }
                
                labels = {
                    "job": "system-auth",
                    "event_type": "sudo_usage",
                    "level": "info",
                    "sudo_user": sudo_user,
                    "target_user": target_user
                }
                
                self.send_to_loki(log_entry, labels)
                logger.info(f"Generated sudo usage: {sudo_user} -> {target_user} command: {command}")
                
                # Random interval between 60-300 seconds
                time.sleep(random.randint(60, 300))
                
            except Exception as e:
                logger.error(f"Error generating sudo usage data: {e}")
                time.sleep(30)

    def generate_package_installation(self):
        """Generate package installation logs"""
        while True:
            try:
                package = random.choice(self.packages)
                action = random.choice(["install", "upgrade", "remove"])
                old_version = f"{random.randint(1, 5)}.{random.randint(0, 9)}.{random.randint(0, 9)}"
                new_version = f"{random.randint(1, 5)}.{random.randint(0, 9)}.{random.randint(0, 9)}"
                timestamp = datetime.now(timezone.utc).isoformat()
                
                log_entry = {
                    "timestamp": timestamp,
                    "action": action,
                    "package": package,
                    "old_version": old_version,
                    "new_version": new_version,
                    "event_type": "package_change",
                    "level": "info"
                }
                
                labels = {
                    "job": "package-install",
                    "event_type": "package_change",
                    "level": "info",
                    "package": package,
                    "action": action
                }
                
                self.send_to_loki(log_entry, labels)
                logger.info(f"Generated package activity: {action} {package} {old_version} -> {new_version}")
                
                # Random interval between 300-900 seconds (5-15 minutes)
                time.sleep(random.randint(300, 900))
                
            except Exception as e:
                logger.error(f"Error generating package installation data: {e}")
                time.sleep(30)

    def generate_successful_logins(self):
        """Generate successful login logs"""
        while True:
            try:
                user = random.choice(self.usernames)
                source_ip = random.choice(self.suspicious_ips)
                timestamp = datetime.now(timezone.utc).isoformat()
                
                log_entry = {
                    "timestamp": timestamp,
                    "message": f"session opened for user {user} by (uid=0)",
                    "user": user,
                    "source_ip": source_ip,
                    "event_type": "successful_login",
                    "level": "info"
                }
                
                labels = {
                    "job": "system-auth",
                    "event_type": "successful_login",
                    "level": "info",
                    "user": user,
                    "source_ip": source_ip
                }
                
                self.send_to_loki(log_entry, labels)
                logger.info(f"Generated successful login: {user} from {source_ip}")
                
                # Random interval between 120-600 seconds
                time.sleep(random.randint(120, 600))
                
            except Exception as e:
                logger.error(f"Error generating successful login data: {e}")
                time.sleep(30)

    def run(self):
        """Start all data generators"""
        logger.info("Starting SIEM sample data generators...")
        
        # Start all generators in separate threads
        threads = [
            Thread(target=self.generate_ssh_invalid_user_attempts, daemon=True),
            Thread(target=self.generate_sudo_usage, daemon=True),
            Thread(target=self.generate_package_installation, daemon=True),
            Thread(target=self.generate_successful_logins, daemon=True)
        ]
        
        for thread in threads:
            thread.start()
            time.sleep(1)  # Stagger starts
        
        logger.info("All SIEM data generators started. Press Ctrl+C to stop.")
        
        try:
            while True:
                time.sleep(60)  # Keep main thread alive
        except KeyboardInterrupt:
            logger.info("Stopping SIEM data generators...")
            sys.exit(0)

if __name__ == "__main__":
    generator = SIEMDataGenerator()
    generator.run()
