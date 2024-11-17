#!/bin/bash
set -e

# Run Magento installation if php-fpm is being started
if [ "$1" = "php-fpm" ]; then
    install-magento
    exec php-fpm
else
    exec "$@"
fi
