FROM drujensen/crystal-0.18

ADD . /app/user
WORKDIR /app/user

RUN shards update

CMD ["crystal", "spec"]

