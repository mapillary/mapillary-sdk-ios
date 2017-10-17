# Import the mapillary docker base image
FROM mapillary/mapillary_docker_base:1ad6314492d726f3d4d6795f016b45ac765970e2

# Replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Set debconf to run non-interactively
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Install os dependencies
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash - && \
    apt-get install -y nodejs build-essential libprotobuf-dev inotify-tools && \
    npm install -g npm@4.1.2

# Only install libraries if package.json changed 
RUN mkdir /mapillary_source
ADD package.json /tmp/package.json
RUN cd /tmp && npm install
RUN cp -a /tmp/node_modules mapillary_source

# Add the complete source of your repository source
ADD . mapillary_source
WORKDIR /mapillary_source
RUN mkdir -p /mapillary
RUN ln -s /mapillary_source/docker/dockercontext/mapillary/* /mapillary
ENV PATH="/mapillary:${PATH}"

# Build project
#RUN npm run build