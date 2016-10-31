FROM drujensen/crystal:0.19.4

ADD . /app/user
WORKDIR /app/user

RUN crystal deps

CMD ["crystal", "spec"]

