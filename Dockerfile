FROM gradle:8.5.0-jdk17-focal

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
    && apt-get install --no-install-recommends -y git npm \
    curl jq build-essential apt-transport-https unzip \
    libc6 libgcc1 libgssapi-krb5-2 libicu66 libssl1.1 libstdc++6 zlib1g \
    && curl -sS https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -o packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb && rm packages-microsoft-prod.deb \
    && apt-get update

ENV SDK_URL="https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip" \
    ANDROID_HOME="/usr/local/android-sdk" \
    ANDROID_VERSION=33 \
    ANDROID_BUILD_TOOLS_VERSION=33.0.2

RUN mkdir "$ANDROID_HOME" .android \
    && cd "$ANDROID_HOME" \
    && curl -o sdk.zip $SDK_URL \
    && unzip sdk.zip \
    && rm sdk.zip
    
    
RUN $ANDROID_HOME/tools/bin/sdkmanager --update
RUN RUN yes | sdkmanager --licenses \
    && $ANDROID_HOME/tools/bin/sdkmanager "build-tools;${ANDROID_BUILD_TOOLS_VERSION}" \
    "platforms;android-${ANDROID_VERSION}" \
    "platform-tools"
    
COPY cyclonedx-linux-x64 /usr/bin/cyclonedx-cli
RUN chmod +x /usr/bin/cyclonedx-cli

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["sh","/entrypoint.sh"]
