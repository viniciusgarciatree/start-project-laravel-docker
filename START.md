# Iniciar a aplicação com dockerfile
docker build --progress plain -t management:latest .
docker run --name management -p 80:80 -v .:/var/www --network net-db management:latest