FROM litespeedtech/openlitespeed:latest
COPY install.sh /usr/local/bin/

LABEL version="0.0.1"
LABEL description="PHP/MySQL com Litespeed"
LABEL maintainer="Alan Mosko<falecom@alanmosko.com.br>"

ENV DB_NAME=""
ENV DB_USER="root"
ENV DB_PASS=""
ENV DB_HOST="localhost"
ENV DB_PORT="3306"
ENV LARAVEL_INSTALL=""
ENV PHP_INI_MAXFILE_SIZE="256M"
ENV PHP_INI_EXECUTION_TIME="300"
ENV PHP_INI_MEMORY_LIMIT="512M"

RUN apt-get update -y
RUN apt-get upgrade -y
RUN apt-get install -y wget cron nano zip unzip curl git
RUN wget -O - http://rpms.litespeedtech.com/debian/enable_lst_debain_repo.sh | bash
RUN apt-get install -y lsphp74-ldap
RUN apt-get clean
RUN apt-get autoclean
RUN apt-get autoremove --purge -y wget
RUN rm -rf /var/lib/apt/lists/*

ENV PATH="${PATH}:/usr/local/lsws/lsphp74/bin/"

WORKDIR /var/www/vhosts/localhost/html

CMD ["sh", "/usr/local/bin/install.sh"]

COPY .htaccess /var/www/vhosts/localhost/html

RUN /usr/local/lsws/bin/lswsctrl restart
