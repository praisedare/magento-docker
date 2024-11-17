#!/bin/bash
set -e

# Create required directories with proper ownership
mkdir -p \
    var/cache \
    var/page_cache \
    var/log \
    var/report \
    var/session \
    var/tmp \
    pub/static \
    pub/media \
    generated

# Set proper ownership - root:www-data allows both root and www-data to work with files
chown -R root:www-data .
chmod -R g+w \
    var \
    pub/static \
    pub/media \
    generated \
    app/etc

echo "Waiting for MySQL to be ready..."
until mysql -h db -u magento -pmagento magento -e "SELECT 1"; do
    sleep 1
done

echo "Waiting for Elasticsearch to be ready..."
until curl -s "http://elasticsearch:9200/_cluster/health" > /dev/null; do
    sleep 1
done

if [ ! -f app/etc/env.php ]; then
    bin/magento setup:install \
        --base-url=http://localhost \
        --db-host=db \
        --db-name=magento \
        --db-user=magento \
        --db-password=magento \
        --admin-firstname=Admin \
        --admin-lastname=User \
        --admin-email=admin@example.com \
        --admin-user=admin \
        --admin-password=admin123 \
        --language=en_US \
        --currency=USD \
        --timezone=America/New_York \
        --use-rewrites=1 \
        --search-engine=elasticsearch7 \
        --elasticsearch-host=elasticsearch \
        --elasticsearch-port=9200 \
        --cache-backend=redis \
        --cache-backend-redis-server=redis \
        --cache-backend-redis-port=6379 \
        --session-save=redis \
        --session-save-redis-host=redis \
        --session-save-redis-port=6379 \
        --session-save-redis-db=2 \
        --cleanup-database

    bin/magento config:set web/secure/use_in_frontend 0
    bin/magento config:set web/secure/use_in_adminhtml 0
    
    bin/magento deploy:mode:set developer
    bin/magento indexer:reindex
    bin/magento cache:flush

    # Setup cron after successful installation
    setup-cron
fi

php bin/magento setup:di:compile

chown -R www-data:www-data .

echo "Magento installation completed"
