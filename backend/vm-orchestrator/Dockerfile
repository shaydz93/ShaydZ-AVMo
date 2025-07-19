FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    openjdk-11-jdk \
    wget \
    unzip \
    adb \
    qemu-kvm \
    libvirt-daemon-system \
    bridge-utils \
    virtinst \
    libvirt-clients \
    python3 \
    python3-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set up Android emulator
RUN mkdir -p /opt/android-sdk
ENV ANDROID_HOME /opt/android-sdk
ENV PATH ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools

# Install Python requirements
COPY requirements.txt .
RUN pip3 install -r requirements.txt

# Create workspace
WORKDIR /app
COPY . .

EXPOSE 8082

CMD ["python3", "orchestrator.py"]
