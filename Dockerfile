FROM eclipse-temurin:11-jdk as build

# library
RUN apt-get update && apt-get install -y \
	apt-transport-https \
	ca-certificates \
	curl \
	gnupg \
	--no-install-recommends \
	&& curl -sSL https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
	&& echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list \
	&& apt-get update && apt-get install -y \
	google-chrome-stable \
	--no-install-recommends \
	&& apt-get purge --auto-remove -y curl \
	&& rm -rf /var/lib/apt/lists/*

# install chrome
RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
RUN apt-get install ./google-chrome-stable_current_amd64.deb

# create user & group
RUN set -o errexit -o nounset \
  && groupadd --system --gid 1000 java \
  && useradd --system --gid java --uid 1000 --shell /bin/bash --create-home java \
  && mkdir /home/java/.gradle \
  && chown --recursive java:java /home/java

# build
WORKDIR /app

# copy gradle files
COPY gradlew .
COPY gradle gradle
COPY build.gradle .
COPY settings.gradle .

# build cache
RUN chmod +x ./gradlew
RUN ./gradlew assemble -x test -x bootJar --parallel

# copy source code
COPY . /app

# build
RUN chmod +x ./gradlew
RUN ./gradlew clean assemble -x test --build-cache --parallel

# runtime stage
FROM eclipse-temurin:11-jre
LABEL org.opencontainers.image.source https://github.com/username/reponame

RUN apt-get update && apt-get install -y \
	apt-transport-https \
	ca-certificates \
	curl \
	gnupg \
	--no-install-recommends \
	&& curl -sSL https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
	&& echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list \
	&& apt-get update && apt-get install -y \
	google-chrome-stable \
	--no-install-recommends \
	&& apt-get purge --auto-remove -y curl \
	&& rm -rf /var/lib/apt/lists/*

RUN set -o errexit -o nounset \
  && groupadd --system --gid 1000 java \
  && useradd --system --gid java --uid 1000 --shell /bin/bash --create-home java

WORKDIR /app
COPY --from=build --chown=java:java /app/build/libs/ ./build/

USER java

CMD java -jar `find . -type f -name "*.jar" ! -path "*-plain.jar" ! -path "*-wrapper.jar" | head -1`

