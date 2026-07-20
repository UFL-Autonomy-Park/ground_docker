# The base image is built by:
# UFL-Autonomy-Park/zed_ros2_wrapper_jetson

# Default image value matches that of the `jetson_build_dockerfile_from_sdk_and_l4T_version.sh` script

ARG BASE_IMAGE=zed_ros2_l4t_36.3.0_sdk_5.0.0
FROM ${BASE_IMAGE}

ARG ROS_DISTRO=humble
ENV ROS_DISTRO=${ROS_DISTRO}

SHELL ["/bin/bash", "-c"]

# Install platform-specific packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-${ROS_DISTRO}-microstrain-inertial-driver \
    ros-${ROS_DISTRO}-velodyne
RUN python3 -m pip install --no-cache-dir nmea-parser==0.5.0

# Fast DDS Discovery Server super-client profile.
COPY config/fastdds/super_client_config.xml \
    /etc/fastdds/super_client_config.xml

COPY docker/ros_entrypoint.sh \
    /sbin/ground_ros_entrypoint.sh

RUN chmod 755 /sbin/ground_ros_entrypoint.sh

ENTRYPOINT ["/sbin/ground_ros_entrypoint.sh"]