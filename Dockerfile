FROM crystallang/crystal:0.24.1

WORKDIR /app/user

ADD . /app/user

RUN crystal deps

CMD ["crystal", "spec"]

