# The base image is built by:
# UFL-Autonomy-Park/zed_ros2_wrapper_jetson

# Default image value matches that of the `jetson_build_dockerfile_from_sdk_and_l4T_version.sh` script

ARG BASE_IMAGE=zed_ros2_l4t_36.3.0_sdk_5.0.0
FROM ${BASE_IMAGE}

ARG ROS_DISTRO=humble
ENV ROS_DISTRO=${ROS_DISTRO}
ENV GROUND_WS=/root/ground_ws

SHELL ["/bin/bash", "-c"]

# Install platform-specific packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    cmake \
    libboost-all-dev \
    liblcm-dev \
    python3-pip \
    python3-vcstool \
    python3-colcon-common-extensions \
    ros-${ROS_DISTRO}-microstrain-inertial-driver \
    ros-${ROS_DISTRO}-velodyne \
    ros-${ROS_DISTRO}-robot-localization \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --no-cache-dir nmea-parser==0.5.0

RUN mkdir -p $GROUND_WS

WORKDIR ${GROUND_WS}

COPY config/ground.repos /tmp/ground.repos

RUN mkdir -p src && \
    vcs import src < /tmp/ground.repos

# Build workspace
RUN source /opt/ros/${ROS_DISTRO}/setup.bash && \
    colcon build \
        --merge-install \
        --cmake-args \
            -DCMAKE_BUILD_TYPE=Release

# Fast DDS Discovery Server super-client profile.
COPY config/fastdds/super_client_config.xml \
    /etc/fastdds/super_client_config.xml

COPY docker/ros_entrypoint.sh \
    /sbin/ground_ros_entrypoint.sh

RUN chmod 755 /sbin/ground_ros_entrypoint.sh

WORKDIR ${GROUND_WS}

ENTRYPOINT ["/sbin/ground_ros_entrypoint.sh"]