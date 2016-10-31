FROM drujensen/crystal

ADD . /app/user
WORKDIR /app/user

RUN crystal deps

CMD ["crystal", "spec"]

