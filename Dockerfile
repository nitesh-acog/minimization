FROM ubuntu:20.04
MAINTAINER Manish Sihag <manish@aganitha.ai>

# Miniconda installation
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# Install required system packages
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update --fix-missing
RUN apt-get install -y wget curl bzip2 ca-certificates git \
                       vim procps htop lsof \
                       libglib2.0-0 libxext6 libsm6 libxrender1 \
                       mercurial openssh-client subversion \
                       build-essential software-properties-common \
                       libpq-dev
RUN apt-get update --fix-missing && \
    apt-get install -y cmake mpich libibnetdisc-dev openmpi-bin openmpi-doc libopenmpi-dev \
                       gfortran liblapack-dev

# Install Anaconda3
# ARG py_ver=3
# ARG anaconda_ver=2021.05
# RUN echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh && \
#     wget --quiet https://repo.anaconda.com/archive/Anaconda${py_ver}-${anaconda_ver}-Linux-x86_64.sh -O ~/anaconda.sh && \
#     /bin/bash ~/anaconda.sh -b -p /opt/conda && \
#     rm ~/anaconda.sh

# Install Miniconda3
ARG py_ver=py39
ARG miniconda_ver=4.12.0
RUN echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh && \
    wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-${py_ver}_${miniconda_ver}-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh


# RUN TINI_VERSION=`curl -Ls -o /dev/null -w %{url_effective} https://github.com/krallin/tini/releases/latest | grep -o "v.*" | sed -e 's/v//g'` && \
#     curl -L "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini_${TINI_VERSION}.deb" > tini.deb && \
#     dpkg -i tini.deb && \
#     rm tini.deb && \
#     apt-get clean

RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV PATH /opt/conda/bin:$PATH

# Install the required python packages
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

RUN apt-get update && apt-get install -y flex bison

# Install AmberTools
RUN conda config --add channels conda-forge
RUN conda install -c conda-forge ambertools=22 compilers
RUN apt-get install -y unzip
SHELL ["/bin/bash", "-c"]
RUN wget https://github.com/ParmEd/ParmEd/archive/refs/heads/master.zip && \
    unzip master.zip && \
    cd ParmEd-master && \
    source /opt/conda/amber.sh && \
    python setup.py install --prefix=$AMBERHOME

# Install Gromacs
#RUN apt-get install -y gromacs 
RUN wget ftp://ftp.gromacs.org/gromacs/gromacs-2022.2.tar.gz && \
    tar xfz gromacs-2022.2.tar.gz
ENV PATH /usr/bin/c++:$PATH
ENV PATH /usr/bin/make:$PATH
ENV PATH /usr/bin/make:/usr/bin/c++:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
RUN cd gromacs-2022.2 && \
    mkdir build && \
    cd build && \
    cmake .. -DGMX_BUILD_OWN_FFTW=ON -DREGRESSIONTEST_DOWNLOAD=ON && \
    make && \
    make check && \
    make install && \
    source /usr/local/gromacs/bin/GMXRC

ENV PATH /opt/conda/bin:$PATH
ENV PATH /usr/local/gromacs/bin:$PATH
#WORKDIR /home

RUN conda install -c conda-forge mpi4py=3.1.3 compilers -y -q && \
   python -m pip install gmx-MMPBSA && \
   python -m pip install pyqt5  && \
   python -m pip install gmx_MMPBSA

RUN conda install -y -c conda-forge plumed

#Install Pursenet- binding site prediction
RUN git clone https://github.com/jivankandel/PUResNet.git
WORKDIR PUResNet
RUN conda create -n env_name python=3.6 && \
#conda activate env_name && \
source activate env_name && \
conda install -c openbabel openbabel && \
conda install -c cheminfibb tfbio && \
conda install scikit-image && \ 
conda install numpy && \
conda install -c anaconda scipy && \
conda install -c conda-forge keras=2.1 && \
conda install -c conda-forge tensorflow=1.11

WORKDIR /home/acog/AAV1
CMD ["./mdrun.sh"]
