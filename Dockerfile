FROM ubuntu:latest
LABEL author="Anderson Ignacio da Silva"
LABEL maintainer="anderson@aignacio.com"
ENV TZ=Europe/Dublin
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get update && apt-get upgrade -y
RUN apt-get install git file make -y

#RUN gem install rggen
#RUN gem install rggen-verilog rggen-c-header
#RUN gem update  rggen-verilog rggen-c-header
#
#WORKDIR /
#RUN git clone https://github.com/rggen/rggen-sv-rtl.git
#RUN export RGGEN_SV_RTL_ROOT=`pwd`/rggen-sv-rtl
#RUN git clone https://github.com/rggen/rggen-sv-ral.git
#RUN export RGGEN_SV_RAL_ROOT=`pwd`/rggen-sv-ral

#RUN add-apt-repository ppa:deadsnakes/ppa
RUN apt-get install python3 python3-pip -y

RUN apt-get install git help2man perl python3 make autoconf g++ flex bison ccache -y
RUN apt-get install libgoogle-perftools-dev numactl perl-doc -y
RUN apt-get install libfl2 -y # Ubuntu only (ignore if gives error)
RUN apt-get install libfl-dev -y # Ubuntu only (ignore if gives error)
RUN apt-get install zlib1g zlib1g-dev -y # Ubuntu only (ignore if gives error)
#RUN apt-get install zlibc zlib1g zlib1g-dev -y # Ubuntu only (ignore if gives error)
# [Verilator]
RUN git clone https://github.com/verilator/verilator
WORKDIR /verilator
RUN export VERILATOR_ROOT=/verilator
RUN git checkout stable      # Update latest stable
RUN autoconf                 # Create ./configure script
RUN ./configure              # Configure and create Makefile
RUN make -j20                # Build Verilator itself (if error, try just 'make')
RUN make install

# [Tox]
RUN pip install tox tox-gh-actions
