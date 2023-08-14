
# Dockerfile

# Set the base image to Alpine
FROM alpine

# Set the default build repo and branch
ARG BUILD_REPO=PokemonGoF/PokemonGo-Bot
ARG BUILD_BRANCH=master

# Add labels for build repo and branch
LABEL build_repo=$BUILD_REPO build_branch=$BUILD_BRANCH

# Set the working directory
WORKDIR /usr/src/app

# Add volumes
VOLUME ["/usr/src/app/configs", "/usr/src/app/web"]

# Install required packages and remove cache
RUN apk update \
    && apk add --no-cache python py-pip tzdata \
    && rm -rf /var/cache/apk/* \
    && find / -name '*.pyc' -o -name '*.pyo' | xargs -rn1 rm -f

# Download the requirements.txt file
ADD https://raw.githubusercontent.com/$BUILD_REPO/$BUILD_BRANCH/requirements.txt .

# Install necessary dependencies
RUN apk add --no-cache ca-certificates wget \
    && update-ca-certificates \
    && apk add --no-cache apk-tools \
    && apk add --no-cache --virtual .build-dependencies python-dev gcc make musl-dev git \
    && ln -s locale.h /usr/include/xlocale.h \
    && pip install --no-cache-dir -r requirements.txt \
    && apk del .build-dependencies \
    && rm -rf /var/cache/apk/* /usr/include/xlocale.h \
    && find / -name '*.pyc' -o -name '*.pyo' | xargs -rn1 rm -f

# Download the pgobot version information
ADD https://api.github.com/repos/$BUILD_REPO/commits/$BUILD_BRANCH /tmp/pgobot-version

# Install necessary dependencies for pgobot
RUN apk add --no-cache wget ca-certificates tar jq \
    && wget -q -O- https://github.com/$BUILD_REPO/archive/$BUILD_BRANCH.tar.gz | tar zxf - --strip-components=1 -C /usr/src/app \
    && jq -r .sha /tmp/pgobot-version > /usr/src/app/version \
    && apk del wget ca-certificates tar jq \
    && rm -rf /var/cache/apk/* /tmp/pgobot-version

# Set the command for running the script
CMD ["python", "pokecli.py"]
