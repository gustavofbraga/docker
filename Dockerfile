# Use uma imagem base com PHP e Apache
FROM php:apache

# Argumentos definidos no docker-compose.yml
ARG user
ARG uid

# Atualize a lista de pacotes e instale extensões do PHP e ferramentas conforme necessário
RUN apt-get update && \
    apt-get install -y \
        libpng-dev \
        libjpeg-dev \
        libfreetype6-dev \
        libzip-dev \
        libonig-dev \
        libxml2-dev \
        libssl-dev \
        libcurl4-openssl-dev \
        git \
        nano \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) xml gd zip pdo_mysql mysqli mbstring curl dom exif pcntl bcmath sockets

# Limpeza do cache após a instalação de pacotes
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Instale o OpCache
RUN docker-php-ext-install opcache

# Instale o Xdebug
RUN pecl install xdebug && \
    docker-php-ext-enable xdebug

# Instale o Redis
RUN pecl install -o -f redis \
    && rm -rf /tmp/pear \
    && docker-php-ext-enable redis

# Instale o Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Crie um usuário do sistema para executar comandos do Composer e Artisan
RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

# Configure o PHP
COPY apache-conf/php.ini /usr/local/etc/php

# Copie seu arquivo de configuração do Xdebug para dentro do contêiner
COPY xdebug.ini /usr/local/etc/php/conf.d

# Copie as configurações do Apache
COPY apache-conf/. /etc/apache2/

# Habilite o site "laravel10" no Apache
RUN a2ensite laravel10

# Habilite o módulo de reescrita do Apache
RUN a2enmod rewrite

# Reinicie o serviço Apache
RUN service apache2 restart

# Exponha a porta 80 (a porta padrão do Apache)
EXPOSE 80

# Inicialize o servidor Apache
CMD ["apache2-foreground"]