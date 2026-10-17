# Lab 5 submission

Fill in every line marked `ANSWER:` (one to three sentences each). Write the answer on the same line, right after `ANSWER:`; for pasted output, add a short summary there and paste the output below. Push before the start of the week 9 session.

## Part A - first containers

1. After `docker stop hello`, what does `docker ps` show, and what does `docker ps -a` show? In one sentence each: what is an image, what is a container?
   ANSWER:

## Part B - the image

2. Paste the first five lines of `make history`. Which instruction adds the most, and why do `wget` and `unzip` not appear in the final image?
   ANSWER:

3. The database password is not in the Dockerfile. Where does the shop get it at run time, and what would happen to it if you had written `ENV WORDPRESS_DB_PASSWORD=...` in the Dockerfile and pushed the image?
   ANSWER:

## Part C - two containers

4. Paste the output of `docker exec shop getent hosts db`. How does the shop find the database by the name `db`, and why does `db` publish no port?
   ANSWER:

## Part D - data

5. After `make down` then `make up`, the shop is still installed. Which volume kept what? What would `make down-all` change?
   ANSWER:

## Part E - registry

6. Paste the last line of `make push` (it contains `digest: sha256:...`). What is the difference between the tag `1.0` and the digest?
   ANSWER:

## Cleanup

- `make clean` done (yes/no): ANSWER:
