FROM drujensen/crystal

ADD . /app/user
WORKDIR /app/user

RUN shards update

CMD ["crystal", "spec"]

