FROM ubuntu:latest
LABEL author="Anderson Ignacio da Silva"
LABEL maintainer="anderson@aignacio.com"
ENV TZ=Europe/Dublin
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get update && apt-get upgrade -y
RUN apt-get install git file make ruby -y
RUN gem install rggen
RUN gem install rggen-verilog rggen-c-header
RUN gem update  rggen-verilog rggen-c-header

WORKDIR /
RUN git clone https://github.com/rggen/rggen-sv-rtl.git
RUN export RGGEN_SV_RTL_ROOT=`pwd`/rggen-sv-rtl
RUN git clone https://github.com/rggen/rggen-sv-ral.git
RUN export RGGEN_SV_RAL_ROOT=`pwd`/rggen-sv-ral

#RUN add-apt-repository ppa:deadsnakes/ppa
#RUN apt install python3.9 -y
RUN apt-get install python3 make g++ perl autoconf flex bison libfl2  \
                    libfl-dev zlibc zlib1g zlib1g-dev git file gcc    \
                    make time wget zip python3-pip lcov -y
# [Verilator]
RUN git clone https://github.com/verilator/verilator
WORKDIR /verilator
RUN export VERILATOR_ROOT=/verilator
RUN git checkout v4.106      # Update latest stable
RUN autoconf                 # Create ./configure script
RUN ./configure              # Configure and create Makefile
RUN make -j4                 # Build Verilator itself (if error, try just 'make')
RUN make install

# [Tox]
RUN pip install tox tox-gh-actions
