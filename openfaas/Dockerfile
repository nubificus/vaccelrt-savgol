FROM dustynv/jetson-inference:r32.6.1 as builder

ENV DEBIAN_FRONTEND="noninteractive"

#RUN apt-get update && apt-get install -y build-essential git pkg-config nvidia-cuda-toolkit \
#	libz-dev bison flex wget bc libssl-dev \
#	unzip && apt-get clean

RUN mkdir /opt/vaccel && wget https://github.com/cloudkernels/vaccel/releases/download/v0.4.0/vaccel_aarch64_Release.tar.gz && tar -zxvf vaccel_aarch64_Release.tar.gz -C /opt/vaccel

#FROM ubuntu:20.04 as prom-builder

ENV DEBIAN_FRONTEND="noninteractive"
RUN apt-get update --fix-missing && \
    apt-get install -y ca-certificates libglib2.0-0 libxext6 libsm6 libxrender1 git mercurial subversion zlib1g-dev libcurl4-openssl-dev zlib1g cmake python3-pip curl cmake && \
    apt-get clean

RUN apt-get install -y wget curl
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    /opt/conda/bin/conda clean -tipsy && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc && \
    find /opt/conda/ -follow -type f -name '*.a' -delete && \
    find /opt/conda/ -follow -type f -name '*.js.map' -delete && \
    /opt/conda/bin/conda clean -afy
RUN pip3 install pandas

RUN apt-get install -y libssl-dev
RUN pip3 install cmake==3.18.4
RUN git clone https://github.com/jupp0r/prometheus-cpp && cd prometheus-cpp && git submodule update --init --recursive && mkdir _build && cd _build && cmake .. -DBUILD_SHARED_LIBS=ON && cmake --build . --parallel 4 && ctest -V && cmake --install .

WORKDIR /
ARG TOKEN
ARG CACHE
RUN git clone https://${TOKEN}:x-oauth-basic@github.com/nubificus/vaccelrt-savgol && \
    cd vaccelrt-savgol && ln -s /opt/vaccel /opt/vaccel-v0.4.0  && make

FROM ghcr.io/openfaas/classic-watchdog:latest as watchdog

FROM ubuntu:20.04 

COPY --from=watchdog /fwatchdog /usr/bin/fwatchdog
RUN chmod +x /usr/bin/fwatchdog

COPY --from=builder /vaccelrt-savgol/wrapper_vaccel /wrapper_vaccel
COPY --from=builder /vaccelrt-savgol/libsavgol_vaccel.so /opt/vaccel/lib/libsavgol_vaccel.so
#COPY --from=builder /vaccelrt-savgol/data /data
COPY --from=builder /opt/vaccel	/opt/vaccel

ENV LD_LIBRARY_PATH=/opt/vaccel/lib:/
ENV VACCEL_BACKENDS=/opt/vaccel/lib/libvaccel-vsock.so

EXPOSE 8080

HEALTHCHECK --interval=3s CMD [ -e /tmp/.lock ] || exit 1

ENV write_debug="true"
#ENV fprocess="xargs qemu_run.sh"
CMD ["fwatchdog"]
