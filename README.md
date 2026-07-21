# ground_docker
Docker stack for UF Autonomy Park ground robots to be used on Jetson AGX Orin with CUDA 12.2

## Build ZED base image
Clone our fork of the ZED ROS 2 wrapper
```bash
git clone https://github.com/UFL-Autonomy-Park/zed_ros2_wrapper_jetson.git
cd zed_ros2_wrapper_jetson
git switch autonomypark/humble-v5.0.0
```

Build the ROS 2 Humble, ZED SDK v5.0.0, L4T r36.3.0 base image
```bash
./docker/jetson_build_dockerfile_from_sdk_and_l4T_version.sh \
	l4t-r36.3.0 \
	zedsdk-5.0.0
```

## Setup
Let `${ROBOT_TYPE}` denote your platform. Valid options are `b1,go1,husky,jackal`
```bash
# 1. Clone and configure
git clone https://github.com/UFL-Autonomy-Park/ground_docker.git  && cd homebrew_docker
cp .env.${ROBOT_TYPE}$ .env
# Edit .env with your settings
```

Set up your Zed camera with a factory calibration file before launching. Get your serial number by plugging in the Zed to the Jetson and running
```bash
lsusb -v 2>/dev/null | grep -A20 -i stereolabs
```

Use the 8-digit number and run
```bash
mkdir -p /config/zed
ZED_SERIAL=${YOUR_ZED_SERIAL_NUMBER}
curl -fL \
  "https://calib.stereolabs.com/?SN=${ZED_SERIAL}" \
  -o "config/zed/SN${ZED_SERIAL}.conf"
```

If you are the first person setting up the Zed, print the serial number using the label maker and attach it to the Zed so the next person does not have to do this

## TO-DO:
- Install all required ROS packages that must be pulled from GitHub (`minimal_startup_ground`, `emlid_interface`, `holonomic_interpreter`, the Unitree pkgs, and the Clearpath pkgs)