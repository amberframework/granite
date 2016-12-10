FROM drujensen/crystal:0.20.1

WORKDIR /app/user

ADD . /app/user

RUN crystal deps

CMD ["crystal", "spec"]

