FROM nvidia/cuda:10.2-devel

ENV PATH /opt/conda/bin:$PATH

#fix nvidia gpg key
RUN \
#The following files may not exist in your environment and the commands will fail the build if they don't,
#so comment out the next two lines as needed
rm /etc/apt/sources.list.d/cuda.list && \
rm /etc/apt/sources.list.d/nvidia-ml.list



RUN apt-get update --fix-missing && \
    apt-get install -y wget bzip2 ca-certificates libglib2.0-0 libxext6 libsm6 libxrender1 git mercurial subversion && \
    apt-get clean

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

RUN git clone https://github.com/jupp0r/prometheus-cpp
WORKDIR /prometheus-cpp
RUN git submodule init
RUN git submodule update
RUN  mkdir _build
WORKDIR /prometheus-cpp/_build
RUN apt update
RUN apt install zlib1g
RUN  apt install zlib1g-dev
RUN dpkg -L zlib1g
RUN  dpkg -L zlib1g-dev
RUN apt -y install curl
RUN apt-get install libcurl4-openssl-dev
RUN pip3 install cmake
RUN cmake ..
RUN cmake --build . --parallel 4
RUN ctest -V
RUN cmake --install .

WORKDIR /
