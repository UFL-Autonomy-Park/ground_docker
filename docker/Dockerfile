# The base image is built by:
# UFL-Autonomy-Park/zed_ros2_wrapper_jetson

# Default image value matches that of the `jetson_build_dockerfile_from_sdk_and_l4T_version.sh` script

ARG BASE_IMAGE=zed_ros2_l4t_36.3.0_sdk_5.0.0
FROM ${BASE_IMAGE}

ARG ROS_DISTRO=humble
ENV ROS_DISTRO=${ROS_DISTRO}
ENV GROUND_WS=/root/ground_ws
ENV EXPERIMENT_WS=/root/experiment_ws

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
    ros-${ROS_DISTRO}-rosidl-default-generators \
    ros-${ROS_DISTRO}-microstrain-inertial-driver \
    ros-${ROS_DISTRO}-velodyne \
    ros-${ROS_DISTRO}-robot-localization \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --no-cache-dir --index-url https://pypi.org/simple nmea-parser==0.5.0

RUN mkdir -p ${GROUND_WS}
RUN mkdir -p ${EXPERIMENT_WS}
RUN mkdir -p /etc/ground

RUN mkdir -p /tmp/ground_ws/src
COPY config/ground.repos /etc/ground/ground.repos
# Temporary clone so rosdep can get dependencies from package.xml
# This workspace is deleted after the image is build
RUN vcs import /tmp/ground_ws/src < /etc/ground/ground.repos
    
# rosdep
RUN apt-get update && \
    source /opt/ros/${ROS_DISTRO}/setup.bash && \
    rosdep install \
        --from-paths /tmp/ground_ws/src \
        --ignore-src \
        --rosdistro ${ROS_DISTRO} \
        -r -y && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/ground_ws

COPY docker/ros_entrypoint.sh \
    /sbin/ground_ros_entrypoint.sh

RUN chmod 755 /sbin/ground_ros_entrypoint.sh

WORKDIR ${GROUND_WS}

ENTRYPOINT ["/sbin/ground_ros_entrypoint.sh"]
