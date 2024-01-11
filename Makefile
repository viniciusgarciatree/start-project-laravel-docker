IMAGE_NAME=garciatree/php8.3
CONTAINER_NAME=management
APP_VERSION=0.0.1-dev

clone-larave:
	git clone https://github.com/laravel/laravel.git src
	rm -rf src/.git/

build:
	docker build --progress plain --tag $(IMAGE_NAME):$(APP_VERSION) "."

start:
	docker run --name $(CONTAINER_NAME) -p 80:80 -p 5173:5173 -v /var/www/garcia/management/src:/var/www --network net-db $(IMAGE_NAME):$(APP_VERSION) &

test:
	docker run --rm $(IMAGE_NAME):$(APP_VERSION) php -v | grep 8.3.1

destroy:
	docker image rm $(IMAGE_NAME):$(APP_VERSION)

install:
	docker exec -it $(CONTAINER_NAME) composer install
	docker exec -it $(CONTAINER_NAME) chmod 775 -R .
	docker exec -it $(CONTAINER_NAME) npm install
	docker exec -it $(CONTAINER_NAME) cp .env.example .env
	docker exec -it $(CONTAINER_NAME) php artisan key:generate
	docker exec -it $(CONTAINER_NAME) chmod -R o+w ./storage
	docker exec -it $(CONTAINER_NAME) php artisan cache:clear
	docker exec -it $(CONTAINER_NAME) php artisan view:clear
	docker exec -it $(CONTAINER_NAME) php artisan config:clear

migrate:
	docker exec -it $(CONTAINER_NAME) php artisan migrate

permisson:
	docker exec -it $(CONTAINER_NAME) chown -R www-data:www-data .
	docker exec -it $(CONTAINER_NAME) chmod 775 -R .

bash:
	docker exec -it $(CONTAINER_NAME) /bin/bash

optimize:
	docker exec -it $(CONTAINER_NAME) php artisan optimize

log:
	docker logs -f --tail 100 $(CONTAINER_NAME)