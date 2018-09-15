FROM ubuntu:18.04

RUN apt-get update
RUN apt-get install -y git wget curl
RUN apt-get install -y build-essential

# Clone sources
RUN git clone https://github.com/johnazoidberg/uefi ~/yabits --recurse-submodules
WORKDIR /root/yabits

# Build libpayload
RUN make -C coreboot/payloads/libpayload -j$(nproc)

# Build coreboot cross compile toolchain
RUN apt-get install -y m4 bison flex zlib1g-dev
RUN apt-get install -y gnat-7
RUN make -C coreboot crossgcc-i386 CPUS=$(nproc)

# Build yabits
RUN make defconfig
RUN make

# Build coreboot rom with yabits as payload
RUN make -C coreboot olddefconfig
RUN sed -i '/CONFIG_PAYLOAD_ELF/c\CONFIG_PAYLOAD_ELF=y' coreboot/.config
RUN sed -i '/CONFIG_PAYLOAD_FILE/c\CONFIG_PAYLOAD_FILE="../build/uefi.elf"' coreboot/.config
RUN sed -i '/CONFIG_PAYLOAD_SEABIOS/c\# CONFIG_PAYLOAD_SEABIOS is not set' coreboot/.config
RUN make -C coreboot
