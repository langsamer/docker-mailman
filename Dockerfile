FROM debian:jessie

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y nginx mailman postfix supervisor fcgiwrap multiwatch busybox-syslogd locales

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y mg

RUN rm -rf /var/lib/apt/lists/* && \
    # Configure Nginx
    sed -i -e 's@worker_processes 4@worker_processes 1@g' /etc/nginx/nginx.conf && \
    rm -f /etc/nginx/sites-enabled/default

ADD nginx.conf /etc/nginx/conf.d/

# Required only if volume /etc/mailman not defined or not mapped; use host file system otherwise
ADD templates/de/* /etc/mailman/de/

# Configure Mailman
RUN sed -i -e "s@^DEFAULT_URL_PATTERN.*@DEFAULT_URL_PATTERN = \'http://%s/\'@g" /etc/mailman/mm_cfg.py && \
    echo "MTA ='Postfix'" >> /etc/mailman/mm_cfg.py && \
    echo "add_language('de', 'Deutsch', 'utf-8', 'ltr')" >> etc/mailman/mm_cfg.py && \
    echo "add_language('en', 'English (US)', 'utf-8', 'ltr')" >> etc/mailman/mm_cfg.py && \
    # Cache default dirs as template (must come after configuration)
    cp -a /etc/mailman /etc/mailman.cache && \
    cp -a /var/lib/mailman /var/lib/mailman.cache && \
    cp -a /var/spool/postfix /var/spool/postfix.cache

ADD supervisord.conf /etc/supervisor/supervisord.conf
ADD *.sh /

EXPOSE 25 80

VOLUME ["/etc/mailman", "/var/lib/mailman", "/var/log/mailman", "/var/spool/postfix"]

ENTRYPOINT ["/entry.sh"]

CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
