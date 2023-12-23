FROM ubuntu:focal

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
    && apt-get install --no-install-recommends -y git npm \
    curl jq build-essential apt-transport-https unzip \
    libc6 libgcc1 libgssapi-krb5-2 libicu66 libssl1.1 libstdc++6 zlib1g \
    && curl -sS https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -o packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb && rm packages-microsoft-prod.deb \
    && apt-get update

RUN curl -s https://get.sdkman.io | bash
RUN chmod a+x "$HOME/.sdkman/bin/sdkman-init.sh"
RUN source "$HOME/.sdkman/bin/sdkman-init.sh"
    
COPY cyclonedx-linux-x64 /usr/bin/cyclonedx-cli
RUN chmod +x /usr/bin/cyclonedx-cli

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["sh","/entrypoint.sh"]
