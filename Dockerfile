FROM ubuntu:16.04
MAINTAINER Sharath Ganesh Pai <sharath@cliqz.com>
ENV DEBIAN_FRONTEND noninteractive

#Install the required packages. 1st Set is for FF and the 2nd for Ruby and FastLane.
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y \
        autoconf2.13 \
        build-essential \
        ccache \
        curl \
        language-pack-en \
        libncurses5:i386 \
        libstdc++6:i386 \
        openjdk-8-jdk \
        python-dev \
        python3-dev \
        python-pip \
        python-setuptools \
        python-virtualenv \
        unzip \
        uuid \
        wget \
        zip && \
    apt-get install -y \
        automake \
        bison \
        gawk \
        gnupg2 \
        language-pack-en \
        libffi-dev \
        libgdbm-dev \
        libgmp-dev \
        libncurses5-dev \
        libreadline6-dev \
        libsqlite3-dev \
        libssl-dev \
        libtool \
        libyaml-dev \
        pkg-config \
        python-virtualenv \
        sqlite3 \
        zlib1g-dev && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set the locale
RUN locale-gen en_US en_US.UTF-8
RUN dpkg-reconfigure locales
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

# Add to the user group
ARG UID
ARG GID
ENV SHELL=/bin/bash
RUN getent group $GID || groupadd jenkins --gid $GID && \
    useradd --create-home --shell /bin/bash jenkins --uid $UID --gid $GID

#Set Environment Variables
ENV SHELL /bin/bash
ENV MOZBUILD_STATE_PATH /home/jenkins/.mozbuild/
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
ENV RUSTUP_HOME=/usr/local/rustup
ENV CARGO_HOME=/usr/local/cargo
ENV PATH=/usr/local/cargo/bin:$PATH

#Install Rust and android library
RUN set -eux; \
    \
# this "case" statement is generated via "update.sh"
    dpkgArch="$(dpkg --print-architecture)"; \
    case "${dpkgArch##*-}" in \
        amd64) rustArch='x86_64-unknown-linux-gnu'; rustupSha256='5a38dbaf7ab2e4335a3dfc42698a5b15e7167c93b0b06fc95f53c1da6379bf1a' ;; \
        armhf) rustArch='armv7-unknown-linux-gnueabihf'; rustupSha256='67a98a67f7f7bf19c5cde166499acb8299f2f8fa88c155093df53b66da1f512a' ;; \
        arm64) rustArch='aarch64-unknown-linux-gnu'; rustupSha256='82fe368c4ebf1683d57e137242793a4417042639aace8bd514601db7d79d3645' ;; \
        i386) rustArch='i686-unknown-linux-gnu'; rustupSha256='7a1c085591f6c1305877919f8495c04a1c97546d001d1357a7a879cedea5afbb' ;; \
        *) echo >&2 "unsupported architecture: ${dpkgArch}"; exit 1 ;; \
    esac; \
    \
    url="https://static.rust-lang.org/rustup/archive/1.7.0/${rustArch}/rustup-init"; \
    wget "$url"; \
    echo "${rustupSha256} *rustup-init" | sha256sum -c -; \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --default-toolchain 1.20.0; \
    rm rustup-init; \
    chmod -R a+w $RUSTUP_HOME $CARGO_HOME; \
    rustup --version; \
    cargo --version; \
    rustc --version; \
    rustup self update; \
    rustup toolchain install stable-x86_64-unknown-linux-gnu; \
    rustup default stable-x86_64-unknown-linux-gnu; \
    rustup target add i686-linux-android && rustup target add armv7-linux-androideabi

# CHange to User Jenkins and Set Environment Variables
USER jenkins
ENV ANDROID_HOME /home/jenkins/.mozbuild/android-sdk-linux
ENV ANDROID_NDK_HOME /home/jenkins/.mozbuild/android-ndk-linux
ENV PATH "/home/jenkins/node-v8.9.3-linux-x64/bin:$PATH"
ENV NVM_DIR /home/jenkins/nvm
ENV NODE_VERSION 8.9.3
ENV CLANG_HOME /home/jenkins/clang
SHELL ["/bin/bash", "-l", "-c"]

# Install nvm with node and npm
RUN curl https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh | bash && \
    . $NVM_DIR/nvm.sh
ENV NODE_PATH "$NVM_DIR/versions/node/v$NODE_VERSION/lib/node_modules"
ENV PATH "$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH"

#Install Proguard
RUN mkdir -p /home/jenkins/.mozbuild/proguard/lib && mkdir -p /home/jenkins/tmp && \
    wget --output-document=/home/jenkins/tmp/proguard.tgz --quiet "https://repository.cliqz.com/dist/android/artifacts/proguard/proguard5.3.3.tar.gz" && \
    (cd /home/jenkins/tmp; tar xf proguard.tgz && cp proguard5.3.3/lib/proguard.jar /home/jenkins/.mozbuild/proguard/lib) && \
    rm -rf /home/jenkins/tmp/*

#Install Android SDK and the Required SDKs
COPY mozilla-release/python/mozboot/mozboot/android-packages.txt /home/jenkins/
RUN mkdir -p $ANDROID_HOME; \
    cd $ANDROID_HOME; \
    wget --output-document=sdktools.zip --quiet 'https://repository.cliqz.com/dist/android/artifacts/android-sdk/sdk-tools-linux-3859397.zip'; \
    unzip sdktools.zip; \
    rm -r sdktools.zip; \
    (while (true); do echo y; sleep 2; done) | \
      tools/bin/sdkmanager  --package_file=/home/jenkins/android-packages.txt;

#Install Android NDK
RUN mkdir -p $ANDROID_NDK_HOME; \
    cd $ANDROID_NDK_HOME; \
    wget --output-document=ndk.zip --quiet 'https://dl.google.com/android/repository/android-ndk-r15c-linux-x86_64.zip'; \
    unzip ndk.zip; \
    rm -r ndk.zip;

#Install CLang
RUN mkdir -p $CLANG_HOME; \
    cd $CLANG_HOME; \
    wget --output-document=clang.tar.xz --quiet  http://releases.llvm.org/6.0.0/clang+llvm-6.0.0-x86_64-linux-gnu-ubuntu-16.04.tar.xz && \
    tar xf clang.tar.xz && \
    cp -r clang+llvm-6.0.0-x86_64-linux-gnu-ubuntu-16.04/* $CLANG_HOME; \
    rm -rf clang+llvm-6.0.0-x86_64-linux-gnu-ubuntu-16.04 clang.tar.xz && \
    echo 'export PATH=$CLANG_HOME/bin:$PATH' >> ~/.bashrc && \
    echo 'export LD_LIBRARY_PATH=$CLANG_HOME/lib:LD_LIBRARY_PATH' >> ~/.bashrc

#Installation of 'yarn'; 'appium' & 'wd' for Integration Tests
RUN npm install --global \
    yarn \
    appium \
    wd

#Install Ruby and Fastlane
RUN gpg2 --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 && \
    curl -sSL https://get.rvm.io | bash -s stable --ruby=2.4.1 --autolibs=read-fail
RUN rvm reload && \
gem install fastlane --version 2.87.0