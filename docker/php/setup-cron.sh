#!/bin/bash
set -e

# Only setup cron if Magento is installed
if [ -f app/etc/env.php ]; then
    echo "Setting up Magento cron jobs..."
    
    # Copy cron template to active location
    cp /etc/cron.d/magento.template /etc/cron.d/magento
    
    # Install crontab for www-data user
    crontab -u www-data /etc/cron.d/magento
    
    # Start cron service
    service cron start
    
    echo "Magento cron jobs have been set up"
else
    echo "Magento is not installed yet. Skipping cron setup."
fi
