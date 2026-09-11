# Stage 1: Build the Flutter web project
FROM ubuntu:22.04 AS build

# Set environment to non-interactive to avoid timezone prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies for Flutter
RUN apt-get update && \
    apt-get install -y curl git wget unzip libgconf-2-4 gdb libstdc++6 libglu1-mesa fonts-droid-fallback lib32stdc++6 python3

# Clone and setup Flutter (using stable channel)
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter -b stable
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"
RUN flutter doctor

# Copy app code
WORKDIR /app
COPY . .

# Build Web App
RUN flutter pub get
RUN flutter build web --release --wasm

# Stage 2: Serve the app with Nginx
FROM nginx:alpine

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy the build artifacts from the build stage
COPY --from=build /app/build/web /usr/share/nginx/html

# Expose port (internally mapped in container)
EXPOSE 80

# Run nginx indefinitely
CMD ["nginx", "-g", "daemon off;"]
