# Use uma imagem base com PHP e Apache
FROM php:apache

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
    && docker-php-ext-install -j$(nproc) gd zip pdo_mysql mysqli mbstring xml curl

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

# Copie seu arquivo de configuração do Xdebug para dentro do contêiner
COPY xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

# Copie seus arquivos PHP para o diretório padrão do Apache
COPY ./ /var/www/html/

# Exponha a porta 80 (a porta padrão do Apache)
EXPOSE 80

# Inicialize o servidor Apache
CMD ["apache2-foreground"]