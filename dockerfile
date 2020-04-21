# Dependencies Container Image
# Install wget to retrieve Spark runtime components,
# extract to temporary directory, copy to the desired image
FROM ubuntu:18.04 AS deps

RUN apt-get update && apt-get -y install wget
WORKDIR /tmp
RUN wget http://mirrors.gigenet.com/apache/spark/spark-2.4.5/spark-2.4.5-bin-hadoop2.7.tgz \
	&& tar xvzf spark-2.4.5-bin-hadoop2.7.tgz

RUN wget https://downloads.apache.org/hadoop/common/hadoop-2.7.7/hadoop-2.7.7.tar.gz \
		&& tar xvzf hadoop-2.7.7.tar.gz

# Runtime Container Image. Adapted from the official Spark runtime
# image from the project repository at https://github.com/apache/spark.
FROM openjdk:8-jdk-slim AS build


# Install Spark Dependencies and Prepare Spark Runtime Environment
RUN set -ex && \
    apt-get update && \
    ln -s /lib /lib64 && \
    apt install -y bash tini libc6 libpam-modules libnss3 wget python3 python3-pip && \
    mkdir -p /opt/spark && \
		mkdir -p /opt/spark/checkpoint && \
    mkdir -p /opt/spark/examples && \
    mkdir -p /opt/spark/work-dir && \
    touch /opt/spark/RELEASE && \
    rm /bin/sh && \
    ln -sv /bin/bash /bin/sh && \
    ln -sv /usr/bin/tini /sbin/tini && \
    ln -sv /usr/bin/python3 /usr/bin/python && \
    ln -sv /usr/bin/pip3 /usr/bin/pip \
    rm -rf /var/cache/apt/*


# Install PySpark and Numpy
RUN apt-get update && apt-get install -y \
    python-pip

RUN \
    pip install --upgrade pip && \
    pip install numpy && \
    pip install pyspark

# Copy previously fetched runtime components
COPY --from=deps /tmp/spark-2.4.5-bin-hadoop2.7/bin /opt/spark/bin
COPY --from=deps /tmp/spark-2.4.5-bin-hadoop2.7/jars /opt/spark/jars
COPY --from=deps /tmp/spark-2.4.5-bin-hadoop2.7/python /opt/spark/python
COPY --from=deps /tmp/spark-2.4.5-bin-hadoop2.7/R /opt/spark/R
COPY --from=deps /tmp/spark-2.4.5-bin-hadoop2.7/sbin /opt/spark/sbin
COPY --from=deps /tmp/spark-2.4.5-bin-hadoop2.7/yarn /opt/spark/yarn
COPY --from=deps /tmp/hadoop-2.7.7/share/hadoop /opt/spark/jars


# Copy Docker entry script
COPY --from=deps /tmp/spark-2.4.5-bin-hadoop2.7/kubernetes/dockerfiles/spark/entrypoint.sh /opt/
# Copy examples, data, and tests
COPY --from=deps /tmp/spark-2.4.5-bin-hadoop2.7/examples /opt/spark/examples
COPY --from=deps /tmp/spark-2.4.5-bin-hadoop2.7/data /opt/spark/data
COPY --from=deps /tmp/spark-2.4.5-bin-hadoop2.7/kubernetes/tests /opt/spark/tests
#
# # Replace out of date dependencies causing a 403 error on job launch
# WORKDIR /tmp
# RUN cd /tmp \
#   && wget https://oak-tree.tech/documents/59/kubernetes-client-4.6.4.jar \
#   && wget https://oak-tree.tech/documents/58/kubernetes-model-4.6.4.jar \
#   && wget https://oak-tree.tech/documents/57/kubernetes-model-common-4.6.4.jar \
#   && rm -rf /opt/spark/jars/kubernetes-client-* \
#   && rm -rf /opt/spark/jars/kubernetes-model-* \
#   && rm -rf /opt/spark/jars/kubernetes-model-common-* \
#   && mv /tmp/kubernetes-* /opt/spark/jars/
# Install Python
COPY RedshiftJDBC42-no-awssdk-1.2.37.1061.jar /opt/spark/jars
COPY kubernetes-model-4.4.2.jar /opt/spark/jars
COPY kubernetes-client-4.4.2.jar /opt/spark/jars
COPY kubernetes-model-common-4.4.2.jar /opt/spark/jars

COPY hadoop-jars/ opt/spark/jars
COPY spark-streaming-kafka-0-10_2.11-2.4.5.jar /opt/spark/jars
COPY spark-sql-kafka-0-10_2.11-2.4.5.jar /opt/spark/jars
COPY kafka-clients-0.10.1.0.jar /opt/spark/jars
COPY aws-java-sdk-1.10.65.jar /opt/spark/jars
COPY hadoop-auth-2.6.0.jar /opt/spark/jars
COPY hadoop-aws-2.7.1.2.4.0.0-169.jar /opt/spark/jars
COPY word_count.py /opt/spark/python
COPY input.txt /opt/spark/python
COPY kafka-read.py /opt/spark/python

# Set Spark runtime options
WORKDIR /opt/spark/work-dir
ENV SPARK_HOME /opt/spark
# ENV USER root
# RUN mkdir -p $WORK_DIR_PATH && chown -R $USER:$USER $WORK_DIR_PATH
RUN chmod +x /opt/entrypoint.sh
ENTRYPOINT ["/opt/entrypoint.sh" ]

# # Specify the User that the actual main process will run as
# USER ${spark_uid}
